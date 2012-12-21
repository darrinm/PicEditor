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
    import api.RpcResponse;
   
    import com.adobe.crypto.MD5;
   
    import controls.ErrorTip;
    import controls.NoTipTextInput;
   
    import dialogs.EasyDialog;
    import dialogs.EasyDialogBase;
   
    import flash.events.KeyboardEvent;
    import flash.geom.Point;
    import flash.ui.Keyboard;
   
    import mx.containers.Canvas;
    import mx.controls.Label;
    import mx.effects.Sequence;
    import mx.events.FlexEvent;
   
    import util.UserEmailDictionary;
    import util.UsernameDictionary;
   
    import validators.EmailValidatorPlus;
	
	public class ForgotPasswordResetTabBase extends RegisterBoxBase
	{
		[Bindable] public var _effError:Sequence;
		[Bindable] public var _tiEmail:NoTipTextInput;
		[Bindable] public var _tiPassword:NoTipTextInput;
		[Bindable] public var _lblPwError:Label;
		[Bindable] public var _etEmail:ErrorTip;
		[Bindable] public var _cvsRoot:Canvas;
		[Bindable] public var _vldEmail:EmailValidatorPlus;
		[Bindable] public var _strSuccessFeedbackMessage:String;
		[Bindable] public var _strAccountNotFoundError:String;
		
		private var _fCheckPasswordToken:Boolean = true;
	
		public function ForgotPasswordResetTabBase():void {
			addEventListener(FlexEvent.UPDATE_COMPLETE, OnUpdateComplete);
		}
		
		public function ResetPasswordKeyEvent(event:KeyboardEvent):void
		{
			// BST: buttons treat space as a click, let the button handle those.
			if (event.keyCode == Keyboard.ESCAPE || event.keyCode == Keyboard.TAB || event.keyCode == Keyboard.SPACE)
				return;
			ResetPassword();
		}
		
		// User clicked a button (etc) to submit the form
		public function ResetPassword(): void {
			// First, make sure everything is valid
			if (dataModel.validateAll()) {
				DoResetPassword();	
			} else {
				_effError.end();
				_effError.play();
			}
		}
		
		public override function OnSelect(): void {
			if (!AccountMgr.GetInstance().isGuest)
				AccountMgr.GetInstance().LogOut(null);	// auto-signout when someone gets here
			if (_tiPassword && focusEnabled && focusManager) _tiPassword.setFocus();
			// DEBUG: Don't remember anything across sessions
			UserEmailDictionary.resetGlobal();
			super.OnSelect();
		}

		private function OnCheckPasswordToken(err:Number, strError:String ): void {
			try {
				working = false;
				if (err == PicnikService.errNone) {
					_vldEmail.dict.SetExists(email, true);
					dataModel.validateOne("email");								
				} else {
					OnBadToken();
				}
			} catch (e:Error) {
				PicnikService.Log("Client Exception: in ForgotPasswordResetTabBase.OnUpgradeGuestUserDone: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityError);
				throw e;
			}
		}
				
		private function OnBadToken(): void {
			var dlg:EasyDialog =
					EasyDialogBase.Show(
						this,
						[Resource.getString('ForgotPasswordResetTab', 'ok')],
						Resource.getString('ForgotPasswordResetTab', 'oops'),						
						Resource.getString('ForgotPasswordResetTab', 'badLink'),						
						function( obResult:Object ):void {
							formOwner.SelectForm( 'ForgotPW', {email:email} );
						}
					);		
		}
				
		private function OnUpdateComplete( evt:FlexEvent ):void {
			// position the tooltips
			var pt:Point;
			var ptZero:Point;
			
			ptZero = new Point( 0,0 );
			ptZero = this.localToGlobal( ptZero );
			
			if (_tiEmail && _etEmail) {
				pt = new Point(_tiEmail.x,_tiEmail.y);
				pt = _tiEmail.localToGlobal(pt);
				_etEmail.y = pt.y + 13 - _etEmail.height/2 - ptZero.y;
			}			
			
			// validate email address and token, once, when we've got some data
			if (email && token && _fCheckPasswordToken) {
				working = true;
				_fCheckPasswordToken = false;
				PicnikService.CheckPasswordToken( email, token, OnCheckPasswordToken );						
			}
		}
		
		public function get token(): String {
			return GetFieldValue("token") as String;
		}
		
		public function get email(): String {
			return GetFieldValue("email") as String;
		}
		
		private function get password(): String {
			return GetFieldValue("password") as String;
		}
		
		private function DoResetPassword(): void {
			try {
				// DEBUG: Don't remember anything across sessions
				UserEmailDictionary.resetGlobal();
				UsernameDictionary.resetGlobal();
				PicnikService.Log("ForgotPasswordResetTabBase.UpgradeGuestUser: start", PicnikService.knLogSeverityDebug);
				working = true;
				PicnikService.ResetPassword(email, token, MD5.hash(password), OnResetPassword);
			} catch (e:Error) {
				PicnikService.Log("Client Exception: in ForgotPasswordResetTabBase.UpgradeGuestUser: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityError);
				throw e;
			}
		}
	
		
		private function OnResetPassword(err:Number, strError:String, obResult:Object=null): void {
			try {
				PicnikService.Log("ForgotPasswordResetTabBase.OnResetPassword: password reset email=" + email + ", token=" + token, PicnikService.knLogSeverityDebug);
				if (err == PicnikService.errNone) {
					PicnikService.Log("ForgotPasswordResetTabBase.OnResetPassword: password reset successful. email=" + email + ", token=" + token, PicnikService.knLogSeverityDebug);
					AccountMgr.GetInstance().UserInitiatedLogIn(AccountMgr.GetPicnikLogInCredentials(obResult['strUserName'], password), OnLoginUser);
				} else {
					working = false;
					OnBadToken();
				}
			} catch (e:Error) {
				PicnikService.Log("Client Exception: in ForgotPasswordResetTabBase.OnResetPassword: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityError);
				throw e;
			}
		}
		

		private function OnLoginUser(resp:RpcResponse): void { //err:Number, strError:String,strUserName:String=null, fCreated:Boolean=false, fOtherAccts:Boolean=false)
			try {
				working = false;
				PicnikService.Log("ForgotPasswordResetTabBase.OnResetPassword: password reset email=" + email + ", token=" + token, PicnikService.knLogSeverityDebug);
				if (!resp.isError) {
					PicnikService.Log("ForgotPasswordResetTabBase.OnResetPassword: password reset successful. email=" + email + ", token=" + token, PicnikService.knLogSeverityDebug);
					
					dataModel.resetAll();
					Hide();
					PicnikBase.app.FinishLogOn();
					PicnikBase.app.Notify(_strSuccessFeedbackMessage,500);
				} else {
					OnBadToken();
				}
			} catch (e:Error) {
				PicnikService.Log("Client Exception: in ForgotPasswordResetTabBase.OnLoginUser: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityError);
				throw e;
			}
		}		
	}
}
