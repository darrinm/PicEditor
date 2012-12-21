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

	public class RequiredTrueValidator extends PicnikValidator
	{
  		override protected function get resourceList(): Array {
  			return super.resourceList.concat(["valueNotTrue"]);
  		}

		[Inspectable(category="Errors", defaultValue="This option must be true.")]
		public var valueNotTrue:String;

		public function RequiredTrueValidator() {
			triggerEvent = Event.CHANGE;
		}
		
		private function validateIsTrue(value:*):Array {
			var aResults:Array = [];
			if (!value)
				aResults.push(new ValidationResult(true, null, "valueNotTrue", valueNotTrue));
			return aResults;
		}
		
		protected override function doValidation(value:Object): Array {
			var aResults:Array = super.doValidation(value);
			
			// Do our own validation of the parent finds no problems
			if (aResults.length == 0)
				aResults = validateIsTrue(value);

			return aResults;
		}
	}
}