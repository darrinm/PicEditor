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
package bridges.twitter {
	import bridges.*;
	import bridges.storageservice.StorageServiceBase;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceRegistry;
	import bridges.storageservice.StorageServiceUtil;
	
	import com.adobe.crypto.MD5;
	
	import dialogs.DialogManager;
	
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
	import imagine.ImageDocument;
	
	import mx.controls.Alert;
	import mx.resources.ResourceBundle;
	import mx.rpc.xml.SimpleXMLDecoder;
	import mx.utils.StringUtil;
	
	import util.DynamicLocalConnection;
	import util.IRenderStatusDisplay;
	import util.KeyVault;
	import util.RenderHelper;
	
	public class TwitterStorageService extends StorageServiceBase {
		private static var s_strConsumerSecurityKey:String;
		private static var s_strConsumerSecuritySecret:String;
		private static var s_strInstallPageName:String;
		private static var s_strTwitGooSecret:String;
		private var _strOAuthToken:String;
		private var _strUserId:String;
		private var _strScreenName:String;
		private var _obUserInfoCache:Object = null;
		private var _itemInfoCache:ItemInfo = null;
		
		private var _fnComplete:Function = null;
		private var _lconTwitter:DynamicLocalConnection = null;
		private var _fLconTwitterConnected:Boolean = false;
		
		private static const kstrTwitterAPIBase:String = "http://api.twitter.com/";
			
  		[Bindable] [ResourceBundle("TwitterStorageService")] private var _rb:ResourceBundle;
  		
		public function TwitterStorageService() {
			s_strConsumerSecurityKey = KeyVault.GetInstance().twitter.consumerkey;
			s_strConsumerSecuritySecret = KeyVault.GetInstance().twitter.consumersecret;
			s_strInstallPageName = KeyVault.GetInstance().twitter.name;
			s_strTwitGooSecret = KeyVault.GetInstance().twitter.twitgoosecret;
		}
		
		private static function _xmlToObj(strXML:String): Object {
			var xmld:XMLDocument = new XMLDocument();
			xmld.ignoreWhite = true;
			try {
				xmld.parseXML(strXML);
			} catch (err:Error) {
				return {error:'bad xml'};
			}
			try {
				var xdec:SimpleXMLDecoder = new SimpleXMLDecoder();
				var obData:Object = xdec.decodeXML(XMLNode(xmld));
			} catch (err:Error) {
				return {errror:'failed to decode xml'};
			}
			return obData;
		}

		private function GetTwitterReturn(urll:ProxyURLLoader): Object {	
			if (!urll.data)
				return {error:"IO Error"};
				
			var obData:Object = _xmlToObj(urll.data as String);			
			// Parse the returned XML into an object. SimpleXMLDecoder tries to figure out the type
			// of each field and will parse them into Numbers, Booleans (any casing of "true" or "false"),
			// and Strings. Numbers that start with '0' are left as Strings.
			if (obData == null || obData == "Failed to validate oauth signature or token" || ("hash" in obData && obData.hash.error)) {
				
				if ("hash" in obData)
					obData.error = obData.hash.error;
				else if (obData != null)
					obData.error = obData;
				else
					obData.error = "unknown error";
			}
			
			if ('error' in obData || 'status' in obData) {
				return obData;
			}
			
			var strT:String;
			try {
				strT = obData as String;
			} catch (err:Error) {
				strT = "unknown error";
			}
			
			return {error:strT};			
		}

		public function GetUserDetail(strKey:String):String {
			var strRet:String = null;
			if (_obUserInfoCache != null)
			{
				try {
					strRet = "twitter_" + _obUserInfoCache.user[strKey];
				} catch (err:Error) {
					strRet = null
				}
			}
			return strRet;
		}
				
		override public function GetServiceInfo(): Object {
			return StorageServiceRegistry.GetStorageServiceInfo("twitter");
		}
		
		protected function get oauth_token(): String {
			return OAuthTokenFromToken(_strOAuthToken);
		}
		
		protected function get oauth_token_secret(): String {
			return OAuthTokenSecretFromToken(_strOAuthToken);
		}
		
		private function ValueFromToken(strToken:String, strKey:String): String {
			var strReturn:String = "";
			if (strToken) {
				var obTokenParams:Object = Util.ObFromQueryString(strToken);
				if (obTokenParams && strKey in obTokenParams && obTokenParams[strKey])
					strReturn = obTokenParams[strKey];
			}
			return strReturn;
		}
		
		protected function OAuthTokenFromToken(strToken:String): String {
			// Check for oauth_token_secret to determine method		
			var strReturn:String = "";
			if (strToken) {
				if (strToken.indexOf("oauth_token_secret") > -1) {
					// New way
					strReturn = ValueFromToken(strToken, "oauth_token");
				} else if (strToken.length > "oauth_token=".length &&
						strToken.substr(0, "oauth_token=".length) == "oauth_token=") {
					// Old way
					strReturn = strToken.substr("oauth_token=".length);
				}
			}
			return strReturn;
		}
		
		protected function OAuthTokenSecretFromToken(strToken:String): String {
			return ValueFromToken(strToken, "oauth_token_secret");
		}
		
		// Returns null if the child is not defined
		private function SafeGetChild(obOwner:Object, strPath:String): Object {
			var astrPath:Array = strPath.split('.');
			var obCurrent:Object = obOwner;
			if (!obOwner) return null;
			for each (var strKey:String in astrPath) {
				if (!(strKey in obOwner) || !obOwner[strKey]) return null;
				obOwner = obOwner[strKey];
			}
			return obOwner;
		}
		
		private function SafeGetChildString(obOwner:Object, strPath:String): String {
			var obResult:Object = SafeGetChild(obOwner, strPath);
			return obResult ? String(obResult) : null;
		}
		
		// fnCallback looks like this:
		// void OnGotToken(obResult:Object): void;
		// obResult will either contain 'error' (a string error) or 'oauth_token' and 'oauth_token_secret' (may be empty string)
		private function GetTokenFromUrl(strUrl:String, strXMLLocation:String, fnCallback:Function): void {
			var fnOnGotResult:Function = function (urlr:ProxyURLLoader, err:Number, strError:String): void {
				if (err != ProxyURLLoader.kerrNone)
					fnCallback({error: "Load error: " + err + ": " + strError});
				else
					fnCallback(GetTokenFromResult(urlr.data, strXMLLocation));
			}

			var urlr:URLRequest = new URLRequest(strUrl);
			var urll:ProxyURLLoader = new ProxyURLLoader(urlr, null,
					fnOnGotResult, null, null);

		}
		
		// Twitter access_token and request_token response may be either XML or a query string
		// look at the string to figure it out
		private function IsXMLResponse(strResponse:String): Boolean {
			if (strResponse == null) return false;
			strResponse = StringUtil.trim(strResponse);
			if (strResponse.length == 0) return false;
			if ((strResponse.indexOf("<") == -1) || (strResponse.indexOf(">") == -1)) return false;
			if ((strResponse.indexOf("/>") == 0) && (strResponse.indexOf("</") == 0)) return false;
			// At this point, we have a string which contains < and > and ( /> or </ )
			// Assume it is XML
			return true;
		}

		// Returns null on failure
		// Otherwise, returns an object with:
		//     oauth_token
		private function GetTokenFromResult(obResult:Object, strXMLLocation:String): Object {
			if (!obResult || String(obResult).length == 0)
				return {error:"Connection returned no data (error?)"};

			var strResult:String = String(obResult);
			
			var strOAuthToken:String = null;
			var strOAuthTokenSecret:String = null;
			
			if (IsXMLResponse(strResult)) {
				// Parse the returned XML into an object. SimpleXMLDecoder tries to figure out the type
				// of each field and will parse them into Numbers, Booleans (any casing of "true" or "false"),
				// and Strings. Numbers that start with '0' are left as Strings.
				var xmld:XMLDocument = new XMLDocument();
				xmld.ignoreWhite = true;
				try {
					xmld.parseXML(strResult);
				} catch (err:Error) {
					return {error:"Invalid xml response: " + err.toString() + ", " + strResult.substr(0, 400)};
				}
				var xdec:SimpleXMLDecoder = new SimpleXMLDecoder();
				var obData:Object = xdec.decodeXML(XMLNode(xmld));
				
				if (!obData)
					return {error:"Could not convert xml to object: " + strResult.substr(0, 400)};
				
				if (SafeGetChildString(obData, "error"))
					return {error: "Twitter Error: " + SafeGetChildString(obData, "error.message")};
				
				// e.g. "requesttoken.token"
				strOAuthToken = SafeGetChildString(obData, strXMLLocation);
				if (!strOAuthToken)
					return {error: "Missing location in xml: " + strXMLLocation + ", " + strResult.substr(0, 400)};

				// Got the token. Keep going.
				strOAuthTokenSecret = "";
			} else {
				// Not XML response, check for query string response
				if (strResult.indexOf("oauth_token") == -1)
					return {error: "Missing oauth_token in query response, " + strResult.substr(0, 400)};
				strOAuthToken = OAuthTokenFromToken(strResult);
				strOAuthTokenSecret = OAuthTokenSecretFromToken(strResult);
			}
			return {oauth_token: strOAuthToken, oauth_token_secret: strOAuthTokenSecret};  
		}

		override public function Authorize(strPerm:String=null, fnComplete:Function=null): Boolean {
			//External Auth - generally user initiated (clicked connect)
			// This can fail - if it does, we should throw an alert - and log a failure
			
			// First, request a temp token
			var strUrl:String = kstrTwitterAPIBase + "oauth/request_token";
			
			// Sign the request without a token
			var auth:OAuth = new OAuth();
			auth.Init(strUrl, null, s_strConsumerSecurityKey, s_strConsumerSecuritySecret, "GET");
			strUrl = auth.GetRequestAsUrl();
			
			var strToken:String = "";
			
			var fnPopupOpen:Function = function(err:int, errMsg:String, ob:Object): void {
				// listen for new user properties
				
				_lconTwitter = new DynamicLocalConnection();
				_lconTwitter.allowPicnikDomains();
				_lconTwitter["successMethod"] = function(strCBParams:String=null): void {
					// the popup succeeded!
					if (_fnComplete != null) {
						_fnComplete(0, "", strCBParams);
						_fnComplete = null;
					}
					try {
						_lconTwitter.close();
					} catch (e:Error) {
						//
					}
					_fLconTwitterConnected = false;
					_lconTwitter = null;
					
					DialogManager.HideBlockedPopupDialog();
				};
				
				if (!_fLconTwitterConnected) {
					try {
						_lconTwitter.connect("twitterAuth");
					} catch (e:Error) { /*NOP*/ }
					_fLconTwitterConnected = true;
				}
			}
			
			var fnOnGotRequestToken:Function = function (obResult:Object): void {
				if ('error' in obResult) {
					Util.ShowAlert(Resource.getString("TwitterStorageService", "CouldNotConnect"),
							Resource.getString("TwitterStorageService", "Error"), Alert.OK,
							"Twitter: Authorize: Error getting request token: " + obResult.error);
				} else {
					// Got the data. Now use it.
					
					// When the auth callback comes back, we get back the token but not the secret
					// Remember the secret but not the token - that way, we know that we do not
					// have a valid token - but we can use the same secret when we get the token back
					SetTPAToken("", obResult.oauth_token_secret);
					
					// sample authorize url: http://api.twitter.com/authorize?oauth_callback=http%3a%2f%2fdeveloper.twitter.com%2fmodules%2fapis%2fpages%2faccessdelegationtool.aspx&oauth_token=MIGDBgorBgEEAYI3WAOvoHUwcwYKKwYBBAGCN1gDAaBlMGMCAwIAAQICZgMCAgDABAisgTqQXwMePgQQvwsfWWQGyOYrfYE8WIKYAgQ4s7ovqBqa2ycjXWPaDfaRA1pgQNXbT7SnSFVn5dnkW0T94k5JcEK%2bfQxBWu0c1vB2pATtnM0MlFY%3d
					var strCallbackUrl:String = PicnikService.serverURL + "/callback/twitter";
					var strAuth:String = kstrTwitterAPIBase + "oauth/authorize?oauth_callback=" + OAuth.UrlEncode(strCallbackUrl) + "&oauth_token=" + OAuth.UrlEncode(obResult.oauth_token);
					_fnComplete = fnComplete;
					PicnikBase.app.NavigateToURLInPopup(strAuth, 800, 800, fnPopupOpen);
				}
			}
			
			GetTokenFromUrl(strUrl, "requesttoken.token", fnOnGotRequestToken);
			return true;
		}
		
		override public function HandleAuthCallback(obParams:Object, fnComplete:Function): void {
			var fnOnLoginComplete:Function = function (strError:String=null): void {
				if (strError) {
					// There was an error

					Util.ShowAlert(Resource.getString("TwitterStorageService", "CouldNotConnect"), Resource.getString("TwitterStorageService", "Error"), Alert.OK,
							"Twitter: HandleAuthCallback: " + strError);

					// Clear out user
					var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount("twitter");
					_strUserId = null;
					_strOAuthToken = null;
					tpa.SetUserId("");
					tpa.SetToken("");
				}
				// Done
				fnComplete();
			}
			LoginFromCallback(obParams, fnOnLoginComplete);
		}
		
		// fnComplete looks like this:
		// function OnLoginComplete(strError:String=null): void
		// On success, strError is null
		// On error, strError is an error message for logging (not to display to the user)
		private function LoginFromCallback(obParams:Object, fnComplete:Function): void {
			if (!obParams || !('oauth_token' in obParams) || !obParams.oauth_token) {
				fnComplete("LoginFromCallback: No oauth token in callback params"); // Error
				return;
			}

			// We now have a request token, use it to get an Access Token
			var strUrl:String = kstrTwitterAPIBase + "oauth/access_token";
			_strUserId = obParams['user_id'];
			_strScreenName = obParams['screen_name'];
			
			// Sign the request
			var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount("twitter");
			var auth:OAuth = new OAuth();
			var strTokenSecret:String = OAuthTokenSecretFromToken(tpa.GetToken());
			auth.Init(strUrl, null, s_strConsumerSecurityKey, s_strConsumerSecuritySecret, "GET", obParams.oauth_token, strTokenSecret);
			
			var fnOnGetUserInfo:Function = function (nError:Number, strError:String, obResult:Object=null): void {
				_strUserId = obResult.user.id;
				tpa.SetUserId(_strUserId);
				_strScreenName = obResult.user.screen_name;
				tpa.SetAttribute('screenname', _strScreenName);
				
				fnComplete(); // Success!			
			}
			
			var fnOnGotAccessToken:Function = function (obResult:Object): void {
				if ('error' in obResult) {
					fnComplete("GetAccessToken: Error: " + obResult.error);
					fnComplete();
				} else {
					// Success. Got the access token and a new secret.
					// Now try to get the user from the token
					tpa.SetToken(TokenFromOAuthTokenAndSecret(obResult.oauth_token, obResult.oauth_token_secret));
					_strOAuthToken = tpa.GetToken();

					if (_strUserId == null) {
						GetResource("account/verify_credentials.xml", null, fnOnGetUserInfo, oauth_token, oauth_token_secret);
						
					} else {
						tpa.SetUserId(_strUserId);
						tpa.SetAttribute('screenname', _strScreenName);
						fnComplete(); // Success!			
					}
				}
			}
			GetTokenFromUrl(auth.GetRequestAsUrl(), "accesstoken.token", fnOnGotAccessToken);
		}
		
		private function TokenFromOAuthTokenAndSecret(strOAuthToken:String, strOAuthTokenSecret:String): String {
			return "oauth_token=" + OAuth.UrlEncode(strOAuthToken) + "&oauth_token_secret=" + OAuth.UrlEncode(strOAuthTokenSecret);
		}
		
		private function SetTPAToken(strOAuthToken:String, strOAuthTokenSecret:String=null): void {
			var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount("twitter");
			var strToken:String = tpa.GetToken();
			if (!strOAuthToken) strOAuthToken = ValueFromToken(strToken, "oauth_token");
			if (!strOAuthTokenSecret) strOAuthTokenSecret = ValueFromToken(strToken, "oauth_token_secret");
			strToken = TokenFromOAuthTokenAndSecret(strOAuthToken,strOAuthTokenSecret);
			tpa.SetToken(strToken, true);
		}
		
		override public function IsLoggedIn(): Boolean {
			return oauth_token.length > 0 || (_strOAuthToken && _strOAuthToken.indexOf("opensocial_owner_id") > -1);
		}
		
		// Log the user in. No assumptions are to be made regarding how long the session lasts.
		//
		// fnComplete(err:Number, strError:String)
		// - None
		// - IOError
		// - InvalidUserOrPassword
		//
		// fnProgress(nPercent:Number)
		
		override public function LogIn(tpa:ThirdPartyAccount, fnComplete:Function, fnProgress:Function=null): void {
			_strOAuthToken = null;
			_strUserId = null;
			
			try {
				// Validate the token
				// UNDONE: no way to do this yet with twitter
				if (!tpa.GetUserId() || !tpa.GetToken()) {
					PicnikBase.app.callLater(fnComplete, [ StorageServiceError.LoginFailed, "user is not logged in" ]);
				} else {
					_strOAuthToken = tpa.GetToken();
					_strUserId = tpa.GetUserId();
					// callLater to preserve expected async semantics
					PicnikBase.app.callLater(fnComplete, [ StorageServiceError.None, null ]);
				}
			} catch (e:Error) {
				PicnikService.Log("Client Exception: in TwitterStorageService.LogIn: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityError);
				throw e;
			}
		}

		// Log the user out.
		//
		// fnComplete(err:Number, strError:String)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)

		override public function LogOut(fnComplete:Function=null, fnProgress:Function=null): void {
			_strOAuthToken = null;
			_strUserId = null;
		}
		
		// Returns a dictionary filled with information about the logged in user.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - username (req)
		// - fullname (opt)
		// - thumbnailurl (opt)
		// - webpageurl (opt)
		//
		// fnComplete(err:Number, strError:String, dctUserInfo:Object=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)

		override public function GetUserInfo(fnComplete:Function, fnProgress:Function=null): void {
			var fnOnGetResource:Function = function (nError:Number, strError:String, obResult:Object=null): void {
				if (nError != 0) {
					fnComplete(StorageServiceError.IOError, "Unable to retrieve user information");
					return;
				}
				var dctUserInfo:Object = null;		
				try {
					var obUser:Object = obResult.user;
				 	dctUserInfo = {
						username: obUser.name,
						thumbnailurl: obUser.profile_image_url,
						webpageurl: "http://twitter.com/" + obUser.screen_name,
						id: obUser.id};
				} catch (e:Error) {
					dctUserInfo = null;
				}
				
				if (dctUserInfo == null) {
					fnComplete(StorageServiceError.IOError, "Unable to retrieve user information [2]", null);
					return;
				}
				
				// Copy over every Twitter user property and prefix them with "twitter_".
				for (var strProperty:String in obUser)
					dctUserInfo["twitter_" + strProperty] = obUser[strProperty];
				
				// Use the Twitter name as a temp display name
				AccountMgr.GetInstance().tempDisplayName = dctUserInfo.username;
				_obUserInfoCache = obResult;
				fnComplete(StorageServiceError.None, null, dctUserInfo);
			}
			if (_obUserInfoCache && _strUserId && _strUserId == _obUserInfoCache.user.id) {
				PicnikBase.app.callLater(fnOnGetResource, [ StorageServiceError.None, null, _obUserInfoCache]);
			} else {
				GetResource("users/show/" + _strUserId + ".xml", null, fnOnGetResource, oauth_token, oauth_token_secret);
			}
			_obUserInfoCache = null;
		}

		// We offer up a virtual Set, with id "account", that contains two items: the user's avatar and background images
		override protected function _GetSets(strUsername:String, fnComplete:Function, fnProgress:Function=null): void {
			PicnikBase.app.callLater(fnComplete, [ StorageServiceError.None, null,
					[ { id: "account", itemcount: 2, title: "Account", readonly: true } ] ]);
		}

		// Create two^H^H^Hthree items. One for the user's profile picture and another for their background image.
		// and after we created the image to be tweeted, we saved it to add here
		// UNDONE: can they have no (blank?) background?		
		override protected function FillItemCache(strSetId:String, strSort:String, strFilter:String, fnComplete:Function, obContext:Object): void {
			var fnOnGetUserInfo:Function = function (err:Number, strError:String, dctUserInfo:Object): void {
				if (err != StorageServiceError.None) {
					fnComplete(err, strError, obContext);					
				} else {
					ClearCachedItemInfo();
					
					// HACK: Twitter hasn't documented it but is standard thumbnail (48x48) is suffixed
					// with "_normal.jpg". It has a larger version suffixed with "_bigger.jpg" but the
					// one we really like, up to 500px, has only the ".jpg" extension.
					// DOUBLE-HACK: The above is true UNLESS they've moved the image over to s3 in which
					// case we see URLs ending in "image_normal" which we need to change to just "image".
					var strProfileImageUrl:String = dctUserInfo.twitter_profile_image_url.replace("_normal.", ".");
					strProfileImageUrl = strProfileImageUrl.replace("/image_normal", "/image");
					
					StoreCachedItemInfo(new ItemInfo({
						id: "picture", serviceid: "Twitter", title: Resource.getString("TwitterStorageService", "profile_picture"),
						sourceurl: strProfileImageUrl,
						thumbnailurl: strProfileImageUrl
					}));
					
					StoreCachedItemInfo(new ItemInfo({
						id: "background image", serviceid: "Twitter", title: Resource.getString("TwitterStorageService", "profile_background"),
						sourceurl: dctUserInfo.twitter_profile_background_image_url,
						thumbnailurl: dctUserInfo.twitter_profile_background_image_url,
						twitter_profile_background_color: dctUserInfo.twitter_profile_background_color,
						twitter_profile_text_color: dctUserInfo.twitter_profile_text_color,
						twitter_profile_link_color: dctUserInfo.twitter_profile_link_color,
						twitter_profile_sidebar_fill_color: dctUserInfo.twitter_profile_sidebar_fill_color,
						twitter_profile_sidebar_border_color: dctUserInfo.twitter_profile_sidebar_border_color,
						twitter_profile_background_tile: dctUserInfo.twitter_profile_background_tile
					}));
					
					if (_itemInfoCache != null) {
						// For benefit of the post-save page, we need to make people think this was saved on
						// Twitter itself.
						var itemInfo:ItemInfo = new ItemInfo( _itemInfoCache );
						_itemInfoCache = null;
						itemInfo['serviceid'] = "Twitter";
						itemInfo['webpageurl'] = null;
						StoreCachedItemInfo( itemInfo );
					}
				}
				fnComplete(StorageServiceError.None, null, obContext);
			}
			GetUserInfo(fnOnGetUserInfo);
		}
		
		protected override function UpdateItemCache(strSetId:String, strItemId:String, fnComplete:Function, obContext:Object): void {
			if (_itemInfoCache != null) {
				obContext.fnComplete(StorageServiceError.None, null, _itemInfoCache);			
			} else if (obContext) {
				obContext.fnComplete(StorageServiceError.ItemNotFound, null, null);
			}
		}

		//
		// Helpers
		//
		
		private static function GetResource(strResource:String, dctParams:Object, fnComplete:Function, strOAuthToken:String, strOAuthTokenSecret:String): void {
			var nRetriesLeft:Number = 1; // Retry once

			var fnGetResource:Function = function(): void {
				var strUrl:String = kstrTwitterAPIBase + strResource;
				var auth:OAuth = new OAuth();
				auth.Init(strUrl, dctParams, s_strConsumerSecurityKey, s_strConsumerSecuritySecret, "GET", strOAuthToken, strOAuthTokenSecret);
				strUrl = auth.GetRequestAsUrl();	
				var urlr:URLRequest = new URLRequest(strUrl);
				var urll:ProxyURLLoader = new ProxyURLLoader(urlr, null, fnOnGetResource, null, null);		
			}
			
			var fnOnGetResource:Function = function (urll:ProxyURLLoader, err:Number, strError:String): void {
				try {
					if (!urll.data) {
						if (nRetriesLeft > 0) {
							nRetriesLeft -= 1;
							fnGetResource();
						} else {
							fnComplete(StorageServiceError.IOError, "Failed to retreive data");
						}
						return;
					}
					
					var strData:String = urll.data.toString();
					if ((strData.length >= 6) && (strData.substr(6).toLowerCase() == "<html>") && (nRetriesLeft > 0)) {
						nRetriesLeft -= 1;
						fnGetResource();
						return;
					}
					
					var obData:Object = _xmlToObj(strData);

					if ('error' in obData) {
						fnComplete(StorageServiceError.IOError, obData.error.message);
						return;
					}
					
					fnComplete(0, null, obData);
					
				} catch (e:Error) {
					PicnikService.LogException("Exception in TwitterStorageService.GetResource: " + urll, e);
				}
			}
			
			fnGetResource();
		}

		///
		//
		//
		//
		//
		override public function CreateItem(strSetId:String, strItemId:String, itemInfo:ItemInfo, imgd:ImageDocument,
				fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
			// Clone the ItemInfo so we can update it w/o tampering with the original.
			itemInfo = new ItemInfo(itemInfo);
			
			// These properties won't be valid for the newly created item.
			itemInfo.sourceurl = null;
			itemInfo.thumbnailurl = null;
			itemInfo.webpageurl = null;
			itemInfo.id = null;
			itemInfo.etag = null;
			
			var dctRenderResponse:Object = null;
			var nRetriesLeft:int = 1;
			var strTwitGooUrl:String = null;
			_itemInfoCache = itemInfo;

			var dctParams:Object = {
				title: itemInfo.title ? itemInfo.title : "",
				description: itemInfo.description ? itemInfo.description : "",
				tags: itemInfo.tags ? itemInfo.tags : ""
			}
			
			// Post History			
			var fnOnCommitRenderHistory:Function = function (err:Number, strError:String): void {
				if (fnComplete != null)
					fnComplete(StorageServiceError.None, null, itemInfo);
			}

			// Called after successful save. Decides if we should save hisotry or not.
			var fnSaveHistory:Function = function(): void {
				if (AccountMgr.GetInstance().isGuest) {
					if (fnComplete != null)
						fnComplete(StorageServiceError.None, null, itemInfo);
				} else {						
					PicnikService.CommitRenderHistory(dctRenderResponse.strPikId, StorageServiceUtil.GetLastingItemInfo(itemInfo),
							GetServiceInfo().id, fnOnCommitRenderHistory);
				}
			}
			
			// called after the update to twitter	
			var fnStatusComplete:Function = function(err:Number, strError:String,  obData:Object=null): void {
				if ('error' in obData) {
					if(fnComplete != null)
						fnComplete(StorageServiceError.Unknown, "hash" in obData ? obData.hash.error : obData, null);
					return;
				}
				
				fnSaveHistory();
			}
			
			// Called after we've rendered and posted to twitgoo
			//
			//
			var fnOnRenderSuccess:Function = function(err:Number, strError:String, nHTTPStatus:int=0, dResponseInfo:Object=null, strResponse:String=null): void {
				dctRenderResponse = dResponseInfo;
				if (err != StorageServiceError.None) {
					if (fnComplete != null)
						fnComplete(err, strError, null);
				}
				var obData:Object = _xmlToObj(strResponse);
				if ('error' in obData) {
					if (nRetriesLeft > 0) {
						nRetriesLeft -= 1;
						fnRenderTweet(); //retry
					} else 	if (fnComplete != null) {
						fnComplete(StorageServiceError.IOError, obData.error, null);
					}
					return;
				}
				
				// Update the ItemInfo
				itemInfo.webpageurl = obData.rsp.mediaurl;
				itemInfo.sourceurl = obData.rsp.imageurl;
				itemInfo.thumbnailurl = obData.rsp.thumburl;
				itemInfo.id = obData.rsp.mediaid;

				strTwitGooUrl = obData.rsp.mediaurl;

				// get the image url
				// ensure that the tweet isn't over 140 chars
				// if it is, truncate the text, not the url
				var strTweet:String = itemInfo.twitter_strTweet;
				if (strTweet.length + strTwitGooUrl.length >= 140)
					strTweet = strTweet.slice(0, 140 - strTwitGooUrl.length - 1);
				strTweet += "\n" + strTwitGooUrl;
				
				UpdateStatus(strTweet, fnStatusComplete);	
			}
			
			// Handle response for PostImage for saved background or profile pic.
			//
			//
			var fnOnSavePictureOrBackground:Function = function (err:Number, strError:String, nHTTPStatus:int=0, dResponseInfo:Object=null, strResponse:String=null): void {
				if (err != StorageServiceError.None) {
					if (fnComplete != null)
						fnComplete(err, strError, null);
				}
				dctRenderResponse = dResponseInfo;
				var obData:Object = _xmlToObj(strResponse);
				
				var strError:String = null;
				if ('error' in obData)
					strError = obData.error;
				else if ('hash' in obData && 'error' in obData.hash)
					strError = obData.hash.error;
					
				if (strError) {
					if (nRetriesLeft > 0) {
						nRetriesLeft -= 1;
						fnSaveImages(); //retry
					} else {
						if (fnComplete != null)
							fnComplete(StorageServiceError.Unknown, obData.error, null);
					}
					return;
				}
				
				fnSaveHistory();
			}
			
			//  Render and Post profile or background to twitter
			//
			//
			var fnSaveImages:Function = function(): void {
				var strUrl:String = kstrTwitterAPIBase + "1/account/update_profile_" +
						(strSetId == "background" ? "background_" : "") + "image.xml";
						
				// Enforce dimension and file size limits
				var ptLimited:Point;
				if (strSetId == "picture") {
					// - picture: 500px width/height, 700KB
					ptLimited = Util.GetLimitedImageSize(imgd.width, imgd.height, 500, 500);
				} else {
					// - background: 2048px width (no height limit?), 800KB
					// UNDONE: enforce 800KB limit. Twitter returns "Invalid / used nonce" 401 error if too big
					ptLimited = Util.GetLimitedImageSize(imgd.width, imgd.height, 2048);
					dctParams.up_tile = itemInfo.twitter_profile_background_tile ? "true" : "false";
				}
				var auth:OAuth = new OAuth();
				auth.Init(strUrl, {}, s_strConsumerSecurityKey, s_strConsumerSecuritySecret, "POST", oauth_token, oauth_token_secret);
				dctParams._export_field = "image";
				dctParams.header_Authorization = auth.GetRequestAuthorizationHeader();
				new RenderHelper(imgd, fnOnSavePictureOrBackground, irsd).PostImage(strUrl, ptLimited.x, ptLimited.y, dctParams);
			}
			
			
			// Render and Post tweet image to TwitGoo
			//
			//
			var fnRenderTweet:Function = function(): void {
				var strT:String = _obUserInfoCache.user.screen_name;
				dctParams.up_username = strT;
				dctParams.up_source= "picnik";
				dctParams.up_passkey = MD5.hash(s_strTwitGooSecret + strT);
				dctParams._export_field = "media";
				new RenderHelper(imgd, fnOnRenderSuccess, irsd).PostImage("http://twitgoo.com/api/partnerUpload", imgd.width, imgd.height, dctParams);				
			}
			
			// Get this show kicked off!
			if (strSetId == 'picture' || strSetId == 'background')
				fnSaveImages();
			else
				fnRenderTweet();
		}	
		
		// Send the new status to twitter -- TWEET!
		private function UpdateStatus(strStatus:String, fnComplete:Function):void {
			var strUrl:String = kstrTwitterAPIBase + 'statuses/update.xml';
			var auth:OAuth = new OAuth();
			auth.Init(strUrl, {status:strStatus}, s_strConsumerSecurityKey, s_strConsumerSecuritySecret, "POST", oauth_token, oauth_token_secret);
			strUrl = auth.GetRequestAsUrl();
			
			var nRetriesLeft:Number = 1; // Retry once
			
			var fnRequestStatus:Function = function(): void {
				var urlr:URLRequest = new URLRequest(strUrl);
				urlr.method = "POST";
				urlr.data = ' '; // need something in the body for the proxy server
				var urll:ProxyURLLoader = new ProxyURLLoader(urlr, null, fnOnGetResource, null, null);
			}
			
			var fnOnGetResource:Function = function (urll:ProxyURLLoader, err:Number, strError:String): void {
				if (err != StorageServiceError.None) {
					if (fnComplete != null)
						fnComplete(err, strError, null);
						return;
				}
				
				var obData:Object = GetTwitterReturn(urll);
				if ('error' in obData) {
					if (nRetriesLeft > 0) {
						nRetriesLeft -= 1;
						fnRequestStatus();
					} else {
						if (fnComplete != null)
							fnComplete(StorageServiceError.IOError, obData.error);
					}
					return;
				}
				
				if (fnComplete != null)	{			
					fnComplete(0, null, obData);
				}
			}
			
			fnRequestStatus();
		}		
	}
}
