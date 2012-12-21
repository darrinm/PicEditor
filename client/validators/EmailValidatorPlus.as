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
	import util.UserEmailDictionary;
	import util.PicnikDict;
	import mx.validators.ValidationResult;
	import mx.resources.ResourceBundle;

	public class EmailValidatorPlus extends DictValidator
	{
  		override protected function get resourceList(): Array {
  			return super.resourceList.concat(["emailExistsError", "emailDoesNotExistsError"]);
  		}

	    [CollapseWhiteSpace]
		[Inspectable(category="Errors", defaultValue="We already have a user with this email address.")]
		public var emailExistsError:String;

	    [CollapseWhiteSpace]
		[Inspectable(category="Errors", defaultValue="There are no users with this email address.")]
		public var emailDoesNotExistsError:String;
		
		// Set this to override any fancy invalid email address strings (e.g. "there must be an @ symbol"
	    [CollapseWhiteSpace]
		[Inspectable(category="Errors")]
		public var charError:String = null;

		// Looking for an unused email but found a special one
		// (e.g. a Picnik + Google account, Picnik creds are deprecated)
		[CollapseWhiteSpace]
		[Inspectable(category="Errors", defaultValue="Error. Known Google account.")] // Define localized value in mxml
		public var emailExistsAndIsSpecialError:String;
	
		// Looking for a regular email but got a special one instead
		// (e.g. a Picnik + Google account, Picnik creds are deprecated)
		[CollapseWhiteSpace]
		[Inspectable(category="Errors", defaultValue="Error. Sign in with Google.")] // Define localized value in mxml
		public var emailExistsButIsSpecialError:String;
		
		protected override function CleanInvalidCharErrors(aErrors:Array):Array {
			if (aErrors.length > 0 && charError != null) {
				aErrors = [];
				aErrors.push(new ValidationResult(true, null, "invalidChar", charError));
			}
			return aErrors;
		}
		
		public override function get dict(): PicnikDict {
			return UserEmailDictionary.global;
		}
		
		public override function get missingFromDictError(): String {
			return emailDoesNotExistsError;
		}

		public override function get presentInDictError(): String {
			return emailExistsError;
		}
		
		public override function get presentAndSpecialError():String {
			// Looking for an unused email but found a special one
			// (e.g. a Picnik + Google account, Picnik creds are deprecated)
			return emailExistsAndIsSpecialError;
		}

		public override function get presentButSpecialError():String {
			// Looking for a regular email but got a special one instead
			// (e.g. a Picnik + Google account, Picnik creds are deprecated)
			return emailExistsButIsSpecialError;
		}
	}
}