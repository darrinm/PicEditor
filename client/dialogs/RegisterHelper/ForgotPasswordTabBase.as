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
	import controls.NoTipTextInput;
	
	import dialogs.RegisterDialogBase;
	
	import mx.effects.Sequence;
	import mx.resources.ResourceBundle;
	
	import util.LocUtil;
	import util.PicnikAlert;
	
	import validators.EmailValidatorPlus;

	public class ForgotPasswordTabBase extends RegisterBoxBase
	{
		[Bindable] public var _vldEmail:EmailValidatorPlus;
		[Bindable] public var _strSuccessFeedbackMessage:String;
		[Bindable] public var _tiEmail:NoTipTextInput;
		[Bindable] public var _effError:Sequence;
		[Bindable] public var showSendButton:Boolean = true;
   		[Bindable] [ResourceBundle("ForgotPasswordTab")] protected var rb:ResourceBundle;
		[Bindable] public var sendClickOverride:Function = null;
		
		public function OnSendClick(): void {
			if (sendClickOverride != null) {
				sendClickOverride();
			} else {
				SendNewPassword();
			}
		}
		
		// User clicked a button (etc) to submit the form
		// fnDone(fSuccess:Boolean): void
		public function SendNewPassword(fnDone:Function=null): void {
			// First, make sure everything is valid
			if (dataModel.validateAll()) {
				// Do the form submission
				SendForgotPasswordMail(fnDone);
			} else {
				if (_effError) _effError.play();
				if (fnDone != null)
					fnDone(false);
			}
		}

		public override function OnSelect(): void {
			if (_tiEmail && focusEnabled && focusManager) _tiEmail.setFocus();
			super.OnSelect();
		}
		
		protected function get email(): String {
			return GetFieldValue("email").toString();
		}
		
		// fnDone(fSuccess:Boolean): void
		protected function SendForgotPasswordMail(fnDone:Function=null): void {
			working = true;
			PicnikService.ForgotPassword2(email, function(err:Number, strError:String): void {
				OnForgotPassword2(err, strError, fnDone)
			});
		}

		// fnDone(fSuccess:Boolean): void
		private function OnForgotPassword2(err:Number, strError:String, fnDone:Function=null): void {
			working = false;
			if (email.length > 0) {
				if (err == PicnikService.errNone) {
					_vldEmail.dict.SetExists(email, true);
					if (isUpgrading) {
						// Tell user the mail was sent, then immediately
						// switch back to login dialog when they dismiss.
						formOwner.SelectForm( 'ForgotPWSent', {email:email, back_to_login:true} );
					} else if (registerAction == RegisterDialogBase.REDEEM_GIFT) {
						// Switch back to login dialog.
						formOwner.SelectForm( 'LoginForRedeemGift' );
					} else {
						if (formOwner)
							formOwner.SelectForm( 'ForgotPWSent', {email:email} );
					}
					if (fnDone != null)
						fnDone(true);
				} else {
					if (err == PicnikService.errUnknownAccount) {
						_vldEmail.dict.SetExists(email, false);
						dataModel.validateOne("email");
						if (_effError) _effError.play();
					} else {
						PicnikAlert.show(LocUtil.rbSubst('ForgotPasswordTab', 'unknown_error', err));
					}
					if (fnDone != null)
						fnDone(false);
				}
			}
		}
	}
}