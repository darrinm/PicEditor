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
	import containers.CoreDialog;
	import flash.events.MouseEvent;
	import mx.controls.Button;
	import mx.controls.Text;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	import mx.events.FlexEvent;
	import util.PicnikAlert;
	
	/**
 	 * The ConfirmDelAcctBase class is used in conjunction with ConfirmCancelDialog.mxml
	 * to present the user with a chance to back out of deleting their account.
	 *
   	 */
	public class ConfirmDelAcctDialogBase extends CloudyResizingDialog {
		// MXML-specified variables
		[Bindable] public var _btnYes:Button;
		[Bindable] public var _txtHeader:Text;
		
		public var _bsy:IBusyDialog;
		
		public function ConfirmDelAcctDialogBase() {
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}
		
		private function OnCreationComplete( evt:FlexEvent ): void {
			_btnYes.addEventListener(MouseEvent.CLICK, OnYesClick);
		}		
				
		private function OnYesClick(evt:Event): void {
			_bsy = BusyDialogBase.Show(this, Resource.getString('SettingsComponent', 'working_on_it'), BusyDialogBase.OTHER, "IndeterminateNoCancel", 0.5);
			PicnikService.DeleteMyAccount( function(nErr:Number, nErrMsg:String, obResult:Object = null):void {
					_bsy.Hide()
					_bsy = null;
					if (nErr || isNaN(nErr)) {
						PicnikAlert.show(Resource.getString('SettingsComponent', 'server_problems_error'));
					} else {
						AccountMgr.GetInstance().LogOut(null);
						Hide();
					}
				} );			
		}
	}
}
