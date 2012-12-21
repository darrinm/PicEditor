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
package bridges.mypicnik {
	import bridges.*;
	import bridges.storageservice.StorageServiceOutBridgeBase;
	import bridges.storageservice.StorageServiceSetComboItem;
	
	import events.LoginEvent;
	
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	
	import mx.containers.Box;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.events.FlexEvent;
			
	public class MyPicnikOutBridgeBase extends StorageServiceOutBridgeBase {
		public function MyPicnikOutBridgeBase() {
			super();
//			_tpa = AccountMgr.GetThirdPartyAccount("MyPicnik");
			_tpa = new ThirdPartyAccount("MyPicnik", new MyPicnikStorageService());
		}

		override protected function OnLoginComplete(evt:LoginEvent): void {
			super.OnLoginComplete(evt);
			RefreshUserInfo();
		}
		
		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
			if (_ss.IsLoggedIn()) {
				RefreshUserInfo();
				return;
			}
		}
				
		override protected function IsOverwriteable(itemInfo:ItemInfo=null): Boolean {
			/* UNDONE: DWM: enable this when MyPicnik 'replace' technology is implemented
			if (itemInfo != null && itemInfo.serviceid == "MyPicnik" && itemInfo.pikid)
				return true;
			*/
			return false;
		}		
	
		override protected function GetLocalPhrases():Object {
			// localize some of the words we use to match this bridge
			var obPhrases:Object = super.GetLocalPhrases();
			obPhrases.set = "album";
			return obPhrases;
		}
	}
}
