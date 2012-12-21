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
	import controls.NoTipTextInput;
	import controls.ResizingErrorTip;
	
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import mx.controls.Button;
	import mx.controls.RadioButton;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	import util.AutoResizeMode;
	
	public class ChangePerformanceDialogBase extends CloudyResizingDialog
	{
		[Bindable] public var _strSuccessFeedbackMessage:String;
		[Bindable] public var _rbtnPrint:RadioButton;
		[Bindable] public var _rbtnArchival:RadioButton;
		[Bindable] public var _btnDone:Button;
		[Bindable] public var _strOriginalMode:String;
		
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			super.Constructor(fnComplete, uicParent, obParams);
			_strOriginalMode = AccountMgr.GetInstance().autoResizeMode;
		}
		
		public function ChangePerformanceDialogBase() {
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}
		
		private function OnCreationComplete( evt:FlexEvent ): void {
			_btnDone.addEventListener(MouseEvent.CLICK, OnDoneClick);
		}
		
		private function OnDoneClick(evt:MouseEvent):void {
			SaveSettings();
		}
				
		override protected function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.ESCAPE) {
				Hide();
			} else if (evt.keyCode == Keyboard.ENTER) {
				SaveSettings();
			}
		}		
		
		override protected function OnShow(): void {
			super.OnShow();
			if (_btnDone) {
				_btnDone.setFocus();
			}
		}
		
		public function SaveSettings(): void {
			AccountMgr.GetInstance().autoResizeMode = _rbtnPrint.selected ? AutoResizeMode.PRINT : AutoResizeMode.ARCHIVAL;
			AccountMgr.GetInstance().FlushUserAttributes();
			Hide();
			PicnikBase.app.Notify(_strSuccessFeedbackMessage);
		}				
	}
}
