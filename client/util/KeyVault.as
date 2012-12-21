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
	
	// KeyVault.as gives us a central place to store keys
	// that we've received from external parties
	
	public dynamic class KeyVault extends SafeGetObject {		

		private static var s_instance:KeyVault = null;	// singletonia!

		public static function GetInstance(): KeyVault {
			if (!s_instance) {
				s_instance = new KeyVault;
			}
			return s_instance;
		}

		public function AddKey( strKey:String, strValue:String): void {
			// split the key on "." to create subobjects.  That means if
			// someone gives us a key that looks like "partner.pub", they'll
			// bet able to access it from us like "<thisobject>.partner.pub"
			var aKeys:Array = strKey.split(".");
			var obj:Object = this;
			for (var i:Number = 0; i < aKeys.length-1; i++) {
				if (!(aKeys[i] in obj)) {
					obj[aKeys[i]] = new SafeGetObject();
				}
				obj = obj[aKeys[i]];
			}
			obj[aKeys[aKeys.length-1]] = strValue;
		}				
	}
}
