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
	public class NextNavigationTracker
	{
		private static var _nntInstance:NextNavigationTracker = new NextNavigationTracker();
		
		private var _afnListeners:Array = [];
		
		public function NextNavigationTracker()
		{
		}
		
		// fnOnClick = function(strTarget:String): void;
		public static function RegisterListener(fnOnClick:Function): void {
			_nntInstance._RegisterListener(fnOnClick);
		}
		
		// Called when the user clicks on something.
		// Examples include:
		//  - /tab/out/download
		//  - /post_save/start_printing
		public static function OnClick(strTarget:String): void {
			_nntInstance._OnClick(strTarget);
		}
		
		public function _RegisterListener(fnOnClick:Function): void {
			_afnListeners.push(fnOnClick);
		}
		
		private function _OnClick(strTarget:String): void {
			if (strTarget.length > 0 && strTarget.charAt(0) != '/')
				strTarget = '/' + strTarget;
			while (_afnListeners.length > 0) {
				var fn:Function = _afnListeners.pop();
				fn(strTarget);
			}
		}
	}
}