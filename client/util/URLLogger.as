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
	
	import mx.utils.ObjectProxy;
	
	public class URLLogger  {
		private static const knLogsToKeep:Number = 50;
		
		private static var _aLogs:Array = [];
		private static var _nId:Number = 0;
		
		public static function LogRequest( strUrlIn:String, oRequest:Object ):Number {
			_nId++;
			var oLog:Object = {
				nId: _nId,
				strUrl: strUrlIn,
				dtStart: new Date(),
				dtEnd: null,
				oRequest: oRequest,
				oResponse: null,
				strStatus: null
			};			
				
			// push this request onto the log, and if the log is getting
			// too long then remove an old request off the the front
			_aLogs.push( oLog );
			if (_aLogs.length > knLogsToKeep) {
				_aLogs.shift();
			}
			
			return _nId;
		}
		
		public static  function LogResponse( nId:Number, strStatus:String, oResponse:Object = null ):void {
			for (var i:Number = _aLogs.length - 1; i >= 0; i--) {
				if (_aLogs[i].nId == nId) {
					_aLogs[i].dtEnd = new Date();
					_aLogs[i].strStatus = strStatus;
					_aLogs[i].oResponse = oResponse;
					return;
				}
			}	
		}
		
		private static function _obToString( ob:*, t:String = "\t" ):String {
			var s:String = "";
			if (ob is Array) { 
				s = "[";
				for( var i:Number = 0; i < ob.length; i++ ) {
					s += _obToString( ob[i], t );
				}
				s += "]";
			} else if (ob is XML) {
				s = (ob as XML).toXMLString() + "\n";
			} else if (typeof ob == "function") {
				s = "(function)";
			} else if (typeof ob == "object") {
				s = "{\n";
				for (var p:* in ob){
					s += t + p + ": " + _obToString(ob[p], t + "\t") + "\n";
				}
				s += t + "}";
			} else {
				s = ob;
			}
			if (s.length > 10 && s.substr(0,5).toLowerCase() == "<?xml") {
				s = XML(s).toXMLString();
			}
			
			return EncodeStr(s);
		}

		
		private static function isValidXMLCharCode(n:Number): Boolean {
            return ((n == 0x9) ||
                (n == 0xA) ||
                (n == 0xD) ||
                ((n >= 0x20) && (n <= 0xD7FF)) ||
                ((n >= 0xE000) && (n <= 0xFFFD)) ||
                ((n >= 0x10000) && (n <= 0x10FFFF)));
 			
		}
		
		private static function EncodeStr(str:String): String {
			return str;
			
			var strOut:String = "";
			for (var i:Number = 0; i < str.length; i++) {
				var n:Number = str.charCodeAt(i);
				if (isValidXMLCharCode(n))
					strOut += str.charAt(i);
				else
					strOut += "#x" + n;
			}
			return strOut;
		}
		
		public static  function Dump():XML {
			var xml:XML = <urllog></urllog>;
			for (var i:Number = 0; i < _aLogs.length; i++) {
				var xmlChild:XML = <log id={_aLogs[i].nId} start={_aLogs[i].dtStart} end={_aLogs[i].dtEnd} status={_aLogs[i].strStatus}>
						<url>{_aLogs[i].strUrl}</url>
						<request>{_obToString(_aLogs[i].oRequest)}</request>
						<response>{_obToString(_aLogs[i].oResponse)}</response>
					</log>			
				xml.appendChild(xmlChild);
			}
			return xml;
		}
	}
}