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
package util {
	import flash.display.BitmapData;
	import flash.display.IBitmapDrawable;
	import flash.display.StageQuality;
	import flash.geom.Matrix;
	
	import mx.core.Application;
	
	public class DrawUtil {
		private static const IDEAL_RESIZE_PERCENT:Number = .5;

		// Create a high quality downsampled bitmap using the technique outlined at:
		// http://jacwright.com/blog/221/high-quality-high-performance-thumbnails-in-flash/
		//
		// In short, Flash will do a nicely filtered downsample if the image size is being
		// reduced by half or less. Exploit this by iteratively downsizing the image by
		// half until the desired size is reached. The first downsampling sizes the image
		// to a power of 2 multiple of the target size.
		public static function GetResizedBitmapData(bmdr:IBitmapDrawable, cx:uint, cy:uint,
				fTransparent:Boolean=true, coBackground:uint=0x00000000,
				fConstrainProportions:Boolean=false, fHiQuality:Boolean=true): BitmapData {
			var cxSource:int = Object(bmdr).width;
			var cySource:int = Object(bmdr).height;
			var nScaleX:Number = cx / cxSource;
			var nScaleY:Number = cy / cySource;

			if (fConstrainProportions) {
				if (nScaleX > nScaleY)
					nScaleX = nScaleY;
				else
					nScaleY = nScaleX;
			}

			var bmd:BitmapData = null;

			if ((nScaleX > 0.5 && nScaleY > 0.5) || !fHiQuality) {
				bmd = VBitmapData.Construct(Math.max(1, Math.round(cxSource * nScaleX)), Math.max(1, Math.round(cySource * nScaleY)), fTransparent, coBackground);
				bmd.draw(bmdr, new Matrix(nScaleX, 0, 0, nScaleY), null, null, null, fHiQuality);
				return bmd;
			}
			
			// Scale it by the IDEAL for best quality
			var nNextScaleX:Number = nScaleX;
			var nNextScaleY:Number = nScaleY;
			while (nNextScaleX < 1)
				nNextScaleX /= IDEAL_RESIZE_PERCENT;
			while (nNextScaleY < 1)
				nNextScaleY /= IDEAL_RESIZE_PERCENT;

			if (nScaleX < IDEAL_RESIZE_PERCENT)
				nNextScaleX *= IDEAL_RESIZE_PERCENT;
			if (nScaleY < IDEAL_RESIZE_PERCENT)
				nNextScaleY *= IDEAL_RESIZE_PERCENT;

			bmd = VBitmapData.Construct(cxSource * nNextScaleX, cySource * nNextScaleY, fTransparent, coBackground);
			bmd.draw(bmdr, new Matrix(nNextScaleX, 0, 0, nNextScaleY), null, null, null, true);

			nNextScaleX *= IDEAL_RESIZE_PERCENT;
			nNextScaleY *= IDEAL_RESIZE_PERCENT;

			while (nNextScaleX >= nScaleX || nNextScaleY >= nScaleY) {
				var nActualScaleX:Number = nNextScaleX >= nScaleX ? IDEAL_RESIZE_PERCENT : 1;
				var nActualScaleY:Number = nNextScaleY >= nScaleY ? IDEAL_RESIZE_PERCENT : 1;
				var bmdT:BitmapData = VBitmapData.Construct(Math.round(bmd.width * nActualScaleX), Math.round(bmd.height * nActualScaleY), fTransparent, coBackground);
				bmdT.draw(bmd, new Matrix(nActualScaleX, 0, 0, nActualScaleY), null, null, null, true);
				bmd.dispose();
				nNextScaleX *= IDEAL_RESIZE_PERCENT;
				nNextScaleY *= IDEAL_RESIZE_PERCENT;
				bmd = bmdT;
			}

			return bmd;
		}		
	}
}
