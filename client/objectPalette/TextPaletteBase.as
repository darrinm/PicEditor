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
package objectPalette {
	import com.adobe.utils.StringUtil;
	
	import controls.HSliderPlus;
	
	import imagine.documentObjects.DocumentObjectUtil;
	import imagine.documentObjects.Text;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import mx.controls.Button;
	import mx.controls.RadioButton;
	import mx.events.SliderEvent;
	
	import util.FontFamily;
	import util.FontManager;
	import util.PicnikFont;
	
	public class TextPaletteBase extends CommonPaletteBase {
		[Bindable] public var _sldrFontSize:HSliderPlus;
		[Bindable] public var _sldrLeading:HSliderPlus;
		[Bindable] public var _btnBold:Button;
		[Bindable] public var _btnItalic:Button;
		[Bindable] public var _btnAlignLeft:RadioButton;
		[Bindable] public var _btnAlignCenter:RadioButton;
		[Bindable] public var _btnAlignRight:RadioButton;
		
		public function ChangeSelectedFont(fLog:Boolean=false): void {
			callLater(
				function(): void {
					var fnt:PicnikFont = CalculateSelectedFont();
					if (fnt) SetSelectedFont(fnt, false, fLog);
				});
		}
		
		public function HasBold(fnt:PicnikFont): Boolean {
			return FontManager.FindFontFamilyByName(fnt.familyName, fnt.isDevice).hasRealBold;
		}
		
		public function HasItalic(fnt:PicnikFont): Boolean {
			return FontManager.FindFontFamilyByName(fnt.familyName, fnt.isDevice).hasItalic;
		}
		
		public function IsBold(fnt:PicnikFont): Boolean {
			return FontManager.FindFontFamilyByName(fnt.familyName, fnt.isDevice).IsBold(fnt);
		}
		
		public function IsItalic(fnt:PicnikFont): Boolean {
			return FontManager.FindFontFamilyByName(fnt.familyName, fnt.isDevice).IsItalic(fnt);
		}
		
		override protected function OnInitialize(evt:Event): void {
			super.OnInitialize(evt);
			
			// When these controls change we want to add UndoTransactions
			_sldrFontSize.addEventListener(SliderEvent.THUMB_RELEASE, OnFontSizeSliderThumbRelease);
			_sldrFontSize.addEventListener(SliderEvent.CHANGE, OnFontSizeSliderChange);
//			_sldrLeading.addEventListener(SliderEvent.THUMB_RELEASE, OnLeadingSliderThumbRelease);
//			_sldrLeading.addEventListener(SliderEvent.CHANGE, OnLeadingSliderChange);
			_btnAlignLeft.addEventListener(Event.CHANGE, OnAlignButtonChange);
			_btnAlignCenter.addEventListener(Event.CHANGE, OnAlignButtonChange);
			_btnAlignRight.addEventListener(Event.CHANGE, OnAlignButtonChange);
		}
		
		private function OnFontSizeSliderChange(evt:SliderEvent): void {
			// Don't do anything if the size isn't really changing
			if (evt.target.value == Text(_doco).fontSize)
				return;
				
			DocumentObjectUtil.AddPropertyChangeToUndo("Change Font Size", _imgd, DisplayObject(_doco), { fontSize: evt.target.value }, true);
		}
		
		private function OnFontSizeSliderThumbRelease(evt:SliderEvent): void {
			DocumentObjectUtil.SealUndo(_imgd);
		}
		
		private function OnLeadingSliderChange(evt:SliderEvent): void {
			// Don't do anything if the size isn't really changing
			if (evt.target.value == Text(_doco).leading)
				return;
				
			DocumentObjectUtil.AddPropertyChangeToUndo("Change Text Leading", _imgd, DisplayObject(_doco), { leading: evt.target.value }, true);
		}
		
		private function OnLeadingSliderThumbRelease(evt:SliderEvent): void {
			DocumentObjectUtil.SealUndo(_imgd);
		}
		
		private function OnAlignButtonChange(evt:Event): void {
			// We only care about the button being selected
			if (!evt.target.selected)
				return;
				
			var dctMap:Object = { "_btnAlignLeft": "left", "_btnAlignRight": "right", "_btnAlignCenter": "center" }
			var strAlign:String = dctMap[evt.target.name];
			if (strAlign == Text(_doco).textAlign)
				return;
				
			DocumentObjectUtil.AddPropertyChangeToUndo("Change Text Alignment", _imgd, DisplayObject(_doco), { textAlign: strAlign });
		}
		
		private function CalculateSelectedFont(): PicnikFont {
			var fnt:PicnikFont = null;
			var fntf:FontFamily = FontManager.FindFontFamilyByName(Text(_doco).font.familyName, Text(_doco).font.isDevice);
			if (fntf) {
				fnt = fntf.GetFont(_btnBold.selected, _btnItalic.selected, true);
			}
			return fnt;
		}
		
		private function SetSelectedFont(fnt:PicnikFont, fOverwriteAll:Boolean, fLog:Boolean=false): void {
			var txt:Text = Text(_doco);
			if (PicnikFont.Equals(txt.font, fnt))
				return;
				
			if (fLog && fnt && (!txt.font || txt.font.familyName != fnt.familyName))
				PicnikBase.app.LogNav(StringUtil.replace(fnt.baseFileName, ' ', '_'));

			DocumentObjectUtil.AddPropertyChangeToUndo("Change Font", _imgd, _doco as DisplayObject, { font: fnt });
		}
	}
}
