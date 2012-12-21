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
    import com.adobe.crypto.MD5;
   
    import controls.ErrorTip;
    import controls.NoTipTextInput;
   
    import flash.events.KeyboardEvent;
    import flash.geom.Point;
    import flash.ui.Keyboard;
   
    import mx.containers.Canvas;
	import mx.controls.Alert;
	import mx.controls.CheckBox;
    import mx.controls.Label;
    import mx.effects.Sequence;
    import mx.events.FlexEvent;
    import mx.resources.ResourceBundle;
   
	import util.PicnikAlert;
   
    import validators.EmailValidatorPlus;
	import validators.CurrentPasswordValidator;
	
	public class ChangeEmailTabBase extends RegisterBoxBase
	{
		[Bindable] public var _effError:Sequence;
		[Bindable] public var _tiOldPassword:NoTipTextInput;
		[Bindable] public var _vldOldPassword:CurrentPasswordValidator;
		[Bindable] public var _tiEmail:NoTipTextInput;
		[Bindable] public var _tiEmailAgain:NoTipTextInput;
		[Bindable] public var _cbWantsMail:CheckBox;
		[Bindable] public var _lblEmError:Label;
		[Bindable] public var _cvsRoot:Canvas;
		[Bindable] public var _strSuccessFeedbackMessage:String;
		[Bindable] public var _strOldPasswordIncorrectError:String;
		
		[Bindable] public var requirePassword:Boolean = true;

   		[Bindable] [ResourceBundle("ChangeEmailTab")] protected var rb:ResourceBundle;

		public function ChangeEmailTabBase():void {
		}
		
		// User clicked a button (etc) to submit the form
		public function ChangeEmail(): void {
			if (email == oldEmail && wantsmail == oldWantsmail && oldPassword.length == 0) {
				// nothing changed, so just close the dlg
				Hide();
			} else {
				// Make sure everything is valid
				if (dataModel.validateAll()) {
					if (requirePassword) {
						// Lookup the old password in the db
						working = true;
						var strMD5Pass:String = MD5.hash(oldPassword);
						PicnikService.PasswordCorrect(strMD5Pass, OnPasswordCorrect);
					} else {
						CommitChange();
					}
				} else {
					DoErrorEffect();
				}
			}
		}
		
		public override function OnSelect(): void {
			if (_tiOldPassword && focusEnabled && focusManager) _tiOldPassword.setFocus();
			if (_tiEmail) _tiEmail.text = oldEmail;
			if (_tiEmailAgain) _tiEmailAgain.text = oldEmail;
			if (_cbWantsMail) _cbWantsMail.selected = oldWantsmail;
			if (_tiOldPassword) _tiOldPassword.text = "";			
			if (_vldOldPassword) _vldOldPassword.resetDictionary();
			
			dataModel.ClearErrors();
			super.OnSelect();
		}
				
		private function get email(): String {
			return GetFieldValue("email") as String;
		}
		
		private function get oldEmail(): String {
			return AccountMgr.GetInstance().GetUserAttribute("email");
		}
		
		private function get wantsmail(): Boolean {
			return GetFieldValue("wantsmail") as Boolean;
		}
		
		private function get oldWantsmail(): Boolean {
			return AccountMgr.GetInstance().GetUserAttribute("wantsmail") != "N";
		}
		
		private function get oldPassword(): String {
			return GetFieldValue("oldpassword") as String;
		}

		private function OnPasswordCorrect(err:Number, strError:String, obData:Object=null): void {
			working = false;
			if (err == 0) {
				var fCorrect:Boolean = obData["correct"] as Boolean;
				if (fCorrect == true || !AccountMgr.GetInstance().hasCredentials) {
					CommitChange();
				} else {
					// Old password is incorrect. Force an error
					_tiOldPassword.errorString = _strOldPasswordIncorrectError;
				}
			} else {
				// There was some sort of error
				Util.ShowAlert(Resource.getString('ChangeEmailTab', 'unknown_error'), Resource.getString('ChangeEmailTab', 'error'), Alert.OK,
						"change email tab base unknown error: " + err + ", " + strError);
			}
		}
		
		private function CommitChange(): void {
			if (email.length > 0) AccountMgr.GetInstance().SetUserAttribute("email", email, false);							   
			AccountMgr.GetInstance().SetUserAttribute("wantsmail", wantsmail ? "Y" : "N", false);
			AccountMgr.GetInstance().FlushUserAttributes();					
			Hide();
			PicnikBase.app.Notify(_strSuccessFeedbackMessage);
		}
	}
}
