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
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.controls.CheckBox;
	import mx.controls.ComboBox;
	import mx.controls.RadioButtonGroup;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	
	public class DataModel extends ArrayCollection
	{
		private var _fHasFieldErrors:Boolean = false;

		public function DataModel() {
		}
		
		public function Init(): void {
			for (var i:Number = 0; i < this.length; i++) {
				var dtf:DataField = this[i] as DataField;
				if (dtf && dtf.validator != null) {
					var uicSource:UIComponent = dtf.validator.source as UIComponent;
					if (uicSource != null) {
						uicSource.removeEventListener("errorStringChanged", OnValidChange);
						uicSource.addEventListener("errorStringChanged", OnValidChange);
					}
				}
			}
		}
		
		// Remove any errors on empty input fields
		public function ClearErrors(): void {
			for (var i:Number = 0; i < this.length; i++) {
				var dtf:DataField = this[i] as DataField;
				if (dtf && dtf.validator != null && dtf.validator.source != null && (dtf.value == null || dtf.value == "")) {
					var uicSource:UIComponent = dtf.validator.source as UIComponent;
					if (uicSource != null) {
						uicSource.errorString = "";
					}
				}
			}
		}
		
		// Lookup a field by name
		// Returns null if not found
		public function GetField(strFieldName:String): DataField {
			var dtf:DataField = null;
			for (var i:Number = 0; i < this.length; i++) {
				dtf = this[i] as DataField;
				if (dtf && dtf.name == strFieldName) {
					return dtf;
				}
			}
			return null;
		}
		
		// Return the value of a field by name
		// Returns null if not found.
		public function GetValue(strFieldName:String): Object {
			var dtf:DataField = GetField(strFieldName);
			if (dtf)
				return dtf.value;
			return null;
		}
		
		// Return the value of a field by name
		// Returns null if not found.
		public function SetValue(strFieldName:String, value:*): void {
			var dtf:DataField = GetField(strFieldName);
			if (dtf) {
				var source:Object = null;
				if (dtf && dtf.validator != null) {
					source = dtf.validator.source;
				} else {
					source = dtf.source;
				}
				
				if (source) {				
					var tiSource:TextInput = source as TextInput;
					var cbSource:CheckBox = source as CheckBox;
					var cboxSource:ComboBox = source as ComboBox;
					var rbgSource:RadioButtonGroup = source as RadioButtonGroup;
					
					if (tiSource) tiSource.text = String(value);
					if (cbSource) cbSource.selected = Boolean(value);
					if (cboxSource) cboxSource.selectedIndex = Number(value);
					if (rbgSource) rbgSource.selection = value;
					
					if (dtf && dtf.validator != null) {
						dtf.validator.validate(); // this will get rid of any happy checkboxes that are lingering on the form						
					}
				}
			}			
		}
		
		// set all the values at once
		public function SetValues(obParams:Object): void {	
			for (var param:String in obParams) {
				SetValue( param, obParams[param] );
			}
		}
		
		// set all the defaults at once
		public function SetDefaults(obParams:Object): void {	
			for (var param:String in obParams) {
				var df:DataField = GetField( param );
				if (df) df.def_value = obParams[param];
			}
		}		
		
		// get all the values at once
		public function GetValues(): Object {	
			var dtf:DataField = null;
			var obValues:Object = {};
			for (var i:Number = 0; i < this.length; i++) {
				dtf = this[i] as DataField;
				if (dtf) {
					obValues[dtf.name] = dtf.value;
				}
			}
			return obValues;
		}		
		
		
		protected function OnValidChange(evt:Event): void {
			UpdateHasFieldErrors();
		}
		
		public function GetFieldsWithErrors(): Array {
			var astrFields:Array = [];
			for (var i:Number = 0; i < this.length; i++) {
				var dtf:DataField = this[i] as DataField;
				if (dtf && dtf.validator != null) {
					if (dtf.validator.source is UIComponent) {
						var strError:String = (dtf.validator.source as UIComponent).errorString;
						if (strError && strError.length > 0) {
							astrFields.push(dtf.name);
						}
					}
				}
			}
			return astrFields;
		}
		
		protected function UpdateHasFieldErrors(): void {
			var fHasFieldErrors:Boolean = false;
			for (var i:Number = 0; i < this.length; i++) {
				var dtf:DataField = this[i] as DataField;
				if (dtf && dtf.validator != null) {
					if (dtf.validator.source is UIComponent) {
						var strError:String = (dtf.validator.source as UIComponent).errorString;
						if (strError && strError.length > 0) {
							fHasFieldErrors = true;
						}
					}
				}
			}
			hasFieldErrors = fHasFieldErrors;
		}
		
		[Bindable (event="validChanged")]
		public function get hasFieldErrors(): Boolean {
			return _fHasFieldErrors;
		}
		public function set hasFieldErrors(fHasFieldErrors:Boolean): void {
			if (_fHasFieldErrors != fHasFieldErrors) {
				_fHasFieldErrors = fHasFieldErrors;
				dispatchEvent(new Event("validChanged"));
			}
		}
		public function validateAll(): Boolean {
			hasFieldErrors = false;
			for (var i:Number = 0; i < this.length; i++) {
				var dtf:DataField = this[i] as DataField;
				if (dtf && dtf.validator != null) {
					dtf.validator.validate();
				}
			}
			UpdateHasFieldErrors();
			return !hasFieldErrors;
		}
		
		public function validateOne(strField:String):void {
			for (var i:Number = 0; i < this.length; i++) {
				var dtf:DataField = this[i] as DataField;
				if (dtf && dtf.name == strField && dtf.validator != null) {
					dtf.validator.validate();
					break;
				}
			}
		}
		
		public function resetAll(): void {
			for (var i:Number = 0; i < this.length; i++) {
				var dtf:DataField = this[i] as DataField;
				SetValue( dtf.name, dtf.def_value );
			}
			ClearErrors();
		}
	}
}