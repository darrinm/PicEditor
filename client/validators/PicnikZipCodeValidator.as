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
	import mx.validators.ValidationResult;
	import mx.validators.ZipCodeValidator;
	
	public class PicnikZipCodeValidator extends mx.validators.ZipCodeValidator
	{
		private var _aLocalizedKeys:Object = {
							"invalidDomainError": "invalidDomainErrorZCV",
							"invalidCharError": "invalidCharErrorZCV",
							"wrongCAFormatError": "wrongCAFormatError",
							"wrongLengthError": "wrongLengthErrorZCV",
							"wrongUSFormatError": "wrongUSFormatError" };
		
		[ResourceBundle("validators")] static protected var _rb:ResourceBundle;  		
		  		
		public function PicnikZipCodeValidator():void {
			if (!_fLocalized) _Localize();
		}
		
		// Set to true to validate the length only
		[Bindable] public var USOrCanda:Boolean = true;

		private var _fLocalized:Boolean = false;
		private function _Localize() : void {
			_fLocalized = true;
			for (var i:String in _aLocalizedKeys) {
				this[i] = Resource.getString("validators", _aLocalizedKeys[i]);
			}
		}

	    override protected function doValidation(value:Object):Array
	    {
	    	if (USOrCanda) {
		        return super.doValidation(value);
	    	} else {
	    		// Non US/CA postal code validation
		        var results:Array = [];
		       
		        var result:ValidationResult = validateRequired(value);
		        if (result)
		            results.push(result);
		           
		        return results;
		    }
	    }

		// Copied from private Validator function
	    private static function trimString(str:String):String
	    {
	        var startIndex:int = 0;
	        while (str.indexOf(' ', startIndex) == startIndex)
	        {
	            ++startIndex;
	        }
	
	        var endIndex:int = str.length - 1;
	        while (str.lastIndexOf(' ', endIndex) == endIndex)
	        {
	            --endIndex;
	        }
	
	        return endIndex >= startIndex ?
	               str.slice(startIndex, endIndex + 1) :
	               "";
	    }

		// Copied from private Validator function
	    private function validateRequired(value:Object):ValidationResult
	    {
	        if (required)
	        {
	            var val:String = (value != null) ? String(value) : "";
	
	            val = trimString(val);
	
	            // If the string is empty and required is set to true
	            // then throw a requiredFieldError.
	            if (val.length == 0)
	            {
	                return new ValidationResult(true, "", "requiredField",
	                                            requiredFieldError);                
	            }
	        }
	       
	        return null;
	    }

	}
}