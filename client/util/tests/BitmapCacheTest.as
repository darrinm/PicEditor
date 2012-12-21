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
package util.tests {
	import flexunit.framework.*;
	import util.BitmapCache;
	import flash.display.BitmapData;

	public class BitmapCacheTest extends TestCase {
		public function testLookup(): void {
			// BitmapCache is static, make sure it's clear before getting started
			BitmapCache.Clear();
			
			var bmdSrc:BitmapData = new BitmapData(200, 100);
			var bmdRes:BitmapData = new BitmapData(100, 200);
			var strType:String = "type1";
			var strParams:String = "some cool parameters";
			
			BitmapCache.Set(this, strType, strParams, bmdSrc, bmdRes);
			assertEquals(bmdRes, BitmapCache.Lookup(this, strType, strParams, bmdSrc));
			assertEquals(null, BitmapCache.Lookup(this, strType, strParams, bmdRes));
		}
		
		public function testClear(): void {
			// BitmapCache is static, make sure it's clear before getting started
			BitmapCache.Clear();
			
			var bmdSrc:BitmapData = new BitmapData(200, 100);
			var bmdRes:BitmapData = new BitmapData(100, 200);
			var strType:String = "type1";
			var strParams:String = "some cool parameters";
			
			BitmapCache.Set(this, strType, strParams, bmdSrc, bmdRes);
			assertEquals(bmdRes, BitmapCache.Lookup(this, strType, strParams, bmdSrc));
			BitmapCache.Clear();
			assertEquals(null, BitmapCache.Lookup(this, strType, strParams, bmdSrc));
		}
		
		public function testRemoveFromCache(): void {
			// BitmapCache is static, make sure it's clear before getting started
			BitmapCache.Clear();
			
			var bmdSrc:BitmapData = new BitmapData(200, 100);
			var bmdRes:BitmapData = new BitmapData(100, 200);
			var strType:String = "type1";
			var strParams:String = "some cool parameters";
			
			BitmapCache.Set(this, strType, strParams, bmdSrc, bmdRes);
			assertEquals(bmdRes, BitmapCache.Lookup(this, strType, strParams, bmdSrc));
			BitmapCache.Remove(bmdRes);
			assertEquals(null, BitmapCache.Lookup(this, strType, strParams, bmdSrc));
		}
		
		public function testBackupCacheEntry(): void {
			// UNDONE:
		}
		
		public function testSet(): void {
			// UNDONE:
		}
		
		public function testContains(): void {
			// BitmapCache is static, make sure it's clear before getting started
			BitmapCache.Clear();
			
			var bmdSrc:BitmapData = new BitmapData(200, 100);
			var bmdRes:BitmapData = new BitmapData(100, 200);
			var strType:String = "type1";
			var strParams:String = "some cool parameters";
			
			BitmapCache.Set(this, strType, strParams, bmdSrc, bmdRes);
			assertTrue(BitmapCache.Contains(bmdRes));
		}
	}
}
