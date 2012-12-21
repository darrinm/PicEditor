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
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.containers.Canvas;
	import mx.controls.LinkButton;
	import mx.core.Container;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.FlexMouseEvent;
	import mx.managers.PopUpManager;

	public class HelpMenuBase extends Canvas {
		// MXML-specified variables
		[Bindable] public var _ctnr:Container;
		
		public function HelpMenuBase() {
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
			addEventListener(FlexMouseEvent.MOUSE_DOWN_OUTSIDE, OnOutsideClick);
		}
		
		protected function OnCreationComplete(evt:FlexEvent): void {
			// Enumerate all child LinkButtons and give them the same Click handler
			for (var i:int = 0; i < _ctnr.numChildren; i++) {
				var lbtn:LinkButton = _ctnr.getChildAt(i) as LinkButton;
				if (lbtn == null)
					continue;
				lbtn.addEventListener(MouseEvent.CLICK, OnItemClick);
			}
		}
		
		// When a menu item is clicked, remove the menu and invoke the appropriate dialog
		protected function OnItemClick(evt:MouseEvent): void {
			PopUpManager.removePopUp(this);

			var strDialog:String = evt.target.name;			
			if (strDialog == "myaccount")
				strDialog = AccountMgr.GetInstance().isGuest ? "login" : "usersettings";
			if (strDialog == "googlemerge2")
				strDialog = "googlemerge";

			PicnikBase.app.ShowDialog(strDialog, "/helpmenu");
		}
		
		private function OnOutsideClick(evt:FlexMouseEvent): void {
			PopUpManager.removePopUp(this);
		}
		
		// Position the menu left-aligned and below its owner component
		public function Show(uicParent:UIComponent, uicOwner:UIComponent): void {
			var ptOwner:Point = uicOwner.localToGlobal(new Point());
			x = ptOwner.x;
			y = ptOwner.y + uicOwner.height + 2;
			PopUpManager.addPopUp(this, uicParent, true);
		}
	}
}
