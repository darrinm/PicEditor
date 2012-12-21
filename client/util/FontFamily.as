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
	import mx.resources.ResourceBundle;
	import mx.utils.StringUtil;
	
	public class FontFamily
	{
		[Bindable] public var smallPreviewUrl:String = "";
		[Bindable] public var bigPreviewUrl:String = "";
		[Bindable] public var hasItalic:Boolean = false;
		[Bindable] public var hasRealBold:Boolean = false;
		[Bindable] public var isDevice:Boolean = false;
		[Bindable] public var name:String = "<undefined>";
		[Bindable] public var displayName:String = "<undefined>";
		[Bindable] public var category:String = "<undefined>";
		[Bindable] public var premium:Boolean = true;
		[Bindable] public var rendererState:String = "";
		[Bindable] public var color:uint = 0;
		[Bindable] public var blurb:String = null;
		
		private var _fntNormal:PicnikFont = null;
		private var _fntBold:PicnikFont = null;
		private var _fntBoldItalic:PicnikFont = null;
		private var _fntItalic:PicnikFont = null;
		private var _strAuthorName:String = null;
		private var _strAuthorUrl:String = null;
		
		private var _aFonts:Array = new Array();
		
		public function FontFamily(xml:XML) {
			isDevice = xml.@isDevice == "1";
			if (!isDevice) {
				smallPreviewUrl = FontManager.FontsBasePath() + "pngs/" + xml.@categoryId + "/" + xml.@baseFileName + "_pkSmall.png";
				if (xml.hasOwnProperty("@hasPreview") && xml.@hasPreview !='0')
					bigPreviewUrl = FontManager.FontsBasePath() + "pngs/" + xml.@categoryId + "/" + xml.@baseFileName + "_pkPreview.png";
				else
					bigPreviewUrl = smallPreviewUrl;
			}
			if (xml.hasOwnProperty('@blurb') && xml.@blurb != '') blurb = xml.@blurb;
			
			_strAuthorName = xml.@authorName;
			_strAuthorUrl = xml.@authorUrl;
			category = xml.@category;
			rendererState = xml.@rendererState;
			// UNDONE: All "premium" fonts are premium for flickr only
			// We need a new way to denote "more premium" (premium everywhere)
			premium = false; // default
			
			if (PicnikBase.app.freemiumModel && (xml.@premium != "0")) premium = true;
			if (xml.hasOwnProperty('@extraPremium') && xml.@extraPremium != '0') premium = true; 
			name = xml.@familyName;
			displayName = xml.@displayName;
			color = 0;
			if (xml.hasOwnProperty('@color')) color = xml.@color;
			for each (var xmlFont:XML in xml.font) {
				var fnt:PicnikFont = new PicnikFont(xmlFont);
				_aFonts.push(fnt);
				if (fnt.appearsItalic && fnt.appearsBold) _fntBoldItalic = fnt;
				else if (fnt.appearsItalic) _fntItalic = fnt;
				else if (fnt.appearsBold) _fntBold = fnt;
				else _fntNormal = fnt;
			}
			
			// Shuffle fonts so that we always have a normal and bold and non-bold. Sometimes italic too.
			
			// First, move bold fonts to non-bold if there is no non-bold.
			if (_fntBold && ! _fntNormal) {
				_fntNormal = _fntBold;
				_fntBold = null;
			}
			if (_fntBoldItalic && !_fntItalic) {
				_fntItalic = _fntBoldItalic;
				_fntBoldItalic = null;
			}
			
			// Now create bold virtual fonts where needed
			// Don't do fake bold
			// if (_fntNormal && !_fntBold) _fntBold = PicnikFont.FakeBold(_fntNormal);
			// if (_fntItalic && !_fntBoldItalic) _fntBoldItalic =  PicnikFont.FakeBold(_fntItalic);
			
			// Next, if there are no normal fonts, shift italic fonts to normal
			if (!_fntNormal && _fntItalic) {
				_fntNormal = _fntItalic;
				_fntItalic = null;
				
				_fntBold = _fntBoldItalic;
				_fntBoldItalic = null;
			}
			
			hasRealBold = _fntBold != null;
			hasItalic = _fntItalic != null;
		}

		public function GetFont(fBold:Boolean, fItalic:Boolean, fFallback:Boolean=false): PicnikFont {
			var fnt:PicnikFont = _GetFont(fBold, fItalic);
			if (fFallback) {
				if (!fnt) fnt = _GetFont(fBold, false);
				if (!fnt) fnt = _GetFont(false, fItalic);
				if (!fnt) fnt = _GetFont(false, false);
			}
			return fnt;
		}

		public function IsBold(fnt:PicnikFont): Boolean {
			return PicnikFont.Equals(fnt, _fntBold) || PicnikFont.Equals(fnt,_fntBoldItalic);
		}

		public function IsItalic(fnt:PicnikFont): Boolean {
			return PicnikFont.Equals(fnt, _fntItalic) || PicnikFont.Equals(fnt, _fntBoldItalic);
		}

		private function _GetFont(fBold:Boolean, fItalic:Boolean): PicnikFont {
			if (fBold && fItalic) return _fntBoldItalic;
			else if (fBold) return _fntBold;
			else if (fItalic) return _fntItalic;
			else return _fntNormal;
		}

		/*
			Removed!  This code generates UI and so is locale-dependent,
			so we moved its equivalent functionality out of here because
			it was causing the FlashRenderer to become localized.
		
		[Bindable]
		public function set toolTip(str:String): void {
			// Ignore sets
		}
		public function get toolTip(): String {
			
			return StringUtil.substitute( _rb.getString( "tooltip" ), name, authorName );
		}
		*/
		
		[Bindable]
		public function set authorName(str:String): void {
			// Ignore sets
		}
		public function get authorName(): String {
			return _strAuthorName;
		}
		
		[Bindable]
		public function set authorUrl(str:String): void {
			// Ignore sets
		}
		public function get authorUrl(): String {
			return _strAuthorUrl;
		}
		
		// These always work
		public function get normalFont(): PicnikFont {
			return _fntNormal;
		}
		
		public function get boldFont(): PicnikFont {
			return _fntBold;
		}
		
		// These work only if hasItalic is true
		public function get italicFont(): PicnikFont {
			return _fntItalic;
		}
		
		public function get boldItalicFont(): PicnikFont {
			return _fntBoldItalic;
		}
		
		public function toString():String {
			return "";
		}
	}
}
