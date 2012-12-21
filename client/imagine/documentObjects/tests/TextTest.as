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
package imagine.documentObjects.tests {
	import flexunit.framework.*;
	import imagine.documentObjects.IDocumentObject;
	import imagine.documentObjects.Text;
	import imagine.imageOperations.*;
	import imagine.objectOperations.*;
	import util.FontResource;
	import util.PicnikFont;
	import errors.InvalidArgumentError;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;

	import imagine.ImageDocument;
	
	import mx.core.Application;
	
	// UNDONE:
	// - hit testing
	// - fonts
	// - min/max string
	// - min/max size
	// - min/max position
	// - textColor, scaleX/Y, alpha, fontSize, underline, textAlign, rotation, name, leading
	// - serialize/deserialize
	
	
	public class TextTest extends TestCase {
		public function testText(): void {
			// Make sure the font this test uses is preloaded
			var fnWrapper:Function = addAsync(testText_OnFontLoaded, 5000, null, function (): void {
				fail("timeout");
			});
			var fnt:PicnikFont = GetArialRoundedFont();
			fnt.AddReference(this, fnWrapper);
		}
		
		private function testText_OnFontLoaded(fntr:FontResource): void {
			assertEquals(FontResource.knLoaded, fntr.state);
			
			// create doc
			var imgd:ImageDocument = new ImageDocument();
			imgd.Init(1000, 800);
			
			// create a Text object
			var op:ImageOperation = new CreateObjectOperation("Text", {
				name: Util.GetUniqueId(), x: 500, y: 400, font: GetArialRoundedFont(), fontSize: 50, text: "Abcdef 123456"
			});
			AddUndoTransaction("Create Text", op, imgd);
			
			var txt:imagine.documentObjects.Text = imagine.documentObjects.Text(imgd.getChildAt(0));
			var bmdComposite:BitmapData = imgd.composite.clone();
			var x:Number, y:Number, co:uint;
			
			// UNDONE: should seed the random number generator but it doesn't look like Flash
			// provides a way to do it. Implement our own pseudo-random number generator.
			
			var cHit:Number = 0;
			var astrHit:Array = [];
			// Try 10,000 random pixels and assert that hits only occur within the text
			// object's localRect
			bmdComposite.lock();
			var rcBounds:Rectangle = txt.localRect;
			rcBounds.offset(txt.x, txt.y);
			for (var i:Number = 0; i < 100000; i++) {
				x = Math.round(Math.random() * (bmdComposite.width - 1));
				y = Math.round(Math.random() * (bmdComposite.height - 1));
				co = bmdComposite.getPixel(x, y);
//				bmdDisplay.setPixel(x, y, co == 0xffffff ? 0xff0000 : 0x00ff00);
				if (co != 0xffffff) {
					assertTrue(x + "," + y +  "," + co.toString(16) + " should be inside " + rcBounds.toString(), rcBounds.contains(x, y));
					/*
					if (TestColorMatch(co, 0x0000ff, 5)) {
						if (cHit < 100) {
							cHit++;
							astrHit.push("new Point(" + x + "," + y + ")");
						}
					}
					*/
				}
			}
//			trace(cHit + ": " + astrHit.join(","));

			bmdComposite.unlock();
			// Test 100 points known to 'hit' the text
			bmdComposite.lock();
			var pt:Point;
			for each (pt in s_aptHit) {
				co = bmdComposite.getPixel(pt.x, pt.y);
				assertTrue(pt.x + "," + pt.y +  "," + co.toString(16) + " should hit the text", TestColorMatch(0x0000ff, co, 5));
			}
			bmdComposite.unlock();

			// Test 100 points known to 'miss' the text
			bmdComposite.lock();
			for each (pt in s_aptMiss) {
				co = bmdComposite.getPixel(pt.x, pt.y);
				assertEquals(pt.x + "," + pt.y +  "," + co.toString(16) + " should not hit the text", 0xffffff, co);
			}
			bmdComposite.unlock();
		}
		
		//===================================================================
		
		public function testTextHitTestPoint(): void {
			// Make sure the font this test uses is preloaded
			var fnWrapper:Function = addAsync(testTextHitTestPoint_OnFontLoaded, 5000, null, function (): void {
				fail("timeout");
			});
			var fnt:PicnikFont = GetArialRoundedFont();
			fnt.AddReference(this, fnWrapper);
		}
		
		private function testTextHitTestPoint_OnFontLoaded(fntr:FontResource): void {
			assertEquals(FontResource.knLoaded, fntr.state);
			
			// create doc
			var imgd:ImageDocument = new ImageDocument();
			imgd.Init(500, 400, 0x000000);

			// create a Text object
			var op:ImageOperation = new CreateObjectOperation("Text", {
				name: Util.GetUniqueId(), x: 250, y: 200, font: GetArialRoundedFont(), fontSize: 50, text: "Abcdef 123456", textColor: 0x0000ff
			});
			AddUndoTransaction("Create Text", op, imgd);

			var bmdDisplay:BitmapData = imgd.composite.clone();
			var txt:imagine.documentObjects.Text = imagine.documentObjects.Text(imgd.getChildAt(0));

			var x:Number, y:Number, co:uint, pt:Point, ptT:Point;
			
			/*
			// Test every point and display the result
			bmdDisplay.lock();
			for (y = 0; y < bmdDisplay.height; y += 1) {
				for (x = 0; x < bmdDisplay.width; x += 1) {
					var fHit:Boolean = imgd.GetObjectsUnderPoint(new Point(x, y), true).length == 1;
					bmdDisplay.setPixel(x, y, fHit ? 0x00ff00 : 0xff0000);
				}
			}
			bmdDisplay.unlock();
			Application.application.stage.addChild(new Bitmap(bmdDisplay));
			*/
/*			
			// Generate 100 'hit' test points. These points are good for both the NORMAL
			// and ADVANCED AntiAliasType rasterizers.
			bmdDisplay.lock();
			var astrHit:Array = [];
			while (astrHit.length < 100) {
				x = Math.round(Math.random() * bmdDisplay.width);
				y = Math.round(Math.random() * bmdDisplay.height);
				var fHit:Boolean = imgd.GetObjectsUnderPoint(new Point(x, y), true).length == 1;
				if (fHit) {
					var coDrawn:uint = bmdDisplay.getPixel(x, y);
					if (coDrawn == 0x00ff00)
						continue;
					var fHitDrawn:Boolean = (coDrawn & 0x0000ff) != 0;
					if (fHitDrawn)
						astrHit.push("new Point(" + x + "," + y +")");
					bmdDisplay.setPixel(x, y, fHitDrawn ? 0x00ff00 : 0xff0000);
				}
			}
			bmdDisplay.unlock();
			trace("hit: " + astrHit.join(","));
			Application.application.stage.addChild(new Bitmap(bmdDisplay));

			// Generate 100 'miss' test points. These points are good for both the NORMAL
			// and ADVANCED AntiAliasType rasterizers.
			bmdDisplay.lock();
			var astrHit:Array = [];
			while (astrHit.length < 100) {
				x = Math.round(Math.random() * bmdDisplay.width);
				y = Math.round(Math.random() * bmdDisplay.height);
				var fHit:Boolean = imgd.GetObjectsUnderPoint(new Point(x, y), true).length == 0;
				if (fHit) {
					var coDrawn:uint = bmdDisplay.getPixel(x, y);
					if (coDrawn == 0x00ff00 || coDrawn == 0xff0000)
						continue;
					var fHitDrawn:Boolean = coDrawn == 0x000000;
					if (fHitDrawn)
						astrHit.push("new Point(" + x + "," + y +")");
					bmdDisplay.setPixel(x, y, fHitDrawn ? 0x00ff00 : 0xff0000);
				}
			}
			bmdDisplay.unlock();
			trace("miss: " + astrHit.join(","));
			Application.application.stage.addChild(new Bitmap(bmdDisplay));
*/

			// Test 100 points known to hit the text
			for each (pt in s_aptHit) {
				// Use ImageDocument.GetObjectsUnderPoint() to do the hit testing because it has
				// smarts for adding/removing the object to the stage.
				assertTrue(pt.x + "," + pt.y + " should hit the text",
						imgd.GetObjectsUnderPoint(new Point(pt.x, pt.y), true).length == 1);
			}

			// Test 100 points known to miss the text
			for each (pt in s_aptMiss)
				assertTrue(pt.x + "," + pt.y + " should not hit the text",
						imgd.GetObjectsUnderPoint(new Point(pt.x, pt.y), true).length == 0);

			// Flip the text horizontally
			txt.scaleX = -1;
			for each (pt in s_aptHit) {
				ptT = new Point(txt.x - (pt.x - txt.x), pt.y);
				assertTrue(ptT.x + "," + ptT.y + " should hit the h-flipped text",
						imgd.GetObjectsUnderPoint(ptT, true).length == 1);
			}
			
			// Flip the text vertically
			txt.scaleX = 1;
			txt.scaleY = -1;
			
			for each (pt in s_aptHit) {
				ptT = new Point(pt.x, txt.y - (pt.y - txt.y));
				assertTrue(pt.toString() + " " + ptT.x + "," + ptT.y + " should hit the v-flipped text",
						imgd.GetObjectsUnderPoint(ptT, true).length == 1);
			}
			

			
			// Rotate the text
			
			// Test 100 points known to 'hit' the text
			// Test 100 points known to 'miss' the text
			
			// Resize the text
			
			// Test 100 points known to 'hit' the text
			// Test 100 points known to 'miss' the text
			
			// Squash the text vertically
			
			// Test 100 points known to 'hit' the text
			// Test 100 points known to 'miss' the text
			
			// Squish the text horizontally
			
			// Test 100 points known to 'hit' the text
			// Test 100 points known to 'miss' the text
			
		}
		
		// These points are NOT on the anti-aliased edge of the text.
		// They are relative to the ImageDocument's upper-left.
		private static var s_aptHit:Array = [
			new Point(345,214),new Point(143,211),new Point(195,192),new Point(111,194),new Point(268,205),new Point(199,200),new Point(148,207),new Point(130,201),new Point(107,205),new Point(368,188),new Point(130,194),new Point(200,193),new Point(187,212),new Point(376,203),new Point(111,193),new Point(319,189),new Point(198,196),new Point(294,188),new Point(343,190),new Point(238,195),new Point(347,190),new Point(392,186),new Point(217,214),new Point(181,204),new Point(180,197),new Point(389,215),new Point(167,194),new Point(112,197),new Point(235,202),new Point(235,199),new Point(208,201),new Point(387,195),new Point(301,212),new Point(184,211),new Point(371,200),new Point(400,213),new Point(340,208),new Point(214,216),new Point(389,214),new Point(284,194),new Point(235,210),new Point(143,208),new Point(320,189),new Point(187,195),new Point(236,185),new Point(105,192),new Point(388,197),new Point(346,185),new Point(338,201),new Point(241,187),new Point(375,199),new Point(100,204),new Point(299,213),new Point(290,213),new Point(337,205),new Point(157,198),new Point(403,203),new Point(131,204),new Point(207,209),new Point(366,215),new Point(210,198),new Point(268,187),new Point(325,206),new Point(307,208),new Point(271,208),new Point(146,199),new Point(113,190),new Point(270,187),new Point(386,191),new Point(154,208),new Point(137,193),new Point(401,190),new Point(267,203),new Point(155,200),new Point(118,213),new Point(401,205),new Point(369,189),new Point(115,201),new Point(190,212),new Point(219,194),new Point(268,190),new Point(402,202),new Point(311,190),new Point(101,198),new Point(196,192),new Point(208,209),new Point(269,206),new Point(344,193),new Point(133,196),new Point(395,214),new Point(267,186),new Point(292,186),new Point(168,199),new Point(111,204)
		]
		
		private static var s_aptMiss:Array = [
			new Point(210,259),new Point(225,183),new Point(163,28),new Point(248,394),new Point(467,288),new Point(43,124),new Point(458,276),new Point(44,218),new Point(476,332),new Point(140,21),new Point(329,152),new Point(232,317),new Point(356,257),new Point(188,373),new Point(448,244),new Point(497,77),new Point(83,171),new Point(384,234),new Point(413,133),new Point(82,51),new Point(500,265),new Point(56,109),new Point(409,106),new Point(201,36),new Point(331,72),new Point(344,260),new Point(186,119),new Point(138,64),new Point(77,386),new Point(306,25),new Point(236,284),new Point(15,312),new Point(221,43),new Point(52,375),new Point(435,229),new Point(55,379),new Point(180,2),new Point(465,7),new Point(481,46),new Point(420,361),new Point(84,147),new Point(88,285),new Point(493,290),new Point(150,361),new Point(44,108),new Point(488,394),new Point(327,227),new Point(313,245),new Point(191,380),new Point(32,317),new Point(163,235),new Point(340,273),new Point(13,47),new Point(192,22),new Point(371,170),new Point(369,207),new Point(330,147),new Point(188,358),new Point(302,268),new Point(423,261),new Point(209,43),new Point(476,255),new Point(233,15),new Point(260,375),new Point(128,160),new Point(306,71),new Point(321,388),new Point(160,32),new Point(126,25),new Point(432,353),new Point(47,266),new Point(39,372),new Point(153,354),new Point(298,87),new Point(37,231),new Point(198,103),new Point(182,375),new Point(334,343),new Point(460,348),new Point(101,27),new Point(18,227),new Point(292,218),new Point(276,211),new Point(295,241),new Point(123,288),new Point(458,57),new Point(227,91),new Point(62,393),new Point(463,15),new Point(156,230),new Point(44,38),new Point(181,373),new Point(139,121),new Point(465,295),new Point(129,322),new Point(118,24),new Point(224,24),new Point(49,159),new Point(245,182),new Point(479,59)	
		]
		
		private function AddUndoTransaction(strName:String, op:ImageOperation, imgd:ImageDocument): void {
			imgd.BeginUndoTransaction(strName, false, !(op is ObjectOperation));
			op.Do(imgd);
			imgd.EndUndoTransaction();
		}
		
		private function TestColorMatch(coMatch:uint, coTest:uint, nThreshold:uint=0): Boolean {
			if (Math.abs((coMatch & 0xff) - (coTest & 0xff)) > nThreshold)
				return false;
			if (Math.abs((coMatch & 0xff00) >> 8 - (coTest & 0xff00) >> 8) > nThreshold)
				return false;
			if (Math.abs((coMatch & 0xff0000) >> 16 - (coTest & 0xff0000) >> 16) > nThreshold)
				return false;
			return true;
		}
		
		private function GetArialRoundedFont(): PicnikFont {
			var fnt:PicnikFont = new PicnikFont();
			fnt.familyName = "pkARLRDBD";
			fnt.baseFileName = "ARLRDBD";
			return fnt;
		}
	}
}
