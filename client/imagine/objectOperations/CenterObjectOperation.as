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
package imagine.objectOperations {
	import imagine.documentObjects.IDocumentObject;
	
	import flash.display.DisplayObject;
	
	// Wrapper for SetProperties to set scaleX and scaleY to 1
	[RemoteClass]
	public class CenterObjectOperation extends SetPropertiesObjectOperation {
		public function CenterObjectOperation (dob:DisplayObject=null) {
			var strName:String = null;
			var dctPropertySets:Object = null;
			if (dob != null) {
				// Now set the new scale based on the sign of the old scale so we don't flip
				strName = dob.name;
				dctPropertySets = new Object();
				var docob:IDocumentObject = dob as IDocumentObject;
				if (docob) {
					dctPropertySets['x'] = docob.document.width / 2;
					dctPropertySets['y'] = docob.document.height / 2;
				}
			}
			super(strName, dctPropertySets);
		}
	}
}
