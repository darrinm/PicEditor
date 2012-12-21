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
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class FloodFill
	{
		protected var _clrFill:uint = 0;
		protected var _clrTest:uint = 0;
		protected var _ftst:IFillTest;
		protected var _nPixelsFilled:Number = 0; // keep track of the number of pixels filled

		protected var _nMaxPixelsFilled:Number = 2800/2*2800/2; // Timeout after this many pixels tested (may overflow by image width)
		protected var _nMaxSecs:Number = 10; // Timeout after this many seconds

		private var YMAX:Number;
		private var XMAX:Number;
		
		protected var aLines:Array;
		protected var _bmdSrc:BitmapData;
		protected var _bmdTarget:BitmapData;

		public function set MaxPixelsFilled(nMaxPixelsFilled:Number): void {
			_nMaxPixelsFilled = nMaxPixelsFilled;
		}

		protected function PUSH(y:Number, xL:Number, xR:Number, yD:Number): void {
			if (y + yD >= 0 && y + yD <= YMAX && xL <= xR) {
				aLines.push({y:y, xL:xL, xR:xR, yD:yD});
			}
		}

		protected function pixelread(x:Number, y:Number): Boolean {
			// Elegant version would be this:
			// return (!TargetFilled && SourceNeedsFilling)
			// Favor efficiency instead:
			if (_bmdTarget.getPixel32(x, y) == _clrFill) return false;
			if (_ftst) return _ftst.IsTargetColor(_bmdSrc.getPixel(x,y));
			else return _bmdSrc.getPixel32(x, y) == _clrTest;
		}

		protected function pixelwrite(x:Number, y:Number): void {
			_nPixelsFilled++;
			_bmdTarget.setPixel32(x, y, _clrFill);
		}
		
		public function SetFill(ftst:IFillTest, clrFill:uint, clrTest:uint = 0): void {
			_ftst = ftst;
			_clrFill = clrFill;
			_clrTest = clrTest;
		}

		// Returns a count of the pixels filled		
		public function get PixelsFilled(): Number {
			return _nPixelsFilled;
		}
		
		public function Fill(bmdSrc:BitmapData, ptStart:Point, bmdTarget:BitmapData): void {
			_bmdSrc = bmdSrc;
			_bmdTarget = bmdTarget;
			XMAX = bmdSrc.width - 1;
			YMAX = bmdSrc.height - 1;
			var x:Number = Math.round(ptStart.x);
			var y:Number = Math.round(ptStart.y);
			if (!pixelread(x, y)) return; // No pixels to fill
			DoFill(x, y);
//			ScanlineFill(x, y);
		}
		
		// Scanline fill algorithm.
		protected function ScanlineFill(x:Number, y:Number): void {
			// Coming in, we know we want to fill x,y
			// We will scan left and right to find pixels that need filling
			// and then scan up and down off of pixels we filled.
			var xLFill:Number;
			var xRFill:Number;

			pixelwrite(x, y);

			// Left
			xLFill = x - 1;
			while (xLFill >= 0 && pixelread(xLFill, y)) {
				pixelwrite(xLFill, y);
				xLFill--;
			}
			xLFill++;
			
			// Right
			xRFill = x + 1;
			while (xRFill < _bmdSrc.width && pixelread(xRFill, y)) {
				pixelwrite(xRFill, y);
				xRFill++;
			}
			xRFill--;
			
			// look up and down from pixels we filled.
			for (var i:Number = xLFill; i <= xRFill; i++ )
			{
				// Look up
				if (y > 0 && pixelread(i, y - 1)) {
					ScanlineFill(i, y - 1);
				}
				// Look down
				if ((y + 1) < _bmdSrc.height && pixelread(i, y + 1)) {
					ScanlineFill(i, y + 1);
				}
			}
		}
				
		// This is the Seed Fill algorithm from Graphics Gems 1 page 721
		// It is a non-recursive (it uses a stack) scanline fill algorithm.
		// It fills left and right first, then up and down.
		// SeedLines pushed onto the stack represent "places ajacent to a
		// horzontal line I just filled" - in other words, pixels adjacent to fill pixels
		// that need to be checked. They include a direction (yd) so we don't have to
		// re-check the pixels we just filled.
		protected function DoFill(x:Number, y:Number): void {
			var x1:Number;
			var x2:Number;
			var yD:Number;
			var xLeft:Number;
			
			aLines = new Array();

			// These two seed lines get us started
		    PUSH(y, x, x, 1);			/* needed in some cases */
		    PUSH(y + 1, x, x, -1);		/* seed segment (popped 1st) */
		   
		    var nStopTime:Number = new Date().time + _nMaxSecs * 1000;
		   
		    var nStarted:Number = new Date().time;
		   
		    while (aLines.length > 0) {
		    	if ((_nPixelsFilled >= _nMaxPixelsFilled) || (new Date().time >= nStopTime)) break;
				/* pop segment off stack and fill a neighboring scan line */
				var ob:Object = aLines.pop();
				y = ob.y + ob.yD;
				x1 = ob.xL;
				x2 = ob.xR;
				yD = ob.yD;
				/*
				 * segment of scan line y-yd for x1<=x<=x2 was previously filled,
				 * now explore adjacent pixels in scan line y
				 */
				for (x = x1; x >= 0 && pixelread(x, y); x--)
				    pixelwrite(x, y);

				if (x >= x1)
				{
					// Skip algorithm
					for (x++; x <= x2 && !pixelread(x, y); x++);
				    xLeft = x;
				} else {
					xLeft = x + 1;
					if (xLeft < x1) PUSH(y, xLeft, x1 - 1, -yD);		/* leak on left? */
					x = x1 + 1;
				}
				do {
				    for (; x <= XMAX && pixelread(x, y); x++)
						pixelwrite(x, y);
				    PUSH(y, xLeft, x - 1, yD);
				    if (x > x2 + 1) PUSH(y, x2 + 1, x - 1, -yD);	/* leak on right? */
					for (x++; x <= x2 && !pixelread(x, y); x++);
				    xLeft = x;
				} while (x <= x2)
			}
		    var nStopped:Number = new Date().time;
		}
	}
}