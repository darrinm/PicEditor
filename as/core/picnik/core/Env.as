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
	public class Env
	{
		public function Env()
		{
		}
		
		private static var _ienv:IEnvironment = null;
		
		public static function GetInst(): IEnvironment {
			return inst;
		}
		
		public static function get inst(): IEnvironment {
			if (_ienv == null) _ienv = new EmptyEnvironment();
			return _ienv;
		}
		
		public static function set inst(ienv:IEnvironment): void {
			_ienv = ienv;
		}
		
		// TODO:
		// Add ability to test for dummy/real environment
		// Add ability to pass a callback for enviornment changes (especially from dummy to real)
		// Add ability to pass a callback for doing something once the environment has been set up?
	}
}