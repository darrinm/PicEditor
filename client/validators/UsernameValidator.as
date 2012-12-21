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
	import util.PicnikDict;
	import util.UsernameDictionary;
		
	public class UsernameValidator extends DictValidator
	{
  		override protected function get resourceList(): Array {
  			return super.resourceList.concat(["userExistsError", "userDoesNotExistsError", "userNameTooShort", "invalidUsernameCharactersError"]);
  		}
		
		[CollapseWhiteSpace]
		[Inspectable(category="Errors", defaultValue="We already have a user with this username.")]
		public var userExistsError:String;

	    [CollapseWhiteSpace]
		[Inspectable(category="Errors", defaultValue="There are no users with this username.")]
		public var userDoesNotExistsError:String;

		[Inspectable(category="Errors", defaultValue="Your user name is too short. Please enter at least two characters.")]
		public var userNameTooShort:String;
		
		[CollapseWhiteSpace]
		[Inspectable(category="Errors", defaultValue="Please sign in with Google to access this account.")] // Not localized. Override this message in mxml
		public var googleUserCollisionError:String;

		public var invalidUsernameCharactersError:String;

		public var minLength:Number = 2;

		public override function get dict(): PicnikDict {
			return UsernameDictionary.global;
		}
		
		public override function get missingFromDictError(): String {
			return userDoesNotExistsError;
		}
		
		public override function get presentButSpecialError(): String {
			return googleUserCollisionError; // User trying to log in with a Google + Picnik user
		}

		public override function get presentInDictError(): String {
			return userExistsError;
		}
		
/*		
		protected override function doValidation(value:Object): Array {
			var aResults:Array = super.doValidation(value);
			
			// Return if there are errors
			// or if the required property is set to false and length is 0.
			var strName:String = value ? String(value) : "";
			// Do our own validation only if parent returns valid
			if (aResults.length == 0 && strName.length > 0)
			{
				if (strName.length < minLength) {
					aResults.push(new ValidationResult(true, null, "userNameTooShort", userNameTooShort));
				}
			}
			return aResults;
		}
*/
	}
}