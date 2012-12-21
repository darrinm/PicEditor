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
// TextAreaPlus is exactly the same as Flex's mx.controls.TextArea except that
// will auto-size itself vertically to fit its contents, even as text is being
// typed into it. As TextAreaPlus resizes it honors the minHeight, maxHeight
// properties.

package controls {
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	
	import mx.controls.TextArea;
	import mx.controls.textClasses.TextRange;
	import mx.core.UITextField;
	import mx.events.FlexEvent;

	public class TextAreaPlusBase extends TextArea {
		private var _fAutoSize:Boolean = true;
		private var _fPrompting:Boolean = false;
		private var _strPrompt:String = null;
		
		public function TextAreaPlusBase() {
			super();
			addEventListener("textChanged", OnTextChange);
			addEventListener(Event.CHANGE, OnTextChange);
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
			addEventListener(FocusEvent.FOCUS_OUT, OnFocusOut);
		}
		
		[Bindable]
		public function get autoSize(): Boolean {
			return _fAutoSize;
		}
		
		public function set autoSize(fAutoSize:Boolean): void {
			_fAutoSize = fAutoSize;
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
		
		private function OnTextChange(evt:Event): void {
			if (!textField) return;
			// If the field has no text, isn't focused and we have a prompt, show it
			if (_strPrompt) {
				if (getFocus() != textField && text == "")
					ShowPrompt();
				else
					ClearPrompt();
			}
				
			if (!_fAutoSize)
				return;
			
			validateNow();
			
			// We use the textField.textHeight rather than this.textHeight because this.textHeight is
			// updated immediately AFTER this event is fired (too late for us) but fortunately
			// textfield.textHeight is updated BEFORE.
			if (textField) {
				var cy:Number = textField.textHeight + borderMetrics.top + borderMetrics.bottom + 6; // UNDONE: fudge!
				if (cy < minHeight)
					cy = minHeight;
				if (cy > maxHeight)
					cy = maxHeight;
				height = int(cy);
			}
		}
		
		private function OnFocusOut(evt:FocusEvent): void {
			if (_strPrompt && text == "")
				ShowPrompt();
		}

		private function OnMouseDown(evt:MouseEvent): void {
			// Clear out the prompt string when the TextArea is clicked
			ClearPrompt();
				
			// Exit full screen mode when the TextInput control is clicked		
			if (stage.displayState == StageDisplayState.FULL_SCREEN)
				stage.displayState = StageDisplayState.NORMAL;
		}
		
		private function ShowPrompt(): void {
			if (_fPrompting)
				return;
				
			validateProperties();
			_fPrompting = true;
			textField.text = _strPrompt;
			textField.textColor = uint(getStyle("disabledColor"));
		}
		
		private function ClearPrompt(): void {
			if (!_fPrompting)
				return;
				
			_fPrompting = false;
			textField.text = text;
			textField.textColor = uint(getStyle("color"));
		}
		
		/*
		// Make links active without having the text selectable
		//
		// Adapted from the Flex Cookbook posting:
		// http://www.adobe.com/cfusion/communityengine/index.cfm?event=showDetails&postId=8445&productId=2&loc=en_US
		
		// Override the electable property so we can turn our custom onclick handler
		// on if selectable is set to true. If it's set to false, we remove the
		// listener so the text area can handle things as usual.
		override public function set selectable(fSelectable:Boolean): void {
			super.selectable = fSelectable;
			if (textField) {
				textField.selectable = fSelectable;
			} else {
				// If we're attempting to set selectable before the component
				// has completed its instantiation, we need to postpone
				// passing the command on to the textField (which won't have
				// been created yet) until instantiation has completed.
				callLater(function (): void {
					textField.selectable = fSelectable;
				});
			}
			
			if (fSelectable) {
				UITextField(textField).setSelection(-1, -1);
				removeEventListener(MouseEvent.CLICK, OnClick);
			} else {
				addEventListener(MouseEvent.CLICK, OnClick);
			}
		}
		
		private function OnClick(evt:MouseEvent): void {
			// Find the letter under our click
			var index:int = textField.getCharIndexAtPoint(evt.localX, evt.localY);
			if (index != -1) {
				// convert the letter to a text range so we can extract the url
				var range:TextRange = new TextRange(this, false, index, index + 1);
				
				// make sure it contains a url
				if (range.url.length > 0) {
					// The normal click event strips out the 'event;' portion of the url.
					// So to be consistent, let's strip it out, too.
					var url:String = range.url;
					if (url.substr(0, 6) == 'event:') {
						url = url.substring(6);
					}
					
					// Manually dispatch the link event with the url neatly included
					dispatchEvent(new TextEvent(TextEvent.LINK, false, false, url));
				}
			}
		}
		*/
	}
}
