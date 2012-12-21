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
	import imagine.documentObjects.DocumentObjectBase;
	import imagine.documentObjects.DocumentObjectContainer;
	import imagine.documentObjects.PRectangle;
	
	import flash.geom.Rectangle;
	
	import flexunit.framework.*;
	
	import imagine.imageOperations.*;
	
	import imagine.ImageDocument;
	
	import imagine.objectOperations.*;
	import com.google.mockasin.*;
	import tests.MockImageDocument;
	
	public class DocumentObjectTest extends TestCase {

		public override function setUp():void {
			reset();
		}
		
//			return [ "x", "y", "alpha", "rotation", "name", "scaleX", "scaleY", "color", "blendMode", "maskId" ];
// localRect, unscaledWidth, unscaledHeight
		public function testLocalRect(): void {
			// Create blank ImageDocument
			var imgd:MockImageDocument = new MockImageDocument();
			
			expect(imgd.InvalidateComposite)
				.noArgs()
				.times(11);
			
			assertTrue(imgd.Init(1024, 768));
			
			var rcTest:Rectangle = new Rectangle(-150 / 2, -80 / 2, 150, 80);
		
			// Create a Rectangle DisplayObject
			var doco:PRectangle = new PRectangle();
			doco.x = 200;
			doco.y = 100;
			doco.unscaledWidth = 150;
			doco.unscaledHeight = 80;
			imgd.addChild(doco);
			doco.Validate(); // CONSIDER: DocumentObjects self-validating on ADD, or prop-get?
			
			// Is its localRect what we expect?
			var rc:Rectangle = doco.localRect;
			assertTrue(rc.equals(rcTest));
			
			// Change it
			doco.localRect = rcTest;
			doco.Validate();
			
			// Now is it what we expect?
			rc = doco.localRect;
			assertTrue(rc.equals(rcTest));
			
			// UNDONE: Rotate, scale
			
			// Child DocumentObject
			
			var docoChild:PRectangle = new PRectangle();
			docoChild.x = 200;
			docoChild.y = 100;
			docoChild.unscaledWidth = 150;
			docoChild.unscaledHeight = 80;
			var dococ:DocumentObjectContainer = doco;
			dococ.addChild(docoChild);
			docoChild.Validate(); // CONSIDER: DocumentObjects self-validating on ADD, or prop-get?

			// Is its localRect what we expect?
			rc = docoChild.localRect;
			assertTrue(rc.equals(rcTest));
			
			// Change it
			docoChild.localRect = rcTest;
			docoChild.Validate();
			
			// Now is it what we expect?
			rc = docoChild.localRect;
			assertTrue(rc.equals(rcTest));
			
			// How about if we double its parent's size?
			doco.scaleX = 2.0;
			doco.scaleY = 2.0;
			doco.Validate();
			
			// Is its localRect what we expect?
			rc = docoChild.localRect;
			assertTrue(rc.equals(rcTest));
			
			// Change it
			docoChild.localRect = rcTest;
			docoChild.Validate();
			
			// Now is it what we expect?
			rc = docoChild.localRect;
			assertTrue(rc.equals(rcTest));

			verify();
		}
	}
}
