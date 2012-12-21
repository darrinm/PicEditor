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
	import flash.events.Event;

	public class ModulePreloadEvent extends Event {
		static public var COMPLETE:String = "modulePreloadComplete";

		private var _url:String;

		public function ModulePreloadEvent(type:String, url:String, bubbles:Boolean = false,
										   cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
			_url = url;
		}

		public function get url() : String {
			return _url;
		}
	}
}
