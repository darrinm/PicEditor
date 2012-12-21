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
// PhotobucketProxy:
// Inspired by PhotobucketProxy.as, which was...
// Inspired by Brian "Beej Jorgensen" Hall's flickrapi.py
//
// Encapsulated Photobucket functionality
//
// Example usage:
// var fbp:PhotobucketProxy = new PhotobucketProxy(strAPIKey);
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
// PhotobucketProxy can hang onto the auth_token and will automatically add it as
// a parameter to all proxied calls, e.g.:
//
// fbp.token = rsp.auth_token
// fbp.auth_checkToken({}, OnCheckTokenComplete);

package bridges.photobucket {
	import bridges.ProxyURLLoader;
	import bridges.storageservice.StorageServiceError;
	
	import com.adobe.crypto.MD5;
	
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
			
	public dynamic class PhotobucketProxy extends Proxy { // fbp
		
		private var _strSCID:String;
		private var _strPrivateKey:String;
		
		public var token:String; // AKA session_key
		public var apiUrl:String;
		
		public function PhotobucketProxy(strSCID:String, strPrivateKey:String, strApiUrl:String=null) {
			_strSCID = strSCID;
			_strPrivateKey = strPrivateKey;
			if (strApiUrl)
				apiUrl = strApiUrl;
			else
				apiUrl = "http://photobucket.com/svc/api.php"
		}
		
		private static var _dctCache:Dictionary = new Dictionary();
		
		// Handle all the Photobucket API calls
		override flash_proxy function callProperty(obMethodName:*, ...aobArgs): * {
			try {
				var strMethodName:String = obMethodName.toString();
				var dctArgs:Object = aobArgs[0];
				var fnComplete:Function = aobArgs[1];
				var obPassThroughContext:Object = aobArgs.length == 3 ? aobArgs[2] : null;
				var obContext:Object = {obPassThroughContext: obPassThroughContext};
				obContext.fnComplete = fnComplete;
				obContext.obMethodName = obMethodName;
				fnComplete = ValidateResult;
				if (dctArgs["scid"] == undefined)
					dctArgs["scid"] = _strSCID;
				dctArgs["method"] = strMethodName
				dctArgs["version"] = "1.0";
				if (token)
					dctArgs["session_key"] = token;
				
				// Clean the album name (convert ' ' to %20)
				if ("album_name" in dctArgs) {
					dctArgs['album_name'] = dctArgs['album_name'].replace(/ /g, '%20');
				}

				var strUrl:String = apiUrl + BuildQuery(strMethodName,dctArgs);
				var urlr:URLRequest = new URLRequest(strUrl);
				var urll:ProxyURLLoader = new ProxyURLLoader(urlr, obContext, fnComplete, null, null, {gzip:1} );
				_dctCache[urll] = urll;
								
				// UNDONE: remember all outstanding calls and provide a Cancel method to close() them all?
			} catch (err:Error) {
				var strLog:String = "Photobucket Proxy exception: " + strMethodName + ": " + err.toString()+ "/url:" + strUrl;
				PicnikService.LogException(strLog,err);
				
				trace("PhotobucketProxy.callProperty: methodName: " + strMethodName + ", err: " + err.toString());
				var rsp:XML = <error_response><error_code>0</error_code><error_msg>{"Exception: " + strMethodName + ": " + err.toString()}</error_msg></error_response>;
				fnComplete(rsp, obContext);
				return false;
			}
			return true;
		}
		
		private function ValidateResult(urll:ProxyURLLoader, err:Number, strError:String): void {
			var xml:XML = null; // default is null which means there was an error and it has been logged.
			var obContext:Object = urll.obContext.obPassThroughContext;
			var fnComplete:Function = urll.obContext.fnComplete;
			
			delete PhotobucketProxy._dctCache[urll];

			if (err == ProxyURLLoader.kerrNone) {
				err = StorageServiceError.None;
				var strData:String = urll.data as String;
				if (!strData) {
					err = StorageServiceError.IOError;
					strError = "Empty data";
				} else {
					try {
						xml = XML(urll.data);
					} catch (e:Error) {
						err = StorageServiceError.IOError;
						strError = "Error parsing result xml: " + err;
					}
					if (err == 0) {
						// at this point, we have parsed XML. Now check the XML for errors.
						var strPBError:String = GetPhotobucketXMLError(xml);
						if (strPBError) {
							err = StorageServiceError.Unknown;
							strError = "photobucket error: " + strPBError;
						}
					}
				}
			} else {
				err == StorageServiceError.IOError;
			}
			
			if (err != StorageServiceError.None) {
				LogError(urll, err, strError);
			}
			fnComplete(err, strError, xml, obContext);
		}

		// Returns a null if everything is OK
		// Returns an error string if there is a problem.
		private function GetPhotobucketXMLError(xml:XML):String {
			var strError:String = null; // Default is no error
			if (!xml) {
				strError = "no xml";
			} else if (!xml.@stat) {
				strError = "missing stat attribute";
			} else if (xml.@stat != "ok") {
				strError = "";
				try {
					strError += xml.error.@code + ": ";
					strError += xml.error.@msg;
				} catch (e:Error) {
					// Ignore missing error XML
					strError += e;
				}
				if (strError.length == 0) strError = "unknown";
			}
			return strError;
		}
			


		private function LogError(urll:ProxyURLLoader, err:Number, strError:String): void {
			var nSeverity:Number = PicnikService.knLogSeverityWarning;			
			if (err==StorageServiceError.Unknown) {
				// "unknown" errors are properly valid error responses from photobucket...
				// we don't need to log them at such a high level
				nSeverity = PicnikService.knLogSeverityInfo;
			}
				
			var strLog:String = "";
			try {
				strLog = "Photobucket service error calling " + urll.obContext.obMethodName + ": " + err + ": " + strError + ", request = " + urll._urlr.url + ", response = " + urll.data;
			} catch (e:Error) {
				strLog = "Exception while logging photobucket error: " + e + ", " + e.getStackTrace();
			}
			PicnikService.Log(strLog, nSeverity);
		}
		

		
		public function BuildQuery(strMethodName:String,dctArgs:Object): String {
			var strExtra:String = "";
			if (dctArgs['service_token'])
				strExtra = dctArgs['service_token']
			else if (dctArgs['session_key'])
				strExtra = dctArgs['session_key']				
			dctArgs["sig"] = SignArgs(strMethodName, strExtra);

			var strArgs:String = "?";
			for (var strArg:String in dctArgs)
				strArgs += encodeURIComponent(strArg) + "=" + encodeURIComponent(dctArgs[strArg]) + "&";
			return strArgs.slice(0, -1);
		}
		
		// dctArgs -- a dictionary of arguments to be hashed
		// Returns a hex-encoded string from the md5 hash of the concatenated dictionary names and values
		private function SignArgs(strMethodName:String, strExtra:Object): String {
			var strArgs:String = strMethodName;
			strArgs += _strPrivateKey;
			strArgs += _strSCID;
			strArgs += strExtra;
			
			// md5 the UTF-8'ed string
			return MD5.hash(Util.Utf8FromUnicode(strArgs));
		}
	}
}

