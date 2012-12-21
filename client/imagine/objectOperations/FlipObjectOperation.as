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
	import flash.display.DisplayObject;
	
	// Wrapper for set properties to flip an object
	[RemoteClass]
	public class FlipObjectOperation extends SetPropertiesObjectOperation {
		public function FlipObjectOperation(dob:DisplayObject=null, fHorizontal:Boolean=true) {
			var strName:String = null;
			var dctPropertySets:Object = null;
			if (dob != null) {
				strName = dob.name;
				dctPropertySets = new Object();
				if (fHorizontal)
					dctPropertySets['scaleX'] = -dob['scaleX'];
				else
					dctPropertySets['scaleY'] = -dob['scaleY'];
			}
			super(strName, dctPropertySets);
		}
	}
}
