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
	import mx.containers.VBox;
	import flash.events.Event;
	import mx.managers.PopUpManager;
	import mx.events.FlexEvent;
	import mx.events.FlexMouseEvent;
	import mx.core.UIComponent;
	import flash.geom.Point;
	import flash.events.MouseEvent;
	import mx.controls.LinkButton;
	import mx.collections.ArrayCollection;
	import flash.display.InteractiveObject;
	import mx.core.Application;
	import mx.events.ItemClickEvent;

	public class PicnikMenuBase extends VBox
	{
		[Bindable] public var _acobMenuItems:ArrayCollection; // Array of PicnikMenuItems
		public var _fAlignBelow:Boolean = true; // If true, menu appears below button. if false, menu appears above button.
		public var _fAlignLeft:Boolean = true; // If true, left edge of menu and button are aligned. If false, right edges are aligned.
		public var _cyMenuButtonPadding:Number = -3; // Allow this menu pixels between the menu and the button
		public var _cxOffest:Number = 2; // Adjust x position by this much.
		public var _uicOwner:UIComponent = null;

		public function PicnikMenuBase() {
			super();
			addEventListener(FlexMouseEvent.MOUSE_DOWN_OUTSIDE, OnOutsideClick);
		}
		
		private function SetUp(): void {
			// Enumerate all child LinkButtons and give them the same Click handler
			for (var i:int = 0; i < numChildren; i++) {
				var lbtn:LinkButton = getChildAt(i) as LinkButton;
				if (lbtn == null)
					continue;
				lbtn.addEventListener(MouseEvent.CLICK, OnMenuItemClick);
			}
		}
		
		private function TearDown(): void {
			for (var i:int = 0; i < numChildren; i++) {
				var lbtn:LinkButton = getChildAt(i) as LinkButton;
				if (lbtn == null)
					continue;
				lbtn.removeEventListener(MouseEvent.CLICK, OnMenuItemClick);
			}
		}
		
		private function LinkButtonToMenuItem(lbtnFind:LinkButton): PicnikMenuItem {
			if (lbtnFind == null) return null;
			var nPos:Number = 0;
			for (var i:int = 0; i < numChildren; i++) {
				var lbtn:LinkButton = getChildAt(i) as LinkButton;
				if (lbtn == null)
					continue;
				if (lbtn == lbtnFind) return _acobMenuItems[nPos] as PicnikMenuItem;
				nPos++;
			}
			return null; // Not found
		}
		
		// When a menu item is clicked, remove the menu and dispatch an ItemClickEvent
		protected function OnMenuItemClick(evt:MouseEvent): void {
			var pmni:PicnikMenuItem = LinkButtonToMenuItem(evt.target as LinkButton);
			Hide();
			if (pmni) {
				dispatchEvent(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false,
						pmni.strLabel, -1, this, pmni.obItem));
			}
		}
		
		private function OnOutsideClick(evt:FlexMouseEvent): void {
			// If the outside click is on the menu's owner or a child of the menu's
			// owner, swallow the click. This allows the user to hide the menu by
			// clicking its invoker again.
			var ob:InteractiveObject = evt.relatedObject;
			while (ob != null) {
				if (ob == _uicOwner) {
					evt.stopImmediatePropagation();
					break;
				}
				ob = ob.parent;
			}
			
			Hide();
		}
		
		// Position the menu relative to its owner component
		// astrMenuItems is the list of menu item names (also bridge actions) supported by
		// this bridge.
		public function Show(uicOwner:UIComponent = null): void {
			if (uicOwner == null)
				uicOwner = _uicOwner;
			else
				_uicOwner = uicOwner;
			Debug.Assert(uicOwner != null);
			PopUpManager.addPopUp(this, uicOwner, false); // Popup before we check height and width
			validateNow(); // Make sure we update the size before we set the display position
			var ptButtonTopLeft:Point = uicOwner.localToGlobal(new Point(0,0));
			// For now, hard-code alignment
			// Line up left edges
			if (_fAlignLeft) {
				x = ptButtonTopLeft.x + _cxOffest;
			} else {
				x = ptButtonTopLeft.x + uicOwner.width - this.width + _cxOffest;
			}
			
			// Keep the menu from going off the right edge of the screen
			if (x + width > Application.application.stage.stageWidth)
				x = Application.application.stage.stageWidth - width;

			if (_fAlignBelow) {
				// Line up menu top with owner bottom (plus some padding)
				y = ptButtonTopLeft.y + uicOwner.height + _cyMenuButtonPadding;
			} else {
				// This would line up menu bottom with button top.
				y = ptButtonTopLeft.y - this.height - _cyMenuButtonPadding;
			}
			SetUp();
		}

		public function Hide(): void {
			if (isPopUp) {
				PopUpManager.removePopUp(this);
				TearDown();
			}
		}
	}
}
