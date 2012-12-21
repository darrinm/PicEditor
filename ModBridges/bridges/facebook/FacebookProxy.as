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
// Inspired by Brian "Beej Jorgensen" Hall's flickrapi.py
//
// Encapsulated Facebook functionality
//
// Example usage:
// var fbp:FacebookProxy = new FacebookProxy(strAPIKey);
// fbp.auth_checkToken({auth_token: token}, OnCheckTokenComplete);
//
// private function OnCheckTokenComplete(rsp:XML): void {
//     if (rsp.@stat == "ok")
//         strToken = rsp.auth.token;
// }
//
// It is also possible to pass in an optional non-null obContext value to
// any proxy call and it will be returned as a second parameter on the
// fnComplete callback, e.g.:
//
// fbp.auth_checkToken({auth_token: token}, OnCheckTokenComplete, obContext);
//
// private function OnCheckTokenComplete(rsp:XML, obContext:Object): void {
//     if (rsp.@stat == "ok")
//         obContext.Whatever(rsp.auth.token);
// }
//
// FacebookProxy can hang onto the auth_token and will automatically add it as
// a parameter to all proxied calls, e.g.:
//
// fbp.token = rsp.auth_token
// fbp.auth_checkToken({}, OnCheckTokenComplete);

package bridges.facebook {
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import imagine.ImageDocument;
	
	import util.IRenderStatusDisplay;
	import util.RenderHelper;
	import util.URLLoaderPlus;
		
	
	public dynamic class FacebookProxy extends Proxy { // fbp
		private const kstrUploadForm:String = "/services/upload/";
		private const kstrReplaceForm:String = "/services/replace/";
		
		private var _strAPIKey:String;
		private var _strSecretKey:String;
		static private var s_cCalls:Number = 0;
		public var token:String; // AKA session_key
		
		public function FacebookProxy(strAPIKey:String, strSecretKey:String) {
			_strAPIKey = strAPIKey;
			_strSecretKey = strSecretKey;
		}
				
		// Handle all the Facebook API calls
		override flash_proxy function callProperty(obMethodName:*, ...aobArgs): * {
			try {
				var strMethodName:String = obMethodName.toString();
				var dctArgs:Object = aobArgs[0];
				var fnComplete:Function = aobArgs[1];
				var obContext:Object = aobArgs.length == 3 ? aobArgs[2] : null;
				if (dctArgs["api_key"] == undefined)
					dctArgs["api_key"] = _strAPIKey;
				dctArgs["method"] = "facebook." + strMethodName.replace("_", ".");
				dctArgs["call_id"] = GetCallId();
//				trace("call_id: " + dctArgs["call_id"]);
				dctArgs["v"] = "1.0";
				if (token)
					dctArgs["session_key"] = token;


				var urll:URLLoaderPlus = new URLLoaderPlus();
				urll.addEventListener(Event.COMPLETE, OnComplete);
				urll.addEventListener(IOErrorEvent.IO_ERROR, OnIOError);
				urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnSecurityError);
				urll.SetTimeout( 30000, OnTimeout );
				urll.fnComplete = fnComplete;
				urll.obContext = obContext;

				var strUrl:String = "https://api.facebook.com/method/" + strMethodName.replace("_", ".") + BuildQuery(dctArgs);
				
				// uncomment the following line to proxy all FB calls (for eg if their crossdomain.xml file goes bad)
				//strUrl = PicnikService.serverURL + "/proxy?method=get&url=" + encodeURIComponent(strUrl);
				
				var urlr:URLRequest = new URLRequest(strUrl);
				urll.load(urlr);
								
				// UNDONE: remember all outstanding calls and provide a Cancel method to close() them all?
			} catch (err:Error) {
				var strLog:String = "Facebook Proxy exception: " + strMethodName + ": " + err.toString()+ "/url:" + strUrl;
				PicnikService.Log(strLog, PicnikService.knLogSeverityError);
				
				trace("FacebookProxy.callProperty: methodName: " + strMethodName + ", err: " + err.toString());
				var rsp:XML = <error_response><error_code>0</error_code><error_msg>{"Exception: " + strMethodName + ": " + err.toString()}</error_msg></error_response>;
				fnComplete(rsp, obContext);
				return false;
			}
			return true;
		}
		
		private function GetCallId(): String {
			return String(new Date().time + s_cCalls++);
		}
		
		public function BuildQuery(dctArgs:Object): String {
			var strArgs:String = "?";
			for (var strArg:String in dctArgs)
				strArgs += encodeURIComponent(strArg) + "=" + encodeURIComponent(dctArgs[strArg]) + "&";
			return strArgs.slice(0, -1);
		}
		
		private function OnComplete(evt:Event): void {
			var data:String = evt.target.data;
			data = data.replace (/\n/g, ""); // remove all newlines -- decoder chokes on them
			var rsp:Object = JSON.decode(data);

			var urll:URLLoaderPlus = URLLoaderPlus(evt.target);
			if (urll.obContext != null)
				urll.fnComplete(rsp, urll.obContext);
			else
				urll.fnComplete(rsp);
		}
		
		private function OnTimeout(evt:Event, urll:URLLoaderPlus): void {
			var rsp:Object = {
					"error": {
						"message": "Timeout",
						"type": "TimeoutError"
					}
				}
			if (urll.obContext != null)
				urll.fnComplete(rsp, urll.obContext);
			else
				urll.fnComplete(rsp);
		}
				
		private function OnIOError(evt:IOErrorEvent): void {
			var rsp:Object = {
					"error": {
						"message": evt.text,
						"type": "IOError"
					}
				}

			var urll:URLLoaderPlus = URLLoaderPlus(evt.target);
			if (urll.obContext != null)
				urll.fnComplete(rsp, urll.obContext);
			else
				urll.fnComplete(rsp);
		}
		
		private function OnSecurityError(evt:SecurityErrorEvent): void {
			var rsp:Object = {
				"error": {
					"message": evt.text,
						"type": "SecurityError"
				}
			}
			var urll:URLLoaderPlus = URLLoaderPlus(evt.target);
			if (urll.obContext != null)
				urll.fnComplete(rsp, urll.obContext);
			else
				urll.fnComplete(rsp);
		}
		
		// Callback:
		// function fnComplete(obResp:Object, dResponseInfo:Object=null, obContext:Object=null): void
		public function Upload(imgd:ImageDocument, strSetId:String, strItemId:String, strCaption:String,
				fnComplete:Function, irsd:IRenderStatusDisplay=null, obContext:Object=null): void {
			var obParams:Object = {
				access_token:token,
				caption: strCaption
			};
			
			var strUrl:String = "https://graph.facebook.com/";
			if (strItemId) {
				strUrl += strItemId;
			} else if (strSetId) {
				strUrl += strSetId + "/photos";
			}
							
			// Prepend 'up_' to every user parameter
			var obPostParams:Object = new Object();
			for (var strParam:String in obParams)
				obPostParams["up_" + strParam] = obParams[strParam];
			
			var cxNew:Number = Math.min(imgd.width, 2048);
			var cyNew:Number = Math.min(imgd.height, 2048);
			
			var fnDone:Function = function (err:Number, strError:String=null,
						nHttpStatus:Number=200, dResponseInfo:Object=null, strResponse:String=null): void {
					if (err != PicnikService.errNone) {
						fnComplete({error: {message: strError, type: 0}}, null, obContext);
					} else {
						strResponse = strResponse.replace (/\n/g, ""); // remove all newlines -- decoder chokes on them
						var rsp:Object = JSON.decode(strResponse);
						fnComplete(rsp, dResponseInfo, obContext);
					}
				};

			new RenderHelper(imgd, fnDone, irsd).PostImage(strUrl, cxNew, cyNew, obPostParams);
		}
		
		public function GetGraphUrl( strEndPoint:String, dctArgs:Object = null ): String {
			if (!dctArgs) dctArgs = {};
			dctArgs['access_token'] = token;
			return "https://graph.facebook.com" + strEndPoint + BuildQuery(dctArgs);
		}
		
		public function PostGraph( strEndPoint:String, dctArgs:Object, fnComplete:Function, obContext:Object = null): void {
			var urll:URLLoaderPlus = new URLLoaderPlus();
			urll.addEventListener(Event.COMPLETE, OnComplete);
			urll.addEventListener(IOErrorEvent.IO_ERROR, OnIOError);
			urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnSecurityError);
			urll.SetTimeout( 30000, OnTimeout );
			urll.fnComplete = fnComplete;
			urll.obContext = obContext;
			
			var strUrl:String = GetGraphUrl( strEndPoint );			
			var urlr:URLRequest = new URLRequest(strUrl);
			urlr.method = URLRequestMethod.POST;
			if (dctArgs) {
				urlr.data = new URLVariables();
				// Pass on all the user parameters
				for (var strArg:String in dctArgs) {
					urlr.data[strArg] = dctArgs[strArg];
				}
			}
			urll.load(urlr);
		}	
		
		public function CallGraph( strEndPoint:String, dctArgs:Object, fnComplete:Function, obContext:Object = null ): void {
			var urll:URLLoaderPlus = new URLLoaderPlus();
			urll.addEventListener(Event.COMPLETE, OnComplete);
			urll.addEventListener(IOErrorEvent.IO_ERROR, OnIOError);
			urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnSecurityError);
			urll.SetTimeout( 30000, OnTimeout );
			urll.fnComplete = fnComplete;
			urll.obContext = obContext;
			
			var strUrl:String = GetGraphUrl( strEndPoint, dctArgs );			
			var urlr:URLRequest = new URLRequest(strUrl);
			urll.load(urlr);
		}
	}
}

