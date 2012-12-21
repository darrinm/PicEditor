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
package dialogs.RegisterHelper
{
    import api.PicnikRpc;
    import api.RpcResponse;
   
    import com.adobe.utils.StringUtil;
   
    import controls.ErrorTip;
    import controls.NoTipTextInput;
   
    import dialogs.RegisterDialogBase;
   
    import flash.geom.Point;
   
    import mx.controls.Label;
    import mx.events.FlexEvent;
    import mx.resources.ResourceBundle;
   
    import util.GoogleUtil;
    import util.KeyVault;
    import util.LocUtil;
    import util.PicnikAlert;
    import util.UserEmailDictionary;
    import util.UsernameDictionary;
	
	public class LoginTabBase extends RegisterBoxBase
	{
		[Bindable] protected var _fDoWeKnowYou:Boolean = false;
		
		[Bindable] public var _tiUsername:NoTipTextInput;
		[Bindable] public var _tiPassword:NoTipTextInput;
		[Bindable] public var _etUsernameNotFound:ErrorTip;		
		[Bindable] public var _lblPwError:Label;
		[Bindable] public var systemError:String = "";
		[Bindable] public var unknownAccountError:Boolean = false;
		[Bindable] public var _strSuccessFeedbackMessage:String;
		[Bindable] public var _strAccountNotFoundError:String;
		[Bindable] public var showSignInButton:Boolean = true;
		[Bindable] public var hideGoogleLogin:Boolean = false;
		[Bindable] protected var googleLoginVisible:Boolean = true;
		[Bindable] public var submitOverride:Function = null;

   		[Bindable] [ResourceBundle("LoginTab")] protected var rb:ResourceBundle;
		
		public function LoginTabBase():void {
			addEventListener(FlexEvent.UPDATE_COMPLETE, OnUpdateComplete);			
		}		

		protected function OnLoginClick(): void {
			if (submitOverride != null)
				submitOverride();
			else
				Login();
		}
		
		public override function OnSelect(): void {
			_fLogGoogleResults = true;
			if (_tiUsername && focusEnabled && focusManager) _tiUsername.setFocus();
			
			// DEBUG: Don't remember anything across sessions
			UserEmailDictionary.resetGlobal();
			UsernameDictionary.resetGlobal();
			if (_tiPassword) _tiPassword.text = ""; // Clear passwords on selection
			super.OnSelect();
		}
		
		override protected function DoGoogleLogIn(): void {
			// Do the google log in popup.
			GoogleUtil.PopupGoogleLogIn(function(strToken:String): void {
				if (strToken != null)
					DoLogin(AccountMgr.GetGoogleLogInCredentials(strToken));
			});
		}
		
		public function set doWeKnowYou(f:Boolean): void {
			_fDoWeKnowYou = f;
			updateStateIfNeeded();
		}
		
		// User clicked a button (etc) to submit the form
		public function Login(): void {
			// First, make sure everything is valid
			if (dataModel.validateAll()) {
				DoLogin();
			} else {
				DoErrorEffect();
			}
		}
		
		private function ShowErrorResponse(resp:RpcResponse, fHideOnPolicyFail:Boolean=true): void {
			if (resp.errorCode == PicnikService.errInvalidUserName || resp.errorCode == PicnikService.errUnknownAccount) {
				// Validation will clear any previous "password incorrect" error and start a hide effect on error label.
				// In case this shows the label, make sure stop any hide effects.
				_lblPwError.endEffectsStarted();
				unknownAccountError = true;
				_tiPassword.errorString = _strAccountNotFoundError;
				
				// Place the focus on the offending field, with it selected for easy type-over
				_tiPassword.setFocus();
				_tiPassword.setSelection(0, _tiPassword.text.length);
				DoErrorEffect();
			} else if (resp.errorCode == PicnikService.errCancelled) {
				if (fHideOnPolicyFail)
					Hide(); // Privacy policy log in canceled
			} else {
				systemError = resp.errorMessage;
				PicnikAlert.show(LocUtil.rbSubst('LoginTab', 'login_failed', resp.errorCode));
			}
		}
		
		// function fnDone(obResult): void
		// fnDone called on success
		// obResult will contain: strUserId, dLogInServices, obCredentials
		public function TestCredentials(fnDone:Function): void {
			if (dataModel.validateAll()) {
					var obCredentials:Object = AccountMgr.GetPicnikLogInCredentials(username, password);
					
					// Don't remember anything across sessions
					UserEmailDictionary.resetGlobal();
					UsernameDictionary.resetGlobal();
					working = true;
					PicnikRpc.TestCredentials(obCredentials, function(resp:RpcResponse): void {
						working = false;
						systemError = "";
						unknownAccountError = false;
						resp.errorCode = resp.data.nErrorCode; // Make the response more like a login response
						if (resp.isError) {
							ShowErrorResponse(resp, false);
						} else {
							// Success
							resp.data.obCredentials = obCredentials;
							fnDone(resp.data);
						}
					});
			} else {
				DoErrorEffect();
			}
		}

		protected override function updateState(): void {
			if (_fDoWeKnowYou)
				currentState = "DoWeKnowYou";
			else
				super.updateState();
		}

		private function get password(): String {
			return GetFieldValue("password") as String;
		}
		
		public function get username(): String {
			return GetFieldValue("username") as String;
		}
		
		private function DoLogin(obCredentials:Object=null): void {
			try {
				if (obCredentials == null)
					obCredentials = AccountMgr.GetPicnikLogInCredentials(username, password);

				UpgradePathTracker.LogPageView(logEventBase, 'Submitted', 'SignIn');
				
				// DEBUG: Don't remember anything across sessions
				UserEmailDictionary.resetGlobal();
				UsernameDictionary.resetGlobal();
				PicnikService.Log("LoginTabBase.DoLogin: start", PicnikService.knLogSeverityDebug);
				working = true;
				var fGoogle:Boolean = ('authservice' in obCredentials) && obCredentials.authservice == 'google';
				AccountMgr.GetInstance().UserInitiatedLogIn(obCredentials, function(resp:RpcResponse): void {OnLogInUserComplete(resp, fGoogle)});
			} catch (e:Error) {
				PicnikService.Log("Client Exception: in LoginTabBase.DoLogin: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityError);
				throw e;
			}
		}
		
		private function OnLogInUserComplete(resp:RpcResponse, fGoogle:Boolean=false): void {
			try {
				working = false;
				systemError = "";
				unknownAccountError = false;
				if (resp.isError) {
					ShowErrorResponse(resp);
				} else {
					// Success
					UpgradePathTracker.LogPageView(logEventBase, 'Success', 'SignIn');
					LogGoogleResults(fGoogle ? "googleLogin" : "picnikLogin");
					PicnikBase.app.FinishLogOn();
					if (registerAction == RegisterDialogBase.UPGRADE_PAYMENT_SELECTOR) {
						formOwner.SelectForm( "PaymentSelector" );
					} else if (registerAction == RegisterDialogBase.UPGRADE_CREDIT) {
						if(KeyVault.GetInstance().fNewPaymentSystem == 'true')
							Hide();
						else
							formOwner.SelectForm( "Order" );
					} else if (registerAction == RegisterDialogBase.UPGRADE_PAYPAL) {
						formOwner.SelectForm( "OrderPayPal" );
					} else if (registerAction == RegisterDialogBase.REDEEM_GIFT) {
						formOwner.SelectForm( "RedeemGift" );
					} else {
						Hide();
						PicnikBase.app.Notify(_strSuccessFeedbackMessage,500);
					}
				}
			} catch (e:Error) {
				PicnikService.Log("Client Exception: in LoginTabBase.OnDoLoginComplete: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityError);
				throw e;
			}		
		}

		private function OnUpdateComplete( evt:FlexEvent ):void {
			// position the tooltips
			var pt:Point;
			var ptZero:Point;
			
			ptZero = new Point( 0,0 );
			ptZero = this.localToGlobal( ptZero );
			
			if (_tiUsername && _etUsernameNotFound) {
				pt = new Point(_tiUsername.x,_tiUsername.y);
				pt = _tiUsername.localToGlobal(pt);
				_etUsernameNotFound.y = pt.y + 13 - _etUsernameNotFound.height/2 - ptZero.y;
			}
		}		
	}
}
