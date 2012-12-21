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
package controls
{
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.StyleSheet;
	
	import mx.controls.Text;
	import mx.controls.textClasses.TextRange;
	
	import util.UnicodeHelper;

	/*******
	 * A text class which switches to a system font for unicode text
	 */
	public class TextPlus extends Text
	{
		private var _unh:UnicodeHelper = null;

		public function TextPlus() {
			super();
			_unh = new UnicodeHelper(this);
		}

		protected override function commitProperties():void {
			// Make sure we update the UnicodeHelper
			_unh.Update();
			
			// If the field isn't selectable we still want links to be clickable
			ListenForLinkClicks(); // Must do this BEFORE super.commitProperties
			
			super.commitProperties();
		}
		
        public function get styleSheet() : StyleSheet {
             return textField.styleSheet;
        }

        public function set styleSheet(value : StyleSheet) : void {
            textField.styleSheet = value;
        }

		// Make links active without having the text selectable
		//
		// Adapted from the Flex Cookbook posting:
		// http://www.adobe.com/cfusion/communityengine/index.cfm?event=showDetails&postId=8445&productId=2&loc=en_US
		
		private var _fListeningForClick:Boolean = false;
		
		private function ListenForLinkClicks(): void {
			var fSelectable:Boolean = selectable && selectable != textField.selectable;
			if (fSelectable) {
				if (_fListeningForClick) {
					removeEventListener(MouseEvent.CLICK, OnClick);
					_fListeningForClick = false;
				}
			} else {
				if (!_fListeningForClick) {
					addEventListener(MouseEvent.CLICK, OnClick);
					_fListeningForClick = true;
				}
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
					// The normal click event strips out the 'event:' portion of the url.
					// So to be consistent, let's strip it out, too.
					var url:String = range.url;
					if (url.substr(0, 6) == 'event:') {
						url = url.substring(6);
						// Manually dispatch the link event with the url neatly included
						dispatchEvent(new TextEvent(TextEvent.LINK, false, false, url));
					} else {
						// UNDONE: pop-up blockers grab this!
//						navigateToURL(new URLRequest(url));
					}
				}
			}
		}
	}
}
