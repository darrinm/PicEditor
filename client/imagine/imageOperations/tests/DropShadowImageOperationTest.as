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
package imagine.imageOperations.tests {
	import flexunit.framework.*;
	import imagine.objectOperations.*;
	import imagine.imageOperations.ImageOperation;
	import imagine.imageOperations.DropShadowImageOperation;
	import flash.geom.Rectangle;
	import mx.utils.ArrayUtil;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import mx.core.Application;
	import flash.geom.Point;
	import imagine.ImageDocument;
	import com.google.mockasin.*;
	import tests.MockImageDocument;

	public class DropShadowImageOperationTest extends TestCase {
		public override function setUp():void {
			reset();
		}
		
		public function testDropShadowImageOperation(): void {
			// create an ImageDocument, typical dimensions, solid color 0xff0000
			var imgd:MockImageDocument = new MockImageDocument();
			
			expect(imgd.InvalidateComposite)
				.noArgs();
			
			assertTrue(imgd.Init(1024, 768));
			
			// do a DropShadowImageOperation
			var op:DropShadowImageOperation = CreateDefaultDropShadowImageOperation();
			AddUndoTransaction("Drop Shadow", op, imgd);
			
			// test new bitmap dimensions
			var bmd:BitmapData = imgd.composite.clone();
//			Application.application.stage.addChild(new Bitmap(bmd));
			AssertDimsAndPixels(bmd, op, 1024, 768);
			
			// variations
			// - orginal image dimensions (1x1, 2800x2800, 2800x1, 1x2800)
			// - dropshadow parameters
			//   - shadowAlpha
			//   - shadowColor
			//   - backgroundColor
			//   - distance
			//   - inner
			//   - quality
			//   - strength
			//   - blurX
			//   - blurY
			// - dropshadow on top of a dropshadow
			// - undo
			// - redo
			// - serialize
			// - deserialize

			verify();
		}
		
		private static const s_aptTestSizes:Array = [
			new Point(1, 1),
			new Point(2800, 1),
			new Point(1, 2800),
			new Point(2800, 2800),
			new Point(2592, 1944)
		]
		
		private static const s_anTestBlurs:Array = [ 0, 8, 50, 100 ];
		
		public function testDropShadowImageOperationSizes(): void {
			// variations
			// - orginal image dimensions
			for each (var pt:Point in s_aptTestSizes) {
				// variations
				//   - blurX
				//   - blurY
				for each (var cxyBlur:Number in s_anTestBlurs) {
					// create an ImageDocument of the specified dimensions
					reset();

					var imgd:MockImageDocument = new MockImageDocument();
					
					expect(imgd.InvalidateComposite)
						.noArgs();
					
					assertTrue(imgd.Init(pt.x, pt.y));
					
					// do a DropShadowImageOperation
					var op:DropShadowImageOperation = CreateDefaultDropShadowImageOperation();
					op.blurX = op.blurY = cxyBlur;
					
					// We should add an assertNoException() function instead of this ugliness
					try {
						AddUndoTransaction("Drop Shadow", op, imgd);
					} catch (err:Error) {
						assertTrue("cx: " + pt.x + ", cy: " + pt.y + ", blurX/Y: " + cxyBlur, false);
					}
					
					// test new bitmap dimensions
					var bmd:BitmapData = imgd.composite.clone();
					AssertDimsAndPixels(bmd, op, pt.x, pt.y);
					bmd.dispose();

					verify();
				}
			}

			// - dropshadow parameters
			//   - shadowAlpha
			//   - shadowColor
			//   - backgroundColor
			//   - distance
			//   - inner
			//   - quality
			//   - strength
			//   - blurX
			//   - blurY
			// - dropshadow on top of a dropshadow
			// - undo
			// - redo
			// - serialize
			// - deserialize
		}
		
		private function CreateDefaultDropShadowImageOperation(): DropShadowImageOperation {
			return new DropShadowImageOperation(
					0.0,		// cxyDistance
					45,			// degAngle
					0x00ff00,	// coShadow
					0xff0000,	// coBackground
					0.5,		// nShadowAlpha
					8.0,		// cxBlur
					8.0,		// cyBlur
					1.0,		// nStrength
					3, 			// nQuality
					false);		// fInner
		}
		
		private static const s_acxyQualityFudge:Array = [ 0, 10, 6, 4, 2 ];
		
		private function AssertDimsAndPixels(bmd:BitmapData, op:DropShadowImageOperation, cxOrig:Number, cyOrig:Number): void {
			/* UNDONE: the formula by which the DropShadowFilter defines its new size is undetermined.
					   Further, the DropShadowImageOperation may shrink the image to keep the result
					   under the 2800x2800 limit
			var cxNew:Number = cxOrig + (op.quality * (op.blurX - 1));
			var cyNew:Number = cyOrig + (op.quality * (op.blurY - 1));
			assertEquals(cxNew, bmd.width);
			assertEquals(cyNew, bmd.height);
			
			// test pixels expected to be in/out of shadow
			var rcInterior:Rectangle = new Rectangle(9, 9, cxOrig, cyOrig);
			var rcBounds:Rectangle = new Rectangle(0, 0, bmd.width, bmd.height);
			assertEquals(0xffffff, bmd.getPixel(rcInterior.left, rcInterior.top)); // interior
			assertEquals(0xffffff, bmd.getPixel(rcInterior.right, rcInterior.bottom)); // interior
			assertEquals(0xffffff, bmd.getPixel(rcInterior.right, rcInterior.top)); // interior
			assertEquals(0xffffff, bmd.getPixel(rcInterior.left, rcInterior.bottom)); // interior
			
			assertEquals(0xff0000, bmd.getPixel(rcBounds.top, rcBounds.left)); // shadow background
			assertEquals(0xff0000, bmd.getPixel(rcBounds.right, rcBounds.top)); // shadow background
			assertEquals(0xff0000, bmd.getPixel(rcBounds.right, rcBounds.bottom)); // shadow background
			assertEquals(0xff0000, bmd.getPixel(rcBounds.left, rcBounds.bottom)); // shadow background
			*/
		}
		
		private function AddUndoTransaction(strName:String, op:ImageOperation, imgd:ImageDocument): void {
			imgd.BeginUndoTransaction(strName, false, !(op is ObjectOperation));
			op.Do(imgd);
			imgd.EndUndoTransaction();
		}
	}
}
