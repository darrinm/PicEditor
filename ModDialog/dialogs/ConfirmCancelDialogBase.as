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
	import mx.controls.Button;
	import mx.controls.Text;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	import flash.events.MouseEvent;
	import mx.events.FlexEvent;
	
	/**
 	 * The ConfirmCancelDialogBase class is used in conjunction with ConfirmCancelDialog.mxml
	 * to present the user with a chance to back out of canceling their premium subscription.
	 *
   	 */
	public class ConfirmCancelDialogBase extends CoreDialog {
		// MXML-specified variables
		[Bindable] public var _btnYes:Button;
		[Bindable] public var _txtHeader:Text;
		
		private var _strImageName:String;
		[Bindable] public var _strImageThumbUrl:String;
		
		override protected function OnInitialize(evt:Event): void {
			super.OnInitialize(evt);
			_btnYes.addEventListener(MouseEvent.CLICK, OnYesClick);
		}

		override protected function OnCreationComplete(evt:FlexEvent): void {
			super.OnCreationComplete(evt);
			// OnInitialize is too early for this
			_btnCancel.setFocus();
			//_txtHeader.htmlText = _txtHeader.htmlText.replace("{imageName}", _strImageName);
		}
		
		private function OnYesClick(evt:Event): void {
			Hide();
			if (_fnComplete != null)
				_fnComplete({ success: true });
		}
	}
}
