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
	import flash.events.Event;
	
	import overlays.helpers.RGBColor;

	public class MultiColorEyeDropperButton extends EyeDropperButton
	{
		public function MultiColorEyeDropperButton()
		{
			super();
		}
		
		[Bindable] public var colors:Array = null;
		
		public var sampleRadius:Number = 10;
		public var lightPercent:Number = 80; // 0 to 100
		public var contrastBoost:Number = 40; // 1 to 100
		public var numColors:Number = 20;
		
		protected override function UpdateColor(xPos:Number, yPos:Number):void {
			xPos = Math.round(xPos);
			yPos = Math.round(yPos);
			
			var nShiftAmout:Number = 100 / (101 - contrastBoost);
			var nBottomPercent:Number = 1 - (lightPercent / 100);
			
			var aclr:Array = [];
			for (var ix:Number = Math.max(0, xPos - sampleRadius); ix < Math.min(_bmdSnapshot.width, xPos + sampleRadius); ix++) {
				for (var iy:Number = Math.max(0, yPos - sampleRadius); iy < Math.min(_bmdSnapshot.height, yPos + sampleRadius); iy++) {
					var clr:Number = _bmdSnapshot.getPixel(ix, iy);
					aclr.push({clr:clr, lum:RGBColor.LuminosityFromUint(clr)});
				}
			}

			aclr.sortOn('lum', Array.NUMERIC);
			
			var aclr2:Array = [];
			for (var i:Number = 0; i < numColors; i++) {
				var iColor:Number;
				if (i < numColors * nBottomPercent) {
					// Bottom color.
					iColor = Math.round((aclr.length / nShiftAmout) * i / numColors); 
				} else {
					// Top color.
					iColor = aclr.length - 1 - Math.round((aclr.length / nShiftAmout) * (numColors - i - 1) / numColors); 
				}
				aclr2.push(aclr[iColor].clr);
			}
			
			colors = aclr2;
			super.UpdateColor(xPos, yPos);
		}
	}
}