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
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import imagine.ImageDocument;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.Text;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	
	/**
 	 * The ConfirmLoadOverEditDialogBase class is used in conjunction with ConfirmLoadOverEditDialog.mxml
	 * to present the user with a chance to cancel an image load when they have an image open with
	 * unsaved changes.
	 *
	 * @example
		private function DownloadImage(): void {
			ValidateOverwrite(DoDownloadImage);
		}
		
		private function DoDownloadImage(): void {
		    // User has OKed the overwrite if an image needs to be saved
		}
	 *
	 * For now, if a user cliks "Yes" (to save), we simply select the "save & publish" tab.
   	 */
	public class ConfirmLoadOverEditDialogBase extends CoreDialog {
		// MXML-specified variables
		[Bindable] public var _btnYes:Button;
		[Bindable] public var _btnNo:Button;
//		[Bindable] public var _imgv:ImageView;
		[Bindable] public var _cnv1:Canvas;
		[Bindable] public var _txtHeader:Text;
		[Bindable] public var _txtHeader2:Text;
		
		private var _fClosing:Boolean = false;
		private var _strAltTitle:String = null;
		
		// This is here because constructor arguments can't be passed to MXML-generated classes
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			try {
				super.Constructor(fnComplete, uicParent, obParams);
				_fClosing = (obParams && 'fClosing' in obParams) ? obParams['fClosing'] : false;
				_strAltTitle = (obParams && 'strAltTitle' in obParams) ? obParams['strAltTitle'] : null;
			} catch (e:Error) {
				PicnikService.Log("Client Exception:[ConfirmLoadOverEditDialogBase.Constructor] " + e + ", " + e.getStackTrace(), PicnikService.knLogSeverityError);
				// If twe can't show the dialog, assume the current image is bad and call the callback
				fnComplete({ success: true });
			}
		}
		
		override protected function OnInitialize(evt:Event): void {
			super.OnInitialize(evt);
			_btnYes.addEventListener(MouseEvent.CLICK, OnYesClick);
			_btnNo.addEventListener(MouseEvent.CLICK, OnNoClick);
			var thumb:UIComponent = PicnikBase.app.activeDocument.GetDocumentThumbnail();
			if (thumb != null) {
				thumb.percentWidth = 100;
				thumb.percentHeight = 100;
				_cnv1.addChild(thumb);
			}
		}

		override protected function OnCreationComplete(evt:FlexEvent): void {
			super.OnCreationComplete(evt);
			// OnInitialize is too early for this
			_btnYes.setFocus();
			
			if (_strAltTitle != null) {
				_txtHeader2.htmlText = _strAltTitle;
			} else {
				// If we've got a title, use it
				var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
				if (imgd &&
					imgd.properties &&
					imgd.properties.title &&
					imgd.properties.title.length > 0) {
					_txtHeader.visible = true;
					_txtHeader.includeInLayout = true;
					_txtHeader.htmlText = _txtHeader.htmlText.replace("{prevImageName}", imgd.properties.title);
					_txtHeader2.visible = false;
					_txtHeader2.includeInLayout = false;
				}
			}
		
			// center our child if necessary
			if (_cnv1.numChildren > 0) {
				var uicChild:UIComponent = _cnv1.getChildAt(0) as UIComponent;
				if (uicChild && "content" in uicChild) {
					var dob:DisplayObject = uicChild['content'];
					if (dob && dob.width && dob.height) {
						var nScale:Number = Math.min( _cnv1.width/dob.width, _cnv1.height/dob.height );						
						uicChild.x = (_cnv1.width - dob.width * nScale) / 2;
						uicChild.y = (_cnv1.height - dob.height * nScale) / 2;
					}
				}
			}
		}
		
		private function OnYesClick(evt:Event): void {
			Hide();
			if (_fnComplete != null)
				_fnComplete({ success: false, choice: "save" }); // Success == false: we don't want to continue with the opening
				
			if (!_fClosing) {
				PicnikBase.app.DoSave();
			}
		}
		
		private function OnNoClick(evt:Event): void {
			Hide();
			if (_fnComplete != null)
				_fnComplete({ success: true, choice: "discard" }); // Success == true: Go ahead and overwrite changes without saving
		}
	}
}
