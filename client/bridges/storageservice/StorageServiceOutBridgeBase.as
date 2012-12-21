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

	import bridges.OutBridge;
	
	import controls.TextAreaPlus;
	
	import dialogs.BusyDialogBase;
	import dialogs.DialogManager;
	import dialogs.EasyDialog;
	import dialogs.EasyDialogBase;
	
	import events.AccountEvent;
	import events.ActiveDocumentEvent;
	
	import flash.events.*;
	
	import imagine.ImageDocument;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.RadioButton;
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
	import mx.utils.StringUtil;
	
	import util.LocUtil;
	
	public class StorageServiceOutBridgeBase extends StorageServiceBridgeBase {
		// MXML-specified variables
		[Bindable] public var _imgvPreview:ImageView;
		[Bindable] public var _btnSave:Button;
		[Bindable] public var _taItemId:TextAreaPlus;		
		[Bindable] public var _taTitle:TextAreaPlus;
		[Bindable] public var _taDescription:TextAreaPlus;
		[Bindable] public var _taTags:TextAreaPlus;
		[Bindable] public var _rbtnPublic:RadioButton;
		[Bindable] public var _rbtnPrivate:RadioButton;
		[Bindable] public var _chkbPicnikTag:CheckBox;
		[Bindable] public var _chkbFriends:CheckBox;
		[Bindable] public var _chkbFamily:CheckBox;
		[Bindable] public var _rbtnSaveNew:RadioButton;
		[Bindable] public var _btnCreateAlbum:Button;
		[ResourceBundle("StorageServiceOutBridgeBase")] private var _rb:ResourceBundle;

		private var _obSaveParams:Object;
		protected var _originalItemInfo:ItemInfo;
		
		public function StorageServiceOutBridgeBase() {
			super();
		}
		
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			if (_btnSave) _btnSave.addEventListener(MouseEvent.CLICK, OnSaveClick);
			if (_btnCreateAlbum) _btnCreateAlbum.addEventListener(MouseEvent.CLICK, OnCreateAlbumClick);
			if (_chkbPicnikTag) _chkbPicnikTag.selected = _tpa.GetAttribute("_fTagWithPicnik", true);
		}
		
		override public function OnActivate(strCmd:String=null): void {
			// We keep track of the active document because application state
			// restoration may bring us to this bridge BEFORE the current image
			// has finished loading. Once it has loaded we want to update the
			// preview, etc
						
			// We do this last because it may cause a state change that would remove
			// the controls we're fiddling with above!
			super.OnActivate(strCmd);			
		}
		
		override public function OnDeactivate(): void {
			super.OnDeactivate();
			if (_imgvPreview) _imgvPreview.imageDocument = null;
			if (_chkbPicnikTag) _tpa.SetAttribute("_fTagWithPicnik", _chkbPicnikTag.selected, true);
		}

		override protected function OnActiveDocumentChange(evt:ActiveDocumentEvent): void {
			super.OnActiveDocumentChange(evt);
			_originalItemInfo = null;
			
			if( _imgvPreview) _imgvPreview.imageDocument = _imgd;
			if (_imgd != null) {
				// Some service-specific in-bridges will have titles, others will have
				// descriptions, and others will have both or neither. We set the focus
				// to title if it's there, otherwise description.
				var ta:TextAreaPlus = _taTitle ? _taTitle : _taDescription;
				if (ta && ta.enabled && ta.focusManager) {
					ta.setFocus();
					ta.setSelection(0, ta.text.length);
				}
				// Select the album for this image
				var imgp:Object = _imgd.properties;
				if (imgp && imgp./*ss_*/setid) { // If we have properties and a set id
					_strSelectedSetID = imgp./*ss_*/setid;
					if (_cboxSets != null) {
						for each (var itm:StorageServiceSetComboItem in (_cboxSets.dataProvider as ArrayCollection)) {
							if (itm && itm.setinfo && (itm.setinfo.id == imgp./*ss_*/setid)) {
								_cboxSets.selectedItem = itm;
								break;
							}
						}
					}
				}
				
				UpdateOverwriteState();
			}
		}
		
		override protected function OnUserInfoRefreshed(): void {
			super.OnUserInfoRefreshed();
			UpdateOverwriteState();
		}
		
		override protected function OnUserChange(evt:AccountEvent): void {
			UpdateState();
		}						
		
		// Filter out read-only sets
		override protected function OnSetsRefreshed(): void {
			for (var i:Number = _adctSetInfos.length - 1; i >= 0; i--) {
				if (_adctSetInfos[i].readonly)
					_adctSetInfos.splice(i, 1);
			}
			
			super.OnSetsRefreshed();
			UpdateOverwriteState();
		}

		protected function CanCreateSets(adctSetInfos:Array):Boolean {
			// we require aitmSets.length > 0 because otherwise "create album" will be the
			// default (and only) selection, and there'll be no way to re-select it and trigger its action
			return _ss.GetServiceInfo().create_sets && adctSetInfos.length > 0;
		}
		
		override protected function SetInfosToComboItems( adctSetInfos:Array ): Array {
			var aitmSets:Array = super.SetInfosToComboItems( adctSetInfos );
			if (CanCreateSets(adctSetInfos)) {
				var dctPhrases:Object = GetLocalPhrases();
				var strCreateNew:String = "create_new_" + dctPhrases['set'];
				aitmSets.unshift( new StorageServiceSetComboItem( Resource.getString("StorageServiceOutBridgeBase", strCreateNew), null, null, "CreateSet" ) );
			}
			StorageServiceSetComboItem.UpdateHasIcons(aitmSets);
			return aitmSets;	
		}

		override protected function OnSetsComboChange(evt:Event): void {
			if ((_cboxSets.selectedItem as StorageServiceSetComboItem).cmd == "CreateSet" ) {			
				OnSetsRefreshed();	// this forces the selection back to the previous one
				ShowCreateAlbum();
			}
			else {
				super.OnSetsComboChange(evt);
				UpdateOverwriteState();
			}
		}
		
		private function OnCreateAlbumClick(evt:Event):void {
			ShowCreateAlbum();
		}
		
		private function ShowCreateAlbum(): void {
			DialogManager.Show( "CreateAlbumDialog",
								this,
								function( obResult:Object ):void {
									if (obResult.success && obResult.dctSetInfo) {
										_strSelectedSetID = obResult.dctSetInfo.id;
										RefreshSets();
									}
								},
								{ sets: _adctSetInfos, storageservice: _ss, phrases: GetLocalPhrases() } );
		}
		
		// If the current image came from this service get its up-to-date info from the server.
		// If it's overwriteable, present the overwrite option to the user.
		private function UpdateOverwriteState(): void {		
			if (_imgd && _imgd.properties./*bridge*/serviceid == _ss.GetServiceInfo().id) {
				_ss.GetItemInfo(_imgd.properties./*ss_*/setid, _imgd.properties./*ss_item*/id, OnGetItemInfoComplete);
			} else {
				_originalItemInfo = null;
				UpdateState();
			}
		}
		
		private function OnGetItemInfoComplete(err:Number, strError:String, itemInfo:ItemInfo=null): void {
			if (err != StorageServiceError.None)
				return;
			_originalItemInfo = itemInfo;
			UpdateState();				
		}


		// This is meant to be overridden by subclasses
		// It should return whatever state we want after we are authorized
		override protected function GetState(): String {
			if (!IsOverwriteable(_originalItemInfo)) {
				return "AccountTypePro";
			}
			return "AccountTypeProWithImageID";
		}
		
		protected function IsOverwriteable(itemInfo:ItemInfo=null): Boolean {
			var dctSetInfo:Object = GetSelectedSetInfo();
			if (!itemInfo || !itemInfo.overwriteable || !dctSetInfo || itemInfo.setid != dctSetInfo.id)
				return false;
			return true;
		}
		
		protected function Save(): void {
			var dctSetInfo:Object = GetSelectedSetInfo();
			
			var setid:String = "unused"; // Some bridges don't support sets.
			if (dctSetInfo)
				setid = dctSetInfo.id;
				
			var fOverwrite:Boolean = ((currentState == "AccountTypeProWithImageID") && (_rbtnSaveNew.selected == false));

			_obSaveParams = {
				fOverwrite: fOverwrite,
				setid: setid,
				itemid: fOverwrite ? _imgd.properties./*ss_item*/id : null
			}

			if (fOverwrite) {
				DialogManager.Show('ConfirmOverwriteDialog',PicnikBase.app, OnConfirmOverwrite,
					{ strURLOld: _imgd.properties.thumbnailurl,
					  imgd: _imgd,
					  fShowSaveOver: false});
			} else {
				DoSave();
			}
		}
		
		protected function GetSelectedSetInfo(): Object {
			if (!_cboxSets)
				return null;
			var itm:StorageServiceSetComboItem = _cboxSets.selectedItem as StorageServiceSetComboItem;
			if (!itm)
				return null;
			return itm.setinfo;
		}
		
		private function OnConfirmOverwrite(obResult:Object): void {
			if (obResult.success) DoSave();
		}
		
		protected function AddPicnikTag():void {
			if (!_imgd.properties.tags)
				_imgd.properties.tags = "";
			if (_imgd.properties.tags.toLowerCase().indexOf("picnik") < 0) {
				if (_imgd.properties.tags.length > 0)
					_imgd.properties.tags += " ";
				_imgd.properties.tags += "Picnik";
			}			
		}
		
		protected function DoSaveWithParams(obSaveParams:Object): void {
			_obSaveParams = obSaveParams;
			DoSave();
		}

		protected function _ShowBusy(fnOnCancel:Function): void {
			_HideBusy();
			_bsy = BusyDialogBase.Show(this, StringUtil.substitute( Resource.getString("StorageServiceOutBridgeBase", "saving_to"),
					_ss.GetServiceInfo().name), BusyDialogBase.SAVE_USER_IMAGE,
					"ProgressWithCancel", 0, fnOnCancel);

		}
		
		protected function _HideBusy(): void {
			if (_bsy) {
				_bsy.Hide();
				_bsy = null;
			}
		}
		
		private function DoSave(): void {
			if (_chkbPicnikTag && _chkbPicnikTag.selected)
				AddPicnikTag();

			if (ValidateBeforeSave()) {
				var itemInfo:ItemInfo = ItemInfo.FromImageProperties(_imgd.properties);				
				itemInfo = UpdateItemInfo(itemInfo);

				_ShowBusy( OnSavePikCancel );
			
				_ss.CreateItem(_obSaveParams.setid, _obSaveParams.itemid, itemInfo, _imgd,
						OnCreateItemComplete, _bsy);
				
				PicnikService.Log("StorageServiceOutBridge saving title: " + itemInfo.title + ", tags: " +
						itemInfo.tags + ", photoset: " + _obSaveParams.setid +
						", overwriting: " + _obSaveParams.itemid)
			}
		}

		protected function UpdateItemInfo(itemInfo:ItemInfo):ItemInfo {
			return itemInfo;
		}
		
		protected function ValidateBeforeSave(): Boolean {
			return true;
		}
		
		private function OnCreateItemProgress(nPercentComplete:Number, strStatus:String): void {
			if (_bsy)
				_bsy.progress = nPercentComplete;
		}
		
		// Generic third party error save failure handler.
		// Override as needed
		protected function ShowPictureSaveFailedAlert(err:Number, strError:String): void {
			Util.ShowAlert(Resource.getString("StorageServiceOutBridgeBase", "picture_save_fail"),
					Resource.getString("StorageServiceOutBridgeBase", "Error"), Alert.OK,
					"ERROR:out.bridge." + String(_ss.GetServiceInfo().id).toLowerCase() + ".createitem: " + err + ", " + strError);
		}
		
		protected function OnCreateItemComplete(err:Number, strError:String, itemInfo:ItemInfo=null): void {
			_HideBusy();
			if (err != ImageDocument.errNone) {
				trace("StorageServiceOutBridgeBase.OnSavePikDone: err: " + err + ", strError: " + strError);
				if (err == StorageServiceError.ChildObjectFailedToLoad) {
					DisplayCouldNotProcessChildrenError();					
				} else if (err == StorageServiceError.NotEnoughSpace) {
					Util.ShowAlertWithoutLogging(Resource.getString("StorageServiceOutBridgeBase", "notEnoughSpace"), Resource.getString("StorageServiceOutBridgeBase", "Error"), Alert.OK);
				} else if (err == StorageServiceError.BridgeOffline) {
	
					var fnOnButton:Function = function(obResult:Object): void {
						if ('success' in obResult && obResult.success) {
							PicnikBase.app.NavigateTo(PicnikBase.OUT_BRIDGES_TAB, OutBridge.DOWNLOAD_SUB_TAB);
						}
					}
					
					var friendlyServiceName:String = GetServiceName(this.simpleBridgeName);
					var dlg:EasyDialog = EasyDialogBase.Show(PicnikBase.app,
						[Resource.getString("StorageServiceOutBridgeBase", "save_to_my_computer"), Resource.getString("Picnik", "cancel")],
						Resource.getString("StorageServiceOutBridgeBase", "Error"),
						LocUtil.rbSubst("StorageServiceOutBridgeBase", "bridge_offline", friendlyServiceName, friendlyServiceName),
						fnOnButton);					
				} else if (err == StorageServiceError.Unknown) {
					EasyDialogBase.Show(PicnikBase.app,
							[Resource.getString("StorageServiceOutBridgeBase", "unknown_error_ok")],
							Resource.getString("StorageServiceOutBridgeBase", "Error"),
							LocUtil.rbSubst("StorageServiceOutBridgeBase", "unknown_error", GetServiceName(simpleBridgeName)), null, true);
				} else {
					ShowPictureSaveFailedAlert(err, strError);
				}
			} else {
				ReportSuccess(_obSaveParams.fOverwrite ? '/with_overwrite' : '/without_overwrite', "export");
				
				var fnGotItemInfo:Function = function(imgp:ImageProperties, obCallbackData:Object): void {
					if (!AccountMgr.GetInstance().isGuest && imgp != null) {
						OnGetItemInfo(imgp, obCallbackData);
						PostSaveWithItemInfo(ItemInfo.FromImageProperties(imgp));
					}
					NotifySaveComplete();
					PostSaveAction(imgp != null ? imgp : itemInfo);
				}

				// The ItemInfo returned by CreateItem may be a truncated one. Call GetItemInfo to get
				// all the details.
				if (itemInfo != null) {
					GetItemInfo(itemInfo.setid, itemInfo.id, fnGotItemInfo, _imgd);
				} else {
					fnGotItemInfo( null, null );
				}
				
				if (_imgd) {
					// if the user hits cancel on the progress dlg and then navigates away,
					// then OnDeactivate will set _imgd to null.  That's why we check for _imgd first.
					_imgd.isDirty = false;
				}
			}
		}
		
		protected function NotifySaveComplete(): void {
			PicnikBase.app.OnSaveComplete();
		}
		
		protected function PostSaveAction(dctItemInfo:Object): void {
			PicnikBase.app.NavigateToService(PicnikBase.OUT_BRIDGES_TAB, "postsave");
		}
		
		protected function PostSaveWithItemInfo(iinfo:ItemInfo): void {
			if (_imgd) _imgd.lastSaveInfo = iinfo.asImageProperties();
		}
		
		// UNDONE: this and other methods in StorageServiceIn/OutBridgeBase:
		//	change arg type s/ImageProperties/ItemInfo/ as appropriate
		private function OnGetItemInfo(imgp:ImageProperties, obCallbackData:Object): void {
			// UNDONE: is this a great idea? The end result is that saving to a service
			// will wipe out any previous image properties w/ the same names
			var imgd:ImageDocument = obCallbackData as ImageDocument;

			// Note: if the user hits cancel on the progress dlg and then navigates away,
			// then OnDeactivate will set imgd to null.  That's why we check for imgd as well as imgp.
			if (imgp && imgd) imgp.CopyTo(imgd.properties);
		}
		
		private function OnSavePikCancel(obResult:Object): void {
			// UNDONE: _imgd.CancelSave()
			_HideBusy();
		}
		
		protected function OnSaveClick(evt:MouseEvent): void {
			Save();
		}
		
		protected function GetLocalPhrases():Object {
			// this can be overridden in subclasses if they use different
			// words for things (iet "sets" vs "albums" vs "folders")
			return { set: "set" };
		}
		
		override protected function OnKeyDown(evt:KeyboardEvent):void {
			// UNDONE: users that hit enter while filling out a description will accidentally save
			// Disable enter-key saving until this is fixed.
//			if (_btnSave.enabled && evt.keyCode == Keyboard.ENTER)
//				Save();
		}
	}
}
