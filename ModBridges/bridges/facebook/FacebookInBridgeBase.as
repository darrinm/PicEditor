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
package bridges.facebook {
	import bridges.*;
	import bridges.storageservice.StorageServiceInBridgeBase;
	
	import dialogs.DialogManager;
	
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import util.URLLoaderPlus;
	
	public class FacebookInBridgeBase extends StorageServiceInBridgeBase {
		public function FacebookInBridgeBase() {
			super();
			_tpa = AccountMgr.GetThirdPartyAccount("Facebook");
		}

		public override function GetMenuItems(): Array {
			return [Bridge.EDIT_ITEM, Bridge.EMAIL_ITEM, Bridge.DOWNLOAD_ITEM, Bridge.OPEN_ITEMS_WEBPAGE];
		}

		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
			if (_ss.IsLoggedIn()) {
				Util.UrchinLogReport("/facebook/invite/in/view");
			}
		}
				
		protected function TellYourFriends(): void {
			Util.UrchinLogReport("/facebook/invite/in/click");
			if (_tpa && (_tpa.storageService as FacebookStorageService)) (_tpa.storageService as FacebookStorageService).TellYourFriends();
		}
		
		override protected function GetSignedOutState():String {
			if (!PicnikConfig.facebookEnabled)
				return "ServiceDown";
			return super.GetSignedOutState();
		}
					
		override protected function GetState(): String {
			if (!PicnikConfig.facebookEnabled)
				return "ServiceDown";
			if (_fNoSets) return (_strSelectedFriendID != null) ? "NoSets_Friend" : "NoSets";
			else return super.GetState();
		}				
	}
}
