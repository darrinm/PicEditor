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
// ActionScript 3.0 port of Eran Sandler's C# OAuth class (http://oauth.googlecode.com/svn/code/csharp/OAuthBase.cs)

package bridges {
	import com.adobe.net.URI;
	// import com.hurlant.crypto.hash.HMAC;
	// import com.hurlant.crypto.hash.SHA1;
	// import com.hurlant.util.Base64;
	
	import flash.utils.ByteArray;
	
	public class OAuth {
		private static const kstrOAuthVersion:String = "1.0";
		private static const kstrOAuthParameterPrefix:String = "oauth_";
		
		private static const kstrOAuthConsumerKeyKey:String = "oauth_consumer_key";
		private static const kstrOAuthCallbackKey:String = "oauth_callback";
		private static const kstrOAuthVersionKey:String = "oauth_version";
		private static const kstrOAuthSignatureMethodKey:String = "oauth_signature_method";
		private static const kstrOAuthSignatureKey:String = "oauth_signature";
		private static const kstrOAuthTimestampKey:String = "oauth_timestamp";
		private static const kstrOAuthNonceKey:String = "oauth_nonce";
		private static const kstrOAuthTokenKey:String = "oauth_token";
		private static const kstrOAuthTokenSecretKey:String = "oauth_token_secret";

        public static const kstrHMACSHA1SignatureType:String = "HMAC-SHA1";
        public static const kstrPlainTextSignatureType:String = "PLAINTEXT";
        public static const kstrRSASHA1SignatureType:String = "RSA-SHA1";	
       
		private static const kstrUnreservedChars:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.~";

		private var _obRequest:Object = null;
		
		// Internal function to cut out all non oauth query string parameters (all parameters not beginning with "oauth_")
		private function GetQueryParameters(strParameters:String): Array {
			if (strParameters.charAt(0) == "?")
				strParameters = strParameters.slice(1);
				
			var astrResult:Array = [];
			
			if (strParameters.length != 0) {
				var astrNameValues:Array = strParameters.split("&");
				for each (var strNameValue:String in astrNameValues) {
					if (strNameValue.length != 0 && strNameValue.indexOf(kstrOAuthParameterPrefix) != 0) {
						if (strNameValue.indexOf("=") != -1) {
							var astrTemp:Array = strNameValue.split("=");
							astrResult.push({ name: astrTemp[0], value: astrTemp[1] });
						} else {
							astrResult.push({ name: strNameValue, value: null });
						}
					}
				}
			}
			
			return astrResult;
		}
	
		private function GetInitQueryParameters(): Array {
			var astrResult:Array = [];

			if (_obRequest && _obRequest.dctParams != null) {
				var dct:Object = _obRequest.dctParams;
				for (var strKey:String in dct) {
					astrResult.push({ name: strKey, value: dct[strKey]});	
				}
			}
			
			return astrResult;
		}
		
		// This is a different Url Encode implementation since the default one outputs the percent encoding in
		// lower case. While this is not a problem with the percent encoding spec, it is used in upper case
		// throughout OAuth.
		public static function UrlEncode(strValue:String): String {
			var strResult:String = "";
			for (var ich:int = 0; ich < strValue.length; ich++) {
				var chSymbol:String = strValue.charAt(ich);
				if (kstrUnreservedChars.indexOf(chSymbol) != -1) {
					strResult += chSymbol;
				} else {
					var strHex:String = chSymbol.charCodeAt(0).toString(16);
					strHex = strHex.toUpperCase();
					if (strHex.length < 2)
						strHex = "0" + strHex;
					strResult += "%" + strHex;
				}
			}
			return strResult;
		}
		
		// Normalizes the request parameters according to the spec
		private function NormalizeRequestParameters(aobNameValues:Object): String {
			var strResult:String = "";
			for each (var obNameValue:Object in aobNameValues)
				strResult += UrlEncode(obNameValue.name) + "=" + UrlEncode(obNameValue.value) + "&";
			return strResult.slice(0, strResult.length - 1);
		}
		

		public function Init(strUrl:String, dctParams:Object, strConsumerSecurityKey:String, strConsumerSecuritySecret:String, strMethod:String="GET",
				strOAuthToken:String="", strOAuthTokenSecret:String=""): void {
	 		_obRequest = {};
			_obRequest.url = strUrl;
			_obRequest.dctParams = dctParams;
			
			var strTimestamp:String = GenerateTimestamp();
			var strNonce:String = GenerateNonce();
			var uri:URI = new URI(strUrl);
	
			if (dctParams != null) {
				for (var strKey:String in dctParams)
					uri.setQueryValue(strKey, dctParams[strKey]);
			}
			_obRequest.dctParams = dctParams;
			
			var strSig:String = GenerateSignatureHMACSHA1(uri, strConsumerSecurityKey, strConsumerSecuritySecret,
					strOAuthToken, strOAuthTokenSecret, strMethod, strTimestamp, strNonce);
			_obRequest.oauth = {};
			_obRequest.oauth[kstrOAuthConsumerKeyKey] = strConsumerSecurityKey;
			_obRequest.oauth[kstrOAuthNonceKey] = strNonce;
			_obRequest.oauth[kstrOAuthSignatureKey] = strSig;
			_obRequest.oauth[kstrOAuthSignatureMethodKey] = kstrHMACSHA1SignatureType;
			_obRequest.oauth[kstrOAuthTimestampKey] = strTimestamp;
			_obRequest.oauth[kstrOAuthTokenKey] = strOAuthToken;
			_obRequest.oauth[kstrOAuthVersionKey] = kstrOAuthVersion;
			
			_obRequest.fullurl = GetRequestAsUrl();
		}
		
		public function GetTimestamp(): String {
			return _obRequest.oauth[kstrOAuthTimestampKey];
		}
		
		public function GetNonce(): String {
			return _obRequest.oauth[kstrOAuthNonceKey];
		}
		
		public function GetRequestObject(): Object {
			return _obRequest;
		}
		
		public function GetRequestAsUrl(): String {
			var strUrl:String = _obRequest.url;
			var strParams:String = "";
			var strKey:String;
			if (_obRequest.dctParams != null)
			{
				for (strKey in _obRequest.dctParams)
				{
					if (strParams.length > 0) strParams += "&";
					strParams += strKey + "=" + UrlEncode(_obRequest.dctParams[strKey]);
				}
			}

			for (strKey in _obRequest.oauth) {
				if (strParams.length > 0) strParams += "&";
				strParams += strKey + "=" + UrlEncode(_obRequest.oauth[strKey]);
			}
			strUrl += (strUrl.indexOf("?") == -1 ? "?" : "&") + strParams;
			return strUrl;
		}
		
		// Used as the HTTP Authorization: header for OAuth post requests.
		public function GetRequestAuthorizationHeader(): String {
			var uri:URI = new URI(_obRequest.url);
			var strHeader:String = "OAuth realm=\"" + uri.scheme + "://" + uri.authority + "\"";
			var strKey:String;
			
			var aobNameValues:Array = [];
			for (strKey in _obRequest.oauth)
				aobNameValues.push(strKey);
			
			aobNameValues.sort();
			for (var i:int = 0; i < aobNameValues.length; ++i) {
				strKey= aobNameValues[i];
				strHeader += "," + strKey + "=\"" + UrlEncode(_obRequest.oauth[strKey]) + "\"";
			}
			return strHeader;
		}
		
		public function GenerateQueryParameters(strConsumerKey:String, strToken:String,
				strTimestamp:String, strNonce:String, strSignature:String, strSignatureType:String): String {
			return kstrOAuthConsumerKeyKey + "=" + UrlEncode(strConsumerKey) + "&" +
					kstrOAuthNonceKey + "=" + strNonce + "&" + kstrOAuthSignatureKey + "=" + UrlEncode(strSignature) + "&" +
					kstrOAuthSignatureMethodKey + "=" + strSignatureType + "&" +
					kstrOAuthTimestampKey + "=" + strTimestamp + "&" + kstrOAuthTokenKey + "=" + strToken + "&" +
					kstrOAuthVersionKey + "=" + kstrOAuthVersion;
		}
		
		// Generate the signature base that is used to produce the signature
		public function GenerateSignatureBase(uri:URI, strConsumerKey:String, strConsumerSecret:String, strToken:String,
				strTokenSecret:String, strHttpMethod:String, strTimestamp:String, strNonce:String, strSignatureType:String): String {
			if (strToken == null)
				strToken = "";
			if (strTokenSecret == null)
				strTokenSecret = "";
			
			var aobNameValues:Array = _obRequest ? GetInitQueryParameters() : GetQueryParameters(uri.query);
			aobNameValues.push({ name: kstrOAuthVersionKey, value: kstrOAuthVersion });
			aobNameValues.push({ name: kstrOAuthNonceKey, value: strNonce });
			aobNameValues.push({ name: kstrOAuthTimestampKey, value: strTimestamp });
			aobNameValues.push({ name: kstrOAuthSignatureMethodKey, value: strSignatureType });
			aobNameValues.push({ name: kstrOAuthConsumerKeyKey, value: strConsumerKey });
			aobNameValues.push({ name: kstrOAuthTokenKey, value: strToken });
				
			aobNameValues.sortOn("value");
			aobNameValues.sortOn("name");
			
			var strNormalizedRequestParameters:String = NormalizeRequestParameters(aobNameValues);
			var strSignatureBase:String = strHttpMethod.toUpperCase() + "&";
			strSignatureBase += UrlEncode(uri.scheme + "://" + uri.authority + uri.path) + "&";
			strSignatureBase += UrlEncode(strNormalizedRequestParameters);
			
			return strSignatureBase;
		}
		
		// Generates a signature using the HMAC-SHA1 algorithm
		public function GenerateSignatureHMACSHA1(uri:URI, strConsumerKey:String, strConsumerSecret:String, strToken:String,
				strTokenSecret:String, strHttpMethod:String, strTimestamp:String, strNonce:String): String {
			return GenerateSignature(uri, strConsumerKey, strConsumerSecret, strToken, strTokenSecret, strHttpMethod, strTimestamp,
					strNonce, kstrHMACSHA1SignatureType);						
		}
		
		// Generates a signature using the specified signatureType
		public function GenerateSignature(uri:URI, strConsumerKey:String, strConsumerSecret:String, strToken:String,
				strTokenSecret:String, strHttpMethod:String, strTimestamp:String, strNonce:String, strSignatureType:String): String {
			
			switch (strSignatureType) {
			case kstrPlainTextSignatureType:
				return escape(strConsumerSecret + "&" + strTokenSecret);
				
			case kstrHMACSHA1SignatureType:
				var strSignatureBase:String = GenerateSignatureBase(uri, strConsumerKey, strConsumerSecret, strToken,
						strTokenSecret, strHttpMethod, strTimestamp, strNonce, kstrHMACSHA1SignatureType);
				var baKey:ByteArray = new ByteArray();
				baKey.writeUTFBytes(strConsumerSecret + "&" + strTokenSecret);
				var baSignatureBase:ByteArray = new ByteArray();
				baSignatureBase.writeUTFBytes(strSignatureBase);
				throw new Error("Not yet implemented");
				return null;
				/*
				var hmac:HMAC = new HMAC(new SHA1());
				var baHashed:ByteArray = hmac.compute(baKey, baSignatureBase);
				return Base64.encodeByteArray(baHashed);
				*/
				
			case kstrRSASHA1SignatureType:
				// UNDONE:
				return null;
			}
			
			return null;
		}
		
		// Generate the timestamp for the signature
		public function GenerateTimestamp(): String {
			return int(new Date().time / 1000).toString();
		}
		
		// Generate a nonce
		public function GenerateNonce(): String {
			// Just a simple implementation of a random number between 123,400 and 9,999,999
			return (int(Math.random() * (9999999 - 123400)) + 123400).toString();
		}
		
		/* TODO(darrinm): nobody seems to be using this. Remove after verifying. [09/02/10]
		// Get a Request Token for passing to an Authorize request
		public function GetRequestToken(strRequestTokenUrl:String, fnComplete:Function): void {
			
		}
		*/
	}
}
