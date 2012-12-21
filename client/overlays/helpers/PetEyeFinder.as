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
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import util.VBitmapData;
	
	public class PetEyeFinder
	{
		// Returns an object with the following members:
		//   mask: The bitmap mask (in the alpha channel)
		//   offset: Offset of the mask from the original bitmap
		//   clr: Color of the clicked point
		public static function FindPetEye(bmdIn:BitmapData, ptClick:Point): Object {
			var pef:PetEyeFinder = new PetEyeFinder(bmdIn, ptClick);
			return pef.Match();
		}
		
		private var _abmdDispose:Array = [];
		
		private static const knMaxOrigWidth:Number = 300;
		private static const knMaxOrigHeight:Number = 300;
		private static const knMaxOrigPixels:Number = knMaxOrigWidth * knMaxOrigHeight;

		private static const knExactMatch:Number = 25;
		private static const knCloseMatch:Number = 45;
		
		private var _ptClick:Point;
		private var _ptMaskOffset:Point;
		private var _bmdIn:BitmapData;
		private var _bmdInLum:BitmapData = null;

		private var _clr:Number = NaN;
		private var _clrLum:Number = NaN;

		private static var _spCircle:Sprite = null;

		public function PetEyeFinder(bmdIn:BitmapData, ptClick:Point): void {
			_ptClick = new Point(Math.round(ptClick.x), Math.round(ptClick.y));
			_ptMaskOffset = new Point(0,0);
			_bmdIn = bmdIn;
		}
		
		protected function Match(): Object {
			var obRet:Object = null;
			ReduceWorkingArea();
			
			// Which params do we use? Try different params.
			var abmdTest:Array = [];
			
			var nMatchA:Number = 70;
			var nMatchBL:Number = 70;
			var bmdMask:BitmapData = null;
			var nBestMatch:Number = 0.87;

			for (nMatchBL = 70; nMatchBL >= 15; nMatchBL -= 5) {
				var bmdTemp:BitmapData = DoMatch(nMatchA, nMatchBL, nMatchBL);
				var nVal:Number = RateMatch(bmdTemp, nMatchBL);
				if (nVal > nBestMatch) {
					nBestMatch = nVal;
					if (bmdMask) bmdMask.dispose();
					bmdMask = bmdTemp;
				} else {
					bmdTemp.dispose();
				}
			} 

			Cleanup();
			
			if (bmdMask) {
				// Soften edges, crop
				var fltBlur:BlurFilter = new BlurFilter(3, 3, 4);
				bmdMask.applyFilter(bmdMask, bmdMask.rect, new Point(0,0), fltBlur);
				// Now expand our reach
				bmdMask.colorTransform(bmdMask.rect, new ColorTransform(2.2, 2.2, 2.2, 1, 0, 0, 0, 0));

				var rcCrop:Rectangle = bmdMask.getColorBoundsRect(0xff0000, 0, false);
				_abmdDispose.push(bmdMask);

				var bmdReturn:BitmapData = new VBitmapData(rcCrop.width, rcCrop.height, true, 0, "pet eye mask");
				bmdReturn.copyChannel(bmdMask, rcCrop, new Point(0,0), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);

				var ptOffset:Point = _ptMaskOffset.clone();
				ptOffset.offset(rcCrop.x, rcCrop.y);

				obRet = {mask:bmdReturn, offset:ptOffset, clr:matchColor};
			}
			return obRet;
		}
		
		private function GetCircleSprite(): Sprite {
			if (_spCircle == null) {
				_spCircle = new Sprite();
	 			var mat:Matrix = new Matrix();
	 			mat.createGradientBox(100, 100, 0, 0, 0);
	 			_spCircle.graphics.beginGradientFill(GradientType.RADIAL, [0xffffff,0x000000], [1,1], [0,255], mat, SpreadMethod.PAD);
	 			_spCircle.graphics.drawRect(0,0,100,100);
			}
			return _spCircle;
		}
		
		// 1 is a perfect circle (or ellipse)
		// 0 is not circular at all
		private function Cicurlarity(bmdMask:BitmapData, rcArea:Rectangle): Number {
			var nCircularity:Number = 0;
			var mat:Matrix;
			
			if (rcArea.width < 1 || rcArea.height < 1) return 0;
			
			var bmdM:BitmapData;
			bmdM = new BitmapData(rcArea.width, rcArea.height, false);
			bmdM.copyPixels(bmdMask, rcArea, new Point(0,0));
			
			// Draw the circle
			var bmdCirc:BitmapData = new BitmapData(rcArea.width, rcArea.height, false);
 			mat = new Matrix();
 			mat.scale(2 * bmdCirc.width / 100, 2 * bmdCirc.height/100);
 			mat.translate(-bmdCirc.width/2, -bmdCirc.height/2);
 			bmdCirc.draw(GetCircleSprite(), mat, null, null, null, true);
 			
 			// Calculate Holes = Circle - 128 - m
 			var bmdHoles:BitmapData = bmdCirc.clone();
 			bmdHoles.colorTransform(bmdHoles.rect, new ColorTransform(1,1,1,1,-128,-128,-128));
 			bmdHoles.draw(bmdM, null, null, BlendMode.SUBTRACT);
 			
 			// Calculate Overflow = M-128 - circ
 			bmdM.colorTransform(bmdHoles.rect, new ColorTransform(1,1,1,1,-128,-128,-128));
			bmdM.draw(bmdCirc, null, null, BlendMode.SUBTRACT, null, true);
			// Overflow counts as double (to account for highlights)
			bmdM.colorTransform(bmdM.rect, new ColorTransform(2,0,0,1)); 			
 			
 			// Blend holes and overflow
 			bmdM.draw(bmdHoles, null, null, BlendMode.ADD);
			
 			// Multiply by 2 so our range is 0 to 255
			bmdM.colorTransform(bmdHoles.rect, new ColorTransform(2,0,0,1)); 			
			
 			// Shrink
 			// UNDONE: Do we need this?
 			var bmdMSmall:BitmapData = bmdM;
 			
 			// Average resulting colors
 			var nClrAvg:Number = 0;
 			for (var x:Number = 0; x < bmdMSmall.width; x++) {
 				for (var y:Number = 0; y < bmdMSmall.height; y++) {
 					nClrAvg += (bmdMSmall.getPixel(x,y) >> 16) & 0xff; // Use only red channel 
 				}
 			}
 			nClrAvg /= (bmdMSmall.width * bmdMSmall.height);
 			// 255 is not circular
 			// 0 is perfect
 			nCircularity = (255 - nClrAvg) / 255;
 			
 			bmdCirc.dispose();
			bmdM.dispose();
			bmdHoles.dispose();
			return nCircularity;
		}
		
		private function RateMatch(bmd:BitmapData, nThresh:Number): Number {
			var nVal:Number = 0;
			
			var rc:Rectangle = bmd.getColorBoundsRect(0xff0000, 0, false);

			// Overflow
			var fOverflow:Boolean = false;
			if (rc.x == 0 || rc.y == 0 || rc.bottom == bmd.rect.bottom || rc.right == bmd.rect.right) {
				fOverflow = true;
			} else {
				fOverflow = false;
			}
			
			// Shortcut - don't calculate density if have an overflow
			if (fOverflow) return 0;
			
			// Aspect ratio
			var nAspectRatio:Number = rc.width / rc.height;
			if (nAspectRatio > 1) nAspectRatio = 1/nAspectRatio;
			
			var nCirc:Number = Cicurlarity(bmd, rc);
			// Ignore one pixel shapes
			if (rc.width < 2 && rc.height < 2) {
				nVal = 0;
			} else {
				nVal = nCirc;
				if (nAspectRatio < 0.6) {
					nVal = 0;
				}
			}
			
			// Give slight preferences to a threshold of 50
			if (nVal > 0) {
				var nSizeWeight:Number = Math.abs(nThresh - 50);
				// Distance from 50, from 0 to 35
				nSizeWeight = (nSizeWeight / 35) / 100; // Range is now 0 to 1/100 (or 0.01)
				nVal -= nSizeWeight;
			}
			
			var obHSV:Object = RGBColor.Uint2HSV(matchColor);
			// Only fix lighter/more saturated/non-red colors
			if (obHSV.s > 10 && obHSV.h > 220) nVal = 0;
			if (obHSV.v < 40) nVal = 0;
			if (obHSV.v < (65 - obHSV.s)) nVal = 0;
			
			// trace("match: " + nVal + ", " + nThresh + ", " + nAspectRatio + ", " + nCirc + ", " + rc + ", " + obHSV.h + ", " + obHSV.s + ", " + obHSV.v);
			return nVal;
		}
		
		
		private function get matchColor(): uint {
			if (isNaN(_clr)) {
				_clr = GetColor(_bmdIn, _ptClick);
			}
			return _clr;
		}
		
		private function ColorToStr(clr:uint): String {
			var str:String = "";
			str += ((clr >> 16) & 0xff) + ", "
			str += ((clr >> 8) & 0xff) + ", "
			str += ((clr >> 0) & 0xff) + ", "
			return str;
		}
		
		private function get matchColorLum(): uint {
			if (isNaN(_clrLum)) {
				_clrLum = GetColor(bmdInLum, _ptClick);
				
				var nA:Number = (_clrLum >> 16) & 0xff;
				var nB:Number = (_clrLum >> 8) & 0xff;
				var nDev:Number = Math.abs(102 * (104-nB) - (85-nA) * 151) / 182.2223916;
			}
			return _clrLum;
		}
		
		private function get bmdInLum(): BitmapData {
			if (!_bmdInLum) {
				var matLumRotate:Array =
					[0.5,-0.25,-0.25,0, 127.5,
				 	 0, 1, -1, 0, 127.5,
				 	 0.308600035, 0.60940007, 0.081999895, 0, 0,
				 	 0,0,0,1,0];
				var fltLumRotate:ColorMatrixFilter = new ColorMatrixFilter(matLumRotate);
				_bmdInLum = _bmdIn.clone();
				_abmdDispose.push(_bmdInLum);
				_bmdInLum.applyFilter(_bmdIn, _bmdInLum.rect, new Point(0,0), fltLumRotate);
			}
			return _bmdInLum;
		}
		
		protected var _bmdColorDiff:BitmapData = null;
		
		protected function GetColorDiff(): BitmapData {
			if (_bmdColorDiff == null) {
				_bmdColorDiff = new BitmapData(bmdInLum.width, bmdInLum.height, true, 0xff000000 | matchColorLum);
				_bmdColorDiff.draw(bmdInLum, null, null, BlendMode.DIFFERENCE);
				_abmdDispose.push(_bmdColorDiff);
			}
			return _bmdColorDiff;
		}
		
		protected function DoMatch(nRMatch:Number, nGMatch:Number, nBMatch:Number): BitmapData {

			// First, get the difference.
			// Either subtract (To include all brighter colors) or take the difference (brigher colors must match the threshold)
			
			// We could modify this to eventually allow different weights for brighter colors
			// or even by color channel (e.g. LAB color, brighter for A,B is important but not as much for L)
			
			var bmdColorDiff:BitmapData = GetColorDiff();

			// bmdFill is black and gray.
			var bmdFill:BitmapData = bmdColorDiff.clone();
			bmdFill.colorTransform(bmdFill.rect, new ColorTransform(1, 1, 1, 1, -nRMatch, -nGMatch, -nBMatch));

			bmdFill.floodFill(_ptClick.x, _ptClick.y, 0xffFF0000);
			
			var nMult:Number = 255/nRMatch;
			bmdFill.colorTransform(bmdFill.rect, new ColorTransform(nMult, 0, 0, 0, 255 * (1-nMult), 0, 0, 255));
			
			return bmdFill;
		}
		
		protected function Cleanup(): void {
			for each (var bmd:BitmapData in _abmdDispose) {
				bmd.dispose();
			}
			_abmdDispose.length = 0;
		}
		
		protected function ReduceWorkingArea(): void {
			// If our original is very large, work with a smaller sub-region
			if ((_bmdIn.width * _bmdIn.height) > knMaxOrigPixels) {
				// Work with a subset of the original image - try to keep it square.
				var rcTarget:Rectangle = new Rectangle(_ptClick.x, _ptClick.y, knMaxOrigWidth, knMaxOrigHeight);
				rcTarget.x -= knMaxOrigWidth/2;
				rcTarget.y -= knMaxOrigHeight/2;
				// This is our target region in _bmdIn coordinates. Crop at the _bmdIn rect
				rcTarget = rcTarget.intersection(_bmdIn.rect);
				
				var bmdTemp:BitmapData = new BitmapData(rcTarget.width, rcTarget.height, true, 0xffffffff);
				_abmdDispose.push(bmdTemp);
				
				bmdTemp.copyPixels(_bmdIn, rcTarget, new Point(0,0));
				
				_ptClick.offset(-rcTarget.x, -rcTarget.y);
				_ptMaskOffset.offset(rcTarget.x, rcTarget.y);
				
				_bmdIn = bmdTemp;
			}
		}

		private static function GetColor(bmdRegion:BitmapData, pt:Point, nBlur:Number=2): uint {
			if (nBlur <= 1) return bmdRegion.getPixel(pt.x, pt.y);
			
			// Calculate the average color clicked.
			var rc:Rectangle = new Rectangle(pt.x - 3, pt.y - 3, 7, 7);
			rc = rc.intersection(bmdRegion.rect);
			
			// Now we have a region for getting our color.
			if (rc.width < 1 || rc.height == 1) return bmdRegion.getPixel(pt.x, pt.y);
			
			var bmdColor:BitmapData = new BitmapData(rc.width, rc.height, true, 0xffffffff);
			bmdColor.copyPixels(bmdRegion, rc, new Point(0,0));

			var ptSample:Point = pt.clone();
			ptSample.offset(-rc.x, -rc.y);
			
			var fltBlur:BlurFilter = new BlurFilter(nBlur, nBlur, 3);
			bmdColor.applyFilter(bmdColor, bmdColor.rect, new Point(0,0), fltBlur);
			
			var clr:uint = bmdColor.getPixel(ptSample.x, ptSample.y);
			bmdColor.dispose();
			return clr;
		}
		
	}
}