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
package util
{
	import com.adobe.crypto.MD5;
	
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import imagine.ImageDocument;
	
	import mx.controls.Alert;

	public class SessionTransfer
	{
		// Returns false if it fails.
		public static function TransferSession(): Boolean {
			import mx.utils.Base64Encoder;
			try {
				// Package up our session state.
				var baSession:ByteArray = new ByteArray();
				baSession.writeObject(Session.GetCurrent().GetSessionForTransfer()); // GetSessionForTransfer() returns a shallow copy. Do not modify children
				baSession.compress();

		        // Convert to Base64 encoded String
		        var base64:Base64Encoder = new Base64Encoder();
		        base64.encodeBytes(baSession);
		        var strSession:String = base64.drain();
		        strSession = MD5.hash(strSession.replace(/\s/g,'') + 'sezl0nSalz_321DFA') + ":" + strSession;
		        // strSession is a hash, :, and a bas64 encoded, compressed AMF byte array of the session state object.
				PicnikService.SaveSessionState(strSession, _TransferSession);
			} catch (e:Error) {
				// UNDONE: Move this to a loc file.
				Util.ShowAlert(e.message, "Error saving session", Alert.OK, e.message);				
				return false;
			}
			return true;
		}
		
		private static function _TransferSession(nError:Number, strError:String, strSessionId:String=null): void {
			if (nError != PicnikService.errNone) {
				// Fail
				// UNDONE: Move this to a loc file.
				Util.ShowAlert(null, "error saving session", Alert.OK, "Error saving session: " + nError + ", " + strError);				
			} else {
				// Success, forward to target domain
				var strTargetDomain:String = null;
				if (strTargetDomain == null && "openInDomain" in PicnikBase.app.parameters)
					strTargetDomain = PicnikBase.app.parameters["openInDomain"];
				if (strTargetDomain == null) {
					strTargetDomain = "www.mywebsite.com"; // Default
				}
				
				var pas:PicnikAsService = PicnikBase.app.AsService();
				var strURL:String = "http://" + strTargetDomain + "/loadsession"				
				var urlr:URLRequest = new URLRequest(strURL);
				var urlv:URLVariables = new URLVariables();
				
				urlv.sessionid = strSessionId;
				urlv.locale = PicnikBase.Locale();

				if (PicnikBase.app.flickrlite) {
					urlv._host_name = "Flickr";
					urlv._ss = "flickr";
					if (PicnikBase.app.multiMode) {
						urlv._close_target = pas.GetServiceParameter( "_close_target", "http://www.flickr.com" );
					} else {
						urlv._export = "FlickrExport";
						var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
						if (imgd && imgd.properties && imgd.properties.webpageurl && imgd.properties.webpageurl.length > 0) {
							urlv._close_target = imgd.properties.webpageurl;
						} else {
							urlv._close_target = "http://www.flickr.com";
						}
					}
				} else {
					// transfer all the following API params over to the new instance
					for (var strParam:String in ['_host_name','_export','_close_target','_export_title',
													'_replace','_export_agent','_export_method']) {
						urlv[strParam] = pas.GetServiceParameter( strParam );
					}
				}
				if (PicnikBase.app.multiMode) {
					urlv._multi = PicnikBase.app.multi.Serialize();					
				}
				urlv.swfurl = PicnikBase.app.url;
				
				urlr.data = urlv;
				if (PicnikBase.app.canNavParentFrame)
					PicnikBase.app.NavigateToURL(urlr, "_self", true);
				else
					PicnikBase.app.NavigateToURL(urlr, "_blank", true);
			}
		}
		
	}
}