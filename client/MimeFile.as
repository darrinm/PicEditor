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
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	
	public class MimeFile
	{
		private const _strBoundary:String = "XXXab0p4Jq0M2Yt08jU534c0pXXX"; // Random string for mime boundary
		private const kstrNewline:String = "\r\n";
		
		private var _astrData:Array = new Array();
		
		public function get dataArray(): Array {
			return _astrData;
		}
		
		public function push(obData:Object, strContentType:String = null, fAddContentType:Boolean = true): void {
			var strData:String = "";
			if (fAddContentType) {
				strData += kstrNewline;
				if (strContentType == null) {
					if (obData is XML) strContentType = "application/atom+xml";
					else strContentType = "text/plain";
				}
				strData += "Content-Type: " + strContentType + kstrNewline;
			}
			strData += obData.toString();
			_astrData.push(strData);
		}

		public function getBoundaryLine(): String {
			return "--" + _strBoundary + kstrNewline;
		}
		
		public function addMimeHeaders(urlr:URLRequest): void {
			if (urlr.requestHeaders == null) {
				urlr.requestHeaders = new Array();
			}
			urlr.requestHeaders.push(new URLRequestHeader("MIME-version", "1.0"));
			urlr.contentType = "multipart/related; separator=\"" + _strBoundary + "\"";
		}
		
		
		public function toString(): String {
			var strBody:String = "";
			strBody += "Media multipart posting" + kstrNewline;
			strBody += getBoundaryLine();
			for (var i:Number = 0; i < _astrData.length; i++) {
				strBody += _astrData[i] + kstrNewline;
				strBody += getBoundaryLine();
			}
			return strBody;
		}
	}
}