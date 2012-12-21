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
package controls
{
	import mx.containers.Canvas;
	import flash.geom.Point;
	import mx.controls.Image;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import mx.controls.Label;
	import util.PrintLayout;
	import util.PrintPhotoLayout;
	import mx.core.ScrollPolicy;

	public class PrintPreviewBase extends Image
	{
		private var _obPrintSize:Object = {ptDesired:new Point(0, 0), fFullPage:true};
		private var _obPrintMetrics:Object = {fCalibrated:false, ptPrintSize:new Point(72*8, 72*10), ptPageSize:new Point(72*8.5, 72*11)}
		private var _fCrop:Boolean = true;
		private var _fOutOfBounds:Boolean = false;
		private var _bmdPhoto:BitmapData = null;
		[Bindable] public var OutOfBoundsImageAlpha:Number = 0.5;
		[Bindable] public var actualWidth:Number = 100;
		[Bindable] public var actualHeight:Number = 100;

		public static const knNoChange:Number = 0;
		public static const knSmallChange:Number = 1;
		public static const knMediumChange:Number = 2;
		public static const knOutOfBoundsChange:Number = 3;
		
		[Inspectable] [Bindable]
		public function set PrintSize(ob:Object): void {
			if (ob == null) throw new Error("Can not set print size to null. Use full page instead");
			_obPrintSize = ob;
			Relayout();
		}
		
		public function get PrintSize(): Object {
			return _obPrintSize;
		}

		[Inspectable] [Bindable]
		public function set PrintMetrics(ob:Object): void {
			if (ob == null) throw new Error("Can not set print metrics to null. Use default metrics instead");
			_obPrintMetrics = ob;
			Relayout();
		}
		
		public function get PrintMetrics(): Object {
			return _obPrintMetrics;
		}

		[Inspectable] [Bindable]
		public function set Crop(fCrop:Boolean): void {
			_fCrop = fCrop;
			Relayout();
		}
		
		public function get Crop(): Boolean {
			return _fCrop;
		}

		[Bindable]
		public function set OutOfBounds(fOutOfBounds:Boolean): void {
			_fOutOfBounds = fOutOfBounds;
		}
		
		public function get OutOfBounds(): Boolean {
			return _fOutOfBounds;
		}
		
		[Bindable]
		public function set Photo(bmdPhoto:BitmapData): void {
			_bmdPhoto = bmdPhoto;
			Relayout();
		}

		public function get Photo(): BitmapData {
			return _bmdPhoto;
		}

		// Returns a rough "percent" difference. 0 is equal. 10 is 10% different ,etc.
		// 10% corresponds to a "small" difference
		// >10% is a medium difference
		// Margins matter, but not as much as print size. Going from no margin to margin matters (> 10%)
		private function ComparePrintMetrics(obPM1:Object, obPM2:Object): Number {
			var ptPage1:Point = obPM1.ptPageSize;
			var ptPage2:Point = obPM2.ptPageSize;
			var ptPrint1:Point = obPM1.ptPrintSize;
			var ptPrint2:Point = obPM2.ptPrintSize;
			var ptMargins1:Point = new Point(Math.min(ptPage1.x - ptPrint1.x, 0), Math.min(ptPage1.y - ptPrint1.y, 0));
			var ptMargins2:Point = new Point(Math.min(ptPage2.x - ptPrint2.x, 0), Math.min(ptPage2.y - ptPrint2.y, 0));
			
			var nPctDiff:Number = 0;
			if (ptPage1.equals(ptPage2) && ptPrint1.equals(ptPrint2)) {
				nPctDiff = 0;
			} else {
				// Compare margins
				
				// If one or the other is zero, changes matter more
				if (ptMargins1.x * ptMargins2.x == 0) {
					nPctDiff += Math.abs(ptMargins1.x - ptMargins2.x);
				} else {
					nPctDiff += 10 * Math.abs(ptMargins1.x - ptMargins2.x) / Math.max(ptMargins1.x, ptMargins2.x, 10);
				}
				if (ptMargins1.y * ptMargins2.y == 0) {
					nPctDiff += Math.abs(ptMargins1.y - ptMargins2.y);
				} else {
					nPctDiff += 10 * Math.abs(ptMargins1.y - ptMargins2.y) / Math.max(ptMargins1.y, ptMargins2.y, 10);
				}
				
				// Compare print sizes
				if (ptPrint1.x * ptPrint2.x == 0) {
					nPctDiff += Math.abs(ptPrint1.x - ptPrint2.x);
				} else {
					nPctDiff += 100 * Math.abs(ptPrint1.x - ptPrint2.x) / Math.max(ptPrint1.x, ptPrint2.x);
				}
				if (ptPrint1.y * ptPrint2.y == 0) {
					nPctDiff += Math.abs(ptPrint1.y - ptPrint2.y);
				} else {
					nPctDiff += 100 * Math.abs(ptPrint1.y - ptPrint2.y) / Math.max(ptPrint1.y, ptPrint2.y);
				}
			}
			return nPctDiff;
		}

		// Updates print metrics. Returns the severity of the update (i.e. no change, small change, etc)
		// No change: nothing changed
		// Small change: 10% difference. Same number of images per page
		// Medium change: >10% diff. Still fits at least one image. # of images per page changed
		// Out of bounds change: Image doesn't fit on the page.
		public function UpdatePrintMetrics(obPrintMetrics:Object): Number {
			if (obPrintMetrics == null) throw new Error("Can not set print metrics to null. Use default metrics instead");
			var prloPrev:PrintLayout = new PrintLayout(_obPrintMetrics, _obPrintSize, _fCrop, _bmdPhoto);
			var prloNew:PrintLayout = new PrintLayout(obPrintMetrics, _obPrintSize, _fCrop, _bmdPhoto);
			
			var nRet:Number = knNoChange;
			
			var nPctDiff:Number = ComparePrintMetrics(_obPrintMetrics, obPrintMetrics);
			
			if (prloNew.outOfBounds) {
				nRet = knOutOfBoundsChange;
			} else if (prloPrev.outOfBounds) {
				nRet = knMediumChange; // Old layout was out of bounds
			} else if (prloNew.firstPageItems.length != prloPrev.firstPageItems.length) {
				nRet = knMediumChange;
			} else if (nPctDiff > 10) {
				nRet = knMediumChange;
			} else if (nPctDiff > 0) {
				nRet = knSmallChange;
			}

			PrintMetrics = obPrintMetrics;
			return nRet;
		}
		
		public function Relayout(): void {
			// Make the image fit.
			while (numChildren) removeChildAt(0);
			var imgRotated:Image = new Image();
			while (imgRotated.numChildren) imgRotated.removeChildAt(0);
			OutOfBounds = false;
			var nWidth:Number = _obPrintMetrics.ptPageSize.x;
			var nHeight:Number = _obPrintMetrics.ptPageSize.y;
			if (!_bmdPhoto) {
				// Emtpy image. Clear everything.
			} else {
				var prlo:PrintLayout = new PrintLayout(_obPrintMetrics, _obPrintSize, _fCrop, _bmdPhoto);
				OutOfBounds = prlo.outOfBounds;
				if (OutOfBounds) {
					if ((nWidth > nHeight) != (_bmdPhoto.width > _bmdPhoto.height)) {
						var nTemp:Number = nWidth;
						nWidth = nHeight;
						nHeight = nTemp;
					}
				}

				// Fill with white
				var spr:Sprite = new Sprite();
				spr.graphics.beginFill(0xffffff);
				spr.graphics.drawRect(0,0, nWidth, nHeight);
				imgRotated.addChildAt(spr, 0);

				if (OutOfBounds) {
					// Render out of bounds image. Stretch the image to the desired size.
					// we already rotated our dimensions to match the image orientation
					// This means tha we don't have to worry about rotation.
					var cnvClipImage:Canvas = new Canvas();
					cnvClipImage.clipContent = true;
					cnvClipImage.alpha = OutOfBoundsImageAlpha;
					cnvClipImage.width = nWidth;
					cnvClipImage.height = nHeight;
					cnvClipImage.horizontalScrollPolicy = ScrollPolicy.OFF;
					cnvClipImage.verticalScrollPolicy = ScrollPolicy.OFF;
					imgRotated.addChild(cnvClipImage);
					
					var img:Image = new Image();
					img.maintainAspectRatio = true;
					while (img.numChildren) img.removeChildAt(0);
					cnvClipImage.addChild(img);
					var bm:Bitmap = new Bitmap(_bmdPhoto);
					img.addChild(bm);
					img.width = bm.width = _bmdPhoto.width;
					img.height = bm.height = _bmdPhoto.width;
					// Scale and position img to match target print size.
					var fFullPage:Boolean = _obPrintSize.fFullPage;
					var ptDesiredSize:Point;
					if (fFullPage) {
						ptDesiredSize = new Point(nWidth, nHeight);
					} else {
						ptDesiredSize = _obPrintSize.ptDesired.clone();
						if ((ptDesiredSize.x > ptDesiredSize.y) != (nWidth > nHeight)) {
							// Rotate to match image orientation
							ptDesiredSize = new Point(ptDesiredSize.y, ptDesiredSize.x);
						}
					}
					// Now we want our image min width to be ptDesiredSize.x and min height .y
					var nScale:Number = Math.max(ptDesiredSize.x / _bmdPhoto.width, ptDesiredSize.y / _bmdPhoto.height, 0.01);
					img.scaleContent = false;
					
					// Now center it
					img.x = (nWidth - nScale * _bmdPhoto.width) / 2;
					img.y = (nHeight - nScale * _bmdPhoto.height) / 2;

					img.scaleX = nScale;
					img.scaleY = nScale;
					bm.scaleX = 1;
					bm.scaleY = 1;
				} else {
					var aloFirstPageItems:Array = prlo.firstPageItems;
					if (aloFirstPageItems.length > 0)
						imgRotated.rotation = -(aloFirstPageItems[0] as PrintPhotoLayout).rotation;

					// We don't get margins, only page size and print size.
					// Estimate margins assuming top/bottom and left/right are equal.
					var cxLeftMargin:Number = (_obPrintMetrics.ptPageSize.x - _obPrintMetrics.ptPrintSize.x)/2;
					var cyTopMargin:Number = (_obPrintMetrics.ptPageSize.y - _obPrintMetrics.ptPrintSize.y)/2;

					for each (var plo:PrintPhotoLayout in aloFirstPageItems) {
						var cnv:Canvas = plo.CreateImage(_bmdPhoto);
						// Rotate to fit
						cnv.x += cxLeftMargin;
						cnv.y += cyTopMargin;
						imgRotated.addChild(cnv);
					}
				}
			}
			imgRotated.width = nWidth;
			imgRotated.height = nHeight;
			imgRotated.measuredWidth = nWidth;
			imgRotated.measuredHeight = nHeight;
			addChild(imgRotated);
			// Position and size based on the rotated child
			
			if (imgRotated.rotation == 90) {
				imgRotated.x = imgRotated.height;
				imgRotated.y = 0;
				nWidth = imgRotated.height;
				nHeight = imgRotated.width;
			} else if (imgRotated.rotation == -90) {
				imgRotated.x = 0;
				imgRotated.y = imgRotated.width;
				nWidth = imgRotated.height;
				nHeight = imgRotated.width;
			} else {
				imgRotated.x = 0;
				imgRotated.y = 0;
			}
			width = nWidth;
			height = nHeight;
			actualWidth = nWidth;
			actualHeight = nHeight;
		}
	}
}