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
package imagine.documentObjects.frameObjects
{
	import imagine.documentObjects.Clipart;
	import imagine.documentObjects.DocumentStatus;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	
	[Event(name="status_changed", type="documentObjects.frameObjects.FrameObjectEvent")]
	
	public class ClipartLoader extends Loader
	{
		private var _strUrl:String = null;
		private var _cRetriesLeft:Number = 2;
		
		private var _nStatus:Number = DocumentStatus.Static;
		
		public function ClipartLoader(strUrl:String)
		{
			contentLoaderInfo.addEventListener(Event.COMPLETE, OnComplete);
			contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, OnError);
			_strUrl = strUrl;
			StartLoad();
		}
		
		public function get url(): String {
			return _strUrl;
		}
		
		public function get status(): Number {
			return _nStatus;
		}
		
		public function set status(n:Number): void {
			if (_nStatus != n) {
				_nStatus = n;
				dispatchEvent(new FrameObjectEvent(FrameObjectEvent.STATUS_CHANGED));
			}
		}
		
		public override function unload():void {
			super.unload();
			status = DocumentStatus.Static;
		}
		
		private function StartLoad(strCacheBuster:String=""): void {
			status = DocumentStatus.Loading;
			load(new URLRequest(PicnikBase.StaticUrl(urlBasePath + _strUrl + strCacheBuster)));
		}
		
		private function get urlBasePath(): String {
			return Clipart.GetClipartBasePath();
		}
		
		private function OnComplete(evt:Event): void {
			status = DocumentStatus.Loaded;
		}
		
		private function OnError(evt:IOErrorEvent): void {
			if (_cRetriesLeft > 0) {
				_cRetriesLeft--;
				trace("shape load, retrying: " + this._strUrl + ", " + evt.toString());
				StartLoad("?cb=" + _cRetriesLeft.toString());
			} else {
				trace("shape error, no retries left: " + this._strUrl + ", " + evt.toString());
				status = DocumentStatus.Error;
			}
		}
	}
}