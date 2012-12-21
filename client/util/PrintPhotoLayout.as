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
	import mx.controls.Image;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.display.Bitmap;
	import flash.geom.Point;
	import flash.display.Sprite;
	import mx.containers.Canvas;
	import mx.core.ScrollPolicy;
	
	public class PrintPhotoLayout
	{
		private var _rcPrintArea:Rectangle = null;

		private var _ptImageDim:Point = null;
		private var _nScale:Number = 0;
	
		private var _nRotation:Number = 0;
		private var _cxOffset:Number = 0;
		private var _cyOffset:Number = 0;
		
		public function PrintPhotoLayout(ptImageDim:Point, ptDesiredSize:Point, fCropToFit:Boolean) {
			_ptImageDim = ptImageDim.clone();
			_rcPrintArea = GetPrintArea(_ptImageDim.x, _ptImageDim.y, ptDesiredSize.x/ptDesiredSize.y, fCropToFit);
			_nScale = Math.max(ptDesiredSize.x, ptDesiredSize.y) / Math.max(_rcPrintArea.width, _rcPrintArea.height);
		}
		
		public function get rotation(): Number {
			return _nRotation;
		}
		
		public function Position(cxOffset:Number, cyOffset:Number, nRotation:Number): void {
			_cxOffset = cxOffset;
			_cyOffset = cyOffset;
			_nRotation = nRotation;
		}
		
		// Return a print area rectangle based on the image width, height, target aspect ratio, and crop/scale
		// The the aspect ratio will be inverted (image rotated) to the best fit before cropping/scaling
		// The x and y coordinates will either crop the bitmap (if positive) or
		// represent area which needs to be padded for scaling (if negative)
		private function GetPrintArea(cxBM:Number, cyBM:Number, nAspectRatio:Number, fCrop:Boolean): Rectangle {
			// Rotate the aspect ratio to be width/height with best fit
			// If width > height, the aspect ratio (width/height) should be > 1

			if ((cxBM > cyBM) != (nAspectRatio > 1))
				nAspectRatio = 1 / nAspectRatio;
				
			// Check to see which side is bigger than our target aspect ratio
			var fWidthLarger:Boolean = (cxBM/cyBM) > nAspectRatio;
			
			// Width dominant means we set the print area based on the width of the image
			var fWidthDominant:Boolean = fWidthLarger == !fCrop;
			
			var rcPrintArea:Rectangle;
			if (fWidthDominant)
				rcPrintArea = new Rectangle(0, 0, cxBM, cxBM / nAspectRatio);
			else
				rcPrintArea = new Rectangle(0, 0, cyBM * nAspectRatio, cyBM);
			
			// Center the print area
			// If the bitmap width is greater than the print area (crop)
			// move the print area right (positive).
			// Otherwise, move it left (negative) to add space.
			rcPrintArea.x = (cxBM - rcPrintArea.width) / 2;
			rcPrintArea.y = (cyBM - rcPrintArea.height) / 2;
			
			rcPrintArea.x = Math.round(rcPrintArea.x);
			rcPrintArea.y = Math.round(rcPrintArea.y);
			rcPrintArea.width = Math.round(rcPrintArea.width);
			rcPrintArea.height = Math.round(rcPrintArea.height);
			
			return rcPrintArea;
		}

		
		public function Copy(plo:PrintPhotoLayout, cxOffset:Number=Number.NEGATIVE_INFINITY, cyOffset:Number=Number.NEGATIVE_INFINITY, nRotation:Number=Number.NEGATIVE_INFINITY): void {
			_nScale = plo._nScale;
			_rcPrintArea = plo._rcPrintArea.clone();
			_ptImageDim = plo._ptImageDim.clone();

			_cxOffset = (cxOffset != Number.NEGATIVE_INFINITY) ? _cxOffset : plo._cxOffset;
			_cyOffset = (cyOffset != Number.NEGATIVE_INFINITY) ? _cyOffset : plo._cyOffset;
			_nRotation = (nRotation != Number.NEGATIVE_INFINITY) ? _nRotation : plo._nRotation;
		}

		// Creates an image aligned to print dimensions
		public function CreateImage(bmdPhoto:BitmapData): Canvas {
			var img:Image = new Image();
			while (img.numChildren) img.removeChildAt(0);

			var bm:Bitmap = new Bitmap(bmdPhoto);
			img.addChild(bm);

			var cnv:Canvas = new Canvas();
			cnv.clipContent = true;
			cnv.horizontalScrollPolicy = ScrollPolicy.OFF;
			cnv.verticalScrollPolicy = ScrollPolicy.OFF;
			cnv.addChild(img);
			cnv.width = _rcPrintArea.width;
			cnv.height = _rcPrintArea.height;
			
			img.width = bmdPhoto.width;
			img.height = bmdPhoto.height;
			img.x = -_rcPrintArea.x;
			img.y = -_rcPrintArea.y;
			
			// Scale/rotate/position the image within the printed page
			cnv.scaleX = _nScale;
			cnv.scaleY = _nScale;
			cnv.x = _cxOffset;
			cnv.y = _cyOffset;

			if (_nRotation == 90)
				cnv.x += _rcPrintArea.height * _nScale;
				cnv.rotation = _nRotation;
			return cnv;
		}
	}
}