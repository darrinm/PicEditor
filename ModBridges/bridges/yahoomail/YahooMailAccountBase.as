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
	import bridges.storageservice.StorageServiceAccountBase;
	import bridges.storageservice.StorageServiceError;
	
	import events.LoginEvent;
	
	import flash.display.DisplayObjectContainer;
	import dialogs.EasyDialog;
	import dialogs.EasyDialogBase;
	
	import pages.WelcomeNewBase;

	public class YahooMailAccountBase extends StorageServiceAccountBase {
		override protected function Authorize(): void {
			ClearOtherConnections();
			var fnComplete:Function = function (err:Number, strError:String, strUserId:String=null, strToken:String=null): void {
				var fSuccess:Boolean = err == StorageServiceError.None;
				if (fSuccess) {
					_tpa.SetToken(strToken);
				}
				dispatchEvent(new LoginEvent(LoginEvent.LOGIN_COMPLETE, fSuccess));											
			}
			_tpa.storageService.Authorize(null, fnComplete);
		}

		// This function is needed to support the "or, upload a photo" button on YahooMailWelcomeAccount		
		protected function DoUpload(): void {
			// HACK: walk up the parent chain looking for WelcomeNewBase. If found,
			// call its DoUpload function.
			var dobc:DisplayObjectContainer = parent;
			while (dobc != null) {
				if (dobc is WelcomeNewBase) {
					(dobc as WelcomeNewBase).DoUpload();
					return;
				}
				dobc = dobc.parent;
			}
		}	
		
		override protected function PromptForAuth(): void {
			var dlg:EasyDialog =
				EasyDialogBase.Show(
					PicnikBase.app,
					[Resource.getString('YahooMailAccount', 'connect'), Resource.getString('Picnik', 'cancel')],
					Resource.getString('YahooMailAccount', 'ymail_drop_connect_title'),						
					Resource.getString('YahooMailAccount', 'ymail_drop_connect_message'),						
					function( obResult:Object ):void {
						if (obResult.success) {
							Authorize();			
						}
					}	
				);
			
		}
		

	}
}
