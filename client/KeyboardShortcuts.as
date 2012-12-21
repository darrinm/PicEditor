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
	import commands.CommandMgr;
	
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	
	import mx.core.Application;
	import mx.core.IUIComponent;
	import mx.managers.ISystemManager;
	
	import util.GlobalEventManager;
	
	public class KeyboardShortcuts 	{
		public static const GLOBAL:String = "global";
		public static const EDIT:String = "edit";
		
		// Shortcuts are [ keyCode, modifiers, "CommandName" ]
		private static var s_mpModeShortcuts:Object = {
			global: [
				[ 192, GlobalEventManager.kmodCtrl, "ToggleConsoleVisibility" ], // ctrl+`			
			],
			
			edit: [
				[ 90, GlobalEventManager.kmodCtrl, "GenericDocument.Undo" ], // ctrl+z
				[ 89, GlobalEventManager.kmodCtrl, "GenericDocument.Redo" ], // ctrl+y
				[ 0, 0, "global" ] // chain in the global shortcuts
			]
		}
		
		private static var s_mode:String = null;
		private static var s_fEnabled:Boolean = false;
		
		public static function get mode(): String {
			return s_mode;
		}
		
		public static function set mode(strMode:String): void {
			s_mode = strMode;			
		}
		
		public static function set enable(fEnable:Boolean): void {
			s_fEnabled = fEnable;
			if (s_fEnabled) {
				Application.application.stage.addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
			} else {
				Application.application.stage.removeEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
			}
		}
		
		public static function get enable(): Boolean {
			return s_fEnabled;
		}
		
		private static function OnKeyDown(evt:KeyboardEvent): void {
			// Admin only for now
			if (!(AccountMgr.GetInstance().isAdmin))
				return;
			
			// Shortcuts, e.g. ctrl+x,z,x,c,v, should not be triggered while input is going to text field
			var ob:Object = Application.application.stage.focus;
			if (ob is TextField)
				return;
				
			// Shortcuts should not be triggered while a modal dialog is up
			var sm:ISystemManager = Application.application.systemManager;
			for (var i:int = 0; i < sm.numChildren; i++) {
				ob = sm.getChildAt(i);
				if (ob is IUIComponent && IUIComponent(ob).isPopUp)
					return;
			}

//			trace("keyCode: " + evt.keyCode.toString());

			var modHeld:uint = GlobalEventManager.GetHeldModifiers();
			var mode:String = s_mode;
			while (mode != null) {
				var ashct:Array = s_mpModeShortcuts[mode];
				mode = null;
				for each (var shct:Array in ashct) {
					if (shct[0] == evt.keyCode && shct[1] == modHeld) {
						CommandMgr.Execute(shct[2]);
						return;
					}
					
					// Follow the shortcut chain
					if (shct[0] == 0) {
						mode = shct[2];
						break;
					}
				}
			}
		}
	}
}
