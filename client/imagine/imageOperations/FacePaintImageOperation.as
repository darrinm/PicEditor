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
	import com.gskinner.geom.ColorMatrix;
	
	import imagine.imageOperations.NestedImageOperation;
	import imagine.imageOperations.ColorMatrixImageOperation;
	import imagine.imageOperations.PaletteMapImageOperation;
	
	import overlays.helpers.RGBColor;
	
	import util.SplineInterpolator;

	// This is a nested image operation that first desaturates, then applies a color tint and a curve
	// using a single color matrix. The input for this effect is a paint color.
	// It figures out which curve to use to reproduce that color.

	[RemoteClass]
	public class FacePaintImageOperation extends NestedImageOperation
	{
		protected var _opDesaturate:ColorMatrixImageOperation;
		protected var _opResaturate:PaletteMapImageOperation;
		
		private var _nLinearPercent:Number = 0.8;
		private var _nDarkenPercent:Number = 0.8;
		private var _nAverageFaceLuminosity:Number = 0.66 * 255;
		private var _clr:Number = 0;
		
		public function set Color(clr:Number): void {
			if (_clr != clr) {
				_clr = clr;
				CalcArrays();
			}
		}

		private static const kaobWhiteCurve:Array = [{x:0, y:147}, {x:96, y:175}, {x:255, y:255}];
		private static const kaobBlackCurve:Array = [{x:0, y:0}, {x:203, y:87}, {x:255, y:255}];
		
		[RemoteClass]
		public function FacePaintImageOperation()
		{
			// Create the child ops and add them to the array
			super._nAlpha = 0.9;
			var cmat:ColorMatrix = new ColorMatrix();
			cmat.adjustSaturation(-100); // -100 == completely desaturated
			_opDesaturate = new ColorMatrixImageOperation(cmat);
			_aopChildren.push(_opDesaturate);
			
			_opResaturate = new PaletteMapImageOperation();
			CalcArrays();
			_aopChildren.push(_opResaturate);
		}
		
		public function set dynamicColorCachePriority(n:Number): void {
			if (_opResaturate == null)
				return;
			_opResaturate.dynamicParamsCachePriority = n;
		}

		private function clamp(n:Number): Number {
			return Math.max(0, Math.min(255, Math.round(n)));
		}
		
		private function GetTintColor(nLum:Number, clrPaint:Number, si:SplineInterpolator, nPctLinear:Number): Number {
			var clr:Number;
			
			var nLumOut:Number = nLum;
			var nLumOutCurve:Number = nLum;
			var nLumOutLinear:Number;
			
			var nColorLum:Number = GetLuminosityOut();
			
			if (nLum < _nAverageFaceLuminosity) {
				// (0,0) => (_nAverageFaceLuminosity, nColorLum) => y = nColorLum / _nAverageFaceLuminosity * x
				nLumOutLinear = nLum * nColorLum / _nAverageFaceLuminosity;
			} else {
				// (_nAverageFaceLuminosity, nColorLum) => (255, 255)
				// y' = y - nColorLum
				// x' = x - _nAverageFaceLuminosity
				// (0, 0) => (255-_nAverageFaceLuminosity, 255-nColorLum) => y' = x' * (255-nColorLum) / (255-_nAverageFaceLuminosity)
				nLumOutLinear = nColorLum + (255 - nColorLum) * (nLum - _nAverageFaceLuminosity) / (255 - _nAverageFaceLuminosity)
			}
			if (si != null)
				nLumOutCurve = si.Interpolate(nLum);
				
			nLumOut = nLumOutCurve + nPctLinear * (nLumOutLinear - nLumOutCurve);
			
			var obRGB:Object = RGBColor.AdjustLumRGB(RGBColor.RedFromUint(clrPaint), RGBColor.GreenFromUint(clrPaint), RGBColor.BlueFromUint(clrPaint), nLumOut);
			obRGB.r = clamp(obRGB.r);
			obRGB.g = clamp(obRGB.g);
			obRGB.b = clamp(obRGB.b);
			
			return RGBColor.UintFromOb(obRGB);
		}
		
		protected function GetLuminosityOut(): Number {
			var nLumOut:Number = RGBColor.LuminosityFromUint(_clr);
			if (nLumOut > _nAverageFaceLuminosity)
				nLumOut = _nAverageFaceLuminosity + (nLumOut - _nAverageFaceLuminosity) / 2;
			else
				nLumOut = _nAverageFaceLuminosity + (nLumOut - _nAverageFaceLuminosity) * _nDarkenPercent;
				
			return nLumOut;
		}
		
		protected function CalcArrays(): void {
			var anReds:Array = new Array(256);
			var anZeroes:Array = new Array(256);
			
			var si:SplineInterpolator;
			var nLinearPct:Number = _nLinearPercent;
			if (_clr == 0xffffff) {
				nLinearPct = 0;
				si = new SplineInterpolator(kaobWhiteCurve);
			} else if (_clr == 0) {
				nLinearPct = 0;
				si = new SplineInterpolator(kaobBlackCurve);
			} else {
				si = new SplineInterpolator();
				si.add(0, 0);
				si.add(255, 255);
			}

			var nLumIn:Number = _nAverageFaceLuminosity;
			var nLumOut:Number = GetLuminosityOut();

			for (var i:Number = 0; i < 256; i++) {
				anReds[i] = GetTintColor(i, _clr, si, nLinearPct);
				anZeroes[i] = 0;
			}
				
			_opResaturate.Reds = anReds;

			// Zero everything else
			_opResaturate.Greens = anZeroes;
			_opResaturate.Blues = anZeroes;
		}
	}
}