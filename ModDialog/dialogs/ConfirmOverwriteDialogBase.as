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
	
	import flash.geom.Point;
	
	import imagine.ImageDocument;
	
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.controls.Text;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;

	/**
 	 * The ConfirmOverwriteDialogBase class is used in conjunction with ConfirmOverwriteDialog.mxml
	 * to present the user with a chance to cancel an image save over an existing image.
	 *
   	 */
	public class ConfirmOverwriteDialogBase extends CoreDialog {
		// MXML-specified variables
		[Bindable] public var _btnOK:Button;
		[Bindable] public var _txtHeader:Text;
		[Bindable] public var _imgOld:Image;
		[Bindable] public var _imgvNew:ImageView;

		private var _strURLOld:String;
		private var _imgd:ImageDocument;
		[Bindable] protected var _nPercentOfOriginal:Number;
		[Bindable] protected var showSaveOver:Boolean = false;
		[Bindable] protected var imageDownsampled:Boolean = false;
		[Bindable] protected var haveOriginalThumb:Boolean = true;
						
		// This is here because constructor arguments can't be passed to MXML-generated classes
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object = null): void {
			super.Constructor(fnComplete, uicParent, obParams);
			if (obParams && 'strURLOld' in obParams) {
				_strURLOld = obParams['strURLOld'];
				haveOriginalThumb = obParams['strURLOld'] != null && obParams['strURLOld'].length > 0;
			}
			_imgd = (obParams && 'imgd' in obParams) ? obParams['imgd'] : null;
			showSaveOver = (obParams && 'fShowSaveOver' in obParams) ? obParams['fShowSaveOver'] : false;
		}
		
		override protected function OnInitialize(evt:Event): void {
			super.OnInitialize(evt);
			_imgOld.source = _strURLOld;
			_imgvNew.imageDocument = _imgd;
			
			// We need to know if the image has been downsampled to fit within the maximum resolution
			// limitation so we can warn the user.
			if (!_imgd.properties.fCanLoadDirect) {
				if (_imgd.baseImageFileId != null) {
					PicnikService.GetFileProperties(_imgd.baseImageFileId, null, "nOriginalWidth,nOriginalHeight", OnGetBaseImageFileProperties);
				}
			}
		}

		private function OnGetBaseImageFileProperties(err:Number, strError:String, dctProps:Object=null): void {
			if (err != PicnikService.errNone) {
				// UNDONE: alert user of the error
				return;
			}
			
			if (dctProps.nOriginalWidth != undefined && dctProps.nOriginalHeight != undefined)
				UpdateDownsampledIndicator(dctProps.nOriginalWidth, dctProps.nOriginalHeight);
		}

		private function UpdateDownsampledIndicator(cxOriginal:Number, cyOriginal:Number): void {
			var pt:Point = Util.GetLimitedImageSize(cxOriginal, cyOriginal);
			if (cxOriginal > pt.x || cyOriginal > pt.y) {
				var cx:Number = pt.x;
				var cy:Number = pt.y;
				_nPercentOfOriginal = Math.round((int(cx) * int(cy)) / (cxOriginal * cyOriginal) * 100);
				imageDownsampled = true;
			}
		}
		
		override protected function OnCreationComplete(evt:FlexEvent): void {
			super.OnCreationComplete(evt);
			// OnInitialize is too early for this
			_btnCancel.setFocus();
//			_txtHeader.htmlText = _txtHeader.htmlText.replace("{imageName}", _strImageName);
		}
		
		protected function SaveOver(): void {
			Hide();
			if (_fnComplete != null) {
				_fnComplete({ success: true, saveover:true }); // Success == false: we don't want to continue with the opening
			}
		}

		protected function SaveNew(): void {
			Hide();
			if (_fnComplete != null) {
				_fnComplete({ success: true, saveover:false }); // Success == false: we don't want to continue with the opening
			}
		}
	}
}
