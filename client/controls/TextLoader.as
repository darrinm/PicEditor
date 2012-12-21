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
package controls {
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import mx.core.UIComponent;
	
	public class TextLoader extends UIComponent {
		[Bindable] public var text:String = "";
		[Bindable] public var condenseWhitespace:Boolean = true;
		private var _urll:URLLoader;
		private var _strUrl:String;
		
		[Bindable]
		public function get url(): String {
			return _strUrl;
		}
		
		public function set url(strUrl:String): void {
			_strUrl = strUrl;
			if (!_strUrl || _strUrl.length == 0) {
				text = "";
				return;
			}			
			_urll = new URLLoader();
			_urll.addEventListener(Event.COMPLETE, OnComplete);
			_urll.addEventListener(IOErrorEvent.IO_ERROR, OnIOError);
			_urll.load(new URLRequest(strUrl));
		}
		
		private function OnComplete(evt:Event): void {
			text = _urll.data;
			if (condenseWhitespace)
				text = condenseHtmlText( text );
			_urll.removeEventListener(Event.COMPLETE, OnComplete);
			_urll.removeEventListener(IOErrorEvent.IO_ERROR, OnIOError);
			_urll = null;
		}
		
		private function OnIOError(evt:Event): void {
			trace("Error loading text: " + evt);
			text = "";
		}
		
		private function condenseHtmlText(strHtml:String): String {
			// condense whitespace down to single spaces
			strHtml = strHtml.replace( /\s+/g, " " );
			
			// replace all <br>, <br/>, <br /> with \n
			strHtml = strHtml.replace( /<br\s*\/?>/g, "\n" );
			
			// replace all newline-followed-by-space with just a newline.
			strHtml = strHtml.replace( /\n +/g, "\n" );
			
			return strHtml;
		}
		
	}
}
