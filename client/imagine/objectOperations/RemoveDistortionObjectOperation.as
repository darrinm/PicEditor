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
	
	// Wrapper for SetProperties to remove aspect ratio distortion (and maybe eventually other distortions)
	// Sets adjusts aspect ratio to be 1x1 while maintaining approximate size
	[RemoteClass]
	public class RemoveDistortionObjectOperation extends SetPropertiesObjectOperation {
		private function SameSign(nIn:Number, nSign:Number): Number {
			return ((nSign < 0) != (nIn < 0)) ? -nIn : nIn;
		}
		
		public function RemoveDistortionObjectOperation(dob:DisplayObject=null) {
			var strName:String = null;
			var dctPropertySets:Object = null;
			if (dob != null) {
				strName = dob.name;
				dctPropertySets = new Object();
				// Normalize the scale by maintaining the scale "area" (area of a 1x1 box at the current scale)
				// In other words, if an object scale is X,Y, X != Y, we want to change the scale to X2,Y2, X2 == Y2
				// At the same time, we want the approximate size to remain close to the same.
				// Currently, we define the size as the "area" of the scale, in other words X * Y.
				// Thus, X * Y == X2 * Y2 and X2 == Y2 => X2 = Y2 = sqrt(X * Y)
				var nArea:Number = Math.abs(dob['scaleX'] * dob['scaleY']);
				var nScale:Number = Math.sqrt(nArea);
				
				// Now set the new scale based on the sign of the old scale so we don't flip
				dctPropertySets['scaleX'] = SameSign(nScale, dob['scaleX']);
				dctPropertySets['scaleY'] = SameSign(nScale, dob['scaleY']);
			}
			super(strName, dctPropertySets);
		}
	}
}
