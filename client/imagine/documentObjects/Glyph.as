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
package imagine.documentObjects {
	import flash.geom.Rectangle;
	
	[RemoteClass]
	public class Glyph extends imagine.documentObjects.Text {
		[Bindable] public var gxOffset:Number = 0;
		[Bindable] public var gyOffset:Number = 0;
		[Bindable] public var gWidth:Number = 100;
		[Bindable] public var gHeight:Number = 100;

		public function Glyph() {
			super();
		}

		override public function get typeName(): String {
			return "Shape";
		}
		
		override public function get typeSubTab(): String {
			return "_ctShape";
		}
		
		override public function get objectPaletteName(): String {
			return "Shape";
		}
		
		override public function get serializableProperties(): Array {
			return super.serializableProperties.concat(["gxOffset", "gyOffset", "gWidth", "gHeight"]);
		}

		override public function set localRect(rc:Rectangle): void {
			super.localRect = rc; // Adjusts fontSize to handle scaleY
			// Manually handle scaleX
			var fNegative:Boolean = (scaleX < 0);
			scaleX = Math.abs(rc.width * textHeight / (textWidth * fontSize)) * (fNegative ? -1 : 1);
		}

		override public function get localRect(): Rectangle {
			if (ready) {
				var rcSuper:Rectangle = super.localRect;
				if (rcSuper && rcSuper.width != 0 && rcSuper.height != 0)
					return rcSuper;
			}
			// Return the default local rect
			return new Rectangle(x, y, gWidth * 100 / gHeight, 100);
		}
		
		override public function get textWidth():Number {
			return gWidth; //  * fontSize/100;
		}

		override public function get textHeight():Number {
			return gHeight; //  * fontSize/100;
		}
		
		override protected function get xOffset(): Number {
			return gxOffset - 1; // Fudge factor to cover text rendering oddities
		}

		override protected function get yOffset(): Number {
			return gyOffset + 0.5; // Fudge factor to cover text rendering oddities
		}
	}
}
