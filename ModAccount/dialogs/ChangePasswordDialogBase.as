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
	
	import containers.ResizingDialog;
	
	import controls.NoTipTextInput;
	
	import dialogs.RegisterHelper.DataModel;
	
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.RadioButton;
	import mx.core.UIComponent;
	import mx.effects.Sequence;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.managers.PopUpManager;
	
	import util.PicnikAlert;
	
	import validators.CurrentPasswordValidator;
	
	public class ChangePasswordDialogBase extends ChangeWithPasswordDialogBase
	{
		[Bindable] public var _tiPassword:NoTipTextInput;
		[Bindable] public var _tiPasswordAgain:NoTipTextInput;

		override protected function OnShow():void {
			_tiOldPassword.setFocus();
		}
		
		override public function SaveSettings(): void {
			if (dataModel.validateAll()) {
				DoCheckPassword();
			} else {
				_effError.end();
				_effError.play();
			}
		}
		
		// The old password is correct, now save the settings
		override protected function DoSaveSettings(): void {
			if (password.length > 0) AccountMgr.GetInstance().SetUserAttribute("password", md5password, true);
			PicnikBase.app.Notify(_strSuccessFeedbackMessage);
			Hide();
		}	
		
		private function get password(): String {
			return GetFieldValue("password") as String;
		}
		
		private function get md5password(): String {
			return MD5.hash(password);
		}
				
	}
}
