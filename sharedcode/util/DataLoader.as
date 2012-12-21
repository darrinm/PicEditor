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

	public class DataLoader
	{
		private static var _obMapUrlToLoader:Object = {};
		
		protected var _obResult:Object = null;
		protected var _strError:String = null;

		private var _strUrl:String;
		private var _urll:URLLoader;
		private var _urlr:URLRequest;
		private var _afnListeners:Array = [];
		
		protected var _nRetriesLeft:Number = 1;
		
		public function DataLoader(): void {
		}
		
		// function fnComplete(obResult:Object, strError:String=null): void
		public static function LoadData(strUrl:String, fnComplete:Function, clParser:Class): void {
			var dldr:DataLoader = null;
			if (!(strUrl in _obMapUrlToLoader)) {
				dldr = new clParser();
				dldr.StartLoad(strUrl);
			} else {
				dldr = _obMapUrlToLoader[strUrl];
			}
			dldr.AddListener(fnComplete);
		}

		private function StartLoad(strUrl:String): void {
			_strUrl = strUrl;
			
			// Add the URLLoader event listeners before firing off the load so we will
			// be sure to catch any up-front errors (e.g. URLRequest validation)			
			_urll = new URLLoader();
			_urll.addEventListener(Event.COMPLETE, OnLoaded);
			_urll.addEventListener(IOErrorEvent.IO_ERROR, OnLoadError);
			_urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnLoadError);
			_urlr = new URLRequest(strUrl);
			_urll.load(_urlr);
			
		}
		
		// Override in sub-classes
		// Given obData, set _obResult and _strError accordingly
		protected function ProcessResults(obData:Object): void {
			_obResult = obData; // Return what we got.
		}
		
		private function OnLoaded(evt:Event): void {
			try {
				ProcessResults(_urll.data);
			} catch (e:Error) {
				// Corrupted download? OnLoadError will retry w/ cache busting
				_obResult = null;
				OnLoadError(evt);
				return;
			}
			DoCallbacksIfNeeded();
		}
		
		private function OnLoadError(evt:Event): void {
			if (_nRetriesLeft >= 1) {
				_nRetriesLeft -= 1;
				_urlr = new URLRequest(_strUrl + "&nocache=" + Math.random().toString());
				_urll.load(_urlr);
			} else {
				var strError:String = "";
				if ("text" in evt) strError = evt["text"];
				else strError = evt.toString();
				_strError = strError;
				_obResult = null;
				DoCallbacksIfNeeded();
			}
		}
		
		// function fnComplete(obResult:Object, strError:String=null): void
		public function AddListener(fnComplete:Function): void {
			_afnListeners.push(fnComplete);
			Application.application.callLater(DoCallbacksIfNeeded);
		}
		
		private function DoCallbacksIfNeeded(): void {
			if (_obResult != null || _strError != null) {
				while (_afnListeners.length > 0) {
					var fnComplete:Function = _afnListeners.pop();
					fnComplete(_obResult, _strError);
				}
			}
		}
	}
}
