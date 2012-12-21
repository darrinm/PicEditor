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
	
	import controls.ResizingButton;
	import controls.ResizingLabel;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import imagine.ImageDocument;
	
	import mx.controls.Button;
	import mx.controls.Text;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	
	import util.LocUtil;
	
	/**
	 * The ConfirmApplyEffectDialogBase class is used in conjunction with ConfirmApplyEffectDialog.mxml
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
	public class ConfirmApplyEffectDialogBase extends CoreDialog {
		// MXML-specified variables
		[Bindable] public var _btnYes:ResizingButton;
		[Bindable] public var _btnNo:ResizingButton;
		[Bindable] public var _imgv:ImageView;
		[Bindable] public var _txtHeader:ResizingLabel;
		[Bindable] protected var header:String = "";
		protected var _args:Object;
		protected var _strEffectName:String;
		protected var _strEffectClass:String;
		[Bindable] public var _fPremiumEffect:Boolean = false;
		
		[Bindable] public var actm:AccountMgr = AccountMgr.GetInstance();
		
		// This is here because constructor arguments can't be passed to MXML-generated classes
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object = null) : void {
			//strEffectName:String, strEffectClass:String, fPremium:Boolean, args:Array): void {
			super.Constructor(fnComplete, uicParent, obParams);
			if (obParams && 'strEffectName' in obParams) {
				_strEffectName = obParams['strEffectName'];				
			}
			if (obParams && 'strEffectClass' in obParams) {
				_strEffectClass = obParams['strEffectClass'];				
			}
			if (obParams && 'args' in obParams) {
				_args = obParams['args'];				
			}
			if (obParams && 'fPremiumEffect' in obParams) {
				_fPremiumEffect = obParams['fPremiumEffect'];				
			}
			if (obParams && 'strCustomHeader' in obParams) {
				header = obParams['strCustomHeader'];				
			} else {
				header = LocUtil.getString('ConfirmApplyEffectDialog', '_txtHeader')
			}
		}
		
		override protected function OnInitialize(evt:Event): void {
			super.OnInitialize(evt);
			_btnYes.addEventListener(MouseEvent.CLICK, OnYesClick);
			_btnNo.addEventListener(MouseEvent.CLICK, OnNoClick);
			if (_imgv) _imgv.imageDocument = PicnikBase.app.activeDocument as ImageDocument;
		}
		
		override protected function OnCreationComplete(evt:FlexEvent): void {
			super.OnCreationComplete(evt);
			// OnInitialize is too early for this
			_btnYes.setFocus();
			_txtHeader.htmlText = _txtHeader.htmlText.replace("{effectName}", _strEffectName);
		}
		
		protected override function OnCancel(): void {
			Hide();
		}
		
		private function OnYesClick(evt:Event): void {
			if (_fPremiumEffect && !actm.isPremium) {
				if (PicnikConfig.freeForAll && AccountMgr.GetInstance().isGuest) {
					DialogManager.ShowFreeForAllSignIn("/effect_" + className + "/inline");
				} else {				
					DialogManager.ShowUpgrade("/effect_" + _strEffectClass + "/cofirmdialog");
				}
			} else {
				Complete(true);
			}
		}
		
		private function Complete(fYes:Boolean): void {
			Hide();
			if (_fnComplete != null) {
				_args['success'] = fYes;
				_fnComplete.apply(null, [_args]);
			}
		}
		
		private function OnNoClick(evt:Event): void {
			Complete(false);
		}
	}
}
