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
	
	public interface IEnvironment
	{
		function get IsDebug(): Boolean;
		function LogError(strMessage:String, dctParams:Object=null, fnDone:Function=null, fForceLog:Boolean=false): Boolean;
		function LogWarning(strMessage:String, dctParams:Object=null, fnDone:Function=null, fForceLog:Boolean=false): Boolean;
		function get app(): DisplayObject; // Might be an application (e.g. PicnikBase), mignt not. Will be a display object or null
		function get locale(): String; // E.g. "en_US" (should be default)
	}
}