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
package dialogs
{
	
	import com.adobe.crypto.MD5;
	
	import controls.NoTipTextInput;
	import controls.ResizingErrorTip;
	
	import dialogs.RegisterHelper.DataModel;
	
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.RadioButton;
	import mx.core.UIComponent;
	import mx.effects.Sequence;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.managers.PopUpManager;
	
	import util.PicnikAlert;
	import util.PicnikDict;
	import util.UserEmailDictionary;
	
	import validators.CurrentPasswordValidator;
	
	public class ChangeEmailDialogBase extends ChangeWithPasswordDialogBase
	{
		[Bindable] public var _tiEmail:NoTipTextInput;
		[Bindable] public var _tiEmailAgain:NoTipTextInput;
		[Bindable] public var _etEmailExists:ResizingErrorTip;
		[Bindable] public var _cbWantsMail:CheckBox;

		override protected function OnShow():void {
			_cbWantsMail.selected = AccountMgr.GetInstance().GetUserAttribute('wantsmail') != 'N';
			_tiOldPassword.setFocus();
		}
		
		override public function SaveSettings(): void {
			if (dataModel.validateAll()) {
				ValidateEmailUnique();
			} else {
				_effError.end();
				_effError.play();
			}
		}
		
		private function ValidateEmailUnique(): void {
			if (email.length == 0 || email == oldEmail) {
				DoSaveSettings();
			} else {
				var nState:Number = UserEmailDictionary.global.LookupState(email, false);
				if (nState == PicnikDict.knDoesNotExist) {
					DoCheckPassword();
				} else {
					// Lookup the email
					PicnikService.UserExists({email:email}, OnLookupEmailStateInDB);
				}
			}
		}
		
		private function OnLookupEmailStateInDB(err:Number, strError:String, obData:Object=null): void {
			if (err == 0) {
				if (("exists" in obData) && ("email" in obData)) {
					var fExists:Boolean = obData["exists"].toString().toLowerCase() == "true";
					UserEmailDictionary.global.SetExists(obData["email"], fExists);
					if (fExists) {
						dataModel.validateAll();
					} else {
						// Looks good.
						DoCheckPassword();
					}
				}
			} else {
				Util.ShowAlert(Resource.getString('SettingsComponent', 'unknown_error'), Resource.getString('SettingsComponent', 'error'), Alert.OK,
					"SettingsComponentBase.OnLookupEmailStateInDB error: " + err + ", " + strError);
			}
		}
		
		// The old password is correct, now save the settings
		override protected function DoSaveSettings(): void {
			AccountMgr.GetInstance().SetUserAttribute("wantsmail", wantsmail?"Y":"N", false);
			if (email.length > 0) AccountMgr.GetInstance().SetUserAttribute("email", email, false);
			AccountMgr.GetInstance().FlushUserAttributes();
			PicnikBase.app.Notify(_strSuccessFeedbackMessage);
			Hide();
		}	
		
		
		private function get oldEmail(): String {
			return AccountMgr.GetInstance().GetUserAttribute("email");
		}
		
		private function get oldWantsmail(): Boolean {
			return AccountMgr.GetInstance().GetUserAttribute("wantsmail") != "N";
		}
		
		private function get email(): String {
			return GetFieldValue("email") as String;
		}
		
		private function get wantsmail(): Boolean {
			return GetFieldValue("wantsmail") as Boolean;
		}				
	}
}
