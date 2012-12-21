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
package bridges.storageservice {
	import com.adobe.utils.StringUtil;
	
	import dialogs.DialogManager;
	
	import events.LoginEvent;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	
	import mx.containers.Canvas;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.Text;
	import mx.controls.TextInput;
	import mx.core.ScrollPolicy;
	import mx.events.FlexEvent;
	import mx.events.StateChangeEvent;
	import mx.resources.ResourceBundle;
	
	import util.LocUtil;
	
	public class StorageServiceAccountBase extends Canvas {
		// MXML-specified variables
		[Bindable] public var _tiUserName:TextInput;
		[Bindable] public var _tiPassword:TextInput;
		[Bindable] public var _vboxOneConnection:VBox;
		[Bindable] public var _txtOneConnection:Text;
		[Bindable] public var _txtOneConnectionUpsell:Text;
		[Bindable] public var _btnAuthorize:Button;
		[Bindable] public var _tpa:ThirdPartyAccount;
		[Bindable] public var _btnCancel:Button;
		[Bindable] public var _strLoginError:String;
		[Bindable] public var inBasket:Boolean = false;
		
   		[ResourceBundle("StorageServiceAccountBase")] private var _rb:ResourceBundle;

		public function StorageServiceAccountBase() {
			super();
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			verticalScrollPolicy = ScrollPolicy.OFF;
			horizontalScrollPolicy = ScrollPolicy.OFF;
		}
	
		private function OnInitialize(evt:Event): void {
			_btnAuthorize.addEventListener(MouseEvent.CLICK, OnAuthorizeClick);
			addEventListener(StateChangeEvent.CURRENT_STATE_CHANGE, OnCurrentStateChange);
			if (inBasket)
				currentState = "BasketLoginError";
		}
		
		// Remove "Hack" from the end of any names
		private function CleanName(strName:String): String {
			if (strName.length > 4 && strName.substr(strName.length-4,4).toUpperCase() == 'HACK')
				return strName.substr(0,strName.length-4);
			else
				return strName;
		}
		
		public function OnActivate(): void {
			// Who knows what state this StorgeServiceAccount was in when it was last active?
			// Just make sure that if we have no credentials we go into the state where we
			// ask for them. Fixes issue 2912121 which probably came into being when we switched
			// from redirect to popup auth.
			if (!_tpa.HasCredentials() && currentState != "")
				currentState = "";
			
			var strUserId:String = _tpa.GetUserId();
			if (_tiUserName)
				_tiUserName.text = strUserId;
			var strUserToken:String = _tpa.GetToken();
			
			if (strUserToken) {
				currentState = inBasket ? "BasketConnecting" : "Connecting";
				LogIn(strUserId, strUserToken);
			} else if (_tiPassword) {
				_tiPassword.text = "";
			}

			if (_tiUserName)
				_tiUserName.setFocus();
				
			if (_vboxOneConnection) {
				_txtOneConnection.addEventListener( TextEvent.LINK, OnLink );
				_txtOneConnectionUpsell.addEventListener( TextEvent.LINK, OnLink );
				
				// update our connected display depending on whether:
				//	- we've already connected to something else.
				//  - the user isn't premium
				var atpa:Array = AccountMgr.GetInstance().GetConnectedServiceAccounts();
				if (!AccountMgr.GetInstance().isPaid && atpa.length > 0 && !inBasket) {
					_txtOneConnection.htmlText = LocUtil.rbSubst('StorageServiceAccountBase', 'oneConnection', CleanName(atpa[0].name), CleanName(atpa[0].name), CleanName(_tpa.name));
					_txtOneConnectionUpsell.htmlText = LocUtil.rbSubst('StorageServiceAccountBase', 'oneConnectionUpsell', CleanName(atpa[0].name), CleanName(_tpa.name));
					_vboxOneConnection.visible = true;
					_vboxOneConnection.includeInLayout = true;				
				} else {
					_vboxOneConnection.visible = false;
					_vboxOneConnection.includeInLayout = false;
				}
			}		
			
			if (_tpa.storageService.WouldLikeAuth()) {
				PromptForAuth();
			}
		}
		
		public function Logout(): void {
			currentState = "";
			OnActivate();
		}

		protected function PromptForAuth(): void {
			// override in subclasses
		}
		
		protected function OnLink(evt:TextEvent): void {
			if (StringUtil.beginsWith(evt.text.toLowerCase(), "showdialog=")) {
				var strTargetDialog:String = evt.text.substr("showdialog=".length);
				if (strTargetDialog.toLowerCase() == "upgrade") {
					DialogManager.ShowUpgrade( PicnikBase.app.navUpgradePath + "/onebridge", PicnikBase.app);
				}
			}
		}
		
		public function OnAccountError( err:Number, strError:String ): void {
			if (err != StorageServiceError.None) {
				_strLoginError = strError;
				currentState = inBasket ? "BasketLoginError" : "LoginError";
				var strLog:String = "Error talking to";
				if (_tpa) {
					strLog += " " + _tpa.name + ", userID=" + _tpa.GetUserId() + ", token=" + _tpa.GetToken();
					
					// Old credentials are bad. Clear them out.
					_tpa.SetUserId("", false);
					_tpa.SetToken("", true);
					_tpa.storageService.LogOut();
				}
				strLog += ". Error: " + err + ", " + strError;
				PicnikService.Log(strLog, PicnikService.knLogSeverityWarning);
			}
		}
				
		protected function OnEnter(evt:FlexEvent): void {
			if (_btnAuthorize) {
				currentState = inBasket ? "BasketConnecting" : "Connecting";
				Authorize();
			}
		}
		
		private function OnCurrentStateChange(evt:StateChangeEvent): void {
			if (currentState == "" || currentState == "LoginError")
				if (_tiUserName && focusManager)
					_tiUserName.setFocus();
		}
		
		private function OnAuthorizeClick(evt:MouseEvent): void {
			currentState = inBasket ? "BasketConnecting" : "Connecting";
			Authorize();
		}
		
		protected function ClearOtherConnections():void {
			if (!AccountMgr.GetInstance().isPaid && _tpa.IsExclusive() && !_tpa.IsPrimary()) {
				AccountMgr.GetInstance().ClearServiceAccounts(false);
			}			
		}

		protected function Authorize(): void {
			ClearOtherConnections();
			
			// Remember the user's login info
			_tpa.SetUserId(_tiUserName.text, false);
			_tpa.SetToken(_tiPassword.text, true); // flush

			LogIn(_tiUserName.text, _tiPassword.text);
		}		
		
		// Try to log them in.
		private function LogIn(strId:String, strToken:String, fnComplete:Function=null): void {
			//_btnCancel.addEventListener(MouseEvent.CLICK, OnLogInCancelClick);
			try {
				_tpa.storageService.LogIn(_tpa, OnLoginComplete);
			} catch (err:Error) {
				var strLog:String = "Client exception: StorageServiceAccount.LogIn " + err.toString()+ "/" + strId + "/" + strToken + "/" + err.getStackTrace();
				PicnikService.Log(strLog, PicnikService.knLogSeverityError);				
			}
		}
		
		protected function OnLogInCancelClick(evt:MouseEvent): void {
			currentState = inBasket ? "BasketLoginError" : "";
		}
		
		private function OnLoginComplete(err:Number, strError:String): void {
			if (err != StorageServiceError.None) {
				_strLoginError = strError;
				currentState = inBasket ? "BasketLoginError" : "LoginError";
				// logging wasn't useful, so turned off
//				var strLog:String = "Error logging in to storage service";
				if (_tpa) {
//					strLog += _tpa.name + ", userID=" + _tpa.GetUserId() + ", token=" + _tpa.GetToken();
					
					// Old credentials are bad. Clear them out.
					_tpa.SetUserId("", false);
					_tpa.SetToken("", true);
				}
//				strLog += ". Error: " + err + ", " + strError;
//				PicnikService.Log(strLog, PicnikService.knLogSeverityError);
				if (_tiPassword)
					_tiPassword.text = "";
			} else {
				currentState = inBasket ? "BasketLoginError" : "";
				dispatchEvent(new LoginEvent(LoginEvent.LOGIN_COMPLETE, true));
			}
		}
	}
}
