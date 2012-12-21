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
	import com.adobe.utils.DateUtil;
	public class FeedLoader
	{
		[Bindable] public var items:Array = [];
		
		private var _loader:URLLoader;
		private var _strSource:String;
		private var _nItemLimit:Number=-1;

		public function FeedLoader(strSource:String = null, nItemLimit:Number = -1){
			_nItemLimit = nItemLimit;
			if (strSource) source = strSource;
		}
		
		[Bindable]
		public function set source( strSource:String ): void {
			try {
				_strSource = strSource;
				_loader = new URLLoader();
				_loader.addEventListener( Event.COMPLETE, loadComplete );
            	_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
            	_loader.addEventListener( IOErrorEvent.IO_ERROR, ioErrorHandler);
				
				_loader.load( new URLRequest( strSource ) );
			} catch (e:Error) {
				// nothing to do
			}
		}
		
		public function get source():String {
			return _strSource;
		}
		
		private function loadComplete( e:Event ):void
		{
			var xml:XML = new XML( e.target.data );
			var aItems:Array = [];
			for each (var xmlItem:XML in xml.channel.item) {
				var obItem:Object = {};
				
				obItem.date = DateUtil.parseRFC822(String(xmlItem.pubDate));
				obItem.description = String(xmlItem.description);
				obItem.title = String(xmlItem.title);
				obItem.link = String(xmlItem.link);
				
				aItems.push(obItem);
				if (_nItemLimit > 0 && aItems.length >= _nItemLimit)
					break;
			}
			items = aItems;
		}
		
        private function securityErrorHandler(event:SecurityErrorEvent):void {
            // do nothing ... maybe we should retry?
        }		
        private function ioErrorHandler(event:IOErrorEvent):void {
            // do nothing ... maybe we should retry?
        }
	}
}