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
﻿package tests {
	import bridges.tests.*;
	
	import controls.list.util.tests.PendingListTest;
	
	import imagine.documentObjects.tests.*;
	
	import imagine.imageOperations.tests.*;
	
	import imagine.serialization.tests.*;
	
	import util.tests.*;
	
	import flexunit.framework.*;
	
	public class AllClientTests {
		public static function suite(): TestSuite {
			var suite:TestSuite = new TestSuite();		
			
			suite.addTestSuite(DocumentObjectTest);
			suite.addTestSuite(PendingListTest);
			suite.addTestSuite(BitmapCacheTest);
			suite.addTestSuite(TextTest);
			suite.addTestSuite(tests.UtilTest);
			suite.addTestSuite(tests.ImageDocumentTest);
			suite.addTestSuite(DropShadowImageOperationTest);
			suite.addTestSuite(OAuthTest);
			suite.addTestSuite(SerializationUtilTest);
			return suite;
		}
	}
}
