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
package creativeTools {
	import com.adobe.utils.StringUtil;
	
	import containers.FontInfoWindow;
	
	import controls.FontComboBox;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import imagine.ImageDocument;
	import imagine.documentObjects.DocumentObjectUtil;
	import imagine.documentObjects.IDocumentObject;
	import imagine.documentObjects.Text;
	import imagine.objectOperations.CreateObjectOperation;
	
	import mx.controls.Button;
	import mx.controls.TextArea;
	import mx.core.Application;
	import mx.events.CloseEvent;
	
	import util.FontFamily;
	import util.FontManager;
	import util.FontResource;
	import util.PicnikFont;
	
	public class TextToolBase extends ObjectToolBase {
		[Bindable] public var _btnAddText:Button;
		[Bindable] public var _btnDelete:Button;
		[Bindable] public var _btnFontInfo:Button;
		[Bindable] public var _doco:Text;
		[Bindable] public var _taText:TextArea;
		[Bindable] public var _pwndFontInfo:FontInfoWindow;
		
		// Make the FontFamily of the currently selected font available to TextTool.mxml.
		[Bindable] public var fontFamily:FontFamily;
		[Bindable] public var _fntc:FontComboBox;
		public var googlePlus:Boolean = false;
		
		private const knDefaultLeading:Number = -5; // CONFIG:
		
		private static var _fntDefault:PicnikFont = null;
		
		private var _fntSelected:PicnikFont = null;
		private var _obFontSelectedLock:Object = null;
		
		override protected function OnInitialize(evt:Event): void {
			super.OnInitialize(evt);
			_btnAddText.addEventListener(MouseEvent.CLICK, OnAddTextClick);
			_btnDelete.addEventListener(MouseEvent.CLICK, DeleteSelected);
			
			// When these controls change we want to add UndoTransactions
			_taText.addEventListener(Event.CHANGE, OnTextChange);
			_taText.addEventListener(FocusEvent.FOCUS_OUT, OnTextFocusOut);
			_btnFontInfo.addEventListener(Event.CHANGE, OnFontInfoChange);
			addEventListener(Event.RESIZE, OnResize);
		}
		
		override public function OnActivate(ctrlPrev:ICreativeTool): void {
			super.OnActivate(ctrlPrev);
			if (_fntc) _fntc.active = true;
			if (imgd != null && imgd.selectedItems.length > 0) {
				var doco:IDocumentObject = imgd.selectedItems[0];
				if (_doco != doco && doco.typeSubTab == name)
					SetDocumentObject(doco);
			}
		}
		
		override public function OnDeactivate(ctrlNext:ICreativeTool): void {
			super.OnDeactivate(ctrlNext);			
			if (_fntc) _fntc.active = false;
			HideFontInfoWindow();
		}
		
		private function OnResize(evt:Event): void {
			util.StateSize.UpdateState(this);
		}
		
		override protected function toolName(): String {
			return "text tool";
		}

		[Bindable]
		public function get selectedFont(): PicnikFont {
			return _fntSelected;
		}
		
		public function set selectedFont(fnt:PicnikFont): void {
			SetSelectedFont(fnt, true);
		}
		
		public function SetSelectedFont(fnt:PicnikFont, fOverwriteAll:Boolean, fLog:Boolean=false): void {
			if (PicnikFont.Equals(_fntSelected, fnt)) return;
			if (fLog && fnt && (!_fntSelected || _fntSelected.familyName != fnt.familyName))
				PicnikBase.app.LogNav(StringUtil.replace(fnt.baseFileName, ' ', '_'));
			// May require a load. Will trigger a load event and see what happens.	
			// Undone: Make sure we can elegantly handle a switch during a load
			// First, get the selected font.
			if (_fntSelected != null) {
				_fntSelected.RemoveReference(_obFontSelectedLock);
				_fntSelected = null;
				_obFontSelectedLock = null;
			}
			_fntSelected = fnt;
			if (_fntSelected) {
				if (_doco && _doco.font != _fntSelected && UserCanUseFont(_fntSelected)) {
					_fntDefault = _fntSelected;
					DocumentObjectUtil.AddPropertyChangeToUndo("Change Font", _imgd, _doco, { font: _fntSelected, leading: _fntSelected.leading });
				} else if (!UserCanUseFont(_fntSelected)) {
					this._btnFontInfo.selected = true;
				}
				_obFontSelectedLock = new Object();
				_fntSelected.AddReference(_obFontSelectedLock, OnFontLoaded);
			}
			UpdateUIForSelectedFont(fOverwriteAll);
		}
		
		private function UserCanUseFont( fnt:PicnikFont ): Boolean {
			var	fntf:FontFamily = FontManager.FindFontFamilyByName(_fntSelected.familyName);
			if (!fntf)
				return true;
				
			if (fntf.premium && !AccountMgr.GetInstance().isPremium)
				return false;
				
			return true;			
		}
		
		public function ChangeSelectedFont(fLog:Boolean=false): void {
			callLater(
				function(): void {
					var fnt:PicnikFont = CalculateSelectedFont();
					if (fnt) SetSelectedFont(fnt, false, fLog);
				});
		}
		
		private function UpdateUIForSelectedFont(fOverwriteAll:Boolean): void {
			var fntf:FontFamily = null;
			if (_fntSelected != null) {
				fntf = FontManager.FindFontFamilyByName(_fntSelected.familyName, _fntSelected.isDevice);
			}
			
			if (fntf == null) {
				// This may be true the first time we load
				if (_fntc) _fntc.enabled = false;
				if (_fntc) _fntc.selectedIndex = 0;
			} else {
				if (_fntc) _fntc.enabled = true;
				if (_fntc) _fntc.selectedItem = fntf;
				fontFamily = fntf;
			}
		}
		
		private function OnFontLoaded(fr:FontResource): void {
		}
		
		public function CalculateSelectedFont(): PicnikFont {
			var fnt:PicnikFont = null;
			var fntf:FontFamily = _fntc.selectedItem as FontFamily;
			if (fntf) {
				fnt = fntf.GetFont(_doco.font.appearsBold, _doco.font.appearsItalic, true);
			}
			return fnt;
		}
		
		private function OnAddTextClick(evt:MouseEvent): void {
			// Extract the essence of the DocumentObject
			var xmlProperties:XML = ImageDocument.DocumentObjectToXML(_doco);
			// Convert it into the form CreateObjectOperation likes
			var dctProperties:Object = Util.ObFromXmlProperties(xmlProperties);
			
			// Don't copy the template object's id/name. New object needs a new id.
			dctProperties.name = Util.GetUniqueId();

			// Center the text object in the view if its position hasn't been initialized
			if (dctProperties.x == 0 && dctProperties.y == 0) {
				var rcd:Rectangle = _imgv.GetViewRect();
				dctProperties.x = Math.round(rcd.x + (rcd.width / 2));
				dctProperties.y = Math.round(rcd.y + (rcd.height / 2));
			}
			
			var coop:CreateObjectOperation = new CreateObjectOperation("Text", dctProperties);
			imgd.BeginUndoTransaction("Create Text", false, false);
			coop.Do(imgd);
			imgd.EndUndoTransaction();

			// Select the newly created object
			imgd.selectedItems = [ imgd.getChildByName(dctProperties.name) ];
		}
		
		public function OnFontComboLoaded(): void {
			if (_doco) {
				selectedFont = _doco.font;
			} else {
				_fntc.selectedIndex = 0;
			}
			callLater(
				function(): void {
						UpdateUIForSelectedFont(false);
					});
			
		}

		private function CreateDefaultTextObject(): Text {
			var txt:imagine.documentObjects.Text = new imagine.documentObjects.Text();
			if (_fntDefault)
				txt.font = _fntDefault;
			txt.leading = knDefaultLeading;
			return txt;
		}
		
		override protected function SetDocumentObject(doco:IDocumentObject): void {
            super.SetDocumentObject(doco);
           
            // Setting _doco will fire a change event so do it this way to be sure
            // it only happens once.
            _doco = doco as Text ? doco as Text : CreateDefaultTextObject();
		}
		
		//
		// Event handlers responding to UI controls that make undoable changes to the
		// DocumentObject.
		//
		
		private function OnTextChange(evt:Event): void {
			DocumentObjectUtil.AddPropertyChangeToUndo("Change Text", _imgd, _doco, { text: evt.target.text }, true);
		}
		
		private function OnTextFocusOut(evt:FocusEvent): void {
			if (_doco.parent != null)
				DocumentObjectUtil.SealUndo(_imgd);
		}
		
		//
		// FontInfoWindow stuff
		//
		
		private function OnFontInfoChange(evt:Event): void {
			var fActive:Boolean = _btnFontInfo.selected;
			if (fActive)
				ShowFontInfoWindow();
			else
				HideFontInfoWindow();
		}
		
		private function ShowFontInfoWindow(): void {
			if (_pwndFontInfo.parent != Application.application) {
				_pwndFontInfo.parent.removeChild(_pwndFontInfo);
				Application.application.addChild(_pwndFontInfo);
			}
			_pwndFontInfo.visible = true;
			_pwndFontInfo.addEventListener(CloseEvent.CLOSE, OnFontInfoClose);
		}

		private function HideFontInfoWindow(): void {
			_pwndFontInfo.visible = false;
			_pwndFontInfo.removeEventListener(CloseEvent.CLOSE, OnFontInfoClose);
			_btnFontInfo.selected = false;
		}
		
		private function OnFontInfoClose(evt:CloseEvent): void {
			HideFontInfoWindow();
		}
	}
}
