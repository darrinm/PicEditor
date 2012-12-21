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

	public class EqualToValidator extends PicnikValidator
	{
  		override protected function get resourceList(): Array {
  			return super.resourceList.concat(["valuesNotEqual"]);
  		}
 		
		[Inspectable(category="Errors", defaultValue="The values are not equal.")]
		public var valuesNotEqual:String;

		public function EqualToValidator() {
			triggerEvent = Event.CHANGE;
		}

		private var _obEqualTo:Object = null;

		public function set equalTo(obEqualTo:Object): void {
			_obEqualTo = obEqualTo;
			if (enabled && source && source is UIComponent)
			{
				var obValue:Object = getValueFromSource();
				if (!IsNullOrEmptyString(obValue)) {
					(source as UIComponent).validationResultHandler(handleResults(validateIsEqual(obValue)));
				}
			}
		}
		
		protected function IsNullOrEmptyString(ob:Object): Boolean {
			return ob == null || (ob as String) == null || (ob as String).length == 0;
		}
		
		// Validates that the obValue is equal to obEqualTo or either one is null
		protected function validateIsEqual(obValue:Object): Array {
			var aResults:Array = [];
			if (!EqualsOrIsNullOrEmtpy(obValue, _obEqualTo))
				aResults.push(new ValidationResult(true, null, "valuesNotEqual", valuesNotEqual));
			return aResults;
		}
		
		protected function EqualsOrIsNullOrEmtpy(obValue1:Object, obValue2:Object): Boolean {
			if (IsNullOrEmptyString(obValue1)) return true;
			if (IsNullOrEmptyString(obValue2)) return true;
			return obValue1 == obValue2;
		}

		protected override function doValidation(value:Object): Array {
			var aResults:Array = super.doValidation(value);
			
			// Do our own validation of the parent finds no problems
			if (aResults.length == 0)
				aResults = validateIsEqual(value);

			return aResults;
		}
	}
}