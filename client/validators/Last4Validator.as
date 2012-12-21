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
	import mx.validators.ValidationResult;
	
	import util.PicnikDict;
	import util.UsernameDictionary;

	// This class is used to validate the contents of a field containing the last 4 digits of a credit card.
	// Initially, all it can do is test against a regular expression to see if the input has 4 digits.
	// The application can later set the last4Invalid property on this validator to indicate that validation
	// failed for a particular combination of input values, and clear it if those input values change.
	public class Last4Validator extends mx.validators.RegExpValidator
	{
		private var last4RejectedByServerString:String;
		private var last4RejectedByServerFlag:Boolean;

		public function Last4Validator() {
			this.expression = "[0-9]\{4\}";
			this.last4RejectedByServerString = "does not match default value";
			this.last4RejectedByServerFlag = false;
		}

		public function get last4RejectedByServerError():String
		{
			return this.last4RejectedByServerString;
		}
	
		public function set last4RejectedByServerError(value:String):void
		{
			this.last4RejectedByServerString = value;
		}
		
		public function get last4RejectedByServer() : Boolean
		{
			return this.last4RejectedByServerFlag;
		}
		
		public function set last4RejectedByServer(value:Boolean) : void
		{
			this.last4RejectedByServerFlag = value;
		}
		
		protected override function doValidation(obValue:Object) : Array {
			var results:Array = [];
			
			if (this.last4RejectedByServer) {
				results.push(new ValidationResult(true, null, "last4RejectedByServer", this.last4RejectedByServerError));
			}
			else {
				results = super.doValidation(obValue);
			}
			
			return results;
		}
	}
}