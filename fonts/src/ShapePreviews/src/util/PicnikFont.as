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
package util
{
	import documentObjects.IDocumentSerializable;
	
	import flash.text.Font;
	import flash.text.FontStyle;

	public class PicnikFont implements IDocumentSerializable
	{
		[Bindable] public var isBold:Boolean = false;
		[Bindable] public var altBold:Boolean = false;
		[Bindable] public var altItalic:Boolean = false;
		[Bindable] public var fakeBold:Boolean = false;
		[Bindable] public var isItalic:Boolean = false;
		[Bindable] public var familyName:String = null;
		[Bindable] public var size:Number = 0;
		[Bindable] public var leading:Number = 0;
		
		[Bindable] public var baseFileName:String = null;
		[Bindable] public var isEmbeded:Boolean = false;
		
		private static var _fntDefault:PicnikFont;
		private static var _fntDefaultPremium:PicnikFont;
		private var _ffnt:Font = null;
		
		//
		// IDocumentSerializable interface
		//
		
		public function toString(): String {
			return "Font[" + baseFileName + ", " + familyName + ", B=" + isBold + ", FB=" + fakeBold + "]";
		}
		
		public function get serializableProperties(): Array {
			return [ "isBold", "altBold", "altItalic", "fakeBold", "isItalic", "familyName", "size", "isEmbeded",
					"baseFileName", "leading" ];
		}
		
		public static function Equals(fnt1:PicnikFont, fnt2:PicnikFont): Boolean {
			if (fnt1 === fnt2) return true;
			if (fnt1 == fnt2) return true;
			if (fnt1 == null || fnt2 == null) return false;
			return (fnt1.familyName == fnt2.familyName && fnt1.isBold == fnt2.isBold && fnt1.altBold == fnt2.altBold && fnt1.altItalic == fnt2.altItalic && fnt1.isItalic == fnt2.isItalic && fnt1.fakeBold == fnt2.fakeBold);
		}
		

		public static function Default(): PicnikFont {
			if (true) {
				if (_fntDefaultPremium == null) {
					_fntDefaultPremium = new PicnikFont();
					_fntDefaultPremium.familyName = "pkfs0MtBkLFRo";
					_fntDefaultPremium.baseFileName = "fs_MtBkLFRo";
				}
				return _fntDefaultPremium;
			} else {
				if (_fntDefault == null) {
					_fntDefault = new PicnikFont();
					_fntDefault.familyName = "pkarial";
					_fntDefault.baseFileName = "arial";
				}
				return _fntDefault;				
			}
		}

		public static function FakeBold(fnt:PicnikFont): PicnikFont {
			var fntOut:PicnikFont = new PicnikFont();
			fntOut = fnt.clone();
			fntOut.fakeBold = true;
			return fntOut;
		}

		// <font baseFileName="tommortel" className="pktommortel" isBold="0" isItalic="0" size="142232" fakeBold="0"/>
		public function PicnikFont(xml:XML = null) {
			fromXML(xml);
		}
		
		public function get appearsBold(): Boolean {
			return fakeBold || isBold || altBold;
		}
		
		public function get appearsItalic(): Boolean {
			return isItalic || altItalic;
		}
		
		public function fromXML(xml:XML): void {
			if (xml != null) {
				isBold = xml.@isBold == "1";
				isItalic = xml.@isItalic == "1";
				familyName = xml.@familyName;
				baseFileName = xml.@baseFileName;
				isEmbeded = xml.@isEmbeded == "1";
				fakeBold = xml.@fakeBold == "1";
				altBold = (xml.hasOwnProperty('@altBold') && xml.@altBold == "1");
				altItalic = (xml.hasOwnProperty('@altItalic') && xml.@altItalic == "1");
				size = xml.@size;
				leading = xml.hasOwnProperty("@leading") ? Number(xml.@leading) : 0;
			}
		}
		
		public function toXML(): XML {
			return <PicnikFont
				isBold={isBold?'1':'0'}
				isItalic={isItalic?'1':'0'}
				altBold={altBold?'1':'0'}
				altItalic={altItalic?'1':'0'}
				familyName={familyName}
				baseFileName={baseFileName}
				isEmbeded={isEmbeded}
				fakeBold={fakeBold?'1':'0'}
				size={size}
				leading={leading}
				/>
		}
		
		public function clone(): PicnikFont {
			return new PicnikFont(toXML());
		}

		private function get swfUrl(): String {
			if (isEmbeded) return "";
			return FontManager.FontsBasePath() + "swfs/" + baseFileName + ".swf";
		}
		
		public function get thickness(): Number {
			return fakeBold ? 100 : 0;
		}
		
		public function HasGlyphs(strGlyphs:String): Boolean {
			// Find the embedded Font that matches this PicnikFont because it has the
			// hasGlyph method we need to call.
			if (_ffnt == null) {
				var affnt:Array = Font.enumerateFonts(false);
				for each (var ffnt:Font in affnt) {
					if (ffnt.fontName == this.familyName && IsStyleMatch(ffnt.fontStyle)) {
						_ffnt = ffnt;
						break;
					}
				}
			}
			
			if (_ffnt == null)
				return true;
			return _ffnt.hasGlyphs(strGlyphs);
		}
		
		private function IsStyleMatch(strFontStyle:String): Boolean {
			switch (strFontStyle) {
			case FontStyle.BOLD_ITALIC:
				return isBold && isItalic;
			case FontStyle.BOLD:
				return isBold && !isItalic;
			case FontStyle.ITALIC:
				return isItalic && !isBold;
			case FontStyle.REGULAR:
				return !isBold && !isItalic;
			}
			return false;
		}
		
		////////////// Loader Methods //////////////
		
		// Add a reference to the font.
		// If the font is already loaded, call the callback immediately and return true
		// If the font is not loaded, start loading and return false.
		public function AddReference(obReferrer:Object, fnCallback:Function): Boolean {
			return FontLoader.AddReference(swfUrl, obReferrer, fnCallback);
		}
		
		public function RemoveReference(obReferrer:Object): void {
			FontLoader.RemoveReference(swfUrl, obReferrer);
		}
	}
}