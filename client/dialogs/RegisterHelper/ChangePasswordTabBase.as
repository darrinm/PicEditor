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
    import mx.controls.Label;
    import mx.effects.Sequence;
    import mx.events.FlexEvent;
    import mx.resources.ResourceBundle;
   
	import util.PicnikAlert;
   
    import validators.EmailValidatorPlus;
	
	public class ChangePasswordTabBase extends RegisterBoxBase
	{
		[Bindable] public var _tiOldPassword:NoTipTextInput;
		[Bindable] public var _tiPassword:NoTipTextInput;
		[Bindable] public var _lblPwError:Label;
		[Bindable] public var _cvsRoot:Canvas;
		[Bindable] public var _strSuccessFeedbackMessage:String;
		[Bindable] public var _strOldPasswordIncorrectError:String;

		[Bindable] public var requirePassword:Boolean = true;

   		[Bindable] [ResourceBundle("ChangePasswordTab")] protected var rb:ResourceBundle;

		public function ChangePasswordTabBase():void {
		}
		
		// User clicked a button (etc) to submit the form
		public function ChangePassword(): void {
			if (password.length == 0 && oldPassword.length == 0) {
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
					this.DoErrorEffect();
				}
			}
		}
		
		public override function OnSelect(): void {
			if (_tiOldPassword && focusEnabled && focusManager) _tiOldPassword.setFocus();
			// DEBUG: Don't remember anything across sessions
			super.OnSelect();
		}
				
		private function get password(): String {
			return GetFieldValue("password") as String;
		}

		private function get md5password(): String {
			return MD5.hash(password);
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
				Util.ShowAlert(Resource.getString('ChangePasswordTab', 'unknown_error'), Resource.getString('ChangePasswordTab', 'error'), Alert.OK, "change password tab base error: " + err + ", " + strError);
			}
		}
		
		private function CommitChange(): void {
			AccountMgr.GetInstance().SetUserAttribute("password", md5password, false);
			AccountMgr.GetInstance().FlushUserAttributes();					
			Hide();
			PicnikBase.app.Notify(_strSuccessFeedbackMessage);
		}		
	}
}
