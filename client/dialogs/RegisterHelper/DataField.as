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
package dialogs.RegisterHelper
{
	import mx.validators.Validator;
	
	public class DataField
	{
		[Bindable] public var name:String = "";
		[Bindable] public var validator:Validator = null;
		[Bindable] public var def_value:* = "";		// optional; use to reset value to something other than ""
		[Bindable] public var source:Object = null;			// optional; use if validator is not set
		[Bindable] public var source_field:String = null;	// optional; use if validator is not set
		
		private var _fValueSet:Boolean = false;
		
		private var _obValue:Object = null;
		public function set value(obValue:Object): void {
			_obValue = obValue;
			_fValueSet = true;
		}
		
		public function get value(): Object {
			if (_fValueSet)
				return _obValue;
			else if (validator != null && validator.source != null && validator.property != null)
				return validator.source[validator.property];
			else if (source != null && source_field != null)
				return source[source_field];
			return null;
		}
		
		public function getSource():Object {
			if (validator != null && validator.source != null)
				return validator.source;
			else if (source != null)
				return source;
			return null;
		}
	}
}