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
package imagine.imageOperations {
	import com.gskinner.geom.ColorMatrix;
	
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	import imagine.ImageDocument;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class VibranceImageOperation extends BlendImageOperation {
		private static const kptOrigin:Point = new Point(0,0);

		public function VibranceImageOperation () {
		}
	
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			return true; // No properties
		}
		
		override protected function SerializeSelf(): XML {
			return <Vibrance/> // No properties.
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return IncreaseVibrance(bmdSrc);
		}
		
		/** Vibrance algorithm
		 *
		 * Divide the image into four parts:
		 * 1. Everyting but blue
		 * 1.A. Green
		 * 1.B. Purple
		 * 2. Blue
		 *
		 * Part 1 (including 1.A and 1.B): saturate 30%, darken only
		 * Part 1.A: Remove some red
		 * Part 1.B: Remove some red and green
		 * Part 2: Remove some red and green
 		 */
		
		public static function IncreaseVibrance(bmdIn:BitmapData):BitmapData {
			// First, get our green and magenta weights
			var bmdRGBSat:BitmapData = CalcColorWeights(bmdIn);
			
			// Part 1: Increase saturation by 30% for not-blue areas
			
			// First, create our not blue alpha mask
			var bmdANotBlue:BitmapData = VBitmapData.Construct(bmdIn.width, bmdIn.height, true, 0xffffffff);
			bmdANotBlue.draw(bmdRGBSat, null, null, BlendMode.SUBTRACT);
			bmdANotBlue.copyChannel(bmdANotBlue, bmdANotBlue.rect, kptOrigin, BitmapDataChannel.BLUE, BitmapDataChannel.ALPHA);
			
			var bmdOut:BitmapData = bmdIn.clone();
			var bmdSaturated:BitmapData = VBitmapData.Construct(bmdIn.width, bmdIn.height, true);
			var cm:ColorMatrix = new ColorMatrix();
			cm.adjustSaturation(30);
			bmdSaturated.applyFilter(bmdIn, bmdIn.rect, kptOrigin, new ColorMatrixFilter(cm));
			
			bmdOut.copyPixels(bmdSaturated, bmdSaturated.rect, kptOrigin, bmdANotBlue, kptOrigin);
			bmdOut.draw(bmdIn,null, null, BlendMode.DARKEN);
			bmdANotBlue.dispose();
			bmdSaturated.dispose();
			
			// Part 1.A: Remove some red from green areas
			var bmdRedEnhance:BitmapData = VBitmapData.Construct(bmdIn.width, bmdIn.height, false, 0);
			bmdRedEnhance.copyChannel(bmdRGBSat, bmdRGBSat.rect, kptOrigin, BitmapDataChannel.GREEN, BitmapDataChannel.RED); // R = G sat
			bmdRedEnhance.colorTransform(bmdRedEnhance.rect, new ColorTransform(0.66));
			
			bmdOut.draw(bmdRedEnhance, null, null, BlendMode.ADD);
			bmdRedEnhance.dispose();
			
			// Part 2: Remove red and green from blue areas
			var bmdABlue:BitmapData = VBitmapData.Construct(bmdIn.width, bmdIn.height, false, 0);
			bmdABlue.copyChannel(bmdRGBSat, bmdRGBSat.rect, kptOrigin, BitmapDataChannel.BLUE, BitmapDataChannel.RED);
			bmdABlue.copyChannel(bmdRGBSat, bmdRGBSat.rect, kptOrigin, BitmapDataChannel.BLUE, BitmapDataChannel.GREEN);
			bmdABlue.colorTransform(bmdABlue.rect, new ColorTransform(0.69,0.69));
			
			bmdOut.draw(bmdABlue, null, null, BlendMode.SUBTRACT);
			bmdABlue.dispose();
			
			// Part 1.B: Subtract some green and red from magenta regions
			var bmdAMagenta:BitmapData = CalcYCMColorWeights(bmdIn);
			bmdAMagenta.copyChannel(bmdAMagenta, bmdAMagenta.rect, kptOrigin, BitmapDataChannel.BLUE, BitmapDataChannel.GREEN);
			bmdAMagenta.copyChannel(bmdAMagenta, bmdAMagenta.rect, kptOrigin, BitmapDataChannel.BLUE, BitmapDataChannel.RED);
			bmdAMagenta.colorTransform(bmdAMagenta.rect, new ColorTransform(0.19,0.95));
			bmdOut.draw(bmdAMagenta, null, null, BlendMode.SUBTRACT);
			bmdAMagenta.dispose();
			
			return bmdOut;
		}

		private static function CalcYCMColorWeights(bmdIn:BitmapData): BitmapData {
			var fltRotate60:ColorMatrixFilter = new ColorMatrixFilter(
				[.5,.5,0, 0, 0,
				 0,.5,.5, 0, 0,
				 .5,0,.5, 0, 0,
				 0,0,0, 1, 0]);
			
			var bmdRotate60:BitmapData = VBitmapData.Construct(bmdIn.width, bmdIn.height, true);
			bmdRotate60.applyFilter(bmdIn, bmdIn.rect, kptOrigin, fltRotate60);
			var bmdYCMSat:BitmapData = CalcColorWeights(bmdRotate60);
			bmdRotate60.dispose();
			bmdYCMSat.colorTransform(bmdYCMSat.rect, new ColorTransform(2,2,2,2));
			return bmdYCMSat;
		}

		private static function CalcColorWeights(bmdIn:BitmapData): BitmapData {
			var bmdOut:BitmapData;
			
			var fltRotate:ColorMatrixFilter = new ColorMatrixFilter(
				[0,1,0, 0, 0,
				 0,0,1, 0, 0,
				 1,0,0, 0, 0,
				 0,0,0, 1, 0]);
			
			var bmdRotate1:BitmapData = VBitmapData.Construct(bmdIn.width, bmdIn.height, true);
			bmdRotate1.applyFilter(bmdIn, bmdIn.rect, kptOrigin, fltRotate);
			
			var bmdRotate2:BitmapData = VBitmapData.Construct(bmdIn.width, bmdIn.height, true);
			bmdRotate2.applyFilter(bmdRotate1, bmdIn.rect, kptOrigin, fltRotate);
			
			// Now we have our rotate dfilters
			var bmdMaxOpposite:BitmapData = bmdRotate2.clone();
			bmdMaxOpposite.draw(bmdRotate1, null, null, BlendMode.LIGHTEN);
			
			bmdOut = VBitmapData.Construct(bmdIn.width, bmdIn.height, true);
			bmdOut.draw(bmdIn);
			bmdOut.draw(bmdMaxOpposite, null, null, BlendMode.SUBTRACT);
			return bmdOut;
		}
	}
}
