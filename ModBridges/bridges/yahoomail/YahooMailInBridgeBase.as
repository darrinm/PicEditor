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
package bridges.yahoomail {
	import bridges.*;
	import bridges.storageservice.StorageServiceInBridgeBase;
	import bridges.storageservice.StorageServiceProxy;
	
	public class YahooMailInBridgeBase extends StorageServiceInBridgeBase {
		public function YahooMailInBridgeBase() {
			super();
			_tpa = AccountMgr.GetThirdPartyAccount("YahooMail");
			
			// Use super small batches because they can take a long time to process
			batchSize = 1;
		}

		override protected function PrepareBatch(obBatch:Object): void {
			obBatch.fNewList = true;
			obBatch.fOverwrite = true; // Overwrite the batch because we cache our list (except when we explicitly refresh)
		}

		public override function GetMenuItems(): Array {
			return [ Bridge.EDIT_ITEM, Bridge.EMAIL_ITEM, Bridge.DOWNLOAD_ITEM ];
		}

		protected override function OnItemListChanging(strSetId:String, strSort:String, strFilter:String): void {
			super.OnItemListChanging(strSetId, strSort, strFilter);
			// strSetId:String, strSort:String, strFilter
			GetStorageService().OnFolderChanged(strSetId, strSort, strFilter);
		}
		
		override public function OnDeactivate():void {
			super.OnDeactivate();
			YahooMailFolder.SetActive(null);
		}
		
		protected function Refresh(): void {
			GetStorageService().Refresh();
			RefreshItemList(true);
		}
		
		protected function GetStorageService(): YahooMailStorageService {
			if (!_ss) {
				return null;	
			}
			var ymss:YahooMailStorageService = _ss as YahooMailStorageService;
			if (ymss) {
				return ymss;
			}
			var ssp:StorageServiceProxy = _ss as StorageServiceProxy;
			if (ssp) {
				return ssp.GetProxiedService() as YahooMailStorageService;
			}
			return null;
		}
	}
}
