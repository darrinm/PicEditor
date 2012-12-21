// Copyright 2011 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS-IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package bridges.storageservice {
	import bridges.Bridge;
	import bridges.BridgeItemBase;
	import bridges.BridgeItemEvent;
	import bridges.Downloader;
	import bridges.FileTransferBase;
	import bridges.IAutoFillSource;
	import bridges.InBridgeTileList;
	
	import controls.TextInputPlus;
	
	import dialogs.BusyDialogBase;
	import dialogs.DialogManager;
	import dialogs.EasyDialog;
	import dialogs.EasyDialogBase;
	
	import imagine.documentObjects.DocumentStatus;
	
	import events.*;
	
	import flash.events.*;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	
	import imagine.ImageDocument;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.CollectionEvent;
	import mx.events.FlexEvent;
	import mx.events.ItemClickEvent;
	import mx.events.StateChangeEvent;
	import mx.resources.ResourceBundle;
	import mx.states.State;
	import mx.utils.StringUtil;
	
	import util.Cancelable;
	import util.IPendingFile;
	import util.ImagePropertiesUtil;
	import util.Navigation;
	
	public class StorageServiceInBridgeBase extends StorageServiceBridgeBase implements IAutoFillSource {
		// MXML-specified variables
		[Bindable] public var _tlst:InBridgeTileList;
		[Bindable] public var _imgUserThumbnail:Image;
		[Bindable] public var _imgSet:Image;
		[Bindable] public var _lbGreeting:Label;
		[Bindable] public var _lbPhotoSummary:Label;
		[Bindable] public var _cboxOrderBy:ComboBox;
		[Bindable] public var _tiFilter:TextInputPlus;
		[Bindable] public var _btnSearch:Button;
		[Bindable] public var kstrSearchPrompt:String;

		[Bindable] public var _vbxMain:VBox;
		[Bindable] public var _hbxTip:HBox;

		protected var _fNoItems:Boolean = false;
		protected var batchSize:Number = 18; // BUGBUG: something weird going on with Picasa if we get more that 18 items
		
   		[ResourceBundle("StorageServiceInBridgeBase")] private var _rb:ResourceBundle;
		
		private var _usri:UserInfo;
		
		// PORT: thumbnail sizes should be kept in one place		
		private static const kcxThumbnail:Number = 160; // CONFIG:
		private static const kcyThumbnail:Number = 160; // CONFIG:

		private var _itemInfo:ItemInfo = null;
		private var _strCurrentAction:String = null;
		private var _strRenameTarget:String = null;
		private var _obDeleteCallbackData:Object;
		private var _fnOnLoginComplete:Function;
		private var _obBatchInProgress:Object = null;
		private var _canDownloadOp:Cancelable = null;
		private var _coll:ICollectionView;
		private var _fRefreshingItemList:Boolean = false;
		private var _fItemListDirty:Boolean = false;
		
		protected var _fPendingRefresh:Boolean = false; // if we're in the middle of a meta-op that promises to refresh when it's done
		
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			if (_tlst) _tlst.addEventListener(BridgeItemEvent.ITEM_ACTION, OnBridgeItemAction);
			if (_tlst) _tlst.addEventListener(MouseEvent.DOUBLE_CLICK, OnTileListDoubleClick);
			if (_tlst) _tlst.addEventListener(CollectionEvent.COLLECTION_CHANGE, OnCollectionChange);
			if (_cboxFriends) _cboxFriends.addEventListener(Event.CHANGE, OnFriendsComboChange);
			if (_cboxOrderBy) _cboxOrderBy.addEventListener(Event.CHANGE, OnOrderByComboChange);
			if (_lbGreeting) _lbGreeting.addEventListener(MouseEvent.CLICK, OnGreetingClick);
			if (_imgUserThumbnail) _imgUserThumbnail.addEventListener(MouseEvent.CLICK, OnGreetingClick);
			if (_imgSet) _imgSet.addEventListener(MouseEvent.CLICK, OnSetClick);
			if (_tiFilter) _tiFilter.addEventListener(FlexEvent.ENTER, OnFilterEnter);
			if (_tiFilter) _tiFilter.addEventListener(MouseEvent.CLICK, OnFilterClick);
			if (_btnSearch) _btnSearch.addEventListener(MouseEvent.CLICK, OnSearchClick);
			
			OnCollectionChange();
		}
		
		private function OnCollectionChange(evt:Event=null): void {
			collection = _tlst ? _tlst.dataProvider as ICollectionView : null;
		}
		
		[Bindable]
		public function set collection(coll:ICollectionView): void {
			_coll = coll;
		}
		public function get collection(): ICollectionView {
			return _coll;
		}
	
		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
			
			if (_tiFilter && _tiFilter.text == "")
				_tiFilter.text = kstrSearchPrompt;	
			
			if (_ss.IsLoggedIn()) {
				currentState = GetState();
			}
		}
		
		override protected function OnUserChange(evt:AccountEvent): void {
			if (_ss.IsLoggedIn()) {
				currentState = GetState();
			} else {
				if (currentState != GetSignedOutState())
					currentState = GetSignedOutState();
			}
			RefreshItemList(true);
		}				
		
		// This is meant to be overridden by subclasses		
		// It should return whatever state we want after we are authorized
		override protected function GetState(): String {
			if (_fNoItems) {
				if (HasSearchString()) return "NoImagesWithSearch";
				else return "NoImages";
			}
			else return "";
		}					
				
		public override function GetMenuItems(): Array {
			var aitm:Array = super.GetMenuItems();
			aitm.push(Bridge.OPEN_ITEMS_WEBPAGE);
			return aitm;
		}
		
		private function OnTileListDoubleClick(evt:MouseEvent): void {
			HideTip();
		}
		
		// UNDONE: Generalize the tip system
		protected function HideTip(): void {
			if (_hbxTip && _hbxTip.parent) {
				_vbxMain.removeChild(_hbxTip);
				AccountMgr.GetInstance().SetUserAttribute("bridges.fDoubleClickThumbnailTipClosed", true);
			}
		}
		
		override protected function OnCurrentStateChange(evt:StateChangeEvent): void {
			super.OnCurrentStateChange(evt);
			if (evt.newState == "" && AccountMgr.GetInstance().GetUserAttribute("bridges.fDoubleClickThumbnailTipClosed", false))
				HideTip();
		}
			
		private function OnFilterEnter(evt:FlexEvent): void {
			RefreshItemList();
		}

		private function OnSearchClick(evt:Event): void {
			RefreshItemList(true);
		}

		private function OnFilterClick(evt:MouseEvent): void {
			if (_tiFilter && _tiFilter.text == kstrSearchPrompt)
				_tiFilter.text = "";
		}
					
		private function HasSearchString(): Boolean {
			return _tiFilter && _tiFilter.enabled && _tiFilter.text != "" && _tiFilter.text != kstrSearchPrompt;
		}
		
		protected override function OnMenuItemClick(evt:ItemClickEvent): void {
			if (evt.item && ('id' in evt.item) && evt.item.id == "visitwebsite") {
				OpenBridgeWebpage();
			} else {
				super.OnMenuItemClick(evt);
			}
		}

		protected function OpenBridgeWebpage(): void {
			if (_dctUserInfo && _dctUserInfo.webpageurl)
				PicnikBase.app.NavigateToURL(new URLRequest(_dctUserInfo.webpageurl), "_blank");
		}
		
		private function OnGreetingClick(evt:MouseEvent): void {
			OpenBridgeWebpage();
		}
		
		private function OnSetClick(evt:MouseEvent): void {
			var dctSetInfo:Object = (_cboxSets.selectedItem as StorageServiceSetComboItem).setinfo;
			if (dctSetInfo && dctSetInfo.webpageurl)
				PicnikBase.app.NavigateToURL(new URLRequest(dctSetInfo.webpageurl), "_blank");
		}
		
		protected function OnBridgeItemAction(evt:BridgeItemEvent): void {
			var item:ItemInfo = evt.bridgeItem.data as ItemInfo;

			switch (evt.action) {
			case Bridge.EDIT_ITEM:
			case Bridge.EDIT_GALLERY:
			case Bridge.EMAIL_ITEM:
			case Bridge.DOWNLOAD_ITEM:
				_strCurrentAction = evt.action; // Remember where we are going
				DownloadItem(item); // Email and download start by getting the image.
				break;

			case Bridge.EMAIL_GALLERY:
			case Bridge.SHARE_GALLERY:
				DialogManager.Show("ShareContentDialog", null, null, {item:item})
				break;
				
			case Bridge.RENAME_ITEM:
				// Do nothing for rename - let the bridge item handle it
				break;
				
			case Bridge.COMMIT_RENAME_ITEM:
				RenamePhoto(item, evt.data as String, evt.bridgeItem);
				break;
				
			case Bridge.DELETE_GALLERY:
				DeleteGallery(item, evt.bridgeItem);
				break;
				
			case Bridge.DELETE_ITEM:
				DeletePhoto(item, evt.bridgeItem);
				break;
				
			case Bridge.OPEN_ITEMS_WEBPAGE:
				PicnikBase.app.NavigateToURL(new URLRequest(item.webpageurl), "_blank");
				break;
				
			case Bridge.PUBLISH_TEMPLATE:
				DialogManager.Show('PublishTemplateDialog', null, null, { imgp: item.asImageProperties() });
				break;
				
			case Bridge.ADD_GALLERY_ITEM:
				addGalleryItem(evt);
				break;
				
			case Bridge.LAUNCH_GALLERY:
				PicnikBase.app.NavigateToURL(new URLRequest(item.webpageurl), "_blank");
				break;
			}
		}
					
		// Initiate the delete process by throwing up a confirmation dialog
		protected function DeletePhoto(itemInfo:ItemInfo, britm:BridgeItemBase): void {
			_obDeleteCallbackData = { itemInfo:itemInfo, britm:britm };
			var fnCallback:Function = function(obResult:Object): void {
				DoDeletePhoto(obResult, itemInfo);
			}
			DialogManager.Show("ConfirmDeleteDialog", PicnikBase.app, fnCallback, { iinfo: itemInfo });
		}
		
		// Continue the delete process. Confirm dialog callback function.
		private function DoDeletePhoto(obResult:Object, itemInfo:ItemInfo): void {
			if (!obResult.success) {
				// They canceled the delete. Do nothing.
			} else {
				// Do the delete.
				_fPendingRefresh = true; // wait on refreshes
				if (_bsy != null) _bsy.Hide();
				_bsy = BusyDialogBase.Show(this, Resource.getString("StorageServiceInBridgeBase", "Deleting"), BusyDialogBase.DELETE, "IndeterminateNoCancel", 0);
				
				var fnOnDelete:Function = function(err:Number, strError:String/*, itemInfo:ItemInfo*/): void {
					DeletePhotoComplete(err, strError, itemInfo);
				}
				
				_ss.DeleteItem(itemInfo./*ss_*/setid, itemInfo./*ss_item*/id, fnOnDelete);
				
				PicnikService.Log("StorageServiceInBridge deleting item id: " + itemInfo./*ss_item*/id);
			}
		}

		// Finish the delete process. Callback for storage service delete function		
		private function DeletePhotoComplete(err:Number, strError:String, itemInfo:ItemInfo): void {
			// Image deleted
			_fPendingRefresh = false;
			if (_bsy) {
				_bsy.Hide();	
				_bsy = null;
			}
			if (err != StorageServiceError.None) {
				Util.ShowAlert( Resource.getString("StorageServiceInBridgeBase", "unable_to_delete"), Resource.getString("StorageServiceInBridgeBase", "Error"), Alert.OK,
						"ERROR:in.bridge." + String(_ss.GetServiceInfo().id).toLowerCase() + ".delete: " + err + ", " + strError);
			} else { // Delete worked
				var aob:ArrayCollection = ArrayCollection(_tlst.dataProvider);
				var iData:Number = aob.getItemIndex(itemInfo);
				if (iData > -1) {
					aob.removeItemAt(iData);
					if (aob.length == 0) {
						_fNoItems = true;
						UpdateState();
					} else {
						SmartUpdateDataProvider(aob.source,_tlst);
					}
				} else {
					RefreshItemList(); // Fallback plan: If we can't find the image, use brute force
				}
				RefreshStoreInfo(); // Update photo counts
			}
			_obDeleteCallbackData = null;			
		}

		// Initiate the delete process by throwing up a confirmation dialog
		protected function DeleteGallery(itemInfo:ItemInfo, britm:BridgeItemBase): void {
			_obDeleteCallbackData = { itemInfo:itemInfo, britm:britm };
			var isDeletingOpenDocument:Boolean = (doc != null && doc is GalleryDocument &&
				(doc as GalleryDocument).id == itemInfo.id);
			var fnCallback:Function = function(obResult:Object): void {
				DoDeleteGallery(obResult, itemInfo);
			}
			DialogManager.Show("ConfirmDeleteDialog", PicnikBase.app, fnCallback,
					{ iinfo: itemInfo,
					  isDeletingOpenDocument: isDeletingOpenDocument });
		}
		
		// Continue the delete process. Confirm dialog callback function.
		private function DoDeleteGallery(obResult:Object, itemInfo:ItemInfo): void {
			if (!obResult.success) {
				// They canceled the delete. Do nothing.
			} else {
				// Do the delete.
				_fPendingRefresh = true; // wait on refreshes
				if (_bsy != null) _bsy.Hide();
				_bsy = BusyDialogBase.Show(this, Resource.getString("StorageServiceInBridgeBase", "Deleting"), BusyDialogBase.DELETE, "IndeterminateNoCancel", 0);
				
				var fnOnDelete:Function = function(err:Number, strError:String, adctSetInfos:Array): void {
					DeleteGalleryComplete(err, strError, adctSetInfos);
				}
				
				_ss.DeleteSet(itemInfo./*ss_*/id, fnOnDelete);
				
				PicnikService.Log("StorageServiceInBridge deleting item id: " + itemInfo./*ss_item*/id);
			}
		}

		// Finish the delete process. Callback for storage service delete function		
		private function DeleteGalleryComplete(err:Number, strError:String, adctSetInfos:Array): void {
			// Image deleted
			_fPendingRefresh = false;
			if (_bsy) {
				_bsy.Hide();	
				_bsy = null;
			}
			if (err != StorageServiceError.None) {
				Util.ShowAlert( Resource.getString("StorageServiceInBridgeBase", "unable_to_delete"), Resource.getString("StorageServiceInBridgeBase", "Error"), Alert.OK,
						"ERROR:in.bridge." + String(_ss.GetServiceInfo().id).toLowerCase() + ".delete: " + err + ", " + strError);
			} else { // Delete worked
				var aob:ArrayCollection = ArrayCollection(_tlst.dataProvider);
				var lenOld:int = aob.length;
				aob.removeAll();
				for each (var dctSetInfos:Object in adctSetInfos) {
					aob.addItem(dctSetInfos);
				}
				if (aob.length != lenOld) {
					if (aob.length == 0) {
						_fNoItems = true;
						UpdateState();
					} else {
						SmartUpdateDataProvider(aob.source,_tlst);
					}
				} else {
					RefreshItemList(); // Fallback plan: If we can't find the image, use brute force
				}
				RefreshStoreInfo(); // Update photo counts
			}
			_obDeleteCallbackData = null;			
		}


		// Rename an image
		// If we are missing the description, we will call get info which will
		// call back into this function (sort of recursively - ugh)
		protected function RenamePhoto(itemInfo:ItemInfo, strNewName:String, britm:BridgeItemBase): void {
			if (_bsy == null) _bsy = BusyDialogBase.Show(this, Resource.getString("StorageServiceInBridgeBase", "Renaming"), BusyDialogBase.RENAME, "IndeterminateNoCancel", 0);

			_obRenameCallbackData = {strNewName:strNewName, britm:britm};
			PicnikService.Log("StorageServiceInBridge renaming photo id: " + itemInfo./*ss_item*/id + " to: " + strNewName);
			_ss.SetItemInfo(itemInfo./*ss_*/setid, itemInfo./*ss_item*/id, new ItemInfo( { title: strNewName, description: itemInfo.description } ), RenamePhotoComplete);
		}
		
		protected var _obRenameCallbackData:Object = null;
		
		// Second rename callback - the result of setting the name
		protected function RenamePhotoComplete(err:Number, strError:String): void {
			if (_bsy != null) {
				_bsy.Hide();
				_bsy = null;
			}
			var britm:BridgeItemBase = _obRenameCallbackData.britm;
			if (err != StorageServiceError.None) {
				Util.ShowAlert(Resource.getString("StorageServiceInBridgeBase", "unable_to_rename"), Resource.getString("StorageServiceInBridgeBase", "Error"), Alert.OK,
						"ERROR:in.bridge." + String(_ss.GetServiceInfo().id).toLowerCase() + ".rename: " + err + ", " + strError);
				britm._tiName.text = britm.data.title;
			} else {
				britm.data.title = _obRenameCallbackData.strNewName;
			}
			if (_tlst.selectedItem == britm.data)
				_tlst.selectedBridgeItem.setFocus(); // Make sure we set the focus out
		}

		override protected function OnSetsComboChange(evt:Event): void {
			super.OnSetsComboChange(evt);
			RefreshItemList(true);
		}
		
		private function OnFriendsComboChange(evt:Event): void {
			_strSelectedFriendID = (_cboxFriends.selectedItem as StorageServiceFriendComboItem).friendInfo.uid;
			RefreshSets();
		}
		
		private function OnOrderByComboChange(evt:Event): void {
			RefreshItemList();
		}
		
		override protected function get storeIsOff():Boolean {
			return (_tlst == null);
		}
		
		protected function OnItemListChanging(strSetId:String, strSort:String, strFilter:String): void {
			// Override in sub-classes as needed
			// Useful when your GetItems() calls are very slow
			// In this case, RefreshItemList is called, we get a new batch, and then
			// wait for the previous call to return before calling GetItems again
			// Used by YMail
		}
		
		private function GetSetId(): String {
			var strSetId:String = null;
			if (_adctSetInfos != null && _adctSetInfos.length > 0)
				strSetId = _adctSetInfos[0].id;
			if (_cboxSets != null && _cboxSets.selectedItem && _cboxSets.selectedItem.setinfo)
				strSetId = _cboxSets.selectedItem.setinfo.id;
			return strSetId;
		}
		
		private function GetSortOder(): String {
			return (_cboxOrderBy && _cboxOrderBy.selectedItem) ? _cboxOrderBy.selectedItem.data : null;
		}
		
		private function GetFilter(): String {
			return HasSearchString() ? _tiFilter.text : null;
		}
		
		protected function PrepareBatch(obBatch:Object): void {
			// Do nothing. Override in sub-classes as needed
		}
		
		protected function RefreshItemList(fReset:Boolean=false): void {
			if (storeIsOff) {
				SetItemList([]); // No sets, no images.
				return;
			}
			
			if (!active || _fPendingRefresh)
				return;

			StartSlowGetItemsTimer();				

			OnItemListChanging(GetSetId(), GetSortOder(), GetFilter());
				
			if (_fRefreshingItemList) {
				_fItemListDirty = true;
				// Clear the item list right away so the UI feels responsive and do it
				// this way rather than through SetItemList so the UI state doesn't change
				// to the "you have no photos" state.
				_tlst.dataProvider = [];
				return;
			}
			
			if (fReset) {
				_tlst.dataProvider = [];
				currentState = "";
			}
				
			if (_adctSetInfos && _adctSetInfos.length > 0) {
				var obBatch:Object = {
					strSortOrder: GetSortOder(),
					strSetId: GetSetId(),
					strFilter: GetFilter(),
					aitemInfos: new Array(),
					fNewList: fReset || _tlst.dataProvider == null || _tlst.dataProvider.length == 0
				}
				PrepareBatch(obBatch);
				_obBatchInProgress = obBatch;
				_fRefreshingItemList = true;
				ShowBusy();
				
				var fnOnAllDone:Function = function(): void {
					StopSlowGetItemsTimer();
					HideBusy();
					_fRefreshingItemList = false;
					if (_fItemListDirty) {
						_fItemListDirty = false;
						RefreshItemList(fReset);
					}
				}

				GetNextBatchOfItems(obBatch, fnOnAllDone);
			} else {
				SetItemList([]); // No sets, no items.
			}
		}
		
		// fnAllDone is called when the last batch has been fetched, looks like this:
		// fnAllDone(): void {}
		private function GetNextBatchOfItems(obBatch:Object, fnAllDone:Function): void {
			// We use this nested function as a closure that binds together
			// obBatch and GetItems's callback function
			var fnOnGetItems:Function = function (err:Number, strError:String, aitemInfos:Array=null): void {
				if (err != StorageServiceError.None) {
					Util.ShowAlert( Resource.getString("StorageServiceInBridgeBase", "unable_to_get_picture_list"), Resource.getString("StorageServiceInBridgeBase", "Error"), Alert.OK,
							"ERROR:in.bridge." + String(_ss.GetServiceInfo().id).toLowerCase() + ".getitems: " + err + ", " + strError);
					fnAllDone();
					return;
				}
				
				// Interrupt batching if some other change (e.g. switch to new set) requires a new list of items
				if (_fItemListDirty || !active) {
					_obBatchInProgress = null;
					fnAllDone();
					return;
				}
			
				// Discontinue batch if it has been superceded by a new one
				if (_obBatchInProgress != obBatch)
					return;
				
				var fOverwrite:Boolean = ('fOverwrite' in obBatch && obBatch.fOverwrite == true);
				if (!fOverwrite && obBatch.fNewList)
					SetItemList(aitemInfos, true);

				if (fOverwrite)
					OverwriteItemList(aitemInfos, obBatch.aitemInfos.length);
					
				obBatch.aitemInfos = obBatch.aitemInfos.concat(aitemInfos);

				if (aitemInfos.length > 0)
					StopSlowGetItemsTimer();

				if (aitemInfos.length == batchSize) {
					GetNextBatchOfItems(obBatch, fnAllDone);
				} else {
					if (!obBatch.fNewList && !fOverwrite)
						SetItemList(obBatch.aitemInfos);
					_obBatchInProgress = null;
					fnAllDone();
				}
			}
			
			_ss.GetItems(obBatch.strSetId, obBatch.strSortOrder, obBatch.strFilter, obBatch.aitemInfos.length, batchSize, fnOnGetItems);
		}
		
		private function ItemsEqual(obItem1:Object, obItem2:Object): Boolean {
			return (obItem1.title == obItem2.title) && (obItem1.thumbnailurl == obItem2.thumbnailurl);
		}
		
		// Overwrite items in our list - leave items before and after alone
		private function OverwriteItemList(aitemInfos:Array, nOffset:Number): void {
			if (_tlst.dataProvider == null) {
				_tlst.dataProvider = aitemInfos;
			} else {
				var acOut:ArrayCollection = ArrayCollection(_tlst.dataProvider);
				for (var i:Number = 0; i < aitemInfos.length; i++) {
					var j:Number = i + nOffset;
					if (acOut.length <= j) {
						acOut.addItem(aitemInfos[i]);
					} else if (!ItemsEqual(aitemInfos[i], acOut.getItemAt(j))) { 
						acOut.setItemAt(aitemInfos[i], j);
					}
				}
			}
		}
		
		protected function FilterItemList(aitemInfos:Array): Array {
			return aitemInfos;	
		}
		
		// SetItemList can be called iteratively to build up the item list as items are received from the StorageService.
		// SetItemList(list) -- Smart update new list into existing list
		// SetItemList(list, true) -- Append items to existing list
		protected function SetItemList(aitemInfo:Array, fAppend:Boolean=false): void {
			aitemInfo = FilterItemList(aitemInfo);
			if (_tlst) {
				if (fAppend) {
					if (_tlst.dataProvider == null)
						_tlst.dataProvider = [];
					for each (var tmi:ItemInfo in aitemInfo)
						_tlst.dataProvider.addItem(tmi);
				} else {
					SmartUpdateDataProvider(aitemInfo, _tlst, false); // Update rather than replace to minimize screen updates
				}
			}
			
			_fNoItems = _tlst == null || _tlst.dataProvider == null || _tlst.dataProvider.length == 0;
			UpdateState();
		}

		private function DownloadItem(itemInfo:ItemInfo): void {
			_itemInfo = itemInfo;
			ValidateOverwrite(DoDownloadItem);
		}
		
		// alternate entry point for downloading: don't bother with validating overwrite,
		// and presume that itemInfo is already fully populated.  Used by
		// GalleryOutBridgeBase.PostSaveAction to load the gallery the user just created.		
		public function DownloadItemDirect(itemInfo:ItemInfo, strCurrentAction:String=null): void {
			if (strCurrentAction != null)
				_strCurrentAction = strCurrentAction;
			DoDownloadItem2(itemInfo);
		}

		private function DoDownloadItem(): void {
			_bsy = BusyDialogBase.Show(UIComponent(Application.application), Resource.getString("StorageServiceInBridgeBase", "Loading"), BusyDialogBase.LOAD_USER_IMAGE, "ProgressWithCancel", 0, OnDownloadCancel);
			
			// OPT: don't bother with this if we already have all the item info we need
			_canDownloadOp = new Cancelable( this, OnGetItemInfo );
			if (_itemInfo.species != "gallery")
				_ss.GetItemInfo(_itemInfo.setid, _itemInfo.id, _canDownloadOp.callback );
			else
				_ss.GetSetInfo( _itemInfo.id, _canDownloadOp.callback );
		}

		private function OnGetItemInfo(err:Number, strError:String, itemInfo:ItemInfo=null): void {
			if (err != StorageServiceError.None) {
				Util.ShowAlert( Resource.getString("StorageServiceInBridgeBase", "unable_to_get_photo_info"), Resource.getString("StorageServiceInBridgeBase", "Error"), Alert.OK,
						"ERROR:in.bridge." + String(_ss.GetServiceInfo().id).toLowerCase() + ".getinfo: " + err + ", " + strError);
				if (_bsy) _bsy.Hide();
				_bsy = null;
				return;
			}
			DoDownloadItem2(itemInfo);
		}

		private function DoDownloadItem2(itemInfo:ItemInfo): void {
			var pf:IPendingFile;
						
			_itemInfo = itemInfo;	// formerly, we constructed a copy.  Now we just pass the original instance
			if (_itemInfo.species == "gallery") {
				_gald = new GalleryDocument();

				pf = ImagePropertiesUtil.GetPendingFile(_itemInfo);
				
				var fnOnPendingFileStatusUpdate1:Function = function(evt:Event=null): void {
					if (pf.status != DocumentStatus.Loading) {
						_canDownloadOp = new Cancelable(this, OnInitFromIdDone);
						_gald.InitFromPicnikFile(itemInfo, OnInitFromIdProgress, _canDownloadOp.callback);
					}
				}
				
				if (pf.status == DocumentStatus.Loading) {
					// The file is not ready for reference. Wait for it.
					// Ideally, we would use this to update our progress. For now, just wait for it.
					pf.addEventListener("statusupdate", fnOnPendingFileStatusUpdate1);
				} else {
					fnOnPendingFileStatusUpdate1();
				}
	
			} else {
				_imgd = new ImageDocument();
	
				var fnOnInitFromPicnikFileDone2:Function = function (err:Number, strError:String): void {
					if (_bsy) _bsy.Hide();
					_bsy = null;
					
					if (err == ImageDocument.errNewerFlashPlayerRequired) {
						ShowRequiresNewerFlashPlayerDialog("documentrequires");
					} else if (err != ImageDocument.errNone) {
						Util.ShowAlert(Resource.getString("StorageServiceInBridgeBase", "failed_to_download"), Resource.getString("StorageServiceInBridgeBase", "Error"), Alert.OK,
								"ERROR:in.bridge." + String(_ss.GetServiceInfo().id).toLowerCase() + ".initfrompik: " + err + ", " + strError);
					} else {
						ReportSuccess(null, "download");				
						PicnikService.Log(_ss.GetServiceInfo().id + " StorageServiceInBridge loaded " +
								_ss.GetServiceInfo().id + "_" + _itemInfo./*ss_item*/id);
						PicnikBase.app.activeDocument = _imgd;
						
						// Go to the next destination:
						NavigateToAction(_strCurrentAction);
					}
				}
				
				pf = ImagePropertiesUtil.GetPendingFile(_itemInfo);
				
				var fnOnPendingFileStatusUpdate2:Function = function(evt:Event=null): void {
					if (pf.status != DocumentStatus.Loading) {
						if (("fUseExistingFid" in itemInfo) && itemInfo.fUseExistingFid) {
							// The fid we have is a pointer to an existing image file.
							// Make a clone of the fid and use that for our loaded file.
							_canDownloadOp = new Cancelable(this, OnDownloadDone);
							var dnldr:Downloader = new Downloader(_itemInfo, "/" + _ss.GetServiceInfo().id + "InBridge",
									_canDownloadOp.callback, OnDownloadProgress);
							dnldr.fid = itemInfo.id;
							dnldr.Start();
							PicnikService.Log(_ss.GetServiceInfo().id + " StorageServiceInBridge loading " + _itemInfo.sourceurl);
							
						// If the iteminfo has a pikid, we can load the .pik file from our server!
						// This is true for the History bridge and (someday) for all images backed
						// by Perfect Memory. Also true for most items from the PicnikStorageService.
						} else if ("pikid" in itemInfo) {
							_canDownloadOp = new Cancelable(this, fnOnInitFromPicnikFileDone2);
							_imgd.InitFromPicnikFile(itemInfo.pikid, itemInfo.assetmap, _itemInfo.asImageProperties(),
									OnInitFromIdProgress, _canDownloadOp.callback, _ss.GetServiceInfo().id);
							
						} else {
							var fnOnGetPerfectMemoryFid:Function = function (err:Number, strError:String, fid:String=null, strAssetMap:String=null): void {
								// BUGBUG: handle err
								
								if (fid != null) {
									_canDownloadOp = new Cancelable(this, fnOnInitFromPicnikFileDone2);
									_imgd.InitFromPicnikFile(fid, strAssetMap, _itemInfo.asImageProperties(),
											OnInitFromIdProgress, _canDownloadOp.callback, _ss.GetServiceInfo().id);
								} else {
									// UNDONE: old-style perfect memory lookup. Remove after build xx when old perfect memory
									// files are migrated and GetPerfectMemoryFid does the fallback handling (use update_date
									// when etag lookup fails).
									// Test to see if there is a Perfect Memory .pik file corresponding to this item
									_canDownloadOp = new Cancelable(this, OnInitFromIdDone);
									var strImageID:String = itemInfo.serviceid + "_" + _itemInfo./*ss_item*/id;
									_imgd.InitFromIdWithMetadata(strImageID, _itemInfo.asImageProperties(),
											OnInitFromIdProgress, _canDownloadOp.callback);
								}
							}
			
							// Test to see if there is a new style Perfect Memory .pik file corresponding to this item
							StorageServiceUtil.GetPerfectMemoryFid(itemInfo.serviceid, _itemInfo./*ss_item*/id, _itemInfo.etag, fnOnGetPerfectMemoryFid);
						}
					}
				}
				
				if (pf.status == DocumentStatus.Loading) {
					// The file is not ready for reference. Wait for it.
					// Ideally, we would use this to update our progress. For now, just wait for it.
					pf.addEventListener("statusupdate", fnOnPendingFileStatusUpdate2);
				} else {
					fnOnPendingFileStatusUpdate2();
				}
			} // if (_itemInfo.species != 'show' && _itemInfo.species != "gallery")
		}
		
		private function OnInitFromIdProgress(nPercentDone:Number, strStatus:String): void {
			if (_bsy) _bsy.progress = nPercentDone;
		}
		
		private function OnInitFromIdDone(nError:Number, strError:String=null, xml:XML=null): void {
			if (nError == GalleryDocument.errDisabled) {
				OnDownloadDone(nError, strError, null);
				return;				
			}
			if (nError != 0) {
				// No .pik file has been associated with this item, continue loading
				// it straight from the storage service.
				
				_canDownloadOp = new Cancelable(this, OnDownloadDone);
				var dnldr:Downloader = new Downloader(_itemInfo, "/" + _ss.GetServiceInfo().id + "InBridge",
						_canDownloadOp.callback, OnDownloadProgress);
				dnldr.Start();
				PicnikService.Log(_ss.GetServiceInfo().id + " StorageServiceInBridge loading " + _itemInfo.sourceurl);
			} else {
				ReportSuccess("/with_perfectmemory", "download");
				if (_ss != null)				
					PicnikService.Log(_ss.GetServiceInfo().id + " StorageServiceInBridge loaded " +
							_ss.GetServiceInfo().id + "_" + _itemInfo./*ss_item*/id + ", shadow of " + _itemInfo.sourceurl);
				if (_bsy) _bsy.Hide();
				_bsy = null;
				PicnikBase.app.activeDocument = _gald;
				
				// Go to the next destination:
				if (_itemInfo.species == "show" || _itemInfo.species == "gallery") {
					if (_strCurrentAction == Bridge.EDIT_ITEM)
						_strCurrentAction = Bridge.EDIT_GALLERY;		// sometimes we enter with this as EDIT_ITEM
 					else if (_strCurrentAction == Bridge.EMAIL_ITEM)
 						_strCurrentAction = Bridge.EMAIL_GALLERY;
 				}
				NavigateToAction(_strCurrentAction);
			}
		}
		
		private function OnDownloadCancel(dctResult:Object): void {
			if (_bsy) {
				_bsy.Hide();
				_bsy = null;
			}
			
			// this will cancel any callbacks from coming through
			if (_canDownloadOp) _canDownloadOp.Cancel();
		}
		
		private function OnDownloadProgress(strStatus:String, nFractionDone:Number): void {
			if (_bsy)
				_bsy.progress = nFractionDone * 100;
		}
		
		private function OnDownloadDone(err:Number, strError:String, dnldr:FileTransferBase): void {
			// we'll only process the "OnDownloadDone" if the _bsy box is still around. 
			// if it's not around, then we've been cancelled.
			if (_bsy) {
				_bsy.Hide();
				_bsy = null;
				if (err != GenericDocument.errNone) {
					if (err == ImageDocument.errNewerFlashPlayerRequired) {
						ShowRequiresNewerFlashPlayerDialog("imagerequires");
					} else if (err == GalleryDocument.errDisabled) {
						var dlg:EasyDialog =
							EasyDialogBase.Show(
								this,
								[Resource.getString('Picnik', 'ok')],
								Resource.getString('Picnik', 'no_gallery_create_title'),						
								Resource.getString('Picnik', 'no_gallery_create_message'));	
					} else {
						if (_gald != null) {
							Util.ShowAlert(Resource.getString("StorageServiceInBridgeBase", "failed_to_download_show"),
									Resource.getString("StorageServiceInBridgeBase", "Error"), Alert.OK,
									"ERROR:in.bridge." + String(_ss.GetServiceInfo().id).toLowerCase() + ".download: " + err + ", " + strError);
						} else {
							Util.ShowAlert(Resource.getString("StorageServiceInBridgeBase", "failed_to_download"),
									Resource.getString("StorageServiceInBridgeBase", "Error"), Alert.OK,
									"ERROR:in.bridge." + String(_ss.GetServiceInfo().id).toLowerCase() + ".download: " + err + ", " + strError);							
						}
					}
					return;
				}
				
				if (dnldr != null) {
					ReportSuccess("/without_perfectmemory", "import");
					PicnikBase.app.activeDocument = dnldr.imgd;
										
					// Go to the next destination:
					NavigateToAction(_strCurrentAction);
				}
			}
		}
		
		override protected function OnSetsRefreshed(): void {
			super.OnSetsRefreshed();
			if (_cboxSets) {
				var cmboi:StorageServiceSetComboItem = _cboxSets.selectedItem as StorageServiceSetComboItem;
				if (cmboi) {
					var dctSetInfo:Object = cmboi.setinfo;
					if (_imgSet) _imgSet.useHandCursor = (dctSetInfo && dctSetInfo.webpageurl);
				}
			}
			RefreshItemList();
		}

		override protected function OnUserInfoRefreshed(): void {
			var dctUserInfo:Object = _dctUserInfo;
			var strName:String = dctUserInfo.fullname ? dctUserInfo.fullname : dctUserInfo.username;
			// UNDONE: MXML-ize this
			if (_lbGreeting)
				_lbGreeting.text = StringUtil.substitute(Resource.getString("StorageServiceInBridgeBase", "greeting"), strName);
			
			if (dctUserInfo.thumbnailurl && _imgUserThumbnail)
				_imgUserThumbnail.source = dctUserInfo.thumbnailurl;
		}
		
		static private function ShowRequiresNewerFlashPlayerDialog(strReason:String): void {
			var fnOnDialogResult:Function = function (obResult:Object): void {
				if (obResult.success)
					Navigation.NavigateToFlashUpgrade(strReason);							
			}
			
			var dlg:EasyDialog = EasyDialogBase.Show(PicnikBase.app,
					[Resource.getString("StorageServiceInBridgeBase", "upgrade"),Resource.getString("StorageServiceInBridgeBase", "cancel")],
					Resource.getString("StorageServiceInBridgeBase", "requires_new_flash_player_title"),						
					Resource.getString("StorageServiceInBridgeBase", "requires_new_flash_player_message"),
					fnOnDialogResult);
		}
		
		//
		// If GetItems is taking a long time display a friendly please wait message to the user
		// by setting the Bridge state to "SlowGetItems". This state is optional, some bridges
		// have it (e.g. Yahoo! Mail), some don't.
		//
		
		private var _tmrSlowGetItems:Timer;
		private static const kcmsSlowGetItems:Number = 4000; // 4 seconds
		
		private function StartSlowGetItemsTimer(): void {
			if (_tmrSlowGetItems) {
				_tmrSlowGetItems.reset();
			} else {
				_tmrSlowGetItems = new Timer(kcmsSlowGetItems, 1);
				_tmrSlowGetItems.addEventListener(TimerEvent.TIMER_COMPLETE, OnSlowGetItemsTimerComplete);
				_tmrSlowGetItems.start();
			}
		}
		
		private function StopSlowGetItemsTimer(): void {
			if (_tmrSlowGetItems) {
				_tmrSlowGetItems.stop();
				_tmrSlowGetItems = null;
			}
			if (currentState == "SlowGetItems")
				currentState = "";
		}
		
		private function OnSlowGetItemsTimerComplete(evt:TimerEvent): void {
			if (_tlst.dataProvider == null || _tlst.dataProvider.length == 0) {
				// This state is optional. Some bridges have it (e.g. Yahoo! Mail), some don't.
				for each (var state:State in states) {
					if (state.name == "SlowGetItems")
						currentState = "SlowGetItems";
				}
			}
		}
	}
}
