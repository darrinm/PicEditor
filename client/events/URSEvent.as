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
package events {
	import flash.events.Event;
	
	// Undo, Redo, Save event.
	public class URSEvent extends Event {
		public static const BEFORE_HANDLING_URS:String = "beforeHandlingURS";
		
		private var _fCancel:Boolean = false;
		
		public function URSEvent(type:String, fCancel:Boolean = false) {
			super(type, false, true);
			_fCancel = fCancel;
		}
		
		public function get cancel(): Boolean {
			return _fCancel;
		}
		
		public function set cancel(fCancel:Boolean): void {
			_fCancel = fCancel;
		}
		
		// Override the inherited clone() method
		override public function clone(): Event {
			return new URSEvent(type, _fCancel);
		}
	}
}
