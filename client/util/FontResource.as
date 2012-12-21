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
	import flash.utils.Dictionary;
	
	public class FontResource
	{
		////////////// Loader Constants //////////////
		public static const knUnloaded:Number = 0;
		public static const knPending:Number = 1;
		public static const knLoaded:Number = 2;
		public static const knError:Number = -1;
		
		////////////// Loader members //////////////
		private var _strUrl:String = null;
		private var _dtReferrers:Dictionary = new Dictionary();
		private var _nState:Number = knUnloaded;
		private var _strErrorText:String = "";
		
		public function FontResource(strUrl:String) {
			_strUrl = strUrl;
		}

		// Add a reference to the font.
		// If the font is already loaded, call the callback immediately and return true
		// If the font is not loaded, start loading and return false.
		public function AddReference(obReferrer:Object, fnCallback:Function): Boolean {
			if (_dtReferrers[obReferrer])
				RemoveReference(obReferrer);
				
			var fLoaded:Boolean = false;
				
			_dtReferrers[obReferrer] = fnCallback;
			if (_nState == knUnloaded) {
				fLoaded = Load();
			} else if (_nState == knLoaded || _nState == knError) {
				fnCallback(this);
				fLoaded = true;
			}
			return fLoaded;
		}
		
		public function RemoveReference(obReferrer:Object): void {
			if (!_dtReferrers[obReferrer])
				throw new Error("Removing non-existant reference to font. Font = " + _strUrl + ", referrer = " + obReferrer);
			delete _dtReferrers[obReferrer];
			if (state == knLoaded && ! isReferenced) {
				Unload();
			}
		}
		
		public function get isReferenced(): Boolean {
			for (var ob:Object in _dtReferrers)
				if (_dtReferrers[ob])
					return true;
			return false;
		}
		
		public function get state(): Number {
			return _nState;
		}

		public function get errorText(): String {
			return _strErrorText;
		}
		
		private function Unload(): void {
			// Make sure there are no references
			if (isReferenced)
				throw new Error("Unloading font with references. Font = " + _strUrl);
			if (_nState != knLoaded)
				throw new Error("Unloading font which is not loaded. Font = " + _strUrl + ", state = " + _nState);
			_nState = knUnloaded;
			_strErrorText = "";
			if (_strUrl != "") {
				FontLoader.UnloadFont(_strUrl);
			}
			
		}
		
		// If the font is already loaded, call the callback and return true
		// Otherwise, return false and start loading.
		private function Load(): Boolean {
			if (_nState != knUnloaded)
				throw new Error("Loading font " + _strUrl + " which is not unloaded (state == " + _nState + ")");
				
			var fLoaded:Boolean = false;
			_nState = knPending;
			if (_strUrl == "") {
				// System font doesn't need to be loaded.
				OnStyleLoadComplete();
				fLoaded = true;
			} else {
				fLoaded = FontLoader.LoadFont(_strUrl, OnStyleLoadComplete);
			}
			return fLoaded;
		}

		private function DoCallbacks(): void {
			for each (var fnCallback:Function in _dtReferrers) {
				fnCallback(this);
			}
		}
		
		private function OnStyleLoadComplete(fError:Boolean=false, strError:String=null): void {
			if (fError) {
				_strErrorText = strError;
				_nState = knError;
				DoCallbacks();
			} else {
				_nState = knLoaded;
				DoCallbacks();
				if (! isReferenced) {
					Unload();
				}
			}
		}
	}
}