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
package util
{
	import com.adobe.utils.StringUtil;
	
	import dialogs.BusyDialog;
	import dialogs.BusyDialogBase;
	import dialogs.DialogManager;
	import dialogs.IBusyDialog;
	
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.core.UIComponent;

	public class GoogleUtil
	{
		public function GoogleUtil()
		{
		}

		public static function PopupGoogleLogOut(): void {
			try {
				ExternalInterface.call("eraseCookie", "gpc");
			} catch (e:Error) {
				trace("Ignoring error clearing cookie: " + e);
			}
			navigateToURL(new URLRequest(PicnikService.serverURL + "/auth/goog/popup/logout"), "_blank");
		}

		// fnDone(strGooglePicnikUserToken:String): void
		// returns a null token if something failed.
		public static function PopupGoogleLogIn(fnDone:Function, fForcePassword:Boolean=false): void {
			// Show a progress indicator
			var fReturned:Boolean = false;
			
			var bsy:IBusyDialog = null;
			
			var fnHideBusy:Function = function(): void {
				if (bsy != null)
					bsy.Hide();
				bsy = null;
			};
			
			var fLogged:Boolean = false;
			var fnLogResult:Function = function(strResult:String): void {
				if (!fLogged) {
					fLogged = true;
					Util.UrchinLogReport("/googleLogin/successRate/" + strResult);
				}
			};
			
			var fnReturn:Function = function(strResult:String): void {
				if (!fReturned) {
					fReturned = true;
					fnHideBusy();
					if (strResult != null) {
						strResult = StringUtil.trim(strResult);
						if (strResult.length == 0)
							strResult = null;
					}
					fnDone(strResult);
				}
			};
			
			var fnOnCancel:Function = function(obResult:Object): void {
				fnLogResult("cancel");
				fnReturn(null);
			};
			
			var fnOnFailure:Function = function(err:int, errMsg:String, nSeverity:Number=40): void {
				PicnikService.Log("Google login failure:" + err + ", " + errMsg, nSeverity);
				fnReturn(null);
			};

			var strConnectionName:String = "gwa" + Math.random(); // Use a new connection each time in case something goes wrong with the old one and it doesn't get closed.

			var fnOnPopupOpen:Function = function(err:int, errMsg:String, ob:Object): void {
				// listen for new user properties
				if (err != PicnikService.errNone) {
					fnLogResult("popupFailure");
					fnOnFailure(err, errMsg);
				} else {
					var dtStart:Date = new Date();
					var strSuccessMethod:String = "successMethod";
					
					var lconPicasawebSuccess:DynamicLocalConnection = new DynamicLocalConnection();
					lconPicasawebSuccess.allowPicnikDomains();
					lconPicasawebSuccess[strSuccessMethod] = function(strCBParams:String=null): void {
						// the popup succeeded!
						var msElapsed:Number = (new Date()).time - dtStart.time; // Already signed in takes about 900ms. Fast typers logging in on a fast connection take about 3500ms.
						try {
							lconPicasawebSuccess.close();
						} catch (e:Error) {
							trace("ignoring error: " + e);
						}
						try {
							fnReturn(strCBParams);
						} catch (e:Error) {
							trace("ignoring error: " + e);
						}
						var strLog:String;
						if (strCBParams == null || strCBParams.length == 0) {
							strLog = "callbackFailure";
						} else {
							strLog = "success/" + (msElapsed > 3000) ? "manual" : "instant";
						}
						fnLogResult(strLog);
						DialogManager.HideBlockedPopupDialog();
					};
					
					try {
						// Once we open the connection, we MUST make sure we close it. Otherwise, we won't be able to open a new one.
						lconPicasawebSuccess.connect(strConnectionName);
					} catch (e:Error) {
						trace("ignoring error: " + e);
						fnLogResult("connectionFailure");
						fnOnFailure(PicnikService.errFail, "could not open connection");
					}
				}
			}

			// Show the busy dialog
			bsy = BusyDialogBase.Show(Application.application as UIComponent,
					// StringUtil.substitute( Resource.getString("BuzzOutBridge", "preparing_to_buzz"),
					"Logging in to Google", BusyDialogBase.OTHER,
				"", 0, fnOnCancel);

			fnLogResult("started");

			// Pop up the window
			PicnikBase.app.NavigateToURLInPopup(PicnikService.serverURL + "/auth/goog/popup/?fpass=" + fForcePassword + "&dcon=" + strConnectionName, 775, 800, fnOnPopupOpen);
		}
	}
}