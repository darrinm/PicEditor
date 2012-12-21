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
package
{
	import mx.styles.StyleManager;
	import flash.events.IEventDispatcher;
	import mx.events.StyleEvent;
	
	public class FontLoader
	{
		[Bindable] public var label:String = "preinit";
		[Bindable] public var errorText:String = "";
		
		private var _strFontName:String;
		private var _strFontStyle:String;
		private var _strSwfUrl:String;
		private var _strOutputBase:String;
		
		private var _fnComplete:Function;
		
		public function get fontName(): String {
			return _strFontName;
		}
		
		public function get swfUrl(): String {
			return _strSwfUrl;
		}
		
		public function get outputBase(): String {
			return _strOutputBase;
		}
		
		public function get fontStyle(): String {
			return _strFontStyle;
		}
		
		public function FontLoader(strFontName:String, strFontStyle:String, strSwfUrl:String, strOutputBase:String) {
			_strFontName = strFontName;
			_strFontStyle = strFontStyle;
			_strSwfUrl = strSwfUrl;
			_strOutputBase = strOutputBase;
			label = "Waiting to render " + strFontName;
		}
		
		public function Unload(): void {
			StyleManager.unloadStyleDeclarations(_strSwfUrl);
		}
		
		public function Load(fnComplete:Function): void {
			_fnComplete = fnComplete;
			label = "Loading " + _strFontName;
			var evtd:IEventDispatcher = StyleManager.loadStyleDeclarations(_strSwfUrl);
			evtd.addEventListener(StyleEvent.COMPLETE, OnLoadComplete);
			evtd.addEventListener(StyleEvent.PROGRESS, OnLoadProgress);
			evtd.addEventListener(StyleEvent.ERROR, OnLoadError);
		}

		private function OnLoadProgress(evt:StyleEvent): void {
			if (evt.bytesTotal > 0 && evt.bytesLoaded > 0) {
				var nPctDone:Number = Math.round(100 * evt.bytesLoaded / evt.bytesTotal);
				label = "Loading " + _strFontName + ", " + nPctDone + "% complete";
			}
		}
		
		private function OnLoadError(evt:StyleEvent): void {
			trace("Load error: " + evt.errorText);
			errorText = evt.errorText;
			_fnComplete(this, false);
		}
		
		private function OnLoadComplete(evt:StyleEvent): void {
			trace("Load complete: " + _strFontName);
			label = "Installing " + _strFontName;
			_fnComplete(this, true);
		}
		
		
	}
}