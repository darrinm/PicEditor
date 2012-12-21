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
package bridges.flickr {
	import bridges.storageservice.StorageServiceAccountBase;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceProxy;
	
	import events.LoginEvent;
	
	import util.Unpickler;
	
	public class FlickrAccountBase extends StorageServiceAccountBase {
		override protected function Authorize(): void {

			var OnGetAuthTokenDone:Function = function(err:Number, strError:String, dctInfo:Object=null): void {
				_tpa.SetToken(dctInfo.authtoken);
				_tpa.SetUserId(dctInfo.nsid);
				_tpa.storageService.LogIn(_tpa, function(err:int, errMsg:String): void {
					dispatchEvent(new LoginEvent(LoginEvent.LOGIN_COMPLETE, (err==PicnikService.errNone)));
				});
			}

			var fnComplete:Function = function (err:Number, strError:String, strCBParams:String=null): void {
				if (err == StorageServiceError.None) {
					var obParams:Object = util.Unpickler.loads(strCBParams);
					var fss:FlickrStorageService = GetStorageService();
					if (fss != null)
						fss.GetAuthToken(obParams.frob, OnGetAuthTokenDone);
				}
			}
			ClearOtherConnections();
			_tpa.storageService.Authorize(null, fnComplete);
		}
		
		private function GetStorageService(): FlickrStorageService {
			if (!_tpa.storageService) {
				return null;	
			}
			var fss:FlickrStorageService = _tpa.storageService as FlickrStorageService;
			if (fss) {
				return fss;
			}
			var ssp:StorageServiceProxy = _tpa.storageService as StorageServiceProxy;
			if (ssp) {
				return ssp.GetProxiedService() as FlickrStorageService;
			}
			return null;
		}
		
	}
}
