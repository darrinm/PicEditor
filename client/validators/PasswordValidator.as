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
	import mx.validators.Validator;
	import mx.validators.ValidationResult;
	import mx.core.UIComponent;
	import flash.events.Event;
	import mx.resources.ResourceBundle;

	public class PasswordValidator extends PicnikValidator
	{
  		override protected function get resourceList(): Array {
  			return super.resourceList.concat(["passwordTooCloseToUsername", "passwordTooShort"]);
  		}
 		
		[Inspectable(category="Errors", defaultValue="Your password is too short. Please enter at least five characters.")]
		public var passwordTooShort:String;

		[Inspectable(category="Errors", defaultValue="Your password is too close to your username.")]
		public var passwordTooCloseToUsername:String;

		private var _strUsername:String = null;
		public var minLength:Number = 5;

		public function PasswordValidator() {
			triggerEvent = Event.CHANGE;
		}

		public function set username(strUsername:String): void {
			_strUsername = strUsername;
			if (enabled && source && source is UIComponent)
			{
				var obValue:Object = getValueFromSource();
				var strVal:String = obValue ? String(obValue) : "";
				if (strVal.length > 0) {
					(source as UIComponent).validationResultHandler(handleResults(validatePassword(strVal)));
				}
			}
		}
		
		protected function validatePasswordCloseToUsername(strPassword: String): Array {
			var aResults:Array = [];
			if (_strUsername && strPassword && strPassword.length >= minLength) {
				if (PasswordIsTooClose(strPassword, _strUsername))
					aResults.push(new ValidationResult(true, null, "passwordTooCloseToUsername", passwordTooCloseToUsername));
			}
			return aResults;
		}
		
		// Returns true if the password is too close to the username
		// Currently, checks to see if the password is a subset of the username.
		protected function PasswordIsTooClose(strPassword:String, strUsername:String): Boolean {
			return (strUsername.toLowerCase().indexOf(strPassword.toLowerCase()) != -1);
		}
		
		protected function validatePassword(strPassword:String): Array {
			var aResults:Array = [];
			if (strPassword.length < minLength) {
				aResults.push(new ValidationResult(true, null, "passwordTooShort", passwordTooShort));
			} else {
				aResults = validatePasswordCloseToUsername(strPassword);
			}
			return aResults;
		}

		protected override function doValidation(value:Object): Array {
			var aResults:Array = super.doValidation(value);
			
			// Return if there are errors
			// or if the required property is set to false and length is 0.
			var strPassword:String = value ? String(value) : "";
			// Do our own validation only if parent returns valid
			if (aResults.length == 0 && strPassword.length > 0)
			{
				aResults = validatePassword(strPassword);
			}
			return aResults;
		}
	}
}