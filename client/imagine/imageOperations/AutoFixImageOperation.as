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
package imagine.imageOperations {
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	
	import imagine.ImageDocument;
	
	import overlays.helpers.RGBColor;
	
	import util.SplineInterpolator;
	import util.VBitmapData;
	
	[RemoteClass]
	public class AutoFixImageOperation extends PaletteMapImageOperation {
		protected var _bmdPrev:BitmapData = null;
		private var _strPrevState:String = "";
		protected var _obAnalysisPrev:Object = null;

		protected var _nMaxAnalysisArea:Number = 1000;
		protected var _fEqualize:Boolean = false; // Equalize means flatten the curve. Otherwise, just stretch it equally
		protected var _fMaintainColorBalance:Boolean = false;
		
		public var medianVal:Number = 127.5;
		
		private const knRedShift:Number = 16;
		private const knGreenShift:Number = 8;
		private const knBlueShift:Number = 0;

		public function set maxAnalysisArea(nMaxAnalysisArea:Number): void {
			_nMaxAnalysisArea = nMaxAnalysisArea;
		}

		public function set equalize(fEqualize:Boolean): void {
			_fEqualize = fEqualize;
		}

		public function set maintainColorBalance(fMaintainColorBalance:Boolean): void {
			_fMaintainColorBalance = fMaintainColorBalance;
		}

		// Return a scaled bitmap with an area of approximately nArea.
		protected function ScaleToArea(bmd:BitmapData, nArea:Number): BitmapData {
			var nScaleFact:Number = Math.sqrt(nArea / (bmd.width * bmd.height));
			var nScaledWidth:Number = Math.max(1, Math.round(nScaleFact * bmd.width));
			var nScaledHeight:Number = Math.max(1, Math.round(nScaleFact * bmd.height));
			var bmdOut:BitmapData = VBitmapData.Construct(nScaledWidth, nScaledHeight);
			var mat:Matrix = new Matrix();
			mat.scale(nScaledWidth / bmd.width, nScaledHeight / bmd.height);
			bmdOut.draw(bmd, mat);
			return bmdOut;
		}

		protected function GetAnalysis(bmd:BitmapData): Object {
			var i:Number;
			if (_bmdPrev != bmd || _obAnalysisPrev == null) {
				if (_obAnalysisPrev == null) {
					_obAnalysisPrev = new Object();
					_obAnalysisPrev.nArea = 0;
					_obAnalysisPrev.anR = new Array(256);
					_obAnalysisPrev.anG = new Array(256);
					_obAnalysisPrev.anB = new Array(256);
					_obAnalysisPrev.anL = new Array(256);
					for (i = 0; i < 256; i++) {
						_obAnalysisPrev.anR[i] = _obAnalysisPrev.anG[i] = _obAnalysisPrev.anB[i] = _obAnalysisPrev.anL[i] = 0;
					}
				}
				var bmdDispose:BitmapData = null;
				if (bmd.width * bmd.height > _nMaxAnalysisArea) {
					bmd = ScaleToArea(bmd, _nMaxAnalysisArea);
					bmdDispose = bmd;
				}
				
				_obAnalysisPrev.nArea = bmd.width * bmd.height;
				var anR:Array = _obAnalysisPrev.anR;
				var anG:Array = _obAnalysisPrev.anG;
				var anB:Array = _obAnalysisPrev.anB;
				var anL:Array = _obAnalysisPrev.anL;
				
				for (i = 0; i < 256; i++) {
					anR[i] = anG[i] = anB[i] = anL[i] = 0;
				}
				for (var x:Number = 0; x < bmd.width; x++) {
					for (var y:Number = 0; y < bmd.height; y++) {
						var clr:uint = bmd.getPixel(x,y);
						var nR:Number = RGBColor.RedFromUint(clr);
						var nG:Number = RGBColor.GreenFromUint(clr);
						var nB:Number = RGBColor.BlueFromUint(clr);
						var nL:Number = RGBColor.LuminosityFromRGB(nR, nG, nB);
						anR[nR]++;
						anG[nG]++;
						anB[nB]++;
						anL[nL]++;
					}
				}
				
				if (bmdDispose)
					bmdDispose.dispose();
				
				_bmdPrev = bmd;
			}
			return _obAnalysisPrev;
		}

		public function AutoFixImageOperation() {
			// ImageOperation constructors are called with no arguments during Deserialization
			_acoRed = new Array(256);
			_acoGreen = new Array(256);
			_acoBlue = new Array(256);
		}

		override protected function get applyHasNoEffect(): Boolean {
			return false;
		}
		
		public override function Apply(imgd:ImageDocument, bmdOrig:BitmapData, fDoObjects:Boolean, fUseCache:Boolean=false): BitmapData {
			// If we are using the cache, we need to fore a recalculation of the arrays
			CalcArraysIfNeeded(bmdOrig);
			return super.Apply(imgd, bmdOrig, fDoObjects, fUseCache);
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			CalcArraysIfNeeded(bmdSrc);
			return super.ApplyEffect(imgd, bmdSrc, fDoObjects, fUseCache);
		}
		
		private function CalcArraysIfNeeded(bmd:BitmapData): void {
			var strState:String = _fMaintainColorBalance + ":" + _fEqualize + ":" + _nMaxAnalysisArea + ":" + medianVal;
			if (bmd != _bmdPrev || _strPrevState != strState) {
				CalcArrays(bmd);
				_strPrevState = strState;
			}
		}
		
		private function CalcArrays(bmd:BitmapData): void {
			var obAnalysis:Object = GetAnalysis(bmd);
			// Now fill _acoRed, _acoGreen, and _acoBlue based on our analysis and our settings
			// Four possible results:
			// 1. Stretch, maintain color balance
			// 2. Stretch, rebalance colors
			// 3. Equalize, maintain color balance
			// 4. Equalize, rebalance colors
			var nTot:Number = obAnalysis.nArea;
			var anR:Array = obAnalysis.anR;
			var anG:Array = obAnalysis.anG;
			var anB:Array = obAnalysis.anB;
			if (_fMaintainColorBalance) {
				anR = anG = anB = obAnalysis.anL;
			}
			
			if (_fEqualize) {
				Equalize(_acoRed, knRedShift, anR, nTot);
				Equalize(_acoGreen, knGreenShift, anG, nTot);
				Equalize(_acoBlue, knBlueShift, anB, nTot);
			} else {
				// Stretch
				Stretch(_acoRed, knRedShift, anR);
				Stretch(_acoGreen, knGreenShift, anG);
				Stretch(_acoBlue, knBlueShift, anB);
			}
		}
		
		private function Equalize(anOut:Array, nShift:Number, anHist:Array, nTot:Number): void {
			// First, set our start and end points
			var nInMin:Number = FirstNonZeroIndex(anHist);
			var nInMax:Number = LastNonZeroIndex(anHist);
			
			// Next, set our mid point color. Find the median color, adjust to be 128
			var nInMid:Number = FindSum(anHist, nTot/2);
			var sp:SplineInterpolator = new SplineInterpolator();
			sp.add(nInMin, 0);
			sp.add(nInMid, medianVal);
			sp.add(nInMax, 255);
			
			for (var i:Number = 0; i <= 255; i++) {
				var nOutPos:Number = sp.Interpolate(i);
				anOut[i] = Clamp(Math.round(nOutPos), 0, 255) << nShift;
			}
		}
		
		// Assume a two-d representation of an array as a bar graph
		// The bars are centered on their indexes and touching neighbors.
		// Thus, at an index, e.g. 35, the "area" of that index is the sum
		// of predecsors plus half of that value.
		// Returns a value between -0.5 (before first element) and an.length-0.5 (after last element)
		private function FindSum(an:Array, nTarget:Number): Number {
			var nRemaining:Number = nTarget;
			for (var i:Number = 0; i < an.length; i++) {
				var nNext:Number = an[i];
				if (nNext >= nRemaining) {
					return i - 0.5 + nRemaining / nNext;
				} else {
					nRemaining -= nNext;
				}
			}
			return an.length - 0.5; // Last element
		}
		
		private function FirstNonZeroIndex(an:Array): Number {
			for (var i:Number = 0; i < an.length; i++) {
				if (an[i] != 0) return i;
			}
			return -1;
		}
		
		private function ArrayAverage(an:Array): Number {
			var nTot:Number = 0;
			for (var i:Number = 0; i < an.length; i++) {
				nTot += an[i];
			}
			return nTot / an.length;
		}
		
		private function LastNonZeroIndex(an:Array): Number {
			for (var i:Number = an.length-1; i >= 0; i--) {
				if (an[i] != 0) return i;
			}
			return -1;
		}
		
		private function Clamp(nVal:Number, nMin:Number, nMax:Number): Number {
			if (nVal < nMin) return nMin;
			if (nVal > nMax) return nMax;
			return Math.round(nVal);
		}
		
		private function Map(nVal:Number, nInMin:Number, nInMax:Number, nOutMin:Number, nOutMax:Number): Number {
			nVal = nOutMin + ((nVal - nInMin) / (nInMax - nInMin)) * (nOutMax - nOutMin);
			return Clamp(nVal, nOutMin, nOutMax);
		}

		private function Stretch(anOut:Array, nShift:Number, anHist:Array): void {
			// Stretch is easy
			var nOutMin:Number = 0;
			var nOutMax:Number = 255;
			var nInMin:Number = FirstNonZeroIndex(anHist);
			var nInMax:Number = LastNonZeroIndex(anHist);
			
			for (var i:Number = 0; i < 256; i++) {
				anOut[i] = Map(i, nInMin, nInMax, nOutMin, nOutMax) << nShift;
			}
		}
	}
}
