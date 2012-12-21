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
   
    import com.adobe.crypto.MD5;
   
    import controls.ErrorTip;
    import controls.NoTipTextInput;
   
    import dialogs.RegisterDialogBase;
   
    import flash.events.KeyboardEvent;
    import flash.events.TextEvent;
    import flash.geom.Point;
    import flash.net.URLRequest;
    import flash.ui.Keyboard;
   
    import mx.containers.Canvas;
    import mx.events.FlexEvent;
    import mx.resources.ResourceBundle;
   
    import util.ABTest;
    import util.GoogleUtil;
    import util.NextNavigationTracker;
    import util.PicnikAlert;
    import util.UserBucketManager;
    import util.UserEmailDictionary;
    import util.UsernameDictionary;
	
	public class RegisterTabBase extends RegisterBoxBase
	{
		[Bindable] public var _strSuccessFeedbackMessage:String;
		[Bindable] public var _tiUsername:NoTipTextInput;
		[Bindable] public var _tiEmail:NoTipTextInput;
		[Bindable] public var _etUsername:ErrorTip;
		[Bindable] public var _etEmail:ErrorTip;
		[Bindable] public var _cvsRoot:Canvas;

   		[Bindable] [ResourceBundle("RegisterTab")] protected var rb:ResourceBundle;

		public function RegisterTabBase():void {
			addEventListener(FlexEvent.UPDATE_COMPLETE, OnUpdateComplete);
		}	
		
		override protected function DoGoogleLogIn(): void {
			// Do the google log in popup.
			GoogleUtil.PopupGoogleLogIn(function(strToken:String): void {
				if (strToken != null) {
					working = true;
					AccountMgr.GetInstance().UserInitiatedLogIn(AccountMgr.GetGoogleLogInCredentials(strToken), OnGoogleLoginComplete);
				}
			});
		}
		
		private function OnGoogleLoginComplete(resp:RpcResponse): void {
			working = false;
			if (resp.isError) {
				// Handle google login errors?
			} else {
				UpgradePathTracker.LogPageView(logEventBase, 'Success', 'GoogleSignIn');
				PicnikBase.app.FinishLogOn();
				
				// clear out the fields so that everything stays private
				dataModel.resetAll();
				LogGoogleResults("googleLogin");
				
				if (registerAction != RegisterDialogBase.NO_ACTION) {
					OnUpgradeComplete(); // Continue
				} else {
					// All done. Close the window.
					Hide();
				}
			}
		}
		
		public function CreateAccountKeyEvent(event:KeyboardEvent):void
		{
			// BST: buttons treat space as a click, let the button handle those.
			if (event.keyCode == Keyboard.ESCAPE || event.keyCode == Keyboard.TAB || event.keyCode == Keyboard.SPACE)
				return;
			CreateAccount();
		}
		
		// User clicked a button (etc) to submit the form
		public function CreateAccount(): void {
			NextNavigationTracker.OnClick("/create_account");
			UpgradePathTracker.LogPageView(logEventBase, 'Submitted', 'Register');
			
			// First, make sure everything is valid
			if (dataModel.validateAll()) {
				if (AccountMgr.GetInstance().isGuest) {
					UpgradeGuestUser();	
				} else {
					// we're a third-party account.  Just update ourselves in-place.
					AccountMgr.GetInstance().SetUserAttribute("name", username, false);
					AccountMgr.GetInstance().SetUserAttribute("email", email, false);
					AccountMgr.GetInstance().SetUserAttribute("password", MD5.hash(password), false);
					AccountMgr.GetInstance().SetUserAttribute("wantsmail", wantsmail, false);
					AccountMgr.GetInstance().FlushUserAttributes();
					PicnikRpc.SetUserProperties({ "accepted": "true" }, "privacypolicy");
					
					PicnikService.Log("RegisterTabBase.Converted TP account: name=" + username + ", email=" + email + ", wantsmail=" + wantsmail, PicnikService.knLogSeverityDebug);
					
					UserBucketManager.GetInst().OnUserRegistered();
					
					UpgradePathTracker.LogPageView(logEventBase, 'Success', 'Register');
					
					// clear out the fields so that everything stays private
					dataModel.resetAll();
					LogGoogleResults("picnikRegister");
					// It worked. Now update our application state (username, not guest, email, etc)					
					// Finally, hide this dialog and show the "Account Created" message
					if (registerAction != RegisterDialogBase.NO_ACTION) {
						AccountMgr.GetInstance().GuestUserUpgraded(OnUpgradeComplete);
					} else {
						working = false;
						AccountMgr.GetInstance().GuestUserUpgraded();
						formOwner.SelectForm( 'Survey' );						
					}
					ABTest.HandleRegistration();
				}
				
				// Do the form submission
			} else {
				DoErrorEffect();
			}
		}
		
		public override function OnSelect(): void {
			_fLogGoogleResults = true;
			if (_tiUsername && focusEnabled && focusManager) _tiUsername.setFocus();
			// DEBUG: Don't remember anything across sessions
			//UserEmailDictionary.resetGlobal();
			//UsernameDictionary.resetGlobal();
			
			super.OnSelect();
			LayoutTips();
		}
		
		private function OnUpdateComplete( evt:FlexEvent=null ):void {
			LayoutTips();
		}
		
		private function LayoutTips():void {
			// position the tooltips
			var pt:Point;
			var ptZero:Point;
			
			ptZero = new Point( 0,0 );
			ptZero = this.localToGlobal( ptZero );
			
			var nStateOffset:Number = currentState == "Inline" ? 8 : 13;
			
			if (_tiEmail && _etEmail) {
				pt = new Point(_tiEmail.x,_tiEmail.y);
				pt = _tiEmail.localToGlobal(pt);
				_etEmail.y = pt.y + nStateOffset - _etEmail.height/2 - ptZero.y;
			}
			
			if (_tiUsername && _etUsername) {
				pt = new Point(_tiUsername.x,_tiUsername.y);
				pt = _tiUsername.localToGlobal(pt);
				_etUsername.y = pt.y + nStateOffset - _etUsername.height/2 - ptZero.y;
			}			
		}
		
		public function get email(): String {
			return GetFieldValue("email") as String;
		}
		
		private function get password(): String {
			return GetFieldValue("password") as String;
		}
		
		public function get username(): String {
			return GetFieldValue("username") as String;
		}
		
		private function get wantsmail(): Boolean {
			return GetFieldValue("wantsmail") as Boolean;
		}

		private function UpgradeGuestUser(): void {
			try {
				// DEBUG: Don't remember anything across sessions
				UserEmailDictionary.resetGlobal();
				UsernameDictionary.resetGlobal();
				PicnikService.Log("RegisterTabBase.UpgradeGuestUser: start", PicnikService.knLogSeverityDebug);
				var obParams:Object = {username:username, md5pass:MD5.hash(password), email:email, wantsmail:wantsmail, privacypolicyaccepted:true};
				working = true;
				PicnikService.UpgradeGuestUser(obParams, OnUpgradeGuestUserDone);
			} catch (e:Error) {
				PicnikService.Log("Client Exception: in RegisterTabBase.UpgradeGuestUser: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityError);
				throw e;
			}
		}
	
		// Called when we completed upgrading and we want to go to the order tab	
		private function OnUpgradeComplete(): void {
			working = false;
			if (registerAction == RegisterDialogBase.UPGRADE_PAYMENT_SELECTOR) {
				formOwner.SelectForm( "PaymentSelector" );
			} else if (registerAction == RegisterDialogBase.UPGRADE_CREDIT) {
				formOwner.SelectForm( "Order" );
			} else if (registerAction == RegisterDialogBase.UPGRADE_PAYPAL) {
				formOwner.SelectForm( "OrderPayPal" );
			} else if (registerAction == RegisterDialogBase.REDEEM_GIFT) {
				formOwner.SelectForm( "RedeemGift" );
			}
		}
		
		private function OnUpgradeGuestUserDone(err:Number, strError:String, strUserName:String = null, fCreated:Boolean=false, fOtherAccts:Boolean=false): void {
			try {
				PicnikService.Log("RegisterTabBase.OnUpgradeGuestUserDone: start. username=" + username + ", email=" + email + ", wantsmail=" + wantsmail, PicnikService.knLogSeverityDebug);
				if (err == PicnikService.errNone) {
					PicnikService.Log("RegisterTabBase.OnUpgradeGuestUserDone: success. username=" + username + ", email=" + email + ", wantsmail=" + wantsmail, PicnikService.knLogSeverityDebug);
					UpgradePathTracker.LogPageView(logEventBase, 'Success', 'Register');
					UserBucketManager.GetInst().OnUserRegistered();
					
					// clear out the fields so that everything stays private
					dataModel.resetAll();
					
					// It worked. Now update our application state (username, not guest, email, etc)
					
					// Finally, hide this dialog and show the "Account Created" message
					if (registerAction != RegisterDialogBase.NO_ACTION) {
						AccountMgr.GetInstance().GuestUserUpgraded(OnUpgradeComplete);
					} else {
						working = false;
						AccountMgr.GetInstance().GuestUserUpgraded();
						formOwner.SelectForm( 'Survey' );
					}
				} else {
					working = false;
					if (err == PicnikService.errUsernameAlreadyExists) {
						PicnikService.Log("RegisterTabBase.OnUpgradeGuestUserDone: error, username exists. username=" + username + ", email=" + email + ", wantsmail=" + wantsmail, PicnikService.knLogSeverityDebug);
						UsernameDictionary.global.SetExists(username, true);
						if (dataModel.validateAll()) {
							// We shouldn't get here
							PicnikAlert.show(Resource.getString('RegisterTab', 'usernameExistsError'));
						}
					} else if (err == PicnikService.errEmailAlreadyExists) {
						PicnikService.Log("RegisterTabBase.OnUpgradeGuestUserDone: error, email exists. username=" + username + ", email=" + email + ", wantsmail=" + wantsmail, PicnikService.knLogSeverityDebug);
						UserEmailDictionary.global.SetExists(email, true);
						if (dataModel.validateAll()) {
							// We shouldn't get here
							PicnikAlert.show(Resource.getString('RegisterTab', 'emailExistsError'));
						}
					} else if (err == PicnikService.errInvalidUserName) {
						PicnikService.Log("RegisterTabBase.OnUpgradeGuestUserDone: error, username invalid. username=" + username + ", email=" + email + ", wantsmail=" + wantsmail, PicnikService.knLogSeverityDebug);
						PicnikAlert.show(Resource.getString('RegisterTab', 'usernameInvalidError'));
					} else if (err == PicnikService.errInvalidEmail) {
						PicnikService.Log("RegisterTabBase.OnUpgradeGuestUserDone: error, email invalid. username=" + username + ", email=" + email + ", wantsmail=" + wantsmail, PicnikService.knLogSeverityDebug);
						PicnikAlert.show(Resource.getString('RegisterTab', 'emailsInvalidError'));
					} else if (err == PicnikService.errInvalidPassword) {
						PicnikService.Log("RegisterTabBase.OnUpgradeGuestUserDone: error, password invalid. username=" + username + ", email=" + email + ", wantsmail=" + wantsmail, PicnikService.knLogSeverityDebug);
						PicnikAlert.show(Resource.getString('RegisterTab', 'passwordInvalidError'));
					} else {
						PicnikService.Log("RegisterTabBase.OnUpgradeGuestUserDone: error, unknown: " + strError + ". username=" + username + ", email=" + email + ", wantsmail=" + wantsmail, PicnikService.knLogSeverityDebug);
						// Unknown error
						PicnikAlert.show(Resource.getString('RegisterTab', 'generalFailure'));
					}
				}
				ABTest.HandleRegistration();
			} catch (e:Error) {
				PicnikService.Log("Client Exception: in RegisterTabBase.OnUpgradeGuestUserDone: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityError);
				throw e;
			}
		}
	}
}
