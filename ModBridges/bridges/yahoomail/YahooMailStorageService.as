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
//

package bridges.yahoomail {
	import api.PicnikRpc;
	
	import bridges.*;
	import bridges.storageservice.StorageServiceBase;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceRegistry;
	
	import com.adobe.serialization.json.JSON;
	
	import dialogs.DialogManager;
	
	import flash.events.TimerEvent;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	
	import mx.core.Application;
	import mx.resources.ResourceBundle;
	import mx.utils.ObjectProxy;
	
	import util.KeyVault;
	import util.LocUtil;
	
	public class YahooMailStorageService extends StorageServiceBase {
		private var _ymp:YahooMailProxy;
		private var _tmrCheckAuth:Timer=null;
		private var _nAuthRetries:int=0;
		private var _fnComplete:Function=null;
		private var _tmrRelogin:Timer;
		private var _dctPostAuthorizeParams:Object = null;
		private var _strYahooId:String = "";
		
		private var _aitmSelectedMessages:Array = null;
		private static const kstrSelectedMessagesSetId:String = "__selected_messages_setid__";
		private var _opProgressInfo:ObjectProxy;

		private var _ymf:YahooMailFolder = null; // Most recent folder for which we have called GetItems
		
  		[Bindable] [ResourceBundle("YahooMailStorageService")] private var rb:ResourceBundle;

		public function YahooMailStorageService() {
			_ymp = new YahooMailProxy(KeyVault.GetInstance().yahoomail.pub, KeyVault.GetInstance().yahoomail.priv);
			StorageServiceRegistry.Register(this);
			_opProgressInfo = new ObjectProxy({ymf:null});
		}
		
		public function GetProgressInfo(): ObjectProxy {
			return _opProgressInfo;
		}
		
		override public function GetServiceInfo(): Object {
			return StorageServiceRegistry.GetStorageServiceInfo("yahoomail");			
		}
		
		override public function Authorize(strPerm:String=null, fnComplete:Function=null): Boolean {
			// clear out authorization information
			PicnikRpc.SetUserProperties({ latest_auth_vars: "" }, "yahoo");
			_fnComplete = fnComplete;
			var fnPopupComplete:Function = function(err:int, errMsg:String, ob:Object): void {
				// start timer, look for new user properties
				if (_tmrCheckAuth == null) {
					_tmrCheckAuth = new Timer(5000, 1);
					_tmrCheckAuth.addEventListener(TimerEvent.TIMER_COMPLETE, OnCheckAuthTimerComplete);
				}
				_tmrCheckAuth.reset();
				_tmrCheckAuth.start();
				_nAuthRetries = 0;
			}
			PicnikBase.app.NavigateToURLInPopup(_ymp.loginURL, 775, 800, fnPopupComplete);
			return true;
		}		

		private function OnCheckAuthTimerComplete(evt:TimerEvent): void {
			var fnDone:Function = function(err:Number, obResults:Object): void {
	 			if (obResults && "yahoo" in obResults && "latest_auth_vars" in obResults.yahoo) {
	 				var strVars:String = obResults.yahoo.latest_auth_vars;
	 				var urlv:URLVariables = new URLVariables(strVars);
	 				if (urlv.hasOwnProperty("token")) {
						PicnikRpc.SetUserProperties({ latest_auth_vars: "" }, "yahoo");
						DialogManager.HideBlockedPopupDialog();
	 					var strToken:String = urlv.token;
	 					_ymp.SetToken(strToken, "OnCheckAuthTimerComplete");
	 					
	 					var fnOnAuthorized:Function = function( err:Number, strErr:String, dctResult:Object=null ):void {
		 					if (_fnComplete != null)
		 						_fnComplete(StorageServiceError.None, null, null, strToken);	 						
	 					}
	 					if (null != _dctPostAuthorizeParams) {
	 						var dctParams:Object = _dctPostAuthorizeParams;
	 						_dctPostAuthorizeParams = null;
	 						ProcessServiceParams(dctParams, fnOnAuthorized );
	 					} else {
	 						fnOnAuthorized( null, null );
	 					}
	 				}	
	 			} else {
	 				_nAuthRetries ++;
	 				if (_nAuthRetries <= 36) {			// only retry for 3 minutes (5000ms * 36) since Connect button pushed
						_tmrCheckAuth.reset();
						_tmrCheckAuth.start();
	 				}
	 			}
			}
			PicnikService.GetUserProperties("yahoo", fnDone);	
		}
		
		override public function HandleAuthCallback(obParams:Object, fnComplete:Function): void {
			// Remember the token
			var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount("YahooMail");
			tpa.SetToken(obParams.token);
			
			// Remember the userhash?
			tpa.SetUserId(obParams.userhash);
			
			// Go the extra step and use the token to get the "auth cookie" and WSSID from Yahoo
			var fnOnGetAuthCookie:Function = function (fSuccess:Boolean): void {
				if (fSuccess)
					StartReloginTimer();
				fnComplete();
			}
			
			_ymp.SetToken(obParams.token, "HandleAuthCallback");
			_ymp.GetAuthCookie(fnOnGetAuthCookie, "HandleAuthCallback");
		}
		
		override public function WouldLikeAuth(): Boolean {
			if (_dctPostAuthorizeParams != null && !IsLoggedIn()) {
				return true;
			}
			return false;
		}
		
		override public function IsLoggedIn(): Boolean {
			return _ymp.token != null;
		}
		
		// Log the user in. Yahoo! BBAuth sessions are documented to last 1 hour.
		//
		// fnComplete(err:Number, strError:String)
		// - None
		// - IOError
		// - InvalidUserOrPassword
		//
		// fnProgress(nPercent:Number)
		
		override public function LogIn(tpa:ThirdPartyAccount, fnComplete:Function, fnProgress:Function=null): void {
			try {
				_ymp.SetToken(tpa.GetToken(), "LogIn: tpa.GetToken");
				
				var fnOnGetAuthCookie:Function = function (fSuccess:Boolean): void {
					if (!fSuccess) {
						_ymp.SetToken(null, "LogIn failed");
						fnComplete(StorageServiceError.LoginFailed, "GetAuthCookie failed");
						return;
					}
					StartReloginTimer();
					fnComplete(StorageServiceError.None, null);
				}
				
				_ymp.GetAuthCookie(fnOnGetAuthCookie, "LogIn");
			} catch (err:Error) {
				var strLog:String = "Client exception: YahooMailStorageService.LogIn " + err.toString()+ "/" + tpa.GetUserId() + "/" + tpa.GetToken() + "/" + err.getStackTrace();
				PicnikService.Log(strLog, PicnikService.knLogSeverityError);				
				fnComplete(StorageServiceError.Unknown, err.toString());
			}
		}
		
		private function StartReloginTimer(): void {
			// We might already be doing it.
			if (_tmrRelogin)
				return;
								
			// Some services auto-logout and therefore have to be logged in periodically.
			var ssi:Object = GetServiceInfo();
			if ("login_lifetime" in ssi) {
				// NOTE: The "* 0.9" here is so we don't wait until the last second to relogin
				_tmrRelogin = new Timer(ssi.login_lifetime * 0.9 * 1000);
				_tmrRelogin.addEventListener(TimerEvent.TIMER, OnReloginTimer);
				_tmrRelogin.start();
			}
		}
		
		private function StopReloginTimer(): void {
			if (_tmrRelogin) {
				_tmrRelogin.stop();
				_tmrRelogin = null;
			}
		}

		private function OnReloginTimer(evt:TimerEvent): void {
			// If user has been totally de-authed there's no point in trying to relogin
			if (!IsLoggedIn())
				return;

			var fnOnReloginComplete:Function = function (err:Number, strError:String): void {
				// Nothing to do
			}
			
			var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount("YahooMail");
			LogIn(tpa, fnOnReloginComplete);
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
			_ymp.authCookie = null;
			_ymp.SetToken(null, "LogOut");
			_aitemInfoCache = null;
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
			_ymp.GetUserData({}, OnGetUserInfo, { fnComplete: fnComplete, fnProgress: fnProgress });
		}
		
		private function OnGetUserInfo(err:Number, strError:String, obResponse:Object, obContext:Object): void {
			var fnComplete:Function = obContext.fnComplete;
			if (err == StorageServiceError.None && obResponse) {
				try {
					var dctUserInfo:Object = {
						username: obResponse.result.data.userSendPref.defaultID,
						fullname: obResponse.result.data.userSendPref.defaultFromName
					}
					_strYahooId = dctUserInfo.username;
					fnComplete(StorageServiceError.None, null, dctUserInfo);
					return;
				} catch (e:Error) {
					LogYahooMailResponse("YahooMail Exception: OnGetUserInfo: " + err + ", " + e.getStackTrace(), obResponse);
					fnComplete(StorageServiceError.Exception, e.message, dctUserInfo);
					return;
				}
			}
			fnComplete(err, strError, null);
		}
		
		// Returns a dictionary filled with information about the service's item store.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - itemcount (opt)
		// - setcount (opt)
		//
		// It is assumed that there is only one store per service.
		//
		// fnComplete(err:Number, strError:String, dctUserInfo:Object=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		
		override public function GetStoreInfo(fnComplete:Function, fnProgress:Function=null): void {
			// Call GetSets and add up the # of photos/album to return { itemcount: <>, setcount: <> }
			var fnOnGetStoreInfoGetSets:Function = function (err:Number, strError:String, adctSetInfos:Array=null): void {
				try {
					if (err != StorageServiceError.None) {
						fnComplete(err, strError);
						return;
					}
					// There is no quick way to determine an itemcount.
					fnComplete(StorageServiceError.None, null, { setcount: adctSetInfos.length });
				} catch (err:Error) {
					LogYahooMailResponse("YahooMail Exception: OnGetStoreInfo: " + err + ", " + err.getStackTrace(), null);
					fnComplete(StorageServiceError.Exception, null);
				}							
			}
			
			GetSets(null, fnOnGetStoreInfoGetSets);
		}
		
		// Returns an array of dictionaries filled with information about the sets.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - id (req)
		// - itemcount (req)
		// - title (opt)
		// - description (opt)
		// - thumbnailurl (opt)
		// - webpageurl (opt)
		// - last_update (opt)
		// - createddate (opt)
		// - readonly (opt)
		//
		// fnComplete(err:Number, strError:String, adctSetInfo:Array=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		
		override public function GetSets(strUsername:String, fnComplete:Function, fnProgress:Function=null): void {
			try {
				// Get all the regular albums
				_ymp.ListFolders({}, OnGetSets, { fnComplete: fnComplete, fnProgress: fnProgress });
			} catch (err:Error) {
				LogYahooMailResponse("YahooMail Exception: GetSets: " + err + ", " + err.getStackTrace(), null);
				fnComplete(StorageServiceError.Exception, null);
			}							
		}
		
		// Sort the mail folders in this order
		private static var s_dctSortOrder:Object = { "Inbox": 0, "Draft": 1, "Sent": 2, "%40B%40Bulk": 3, "Trash": 4 };
		
		private function OnGetSets(err:Number, strError:String, obResponse:Object, obContext:Object): void {
			var fnComplete:Function = obContext.fnComplete;
			if (err == StorageServiceError.None && obResponse != null) {
				var adctSetInfos:Array = [];
				try {
					var adctFolders:Array = obResponse.result.folder;
					for each (var dctFolder:Object in adctFolders) {
						var dctSetInfo:Object = {
							id: dctFolder.folderInfo.fid,
							itemcount: 0, // UNDONE: required but unknown!
							title: dctFolder.folderInfo.name
						}
						
						// HACK: The spam folder is named "@B@Bulk". Why doesn't Yahoo fix it? Maybe it will break apps.
						if (dctSetInfo.title == "@B@Bulk")
							dctSetInfo.title = Resource.getString("YahooMailStorageService", "spam");
						
						adctSetInfos.push(dctSetInfo);
					}
					
					// The default folder order we want is: Inbox, Drafts, Sent, Spam, Trash, <user folders, case-insensitive sort>
					// Yahoo returns the folders in case-senstive sort order, @B@Bulk first.
					var fnCompare:Function = function (dctA:Object, dctB:Object): Number {
						var strA:String = (dctA.title as String).toLocaleLowerCase();
						var strB:String = (dctB.title as String).toLocaleLowerCase();
						if (strA == strB)
							return 0;
						if (dctA.id in s_dctSortOrder) {
							if (dctB.id in s_dctSortOrder)
								return s_dctSortOrder[dctA.id] < s_dctSortOrder[dctB.id] ? -1 : 1;
							return -1;
						} else if (dctB.id in s_dctSortOrder) {
							return 1;
						}
						return strA < strB ? -1 : 1;
					}
					adctSetInfos.sort(fnCompare);
					
					if (_aitmSelectedMessages != null) {
						dctSetInfo = { id: kstrSelectedMessagesSetId,
										itemcount: _aitmSelectedMessages.length,
										title: Resource.getString("YahooMailStorageService", "selectedMessages")
								};
						// stick it on the front
						adctSetInfos.unshift( dctSetInfo );
					}
					
					fnComplete(StorageServiceError.None, null, adctSetInfos);	
					return;
				} catch (err:Error) {
					LogYahooMailResponse("YahooMail Exception: OnGetSets: " + err + ", " + err.getStackTrace(), obResponse);
					fnComplete(StorageServiceError.Exception, null);
					return;
				}
			}
			fnComplete(err, strError);
		}
		
		public function GetProxy(): YahooMailProxy {
			return _ymp;
		}
		
		public function OnFolderChanged(strSetId:String, strSort:String, strFilter:String): void {
			GetYahooMailFolder(strSetId, strSort, strFilter);
		}
		
		private function GetYahooMailFolder(strSetId:String, strSort:String, strFilter:String): YahooMailFolder {
			var ymf:YahooMailFolder = YahooMailFolder.GetFolder(strSetId, strSort, strFilter, AccountMgr.GetThirdPartyAccount("YahooMail").GetToken(), this);
			_ymf = ymf;
			if (_ymf != null) {
				// Note that there are cases where _aitemInfoCache is set to null but _ymf is not changed. In these cases, we will need to update _aitemInfoCache
				_aitemInfoCache = _ymf.GetCache();
				_opProgressInfo.ymf = _ymf;
				_ymf.Activate();
			} else {
				_aitemInfoCache = [];
				_opProgressInfo.ymf = null;
			}
			return _ymf;
		}
		
		public function Refresh(): void {
			if (_ymf != null) {
				_ymf.Reset();
			}
		}

		// Returns an array of dictionaries filled with information about the items.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - id (req)
		// - thumbnailurl (req)
		// - sourceurl (req)
		// - title (opt)
		// - description (opt)
		// - tags (opt)
		// - width (opt)
		// - height (opt)
		// - size (opt)
		// - sort values (opt)
		// - createddate (opt)
		//
		// fnComplete(err:Number, strError:String, adctItemInfo:Array=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		// UNDONE: standard sorts

		// There is not an efficient way to map from an item index to message/part.
		// What we do is populate a cache as needed to fullfill the items request by enumerating
		// as many messages/parts as necessary to find them. The cache is invalidated
		// if strSetId, strSort, or strFilter are changed.
		
		override public function GetItems(strSetId:String, strSort:String, strFilter:String, nStart:Number, nCount:Number, fnComplete:Function, fnProgress:Function=null): void {
			try {
				// If what is requested is in the cache, return it from there.
				if (strSetId == kstrSelectedMessagesSetId) {
					ClearCachedItemInfo();
					for each (var itmSelected:ItemInfo in _aitmSelectedMessages) {
						StoreCachedItemInfo(itmSelected);
					}
					if (_aitemInfoCache == null) _aitemInfoCache = [];
					Application.application.callLater(fnComplete, [ StorageServiceError.None, null, _aitemInfoCache.slice(nStart, nStart + nCount) ]);
					return;
				}
				GetYahooMailFolder(strSetId, strSort, strFilter).ReadMail(nStart, nCount, fnComplete);
			} catch (err:Error) {
				PicnikService.LogException("Client exception: YahooMailStorageService.GetItems: ", err);
				fnComplete(StorageServiceError.Exception, null);
			}												
		}
		
		// See IStorageService.GetResourceURL for this method's documentation		
		override public function GetResourceURL(strResourceId:String): String {
			return strResourceId + "&appid=" + encodeURIComponent(_ymp.appId) + "&WSSID=" + encodeURIComponent(_ymp.WSSID) +
					"&_cookie=" + encodeURIComponent(_ymp.authCookie);			
		}
		
		protected override function UpdateItemCache( strSetId:String, strItemId:String, fnComplete:Function, obContext:Object ): void {
			try {
				var fnOnGetMessage:Function = function (err:Number, strError:String, obResponse:Object, obContext:Object): void {
					try {
						if (err != StorageServiceError.None || obResponse == null) {
							fnComplete(err, strError, obContext);
							return;
						}
						
						for each (var dctMessage:Object in obResponse.result.message) {
							for each (var dctPart:Object in dctMessage.part) {
								if (dctPart.type == "image" || (dctPart.type == "application" && IsImageFileType(dctPart.filename))) {
									var itemInfo:ItemInfo = ItemInfoFromMessagePart(dctMessage, dctPart, strSetId);
									UpdateCachedItemInfo(itemInfo);
								}
							}
						}
						fnComplete(StorageServiceError.None, null, obContext);
												
					} catch (err:Error) {
						LogYahooMailResponse("YahooMail Exception: UpdateItemCache: " + err + ", " + err.getStackTrace(), obResponse);
						fnComplete(StorageServiceError.Exception, null, obContext);
					}
				}
				
				var aSplitId:Array = strItemId.split("/", 2);
				var strMid:String = aSplitId[0];
				
				_ymp.GetMessage({ truncateAt: 0, fid: strSetId, message: strMid }, fnOnGetMessage); 
							
			} catch (err:Error) {
				var strLog:String = "Client exception: YahooMailStorageService.UpdateItemCache: ";
				PicnikService.LogException(strLog, err);
				fnComplete(StorageServiceError.Exception, null, obContext);
			}												
		}

		protected override function FillItemCache2( apartialItemInfos:Array, fnComplete:Function, obContext:Object ): void {
			try {
				var fnOnGetMessage:Function = function (err:Number, strError:String, obResponse:Object, obContext2:Object): void {
					try {
						if (err != StorageServiceError.None || obResponse == null) {
							fnComplete(err, strError, obContext);
							return;
						}

						for each (var dctMessage:Object in obResponse.result.message) {
							for each (var dctPart:Object in dctMessage.part) {
								if (dctPart.type == "image" || (dctPart.type == "application" && IsImageFileType(dctPart.filename))) {
									var itemInfo:ItemInfo = ItemInfoFromMessagePart(dctMessage, dctPart, obContext2.setid);
									UpdateCachedItemInfo(itemInfo);
								}
							}
						}

						if (astrMidsToGet.length > 0) {
							var strMid:String = astrMidsToGet.pop();
							var oItemInfo:ItemInfo = aobItemInfosByMid[strMid];
							_ymp.GetMessage({ truncateAt: 0, fid: oItemInfo.setid, message: strMid }, fnOnGetMessage);
						} else {
							fnComplete(StorageServiceError.None, null, obContext);
						}
												
					} catch (err:Error) {
						LogYahooMailResponse("YahooMail Exception: UpdateItemCache: " + err + ", " + err.getStackTrace(), obResponse);
						fnComplete(StorageServiceError.Exception, null, obContext);
					}
				}
				
				var aobItemInfosByMid:Object = {};
				var astrMidsToGet:Array = [];
				var strMid:String;
				for each( var itemInfo:ItemInfo in apartialItemInfos ) {
					var aSplitId:Array = itemInfo.id.split("/", 2);
					strMid = aSplitId[0];
					if (astrMidsToGet.indexOf(strMid) == -1) {
						astrMidsToGet.push(strMid);
						aobItemInfosByMid[strMid] = itemInfo;
					}
				}
				
				if (astrMidsToGet.length > 0) {
					strMid = astrMidsToGet.pop();
					var oItemInfo:ItemInfo = aobItemInfosByMid[strMid];
					_ymp.GetMessage({ truncateAt: 0, fid: oItemInfo.setid, message: { mid: strMid, blockImages: "none" }}, fnOnGetMessage, {setid:oItemInfo.setid});
				}
				 
			} catch (err:Error) {
				var strLog:String = "Client exception: YahooMailStorageService.UpdateItemCache: ";
				PicnikService.LogException(strLog, err);
				fnComplete(StorageServiceError.Exception, null, obContext);
			}												
			
		}
		
		public static function LogYahooMailResponse(strPrologue:String, obResponse:Object):void {		
			var strError:String = strPrologue + "/";
			if (obResponse) strError += JSON.encode(obResponse);
			else strError += "(JSON is null)";			
			PicnikService.Log(strError, PicnikService.knLogSeverityWarning);
		}		

		public function ItemInfoFromMessagePart(dctMessage:Object, dctPart:Object, strSetId:String): ItemInfo {
			var strThumbnailUrl:String = "http://mail.yahooapis.com/ya/download?mid=" + encodeURIComponent(dctMessage.mid) +
					"&fid=" + encodeURIComponent(strSetId) + "&pid=" + encodeURIComponent(dctPart.partId) +
					"&_yid=" + encodeURIComponent(_strYahooId.replace('@','_')) +
					"&appid=" + encodeURIComponent(_ymp.appId) + "&WSSID=" + encodeURIComponent(_ymp.WSSID);
			
			var itemInfo:ItemInfo = new ItemInfo({
				id: dctMessage.mid + "/" + dctPart.partId,
				setid: strSetId,
				serviceid: "YahooMail",
				title: dctPart.filename,
				description: Resource.getString("YahooMailStorageService", "from") + ": " +
						(dctMessage.from.name ? dctMessage.from.name : dctMessage.from.email) + "\n" +
						Resource.getString("YahooMailStorageService", "subject") + ": " + dctMessage.subject + "\n" +
						Resource.getString("YahooMailStorageService", "received") + ": " +
						LocUtil.shortDate(new Date(dctMessage.receivedDate * 1000)),
//				ownerid: String(xmlPhoto.@username),
//				webpageurl: String(xmlPhoto.browseurl),
				sourceurl: StorageServiceRegistry.GetStorageServiceURL(this, "http://mail.yahooapis.com/ya/download?mid=" +
						encodeURIComponent(dctMessage.mid) + "&fid=" + encodeURIComponent(strSetId) +
						"&pid=" + encodeURIComponent(dctPart.partId)),
//				thumbnailurl: dctPart.thumbnailurl, // DWM: I wish!
				thumbnailurl: PicnikService.serverURL + "/thumbproxy?method=get&url=" + encodeURIComponent(strThumbnailUrl) + "&cookie=" + encodeURIComponent(_ymp.authCookie),
				createddate: dctMessage.receivedDate
			});

			return itemInfo;
		}
		
		// Return true if the passed-in filename has an image-type extension
		static private var s_astrImageExt:Array = [ "jpg", "jpeg", "jfif", "png", "tif", "tiff", "gif", "bmp", "tga", "xbm", "ppm" ];
		
		static public function IsImageFileType(strFilename:String): Boolean {
			var strExt:String = strFilename.toLowerCase().slice(strFilename.lastIndexOf(".") + 1);
			for each (var strImageExt:String in s_astrImageExt)
				if (strExt == strImageExt)
					return true;
			return false;
		}
	
		public override function ProcessServiceParams(dctParams:Object, fnComplete:Function, fnProgress:Function=null): void {			
			try {
				// store a local var with "this" that it'll be available within the callbacks below
				var ssThis:StorageServiceBase = this;
				
				// first, we must log in!
				if (!IsLoggedIn()) {
					var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount("YahooMail");
					LogIn(tpa, function (err:Number, strError:String = ""): void {					
						if (err == StorageServiceError.None) {
							// login was successful -- invoke ProcessServiceParams again
							// UNDONE: add something to dctParams to prevent infinite loopage
							if (!ProcessServiceParams(dctParams, fnComplete, fnProgress)) {
								fnComplete(err, strError, {} );																
							}
						} else {
							// bail
							if (err == StorageServiceError.NotLoggedIn || err == StorageServiceError.LoginFailed) {
								_dctPostAuthorizeParams = dctParams;
								err = StorageServiceError.PendingAuth;
							}
							fnComplete(err, strError, { ss: ssThis });								
							return;
						}
					});
					return; // Async operation in progress
				}
							
				// we are properly authorized, so process the command
				if ("_select" in dctParams && dctParams['_select'].length > 0) {			
					try {
						var itemSelection:ItemManager = new ItemManager();
						itemSelection.defaultService = "yahoomail";
						itemSelection.Deserialize( dctParams['_select'] );
					
						// we need to process the item selection to fill in all the iteminfos
						var fnOnGetItemInfos:Function = function(err:Number, strErr:String, aitemInfos:Array = null ):void {
							if (aitemInfos && err == StorageServiceError.None) {
								_aitmSelectedMessages = [];
								for each (var itm:ItemInfo in aitemInfos) {
									_aitmSelectedMessages.push(itm);
								}
							}							
							fnComplete( err, strErr, {} );
						};
														
						// find all the yahoomail items
						var aitems:Array = [];
						for (var i:Number = 0; i < itemSelection.items.length; i++ ) {
							aitems.push(itemSelection.items[i]);
						}
						if (aitems.length > 0) {
							GetItemInfos( aitems, fnOnGetItemInfos );
						} else {
							// no items to get
							fnComplete(StorageServiceError.None, null, {} );																
							return;
						}								
															
					} catch (err:Error) {
						var strLog4:String = "Client exception:YahooMailStorageService.ProcessServiceParams.Multi: ";
						strLog4 += err.toString();
						PicnikService.Log(strLog4, PicnikService.knLogSeverityError);
						PicnikBase.app.callLater(fnComplete, [StorageServiceError.Unknown, ""]);						
						return;
					}

					return;
				}
			} catch (err:Error) {
				var strLog:String = "Client exception: YahooMailStorageService.ProcessServiceParams: ";
				strLog += err.toString();
				PicnikService.Log(strLog, PicnikService.knLogSeverityError);
			}
			
			fnComplete(StorageServiceError.None, null, {} );																
			return;
		}	
	}
}
