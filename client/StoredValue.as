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
package
{
	public class StoredValue
	{
		private var _strTarget:String = null;
		private var _obValue:Object = null;
		private var _fHasInitialValue:Boolean = true;

		public static const kstrUninitialized:String = "This object has not been initialized 0x3214";

		// Static helpers
		public static function readValues(asv:Array, obOwner:Object): void {
			for each (var sv:StoredValue in asv) {
				sv.readValue(obOwner);
			}
		}
		
		public static function valuesChanged(asv:Array, obOwner:Object): Boolean {
			for each (var sv:StoredValue in asv) {
				if (sv.valueChanged(obOwner)) {
					return true;
				}
			}
			return false;
		}
		
		public static function readUninitializedValues(asv:Array, obOwner:Object): void {
			for each (var sv:StoredValue in asv) {
				if (!sv.hasInitialValue()) sv.readValue(obOwner);
			}
		}
		
		public static function applyValues(asv:Array, obOwner:Object): void {
			for each (var sv:StoredValue in asv) {
				sv.applyValue(obOwner);
			}
		}
		
		// Methods
		public function StoredValue(): void {
			_obValue = kstrUninitialized;
		}
		
		public function hasInitialValue(): Boolean {
			if (_obValue === kstrUninitialized) _fHasInitialValue = false;
			return _fHasInitialValue;
		}
		
		public function set target(strTarget:String): void {
			_strTarget = strTarget;
		}
		
		public function get target(): String {
			return _strTarget;
		}
		
		public function set value(obValue:Object): void {
			_obValue = obValue;
		}
		
		public function get value(): Object {
			return _obValue;
		}
		
		public function readValue(obOwner:Object): void {
			value = getValue(obOwner, target);
		}
		
		// Returns true if the objects are equal or very close to equal (off by 1/10th of a percent for Numbers)
		public function virtuallyEqual(ob1:Object, ob2:Object): Boolean {
			const knPctDiffThreshold:Number = 0.001;
			if (ob1 is Number && ob2 is Number) {
				var n1:Number = ob1 as Number;
				var n2:Number = ob2 as Number;
				if (n1 == n2) return true;
				var nPctDiff:Number = 2 * Math.abs(n1 - n2) / (n1 + n2); // Percentage diff
				if (nPctDiff < knPctDiffThreshold) return true;
				else return false;
			} else {
				return ob1 == ob2;
			}
		}
		
		public function valueChanged(obOwner:Object): Boolean {
			var obNewVal:Object = getValue(obOwner, target);
			if (value is Array && obNewVal is Array) {
				var aobVals:Array = value as Array;
				var aobNewVals:Array = obNewVal as Array;
				if (aobVals.length != aobNewVals.length) return true;
				for (var i:Number = 0; i < aobVals.length; i++) {
					if (!virtuallyEqual(aobVals[i], aobNewVals[i])) return true;
				}
				return false;
			} else {
				return !virtuallyEqual(value, obNewVal);
			}
		}
		
		public function applyValue(obOwner:Object): void {
			setValue(obOwner, target, value);
		}

		public function setValue(obOwner:Object, strTarget:String, obValue:Object): void {
			// Set the owner.target to a value
			RecursiveSetProperty(strTarget, obValue, obOwner);
		}

		public function getValue(obOwner:Object, strTarget:String): Object {
			// Get the owner.target value
			return RecursiveGetProperty(strTarget, obOwner);
		}
		
		// UNDONE: This code is very similar to the code in Overlay.as
		// We should merge them together (perahps use this code instead of the Overlay code?)
		
		// Support recursive reset properties, like "_sldr.value"
		protected function RecursiveSetProperty(strName:String, obValue:Object, obOwner:Object): void {
			var iBreakPos:Number = strName.lastIndexOf(".");
			if (iBreakPos == -1) {
				if (obValue is Array)
					obValue = (obValue as Array).slice();
				obOwner[strName] = obValue;
			} else {
				var strObjectName:String;
				var strPropName:String;
				strObjectName = strName.substr(0, iBreakPos);
				strPropName = strName.substr(iBreakPos+1);
				var obOwner:Object = RecursiveGetProperty(strObjectName, obOwner);
				obOwner[strPropName] = obValue;
			}
		}
		
		// Support recursive reset properties, like "_sldr.value"
		protected function RecursiveGetProperty(strName:String, obOwner:Object): Object {
			var iBreakPos:Number = strName.indexOf(".");
			var strThisName:String;
			var strRestName:String;
			if (iBreakPos >= 0) {
				strThisName = strName.substr(0, iBreakPos);
				strRestName = strName.substr(iBreakPos+1);
			} else {
				strThisName = strName;
				strRestName = null;
			}
			
			var obFirstResult:Object;
			if (obOwner == null) {
				Debug.Assert(false, "obOwner is required for calls to RecursiveGetProperty");
			} else {
				obFirstResult = obOwner[strThisName];
				if (obFirstResult is Array)
					obFirstResult = (obFirstResult as Array).slice();
			}
			if (strRestName == null) {
				return obFirstResult;
			} else {
				return RecursiveGetProperty(strRestName, obFirstResult);
			}
		}
	}
}