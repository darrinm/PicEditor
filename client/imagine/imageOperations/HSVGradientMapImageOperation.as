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
	public class HSVGradientMapImageOperation extends PaletteMapImageOperation
	{
		private var _chnl:uint = BitmapDataChannel.RED; // Default channel
		
		// Gradient object array.
		// Each object has .position (0-255) and .color
		// Does nothing if it has fewer than 2 elements.
		// If first position is > 0, elements from first position up to 0 will be the first color. Same applies to last position.
		// Array will be sorted by position.
		private var _aobGradient:Array = [];
		private var _nHueOffset:Number = 0;

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
		
		public function set hueOffset(nHueOffset:Number): void {
			if (_nHueOffset != nHueOffset) {
				_nHueOffset = nHueOffset;
				CalcArrays();
			}
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

		public function HSVGradientMapImageOperation()
		{
			CalcArrays();
		}
		
		// Take a blend of color 1 and color 2. use clr1pct % of color 1 plus remaining % of color 2
		protected function BlendColors(clr1:Object, clr2:Object, clr1pct:Number): Object {
			if (clr1pct >= 1) return clr1;
			if (clr1pct <= 0) return clr2;
			
			var s:Number = clr1pct * clr1.s + (1-clr1pct) * clr2.s;
			var v:Number = clr1pct * clr1.v + (1-clr1pct) * clr2.v;
			var h1:Number = clr1.h;
			var h2:Number = clr2.h;
			var h:Number;
			if (Math.abs(h2-h1) <= 180) {
				h = clr1pct * h1 + (1-clr1pct) * h2;
			} else {
				// wrap around. Bring the bigger one back
				if (h1 > h2) h1 -= 360;
				else h2 -= 360;
				h = clr1pct * h1 + (1-clr1pct) * h2;
				if (h < 0) h += 360;
			}
			return {h:h, s:s, v:v};
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

		protected function CalcBlendColor(i:Number): Object {
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
			var obClr:Object = BlendColors(obFirstColor.color, obSecondColor.color, nFirstPct);
			return obClr;
		}
		
		protected function CalcColor(i:Number): Object {
			// First, get surrounding colors and their positions
			var obClr:Object = CalcBlendColor(i);
			if (_nHueOffset != 0) {
				// Make a copy before we change it
				obClr = {h:obClr.h + _nHueOffset, s:obClr.s, v:obClr.v};
				while (obClr.h > 360) obClr.h -= 360;
				while (obClr.h < 0) obClr.h += 360;
			}
			return obClr;
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
					var obClr:Object = CalcColor(i);
					var clr:uint = RGBColor.HSVtoUint(obClr.h, obClr.s, obClr.v);
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