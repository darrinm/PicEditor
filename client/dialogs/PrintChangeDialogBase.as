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
package dialogs {
	import containers.Dialog;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	
	/**
 	 * The PrintChangeDialogBase class is used in conjunction with PrintChangeDialog.mxml
	 * to show information about a pending print operation
   	 **/
	public class PrintChangeDialogBase extends Dialog {
		// MXML-specified variables
		protected var _args:Array;
		
		public static const kstrOutOfBounds:String = "OutOfBounds";
		public static const kstrCalibrate:String = "Calibrate";
		public static const kstrPageChange:String = "";
				
		public static function Show(uicParent:UIComponent, fnComplete:Function, strState:String, ...args:Array): PrintChangeDialog {
			var dlg:PrintChangeDialog = new PrintChangeDialog();
			// PORT: use the cool varargs way to relay these params
			dlg.Constructor(fnComplete, strState, args);
			PopUpManager.addPopUp(dlg, uicParent, true);
			mx.managers.PopUpManager.centerPopUp(dlg);
			return dlg;
		}
		
		// This is here because constructor arguments can't be passed to MXML-generated classes
		public function Constructor(fnComplete:Function, strState:String, args:Array): void {
			_fnComplete = fnComplete;
			currentState = strState;
			_args = args;
		}
		
		protected override function OnCancel(): void {
			Complete(false);
		}
		
		protected function Complete(fYes:Boolean): void {
			Hide();
			if (_fnComplete != null) {
				var args:Array = _args.slice();
				args.unshift(fYes);
				_fnComplete.apply(null, args); // Success == false: Go ahead and overwrite changes without saving
			}
		}
	}
}
