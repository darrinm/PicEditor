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
package bridges {
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
	import util.URLLoaderPlus;
	
	public class ProxyURLLoader extends URLLoaderPlus {
		public var fnProgress:Function;
		
		public var _urlr:URLRequest = null;
		
		public static const kerrNone:Number = 0;
		public static const kerrIOError:Number = 1;
		public static const kerrSecurityError:Number = 2;
		
		public static const PROXY_VERSION:int = 2;
		
		public function ProxyURLLoader(urlr:URLRequest, obContext:Object=null,
				fnComplete:Function=null, fnProgress:Function=null, strMethod:String=null, obProxyParams:Object=null) {
			super();
			_urlr = urlr;
			this.fnComplete = fnComplete;
			this.fnProgress = fnProgress;
			this.obContext = obContext;
			addEventListener(ProgressEvent.PROGRESS, OnProgress);
			addEventListener(IOErrorEvent.IO_ERROR, OnIOError);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnSecurityError);
			addEventListener(Event.COMPLETE, OnComplete);

			if (strMethod == null) strMethod = urlr.method;
			
			if (urlr.method != URLRequestMethod.POST) {
				// Not a post, so use the GET proxy
				urlr.method = URLRequestMethod.POST;
				urlr.data = urlr.url;
				urlr.url = PicnikService.serverURL + "/proxy/get/?v=" + PROXY_VERSION + "&nocache=" + Math.random().toString();
			} else {
				// Request is a post, so follow through as normal
				// UNDONE: Posting with query params will return occasional 2032 errors (especially on IE)
				// We need to figure out how to add our params to the post data.
				urlr.url = PicnikService.serverURL + "/proxy?v=" + PROXY_VERSION + "&url=" + escape(urlr.url) + "&method=" + strMethod + "&nocache=" + Math.random().toString();
			}
			
			if (null != obProxyParams) {
				for (var strParam:String in obProxyParams) {
					urlr.url += "&" + strParam + "=" + escape(obProxyParams[strParam]);					
				}				
			}
			
			// Change the URLRequest to point to our server with a parameter referencing
			// the original URL
			load(urlr);
		}
		
		private function OnIOError(evt:IOErrorEvent): void {
			if (fnComplete != null) {
				try {
					fnComplete(this, kerrIOError, evt.text);
				} catch (e:Error) {
					PicnikService.LogException("Exception in ProxyUrlLoader.OnIOError: " + this, e);
				}
			}
		}			
		
		private function OnSecurityError(evt:SecurityErrorEvent): void {
			if (fnComplete != null) {
				try {
					fnComplete(this, kerrSecurityError, evt.text);
				} catch (e:Error) {
					PicnikService.LogException("Exception in ProxyUrlLoader.OnSecurityError: " + this, e);
				}
			}
		}	
		
		private function OnProgress(evt:ProgressEvent): void {
			if (fnProgress != null) {
				try {
					fnProgress(this, Math.round(evt.bytesLoaded / evt.bytesTotal * 100));
				} catch (e:Error) {
					PicnikService.LogException("Exception in ProxyUrlLoader.OnProgress: " + this, e);
				}
			}
		}
		
		private function OnComplete(evt:Event): void {
			if (fnComplete != null) {
				try {
					if (PROXY_VERSION == 2) {
						
						// we need to de-base-64 and de-zlib the result
						import mx.utils.Base64Decoder;
						var strBase64CompressedData:String = data;
						var b64d:Base64Decoder = new Base64Decoder();
						b64d.decode(strBase64CompressedData);
						var baCompressedData:ByteArray = b64d.drain();
						baCompressedData.uncompress();
						data = baCompressedData.toString();
					}
					fnComplete(this, kerrNone, null);
				} catch (e:Error) {
					PicnikService.LogException("Exception in ProxyUrlLoader.OnComplete: " + this, e);
				}
			}
		}
		
		override public function toString(): String {
			var str:String = "ProxyURLLoader[";
			if (_urlr) {
				if (_urlr.url) {
					str += "url=";
					if (_urlr.url.length > 200) {
						str += _urlr.url.substr(0,200) + "...";
					} else {
						str += _urlr.url;
					}
				}
				var strData:String;
				if (_urlr.data) {
					strData = _urlr.data.toString();
					if (strData.length > 400) {
						str += ", post data=" + strData.substr(0,400) + "...";
					} else {
						str += ", post data=" + strData;
					}
				}
				if (data) {
					strData = String(data);
					if (strData.length > 400) {
						str += ", response data=" + strData.substr(0,800) + "...";
					} else {
						str += ", response data=" + strData;
					}
				}
			}
			str += "]";
			return str;
		}
	}
}
