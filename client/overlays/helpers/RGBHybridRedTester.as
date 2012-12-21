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
	import flash.geom.Rectangle;
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	public class RGBHybridRedTester extends RGBRedTester
	{
		private var _fUseLowerThreshold:Boolean = false;

		public override function IsTargetColor(clr:uint): Boolean {
			var nR:Number = ((clr & 0xff0000) >> 16);
			if (_fUseLowerThreshold) {
				return PctRGBIsRed(nR, RGBColor.GreenFromUint(clr), RGBColor.BlueFromUint(clr));
			} else {
				// Should be:
				// return R2GRGBIsRed(nR, RGBColor.GreenFromUint(clr), RGBColor.BlueFromUint(clr));
				// instead, we optimize this common path
				// We want nG * 2, so don't shift as much as we would to get nG
				return (nR > 40) && (nR > ((clr & 0x00ff00) >> 7));
			}
		}

		public override function Calibrate(bmdSrc:BitmapData, pt:Point):Boolean {
			// Set the threshold based on some analysis
			const knSampleSize:Number = 4; // Check this many pixels around the click target for red pixels.
			const knMaxDist:Number = 1.5 * knSampleSize; // Diagonal distance.
			
			var rcTest:Rectangle = new Rectangle(pt.x, pt.y, 0, 0);
			rcTest.inflate(knSampleSize, knSampleSize);
			rcTest = rcTest.intersection(bmdSrc.rect);

			var nRed1Pixels:Number = 0;
			var nRed1Tot:Number = 0;
			var nRed1R:Number = 0;
			var nRed2Pixels:Number = 0;
			var nRed2Tot:Number = 0;
			var nRed2R:Number = 0;
					
			var nWTot:Number = 0;
			var nRW:Number = 0;
			var nGW:Number = 0;
			var nBW:Number = 0;
					
			// Next, look for these pixels
			for (var x:Number = 0; x < rcTest.width; x++)
			{
				for (var y:Number = 0; y < rcTest.height; y++) {
					var ptTest:Point = new Point(rcTest.x + x, rcTest.y + y);
					var clr:uint = bmdSrc.getPixel(ptTest.x, ptTest.y);
					var nR:Number = RGBColor.RedFromUint(clr);
					var nG:Number = RGBColor.GreenFromUint(clr);
					var nB:Number = RGBColor.BlueFromUint(clr);
					if (R2GRGBIsRed(nR, nG, nB)) {
						nRed1Pixels++;
						nRed1Tot += nR+nG+nB;
						nRed1R += nR;
					}
					if (PctRGBIsRed(nR, nG, nB)) {
						nRed2Pixels++;
						nRed2Tot += nR+nG+nB;
						nRed2R += nR;
						
						var nDist:Number = Point.distance(pt, ptTest);
						var nW:Number = 1-(nDist/knMaxDist);
						if (nW > 0) {
							nWTot += nW;
							nRW += nR * nW;
							nGW += nG * nW;
							nBW += nB * nW;
						}
					}
				}
			}
			
			// Now we have finished our analysis - what next?
			if (nRed1Pixels < 2) _fUseLowerThreshold = true; // Nothing found, use a lower threshold
			else if (nRed2R / nRed2Tot < 0.45) _fUseLowerThreshold = true;
			else _fUseLowerThreshold = false;
			
			if (_fUseLowerThreshold) {
				_obClrBase = new Object();
				_obClrBase.nR = nRW / nWTot;
				_obClrBase.nG = nGW / nWTot;
				_obClrBase.nB = nBW / nWTot;
			}
			
			return super.Calibrate(bmdSrc, pt);
		}
		
		public override function RGBIsRed(nR:Number, nG:Number, nB:Number):Boolean {
			if (_fUseLowerThreshold) {
				return PctRGBIsRed(nR, nG, nB);
			} else {
				return R2GRGBIsRed(nR, nG, nB);
			}
		}	
		
		public function R2GRGBIsRed(nR:Number, nG:Number, nB:Number):Boolean {
			return (nR > 40) && (nR > 2 * nG);
		}	

		private var _obClrBase:Object = null;
		
		public function PctRGBIsRed(nR:Number, nG:Number, nB:Number):Boolean {
			var nTot:Number = nR + nG + nB;
			var nRpct:Number = nR/nTot;
			var nGpct:Number = nG/nTot;
			var nBpct:Number = nB/nTot;

			var nDiff:Number = 0;
			if (_obClrBase != null) {
				var nRDiff:Number = nR - _obClrBase.nR;
				var nGDiff:Number = nG - _obClrBase.nG;
				var nBDiff:Number = nB - _obClrBase.nB;
				nDiff = Math.sqrt(nRDiff * nRDiff + nGDiff * nGDiff + nBDiff * nBDiff);
				
				return nDiff < 30;
			} else {
				return nR > 40 && nRpct > 0.4 && nGpct < 0.31 && nBpct < 0.8 && nDiff < 30;
			}
		}	
	}
}