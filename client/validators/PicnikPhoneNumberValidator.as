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
package validators
{
	// This file contains validators which are here just because we need to create
	// localized versions of their output strings.  No other functionality is changed
	// from the base classes.
	// You should change the code that uses validators to look for validators.ValidatorName
	// instead of mx.ValidatorName
	
	import mx.resources.ResourceBundle;	
	import mx.validators.PhoneNumberValidator;
	
	public class PicnikPhoneNumberValidator extends mx.validators.PhoneNumberValidator
	{
		private var _aLocalizedKeys:Object = {
							"invalidCharError": "invalidCharErrorPNV",
							"wrongLengthError": "wrongLengthErrorPNV" };
		
		[ResourceBundle("validators")] static protected var _rb:ResourceBundle;  		
		  		
		public function PicnikPhoneNumberValidator():void {
			if (!_fLocalized) _Localize();
		}
			
		private var _fLocalized:Boolean = false;
		private function _Localize() : void {
			_fLocalized = true;
			for (var i:String in _aLocalizedKeys) {
				this[i] = Resource.getString("validators", _aLocalizedKeys[i]);
			}
		}
	}
}