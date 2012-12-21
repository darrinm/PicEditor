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
package picnik.core
{
	import flash.display.DisplayObject;
	
	public class EmptyEnvironment implements IEnvironment
	{
		public function EmptyEnvironment()
		{
		}

		public function get IsDebug():Boolean
		{
			return false;
		}
		
		public function LogError(strMessage:String, dctParams:Object=null, fnDone:Function=null, fForceLog:Boolean=false):Boolean
		{
			return false;
		}
		
		public function LogWarning(strMessage:String, dctParams:Object=null, fnDone:Function=null, fForceLog:Boolean=false):Boolean
		{
			return false;
		}
		
		// Might be an application (e.g. PicnikBase), mignt not. Will be a display object or null
		public function get app(): DisplayObject {
			return null;
		}
		
		public function get locale(): String {
			return "en_US";
		}
	}
}