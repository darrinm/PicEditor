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
package controls {
	import bridges.Bridge;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	
	import mx.collections.ArrayCollection;
	import mx.containers.HBox;
	import mx.containers.ViewStack;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ItemClickEvent;
	import mx.events.ResizeEvent;
	
	public class OverflowMenuBase extends HBox {
		[Bindable] public var _buText:Button;
		[Bindable] public var viewStack:ViewStack;
		[Bindable] public var buttonBar:ThumbToggleButtonBar;
		
		private var _strText:String;
		private var _mnuItems:PicnikMenu = new PicnikMenu();
		private var _fIgnoreClick:Boolean = false;
		
		public function OverflowMenuBase() {
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
			addEventListener(MouseEvent.CLICK, OnClick);
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
		}
		
		public function set text(strText:String): void {
			_strText = strText;
			if (_buText)
				_buText.label = strText;
		}
		
		public function get text(): String {
			return _strText;
		}
		
		private function OnInitialize(evt:FlexEvent): void {
			_buText.label = _strText;
			parent.addEventListener(ResizeEvent.RESIZE, OnParentResize);
			_mnuItems.addEventListener(ItemClickEvent.ITEM_CLICK, OnMenuItemClick);
			
			// Force inheritance of fontSize
			_buText.setStyle("fontSize", getStyle("fontSize"));
		}
		
		private function OnCreationComplete(evt:FlexEvent): void {
			buttonBar.addEventListener(FlexEvent.UPDATE_COMPLETE, OnButtonBarUpdateComplete);			
			HideClippedSubTabs();
		}
		
		private function OnButtonBarUpdateComplete(evt:FlexEvent): void {
			HideClippedSubTabs();
		}
		
		private function OnMenuItemClick(evt:ItemClickEvent): void {
			viewStack.selectedChild = evt.item as Bridge;
		}
		
		// Ignore the menu click if the menu is already visible
		private function OnMouseDown(evt:MouseEvent): void {
			if (_mnuItems.isPopUp)
				_fIgnoreClick = true;
		}
		
		private function OnClick(evt:MouseEvent): void {
			// Only show the menu if we've seen the mouse down event as well as the click.
			// The menu's click outside handler swallows the down to make this work.
			if (_fIgnoreClick) {
				_fIgnoreClick = false;
				return;
			}
			
			_mnuItems.Show(this);
		}
		
		private function OnParentResize(evt:ResizeEvent): void {
			_mnuItems.Hide();
			
			HideClippedSubTabs();
		}
				
		public function HideClippedSubTabs(): void {
			// Hide/show the 'More' menu depending on whether it is needed
			var cxGears:Number = parent.getChildByName("_grsBusy") ? parent.getChildByName("_grsBusy").width : 0;
			var cxAvailable:Number = parent.width - cxGears;
			visible = buttonBar.width > cxAvailable;
			
			// The amount of available space diminishes if the 'More' menu is visible
			cxAvailable -= (visible ? width : 0);

			// Clear the menu of items
			_mnuItems._acobMenuItems = new ArrayCollection();
			
			// Hide any buttonBar children that don't fully fit
			var fFirstHidden:Boolean = true;
			for (var i:Number = 0; i < buttonBar.numChildren; i++) {
				var uic:UIComponent = buttonBar.getChildAt(i) as UIComponent;
				var brg:DisplayObject = viewStack.getChildAt(i);
				if (brg && (!brg.hasOwnProperty("NoNavBar") || !brg['NoNavBar'])) {				
					uic.visible = uic.x + uic.width <= cxAvailable;
					if (!uic.visible) {
						_mnuItems._acobMenuItems.addItem(new PicnikMenuItem(brg['label'], brg));
						
						// Position the 'More' menu where the left-most hidden item was
						if (fFirstHidden) {
							x = uic.x;
							fFirstHidden = false;
						}
					}
				}
			}
			
			buttonBar.UpdateThumb();
		}
	}
}
