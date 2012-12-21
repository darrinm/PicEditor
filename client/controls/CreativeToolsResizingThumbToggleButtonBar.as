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
package controls
{
	import flash.events.Event;
	
	import mx.controls.Button;
	import mx.core.ClassFactory;
	import mx.core.mx_internal;
	import mx.events.ChildExistenceChangedEvent;
	
	use namespace mx_internal;


	public class CreativeToolsResizingThumbToggleButtonBar extends ResizingThumbToggleButtonBar
	{
		public function CreativeToolsResizingThumbToggleButtonBar()
		{
			navItemFactory = new ClassFactory(CreativeToolsResizingThumbButtonBarButton);
			
			addEventListener(ChildExistenceChangedEvent.CHILD_ADD, InvalidateNewItems);
			addEventListener(ChildExistenceChangedEvent.CHILD_REMOVE, InvalidateNewItems);
		}
		
		private var _anNewItems:Array = [];
		private var _fNewItemsValid:Boolean = false;
		
		public function set newItems(an:Array): void {
			if (an == null) an = [];
			var i:Number;
			var fChanged:Boolean = true;
			if (an.length == _anNewItems.length)
				for (i = 0; i < an.length; i++)
					if (an[i] != _anNewItems[i])
						fChanged = true;
			if (!fChanged) return; // No change
			
			_anNewItems = an;
			InvalidateNewItems();
		}
		private function InvalidateNewItems(evt:Event=null): void {
			// Something changed
			_fNewItemsValid = false;
			invalidateProperties();
		}
		
		private function ArrayContains(an:Array, nFind:Number): Boolean {
			for each (var nFound:Number in an)
				if (nFound == nFind) return true;
			return false;
		}
		
		public override function validateProperties():void {
			super.validateProperties();
			if (!_fNewItemsValid) {
				if (numChildren > 0) {
					for (var i:Number = 0; i < numChildren; i++) {
						var obChild:Object = getChildAt(i) as Button;
						if ('showNew' in obChild) obChild.showNew = ArrayContains(_anNewItems, i);
					}
					_fNewItemsValid = true;
				}
			}
		}
	}
}