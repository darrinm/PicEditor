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
package bridges.history {
	import bridges.*;
	import bridges.picnik.*;
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

	public class HistoryInBridgeBase extends StorageServiceInBridgeBase {
  		[ResourceBundle("HistoryInBridge")] static protected var _rbHistory:ResourceBundle;
  		private const kcNonSubscriberEnabledLimit:int = 5;
  		
		public function HistoryInBridgeBase() {
			super();
			_tpa = new ThirdPartyAccount("History", new HistoryStorageService());
			_mnuOptions._acobMenuItems = new ArrayCollection([new PicnikMenuItem( Resource.getString("HistoryInBridge", "ClearAll"),
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
				RefreshStoreInfo();
				RefreshItemList();
			}
			var this2:UIComponent = this;
			var fnOnClear:Function = function(obResult:Object): void {
				if ('success' in obResult && obResult.success) {
					// Do the deletion
					HideBusyDialog();
					_bsy = BusyDialogBase.Show(this2, Resource.getString("HistoryInBridge", "Deleting"), BusyDialogBase.DELETE, "IndeterminateNoCancel", 0);
					picnikStorageService.DeleteAll(fnOnDeleteAll);
				}
			}
			
			EasyDialogBase.Show(PicnikBase.app,
					[Resource.getString("HistoryInBridge", "DeleteThem"), Resource.getString("HistoryInBridge", "Cancel")],
					Resource.getString("HistoryInBridge", "DeleteAllAreYouSureTitle"),
					Resource.getString("HistoryInBridge", "DeleteAllAreYouSureBody"),
					fnOnClear);
		}
		
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			ChangeWatcher.watch(AccountMgr.GetInstance(), "isPremium", OnUserIsPaidChange);
		}

		public override function GetMenuItems(): Array {
			var astrItems:Array = [ Bridge.EDIT_ITEM, Bridge.DELETE_ITEM, Bridge.EMAIL_ITEM, Bridge.DOWNLOAD_ITEM ];
			if (AccountMgr.GetInstance().isCollageAuthor)
				astrItems.push(Bridge.PUBLISH_TEMPLATE);
			return astrItems;
		}
		
		override protected function GetPhotosAndAlbums(nPhotos:Number, nAlbums:Number, strKeySuffix:String="albums"): String {
			// Avoid reporting the scary "No photos" message while the bridge is initializing
			if (nPhotos == -1)
				return "";
				
			return LocUtil.zeroOneOrMany('HistoryInBridge', nPhotos, "number_of_photos");
		}
		
		// Subscribers have unlimited access to the History. Non-subscribers have access
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
			case Bridge.EMAIL_ITEM:
			case Bridge.DOWNLOAD_ITEM:
			case Bridge.ADD_GALLERY_ITEM:
				var strEvent:String = "/in_history/" + evt.action;
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
				
		static public function GetSavedOnString(strServiceId:String): String {
			var strLookup:String = "saved_on";
			if (strServiceId == "Email")
				strLookup = "emailed_on";
			else if (strServiceId == "Print")
				strLookup = "printed_on";
			else if (strServiceId.indexOf("GenericEmail") == 0)
				strLookup = "sent_on";
			return Resource.getString("HistoryInBridge", strLookup);
		}
	}
}
