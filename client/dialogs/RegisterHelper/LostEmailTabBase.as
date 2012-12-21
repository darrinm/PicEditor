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
	import validators.Last4Validator;

	public class LostEmailTabBase extends RegisterBoxBase
	{
		[Bindable] public var _vldEmail:EmailValidatorPlus;
		[Bindable] public var _vldLast4:Last4Validator;
		[Bindable] public var _strSuccessFeedbackMessage:String;
		[Bindable] public var _tiOldUsernameOrEmail:NoTipTextInput;
		[Bindable] public var _tiEmail:NoTipTextInput;
		[Bindable] public var _tiLast4:NoTipTextInput;
		[Bindable] public var _tiNoc:NoTipTextInput;
		[Bindable] public var _effError:Sequence;
		[Bindable] public var showSendButton:Boolean = true;
		[Bindable] [ResourceBundle("LostEmailTab")] protected var rb:ResourceBundle;
		[Bindable] public var sendClickOverride:Function = null;
		[Bindable] public var footerVisible:Boolean = false;
		
		public function OnSendClick(): void {
			if (sendClickOverride != null) {
				sendClickOverride();
			} else {
				SendNewPassword();
			}
		}
		
		// User clicked a button (etc) to submit the form
		// fnDone(fSuccess:Boolean): void
		public function SendNewPassword(): void {
			// First, make sure everything is valid
			if (dataModel.validateAll()) {
				// Do the form submission
				working = true;
				PicnikService.LostEmail(oldUsernameOrEmail, newEmail, last4, OnLostEmailFinished);
			} else {
				if (_effError)
					_effError.play();
			}
		}
		
		public function OnUsernameOrLast4Changed() : void {
			if (_vldLast4.last4RejectedByServer) {
				// If the value of last4 that we sent to the server was rejected, and the user
				// changes something that might produce a different result, then clear that state.
				_vldLast4.last4RejectedByServer = false;
				_vldLast4.validate();
			}
		}

		public override function OnSelect(): void {
			if (_tiNoc && focusEnabled && focusManager) {
				_tiNoc.setFocus();
			}
			footerVisible = false;
			super.OnSelect();
		}
		
		protected function get oldUsernameOrEmail(): String {
			return GetFieldValue("oldUsernameOrEmail").toString();
		}
		
		protected function get newEmail(): String {
			return GetFieldValue("newEmail").toString();
		}
		
		protected function get last4(): String {
			return GetFieldValue("last4").toString();
		}
		
		private function HandleSuccess(): void {
			_vldEmail.dict.SetExists(newEmail, true);
			if (isUpgrading) {
				// Tell user the mail was sent, then immediately
				// switch back to login dialog when they dismiss.
				formOwner.SelectForm( 'ForgotPWSent', {email:newEmail, back_to_login:true} );
			} else if (registerAction == RegisterDialogBase.REDEEM_GIFT) {
				// Switch back to login dialog.
				formOwner.SelectForm( 'LoginForRedeemGift' );
			} else {
				if (formOwner)
					formOwner.SelectForm( 'ForgotPWSent', {email:newEmail} );
			}
		}

		// fnDone(fSuccess:Boolean): void
		private function OnLostEmailFinished(err:Number, strError:String): void {
			working = false;
			switch (err) {
				case PicnikService.errNone:
					HandleSuccess();
					return;

				case PicnikService.errUserNotPremium:
					_tiOldUsernameOrEmail.errorString = Resource.getString('LostEmailTab', 'error_not_premium');
					_tiOldUsernameOrEmail.setFocus();
					_tiOldUsernameOrEmail.setSelection(0, _tiOldUsernameOrEmail.text.length);
					break;
				
				case PicnikService.errGoogleAccount:
					_tiOldUsernameOrEmail.errorString = Resource.getString('LostEmailTab', 'error_google_account');
					_tiOldUsernameOrEmail.setFocus();
					_tiOldUsernameOrEmail.setSelection(0, _tiOldUsernameOrEmail.text.length);
					break;
				
				case PicnikService.errUnknownAccount:
					_tiOldUsernameOrEmail.errorString = Resource.getString('LostEmailTab', '_vldUsername');
					_tiOldUsernameOrEmail.setFocus();
					_tiOldUsernameOrEmail.setSelection(0, _tiOldUsernameOrEmail.text.length);
					break;
				
				case PicnikService.errInvalidEmail:
				case PicnikService.errEmailAlreadyExists:
					_tiEmail.errorString = Resource.getString('LostEmailTab', (err == PicnikService.errInvalidEmail) ? '_vldEmail_1' : '_vldEmailAddressTaken');
					_tiEmail.setFocus();
					_tiEmail.setSelection(0, _tiEmail.text.length);
					break;
				
				case PicnikService.errBadParams:
					// Force the last4 validator into the invalid state, and trigger re-validation on that field
					_vldLast4.last4RejectedByServer = true;
					_vldLast4.validate();
					_tiLast4.setFocus();
					_tiLast4.setSelection(0, _tiLast4.text.length);
					break;
				
				default:
					PicnikAlert.show(LocUtil.rbSubst('LostEmailTab', 'unknown_error', err));
					break;
			}
			footerVisible = true;
		}
	}
}