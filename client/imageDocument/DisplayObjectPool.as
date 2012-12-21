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
package imageDocument {
	import flash.display.DisplayObject;
	
	public class DisplayObjectPool {
		static private var s_dctPool:Object = {};
			
		static public function Add(strUrl:String, dob:DisplayObject): void {
			var adob:Array = (strUrl in s_dctPool) ? s_dctPool[strUrl] : [];
			for (var i:int = 0; i < adob.length; i++)
				Debug.Assert(adob[i] != dob, "DisplayObject should only be in the DisplayObjectPool once");
			adob.push(dob);
			s_dctPool[strUrl] = adob;
		}
		
		static public function Get(strUrl:String): DisplayObject {
			if (!(strUrl in s_dctPool))
				return null;
			var adob:Array = s_dctPool[strUrl];
			var dob:DisplayObject = adob.pop();
			if (adob.length == 0)
				delete s_dctPool[strUrl];
			return dob;
		}
		
		static public function Clear(): void {
			s_dctPool = {};
		}
	}
}
