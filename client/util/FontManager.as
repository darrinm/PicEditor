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
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import mx.core.Application;
	
	public class FontManager
	{
		private static var _fm:FontManager = new FontManager();
		
		private var _afntf:Array = null;	// font families
		private var _afntc:Object = null;	// font categories
		private var _xmlFontList:XML = null;
		private var _fFontListLoading:Boolean = false;
		private var _afnCallbacks:Array = new Array();
		private var _strError:String = "";
		
		public static function GetFontList(fnComplete:Function): void {
			_fm._GetFontList(fnComplete);
		}
		
		// Returns null if the list isn't loaded yet.
		public static function GetLoadedFontList(): Array {
			return _fm._afntf;
		}
		
		// Returns null if the list isn't loaded yet, or the family is not found.
		public static function FindFontFamilyByName(strName:String, fDevice:Boolean=false): FontFamily {
			if (_fm._afntf != null) {
				var fntf:FontFamily;
				for each (fntf in _fm._afntf) {
					if (fntf.name == strName && fntf.isDevice == fDevice) return fntf;
				}
				// Not found as a family, now try as a font.
				// This fixes problems with special fonts, like embeded Trebuchet or Bold/Italic fonts
				for each (fntf in _fm._afntf) {
					if (fntf.normalFont && fntf.normalFont.familyName == strName) return fntf;
					if (fntf.boldFont && fntf.boldFont.familyName == strName) return fntf;
					if (fntf.italicFont && fntf.italicFont.familyName == strName) return fntf;
					if (fntf.boldItalicFont && fntf.boldItalicFont.familyName == strName) return fntf;
				}
			}
			return null;
		}
		
		// Returns null if the list isn't loaded yet, or the family is not found.
		public static function FindFontByName(strName:String, fBold:Boolean, fItalic:Boolean, fFallback:Boolean=false, fDevice:Boolean=false): PicnikFont {
			var fnt:PicnikFont = null;
			var fntf:FontFamily = FindFontFamilyByName(strName, fDevice);
			if (fntf) {
				fnt = fntf.GetFont(fBold, fItalic, fFallback);
			}
			return fnt;
		}

		private static function IsStandaloneFlashPlayer(): Boolean {
			return ("http" != Application.application.url.substr(0,4).toLowerCase());
		}
		
		public static function FontsBasePath(): String {
			var strBase:String;
			if (FontManager.IsStandaloneFlashPlayer()) {
				strBase = "../website/fonts/";
			} else {
				strBase = "../fonts/";
			}
			return strBase;
		}
		
		public static function FontsXMLBasePath(): String {
			var strBase:String;
			if (FontManager.IsStandaloneFlashPlayer()) {
				strBase = "../website/app/";
			} else {
				strBase = "../app/";
			}
			strBase += CONFIG::locale + "/";
			return strBase;
		}
		
		private function _GetFontList(fnComplete:Function): void {
			_afnCallbacks.push(fnComplete);
			if (_xmlFontList) {
				PicnikBase.app.callLater(CallFontListLoadedCallbacks);
			} else if (!_fFontListLoading) {
				LoadFontList();
			}
		}
		
		private function LoadFontList(): void {
			_fFontListLoading = true;
			var urlr:URLRequest = new URLRequest(PicnikBase.StaticUrl(FontManager.FontsXMLBasePath() + "fonts.xml"));

			// Add the URLLoader event listeners before firing off the load so we will
			// be sure to catch any up-front errors (e.g. URLRequest validation)			
			var urll:URLLoader = new URLLoader();
			urll.addEventListener(Event.COMPLETE, OnFontListLoaded);
			urll.addEventListener(IOErrorEvent.IO_ERROR, OnFontListError);
			urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnFontListError);
			urll.load(urlr);
		}
		
		private function OnFontListLoaded(evt:Event): void {
			_xmlFontList = new XML((evt.target as URLLoader).data);
			_afntf = new Array();
			for each (var xmlFontFamily:XML in _xmlFontList.fontFamily) {
				_afntf.push(new FontFamily(xmlFontFamily));
			}
			_afntc = new Object();
			for each (var xmlFontCategory:XML in _xmlFontList.fontCategory) {
				var fntc:FontCategory = new FontCategory(xmlFontCategory);
				_afntc[fntc.category] = fntc;
			}			
			_fFontListLoading = false;
			CallFontListLoadedCallbacks();
		}
		
		private function OnFontListError(evt:Event): void {
			var strError:String = "";
			if ("text" in evt) strError = evt["text"];
			_strError = strError;
			CallFontListLoadedCallbacks();
		}
		
		private function CallFontListLoadedCallbacks(): void {
			for each (var fn:Function in _afnCallbacks) {
				fn(_afntf, _afntc);
			}
			_afnCallbacks.length = 0;
		}
	}
}
