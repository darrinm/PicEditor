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
package util {
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	public class AlchemyLib {
		[Bindable] static public var inst:AlchemyLib = new AlchemyLib();
		[Bindable] public var isLoaded:Boolean = false;
		[Bindable] public var isLoading:Boolean = false;
		
		//
		// The good stuff, functions provided by the Alchemy module
		//
		
		/* nChromaSubsampling (-1=default, 0=none, 1=medium, 2=high) */
		static public function JPEGEncode(ba:ByteArray, cx:int, cy:int, nQuality:int,
				aobSegments:Array, nChromaSampling:int, fnCallback:Function): ByteArray {
			return inst._lib.JPEGEncode(ba, cx, cy, nQuality, aobSegments, nChromaSampling, fnCallback);
		}
		
		//
		// Boring stuff, all about loading the Alchemy module
		//
		
		private var _ldr:Loader;
		private var _lib:Object;
		private var _afnCallbacks:Array = [];
		private var _cRetries:int = 3;
		
		public function Load(fnCallback:Function): void {
			// Already loaded or trying to load it
			if (_lib) {
				fnCallback(true);
				return;
			}
	
			_afnCallbacks.push(fnCallback);
			if (_ldr)
				return;
				
			_ldr = new Loader();
			isLoading = true;
			
			var urlr:URLRequest = new URLRequest(PicnikBase.StaticUrl("../app/AlchemyLib.swf"));
	
			var fnOnLoadComplete:Function = function (evt:Event): void {
				_lib = _ldr.content;
				_ldr = null;
				isLoading = false;
				isLoaded = _lib != null;
				CallLoadCallbacks(isLoaded);
			}
			
			// On load failure retry 3 times before giving up
			var fnOnIOError:Function = function (evt:IOErrorEvent): void {
				if (_cRetries <= 0) {
					_ldr = null;
					isLoading = false;
					PicnikService.Log("AlchemyLib load failure: " + evt.text, PicnikService.knLogSeverityError);
					CallLoadCallbacks(false);
				} else {
					_cRetries--;
					
					// Include _cRetries in the URL to cache bust in case what's there is corrupted
					urlr = new URLRequest(PicnikBase.StaticUrl("../app/AlchemyLib.swf?retry=" + _cRetries));
					_ldr.load(urlr);
				}
			}

			var fnOnSecurityError:Function = function (evt:SecurityErrorEvent): void {
				_ldr = null;
				isLoading = false;
				CallLoadCallbacks(false);
			}
			
			_ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, fnOnLoadComplete);
			_ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, fnOnIOError);
			_ldr.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnOnSecurityError);
//			_ldr.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS, function (evt:HTTPStatusEvent): void { trace(evt); });
//			_ldr.contentLoaderInfo.addEventListener(Event.INIT, function (evt:Event): void { trace(evt); });
//			_ldr.contentLoaderInfo.addEventListener(Event.OPEN, function (evt:Event): void { trace(evt); });
//			_ldr.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, function (evt:ProgressEvent): void { trace(evt); });
//			_ldr.contentLoaderInfo.addEventListener(Event.UNLOAD, function (evt:Event): void { trace(evt); });
			
			_ldr.load(urlr);
		}
		
		private function CallLoadCallbacks(fSuccess:Boolean): void {
			while (_afnCallbacks.length > 0) {
				var fnCallback:Function = _afnCallbacks.pop();
				fnCallback(fSuccess);
			}
		}
	}
}
