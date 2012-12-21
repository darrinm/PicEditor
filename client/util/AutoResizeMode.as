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
package util
{
	public class AutoResizeMode
	{
		public static const ARCHIVAL:String = "archival";
		public static const PRINT:String = "print";
		public static const SCREEN:String = "screen";
		public static const WEB:String = "web";
		
		private static var _obModeToAreaMap:Object = null;
		
		public static function get modeToAreaMap(): Object {
			if (_obModeToAreaMap == null) {
				_obModeToAreaMap = {};
				// Area goes down roughly by 1/3 for each step
				_obModeToAreaMap[AutoResizeMode.ARCHIVAL] = Number.MAX_VALUE; // 4000 * 4000 for flash 10
				_obModeToAreaMap[AutoResizeMode.PRINT] = 2800 * 2800 * 2 / 3;
				_obModeToAreaMap[AutoResizeMode.SCREEN] = 1600 * 1200;
				_obModeToAreaMap[AutoResizeMode.WEB] = 800 * 800;
				
			}
			return _obModeToAreaMap;
		}
			
		public function AutoResizeMode()
		{
		}

	}
}