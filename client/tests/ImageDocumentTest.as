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
package tests {
	import com.google.mockasin.*;
	
	import errors.InvalidArgumentError;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.getQualifiedClassName;
	
	import flexunit.framework.*;
	
	import imagine.ImageDocument;
	import imagine.documentObjects.IDocumentObject;
	import imagine.documentObjects.Text;
	import imagine.imageOperations.*;
	import imagine.objectOperations.CreateObjectOperation;
	import imagine.objectOperations.ObjectOperation;
	
	import util.FontResource;
	import util.PicnikFont;
	import util.VBitmapData;
	
	public class ImageDocumentTest extends TestCase {
		
		public override function setUp(): void {
			reset();
		}
		
		public function testInitPass(): void {
			var imgd_array:Array = new Array(
				new MockImageDocument(), new MockImageDocument(),
				new MockImageDocument(), new MockImageDocument(),
				new MockImageDocument());

			for (var i:int=0; i<5; i++) {
				expect(imgd_array[i].InvalidateComposite)
					.noArgs();
			}
			
			var imgd:MockImageDocument;

			imgd = imgd_array[0];
			assertTrue(imgd.Init(999, 666));
			assertTrue(imgd.background.width == 999 && imgd.background.height == 666);
			assertTrue(imgd.composite.width == 999 && imgd.composite.height == 666);

			imgd = imgd_array[1];
			assertTrue(imgd.Init(1, 1));
			assertTrue(imgd.background.width == 1 && imgd.background.height == 1);
			assertTrue(imgd.composite.width == 1 && imgd.composite.height == 1);
			
			imgd = imgd_array[2];
			assertTrue(imgd.Init(2800, 2800));
			assertTrue(imgd.background.width == 2800 && imgd.background.height == 2800);
			assertTrue(imgd.composite.width == 2800 && imgd.composite.height == 2800);
			
			imgd = imgd_array[3];
			assertTrue(imgd.Init(4000, 4000));
			assertTrue(imgd.background.width == 4000 && imgd.background.height == 4000);
			assertTrue(imgd.composite.width == 4000 && imgd.composite.height == 4000);
			
			imgd = imgd_array[4];
			assertTrue(imgd.Init(8000, 2000));
			assertTrue(imgd.background.width == 8000 && imgd.background.height == 2000);
			assertTrue(imgd.composite.width == 8000 && imgd.composite.height == 2000);

			verify();
		}
		
		public function testInitFail(): void {
			var imgd:ImageDocument;
			imgd = new ImageDocument();
			try {
				assertFalse(imgd.Init(4097, 4096));
			} catch (err:InvalidArgumentError) {}
			assertTrue(imgd.background == null);
			assertTrue(imgd.composite == null);
			
			imgd = new ImageDocument();
			try {
				assertFalse(imgd.Init(0, 0));
			} catch (err:InvalidArgumentError) {}
			assertTrue(imgd.background == null);
			assertTrue(imgd.composite == null);
			
			imgd = new ImageDocument();
			try {
				assertFalse(imgd.Init(4096, 4097));
			} catch (err:InvalidArgumentError) {}
			assertTrue(imgd.background == null);
			assertTrue(imgd.composite == null);
			
			imgd = new ImageDocument();
			try {
				assertFalse(imgd.Init(-1, -1));
			} catch (err:InvalidArgumentError) {}
			assertTrue(imgd.background == null);
			assertTrue(imgd.composite == null);
		}
		
		public function testInitFromLocalFilePass(): void {
			var imgd:ImageDocument = new ImageDocument();
			var fnOnDone:Function = function (err:Number, strError:String): void {
				assertEquals("init failed (" + err + ", " + strError + ")", ImageDocument.errNone, err);
			}
			var fnOnTimeout:Function = function (): void {
				fail("timeout");
			}
			var fnWrapper:Function = addAsync(fnOnDone, 5000, null, fnOnTimeout);
			assertTrue(imgd.InitFromLocalFile(null, "test.pik", "0:test.base.jpg", null, fnWrapper));
		}

		public function testUndoRedo(): void {
			// Make sure the font this test uses is preloaded
			var fnWrapper:Function = addAsync(testUndoRedo_OnFontLoaded, 5000, null, function (): void {
				fail("timeout");
			});
			var fnt:PicnikFont = GetArialRoundedFont();
			fnt.AddReference(this, fnWrapper);
		}
		
		private function testUndoRedo_OnFontLoaded(fntr:FontResource): void {
			assertEquals(FontResource.knLoaded, fntr.state);
			
			// create doc
			var imgd:ImageDocument = new ImageDocument();
			var fnWrapper:Function = addAsync(testUndoRedo_OnInitFromLocalFileDone, 5000, imgd, function (): void {
				fail("timeout");
			});
			assertTrue(imgd.InitFromLocalFile(null, "test.pik", "0:test.base.jpg", null, fnWrapper));
		}

		private function testUndoRedo_OnInitFromLocalFileDone(err:Number, strError:String, imgd:ImageDocument): void {
			assertEquals("init failed (" + err + ", " + strError + ")", ImageDocument.errNone, err);
			
			// assert initial history state
			assertEquals(0, imgd.undoDepth);
			assertEquals(0, imgd.redoDepth);
			assertNull(imgd.topUndoTransaction);
			
			// assert ImageDocument (background, composite, document objects) state
			assertNotNull(imgd.background);
			assertNotNull(imgd.composite);
			assertEquals(0, imgd.numChildren);
			assertFalse(imgd.isDirty);

			// assert known values for the hurricane bitmap
			assertEquals(460854, imgd.background.getPixel(0, 0));
			assertEquals(50, imgd.background.getPixel(1023, 767));
			assertEquals(7304768, imgd.background.getPixel(1023, 0));
			assertEquals(197429, imgd.background.getPixel(0, 767));

			var obState:Object = {
				bmdInitialBackground: imgd.background.clone()
			}
			
			//
			// do an object operation (create a Text object)
			//
			
			var op:ImageOperation = new CreateObjectOperation("Text", {
				name: Util.GetUniqueId(), x: 500, y: 400, font: GetArialRoundedFont(), fontSize: 50, text: "Abcdef 123456"
			});
			imgd.BeginUndoTransaction("Create Text", false, false);
			op.Do(imgd);
			imgd.EndUndoTransaction();
			
			// remember Text object's initial state for assertion later
			var txt:imagine.documentObjects.Text = imagine.documentObjects.Text(imgd.getChildAt(0));
			obState.xText = txt.x;
			obState.yText = txt.y;
			obState.degText = txt.rotation;

			// assert history state
			assertEquals(1, imgd.undoDepth);
			assertEquals(0, imgd.redoDepth);
			assertNotNull(imgd.topUndoTransaction);
			
			// assert ImageDocument (background, composite, document objects) state
			assertEquals(0, BitmapData(obState.bmdInitialBackground).compare(imgd.background));
			var bmdComposite:BitmapData = imgd.composite.clone();
//			Application.application.stage.addChild(new Bitmap(bmdComposite.clone()));
			var obT:Object = BitmapData(obState.bmdInitialBackground).compare(bmdComposite);
			assertTrue(obT is BitmapData);
			bmdComposite.dispose();
			assertEquals(1, imgd.numChildren);
			assertTrue(imgd.isDirty);
			AssertTextIsPresent(imgd);
			
			//
			// undo create text
			//
			
			imgd.Undo();
			
			// assert history state
			assertEquals(0, imgd.undoDepth);
			assertEquals(1, imgd.redoDepth);

			// assert ImageDocument (background, composite, document objects) state
			assertEquals(0, BitmapData(obState.bmdInitialBackground).compare(imgd.background));
			bmdComposite = imgd.composite.clone();
			assertEquals(0, BitmapData(obState.bmdInitialBackground).compare(bmdComposite));
			bmdComposite.dispose();
			assertEquals(0, imgd.numChildren);
// UNDONE: dirty flag behavior isn't fully spec'ed. Update this test when it is.
//			assertFalse(imgd.isDirty);

			//
			// redo create text
			//
			
			imgd.Redo();
			
			// assert history state
			assertEquals(1, imgd.undoDepth);
			assertEquals(0, imgd.redoDepth);

			// assert ImageDocument (background, composite, document objects) state
			assertEquals(0, BitmapData(obState.bmdInitialBackground).compare(imgd.background));
			bmdComposite = imgd.composite.clone();
			assertTrue(BitmapData(obState.bmdInitialBackground).compare(bmdComposite) is BitmapData);
			bmdComposite.dispose();
			assertEquals(1, imgd.numChildren);
			assertTrue(imgd.isDirty);
			AssertTextIsPresent(imgd);
			
			// assert that Text object is back to its initial state
			txt = imagine.documentObjects.Text(imgd.getChildAt(0));
			assertEquals(obState.xText, txt.x);
			assertEquals(obState.yText, txt.y);
			assertEquals(obState.degText, txt.rotation);

			//
			// do an image operation (rotate)
			//
			
			AddUndoTransaction("Rotate 90 degrees clockwise", new RotateImageOperation(Util.RadFromDeg(90)), imgd);

			// assert history state
			assertEquals(2, imgd.undoDepth);
			assertEquals(0, imgd.redoDepth);

			// assert ImageDocument (background, composite, document objects) state
			assertEquals(-3, BitmapData(obState.bmdInitialBackground).compare(imgd.background));
			bmdComposite = imgd.composite.clone();
			assertTrue(BitmapData(imgd.background).compare(bmdComposite) is BitmapData);
			bmdComposite.dispose();
			assertEquals(1, imgd.numChildren);
			assertTrue(imgd.isDirty);
			AssertTextIsPresent(imgd, 90);
			
			// assert that Text object rotated
			txt = imagine.documentObjects.Text(imgd.getChildAt(0));
			assertTrue(obState.xText != txt.x); // UNDONE: assert expected new value
			assertTrue(obState.yText != txt.y); // UNDONE: assert expected new value
			assertEquals(90, txt.rotation);
			
			//
			// rotate again
			//
			
			AddUndoTransaction("Rotate 90 degrees clockwise", new RotateImageOperation(Util.RadFromDeg(90)), imgd);
			
			// assert history state
			assertEquals(3, imgd.undoDepth);
			assertEquals(0, imgd.redoDepth);

			// assert ImageDocument (background, composite, document objects) state
			assertTrue(BitmapData(obState.bmdInitialBackground).compare(imgd.background) is BitmapData);
			bmdComposite = imgd.composite.clone();
			assertTrue(BitmapData(imgd.background).compare(bmdComposite) is BitmapData);
			bmdComposite.dispose();
			assertEquals(1, imgd.numChildren);
			assertTrue(imgd.isDirty);
			AssertTextIsPresent(imgd, 180);
			
			// assert that Text object rotated
			txt = imagine.documentObjects.Text(imgd.getChildAt(0));
			assertTrue(obState.xText != txt.x); // UNDONE: assert expected new value
			assertTrue(obState.yText != txt.y); // UNDONE: assert expected new value
			assertEquals(180, txt.rotation);
			
			//
			// undo rotate
			//
			
			imgd.Undo();

			// assert that Text object unrotated
			txt = imagine.documentObjects.Text(imgd.getChildAt(0));
			assertTrue(obState.xText != txt.x); // UNDONE: assert expected new value
			assertTrue(obState.yText != txt.y); // UNDONE: assert expected new value
			assertEquals(90, txt.rotation);
			AssertTextIsPresent(imgd, 90);
	
			//
			// undo rotate
			//
			
			imgd.Undo();
			
			// assert history state
			assertEquals(1, imgd.undoDepth);
			assertEquals(2, imgd.redoDepth);

			// assert ImageDocument (background, composite, document objects) state
//			Application.application.stage.addChild(new Bitmap(imgd.background.clone()));
			assertEquals(0, BitmapData(obState.bmdInitialBackground).compare(imgd.background));
			
			bmdComposite = imgd.composite.clone();
			assertTrue(BitmapData(obState.bmdInitialBackground).compare(bmdComposite) is BitmapData);
			bmdComposite.dispose();
			assertEquals(1, imgd.numChildren);
			assertTrue(imgd.isDirty);
			AssertTextIsPresent(imgd);

			// assert that Text object is back to its original (non-rotated) state
			txt = imagine.documentObjects.Text(imgd.getChildAt(0));
			assertEquals(obState.xText, txt.x);
			assertEquals(obState.yText, txt.y);
			assertEquals(obState.degText, txt.rotation);

			//
			// redo rotate
			//
			
			imgd.Redo();

			// assert history state
			assertEquals(2, imgd.undoDepth);
			assertEquals(1, imgd.redoDepth);

			// assert ImageDocument (background, composite, document objects) state
			assertEquals(-3, BitmapData(obState.bmdInitialBackground).compare(imgd.background));
			bmdComposite = imgd.composite.clone();
			assertTrue(BitmapData(imgd.background).compare(bmdComposite) is BitmapData);
			bmdComposite.dispose();
			assertEquals(1, imgd.numChildren);
			assertTrue(imgd.isDirty);
			AssertTextIsPresent(imgd, 90);

			// assert that Text object is rotated again
			txt = imagine.documentObjects.Text(imgd.getChildAt(0));
			assertTrue(obState.xText != txt.x); // UNDONE: assert expected new value
			assertTrue(obState.yText != txt.y); // UNDONE: assert expected new value
			assertEquals(90, txt.rotation);
			
			//
			// undo rotate
			//
			
			imgd.Undo();
			
			// assert history state
			assertEquals(1, imgd.undoDepth);
			assertEquals(2, imgd.redoDepth);

			// assert ImageDocument (background, composite, document objects) state
			assertEquals(0, BitmapData(obState.bmdInitialBackground).compare(imgd.background));
			bmdComposite = imgd.composite.clone();
			assertTrue(BitmapData(obState.bmdInitialBackground).compare(bmdComposite) is BitmapData);
			bmdComposite.dispose();
			assertEquals(1, imgd.numChildren);
			assertTrue(imgd.isDirty);
			AssertTextIsPresent(imgd);

			// assert that Text object is back to its original state
			txt = imagine.documentObjects.Text(imgd.getChildAt(0));
			assertEquals(obState.xText, txt.x);
			assertEquals(obState.yText, txt.y);
			assertEquals(obState.degText, txt.rotation);
			
			//
			// undo create text
			//
			
			imgd.Undo();
			
			// assert history state
			assertEquals(0, imgd.undoDepth);
			assertEquals(3, imgd.redoDepth);

			// assert ImageDocument (background, composite, document objects) state
			assertEquals(0, BitmapData(obState.bmdInitialBackground).compare(imgd.background));
			bmdComposite = imgd.composite.clone();
			assertEquals(0, BitmapData(obState.bmdInitialBackground).compare(bmdComposite));
			bmdComposite.dispose();
			assertEquals(0, imgd.numChildren);
// UNDONE: dirty flag behavior isn't fully spec'ed. Update this test when it is.
//			assertFalse(imgd.isDirty);

			//
			// Stress undo/redo a bit more
			//

			imgd.Redo(); // create text
			AssertTextIsPresent(imgd, 0);
			imgd.Redo(); // rotate 90
			AssertTextIsPresent(imgd, 90);
			imgd.Redo(); // rotate 90
			AssertTextIsPresent(imgd, 180);
			imgd.Undo(); // rotate 90
			AssertTextIsPresent(imgd, 90);
			imgd.Undo(); // rotate 90
			AssertTextIsPresent(imgd, 0);
			imgd.Undo(); // create text
			
			// assert history state
			assertEquals(0, imgd.undoDepth);
			assertEquals(3, imgd.redoDepth);

			// assert ImageDocument (background, composite, document objects) state
			assertEquals(0, BitmapData(obState.bmdInitialBackground).compare(imgd.background));
			bmdComposite = imgd.composite.clone();
			assertEquals(0, BitmapData(obState.bmdInitialBackground).compare(bmdComposite));
			bmdComposite.dispose();
			assertEquals(0, imgd.numChildren);
// UNDONE: dirty flag behavior isn't fully spec'ed. Update this test when it is.
//			assertFalse(imgd.isDirty);
		}
		
		private function AssertTextIsPresent(imgd:ImageDocument, degRotation:Number=0): void {
			assertEquals(0, degRotation % 90);
			assertTrue(imgd.getChildAt(0) is imagine.documentObjects.Text);
			
			// test some pixels to verify that the text object is present and where we
			// expect it to be
			var apt:Array = [
				new Point(518, 400), // slightly left of text center
				new Point(359, 387), // text upper-left
				new Point(646, 414)  // text lower-right
			]
			
			// take rotation into account
			var mat:Matrix = new Matrix();
			mat.rotate(Util.RadFromDeg(degRotation));
			
			var bmdComposite:BitmapData = imgd.composite;
			for each (var pt:Point in apt) {
				pt = mat.transformPoint(pt);
				pt.x = Math.round(pt.x);
				pt.y = Math.round(pt.y);
				switch (degRotation) {
				case 90:
					pt.x += imgd.background.width;
					break;
				case 180:
					pt.x += imgd.background.width;
					pt.y += imgd.background.height;
					break;
				case 270:
					pt.y += imgd.background.height;
					break;
				}
				var co:uint = bmdComposite.getPixel(pt.x, pt.y);
//				assertEquals(pt.x + "," + pt.y + " should be 0xffffff (is 0x" + co.toString(16) + ")", 0xffffff, co);
				// The FlashType renderer renders non-rotated, unfiltered, less than 256 pixel high text
				// with a very slight amount of alpha! So we do this inexact test until we decide how
				// best to deal with it.
				AssertColor(pt.x + "," + pt.y + " should be close to 0xffffff (is 0x" + co.toString(16) + ")", 0xffffff, co, 1);
			}
		}
		
		private function AssertColor(strComment:String, coMatch:uint, coTest:uint, nThreshold:uint=0): void {
			assertTrue(strComment, Math.abs((coMatch & 0xff) - (coTest & 0xff)) <= nThreshold);
			assertTrue(strComment, Math.abs((coMatch & 0xff00) >> 8 - (coTest & 0xff00) >> 8) <= nThreshold);
			assertTrue(strComment, Math.abs((coMatch & 0xff0000) >> 16 - (coTest & 0xff0000) >> 16) <= nThreshold);
		}
		
		public function testUndoRedoSuccessive(): void {
			// Make sure the font this test uses is preloaded
			var fnWrapper:Function = addAsync(testUndoRedoSuccessive_OnFontLoaded, 5000, null, function (): void {
				fail("timeout");
			});
			var fnt:PicnikFont = GetArialRoundedFont();
			fnt.AddReference(this, fnWrapper);
		}
		
		private function testUndoRedoSuccessive_OnFontLoaded(fntr:FontResource): void {
			assertEquals(FontResource.knLoaded, fntr.state);
			
			// create doc
			var imgd:ImageDocument = new ImageDocument();
			var fnWrapper:Function = addAsync(testUndoRedoSuccessive_OnInitFromLocalFileDone, 5000, imgd, function (): void {
				fail("timeout");
			});
			assertTrue(imgd.InitFromLocalFile(null, "test.pik", "0:test.base.jpg", null, fnWrapper));
		}

		private function testUndoRedoSuccessive_OnInitFromLocalFileDone(err:Number, strError:String, imgd:ImageDocument): void {
			var obState:Object = {
				bmdInitialBackground: imgd.background.clone()
			}
			
			// create a Text object
			var op:ImageOperation = new CreateObjectOperation("Text", {
				name: Util.GetUniqueId(), x: 500, y: 400, font: GetArialRoundedFont(), fontSize: 50, text: "Abcdef 123456"
			});
			imgd.BeginUndoTransaction("Create Text", false, false);
			op.Do(imgd);
			imgd.EndUndoTransaction();
			
			// rotate document 90 degrees
			AddUndoTransaction("Rotate 90 degrees clockwise", new RotateImageOperation(Util.RadFromDeg(90)), imgd);
			
			// rotate document again (2)
			AddUndoTransaction("Rotate 90 degrees clockwise", new RotateImageOperation(Util.RadFromDeg(90)), imgd);
			
			// rotate document again (3)
			AddUndoTransaction("Rotate 90 degrees clockwise", new RotateImageOperation(Util.RadFromDeg(90)), imgd);
			
			// rotate document again (4)
			AddUndoTransaction("Rotate 90 degrees clockwise", new RotateImageOperation(Util.RadFromDeg(90)), imgd);

			AssertTextIsPresent(imgd, 0);
			
			// Stress undo/redo a bit more

			imgd.Undo(); // rotate 90
			AssertTextIsPresent(imgd, 270);
			imgd.Redo(); // rotate 90
			AssertTextIsPresent(imgd, 0);
			imgd.Undo(); // rotate 90
			AssertTextIsPresent(imgd, 270);
			imgd.Undo(); // rotate 90
			AssertTextIsPresent(imgd, 180);
			imgd.Undo(); // rotate 90
			AssertTextIsPresent(imgd, 90);
			imgd.Undo(); // rotate 90
			AssertTextIsPresent(imgd, 0);
			imgd.Undo(); // create text

			imgd.Redo(); // create text
			AssertTextIsPresent(imgd, 0);
			imgd.Redo(); // rotate 90
			AssertTextIsPresent(imgd, 90);
			imgd.Redo(); // rotate 90
			AssertTextIsPresent(imgd, 180);
			imgd.Redo(); // rotate 90
			AssertTextIsPresent(imgd, 270);
			imgd.Redo(); // rotate 90
			AssertTextIsPresent(imgd, 0);
			
			imgd.Undo(); // rotate 90
			AssertTextIsPresent(imgd, 270);
			imgd.Undo(); // rotate 90
			AssertTextIsPresent(imgd, 180);
			imgd.Undo(); // rotate 90
			AssertTextIsPresent(imgd, 90);
			imgd.Undo(); // rotate 90
			AssertTextIsPresent(imgd, 0);
			imgd.Undo(); // create text
			
			// assert history state
			assertEquals(0, imgd.undoDepth);
			assertEquals(5, imgd.redoDepth);

			// assert ImageDocument (background, composite, document objects) state
			assertEquals(0, BitmapData(obState.bmdInitialBackground).compare(imgd.background));
			var bmdComposite:BitmapData = imgd.composite.clone();
			assertEquals(0, BitmapData(obState.bmdInitialBackground).compare(bmdComposite));
			bmdComposite.dispose();
			assertEquals(0, imgd.numChildren);
// UNDONE: dirty flag behavior isn't fully spec'ed. Update this test when it is.
//			assertFalse(imgd.isDirty);
		}
		
		public function testSerializeDeserialize(): void {
			// Make sure the font this test uses is preloaded
			var fnWrapper:Function = addAsync(testSerializeDeserialize_OnFontLoaded, 5000, null, function (): void {
				fail("timeout");
			});
			var fnt:PicnikFont = GetArialRoundedFont();
			fnt.AddReference(this, fnWrapper);
		}
		
		private function testSerializeDeserialize_OnFontLoaded(fntr:FontResource): void {
			assertEquals(FontResource.knLoaded, fntr.state);
			
			// Create an interesting ImageDocument
			var imgd:ImageDocument = new ImageDocument();
			var fnWrapper:Function = addAsync(testSerializeDeserialize_OnInitFromLocalFileDone, 5000, imgd, function (): void {
				fail("timeout");
			});
			assertTrue(imgd.InitFromLocalFile(null, "blank.pik", "0:blank.base.jpg", null, fnWrapper));
		}

		private function testSerializeDeserialize_OnInitFromLocalFileDone(err:Number, strError:String, imgd:ImageDocument): void {
			//
			// Add every ImageOperation to the ImageDocument
			//
			
			// Text
			var dctParams:Object = {
				name: Util.GetUniqueId(), x: 500, y: 400, font: GetArialRoundedFont(), fontSize: 50, text: "Abcdef 123456"
			}
			AddUndoTransaction("Create Text", new CreateObjectOperation("Text", dctParams), imgd, true);
			AddUndoTransaction("Rotate 90 degrees clockwise", new RotateImageOperation(Util.RadFromDeg(90)), imgd, true);
			// UNDONE: AdjustCurves
			AddUndoTransaction("Auto fix", new AutoFixImageOperation(), imgd, true);
			AddUndoTransaction("Blur", new BlurImageOperation(1.0, 5, 10, 3), imgd, true);
			// UNDONE: Border [needs constructor arguments]
			AddUndoTransaction("Black & White", new BWImageOperation(), imgd, true);
			// UNDONE: ColorMatrix
			AddUndoTransaction("Crop to 1000x700 pixels", new CropImageOperation(10, 60, 1000, 700), imgd, true);
			// UNDONE: Doodle
			// UNDONE: DropShadow [needs constructor arguments]
			// UNDONE: FillColorMatrix
			// UNDONE: Glow
			// UNDONE: Gooify
			// UNDONE: GradientMap
			// UNDONE: HSVGradientMap
			AddUndoTransaction("Infrared", new IRImageOperation(), imgd, true);
			AddUndoTransaction("Local Contrast", new LocalContrastImageOperation(), imgd, true);
			// UNDONE: MultiplyColorMatrix
			// UNDONE: Nested
			// UNDONE: PaletteMap
			AddUndoTransaction("Resize to 999x666 pixels", new ResizeImageOperation(999, 666), imgd, true);
			AddUndoTransaction("Sharpen", new SharpenImageOperation(8), imgd, true);
			// UNDONE: SimpleColorMatrix
			// UNDONE: Tint
			AddUndoTransaction("Two Tone", new TwoToneImageOperation(), imgd, true);

			// Include a couple redo transactions
			AddUndoTransaction("Rotate 90 degrees clockwise", new RotateImageOperation(Util.RadFromDeg(90)), imgd, true);
			AddUndoTransaction("Rotate 90 degrees clockwise", new RotateImageOperation(Util.RadFromDeg(90)), imgd, true);
			imgd.Undo();
			imgd.Undo();
			
			// Serialize ImageDocument to XML
			var xml:XML = imgd.Serialize(false);
			var strAssetMap:String = imgd.GetSerializedAssetMap(true);
			
			// assert it is what it should be
			assertEquals("PicnikDocument", xml.name().toString());
			assertEquals("Objects", xml.Objects.name().toString());
			assertEquals(1, xml.Objects.children().length());
			assertEquals("UndoTransactions", xml.UndoTransactions.name().toString());
			assertEquals("11", xml.UndoTransactions.@redoStart.toString());
			assertEquals(13, xml.UndoTransactions.children().length());
			assertEquals("0:blank.base.jpg", strAssetMap);
			
			// Deserialize the XML to a new ImageDocument
			var imgdNew:ImageDocument = new ImageDocument();
			var fnWrapper:Function = addAsync(testSerializeDeserialize_OnDeserializeDone, 5000,
					{ imgdOrig: imgd, imgdNew: imgdNew }, function (): void {
				fail("timeout");
			});
			imgdNew.assets = GenericDocument.DeserializeAssetMap(strAssetMap);
			imgdNew.Deserialize("imgdNew", xml, null, fnWrapper);
		}

		private function testSerializeDeserialize_OnDeserializeDone(err:Number, strError:String, dctParams:Object): void {
			assertEquals("error " + strError, ImageDocument.errNone, err);
			
			var imgdOrig:ImageDocument = dctParams.imgdOrig;
			var imgdNew:ImageDocument = dctParams.imgdNew;
			
			// assert that the deserialized document is the same as the original
			// - same background
			assertEquals(imgdOrig.width, imgdNew.width);
			assertEquals(imgdOrig.height, imgdNew.height);
			assertEquals(imgdOrig.background.width, imgdNew.background.width);
			assertEquals(imgdOrig.background.height, imgdNew.background.height);
			
			// - same composite
			assertEquals(imgdOrig.composite.width, imgdNew.composite.width);
			assertEquals(imgdOrig.composite.height, imgdNew.composite.height);
			
			// - same objects
			assertEquals(imgdOrig.numChildren, imgdNew.numChildren);
			for (var i:Number = 0; i < imgdOrig.numChildren; i++) {
				var dobOrig:DisplayObject = imgdOrig.getChildAt(i);
				var dobNew:DisplayObject = imgdNew.getChildAt(i);
				assertEquals(getQualifiedClassName(dobOrig), getQualifiedClassName(dobNew));
				for each (var strProp:String in IDocumentObject(dobOrig).serializableProperties) {
					// UNDONE: drill into complex types, e.g. PicnikFont
					if (Util.IsComplexType(dobOrig[strProp]))
						continue;
					assertEquals(strProp + " not preserved", dobOrig[strProp], dobNew[strProp]);
				}
			}
			
			// - same history (undo & redo)
			assertEquals(imgdOrig.undoDepth, imgdNew.undoDepth);
			assertEquals(imgdOrig.redoDepth, imgdNew.redoDepth);
			var autHistoryOrig:Array = imgdOrig.GetHistoryInfo()._autHistory;
			var autHistoryNew:Array = imgdNew.GetHistoryInfo()._autHistory;
			assertEquals(autHistoryOrig.length, autHistoryNew.length);
			for (i = 0; i < autHistoryOrig.length; i++) {
				assertEquals(autHistoryOrig[i].strName, autHistoryNew[i].strName);
			}
		}
		
		public function testImageDocumentDoUndoRedoDisposing(): void {
			VBitmapData.s_fDebug = true;
			var imgd:MockImageDocument = new MockImageDocument();
			
			expect(imgd.InvalidateComposite)
				.noArgs()
				.times(2);
			
			assertTrue(imgd.Init(999, 666));
			assertTrue(imgd.background.width == 999 && imgd.background.height == 666);
			assertTrue(imgd.composite.width == 999 && imgd.composite.height == 666);
			
			// Get a baseline number of undisposed bitmaps
			var cbmdBaseline:Number = VBitmapData.s_cbmdUndisposed;
			
			// Do an operation (+1)
			// - imgd.background -> UndoTransaction.bmdBackground
			// - new BitmapData, the sharpened image -> imgd.background
			var op:ImageOperation = new SharpenImageOperation(10);
			AddUndoTransaction("Sharpen", op, imgd);
			assertEquals(1, VBitmapData.s_cbmdUndisposed - cbmdBaseline);
			cbmdBaseline += 1;
			
			// Undo (-1)
			// - imgd.background.dispose()
			// - UndoTransaction.bmdBackground -> imgd.background
			imgd.Undo();
			assertEquals(-1, VBitmapData.s_cbmdUndisposed - cbmdBaseline);
			cbmdBaseline -= 1;
			
			// Redo (+1)
			// - imgd.background -> UndoTransaction.bmdBackground
			// - new BitmapData, the sharpened image -> imgd.background
			imgd.Redo();
			assertEquals(1, VBitmapData.s_cbmdUndisposed - cbmdBaseline);
			cbmdBaseline += 1;
			
			// Set up to stress FreeUndoBitmaps and Undo's replay from keyframe
			VBitmapData.s_fDebug = false;
			
			verify();
		}

		private static var s_cbmdBaselineImageDocumentDoDisposing:Number = 0;
		
		public function testImageDocumentDoDisposing(): void {
			// Get a baseline number of undisposed bitmaps
			VBitmapData.s_fDebug = true;
			s_cbmdBaselineImageDocumentDoDisposing = VBitmapData.s_cbmdUndisposed;
			
			// Make sure the font this test uses is preloaded
			var fnWrapper:Function = addAsync(testImageDocumentDoDisposing_OnFontLoaded, 5000, null, function (): void {
				fail("timeout");
			});
			var fnt:PicnikFont = GetArialRoundedFont();
			fnt.AddReference(this, fnWrapper);
		}
		
		private function testImageDocumentDoDisposing_OnFontLoaded(fntr:FontResource): void {
			assertEquals(FontResource.knLoaded, fntr.state);

			// create doc
			var imgd:ImageDocument = new ImageDocument();
			var fnWrapper:Function = addAsync(testDoDisposing_OnInitFromLocalFileDone, 5000, imgd, function (): void {
				fail("timeout");
			});
			assertTrue(imgd.InitFromLocalFile(null, "test.pik", "0:test.base.jpg", null, fnWrapper));
		}

		private function testDoDisposing_OnInitFromLocalFileDone(err:Number, strError:String, imgd:ImageDocument): void {
			assertEquals("init failed (" + err + ", " + strError + ")", ImageDocument.errNone, err);
			assertEquals(2, VBitmapData.s_cbmdUndisposed - s_cbmdBaselineImageDocumentDoDisposing);
			s_cbmdBaselineImageDocumentDoDisposing += 2;
			
			// Text
			var dctParams:Object = {
				name: Util.GetUniqueId(), x: 500, y: 400, font: GetArialRoundedFont(), fontSize: 50, text: "Abcdef 123456"
			}
			AddUndoTransaction("Create Text", new CreateObjectOperation("Text", dctParams), imgd, true);
			assertEquals(0, VBitmapData.s_cbmdUndisposed - s_cbmdBaselineImageDocumentDoDisposing);

/*			
			// Do an operation (+1)
			// - imgd.background -> UndoTransaction.bmdBackground
			// - new BitmapData, the sharpened image -> imgd.background
			var op:ImageOperation = new SharpenImageOperation(10);
			AddUndoTransaction("Sharpen", op, imgd);
			assertEquals(1, VBitmapData.s_cbmdUndisposed - s_cbmdBaselineImageDocumentDoDisposing);
			s_cbmdBaselineImageDocumentDoDisposing += 1;
			
			// Undo (-1)
			// - imgd.background.dispose()
			// - UndoTransaction.bmdBackground -> imgd.background
			imgd.Undo();
			assertEquals(-1, VBitmapData.s_cbmdUndisposed - s_cbmdBaselineImageDocumentDoDisposing);
			s_cbmdBaselineImageDocumentDoDisposing -= 1;
			
			// Redo (+1)
			// - imgd.background -> UndoTransaction.bmdBackground
			// - new BitmapData, the sharpened image -> imgd.background
			imgd.Redo();
			assertEquals(1, VBitmapData.s_cbmdUndisposed - s_cbmdBaselineImageDocumentDoDisposing);
			s_cbmdBaselineImageDocumentDoDisposing += 1;
*/			
			VBitmapData.s_fDebug = false;
			
			PicnikService.Logout2();
		}

		//
		// Helpers
		//
				
		private function AddUndoTransaction(strName:String, op:ImageOperation, imgd:ImageDocument, fUseCache:Boolean=false): void {
			imgd.BeginUndoTransaction(strName, fUseCache, !(op is ObjectOperation));
			op.Do(imgd, true, fUseCache); // do objects, use BitmapCache
			imgd.EndUndoTransaction(true, fUseCache); // commit, clear cache
		}
		
		private function GetArialRoundedFont(): PicnikFont {
			var fnt:PicnikFont = new PicnikFont();
			fnt.familyName = "pkARLRDBD";
			fnt.baseFileName = "ARLRDBD";
			return fnt;
		}
		// UNDONE: test each ImageOperation (in imageOperations/tests/Test*ImageOperation.as)
		// - Do with a range of parameters
		//   - valid
		//   - invalid
		//   - try to break Filters
		// - Undo
		// - DocumentObjects are handled right
		// UNDONE: test each ObjectOperation
	}
}
