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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.display.BitmapData;
	
	public class RGBRedTester implements IRedTester
	{
		private var _ptStart:Point = null;
		
		public function IsTargetColor(clr:uint): Boolean {
			return RGBIsRed(RGBColor.RedFromUint(clr),RGBColor.GreenFromUint(clr),RGBColor.BlueFromUint(clr));
		}
		
		public function RGBIsRed(nR:Number, nG:Number, nB:Number): Boolean {
			return false;
		}

		public function Calibrate(bmdSrc:BitmapData, pt:Point): Boolean {
			var fSuccess:Boolean = false;

			const knSampleSize:Number = 4; // Check this many pixels around the click target for red pixels.
			const knMaxDist:Number = 1.5 * knSampleSize; // Diagonal distance.
			
			var aanRedSibblings:Array = new Array();
			
			var rcTest:Rectangle = new Rectangle(pt.x, pt.y, 0, 0);
			rcTest.inflate(knSampleSize, knSampleSize);
			rcTest = rcTest.intersection(bmdSrc.rect);
			
			// First, initialize our red sibbling count array to zeros
			for (var x:Number = 0; x < rcTest.width; x++) {
				aanRedSibblings[x] = new Array();
				for (var y: Number = 0; y < rcTest.height; y++) {
					aanRedSibblings[x][y] = 0;
				}
			}
					
			// Next, fill our array based on our sibbilings.
			for (x = 0; x < rcTest.width; x++) {
				for (y = 0; y < rcTest.height; y++) {
					var ptTest:Point = new Point(rcTest.x + x, rcTest.y + y);
					if (IsTargetColor(bmdSrc.getPixel(ptTest.x, ptTest.y))) {
						aanRedSibblings[x][y] += 30; // Weight the center greater than all of the sibblings
						// Add a tiny weight (up to 2) for closeness to the click point
						var nDist:Number = Point.distance(pt, ptTest);
						aanRedSibblings[x][y] += 2 * (1 - nDist/knMaxDist);
						if (y > 0) aanRedSibblings[x][y-1] += 3; // Side
						if ((y+1) < rcTest.height) aanRedSibblings[x][y+1] += 3; // Side
						if (x > 0) {
							aanRedSibblings[x-1][y] += 3; // Side
							if (y > 0) aanRedSibblings[x-1][y-1] += 2; // Corner
							if ((y+1) < rcTest.height) aanRedSibblings[x-1][y+1] += 2; // Corner
						}
						if ((x+1) < rcTest.width) {
							aanRedSibblings[x+1][y] += 3; // Side
							if (y > 0) aanRedSibblings[x+1][y-1] += 2; // Corner
							if ((y+1) < rcTest.height) aanRedSibblings[x+1][y+1] += 2; // Corner
						}
					}
				}
			}
			
			// Finally, go back through the array to find the highest weighted sibbling.
			var nMaxWeight:Number = 0;
			for (x = 0; x < rcTest.width; x++) {
				for (y = 0; y < rcTest.height; y++) {
					if (aanRedSibblings[x][y] > nMaxWeight) {
						nMaxWeight = aanRedSibblings[x][y];
						_ptStart = new Point(rcTest.x + x, rcTest.y + y);
					}
				}
			}
			return nMaxWeight > 0;
		}

		public function get StartPoint(): Point {
			return _ptStart;
		}
	}
}