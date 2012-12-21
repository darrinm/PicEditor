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
	import mx.controls.ToolTip;
	import mx.core.EdgeMetrics;
	import flash.text.TextFormat;
	import flash.events.TextEvent;
	import skins.ToolTipBorderPlus;
	import mx.skins.RectangularBorder;

	public class ErrorTip extends ToolTipPlus {
		public var showHtml:Boolean = true;
		
		public function ErrorTip() {
			super();
            setStyle("styleName", "errorTip");
            var cl:Class;
            cl = ToolTipBorderPlus;
           
            setStyle("borderSkin", cl);
            setStyle("borderStyle", "errorTipRight");
		}
		
		private var _fTextChanged:Boolean = false;
	
		// NOTE: not strictly needed but Flex gives a runtime warning about duplicate
		// TypeDescriptors if it isn't here.
		public override function get text(): String {
			return super.text;
		}
		
		public override function set text(value:String):void {
			super.text = value;
			_fTextChanged = true;
		}	
		
		//
		// We override measure because the default version from ToolTip
		// uses ToolTip.maxWidth as its size, which is just plain wrong.
		//	
		override protected function measure():void
		{
			var nOldMaxWidth:Number = ToolTip.maxWidth;
			if (!isNaN(maxWidth)) {
				ToolTip.maxWidth = maxWidth;
			}
			super.measure();
			ToolTip.maxWidth = nOldMaxWidth;
		}				
				
		override protected function commitProperties():void {
			super.commitProperties();
			if (showHtml && _fTextChanged) {
				_fTextChanged = false;
				textField.text = "";
				textField.htmlText = text;
				// Make sure links work
				textField.mouseEnabled = true;
				textField.selectable = true;
				// Remove leading and trailing whitespace in CData tags
				textField.condenseWhite = true;
			}
		}
	}
}
