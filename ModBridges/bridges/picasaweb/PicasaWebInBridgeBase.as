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
package bridges.picasaweb {
	import bridges.*;
	import bridges.storageservice.StorageServiceInBridgeBase;
	
	import controls.PicnikMenuItem;
	
	import flash.events.*;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.collections.ArrayCollection;
	
	import util.LocUtil;

	public class PicasaWebInBridgeBase extends StorageServiceInBridgeBase {
		private var _cwHasGoogleCreds:ChangeWatcher;
		
		public function PicasaWebInBridgeBase() {
			super();
			_tpa = AccountMgr.GetThirdPartyAccount("PicasaWeb");
			UpdateMenu();
			_cwHasGoogleCreds = ChangeWatcher.watch(AccountMgr.GetInstance(), "hasGoogleCredentials", UpdateMenu);
		}
		
		private function UpdateMenu(evt:Event=null): void {
			if (_mnuOptions._acobMenuItems == null)
				_mnuOptions._acobMenuItems = new ArrayCollection();

			_mnuOptions._acobMenuItems.removeAll();
			_mnuOptions._acobMenuItems.addItem(new PicnikMenuItem( LocUtil.rbSubst("Bridge", "VisitWebsite", "Picasa"), { id: "visitwebsite" }));
			if (!AccountMgr.GetInstance().hasGoogleCredentials) {
				_mnuOptions._acobMenuItems.addItem(new PicnikMenuItem( Resource.getString("Bridge", "Disconnect"), { id: "disconnect" }));
			}

		}

		override protected function GetState(): String {
			if (_fNoSets) return "NoSets";
			else return super.GetState();
		}
	}
}
