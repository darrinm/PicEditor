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
	
	import flash.display.BitmapDataChannel;
	
	import overlays.helpers.RGBColor;

	// This is a nested image operation that first desaturates, then applies a color tint.
	// Set _bAutoLevels to true and the tint will expand to fill the range.
	// Tint works like a Color overlay in photoshop - it tries to maintain the
	// same distance between R,G,and B components, while maintaining luminosity.
	// At the upper and lower ends, clipping will occur.

	[RemoteClass]
	public class TintImageOperation extends NestedImageOperation
	{
		protected var _opDesaturate:ColorMatrixImageOperation;
		protected var _opResaturate:PaletteMapImageOperation;
		
		private var _clr:Number = 0xddc9ae; // Sepia
		
		public function set Color(clr:Number): void {
			if (_clr != clr) {
				_clr = clr;
				CalcArrays();
			}
		}

		// Luminance color weights
		private static const knLumR:Number = 0.3086;
		private static const knLumG:Number = 0.6094;
		private static const knLumB:Number = 0.0820;
		
		public function TintImageOperation()
		{
			// Create the child ops and add them to the array

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
		
		public static function CalcTintArrays(opResaturate:PaletteMapImageOperation, nClr:Number, nBaseBitmapDataChannel:Number): void {
			var anPrimary:Array = new Array(256);
			var anZeroes:Array = new Array(256);
			
			var nClrR:Number = RGBColor.RedFromUint(nClr);
			var nClrG:Number = RGBColor.GreenFromUint(nClr);
			var nClrB:Number = RGBColor.BlueFromUint(nClr);
			var nClrLum:Number = nClrR * knLumR + nClrG * knLumG + nClrB * knLumB;
			
			for (var i:Number = 0; i < 256; i++) {
				// Since this is a grayscale image, use red to specify the color and set green and blue to 0
				anPrimary[i] = RGBColor.UintFromOb(RGBColor.AdjustLumRGB(nClrR, nClrG, nClrB, i));
				anZeroes[i] = 0;
			}
			
			// Zero everything
			opResaturate.Reds = anZeroes;
			opResaturate.Greens = anZeroes;
			opResaturate.Blues = anZeroes;
			
			// Now set the primary channel
			if (nBaseBitmapDataChannel == BitmapDataChannel.BLUE)
				opResaturate.Blues = anPrimary;
			else if (nBaseBitmapDataChannel == BitmapDataChannel.GREEN)
				opResaturate.Greens = anPrimary;
			else
				opResaturate.Reds = anPrimary;
		}

		// returns an object with palette arrays (array of number) for .red, .green, and .blue		
		protected function CalcArrays(): void {
			CalcTintArrays(_opResaturate, _clr, BitmapDataChannel.RED);
		}
	}
}