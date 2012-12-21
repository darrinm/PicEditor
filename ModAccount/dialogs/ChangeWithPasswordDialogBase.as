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
	
	public class ChangeWithPasswordDialogBase extends CloudyResizingDialog
	{
		[Bindable] public var _strSuccessFeedbackMessage:String;
		[Bindable] public var _effError:Sequence;
		[Bindable] public var _tiOldPassword:NoTipTextInput;
		[Bindable] public var _strOldPasswordIncorrectError:String;
		[Bindable] public var _btnDone:Button;

		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			super.Constructor(fnComplete, uicParent, obParams);
		}
		
		override protected function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.ESCAPE) {
				Hide();
			} else if (evt.keyCode == Keyboard.ENTER) {
				SaveSettings();
			}
		}		
		
		public function SaveSettings(): void {
		}
		
		override protected function OnShow(): void {
			super.OnShow();
			if (_btnDone) {
				_btnDone.setFocus();
			}
		}

		protected function DoCheckPassword(): void {
			// Lookup the old password in the db
			var strMD5Pass:String = MD5.hash(oldPassword);
			PicnikService.PasswordCorrect(strMD5Pass, OnPasswordCorrect);
		}
		
		private function OnPasswordCorrect(err:Number, strError:String, obData:Object=null): void {
			if (err == 0) {
				var fCorrect:Boolean = obData["correct"] as Boolean;
				if (fCorrect == true || !AccountMgr.GetInstance().hasCredentials) {
					DoSaveSettings();
				} else {
					// Old password is incorrect. Force an error
					_tiOldPassword.errorString = _strOldPasswordIncorrectError;
				}
			} else {
				// There was some sort of error
				Util.ShowAlert(Resource.getString('SettingsComponent', 'unknown_error'), Resource.getString('SettingsComponent', 'error'), Alert.OK,
					"SettingsComponentBase error, password: " + err + ", " + strError);
			}
		}
		
		// The old password is correct, now save the settings
		protected function DoSaveSettings(): void {
		}	
		
		protected function get dataModel(): DataModel {
			if ("_dtmFormFields" in this) return this["_dtmFormFields"] as DataModel;
			else return null; // Not found. Error.
		}
		
		protected function GetFieldValue(strFieldName:String): Object {
			return dataModel.GetValue(strFieldName);
		}
		
		protected function get oldPassword(): String {
			return GetFieldValue("oldpassword") as String;
		}
	}
}
