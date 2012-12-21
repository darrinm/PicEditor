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
package overlays.helpers
{
	// This class is used to calculate red, blue, and green proportions
	// when temperature shifting left or right.
	// Whitebalance color changes impact images by multiplying RGB color channels
	// by different multipliers while maintaining a consistent luminosity
	// Basically, there are three ways we can talk about a white balance shift:
	// 1. In terms of R,G,B ratios (e.g. shift blue to 2 x red)
	// 2. In terms of temparature/green (shift the temperature towards blue, add a bit of green)
	// 3. In terms of a color to neutralize (e.g. take 212,200,190 and make it gray)
	// This class is responsible for converting between these various representations
	public class WBAdjustment
	{
		// This class returns RGB ratios, use red as the point of relativity
		// by fixing it at 1. Green and Blue are thus relative to red.
		private const knRM:Number = 1;
		private var _nGM:Number;
		private var _nBM:Number;

		private var _nTemp:Number; // Temperature (between -1 and 1)
		private var _nGreen:Number;

		// Constants used for conversion between color multipliers and temp/green
		private static const kTempMin:Number = -1; // Roughly corresponds to 2000
		private static const kTempMax:Number = 1; // Rougly corresponds to 12000
		private static const kTempMid:Number = (kTempMin + kTempMax) / 2;

		private static const kMaxRedMult:Number = 3; // Increase this for more red
		private static const kMaxBlueMult:Number = 5; // Incrase this for more blue when we go cold
		
		public function WBAdjustment(nRM:Number, nGM:Number, nBM:Number, fInitTempAndGreen:Boolean = true) {
			setRGBMult(nRM, nGM, nBM);
			if (fInitTempAndGreen) {
				CalculateTempAndGreen();
			}
		}
		
		private function setRGBMult(nRM:Number, nGM:Number, nBM:Number): void {
			// Normalize the multipliers
			if (nRM == 0) nRM = 0.1; // Avoid division by zero
			_nGM = nGM / nRM;
			_nBM = nBM / nRM;
		}
		
		// Given an RGB of a neutral element which has a color cast,
		// returns the WBAdjustemnt to neutralize the image.
		public static function WBToNeutralizeRGB(nR:Number, nG:Number, nB:Number): WBAdjustment {
			if (nR == 0) nR = 0.01; // Avoid division by zero
			if (nG == 0) nG = 0.01;
			if (nB == 0) nB = 0.01;
			return new WBAdjustment(1/nR, 1/nG, 1/nB);
		}

		public static function WBFromTempAndGreen(nTemp:Number, nGreen:Number): WBAdjustment {
			var wba:WBAdjustment = new WBAdjustment(1, 1, 1, false);
			wba._nGreen = nGreen;
			wba._nTemp = nTemp;
			wba.setFactorsFromTempAndGreen();
			return wba;
		}
		
		private function CalculateTempAndGreen(): void {
			if (knRM == 0 || _nGM == 0 || _nBM == 0) return;

			// First, calculate temp and green
			_nTemp = RBMultToTemp(knRM, _nBM);
			var obRGBMult:Object = TempToRGBMult(_nTemp);
			var nGreen:Number = _nGM / (obRGBMult.nGM / obRGBMult.nRM);
			_nGreen = Clamp(nGreen, 0.33, 3);

			// Next, go back the other way to set RM, GM, and BM based on temp and green
			// This keeps RM, GM, and BM without our temp/green limits.
			setFactorsFromTempAndGreen();
		}
		
		private function setFactorsFromTempAndGreen(): void {
			var obRGBMult:Object = TempToRGBMult(_nTemp);
			setRGBMult(obRGBMult.nRM, obRGBMult.nGM * _nGreen, obRGBMult.nBM);
		}
		
		private function MultFact(): Number {
			// Try to maintain the same luminosity
			// these constants are from com.gskinner.geom.ColorMatrix
			const lumR:Number = 0.3086;
			const lumG:Number = 0.6094;
			const lumB:Number = 0.0820;

			return 1 / (lumR * knRM + lumG * _nGM + lumB * _nBM);
		}
		
		public function get RMult(): Number {
			return MultFact() * knRM;
		}

		public function get GMult(): Number {
			return MultFact() * _nGM;
		}

		public function get BMult(): Number {
			return MultFact() * _nBM;
		}

		public function Temp(): Number {
			return _nTemp;
		}

		public function Green(): Number {
			return _nGreen;
		}
		
		public function IsValid(): Boolean {
			return !isNaN(_nGreen) && !isNaN(_nTemp) && (_nTemp >= kTempMin) && (_nTemp <= kTempMax);
		}

		// Internal implementation
		// This is how we convert color multipliers too and from a temperature/green value
		private static function TempToRGBMult(nTemp:Number): Object {
			var nRM:Number = 1;
			var nGM:Number = 1;
			var nBM:Number = 1;
			
			if (nTemp > kTempMid) { // Warmer = more red
				nRM = TranslateSpace(nTemp, kTempMid, kTempMax, 1, kMaxRedMult);
			} else {
				nBM = TranslateSpace(nTemp, kTempMid, kTempMin, 1, kMaxBlueMult);
			}
			nGM *= (nRM + nBM) / 2; // Maintain the Green to R+B ratio
			return {nRM:nRM, nGM:nGM, nBM:nBM};
		}

		private static function RBMultToTemp(nRM:Number, nBM:Number): Number {
			var nTemp:Number;
			if (nRM > nBM) {
				// More red, adjust nRM based on nBM == 1
				nRM /= nBM;
				nTemp = TranslateSpace(nRM, 1, kMaxRedMult, kTempMid, kTempMax);
			} else {
				nBM /= nRM;
				nTemp = TranslateSpace(nBM, 1, kMaxBlueMult, kTempMid, kTempMin);
			}
			return Clamp(nTemp, kTempMin, kTempMax);
		}
		
		// Utility functions
		private static function Clamp(n:Number, nMin:Number, nMax:Number): Number {
			if (n < nMin) return nMin;
			else if (n > nMax) return nMax;
			else return n;
		}
		
		private static function TranslateSpace(n:Number, nMin:Number, nMax:Number, nNewMin:Number, nNewMax:Number): Number {
			return ((n - nMin)/(nMax-nMin)) * (nNewMax - nNewMin) + nNewMin;
		}
	}
}