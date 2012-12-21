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
package {
	import flash.geom.Point;
	
	import mx.containers.Canvas;
	import mx.controls.List;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.FlexMouseEvent;
	import mx.events.ListEvent;
	import mx.managers.PopUpManager;

	public class LocaleMenuBase extends Canvas {
		[Bindable] public var _lstLocales:List;
		
		public function LocaleMenuBase() {
			super();
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			addEventListener(FlexMouseEvent.MOUSE_DOWN_OUTSIDE, OnOutsideClick);
		}
		
		[Bindable] public var _strSelectedLocale:String = null;
		
		private function OnInitialize(evt:FlexEvent): void {
			_lstLocales.selectedIndex = 0;
			_strSelectedLocale = PicnikBase.Locale();
			for (var i:Number = 0; i < _lstLocales.dataProvider.length; i++) {
				if (_lstLocales.dataProvider[i].locale == _strSelectedLocale) {
					_lstLocales.selectedIndex = i;
					_lstLocales.selectedItem.isSelected = true;
					break;
				}
			}
			_lstLocales.addEventListener(ListEvent.CHANGE, onListChange);
		}
		
		// When a menu item is clicked, remove the menu and invoke the appropriate dialog
		private function onListChange(evt:ListEvent): void {
			var nSelectedIndex:Number = evt.target.selectedIndex;
			var strLocale:String = _lstLocales.selectedItem.locale;
			PicnikBase.app.SwitchLocale( strLocale );
		}
		
		private function OnOutsideClick(evt:FlexMouseEvent): void {
			PopUpManager.removePopUp(this);
		}
		
		// Position the menu left-aligned and below its owner component
		public function Show(uicParent:UIComponent, uicOwner:UIComponent): void {
			var ptOwner:Point = uicOwner.localToGlobal(new Point());
			x = ptOwner.x;
			y = ptOwner.y + uicOwner.height + 2;
			PopUpManager.addPopUp(this, uicParent, false);
		}
	}
}
