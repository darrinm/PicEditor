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
package imageUtils
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	
	import overlays.helpers.RGBColor;
	
	import util.VBitmapData;
	
	
	/**
	 * Dispatched when the histogram changes (and needs to be redrawn)
	 */
	[Event(name="change", type="flash.events.Event")]
	
	public class SimpleHistogram extends EventDispatcher
	{
		protected var _an:Array = null;
		
		private static const knMaxArea:Number = 10000;
		// private static const knMaxArea:Number = 10;

		private static const knLinesToClip:Number = 10;
		
		// Given a list of histogram arrays, figure out
		// a decent clip value ("max" value to display)
		// We want to choose a value that does some clipping so that
		// we can see a lot of middle values but not too much clipping.
		private static function CalcClipMax(aan:Array): Number {
			var nMax:Number = Number.MAX_VALUE;
			var anMax:Array = [];
			for each (var anIn:Array in aan) {
				for each (var n:Number in anIn) {
					anMax.push(n);
					anMax.sort(Array.DESCENDING | Array.NUMERIC);
					if (anMax.length > knLinesToClip) anMax.length = knLinesToClip;
				}
			}
			// Coming out, anMax is an array of the knLinesToClip largest elements of the array
			// We care only about the last element of this array
			return anMax[anMax.length-1];
		}
		
		public static function HistogramsFromBitmap(bmd:BitmapData): Object {
			var dtStart:Date = new Date();
			var anR:Array = [];
			var anG:Array = [];
			var anB:Array = [];
			var anLum:Array = [];
			
			var i:Number;
			for (i = 0; i < 256; i++) {
				anR[i] = 0;
				anG[i] = 0;
				anB[i] = 0;
				anLum[i] = 0;
			}
			
			var bmdTemp:BitmapData = null;
			
			var nScale:Number = knMaxArea / (bmd.width * bmd.height);
			if (nScale < 1) {
				nScale = Math.sqrt(nScale);
				var nTargetWidth:Number = Math.round(nScale * bmd.width);
				var nTargetHeight:Number = Math.round(nScale * bmd.height);
				
				bmdTemp = new VBitmapData(nTargetWidth, nTargetHeight, false, 0xffffffff, "Histogram Temp");
				var mat:Matrix = new Matrix();
				mat.scale(nTargetWidth/bmd.width, nTargetHeight/bmd.height);
				bmdTemp.draw(bmd, mat, null, null, null, true);
				bmd = bmdTemp;
			}
			
			var nR:Number;
			var nG:Number;
			var nB:Number;
			var nLum:Number;
			for (var x:Number = 0; x < bmd.width; x++) {
				for (var y:Number = 0; y < bmd.height; y++) {
					var clr:uint = bmd.getPixel(x, y);
					nR = RGBColor.RedFromUint(clr);
					nG = RGBColor.GreenFromUint(clr);
					nB = RGBColor.BlueFromUint(clr);
					nLum = Math.round(RGBColor.LuminosityFromRGB(nR, nG, nB));
					anR[nR]++;
					anG[nG]++;
					anB[nB]++;
					anLum[nLum]++;
				}
			}
			var nArea:Number = (bmd.width * bmd.height);
			if (bmdTemp) bmdTemp.dispose();
			var dtEnd:Date = new Date();

			var nClipMax:Number = CalcClipMax([anR, anG, anB]);
			
			return {clipMax:nClipMax, ahist:[new SimpleHistogram(anR),new SimpleHistogram(anG),new SimpleHistogram(anB),new SimpleHistogram(anLum)]};  
		}
		
		private static function Log(nBase:Number, n:Number): Number {
			return Math.log(n) / Math.log(nBase);
		}

		// Find min/max in (and mid) settings to expand this histogram
		// If fNeutralMid is true, choose a mid point that will not change the color of medium gray
   		public function GetAutoLevels(nClipPct:Number, fNeutralMidtones:Boolean=false): Object {
			var obSettings:Object = {};
			// First, sum up our points.
			var i:Number;
			var nTotal:Number = 0;
			for (i = 0; i < _an.length; i++) {
				nTotal += _an[i];
			}
			
			// Now walk up until we get past nClipPct and walk back one
			var nClipped:Number = 0;
			for (i = 0; i < _an.length; i++) {
				nClipped += _an[i];
				if ((nClipped / nTotal) > (nClipPct/100)) {
					break;
				}
			}
			obSettings.inMin = Math.max(0, i-1);
			nClipped = 0;
			for (i = _an.length-1; i >= 0; i--) {
				nClipped += _an[i];
				if ((nClipped / nTotal) > (nClipPct/100)) {
					break;
				}
			}
			obSettings.inMax = Math.min(_an.length-1, i+1);
			
			var nMidTarget:Number = -1;
			if (fNeutralMidtones) {
				nMidTarget = 127.5;
			}
			// Add other algorithms for a mid target?
			
			if (nMidTarget > 0) {
				obSettings.mid = SimpleHistogram.MidForVal(nMidTarget, obSettings.inMin, obSettings.inMax);
			} else {
				obSettings.mid = 0.5;
			}
			
			return obSettings;	   			
   		}
   		
   		// Given a min, a max, and a neutral target, calculate the mid
   		public static function MidForVal(nTargetVal:Number, nMin:Number, nMax:Number): Number {
   			nTargetVal = 255 - nTargetVal;
   			if (nMax < (nTargetVal + 1)) return 1; // max mid
   			if (nMin > (nTargetVal - 1)) return 0; // min mid
			var y1:Number = (127.5 - nMin) / (nMax - nMin);
			var nMid:Number = SimpleHistogram.Log(10, SimpleHistogram.Log(y1, nTargetVal / 255)); // range -1 to 1
			nMid = (nMid + 1) / 2; // Convert range to 0 to 1
			nMid = Math.max(Math.min(nMid, 1), 0); // Clip to 0 to 1 range
			return nMid;
   		}
		
		public function SimpleHistogram(an:Array=null) {
			if (an == null) {
				an = new Array();
				for (var i:Number = 0; i < 256; i++) an.push(0);
			}
			setArray(an);
		}
		
		public function get array(): Array {
			return _an;
		}
		
		public function setArray(an:Array): void {
			_setArray(an);
		}
		
		protected function _setArray(an:Array): void {
			_an = an;
			for (var i:Number = 0; i < 256; i++) {
				if (_an[i] < 0) _an[i] = 0;
			}
			dispatchEvent(new Event("change"));
		}
	}
}