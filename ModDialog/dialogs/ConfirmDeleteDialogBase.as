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
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	
	import util.LocUtil;
	
	/**
 	 * The ConfirmDeleteDialogBase class is used in conjunction with ConfirmDeleteDialog.mxml
	 * to present the user with a chance to cancel an image load when they have an image open with
	 * unsaved changes.
	 *
   	 */
	public class ConfirmDeleteDialogBase extends CoreDialog {
		// MXML-specified variables
		[Bindable] public var _btnYes:Button;
		[Bindable] public var _txtHeader:Text;
		[Bindable] public var _isDeletingOpenDocument:Boolean;
		
		private var _strImageName:String;
		[Bindable] public var _iinfo:ItemInfo;
		
		// This is here because constructor arguments can't be passed to MXML-generated classes
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object = null): void {
			super.Constructor(fnComplete, uicParent, obParams);
			var iinfo:ItemInfo = obParams['iinfo'];
			_strImageName = iinfo.title;
			if (_strImageName == null) _strImageName = LocUtil.Untitled(); // UNDONE: Localize this
			_iinfo = iinfo;
			_isDeletingOpenDocument = obParams['isDeletingOpenDocument'];
		}
		
		override protected function OnInitialize(evt:Event): void {
			super.OnInitialize(evt);
			_btnYes.addEventListener(MouseEvent.CLICK, OnYesClick);
		}

		override protected function OnCreationComplete(evt:FlexEvent): void {
			super.OnCreationComplete(evt);
			// OnInitialize is too early for this
			_btnCancel.setFocus();
			_txtHeader.htmlText = _txtHeader.htmlText.replace("{imageName}", _strImageName);
		}
		
		private function OnYesClick(evt:Event): void {
			if (_isDeletingOpenDocument)
				PicnikBase.app.CloseActiveDocument(true);
			Hide();
			if (_fnComplete != null)
				_fnComplete({ success: true }); // Success == false: we don't want to continue with the opening
		}
		
		protected function GetHeader(): String {
			return Resource.getString("ConfirmDeleteDialog", _isDeletingOpenDocument ? "_txtHeader2" : "_txtHeader");
		}
	}
}
