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
	import imagine.documentObjects.IDocumentObject;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import flexunit.framework.*;
	
	import mx.utils.ArrayUtil;

	public class UtilTest extends TestCase {
		public function testXmlPropertiesFromOb(): void {
			var ob:Object = {
				x: 10.0,
				y: 100.001,
				rotation: 0,
				string: "test string",
				"null": null,
				"true": true,
				"false": false,
				date: new Date(),
				rectangle: new Rectangle(123.345, 356.12, 10001.9999, 20021)
				// UNDONE: an IDocumentSerializable instance
			}
			
			// assert default parameters
			var xml:XML = Util.XmlPropertiesFromOb(ob);
			AssertXmlMatchesObject(xml, ob);

			// assert strElementName parameter
			xml = Util.XmlPropertiesFromOb(ob, "Properties");
			assertEquals("Properties", xml.name());
			AssertXmlMatchesObject(xml, ob);
		}
		
		public function testXmlPropertiesFromObWithSubset(): void {
			var doco:MockDocumentObject = new MockDocumentObject();
			var xml:XML = Util.XmlPropertiesFromOb(doco, "Properties", doco.serializableProperties);
			AssertXmlMatchesObject(xml, doco, doco.serializableProperties);
		}
		
		public function testXmlPropertiesFromObWithExcludeSubset(): void {
			var ob:Object = {
				x: 10.0,
				y: 100.001,
				rotation: 0,
				string: "test string",
				"null": null,
				"true": true,
				"false": false,
				date: new Date(),
				rectangle: new Rectangle(123.345, 356.12, 10001.9999, 20021)
				// UNDONE: an IDocumentSerializable instance
			}

			var astrSubset:Array = ["null", "true", "false", "y"];
			var xml:XML = Util.XmlPropertiesFromOb(ob, "Properties", astrSubset, true);
			AssertXmlMatchesObject(xml, ob, astrSubset, true);
		}
		
		private function AssertXmlMatchesObject(xml:XML, ob:Object, astrSubset:Array=null, fExclude:Boolean=false): void {
			var astrProps:Array = [];
			var strProp:String;
			if (astrSubset != null) {
				if (fExclude) {
					for (strProp in ob)
						if (astrSubset.indexOf(strProp) == -1)
							astrProps.push(strProp);
				} else {
					astrProps = astrSubset;
				}
			} else {
				for (strProp in ob)
					astrProps.push(strProp);
			}
			
			// Verify that every object property made it
			for each (strProp in astrProps) {
				var strValue:Object = xml.Property.(@name==strProp).@value.toString();
				var strType:Object = xml.Property.(@name==strProp).@type.toString();
				assertTrue(strProp + " is present", strValue != null && strValue != "");
				assertTrue(strProp + " value is correct", strValue == String(ob[strProp]));
//				trace(strProp + " = " + strValue + " [" + strType + "]");
			}
			
			// Verify that no extra properties were created
			for (var i:Number = 0; i < xml.Property.length(); i++)
				assertTrue(xml.Property[i].@name + " not expected",
						astrProps.indexOf(xml.Property[i].@name.toString()) != -1);
		}
		
		public function testGetRaySegmentIntersection(): void {
			var ptIntersection:Point;
			var nDistance:Number;
			
			// A bunch of rays and segments that intersect
			
			ptIntersection = Util.GetRaySegmentIntersection(new Point(0, 0), new Point(1, 0), new Point(2, 1), new Point(2, -1));
			assertEquals(ptIntersection.toString(), new Point(2, 0).toString());
			
			ptIntersection = Util.GetRaySegmentIntersection(new Point(0, 0), new Point(-1, 0), new Point(-2, 1), new Point(-2, -1));
			assertEquals(ptIntersection.toString(), new Point(-2, 0).toString());
			
			ptIntersection = Util.GetRaySegmentIntersection(new Point(0, 0), new Point(1, 1), new Point(0, 10), new Point(10, 0));
			assertEquals(ptIntersection.toString(), new Point(5, 5).toString());
			
			ptIntersection = Util.GetRaySegmentIntersection(new Point(-10, -10), new Point(0, 0), new Point(0, 10), new Point(10, 0));
			assertEquals(ptIntersection.toString(), new Point(5, 5).toString());

			// line with ray origin on it intersects
			
			ptIntersection = Util.GetRaySegmentIntersection(new Point(0, 0), new Point(1, 0), new Point(0, 1), new Point(0, -1));
			assertEquals(ptIntersection.toString(), new Point(0, 0).toString());

			/*
			// ray inside the seg intersects [GetRaySegementIntersection doesn't recognize this]
			
			ptIntersection = Util.GetRaySegmentIntersection(new Point(0, 0), new Point(1, 0), new Point(-1, 0), new Point(2, 0));
			assertEquals(ptIntersection.toString(), new Point(2, 0).toString());
			*/
			
			// intersection is where it is expected

			
			// parallel lines don't intersect
			
			// - horz
			ptIntersection = Util.GetRaySegmentIntersection(new Point(0, 0), new Point(1, 0), new Point(0, 1), new Point(100, 1));
			assertNull(ptIntersection);
			
			// - vert
			ptIntersection = Util.GetRaySegmentIntersection(new Point(0, 0), new Point(0, 1), new Point(1, 0), new Point(1, 100));
			assertNull(ptIntersection);
			
			// - diag
			ptIntersection = Util.GetRaySegmentIntersection(new Point(0, 0), new Point(1, 1), new Point(1, 0), new Point(2, 1));
			assertNull(ptIntersection);
			
			// line wholly on the 'wrong' side of ray's origin can't intersect

			ptIntersection = Util.GetRaySegmentIntersection(new Point(3, 0), new Point(4, 0), new Point(2, 1), new Point(2, -1));
			assertNull(ptIntersection);
			
			// line intersection outside of segment doesn't count
			
			ptIntersection = Util.GetRaySegmentIntersection(new Point(0, 0), new Point(1, 0), new Point(2, 2), new Point(2, 1));
			assertNull(ptIntersection);
		}
	}
}

class MockDocumentObject {
	public function get serializableProperties(): Array {
		return [ "x", "y", "rotation", "string", "_null", "_true", "_false", "date", "rectangle" ];
	}
	
	public function get x(): Number {
		return 10.0;
	}
	public function get y(): Number {
		return 100.001;
	}
	public function get rotation(): Number {
		return 0;
	}
	public function get string(): String {
		return "test string";
	}
	public function get _null(): Object {
		return null;
	}
	public function get _true(): Boolean {
		return true;
	}
	public function get _false(): Boolean {
		return false;
	}
	public function get date(): Date {
		return new Date();
	}
	public function get rectangle(): flash.geom.Rectangle {
		return new flash.geom.Rectangle(123.345, 356.12, 10001.9999, 20021);
	}
}
