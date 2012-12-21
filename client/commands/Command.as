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
package commands {
	import flash.events.EventDispatcher;
	
	public class Command extends EventDispatcher {
		private var _strName:String;
		private var _fnHandler:Function;
		
		public function Command(strName:String, fnHandler:Function) {
			_strName = strName;
			_fnHandler = fnHandler;
		}
		
		public function get name(): String {
			return _strName;
		}
		
		public function Execute(): void {
			if (hasEventListener(CommandEvent.BEFORE_EXECUTE)) {
				var evt:CommandEvent = new CommandEvent(CommandEvent.BEFORE_EXECUTE, false, true);
				dispatchEvent(evt);
				if (evt.canceled)
					return;
			}
			_fnHandler();
		}
	}
}
