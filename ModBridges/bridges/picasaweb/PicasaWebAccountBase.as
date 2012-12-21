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
	import bridges.storageservice.StorageServiceAccountBase;
	import bridges.storageservice.StorageServiceError;
	
	import events.LoginEvent;
	
	public class PicasaWebAccountBase extends StorageServiceAccountBase {
		override protected function Authorize(): void {

			var OnCallbackDone:Function = function(err:Number, strError:String): void {
				AccountMgr.GetInstance().RefreshUserAttributes(function():void {
					var strUserId:String = AccountMgr.GetInstance().GetUserAttribute("tpa.PicasaWeb._userid", "")
					var strToken:String = AccountMgr.GetInstance().GetUserAttribute("tpa.PicasaWeb._token", "")
					_tpa.SetUserId(strUserId);
					_tpa.SetToken(strToken);
					_tpa.storageService.LogIn(_tpa, function(err:Number, strError:String):void {
						dispatchEvent(new LoginEvent(LoginEvent.LOGIN_COMPLETE, (err==StorageServiceError.None)));
					});
				}, false); // false == don't save old attrs first
			}

			var fnComplete:Function = function(err:Number, strError:String, strCBParams:String=null): void {
				if (err == StorageServiceError.None) {
					var fSuccess:Boolean = err == StorageServiceError.None;
					if (fSuccess) {
						var obParams:Object = {cbService:'picasaweb', cbParams:strCBParams, retriesleft:2};
						PicnikService.callMethod("user.callback", null, obParams, true, null, OnCallbackDone);

					}
				}
			}
			
			ClearOtherConnections();
			_tpa.storageService.Authorize(null, fnComplete);
		}
	}
}
