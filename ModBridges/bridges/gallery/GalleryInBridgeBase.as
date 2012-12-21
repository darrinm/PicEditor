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
package bridges.gallery {
	import bridges.*;
	import bridges.gallery.*;
	import bridges.picnik.*;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceInBridgeBase;
	
	import com.adobe.utils.StringUtil;
	
	import controls.PicnikMenuItem;
	
	import dialogs.BusyDialogBase;
	import dialogs.EasyDialogBase;
	import dialogs.DialogManager;
	
	import flash.events.Event;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.collections.ArrayCollection;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ItemClickEvent;
	import mx.resources.ResourceBundle;
	
	import util.LocUtil;

	public class GalleryInBridgeBase extends StorageServiceInBridgeBase {
  		[ResourceBundle("GalleryInBridge")] static protected var _rbGallery:ResourceBundle;
  		private const kcNonSubscriberEnabledLimit:int = 3;		// UNDONE: need to incorporate this const directly in user-facing messages
  		
		public function GalleryInBridgeBase() {
			super();
			_tpa = new ThirdPartyAccount("Show", new GalleryStorageService());
			_mnuOptions._acobMenuItems = new ArrayCollection([new PicnikMenuItem( Resource.getString("GalleryInBridge", "ClearAll"),
					{ id: "clearall" })]);
		}

		private function get picnikStorageService():PicnikStorageService {
			return _tpa.storageService as PicnikStorageService;
		}
		
		protected override function OnMenuItemClick(evt:ItemClickEvent): void {
			// Only one option
			ClearAll();
		}
		
		private function HideBusyDialog(): void {
			if (_bsy) {
				_bsy.Hide();
				_bsy = null;	
			}
		}
		
		protected function ClearAll(): void {
			var fnOnDeleteAll:Function = function(err:Number, strError:String): void {
				HideBusyDialog();
				if (err != PicnikService.errNone)
					trace("Error deleting: " + err);
				RefreshItemList();
			}
			var this2:UIComponent = this;
			var fnOnClear:Function = function(obResult:Object): void {
				if ('success' in obResult && obResult.success) {
					// Do the deletion
					HideBusyDialog();
					_bsy = BusyDialogBase.Show(this2, Resource.getString("GalleryInBridge", "Deleting"), BusyDialogBase.DELETE, "IndeterminateNoCancel", 0);
					picnikStorageService.DeleteAll(fnOnDeleteAll);
				}
			}
			
			EasyDialogBase.Show(PicnikBase.app,
					[Resource.getString("GalleryInBridge", "DeleteThem"), Resource.getString("GalleryInBridge", "Cancel")],
					Resource.getString("GalleryInBridge", "DeleteAllAreYouSureTitle"),
					Resource.getString("GalleryInBridge", "DeleteAllAreYouSureBody"),
					fnOnClear);
		}
		
		override protected function GetState(): String {
			if (PicnikConfig.galleryUpgradeForAccess) {
				return "PremiumPreview"
			}
			return super.GetState();
		}	
				
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			ChangeWatcher.watch(AccountMgr.GetInstance(), "isPremium", OnUserIsPaidChange);
		}

		public override function GetMenuItems(): Array {
			var astrItems:Array = [ Bridge.EDIT_GALLERY, Bridge.SHARE_GALLERY, Bridge.RENAME_ITEM, Bridge.LAUNCH_GALLERY, Bridge.DELETE_GALLERY];
			return astrItems;
		}
		
		override protected function GetPhotosAndAlbums(nPhotos:Number, nAlbums:Number, strKeySuffix:String="albums"): String {
			// Avoid reporting the scary "No photos" message while the bridge is initializing
			if (nAlbums == -1)
				return "";
				
			return LocUtil.zeroOneOrMany('GalleryInBridge', nAlbums, "number_of_galleries");
		}
		
		// Subscribers have unlimited access to the Gallery. Non-subscribers have access
		// to the 5 most recent entries.
		override public function OnActivate(strCmd:String=null): void {
			UpdateEnabledLimit();
			super.OnActivate(strCmd);
		}
		
		override protected function OnBridgeItemAction(evt:BridgeItemEvent): void {
			// If this item is enabled, handle normally
			if (evt.bridgeItem.enabled) {
				super.OnBridgeItemAction(evt);
				return;
			}
				
			// Most actions on a disabled item result in the upsell dialog
			switch (evt.action) {
			case Bridge.EDIT_ITEM:
			case Bridge.EDIT_GALLERY:
			case Bridge.EMAIL_ITEM:
			case Bridge.DOWNLOAD_ITEM:
				var strEvent:String = "/in_gallery/" + evt.action;
				strEvent = StringUtil.replace(strEvent, ' ', '_');
				DialogManager.ShowUpgrade(strEvent, UIComponent(Application.application));
				break;
			
			default:
				super.OnBridgeItemAction(evt);
			}
		}
		
		private function OnUserIsPaidChange(evt:Event): void {
			UpdateEnabledLimit();
			RefreshEverything();
		}
		
		private function UpdateEnabledLimit(): void {
			_tlst.enabledLimit = AccountMgr.GetInstance().isPremium ? -1 : kcNonSubscriberEnabledLimit;
		}

		override protected function RefreshSets(): void {
			if (storeIsOff) return;
			// UNDONE: keep in and outbridge selected set synchronized and persisted
			ShowBusy();
			_nRefreshSetsOutstanding++;
			_ss.GetSets( _strSelectedFriendID, OnGetSets);
		}

		// UNDONE: in gallery-land, we only save items?	
		static public function GetSavedOnString(strServiceId:String): String {
			var strLookup:String = "saved_on";
//			if (strServiceId == "Email")
//				strLookup = "emailed_on";
//			else if (strServiceId == "Print")
//				strLookup = "printed_on";
//			else if (strServiceId.indexOf("GenericEmail") == 0)
//				strLookup = "sent_on";
			return Resource.getString("GalleryInBridge", strLookup);
		}

		override protected function OnGetSets(err:Number, strError:String, adctSetInfos:Array=null): void {
			CheckFailCount( err, strError );
			Debug.Assert(_nRefreshSetsOutstanding > 0);
			
			if (err != StorageServiceError.None) {
				_nRefreshSetsOutstanding--;								
				currentState = "NeedAuthorization";	// attempt to reconnect
				return;
			}

			this.SetItemList(adctSetInfos);
			
			_nRefreshSetsOutstanding--;
			_fRefreshed = OutstandingRefreshes() == 0 ? true : false;
			if (_fRefreshed) HideBusy();
			
		}
		
		protected function OnNewShowClick(): void {
			PicnikBase.app.CreateFreshGallery();
		}
	}
}
