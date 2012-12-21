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
	
	public class LoginEvent extends Event {
		public static const LOGIN_COMPLETE:String = "loginComplete";
		public static const LOGOUT_COMPLETE:String = "logoutComplete";
		public static const RESTORE_COMPLETE:String = "restoreComplete";
		public static const CREDENTIALS_CHANGED:String = "credentialsChanged";
		
		private var _fSuccess:Boolean;
		
		public function LoginEvent(type:String, fSuccess:Boolean=true) {
			super(type, false, true);
			_fSuccess = fSuccess;
		}
		
		public function get success(): Boolean {
			return _fSuccess;
		}
		
		// Override the inherited clone() method
		override public function clone(): Event {
			return new LoginEvent(type, _fSuccess);
		}
	}
}
