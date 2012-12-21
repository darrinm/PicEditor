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
package controls.itempicker {
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.containers.VBox;
	import mx.effects.Effect;
	import mx.events.FlexEvent;

	public class ListItemBase extends VBox {

		private var _cw:ChangeWatcher = null;
		
		[Bindable] protected var textFilter:String = "";
		
		public override function set owner(value:DisplayObjectContainer):void {
			super.owner = value;
			
			var lstOwner:ItemSearchList = owner as ItemSearchList;
			Unwatch();
			if (lstOwner) {
				_cw = ChangeWatcher.watch(lstOwner, "filterText", OnFilterTextChange);
			}
		}
		
		private function OnFilterTextChange(evt:Event): void {
			var lstOwner:ItemSearchList = owner as ItemSearchList;
			if (lstOwner == null) {
				return;			
			}
			textFilter = lstOwner.filterText;
		}
		
		private function Unwatch(): void {
			if (_cw) _cw.unwatch();
			_cw = null;
		}
		
		protected function ApplyFilter(strName:String, strFilter:String): String {
			if (strFilter.length == 0) return strName;
			var nBreakPos:Number = strName.toLowerCase().indexOf(strFilter.toLowerCase())
			if (nBreakPos == -1) return strName;
			
			return strName.substr(0, nBreakPos) + "<b>" + strName.substr(nBreakPos, strFilter.length) + "</b>" + strName.substr(nBreakPos + strFilter.length);
		}
	}
}
