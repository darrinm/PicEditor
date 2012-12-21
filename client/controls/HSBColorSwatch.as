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
	
	public class HSBColorSwatch extends ColorSwatchBase
	{
		private var _cxGrayscaleSize:Number = 10;
		private var _nTopGray:Number = 255;
		private var _nBottomGray:Number = -1;
		private var _nHueStart:Number = 0;
		
		private var _fSaturationOnlyMode:Boolean = false;

		private static const knFadeLimit:Number = 0.99;
		
		public function HSBColorSwatch() {
		}
		
		public function set thumbColor(clr:Number): void {
			updateThumb(clr,null);
		}
		
		public function set saturationOnlyMode(f:Boolean): void {
			_fSaturationOnlyMode = f;
			invalidateProperties();
		}
		
		[Bindable]
		public function set topGray(nVal:Number): void {
			_nTopGray = Math.round(nVal);
			if (_nTopGray > 255) _nTopGray = 255;
			if (_nTopGray < -1) _nTopGray = -1;
			invalidateProperties();
		}
		public function get topGray(): Number {
			return _nTopGray;
		}
		public function ClearTopGray(): void {
			topGray = -1;
		}
		private function get hasTopGray(): Boolean {
			return _nTopGray >= 0;
		}
		
		public function set hueStart(n:Number): void {
			_nHueStart = n;
			invalidateProperties();
		}
		
		[Bindable]
		public function set bottomGray(nVal:Number): void {
			_nBottomGray = Math.round(nVal);
			if (_nBottomGray > 255) _nBottomGray = 255;
			if (_nBottomGray < -1) _nBottomGray = -1;
			invalidateProperties();
		}
		public function get bottomGray(): Number {
			return _nBottomGray;
		}
		public function ClearBottomGray(): void {
			bottomGray = -1;
		}
		private function get hasBottomGray(): Boolean {
			return _nBottomGray >= 0;
		}
		
		[Bindable]
		public function set grayscaleSize(nVal:Number): void {
			_cxGrayscaleSize = Math.round(nVal);
			invalidateProperties();
		}
		public function get grayscaleSize(): Number {
			return _cxGrayscaleSize;
		}
		private function get hasGrayscale(): Boolean {
			return _cxGrayscaleSize > 0;
		}
		

		protected override function ColorFromPoint(x:Number, y:Number): Number {
			// Do some fun math
			var cxGray:Number = _cxGrayscaleSize;
			if (cxGray < 0) cxGray = 0;
			
			var cy:Number = height;
			var clr:Number;
			
			if (x <= cxGray) {
				var nGray:Number = _fSaturationOnlyMode ? _nTopGray : (255 * (cy - y) / cy);
				if (nGray < 0) nGray = 0;
				else if (nGray > 255) nGray = 255;
				clr = RGBColor.RGBtoUint(nGray, nGray, nGray);
			} else {
				// Hue goes from 0 to 360
				var nHue:Number = _nHueStart + 360 * (x - cxGray) / (width - cxGray);
				var fy:Number = 0; // Shift up (-) or down (+) or no shift (0)
				var nGrayFade:Number = 0; // Shift toward this color
				if (hasTopGray && hasBottomGray) {
					fy = (y * 2 / cy) - 1;
				
					if (fy <= 0) {
						// Fade toward white, -fy%
						nGrayFade = _nTopGray;
						fy = -fy;
					} else {
						// Fade toward black, fy%
						nGrayFade = _nBottomGray;
						fy = fy;
					}
				} else if (hasTopGray) {
					// fade amount is 0 when y is large and 1 when y is 0
					fy = 1 - (y / cy);
					nGrayFade = _nTopGray;
				} else if (hasBottomGray) {
					fy = y / cy;
					nGrayFade = _nBottomGray;
				}
				// Finally, don't let fy get all the way to 1 so reverse matches are possible.
				var nSat:Number = 100 * (1 - fy);
				nSat = 100;
				var nVal:Number = 100 * (1 - fy) + 100 * fy * nGrayFade/255;
				if (nGrayFade == 0 && !_fSaturationOnlyMode) {
					nSat = 100; // Don't fade saturation while going to black.
				} else {
					// For any other gray/white color,
					// target saturation is 0, target value is nGrayFade/255;
					nSat = 100 * (1 - fy);
				}
				
				if (_fSaturationOnlyMode)
					nVal = _nTopGray * 100 / 255;
				
				nSat = 100 - ((100 - nSat) * knFadeLimit);
				nVal = 100 - ((100 - nVal) * knFadeLimit);
				
				clr = RGBColor.HSVtoUint(nHue, nSat, nVal);
			}
			
			return clr;
		}

		protected override function PointFromColor(clr:Number): Point {
			// Do some fun math
			var cxGray:Number = _cxGrayscaleSize;
			if (cxGray < 0) cxGray = 0;
			
			var obHSV:Object = RGBColor.Uint2HSV(clr);
			var nHue:Number = obHSV.h;
			var nSat:Number = obHSV.s;
			var nVal:Number = obHSV.v;
			var cy:Number = height;
			var x:Number;
			var y:Number;

			if (nSat == 0) {
				// Grayscale. Use value for height and center it horizontally
				x = cxGray / 2;
				y = (1-nVal/100) * cy;
			} else {
				nSat = 100 - ((100 - nSat) / knFadeLimit);
				nVal = 100 - ((100 - nVal) / knFadeLimit);
				// There is some color. Use the hue to find the x val
				nHue -= _nHueStart;
				if (nHue < 0) nHue += 360;
				x = cxGray + (width - cxGray) * nHue / 360;
				if (hasTopGray && hasBottomGray) {
					// Top and bottom.
					// Figure out which one we are headed towards
					y = height/2; // Start in the middle
					var cyHalf:Number = y;
					if (nSat >= 100 && nVal >= 100) {
						// No fade
					} else if (nSat >= 100) {
						// Val is fading without sat. We must be going towards black (if present)
						if (bottomGray == 0) {
							// Going down.
							y += cyHalf * (100-nVal)/100;
						} else {
							// Going up
							y -= cyHalf * (100-nVal)/100;
						}
					} else {
						// Sat and val are fading
						var nDirection:Number = 1;
						if (bottomGray == 0) {
							nDirection = -1;
						} else if (topGray == 0) {
							nDirection = 1;
						} else {
							// Neither are black, so both have saturation falling to 0
							// Figure out the target val based on sat
							var nTargetGray:Number = (100 - (100/(100-nSat)) * (100-nVal)) * 255/100;
							// Funky math
							// Figure out which gray is closer
							if (Math.abs(topGray-nTargetGray) < Math.abs(bottomGray-nTargetGray)) {
								nDirection = -1; // Going up
							} else {
								nDirection = 1; // Going down
							}
						}
						y += nDirection * cyHalf * (100-nSat)/100;
					}
				} else if (hasTopGray) {
					if (topGray == 0) {
						// Val fades from 100 to 0 going up
						y = nVal * height / 100;
					} else {
						// Sat fades from 100 to 0 going up
						y = nSat * height / 100;
					}
				} else if (hasBottomGray) {
					if (bottomGray == 0) {
						// Val fades from 100 to 0 going down
						y = (100-nVal) * height / 100;
					} else {
						// Sat fades from 100 to 0 going down
						y = (100-nSat) * height / 100;
					}
				} else {
					// no top-bottom changes
					y = height/2; // Center the thumb.
				}
			}
			
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