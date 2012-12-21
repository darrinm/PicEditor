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
package util
{
	import flash.geom.Point;
	import flash.display.BitmapData;
	
	public class PrintLayout
	{
		// Input
		private var _ptPrintSize:Point = null;
		private var _fFullPage:Boolean = false;
		private var _ptDesiredSize:Point = null;
		private var _fCropToFit:Boolean = true;
		private var _ptImageDim:Point = null;

		// Output. Default values correspond to out of bounds.
		private var _fOutOfBounds:Boolean = false;
		private var _aploFirstPageItems:Array = null;
		private var _aploLastPageItems:Array = null;
		private var _nNumPages:Number = 0;
		
		public function PrintLayout(obPrintMetrics:Object, obDesiredPrintSize:Object, fCropToFit:Boolean, bmd:BitmapData) {
			_ptPrintSize = obPrintMetrics.ptPrintSize.clone();
			_fFullPage = obDesiredPrintSize.fFullPage;
			_ptDesiredSize = obDesiredPrintSize.ptDesired.clone();
			_fCropToFit = fCropToFit;
			_ptImageDim = new Point(bmd.width, bmd.height);
			CalcLayout();
		}
		
		// Calculates the layout
		// This includes:
		// 1. Number of pages
		// 2. The first n page layout
		// 3. The last page layout
		// - A page layout is:
		//   - The position of one or more photos and their cropping, and rotation.
		// Represented as:
		//   1. Image rectangle, scale and crop info
		//   2. Offset pt (in print coordinates) and orientation (0 or 90)
		// Note: Page size/margins are ignored. Print size is used for evrything.
		private function CalcLayout(): void {
			// Do a bunch of print wizardry to set up our output variables
			// Calculate our desired size. Orient the same as our page. May be full page.
			if (_fFullPage) {
				_ptDesiredSize = _ptPrintSize.clone();
			}  else {
				// Fixed size. Rotate to fit on the page.
				if ((_ptDesiredSize.x > _ptDesiredSize.y) != (_ptPrintSize.x  > _ptPrintSize.y)) {
					_ptDesiredSize = new Point(_ptDesiredSize.y, _ptDesiredSize.x);
				}
			}

			// Next, see if our image is too large to fit on a single page or needs some shrinking.
			var nShrinkFactor:Number = Math.min(_ptPrintSize.x / _ptDesiredSize.x,
												_ptPrintSize.y / _ptDesiredSize.y);
			if (nShrinkFactor < 0.9) {
				// Don't shrink below 90% of target size
				_fOutOfBounds = true;
				return;
			}
			if (nShrinkFactor < 1) {
				_ptDesiredSize.x *= nShrinkFactor;
				_ptDesiredSize.y *= nShrinkFactor;
			}
			// Now we have made some adjustments to fit our image on our page. The next step is to create
			// our default photo layout.
			var plo:PrintPhotoLayout = new PrintPhotoLayout(_ptImageDim, _ptDesiredSize, _fCropToFit);
			
			// Now put one or more of these on the page.
			
			// UNDONE: Handle the case of putting more than one on a page.
			// PrintPhotoLayout is in bitmap dimensions. Multiply by scale to get page dims. This should be ptDesiredSize
			
			// See how things fit. If only one fits, put it at upper left of page, same orientation as page
			// If only 2 fit, put it at upper left, rotate for maximum space
			// If more than 2 fit, put it at upper left, same orientation as page.
			
			var cxOffset:Number = 0;
			var cyOffset:Number = 0;
			var nRotation:Number = 0;
			nRotation = ((_ptPrintSize.x > _ptPrintSize.y) == (_ptImageDim.x > _ptImageDim.y)) ? 0 : 90;
			cxOffset = (_ptPrintSize.x - _ptDesiredSize.x)/2;
			cyOffset = (_ptPrintSize.y - _ptDesiredSize.y)/2;

			plo.Position(cxOffset, cyOffset, nRotation);
			_aploFirstPageItems = new Array();
			_aploFirstPageItems.push(plo);
		}
		
		private function NumberThatFit(ptDesiredSize:Point, ptPageSize:Point, fRotate:Boolean): Number {
			if (fRotate) ptDesiredSize = new Point(ptDesiredSize.y, ptDesiredSize.x);
			return Math.floor(ptPageSize.x/ptDesiredSize.x) *
				Math.floor(ptPageSize.y/ptDesiredSize.y);
		}

		public function get outOfBounds(): Boolean {
			return _fOutOfBounds;
		}
		
		public function get numPages(): Number {
			return _nNumPages;
		}
		
		public function get firstPageItems(): Array {
			return _aploFirstPageItems;
		}

		public function get lastPageItems(): Array {
			return _aploLastPageItems;
		}
	}
}