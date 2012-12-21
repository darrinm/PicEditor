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
package controls.itempicker
{
	import flash.display.DisplayObjectContainer;
	import mx.collections.ArrayCollection;
	import mx.controls.List;

	public class ItemSearchList extends List
	{
		[Bindable] public var itemPicker:ItemPickerBase;
		
		public function ItemSearchList()
		{
			super();
		}
		
		private var _strFilterText:String = "";
		private var _aPickedItems:Array = [];

		[Bindable]
		public function set filterText(strFilter:String): void {
			if (strFilter == null)
				strFilter = "";
			_strFilterText = strFilter;
			FilterArray();
		}
		
		public function get filterText():String {
			return _strFilterText;
		}
				
		public function SetPickedItems(aPickedItems:Array): void {
			if (aPickedItems == null)
				aPickedItems = [];
			_aPickedItems = aPickedItems;
			FilterArray();
		}
			
		private function FilterArray(): void {
			var acData:ArrayCollection = (dataProvider as ArrayCollection);
			if (acData) {
				acData.filterFunction = function (ob:Object): Boolean {
						if (!ob) return false;
						if (_aPickedItems.some( function(element:*,index:int,arr:Array):Boolean { return itemPicker.CompareItems(element,ob); } ) )
							return false;
						if (_strFilterText.length == 0) return true;
						if (itemPicker) {
							var strText:String = itemPicker.GetItemFilterText(ob);
							if (_strFilterText.length > strText.length) return false;
							return strText.toLowerCase().indexOf(_strFilterText) > -1;
						}
						return true;
					};
				acData.refresh();
			}
		}
	}
}