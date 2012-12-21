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
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Security;

	public class SecureURLLoader
	{
		private var _strAPIEndPoint:String = null;
		private var _strAPIBaseUrl:String = null;

		public function SecureURLLoader(strUrl:String, fSecure:Boolean) {
			// trace('SecureURLLoader init');
			SetURL(strUrl, fSecure);
		}

		private function SetURL(strUrl:String, fRequireHttps:Boolean): void
		{
			// if we're local, we don't do secure transactions.
			// if we're loaded from one of our test, staging or release servers, we
			// use that server for secure transactions.
			// if we're loaded from an external (partner) server, we use our server for secure transactions
			var nParsed:Number = 0;
			var nIndex:Number = 0;
			var strProtocol:String = "";
			var strSURL:String = "";
			var strDomain:String = null;

			nIndex = strUrl.indexOf("://");
			if (nIndex > 0) {
				nParsed = nIndex + 3;
				strProtocol = strUrl.substr(0,nIndex + 3);
			}
			nIndex = strUrl.indexOf("/", nParsed);
			if (nIndex > 0) {
				strSURL = strUrl.substring( nParsed, nIndex );
			} else {
				strSURL = strUrl.substr( nParsed );
			}

			if (strSURL.match(new RegExp("\.mywebsite.com$", "i")))
				strDomain = strSURL;
			else
				strDomain = "www.mywebsite.com";

			if (fRequireHttps)
				_strAPIBaseUrl = "https://";
			else
				_strAPIBaseUrl = "http://";

			_strAPIBaseUrl += strDomain;

			_strAPIEndPoint = _strAPIBaseUrl + "/api/rest";
		}

		// fnOnGotData(strData:String): void
		// fnError(strError:String): void
		// TODO(bsharon): pull this method into PicnikAmfConnector, extract common code
		public function SecureLoadUrlTextData(strEndpoint:String, obPostData:Object, fnOnGotData:Function, fnError:Function): void {
			var strUrl:String = _strAPIBaseUrl;
			strUrl += strEndpoint;

			var fnOnLoadComplete:Function = function(evt:Event): void {
				fnOnGotData(String(urll.data));
			}

			var fnOnLoadError:Function = function (evt:Event=null): void {
				var strError:String = (evt == null ? "" : evt.toString()) + ", " + String(strUrl);
				fnError(strError);
			}

			var urlr:URLRequest = new URLRequest(strUrl);
			urlr.method = URLRequestMethod.POST;
			urlr.requestHeaders = new Array(new URLRequestHeader("Content-Type", "text/plain"));

			urlr.data = obPostData;

			var urll:URLLoader = new URLLoader(urlr);
			urll.dataFormat = URLLoaderDataFormat.TEXT;

			urll.addEventListener(Event.COMPLETE, fnOnLoadComplete);
			urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnOnLoadError);
			urll.addEventListener(IOErrorEvent.IO_ERROR, fnOnLoadError);

			urll.load(urlr);
		}

		// TODO(bsharon): pull this method next to CookedCallMethod, extract common code
		public function SecureCookedCallMethod(obParams:Object, xmlPayload:XML,
				fnComplete:Function, fnDone:Function=null, fnProgress:Function=null,
				fnOnSendFault:Function=null, fnOnSendResult:Function=null, fnOnSend:Function=null): Boolean
		{
			if (_strAPIEndPoint == null) {
				trace ('API End point not initialized');
				return false;
			}

			var urlr:URLRequest = new URLRequest(_strAPIEndPoint);

			if (xmlPayload) {
				urlr.method = URLRequestMethod.POST;
				urlr.requestHeaders = new Array(new URLRequestHeader("Content-Type", "application/xml;charset=utf-8"));
				urlr.data = xmlPayload;
				urlr.url += "?";
				for (var strParam:String in obParams)
					urlr.url += encodeURIComponent(strParam) + "=" + encodeURIComponent(obParams[strParam]) + "&";
				urlr.url = urlr.url.slice(0, -1);
			} else {
				urlr.requestHeaders = new Array(new URLRequestHeader("Content-Type", "text/html; charset=utf-8"));
				var urlv:URLVariables = new URLVariables;
				for (var key:String in obParams) {
					urlv[key] = obParams[key];
				}
				urlr.data = urlv;
			}


			var urll:URLLoader = new URLLoader();

			// Add everything the result handler might need, in particular if it
			// needs to retry the call after logging in
			var obContext:Object = {
				urlLoader:urll,
				obParams: obParams,
				xmlPayload: xmlPayload,
				fnComplete: fnComplete,
				fnDone: fnDone,
				fnProgress: fnProgress,
				bSecure: true
			}

			var fnOnSendResultWithContext:Function = function( evt:Event ):void {
				fnOnSendResult( obContext, evt );
			}

			var fnOnSendFaultWithContext:Function = function( evt:Event ):void {
				fnOnSendFault( obContext, evt );
			}

			urll.addEventListener(Event.COMPLETE, fnOnSendResultWithContext);
            urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnOnSendFaultWithContext);
            urll.addEventListener(IOErrorEvent.IO_ERROR, fnOnSendFaultWithContext);

			urll.load(urlr);

			if (fnOnSend != null) fnOnSend( obContext, urlr.url, urlr.data );
			return true;
		}

	}
}
