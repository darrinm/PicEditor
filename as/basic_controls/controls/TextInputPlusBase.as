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
package controls {
	import com.adobe.utils.StringUtil;
	
	import flash.display.StageDisplayState;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	
	import mx.controls.TextInput;
	import mx.events.FlexEvent;
	
	import util.smartresize.ISmartResizeComponent;

	public class TextInputPlusBase extends TextInput implements ISmartResizeComponent {
		private var _fPrompting:Boolean = false;
		private var _strPrompt:String = null;

		public function TextInputPlusBase() {
			_srh = new SmartResizeHelper(this) // smart resize code
			super();
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			
			// Prompt stuff
			addEventListener(TextEvent.TEXT_INPUT, OnTextInput);
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
			addEventListener(FocusEvent.FOCUS_OUT, OnFocusOut);
		}

	    include "../util/smartresize/ResizeHelperInc.as";
	    include "../util/smartresize/ResizeHelperFontSizeInc.as";
		
		// Define some new styles which map conditionally to existing styles
		// These include:
		//   enabledBorderColor [aka borderColor], disabledBorderColor -> borderColor
		//   enabledBackgroundAlpha [aka backgroundAlpha], disabledBackgroundAlpha -> backgroundAlpha
	    public override function setStyle(styleProp:String, newValue:*):void {
	    	if (styleProp == "backgroundAlpha") styleProp = "enabledBackgroundAlpha";
	    	if (styleProp == "borderColor") styleProp == "enabledBorderColor";
			super.setStyle(styleProp, newValue);
	    	if (StringUtil.endsWith(styleProp, "BackgroundAlpha") || StringUtil.endsWith(styleProp, "BorderColor")) {
	    		updateConditionalStyles();
	    	}
		}
		
		public override function set enabled(value:Boolean):void {
			super.enabled = value;
			updateConditionalStyles();
		}
		
		protected function updateConditionalStyles(): void {
			var strPrefix:String = enabled ? "enabled" : "disabled";
			super.setStyle("backgroundAlpha", getStyle(strPrefix + "BackgroundAlpha"));
			super.setStyle("borderColor", getStyle(strPrefix + "BorderColor"));
		}

	    public override function getStyle(styleProp:String):* {
			return super.getStyle(styleProp);
		}

		// Exit full screen mode when the TextInput control is clicked		
		private function OnMouseDown(evt:MouseEvent): void {
			// Clear out the prompt string when the TextArea is clicked
			if (_fPrompting)
				ClearPrompt();
				
			if (stage.displayState == StageDisplayState.FULL_SCREEN)
				stage.displayState = StageDisplayState.NORMAL;
		}
		
		//
		// Prompt stuff
		//
		
		public override function setFocus(): void {
			super.setFocus();
			if (_strPrompt && text == "")
				selectionBeginIndex = selectionEndIndex = 0;
		}
		
		[Bindable]
		public function set prompt(strPrompt:String): void {
			_strPrompt = strPrompt;
		}
		
		public function get prompt(): String {
			return _strPrompt;
		}
		
		// Initialize the text with the prompt string		
		private function OnCreationComplete(evt:FlexEvent): void {
			if (_strPrompt)
				ShowPrompt();
		}
		
		private function OnTextInput(evt:TextEvent): void {
			// If the field has no text, isn't focused and we have a prompt, show it
			if (_strPrompt) {
				if (getFocus() != textField && text == "")
					ShowPrompt();
				else
					ClearPrompt();
			}
		}
		
		private function OnFocusOut(evt:FocusEvent): void {
			if (_strPrompt && text == "")
				ShowPrompt();
		}

		private function ShowPrompt(): void {
			validateProperties();
			_fPrompting = true;
			textField.text = _strPrompt;
			textField.textColor = uint(getStyle("disabledColor"));
		}
		
		private function ClearPrompt(): void {
			_fPrompting = false;
			textField.text = text;
			textField.textColor = uint(getStyle("color"));
		}
		
		//
		//
		//
		
		private var _fDrawFocusIndicator:Boolean = true;
		
		public function set drawFocusIndicator(fDraw:Boolean): void {
			_fDrawFocusIndicator = fDraw;
		}
		
		public function get drawFocusIndicator(): Boolean {
			return _fDrawFocusIndicator;
		}
		
		override public function drawFocus(isFocused:Boolean): void {
			super.drawFocus(isFocused && _fDrawFocusIndicator);
		}
	}
}
