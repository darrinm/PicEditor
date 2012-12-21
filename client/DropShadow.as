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
package {
	// The DropShadowFilter has 3 problems
	// - slow because it creates a composite (cached) bitmap as big as the MovieClip it is filtering + some
	// - slow because it takes time to render, especially at highest quality and at arbitrary blur distances
	// - unable to shadow a MovieClip larger than 2,880 pixels due to its cached bitmap dependency (see above)
	//
	// We want a nice looking, dynamically generated drop shadow without these limitations. Our solution
	// is this DropShadow class which uses the DropShadowFilter to create a small drop shadow bitmap from
	// which we can create arbitrarily large shadows. We slice the small shadow bitmap into 8 MovieClips and
	// dynamically size and position them as requested. It is up to the caller to offset the shadow by the
	// desired amount.
	//
	// The small shadow bitmap is 100x100 pixels. The shadow is drawn into this bitmap, inset by 10 pixels
	// from each edge. The 8 slices come from the edges of the shadow bitmap, inset by 15 pixels. This way
	// 5 pixels of the solid shadow are grabbed in addition to 10 pixels of the feathered edge. The 5 pixels
	// of solid shadow are revealed when the shadow is offset from the object casting the shadow.
	
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.display.BitmapData;
	import flash.filters.DropShadowFilter;
	import flash.display.MovieClip;
	import flash.display.Bitmap;
	
	public class DropShadow extends MovieClip {
		static private var garcPieces:Array;
		static private var gbmdSrc:BitmapData;
		private var _amcPieces:Array;
		
		public function DropShadow() {
			_amcPieces = new Array();
			
			if (!garcPieces) {
				garcPieces = new Array(
					new Rectangle(0, 0, 15, 15),	// TL
					new Rectangle(15, 0, 70, 15),	// T
					new Rectangle(85, 0, 15, 15),	// TR
					new Rectangle(85, 15, 15, 70),	// R
					new Rectangle(85, 85, 15, 15),	// BR
					new Rectangle(15, 85, 70, 15),	// B
					new Rectangle(0, 85, 15, 15),	// BL
					new Rectangle(0, 15, 15, 70)	// L
				);
				
				// Create a source bitmap containing a Flash-rendered drop shadow
				var rcOuter:Rectangle = new Rectangle(0, 0, 100, 100);
				var rcInner:Rectangle = new Rectangle(10, 10, 80, 80);
				gbmdSrc = new util.VBitmapData(100, 100, true, 0x00000000);
				gbmdSrc.fillRect(rcInner, 0xffff0000);
				// CONFIG: drop shadow parameters
				var flt:DropShadowFilter = new DropShadowFilter(0, 90, 0x000000, 1, 10, 10, 0.65, 3, false, false, true);
				gbmdSrc.applyFilter(gbmdSrc, rcOuter, new Point(0, 0), flt);
			}
			
			// Cut the source bitmap into 8 MovieClips, 1 for each cell of a 9-grid minus the center
			for (var i:Number = 0; i < garcPieces.length; i++) {
				var rcSrc:Rectangle = garcPieces[i];
				_amcPieces[i] = new MovieClip();
				var bmdT:BitmapData = new VBitmapData(rcSrc.width, rcSrc.height, true, 0x00000000);
				bmdT.copyPixels(gbmdSrc, rcSrc, new Point(0, 0));
				_amcPieces[i].addChild(new Bitmap(bmdT));
			}
		}
		
		public function SetSize(cx:Number, cy:Number): void {
			var cxA:Number = -10;
			var cyA:Number = -10;
			
			// Very small images (<= 6x6 px) look weird with offset drop shadows
			// Reduce the offset for such images
			if (cx <= 6)
				cxA -= 7 - cx;
			if (cy <= 6)
				cyA -= 7 - cy;
				
			// TL
			_amcPieces[0]._x = cxA;
			_amcPieces[0]._y = cyA;
			
			// T
			_amcPieces[1]._x = _amcPieces[0]._x + _amcPieces[0]._width;
			_amcPieces[1]._y = cyA;
			_amcPieces[1]._width = Math.max(0, cx + cxA);
			
			// TR
			_amcPieces[2]._x = _amcPieces[1]._x + _amcPieces[1]._width;
			_amcPieces[2]._y = cyA;
			
			// R
			_amcPieces[3]._x = _amcPieces[2]._x;
			_amcPieces[3]._y = _amcPieces[2]._y + _amcPieces[2]._height;
			_amcPieces[3]._height = Math.max(0, cy + cyA);
			
			// BR
			_amcPieces[4]._x = _amcPieces[3]._x;
			_amcPieces[4]._y = _amcPieces[3]._y + _amcPieces[3]._height;
			
			// B
			_amcPieces[5]._x = _amcPieces[1]._x;
			_amcPieces[5]._y = _amcPieces[4]._y;
			_amcPieces[5]._width = Math.max(0, cx + cxA);
			
			// BL
			_amcPieces[6]._x = cxA;
			_amcPieces[6]._y = _amcPieces[5]._y;
			
			// L
			_amcPieces[7]._x = cxA;
			_amcPieces[7]._y = _amcPieces[3]._y;
			_amcPieces[7]._height = Math.max(0, cy + cyA);
		}
	}
}
