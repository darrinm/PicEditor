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
	import mx.styles.StyleManager;
	import mx.events.StyleEvent;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.utils.Timer;
	
	public class FontLoader
	{
		private static var _fl:FontLoader = new FontLoader();
		private var _nFontsLoading:Number = 0;
		private static const knMaxAsyncLoads:Number = 2;
		private static const knMaxRetries:Number = 5;
		private static const knMaxImmediateRetries:Number = 2;
		private var _aobFontsPending:Array = new Array();
		private var _astrUnload:Array = new Array();
		private var _nFontsLoaded:Number = 0;
		private var _obFontResources:Object = new Object();

		public static function AddReference(strUrl:String, obReferrer:Object, fnCallback:Function): Boolean {
			return GetFontResource(strUrl).AddReference(obReferrer, fnCallback);
		}
		
		public static function RemoveReference(strUrl:String, obReferrer:Object): void {
			GetFontResource(strUrl).RemoveReference(obReferrer);
		}
		
		public static function GetFontResource(strUrl:String): FontResource {
			return global._GetFontResource(strUrl);
		}
		
		private function _GetFontResource(strUrl:String): FontResource {
			if (!(strUrl in _obFontResources)) {
				_obFontResources[strUrl] = new FontResource(strUrl);
			}
			return _obFontResources[strUrl];
		}
		
		public static function get global(): FontLoader {
			return _fl;
		}
		
		// If the font is already loaded, call the callback and return true
		// Otherwise, return false and start loading.
		public static function LoadFont(strUrl:String, fnCallback:Function): Boolean {
			return global.DoLoadFont(strUrl, fnCallback);
		}
		
		public static function UnloadFont(strUrl:String): void {
			global.DoUnloadFont(strUrl);
		}
		
		// If the font is already loaded, call the callback and return true
		// Otherwise, return false and start loading.
		public function DoLoadFont(strUrl:String, fnCallback:Function): Boolean {
			var fLoaded:Boolean = false;
			
			if (RemoveFromUnload(strUrl)) {
				// Already loaded. Just move it off the unload queue.
				fnCallback(false, null);
				fLoaded = true;
			} else {
				if (_nFontsLoading > knMaxAsyncLoads) {
					AddToPending(strUrl, fnCallback);
				} else {
					StartLoad(strUrl, fnCallback);
				}
			}
			return fLoaded;
		}
		
		private function StartLoad(strUrl:String, fnCallback:Function, nTry:Number=1): void {
			CleanUp();
			_nFontsLoading += 1;
			var strLoadUrl:String = strUrl;
			if (nTry > 1) {
				strLoadUrl = PicnikService.AppendParams(strUrl, {
						'try': nTry,
						'nocache': Math.random().toString()
						},
						false);
			}
			var evtd:IEventDispatcher = StyleManager.loadStyleDeclarations(strLoadUrl, false);
			evtd.addEventListener(StyleEvent.COMPLETE, function(evt:StyleEvent):void {
				OnLoad(strUrl, fnCallback, false, null, nTry);
			});
			evtd.addEventListener(StyleEvent.ERROR, function(evt:StyleEvent):void {
				OnLoad(strUrl, fnCallback, true, evt.errorText, nTry);
			});
		}
		
		private function OnLoad(strUrl:String, fnCallback:Function, fError:Boolean, strErrorText:String=null, nTry:Number=1): void {
			_nFontsLoading -= 1;
			// First, see if we need to retry
			if (fError && nTry <= knMaxRetries) {
				// For the first handful of retries, retry immediately.
				// if it still fails, presume it might be a transient connectivity problem, i.e.
				// wireless problems at Tully's or something.  In that case, successive retries have
				// an interval of 10, 20, 30... seconds between them.
				if (nTry <= knMaxImmediateRetries) {
					StartLoad(strUrl, fnCallback, nTry + 1); // Retry
				} else {
					var tmr:Timer = new Timer((nTry-knMaxImmediateRetries)*1000*10);
					tmr.addEventListener("timer", function( evt:Event ): void {
							StartLoad(strUrl, fnCallback, nTry + 1); // Retry		
							tmr.stop();
						} );			
					tmr.start();
					
				}
			} else { // Success or failure with no retries left
				// First, fire off any pending calls.
				if (_nFontsLoading <= knMaxAsyncLoads && _aobFontsPending.length > 0) {
					var obFont:Object = _aobFontsPending.pop();
					StartLoad(obFont.strUrl, obFont.fnCallback);
				}
				
				if (nTry > 1)
					PicnikService.Log("Loaded font after retry", PicnikService.knLogSeverityDebug);
				
				// Call back
				fnCallback(fError, strErrorText);
			}
		}
		
		public function DoUnloadFont(strUrl:String): void {
			if (!RemoveFromPending(strUrl)) {
				_astrUnload.push(strUrl);
			}
			CleanUp();
		}
		
		private function TooManyFonts():Boolean {
			// Tune this function
			// Max of 20 fonts + 5 on unload queue.
			return _nFontsLoaded > 20 && _astrUnload.length > 10;
		}
		
		private function CleanUp(): void {
			while (TooManyFonts() && _astrUnload.length > 0) {
				StyleManager.unloadStyleDeclarations(_astrUnload.shift(), false);
				_nFontsLoaded--;
			}
		}
		
		// Returns false if nPos < 0
		// Otherwise removes element at nPos and returns true
		private function RemoveArrayElement(a:Array, nPos:Number): Boolean {
			if (nPos >= 0) {
				for (var i:Number = nPos; i < (a.length-1); i++) {
					a[i] = a[i+1];
				}
				a.pop();
				return true;
			} else {
				return false;
			}
		}
		
		
		// Returns true if the font was pending and was removed
		// Returns false if the font was not pending
		private function RemoveFromPending(strUrl:String): Boolean {
			return RemoveArrayElement(_aobFontsPending, FindInPending(strUrl));
		}
		
		// Returns -1 if not found
		private function FindInPending(strUrl:String): Number {
			for (var i:Number = 0; i < _aobFontsPending.length; i++) {
				if (_aobFontsPending[i].strUrl == strUrl) return i;
			}
			return -1;
		}
		
		// Returns -1 if not found
		private function FindInUnload(strUrl:String): Number {
			for (var i:Number = 0; i < _astrUnload.length; i++) {
				if (_astrUnload[i] == strUrl) return i;
			}
			return -1;
		}
		
		// Returns true if found, otherwise false (not found, not removed)
		private function RemoveFromUnload(strUrl:String): Boolean {
			return RemoveArrayElement(_astrUnload, FindInUnload(strUrl));
		}
		
		
		
		private function AddToPending(strUrl:String, fnCallback:Function): void {
			_aobFontsPending.push({strUrl:strUrl, fnCallback:fnCallback});
		}
	}
}
