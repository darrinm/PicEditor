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
// Encapsulated Flickr functionality
//
// Example usage:
// var flkrp:FlickrProxy = new FlickrProxy(strAPIKey, strSecret);
// flkrp.auth_checkToken({auth_token: token}, OnCheckTokenComplete);
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
// flkrp.auth_checkToken({auth_token: token}, OnCheckTokenComplete, obContext);
//
// private function OnCheckTokenComplete(rsp:XML, obContext:Object): void {
//     if (rsp.@stat == "ok")
//         obContext.Whatever(rsp.auth.token);
// }
//
// FLickrProxy can hang onto the auth_token and will automatically add it as
// a parameter to all proxied calls, e.g.:
//
// flkrp.token = rsp.auth_token
// flkrp.auth_checkToken({}, OnCheckTokenComplete);

package bridges.flickr {
	import com.adobe.crypto.MD5;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import util.URLLoaderPlus;
	
	public dynamic class FlickrProxy extends Proxy { // flkrp
		private const kstrHost:String = "api.flickr.com";
		private const kstrRESTForm:String = "/services/rest/";
		private const kstrAuthForm:String = "/services/auth/fresh/";
		private const kstrUploadForm:String = "/services/upload/";
		private const kstrReplaceForm:String = "/services/replace/";
		
		private var _strAPIKey:String;
		private var _strSharedSecret:String;
		public var token:String;
		
		public function FlickrProxy(strAPIKey:String, strSharedSecret:String) {
			_strAPIKey = strAPIKey;
			_strSharedSecret = strSharedSecret;
		}
		
		// Get photo info. If the originalsize is not available, fetch the largestsize (using getSizes)
		// May set rsp.photos[0]@largestsource. See FlickrMgr.ImagePropertiesFromPhotoInfo
		public function Photos_GetInfoEx(obParams:Object, fnCallback:Function, obContext:Object=null): void {
			this.photos_getInfo(obParams, OnPhotos_GetInfoEx, {obParams:obParams, obContext:obContext, fnCallback:fnCallback});
		}

		private function OnPhotos_GetInfoEx(rsp:XML, obOrigContext:Object=null): void {
			if (rsp.@stat != "ok") {
				// Failed. Let the caller handle it.
				if (obOrigContext.obContext) obOrigContext.fnCallback(rsp, obOrigContext.obContext);
				else obOrigContext.fnCallback(rsp);
				return;
			}

			if (rsp.hasOwnProperty("photos") && rsp.photos.photo.length() > 1) {
				// if we get more than one photo back, don't go through all the getsizes rigamarole until later
				rsp.photos.@partial = true;
				if (obOrigContext.obContext)
					obOrigContext.fnCallback(rsp, obOrigContext.obContext);
				else
					obOrigContext.fnCallback(rsp);
			} else {
				// Got results. Now look for an original secret
				var ph:XML = rsp.hasOwnProperty("photos") ? rsp.photos.photo[0] : rsp.photo[0];
				//BUGBUG UNDONE We don't deal with changing secrets which reflect changing base images

				// We used ot only look for the original secret to find out if we could load the
				// original base image. But now with direct loading, we also need to look at the
				// size and format of the image, so we scan the entire list.
				// Call get sizes to enhance the result
				obOrigContext.rsp = rsp;
				var obParams:Object = {};
				
				if ("photo_id" in obOrigContext.obParams)
					obParams.photo_id = obOrigContext.obParams.photo_id;
				else if ("photo_ids" in obOrigContext.obParams)
					obParams.photo_id = obOrigContext.obParams.photo_ids;
				if ("api_key" in obOrigContext.obParams) obParams.api_key = obOrigContext.obParams.api_key;
				if ("auth_token" in obOrigContext.obParams) obParams.auth_token = obOrigContext.obParams.auth_token;
				this.photos_getSizes(obParams, OnPhotos_GetInfoEx_GetSizes, obOrigContext);
			}
		}

		private function OnPhotos_GetInfoEx_GetSizes(rsp:XML, obOrigContext:Object=null): void {
			if (rsp.@stat != "ok") {
				// Failed. Fall back to a opening the image without the large size
				trace("Failed to get sizes: " + rsp.@stat);
			} else {
				// Got results. Now look for the largest size
				var nWidth:Number = 0;
				var nHeight:Number = 0;
				var strSource:String = null;
				
				for each(var sz:XML in rsp.sizes.size) {
					// Find the largest size
					if (sz.hasOwnProperty("@width") && sz.hasOwnProperty("@height") && sz.hasOwnProperty("@source")) {
						if (nWidth < sz.@width || nHeight < sz.@height) {
							nWidth = sz.@width;
							nHeight = sz.@height;
							strSource = sz.@source;
						}
					}
				}
				if (strSource == null) {
					// Didn't find any sizes!?!
					trace("No sizes found");
				} else {
					// Found a largestsource
					var ph:XML = obOrigContext.rsp.hasOwnProperty("photos") ? obOrigContext.rsp.photos.photo[0] : obOrigContext.rsp.photo[0];
					ph.@largestsource = strSource;
					ph.@width = nWidth;
					ph.@height = nHeight;
				}
			}
			if (obOrigContext.obContext) obOrigContext.fnCallback(obOrigContext.rsp, obOrigContext.obContext);
			else obOrigContext.fnCallback(obOrigContext.rsp);
		}
				
		// Some helpers
		public function GetLoginURL(strPerms:String, strFrob:String=null): String {
			var dctArgs:Object = { api_key: _strAPIKey, perms: strPerms };
			if (strFrob)
				dctArgs["frob"] = strFrob;
			return "http://" + kstrHost + kstrAuthForm + BuildQuery(dctArgs);
		}
		
		// Handle all the Flickr API calls
		override flash_proxy function callProperty(obMethodName:*, ...aobArgs): * {
			try {
				var strMethodName:String = obMethodName.toString();
				var dctArgs:Object = aobArgs[0];
				var fnComplete:Function = aobArgs[1];
				var obContext:Object = aobArgs.length == 3 ? aobArgs[2] : null;
				if (dctArgs["api_key"] == undefined)
					dctArgs["api_key"] = _strAPIKey;
				var re:RegExp = /_/g;
				dctArgs["method"] = "flickr." + strMethodName.replace(/_/g, ".");
				dctArgs["nocache"] = Math.random().toString();
				if (token)
					dctArgs["auth_token"] = token;
				var urll:URLLoaderPlus = new URLLoaderPlus();
				urll.addEventListener(Event.COMPLETE, OnComplete);
				urll.addEventListener(IOErrorEvent.IO_ERROR, OnIOError);
				urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnSecurityError);
				urll.fnComplete = fnComplete;
				urll.obContext = obContext;

				var strUrl:String = "http://" + kstrHost + kstrRESTForm + BuildQuery(dctArgs);
				var urlr:URLRequest = new URLRequest(strUrl);
				urll.load(urlr);
				// UNDONE: remember all outstanding calls and provide a Cancel method to close() them all?
			} catch (err:Error) {
				trace("FlickrProxy.callProperty: methodName: " + strMethodName + ", err: " + err.toString());
				return false;
			}
			return true;
		}
		
		private function BuildQuery(dctArgs:Object): String {
			var strSig:String = SignArgs(dctArgs);
			// UNDONE: these aren't in the same order as the signed args
			var strArgs:String = "?";
			for (var strArg:String in dctArgs)
				strArgs += encodeURIComponent(strArg) + "=" + encodeURIComponent(dctArgs[strArg]) + "&";

			return strArgs + "api_sig=" + strSig;
		}
		
		// dctArgs -- a dictionary of arguments to be hashed
		// Returns a hex-encoded string from the md5 hash of the concatenated dictionary names and values
		private function SignArgs(dctArgs:Object): String {
			// sort args by name
			var astrArgNames:Array = new Array();
			for (var strArg:String in dctArgs)
				astrArgNames.push(strArg);
			astrArgNames.sort();
			
			// build a string: secret + [arg name, arg] ...
			var strArgs:String = _strSharedSecret;
			for (var i:Number = 0; i < astrArgNames.length; i++)
				strArgs += astrArgNames[i] + dctArgs[astrArgNames[i]];
			
			// UTF-8 the string, then MD5 it
			strArgs = Util.Utf8FromUnicode(strArgs);
			return MD5.hash(strArgs);
		}
		
		private function OnComplete(evt:Event): void {
			var urll:URLLoaderPlus = URLLoaderPlus(evt.target);
			if (urll.obContext != null)
				urll.fnComplete(XML(evt.target.data), urll.obContext);
			else
				urll.fnComplete(XML(evt.target.data));
		}
		
		private function OnIOError(evt:IOErrorEvent): void {
			var rsp:XML = <rsp stat="fail"><err code="0" msg={evt.text}/></rsp>;
			var urll:URLLoaderPlus = URLLoaderPlus(evt.target);
			if (urll.obContext != null)
				urll.fnComplete(rsp, urll.obContext);
			else
				urll.fnComplete(rsp);
		}
		
		private function OnSecurityError(evt:SecurityErrorEvent): void {
			var rsp:XML = <rsp stat="fail"><err code="0" msg={evt.text}/></rsp>;
			var urll:URLLoaderPlus = URLLoaderPlus(evt.target);
			if (urll.obContext != null)
				urll.fnComplete(rsp, urll.obContext);
			else
				urll.fnComplete(rsp);
		}
	}
}
