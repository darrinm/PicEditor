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
package util {
	public class UniversalTime {
		private static var s_dsec:Number;
		
		public static function Init(csec:Number): void {
			// Remember the delta between what the client and server thinks the time is
			s_dsec = csec - Math.floor(new Date().valueOf() / 1000);
		}

		// Return the UTC time in seconds since the 1970 epoch
		public static function get seconds(): Number {
			return Math.floor(new Date().valueOf() / 1000) + s_dsec;
		}
	}
}
