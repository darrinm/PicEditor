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
package util {
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
		
	// SafeGetObject.as returns a default value for any
	// directly accessed members instead of faulting!
	//
	// eg. 
	//	var sgoThing:SafeGetObject = new SafeGetObject( "" );
	//	sgoThing['one'] = "one";
	//	print sgoThing.one;	// "one"
	//  print sgoThing.two; // ""
	//
	
	public dynamic class SafeGetObject extends Proxy {		

		private var _strDefault:String = "";
		private var _aKeys:Array = [];

		public function SafeGetObject( strDef:String = "" ) {
			_strDefault = strDef;
		}
				
		public function toString():String {
			return _strDefault;
		}
				
		public function valueOf():Object {
			if (_aKeys.length) return _aKeys;
			return null;
		}
				
		override flash_proxy function getProperty( name:* ):*
		{
			if (name.toString() in _aKeys) return _aKeys[name];
			return new SafeGetObject(_strDefault);
		}
   		
		override flash_proxy function setProperty( name:*, value:* ):void {
			_aKeys[name.toString()] = value;
		}
		
		override flash_proxy function deleteProperty( name:* ):Boolean {
			if (name.toString() in _aKeys) {
				delete _aKeys[name.toString()];	
				return true;
			}
			return false;			
		} 
    				
		override flash_proxy function hasProperty( name:* ):Boolean {
			if (name.toString() in _aKeys) return true;
			return false;
		}
	}
}
