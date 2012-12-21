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
package bridges
{
	import mx.containers.VBox;
	import mx.controls.LinkButton;
	import flash.events.MouseEvent;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	import mx.events.FlexEvent;
	import mx.events.FlexMouseEvent;
	import flash.geom.Point;
	import mx.core.IDataRenderer;

	// This is the menu used by in bridge items (for example, FlickrInBridge)
	// It generates BridgeItemEvents based on user interaction.
	public class BridgeMenuItemBase extends VBox
	{
		private var _britm:BridgeItemBase;
		
		// MXML-specified variables
		public function BridgeMenuItemBase() {
			super();
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			addEventListener(FlexMouseEvent.MOUSE_DOWN_OUTSIDE, OnOutsideClick);
		}
		
		private function OnInitialize(evt:FlexEvent): void {
			// Enumerate all child LinkButtons and give them the same Click handler
			for (var i:int = 0; i < numChildren; i++) {
				var lbtn:LinkButton = getChildAt(i) as LinkButton;
				if (lbtn == null)
					continue;
				lbtn.addEventListener(MouseEvent.CLICK, OnItemClick);
			}
		}
		
		// When a menu item is clicked, remove the menu and dispatch the appropriate i
		private function OnItemClick(evt:MouseEvent): void {
			PopUpManager.removePopUp(this);
			
			// Dispatch the event to the bridge item and set bubble = true (last param of constructor) so that
			// the event will be caught by bridges listening to the tile list (the parent of the bridge item)
			_britm.dispatchEvent(new BridgeItemEvent(BridgeItemEvent.ITEM_ACTION, _britm, evt.target.name, null, true));
		}
		
		private function OnOutsideClick(evt:FlexMouseEvent): void {
			PopUpManager.removePopUp(this);
		}
		
		// Set up the menu (remove unwanted items)
		protected function SetupMenu(astrMenuItems:Array): void {
			var i:Number = 0;
			while (i < numChildren) {
				var lbtn:LinkButton = getChildAt(i) as LinkButton;
				if (lbtn != null && astrMenuItems.indexOf(lbtn.name) == -1) {
					removeChildAt(i);
				} else {
					i++;
				}
			}
		}
		
		// Position the menu right-aligned and above its owner component
		// astrMenuItems is the list of menu item names (also bridge actions) supported by
		// this bridge.
		public function Show(britm:BridgeItemBase, uicOwner:UIComponent, astrMenuItems:Array): void {
			_britm = britm;
			PopUpManager.addPopUp(this, britm, false); // Popup before we check height and width
			SetupMenu(astrMenuItems); // May change the menu size
			validateNow(); // Make sure we update the size before we set the display position
			var ptButtonTopLeft:Point = uicOwner.localToGlobal(new Point(0,0));
			x = ptButtonTopLeft.x + uicOwner.width - this.width;
			y = ptButtonTopLeft.y - this.height - 4;
		}
	}
}