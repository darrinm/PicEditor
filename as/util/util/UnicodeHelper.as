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
	import mx.binding.utils.ChangeWatcher;
	import mx.core.UIComponent;
	
	import picnik.util.LocaleInfo;
	import flash.events.Event;
	import flash.text.Font;
	
	public class UnicodeHelper
	{
		private var _uic:UIComponent = null;
		private var _astrFields:Array = null;
		
		public function UnicodeHelper(uic:UIComponent, astrFields:Array = null) {
			_uic = uic;
			if (astrFields == null) {
				_astrFields = new Array();
				if ("text" in uic) _astrFields.push("text");
				if ("htmlText" in uic) _astrFields.push("htmlText");
			} else {
				_astrFields = astrFields.slice(); // Copy the field list.
			}
			for each (var strField:String in _astrFields) {
				if (strField in _uic) ChangeWatcher.watch(uic, strField, OnFieldChanged);
			}
		}

		public function Update(): void {
			UpdateFont(HasUnicode());
		}
		
		private function OnFieldChanged(evt:Event): void {
			Update();
		}
		
		private function UpdateFont(fHasUnicode:Boolean): void {
			var strLocale:String = LocaleInfo.locale;
			if (LocaleInfo.UsingSystemFont())
				return;
			if (fHasUnicode)
				_uic.setStyle("fontFamily", ['Trebuchet MS', 'Lucida Grande', 'Arial', 'Verdana', '_sans']);
			else
				_uic.clearStyle("fontFamily");
		}
		
		private function HasUnicode(): Boolean {
			for each (var strField:String in _astrFields) {
				if (strField in _uic && !hasGlyphs(_uic[strField])) return true; // Found some unicode
			}
			return false; // No unicode found.
		}

		private function hasGlyphs(str:String): Boolean {
			if (str == null) return true;
			var afntFonts:Array = Font.enumerateFonts(false);
			if (afntFonts.length == 0) return false;
			return afntFonts[0].hasGlyphs(str);
		}
	}
}