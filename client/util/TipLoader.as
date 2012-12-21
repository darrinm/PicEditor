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
	
	public class TipLoader
	{
		private static var _tl:TipLoader = null;
 		private var _ldr:URLLoader = null;
 		private var _obTipFiles:Object = {};

		// Loads a tip file and returns the tip
		// Returns true if the result came back immediately (callback was called before returning)
		// Callback looks like this:
		// OnTipLoaded(xml:XML <null on failure>, strTipFile:String, strTipId:String): void
		public static function GetTip(strTipFile:String, strTipId:String, fnCallback:Function): Boolean {
			return GetInstance()._GetTip(strTipFile, strTipId, fnCallback);
		}
		
		// Get all the tips in a file.
		// Returns true if the result came back immediately (callback was called before returning)
		// Callback looks like this:
		// OnTipsLoaded(xml:XML <null on failure>, strTipFile:String): void
		public static function GetTips(strTipFile:String, fnCallback:Function): Boolean {
			return GetInstance()._GetTips(strTipFile, fnCallback);
		}
		
		private static function GetInstance(): TipLoader {
			if (_tl == null) _tl = new TipLoader();
			return _tl;
		}
		
		public function TipLoader()
		{
		}
		
		private function GetTipPath(strTipFile:String): String {
			return PicnikBase.StaticUrl("../app/" + PicnikBase.Locale() + "/" + strTipFile );
		}
		
		private function _GetTips(strTipFile:String, fnCallback:Function): Boolean {
			if (strTipFile in _obTipFiles) {
				fnCallback(_obTipFiles[strTipFile] as XML, strTipFile);
				return true;
			} else {
				// Need to load the XML first
				_ldr = new URLLoader();
				_ldr.load(new URLRequest(GetTipPath(strTipFile)));
				
	 			_ldr.addEventListener(Event.COMPLETE, function (evt:Event):void {OnLoadComplete(evt, strTipFile, fnCallback)});
	 			_ldr.addEventListener(IOErrorEvent.IO_ERROR, function (evt:Event):void {OnLoadError(evt, strTipFile, fnCallback)});
	 			_ldr.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function (evt:Event):void {OnLoadError(evt, strTipFile, fnCallback)});
			}
 			return false;
		}
		
		private function _GetTip(strTipFile:String, strTipId:String, fnCallback:Function): Boolean {
			return _GetTips(strTipFile,
				function(xml:XML, strTipFile:String): void {
					if (!xml) {
						fnCallback(xml, strTipFile, strTipId);
					} else {
						fnCallback(FindTip(xml, strTipFile, strTipId), strTipFile, strTipId);
					}
				});
		}
		
		protected function FindTip(xmlTipFile:XML, strTipFile:String, strTipId:String): XML {
			var xmll:XMLList = xmlTipFile.Tip.(@id==strTipId);
			
			if (xmll.length() == 0) {
				trace("ERROR: Could not find tip " + strTipId + " in file " + strTipFile);
				return null;
			} else if (xmll.length() > 1) {
				trace("WARNING: Duplicate tip ID " + strTipId + " in file " + strTipFile);
			}
			return xmll[0];
		}

 		protected function OnLoadError(evt:Event, strTipFile:String, fnCallback:Function): void {
 			trace("Failed to load tip file " + strTipFile + ", " + evt);
 			fnCallback(null, strTipFile);
 		}
 		
 		protected function OnLoadComplete(evt:Event, strTipFile:String, fnCallback:Function): void {
 			var obSettings:Object = XML.settings();
			XML.ignoreWhitespace = false;
 			var xml:XML = XML(evt.currentTarget.data.replace(/[\n\r\t ]+/g, ' ')); // Replace newlines with spaces - text areas display new lines as <br>s
 			XML.setSettings(obSettings);
 			_obTipFiles[strTipFile] = xml;
 			fnCallback(xml, strTipFile);
 		}
	}
}