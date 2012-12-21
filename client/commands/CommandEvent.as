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
	import flash.events.Event;

	public class CommandEvent extends Event {
		public static const BEFORE_EXECUTE:String = "beforeExecute";
		public static const EXECUTE_COMPLETE:String = "executeComplete";
		
		private var _fCanceled:Boolean = false;
		
		public function CommandEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}
		
		override public function preventDefault(): void {
			_fCanceled = true;
		}
		
		public function get canceled(): Boolean {
			return _fCanceled;
		}
	}
}
