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
package util
{
	import flash.events.EventDispatcher;
	import flash.net.SharedObject;

	public class LocalSession
	{
		private var _obState:Object = {};

		public function LocalSession()
		{
		}
		
		public function setValue(strName:String, objData:Object):void {
			_obState[strName] = objData;
		}

		public function clearValue(strName:String): void {
			delete _obState[strName];
		}
		
		public function getValues(regex:RegExp):Object
		{
			var obRet:Object = {};
			for (var k:String in _obState) {
				if (k.match(regex)) {
					obRet[k] = _obState[k];
				}
			}
			return obRet;
		}
		
		public function getValue(strName:String):Object
		{
			return _obState[strName];
		}

		public function flush():String {
			return "OK";
		}
		
		public function initSO(strName:String, strSORoot:String): SharedObject {
			return null;
		}
	}
}