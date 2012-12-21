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
	import flash.events.Event;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.validators.ValidationResult;
	import mx.validators.Validator;
	
	import util.PicnikDict;

	public class DictValidator extends PicnikValidator
	{
		public var validateCharacters:Boolean = true;

		protected var _fDeepLookup:Boolean = false;

		public static const IGNORE:String = "ignore";
		public static const REQUIRE:String = "require";
		public static const PROHIBIT:String = "prohibit";
		
		private var _strDictCheck:String = IGNORE;
		private var _nPrevValid:Number = -1; // Number of validation errors last time we checked.

	    [Bindable("dictCheckChanged")]
	    [Inspectable(category="General", enumeration="ignore,require,prohibit", defaultValue="ignore")]
	    public function get dictCheck():String {
	        return _strDictCheck;
	    }
	    public function set dictCheck(str:String):void {
	    	_strDictCheck = str;
	        dispatchEvent(new Event("dictCheckChanged"));
	    }
	   
	    // Set this to any "bonus" values which are always valid. Default, null, means there are no exeptions
	    private var _strAlsoValid:String = null;
	    [Bindable]
	    public function set alsoValid(strAlsoValid:String):void {
	    	_strAlsoValid = strAlsoValid;
	    	// Something changed. Make sure everything is still valid
	    	OnDictChange(null);
	    }
	   
	    public function get alsoValid():String {
	    	return _strAlsoValid;
	    }
	   
	    // Returns true if the value was confirmed in the dictionary (state is known and desired)
	    // Returns false if the value has changed since we last did a deep check
	    [Bindable] public var passedDeepValidation:Boolean;
	   
		/**** BEGIN: Override these in sub-classes ****/
		public function get dict(): PicnikDict {
			return null;
		}
		
		public function get missingFromDictError(): String {
			return null;
		}

		public function get presentInDictError(): String {
			return null;
		}
		
		public function get presentAndSpecialError(): String {
			// Already exists. Plus, it has special status.
			return presentInDictError; // Default is the same as present error
		}
		
		public function get presentButSpecialError(): String {
			// We are looking for a "normal" entry but found a "special" entry instead.
			// Definition of normal and special is up to the sub-class. In the case of username validator,
			// normal is Picnik creds, special is Picnik + Google creds (picnik creds don't actually work).
			return missingFromDictError; // Default is the same as missing error
		}
		
		/**** END: Override these in sub-classes ****/
		
		public function DictValidator() {
			triggerEvent = Event.CHANGE; // React to chang events, but only do deep lookups on commit events
			AddChangeListeners();
		}
		
		protected function AddChangeListeners(): void {
			ListenForDictChange(dict);
		}
		
		// Override in sub-classes that wish to change the validation errors returned by the dictionary
		protected function CleanInvalidCharErrors(aErrors:Array): Array {
			return aErrors;
		}
		
		// Override this for custom dictionary behavior (e.g. ignore guest users)
		protected function LookupStateInDict(strVal:String, fDeepLookup:Boolean): Number {
			return dict.LookupState(strVal, fDeepLookup);
		}
		
	    protected function dictValidate(strVal:String, fCheckChars:Boolean = true): Array {
			var aResults:Array = [];
			// First, check for illegal characters
	    	if (fCheckChars && validateCharacters) {
	    		aResults = CleanInvalidCharErrors(dict.ValidateChars(strVal));
	    	}
	    	// Don't bother checking if we have invalid characters
    		if (aResults.length == 0) {
    			if (dictCheck != IGNORE && alsoValid != strVal) {
					var nState:Number = LookupStateInDict(strVal, _fDeepLookup);
					if (dictCheck == PROHIBIT) {
						if (nState == PicnikDict.knExists) {
							aResults.push(new ValidationResult(true, null, "inDict", presentInDictError));
						} else if (nState == PicnikDict.knExistsAndIsSpecial) {
							aResults.push(new ValidationResult(true, null, "inDictSpecial", presentAndSpecialError));
						}
					} else if (dictCheck == REQUIRE) {
						if (nState == PicnikDict.knDoesNotExist) {
							aResults.push(new ValidationResult(true, null, "notInDict", missingFromDictError));
						} else if (nState == PicnikDict.knExistsAndIsSpecial) {
							aResults.push(new ValidationResult(true, null, "inDictSpecial", presentButSpecialError));
						}
					}
					passedDeepValidation = (aResults.length == 0 && (nState == PicnikDict.knDoesNotExist || nState == PicnikDict.knExists));
    			}
    			else {
    				passedDeepValidation = true;
    			}
			} else {
   				passedDeepValidation = false;
			}
			_nPrevValid = aResults.length;
	    	return aResults;
	    }

		protected function OnDictChange(evt:Event): void {
			if (enabled && source && source is UIComponent)
	        {
	        	var obValue:Object = getValueFromSource();
				var strVal:String = obValue ? String(obValue) : "";
				if (strVal.length > 0) {
					var nPrevValid:Number = _nPrevValid;
					var aResults:Array = dictValidate(strVal, false);
					// Update the UI if we are invalid or valid and were previously invalid
					if (aResults.length > 0 || nPrevValid != _nPrevValid)
						(source as UIComponent).validationResultHandler(handleResults(aResults));
				}
	        }
		}
		
		protected function ListenForDictChange(dict:PicnikDict): void {
			dict.addEventListener(Event.CHANGE, OnDictChange);
		}

		protected function StopListeningForDictChange(dict:PicnikDict): void {
			dict.removeEventListener(Event.CHANGE, OnDictChange);
		}

		override protected function doValidation(obValue:Object):Array
	    {
			var aResults:Array = [];
			
			// Deep lookup does not do a shallow lookup (check required)
			if (!_fDeepLookup) aResults = super.doValidation(obValue);
			
			// Return if there are errors
			// or if the required property is set to false and length is 0.
			var strVal:String = obValue ? String(obValue) : "";
			if (aResults.length == 0 && strVal.length > 0) {
				aResults = dictValidate(strVal);
			} else {
				passedDeepValidation = false
			}
			return aResults;
		}

	    public override function set source(value:Object):void {
	        if (super.source == value)
	            return;
	        removeDeepTrigger();
	        super.source = value;
	        addDeepTrigger();
	    }
	   
	    protected function OnDeepTrigger(evt:FlexEvent): void {
	    	var fPrevVal:Boolean = _fDeepLookup;
	    	_fDeepLookup = true;
	    	OnDictChange(null);
	    	_fDeepLookup = fPrevVal;
	    }
	   
	    protected function removeDeepTrigger(): void {
	        if (actualTrigger)
	            actualTrigger.removeEventListener(FlexEvent.VALUE_COMMIT, OnDeepTrigger);
	    }

	    protected function addDeepTrigger(): void {
	        if (actualTrigger)
	            actualTrigger.addEventListener(FlexEvent.VALUE_COMMIT, OnDeepTrigger);
	    }
	}
}