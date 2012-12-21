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
	import flash.geom.Point;
	
	import overlays.helpers.RGBColor;
	
	public class SprayTanColorSwatch extends ColorSwatchBase
	{
		private static const knHueMin:Number = 10; // Smallest hue, inclusive
		private static const knHueMax:Number = 45; // Largest hue, exclusive
		private static const knValMin:Number = 20;
		private static const knValMax:Number = 90;
		
		private var _nSat:Number = 72;
		
		private static const knFadeLimit:Number = 0.99;
		
		public function SprayTanColorSwatch() {
		}
		
		public function set saturation(n:Number): void {
			if (_nSat == n) return;
			var xThumb:Number = _spr.x + 6;
			var yThumb:Number = _spr.y + 6;
			_nSat = n;
			var clr:Number = ColorFromPoint(xThumb, yThumb);
			color = clr;
			updateThumb(clr, new Point(xThumb, yThumb));
			invalidateProperties();
		}
		
		public function get saturation(): Number {
			return _nSat;
		}

		protected override function ColorFromPoint(x:Number, y:Number): Number {
			// Do some fun math
			var cy:Number = height;
			var clr:Number;
			
			// Hue goes from hueMin to hueMax
			var nHue:Number = knHueMin + (knHueMax - knHueMin) * x / width;

			// Finally, don't let fy get all the way to 1 so reverse matches are possible.
			var nVal:Number = knValMax + y/height * (knValMin - knValMax);
			
			var nSat:Number = 100 - ((100 - _nSat) * knFadeLimit);
			nVal = 100 - ((100 - nVal) * knFadeLimit);
			
			clr = RGBColor.HSVtoUint(nHue, nSat, nVal);
			
			return clr;
		}

		protected override function PointFromColor(clr:Number): Point {
			// Do some fun math
			var obHSV:Object = RGBColor.Uint2HSV(clr);
			var nHue:Number = obHSV.h;
			var nSat:Number = obHSV.s;
			var nVal:Number = obHSV.v;
			var cy:Number = height;
			var x:Number;
			var y:Number;

			nSat = 100 - ((100 - nSat) / knFadeLimit);
			nVal = 100 - ((100 - nVal) / knFadeLimit);
			// There is some color. Use the hue to find the x val
			x = width * (nHue - knHueMin) / (knHueMax - knHueMin);
			
			y = height * (nVal - knValMax) / (knValMin - knValMax);

			x = Math.round(x);
			if (x < 0) x = 0;
			if (x >= width) x = width-1;
			
			y = Math.round(y);
			if (y < 0) y = 0;
			if (y >= height) y = height-1;
			return new Point(x,y);
		}
	}
}