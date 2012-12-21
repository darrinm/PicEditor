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
package imagine.imageOperations
{
	import flash.geom.Point;
	
	import imagine.imageOperations.PaletteMapImageOperation;
	
	import util.SplineInterpolator;
	
	[RemoteClass]
	public class ExposureImageOperation extends PaletteMapImageOperation
	{
		public function ExposureImageOperation(): void { 	
			CalcArrays();
		}
		
		private var _nExposure:Number = 0;
		private var _nContrast:Number = 0;
		private var _nFill:Number = 0;
		private var _nBlacks:Number = 0;
	
		private static const _siExposure:SplineInterpolator = new SplineInterpolator([{x:14, y:0}, {x:27, y:19}, {x:41, y:36}, {x:81, y:70}, {x:128, y:94}, {x:193, y:123}, {x:220, y:136}, {x:255, y:160}]);
		private var _siContrast:SplineInterpolator = new SplineInterpolator();
		private var _siFill:SplineInterpolator = new SplineInterpolator();
		private var _siBlacks:SplineInterpolator = new SplineInterpolator();
	
		public function set exposure(n:Number): void {
			if (_nExposure != n) {
				_nExposure = n;
				CalcArrays();
			}
		}
		
		public function set contrast(n:Number): void {
			if (_nContrast != n) {
				_nContrast = n;
				_siContrast = new SplineInterpolator();
				_siContrast.add(0,0);
				_siContrast.add(64, 64 - 23 * n);
				_siContrast.add(128, 128);
				_siContrast.add(192, 192 + 27 * n);
				_siContrast.add(255,255);
				CalcArrays();
			}
		}
		
		public static function GetFillSpline(n:Number): SplineInterpolator {
			var siFill:SplineInterpolator = new SplineInterpolator();
			siFill.add(0,0);
			siFill.add(6, 6 + 42 * n);
			siFill.add(36, 36 + 112 * n);
			siFill.add(126, 126 + 72 * n);
			siFill.add(255,255);
			return siFill;
		}
		
		public function set fill(n:Number): void {
			if (_nFill != n) {
				_siFill = GetFillSpline(n);
				CalcArrays();
			}
		}
		
		public static function GetBlacksSpline(n:Number): SplineInterpolator {
			var siBlacks:SplineInterpolator = new SplineInterpolator();
			siBlacks.add(0,0);
			var x1:Number = n / 2;
			if ((68*n) >= 1)
				siBlacks.add(68 * n, 0);
			if (n <= 0.5) {
				siBlacks.add(127,127 - 9 * x1);
				siBlacks.add(188, 188 + 4 * x1);
			} else {
				var x2:Number = 2 * n - 1;
				siBlacks.add(127, 118 - 41 * x2);
				siBlacks.add(188, 192 - 12 * x2);
			}
			siBlacks.add(255,255);
			return siBlacks;
		}
		
		public function set blacks(n:Number): void {
			if (_nBlacks != n) {
				_nBlacks = n;
				_siBlacks = GetBlacksSpline(n);
				CalcArrays();
			}
		}
		
		private function CalcArrays(): void {
			var aR:Array = [];
			var aG:Array = [];
			var aB:Array = [];
			for (var x:Number = 0; x < 256; x++) {
				var y:Number;
				// Adjust exposure
				if (_nExposure != 0) {
					y = _siExposure.Invert(_siExposure.Interpolate(x) + 26 * _nExposure);
				} else {
					y = x;
				}
				y = _siFill.Interpolate(y);
				y = _siBlacks.Interpolate(y);
				y = _siContrast.Interpolate(y);
				y = Math.min(255,Math.max(0,Math.round(y)));
				aR[x] = y << 16;
				aG[x] = y << 8;
				aB[x] = y;
			}
			Reds = aR;
			Greens = aG;
			Blues = aB;
		}
	}
}