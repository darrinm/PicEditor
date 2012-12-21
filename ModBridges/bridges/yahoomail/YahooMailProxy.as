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
// YahooMailProxy:
// Inspired by FlickrProxy.as, which was...
// Inspired by Brian "Beej Jorgensen" Hall's flickrapi.py
//
// Encapsulated YahooMail functionality
//
// Example usage:
// var ymp:YahooMailProxy = new YahooMailProxy(strAppId, strSharedSecret);
// ymp.GetMessage({ truncateAt: 10000, fid: "Inbox", message: [ { mid: xxx, enableWarnings: true, expandCIDReferences: true } ]}, OnGetMessage);
//
// private function OnGetMessage(obResponse:Object): void {
//     if (obResponse.result)
//         strSubject = obResponse.result.message.subject;
// }
//
// It is also possible to pass in an optional non-null obContext value to
// any proxy call and it will be returned as a second parameter on the
// fnComplete callback, e.g.:
//
// ymp.GetMessage({truncateAt: 10000, fid: "Inbox", message: [ { mid: xxx, enableWarnings: true, expandCIDReferences: true } ]}, OnGetMessage, obContext);
//
// private function OnGetMessage(obResponse:Object, obContext:Object): void {
//     if (obResponse.result)
//         obContext.Whatever(obResponse.result.message.subject);
// }
//
// YahooMailProxy holds the "token" and will acquire the "auth cookie" and "WSSID" as needed
// (they expire after an hour).

package bridges.yahoomail {
	import bridges.ProxyURLLoader;
	import bridges.storageservice.StorageServiceError;
	
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;
	import com.adobe.utils.StringUtil;
	
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	import flash.utils.getTimer;
	
	import util.UniversalTime;
			
	public dynamic class YahooMailProxy extends Proxy { // ymp
		public var token:String;
		public var apiUrl:String;
		
		// Set this whenever we set the token
		// Log this if we get an unexpected null token
		private var _strTokenClearedContext:String = "Initial";
		
		private var _strAppId:String;
		private var _strSharedSecret:String;
		private var _strAuthCookie:String;
		private var _strWSSID:String;
		
		public function YahooMailProxy(strAppId:String, strPrivateKey:String) {
			_strAppId = strAppId;
			_strSharedSecret = strPrivateKey;
			
			// Yippie, mail.yahooapis.com has an open crossdomain.xml file!
			apiUrl = "http://mail.yahooapis.com/ws/mail/v1.1/jsonrpc";
		}
		
		public function SetToken(strToken:String, strContext:String): void {
			if (strToken == null)
				_strTokenClearedContext = strContext;
			token = strToken;
		}
		
		public function get loginURL(): String {
			// The tricky part here is 'ts' which is supposed to be within +/- 5 minutes of the time
			// Yahoo's servers think it is. Client clocks are totally unreliable so we have our server
			// return its time in response to clientconnect and PicnikService uses it to initialize
			// the UniversalTime class.
			var strBase:String = "/WSLogin/V1/wslogin?appid=" + _strAppId
					+ "&ts=" + UniversalTime.seconds
					+ "&send_userhash=1"
					+ "&appdata=" + AccountMgr.GetInstance().GetUserId();
			var strSig:String = MD5.hash(strBase + _strSharedSecret);
			return "https://api.login.yahoo.com" + strBase + "&sig=" + strSig;
		}
		
		public function get tokenLoginURL(): String {
			var strBase:String = "/WSLogin/V1/wspwtoken_login?appid=" + _strAppId
					+ "&token=" + encodeURIComponent(token)
					+ "&ts=" + UniversalTime.seconds;
			var strSig:String = MD5.hash(strBase + _strSharedSecret);
			return "https://api.login.yahoo.com" + strBase + "&sig=" + strSig;
		}
		
		public function set authCookie(strAuthCookie:String): void {
			_strAuthCookie = strAuthCookie;
		}
		
		public function get authCookie(): String {
			return _strAuthCookie;
		}
		
		public function get appId(): String {
			return _strAppId;
		}
		
		public function get WSSID(): String {
			return _strWSSID;
		}
		
		public function GetAuthCookie(fnComplete:Function, strContext:String): void {
			_strAuthCookie = null;
			_strWSSID = null;
			var cTries:int = 0;
			var urll:ProxyURLLoader;
			
			var fnOnGetAuthToken:Function = function (urllT:ProxyURLLoader, err:Number=0, strError:String=null): void {
				var strLogError:String = null;
				if (err != ProxyURLLoader.kerrNone) {
					strLogError = strError + "[" + err + "]";
				}
				
				if (strLogError == null) {
					var xml:XML;
					try {
						xml = XML(urllT.data);
					} catch (err:Error) {
						// Hmmm... not a response we were expecting (corrupted? service down?)
						strLogError = "Error parsing xml: " + err;
						try {
							strLogError += ", " + String(urllT.data).substr(0, 500);
						} catch (err2:Error) {
						}
					}
				}
				
				// We get a BBAuthTokenLoginResponse on success or a wspwtoken_login_response on failure
				if (strLogError == null) {
					if (xml.name().localName == "BBAuthTokenLoginResponse") {
						try {
							_strAuthCookie = xml.Success.Cookie.text(); // UNDONE: trim leading/trailing whitespace?
							_strWSSID = xml.Success.WSSID.text();
						} catch (err:Error) {
							strLogError = "Error extracting cookie: " + err;
						}
					} else if (xml.name().localName == "wspwtoken_login_response") {
						strLogError = "error code: " + xml.Error.ErrorCode.text() + ", description: " + xml.Error.ErrorDescription.text();
					} else {
						strLogError = "localName is not known: " + xml.name().localName;
					}
				}
				if (strLogError == null) {
					fnComplete(true); // Success
				} else { // Error
					cTries += 1;
					PicnikService.Log("YahooMailProxy: GetAuthCookie failure #" + cTries + ": " + strLogError, PicnikService.knLogSeverityWarning);
					if (cTries > 2)
						fnComplete(false); // Give up
					else
						urll = new ProxyURLLoader(urlr, null, fnOnGetAuthToken); // Retry
					return;
				}
			}
			if (token == null) {
				// Can't work without a token
				var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount("YahooMail");
				PicnikService.Log("YahooMailProxy: GetAuthCookie failure, token is null. Context: " + strContext + ", " + _strTokenClearedContext + ", tpa: " + tpa.storageService.IsLoggedIn() + ": " + String(tpa.GetToken()).substr(0, 10), PicnikService.knLogSeverityWarning);
				return;
			}
			
			var urlr:URLRequest = new URLRequest(tokenLoginURL);
			
			// https://api.login.yahoo.com's crossdomain.xml only allows *.yahoo.com domains access
			// so we request the auth cookie through our ProxyURLLoader.
			urll = new ProxyURLLoader(urlr, null, fnOnGetAuthToken);
		}
		
		// Handle all the YahooMail API calls
		override flash_proxy function callProperty(obMethodName:*, ...aobArgs): * {
			var obThis:Object = this;
			var strMethodName:String = obMethodName.toString();
			var dctArgs:Object = aobArgs[0];
			var fnComplete:Function = aobArgs[1];
			var obPassThroughContext:Object = aobArgs.length == 3 ? aobArgs[2] : null;
			var obContext:Object = {
				obPassThroughContext: obPassThroughContext,
				fnComplete: fnComplete,
				strMethodName: strMethodName
			};

			CallYahooMail(strMethodName, dctArgs, obContext);
		}

		// Limit the number of YahooMail API call failures logged per client instance
		static private var s_cErrorsLogged:int = 0;
		
		static private const FORCE_RETRY:Number = 2;
		static private const RETRY:Number = 1;
		static private const NO_RETRY:Number = 0;
		
		private function CallYahooMail(strMethodName:String, dctArgs:Object, obContext:Object): void {
			try {
				// Can't make API calls without an auth cookie.
				if (_strAuthCookie == null) {
					var fnOnGetAuthCookie:Function = function (fSuccess:Boolean): void {
						if (!fSuccess) {
							// UNDONE: logging?
							obContext.fnComplete(StorageServiceError.LoginFailed, "GetAuthCookie failed", null, obContext.obPassThroughContext);
							return;
						}
						CallYahooMail(strMethodName, dctArgs, obContext);
					}
					GetAuthCookie(fnOnGetAuthCookie, "CallYahooMail");
					return;
				}
				
				// Encode the method call and parameters as expected by the Yahoo! Mail API 				
				var strJSON:String = JSON.encode({ method: strMethodName, params: [ dctArgs ] });
				
				var strUrl:String = apiUrl + "?appid=" + _strAppId + "&WSSID=" + _strWSSID + "&cachebust=" + Math.random();
				var urlr:URLRequest = new URLRequest(strUrl);
				var strRequestId:String = AccountMgr.GetInstance().GetUserId() + "-" + getTimer() + "-" + Math.random();
				urlr.requestHeaders = [
					// Flash doesn't allow us to use the Cookie header. Our proxy converts OOB-Cookie into Cookie.
					new URLRequestHeader("OOB-Cookie", _strAuthCookie),
					new URLRequestHeader("Content-Type", "application/json"),
					new URLRequestHeader("RequestId", strRequestId)
				];
				urlr.method = URLRequestMethod.POST;
				urlr.data = strJSON;
				
				if ("cAttempts" in obContext)
					obContext.cAttempts++;
				else
					obContext.cAttempts = 1;
				
				var fnOnComplete:Function = function (urll:ProxyURLLoader, err:Number, strError:String): void {
					// This block of code must run to completion
					// and set up our state for doing one of two things:
					// 1. A callback (either success or error)
					// 2. A retry (call to CallYahooMail)
					
					// Variables for doing a callback and/or retry
					var nRetryStatus:Number = NO_RETRY;

					var obResponse:Object = null;
					var strErrorMessage:String = null;
					var err:Number = StorageServiceError.None;
					
					try {
						var strData:String = null;
						var strErrorCode:String = null;
						
						// First, extract our reponse and look for errors
						if (urll == null) {
							strErrorCode = "ConnectionProblem";
							strErrorMessage = "URLLoader is null";
						} else if (urll.data == null) {
							strErrorCode = "ConnectionProblem";
							strErrorMessage = "URLLoader is null";
						} else {
							strData = String(urll.data);
							if (strData.length == 0) {
								strErrorCode = "ConnectionProblem";
								strErrorMessage = "Response is empty";
							} else if (StringUtil.beginsWith(strData, "!!!PICNIK!!!")) {
								strErrorCode = "ProxyConnectionProblem";
								strErrorMessage = strData.substr(13);
							} else {
								// So far, no errors.
								try {
									obResponse = JSON.decode(strData);
								} catch (errParsing:Error) {
									obResponse = null;
									strErrorCode = "JSONParsingException";
									strErrorMessage = errParsing.toString();
									strErrorMessage += ", resp.tail: '" + strData.substr(strData.length - 300) + "'";
								}
							}
						}
						
						// If we have a response, check it for errors
						if (strErrorCode == null) {
// DWM: these are debugging aids to simulate request failures of the two most common types
//							if (Math.random() < 0.5)
//								obResponse = { error: { code: "boguscode", message: "bogusmessage" } };
//							if (Math.random() < 0.5)
//								obResponse = null;


							if ("error" in obResponse && obResponse.error != null) {
								strErrorCode = obResponse.error.code;
								strErrorMessage = obResponse.error.message;
							}
						}
						
						// Now deal with errors
						if (strErrorCode != null) { // Error
							err = StorageServiceError.Unknown;
							nRetryStatus = RETRY;
							switch (strErrorCode) {
							case "JSONParsingException":
								err = StorageServiceError.InvalidServiceResponse
								break;
							case "Client.InputInvalid":
								err = StorageServiceError.InvalidParameters;
								nRetryStatus = NO_RETRY;
								break;
								
							case "Client.RestrictedApiCall":
								err = StorageServiceError.UserNotPremium;
								nRetryStatus = NO_RETRY;
								break;
								
							case "Client.ExpiredCredentials":
								_strAuthCookie = null;
								nRetryStatus = FORCE_RETRY;
								break;
//							case "Server.ListMessagesFailed":
							}
							strErrorMessage = strErrorCode + ": " + strErrorMessage;
						}
					} catch (errException:Error) {
						// Some other exception
						strErrorMessage = errException.toString() + ": " + errException.getStackTrace();
						err = StorageServiceError.Exception;
						obResponse = null;
					}
					
					// Now we should either retry or call a callback 
					if (err != StorageServiceError.None) {
						// There was an error.
						// Log it and possibly retry
						try {
							// Only log invalid responses and exceptions
							if (s_cErrorsLogged < 20 && (err == StorageServiceError.InvalidServiceResponse || err == StorageServiceError.Exception)) {
								s_cErrorsLogged++;
								PicnikService.Log("YahooMailProxy: " + strMethodName + " Unexpected error" +
										", reqid: " + strRequestId +
										(s_cErrorsLogged == 20 ? " (log limit reached)" : " (t: " + obContext.cAttempts + ")") +
										" [" + strErrorMessage + "]",
										PicnikService.knLogSeverityWarning);
							}
						} catch (errIgnore:Error) {
							// Ignore logging errors
						}
						if (nRetryStatus == FORCE_RETRY || (nRetryStatus == RETRY && obContext.cAttempts < 3)) {
							// Retry
							CallYahooMail(strMethodName, dctArgs, obContext);
							return;
						}
					}
					
					// We didn't retry. Do the callback.
					urll.obContext.fnComplete(err, strErrorMessage, obResponse, urll.obContext.obPassThroughContext);
				}
				
				var urll:ProxyURLLoader = new ProxyURLLoader(urlr, null, fnOnComplete);
				urll.obContext = obContext;
			} catch (err:Error) {
				var strLog:String = "YahooMail Proxy exception: " + strMethodName + ": " + err.toString()+ ", url:" + strUrl;
				PicnikService.LogException(strLog, err);
				
				trace("YahooMailProxy.callProperty: methodName: " + strMethodName + ", err: " + err.toString() + "\n" + err.getStackTrace());
				var strError:String = "Exception: " + strMethodName + ": " + err.toString();
				obContext.fnComplete(StorageServiceError.Unknown, strError, null, obContext.obPassThroughContext);
			}
		}
	}
}
