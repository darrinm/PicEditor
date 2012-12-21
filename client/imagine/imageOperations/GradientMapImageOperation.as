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
	import imagine.imageOperations.PaletteMapImageOperation;
	import overlays.helpers.RGBColor;
	import flash.display.BitmapDataChannel;
	import flash.display.Bitmap;

	// This is a palette map image operation that applies a multiple color
	// gradient based on a single channel. Works best if the image is first converted to B/W
	[RemoteClass]
	public class GradientMapImageOperation extends PaletteMapImageOperation
	{
		private var _chnl:uint = BitmapDataChannel.RED; // Default channel
		
		// Gradient object array.
		// Each object has .position (0-255) and .color
		// Does nothing if it has fewer than 2 elements.
		// If first position is > 0, elements from first position up to 0 will be the first color. Same applies to last position.
		// Array will be sorted by position.
		private var _aobGradient:Array = [];

		// Wrapper for set gradient object array which takes an array of colors
		// and assigns evenly distributed positions.
		public function set gradientArray(aclr:Array): void {
			var aobNew:Array = [];
			if (aclr.length >= 2) {
				aobNew.push({position:0, color:aclr[0]}); // Head
				// Add the middle positions
				for (var i:Number = 1; i < (aclr.length-1); i++) {
					var nPos:Number = i*255/(aclr.length-1);
					aobNew.push({position:nPos, color:aclr[i]});
				}
				aobNew.push({position:255, color:aclr[aclr.length-1]}); // Tail
			}
			gradientObjectArray = aobNew;
		}
		
		public function set gradientObjectArray(aobGradient:Array): void {
			// First, clean up our gradient array
			var aobNew:Array = []; // Start with nothing.
			
			var fValid:Boolean = aobGradient.length >= 2;
			var ob:Object;
			
			if (aobGradient.length < 2) {
				trace("gradientObjectArray() too small. Must be at least two elements.");
			}
			
			if (fValid) {
				for each (ob in aobGradient) {
					if (!("color" in ob)) {
						trace("gradientObjectAray() input array object missing color");
						fValid = false;
					}
					if (!("position" in ob)) {
						trace("gradientObjectAray() input array object missing position");
						fValid = false;
					}
				}
				if (fValid) {
					aobNew = aobGradient.slice();
				}
			}
			if (!GradientArraysEqual(_aobGradient, aobNew)) {
				_aobGradient = aobNew;
				CalcArrays();
			}
		}
		
		// Returns true if the two gradient arrays are equal.
		protected function GradientArraysEqual(aob1:Array, aob2:Array): Boolean {
			if (aob1 === aob2) return true;
			if (aob1.length != aob2.length) return false;
			// Look for differences.
			for (var i:Number = 0; i < aob1.length; i++) {
				var ob1:Object = aob1[i];
				var ob2:Object = aob2[i];
				if (!(ob1 === ob2)) {
					if ("position" in ob1) {
						if ("position" in ob2) {
							if (ob1.position != ob2.position) return false;
						} else {
							return false;
						}
					} else if ("position" in ob2) return false;
					
					if ("color" in ob1) {
						if ("color" in ob2) {
							if (ob1.color != ob2.color) return false;
						} else {
							return false;
						}
					} else if ("color" in ob2) return false;
				}
			}
			return true; // Equal
		}

		public function GradientMapImageOperation()
		{
			CalcArrays();
		}
		
		// Take a blend of color 1 and color 2. use clr1pct % of color 1 plus remaining % of color 2
		protected function BlendColors(clr1:Number, clr2:Number, clr1pct:Number): Number {
			if (clr1pct >= 1) return clr1;
			if (clr1pct <= 0) return clr2;
			
			var nR1:Number = RGBColor.RedFromUint(clr1);
			var nG1:Number = RGBColor.GreenFromUint(clr1);
			var nB1:Number = RGBColor.BlueFromUint(clr1);
			var nR2:Number = RGBColor.RedFromUint(clr2);
			var nG2:Number = RGBColor.GreenFromUint(clr2);
			var nB2:Number = RGBColor.BlueFromUint(clr2);
			
			var nR:Number = Math.min(Math.max(Math.round(nR1 * clr1pct + nR2 * (1-clr1pct)), 0), 255);
			var nG:Number = Math.min(Math.max(Math.round(nG1 * clr1pct + nG2 * (1-clr1pct)), 0), 255);
			var nB:Number = Math.min(Math.max(Math.round(nB1 * clr1pct + nB2 * (1-clr1pct)), 0), 255);
			return RGBColor.RGBtoUint(nR, nG, nB);
		}

		protected function GetSurroundingColors(i:Number): Object {
			var obFirstColor:Object = null; // Should be set to last color before i, null if none exists.
			var obSecondColor:Object = null; // Should be set to first color after i, null if none exists

			// Firnd first and last color.
			for each (var ob:Object in _aobGradient) {
				if (ob.position <= i) obFirstColor = ob;
				if (ob.position > i) {
					obSecondColor = ob;
					break;
				}
			}			
			
			return {firstColor:obFirstColor, secondColor:obSecondColor};
		}
		
		protected function CalcColor(i:Number): Number {
			// First, get surrounding colors and their positions
			var obSurroundingColors:Object = GetSurroundingColors(i);
			var obFirstColor:Object = obSurroundingColors.firstColor;
			var obSecondColor:Object = obSurroundingColors.secondColor;
			if (obFirstColor == null) return obSecondColor.color;
			if (obSecondColor == null) return obFirstColor.color;
			// Now we know we have both a first and a second color.
			if (obFirstColor.position == i) return obFirstColor.color;
			if (obSecondColor.position == i) return obSecondColor.color;
			// Now we know that i is between the first and second colors
			Debug.Assert(obFirstColor.position < i);
			Debug.Assert(obSecondColor.position > i);
			
			var nFirstPct:Number = (obSecondColor.position - i) / (obSecondColor.position - obFirstColor.position);
			return BlendColors(obFirstColor.color, obSecondColor.color, nFirstPct);
		}

		// returns an object with palette arrays (array of number) for .red, .green, and .blue		
		protected function CalcArrays(): void {
			var anReds:Array = new Array(256);
			var anGreens:Array = new Array(256);
			var anBlues:Array = new Array(256);
			var i:Number;
			
			if (_aobGradient.length < 2) {
				for (i = 0; i < 256; i++) {
					// Not enough colors. Map back to same colors
					anReds[i] = i;
					anGreens[i] = i;
					anBlues[i] = i;
				}
			} else {
				for (i = 0; i < 256; i++) {
					var clr:Number = CalcColor(i);
					anReds[i] = (_chnl == BitmapDataChannel.RED) ? clr : 0;
					anGreens[i] = (_chnl == BitmapDataChannel.GREEN) ? clr : 0;
					anBlues[i] = (_chnl == BitmapDataChannel.BLUE) ? clr : 0;
				}
			}
			Reds = anReds;
			Greens = anGreens;
			Blues = anBlues;
		}
	}
}