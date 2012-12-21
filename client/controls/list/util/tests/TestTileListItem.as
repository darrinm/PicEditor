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
package controls.list.util.tests
{
	import controls.list.ITileListItem;
	
	import mx.core.UIComponent;

	public class TestTileListItem extends UIComponent implements ITileListItem
	{
		public function TestTileListItem(obData:Object) {
			super();
			data = obData;
			initialData = obData;
		}
		
		public var initialData:Object;
		
		public function set highlighted(f:Boolean):void {
		}
		
		public function get highlighted(): Boolean {
			return false;
		}
		
		public override function toString(): String {
			return "TestTileListItem[" + initialData + ", " + data + "]: " + super.toString();
		}
		
		public function set selected(f:Boolean):void {
		}
		
		public function get selected(): Boolean {
			return false;
		}
		
		public function setState(fHighlighted:Boolean, fSelected:Boolean, fEnabled:Boolean): void {
		}
		
		public function isLoaded(): Boolean {
			return false;
		}
		
		private var _obData:Object = null;
		
		public function get data():Object {
			return _obData;
		}
		
		public function set data(value:Object): void {
			_obData = value;
		}
	}
}
