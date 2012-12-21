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
package bridges.flickrsearch {
	import bridges.Bridge;
	import bridges.BridgeItemEvent;
	import bridges.Downloader;
	import bridges.FileTransferBase;
	import bridges.InBridgeTileList;
	import bridges.flickr.*;
	import bridges.storageservice.*
	
	import dialogs.*;
	
	import flash.events.*;
	import flash.net.URLRequest;
	
	import imagine.ImageDocument;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.ComboBox;
	import mx.controls.RadioButton;
	import mx.controls.Spacer;
	import mx.controls.TextInput;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.resources.ResourceBundle;
	
	import urlkit.rules.UrlValueRule;
	
	import util.Cancelable;

	public class FlickrSearchInBridgeBase extends FlickrBridgeBase {
		// MXML-specified variables
		[Bindable] public var _tlst:InBridgeTileList;
		[Bindable] public var _cboxOrderBy:ComboBox;
		[Bindable] public var _tiText:TextInput;
		[Bindable] public var _btnSearch:Button;
		[Bindable] public var _rbtnTags:RadioButton;
		[Bindable] public var _rbtnNewestFirst:RadioButton;
		[Bindable] public var _rbtnOldestFirst:RadioButton;
		[Bindable] public var _chkbCommercial:CheckBox;
		[Bindable] public var _chkbDerivative:CheckBox;
		[Bindable] public var _btnCreativeCommons:Button;
		[Bindable] public var _uvrTags:UrlValueRule;
		[Bindable] public var _uvrOrderBy:UrlValueRule;
		[Bindable] public var _cvsCC:Canvas;
		[Bindable] public var _spcCC:Spacer;
		public var _strQueryTags:String;
		public var _strQueryOrderBy:String;

   		[ResourceBundle("FlickrSearchInBridge")] private var _rb:ResourceBundle;

		// PORT: thumbnail sizes should be kept in one place		
		private static const kcxThumbnail:Number = 160; // CONFIG:
		private static const kcyThumbnail:Number = 160; // CONFIG:
		
		private var _imgp:ImageProperties = null;
		private var _strCurrentAction:String = null;
		private var _strRenameTarget:String = null;
		private var _obDeleteCallbackData:Object;
		
		private var _fNoImages:Boolean = false;
		private var _apset:Array;
		private var _strSelectedPhotoSet:String = null;
		private var _nSearchPage:Number;
		private var _canDownloadOp:Cancelable = null;
		
		public function FlickrSearchInBridgeBase() {
			super();
		}

		override protected function OnInitialize(evt:Event): void {
			super.OnInitialize(evt);
			addEventListener(ResizeEvent.RESIZE, OnResize);
			
			_tlst.addEventListener(BridgeItemEvent.ITEM_ACTION, OnBridgeItemAction);
			_cboxOrderBy.addEventListener(Event.CHANGE, OnOrderByChange);
			_tiText.addEventListener(FlexEvent.ENTER, OnTextInputEnter);
			_btnSearch.addEventListener(MouseEvent.CLICK, OnSearchClick);
			_rbtnNewestFirst.addEventListener(MouseEvent.CLICK, OnOrderAscDescClick);
			_rbtnOldestFirst.addEventListener(MouseEvent.CLICK, OnOrderAscDescClick);
		}
		
		override public function OnActivate(): void {
			super.OnActivate();
			
			// HACK: until we redo the Flickr Search bridge
			if (currentState == "ComingSoon")
				return;
			
			_tiText.setFocus();
			
			if (_strQueryOrderBy && _strQueryOrderBy != "") {
				for each (var itm:Object in _cboxOrderBy.dataProvider) {
					if (itm.data == _strQueryOrderBy)
						_cboxOrderBy.selectedItem = itm;
				}
				_strQueryOrderBy = null;
				_uvrOrderBy.stringValue = "";
			}
			
			if (_strQueryTags && _strQueryTags != "") {
				_tiText.text = _strQueryTags;
				_rbtnTags.selected = true;
				_strQueryTags = null;
				_uvrTags.stringValue = "";
				RefreshImageList();
			}
		}
		
		// Hide the Creative Commons box if there isn't room for it
		private function OnResize(evt:ResizeEvent): void {
			var fShow:Boolean = width > 763;
			_cvsCC.includeInLayout = fShow;
			_cvsCC.visible = fShow;
			_spcCC.includeInLayout = fShow;
			_spcCC.visible = fShow;
		}

		public override function GetMenuItems():Array {
			return [Bridge.EDIT_ITEM, Bridge.EMAIL_ITEM, Bridge.DOWNLOAD_ITEM, Bridge.OPEN_ITEMS_FLICKRPAGE];
		}
		
		private function OnBridgeItemAction(evt:BridgeItemEvent): void {
			var imgp:ImageProperties = evt.bridgeItem.data as ImageProperties;

			switch (evt.action) {
			case Bridge.EDIT_ITEM:
			case Bridge.EMAIL_ITEM:
			case Bridge.DOWNLOAD_ITEM:
				_strCurrentAction = evt.action; // Remember where we are going
				DownloadImage(imgp); // Email and download start by getting the image.
				break;
				
			case Bridge.OPEN_ITEMS_FLICKRPAGE:
				PicnikBase.app.NavigateToURL(new URLRequest(imgp.webpageurl), "_blank");
				break;
			}
		}
		
		private function OnSearchClick(evt:MouseEvent): void {
			RefreshImageList();
		}
		
		private function OnTextInputEnter(evt:FlexEvent): void {
			RefreshImageList();
		}

		private function OnOrderByChange(evt:Event): void {
			currentState = _cboxOrderBy.selectedItem.data;
			RefreshImageList();
		}
		
		private function OnOrderAscDescClick(evt:MouseEvent): void {
			RefreshImageList();
		}
		
		private function RefreshImageList(): void {
			if (_tiText.text == "")
				return;
				
			var i:Number = -1;
			if (_btnCreativeCommons.selected)
				i = (_chkbCommercial.selected ? 1 : 0) | (_chkbDerivative.selected ? 2 : 0);
			PicnikService.Log("FlickrSearchInBridge for " + (_rbtnTags.selected ? "tags" : "text") + ' "' + _tiText.text +
					'", order: ' + _cboxOrderBy.selectedLabel + (_rbtnNewestFirst.selected ? " (desc)" : " (asc)") +
					", license: " + i);
				
			ShowBusy();
			_nSearchPage = 1;
			_tlst.dataProvider = new Array();
			GetNextPageOfSearchResults();
		}

		// A list of Flickr's creative commons license values to match the selected license types
		private static var s_mpCreativeCommonLicense:Array = [
			[1, 2, 3, 4, 5, 6], // Creative Commons checked, others unchecked
			[4, 6, 5],			// Creative Commons, commercial checked
			[4, 2, 1, 5],		// Creative Commons, derivative checked
			[4, 5]				// Creative Commons, commercial, derivative all checked
		];
		
		// BUGBUG: this isn't protect from the user changing something while
		// the search is in progress
		private function GetNextPageOfSearchResults(): void {
			var strExtras:String = "original_format, last_update, date_taken, date_upload, owner_name";
			
			var dctArgs:Object = {
				extras: strExtras, per_page: 100, page: _nSearchPage,
				sort: _cboxOrderBy.selectedItem.data + (_rbtnNewestFirst.selected ? "-desc" : "-asc")
			}
			
			// Set up for searching tags or text
			if (_rbtnTags.selected)
				dctArgs["tags"] = _tiText.text;
			else
				dctArgs["text"] = _tiText.text;
				
			// Set up for searching based on Creative Commons license
			if (_btnCreativeCommons.selected) {
				var i:Number = (_chkbCommercial.selected ? 1 : 0) | (_chkbDerivative.selected ? 2 : 0);
				dctArgs["license"] = s_mpCreativeCommonLicense[i].join(",");
			}
			_flkrp.photos_search(dctArgs, OnPhotosSearch);
		}
		
		private function OnPhotosSearch(rsp:XML): void {
			if (!active)
				return;
				
			if (rsp.@stat != "ok") {
				HideBusy();
				Util.ShowAlert(Resource.getString("FlickrSearchInBridge", "no_picture_list") +
						" (" + rsp.err.@code + ")",
						Resource.getString("FlickrSearchInBridge", "Error"), Alert.OK,
						"ERROR:in.bridge.flickrsearch.photosearch: " + rsp.toXMLString());
				return;
			}
			
			SetImageList(rsp.photos.photo);

			// Loop until all or 500 results found, whichever comes first.			
			if (rsp.photos.photo.length() == 100 && (ArrayCollection)(_tlst.dataProvider).length < 500) {
				_nSearchPage++;
				GetNextPageOfSearchResults();
			} else {
				HideBusy();
			}
		}
		
		private function SetImageList(xlph:XMLList, fReset:Boolean=false): void {
			for (var i:Number = 0; i < xlph.length(); i++) {
				var ph:XML = xlph[i];
				var itemInfo:ItemInfo = FlickrStorageService.ItemInfoFromPhoto(ph);
				var imgp:ImageProperties = StorageServiceUtil.ImagePropertiesFromItemInfo(itemInfo);
				if (ph.dates.@last_update != null)
					imgp.thumbnailurl += "?noCache=" + ph.dates.@last_update;
					
				(ArrayCollection)(_tlst.dataProvider).addItem(imgp);
			}
			_fNoImages = (xlph.length() == 0);
			UpdateState();
		}
		
		// Return whatever state we want after we are authorized
		override protected function GetState(): String {
			if (_fNoImages) {
				return "NoImages";
			} else {
				if (_cboxOrderBy.selectedItem == null)
					return "date-posted";
				else
					return _cboxOrderBy.selectedItem.data;	
			}
		}
		
		private function DownloadImage(imgp:ImageProperties): void {
			_imgp = imgp;
			ValidateOverwrite(DoDownloadImage);
		}
		
		private function DoDownloadImage(): void {
			_bsy = BusyDialogBase.Show(UIComponent(Application.application), Resource.getString("FlickrSearchInBridge", "Loading"), BusyDialogBase.LOAD_USER_IMAGE, "ProgressWithCancel", 0, OnDownloadCancel);
			// BUGBUG broken: need to change to use FlickrStorageService
//			var flka:FlickrAccount = FlickrMgr.GetInstance().GetFlickrAccount();
//			if (flka)
//				_flkrp.token = flka.authtoken;
//			_flkrp.Photos_GetInfoEx({ photo_id: _imgp.flickr_photo_id }, OnPhotosGetInfo);
		}
		
//		private function OnPhotosGetInfo(rsp:XML): void {
//			if (rsp.@stat != "ok") {
//				Util.ShowAlert(Resource.getString("FlickrSearchInBridge", "no_photo_info") + " (" + rsp.err.@code + ")",
//						Resource.getString("FlickrSearchInBridge", "Error"), Alert.OK,
//						"ERROR:in.bridge.flickrsearch.getinfo: " + rsp.toXMLString());
//				return;
//			}
//			
//			var imgp:ImageProperties = FlickrMgr.ImagePropertiesFromPhotoInfo(rsp.photo[0]);
//			
//			_canDownloadOp = new Cancelable(this, OnDownloadDone);
//			var dnldr:Downloader = new Downloader(imgp, "/WebInBridge", _canDownloadOp.callback, OnDownloadProgress);
//			dnldr.Start();
//					
//			PicnikService.Log("FlickrSearchInBridge loading " + imgp.sourceurl);
//		}
		
		private function OnDownloadCancel(dctResult:Object): void {
			_bsy.Hide();
			_bsy = null;
			_canDownloadOp.Cancel();
		}
		
		private function OnDownloadProgress(strStatus:String, nFractionDone:Number): void {
			if (_bsy)
				_bsy.progress = nFractionDone * 100;
		}
		
		private function OnDownloadDone(err:Number, strError:String, dnldr:FileTransferBase): void {
			// we'll only process the "OnDownloadDone" if the _bsy box is still around. 
			// if it's not around, then we've been cancelled.
			if (_bsy && dnldr != null) {
				_bsy.Hide();
				_bsy = null;
				if (err != ImageDocument.errNone) {
					Util.ShowAlert(Resource.getString("FlickrSearchInBridge", "download_failed"), Resource.getString("FlickrSearchInBridge", "Error"), Alert.OK,
							"ERROR:in.bridge.flickrsearch.download: " + err + ", " + strError);				
					return;
				}
				
				ReportSuccess(null, "import");
				PicnikBase.app.activeDocument = dnldr.imgd;
									
				// Go to the next destination:
				NavigateToAction(_strCurrentAction);
			}
		}
	}
}
