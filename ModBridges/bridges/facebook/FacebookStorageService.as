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

package bridges.facebook {
	import bridges.*;
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceUtil;
	
	import com.adobe.serialization.json.JSON;
	
	import dialogs.DialogManager;
	
	import imagine.ImageDocument;
	
	import mx.resources.ResourceBundle;
	
	import util.DynamicLocalConnection;
	import util.IRenderStatusDisplay;
	import util.KeyVault;
	import util.LocUtil;
	
	public class FacebookStorageService implements IStorageService {
		public static const kstrPhotosOfYouSetId:String = "photos_of_you_setid";
		
  		[Bindable] [ResourceBundle("FacebookStorageService")] private var rb:ResourceBundle;

		private var _strUserId:String; 	// uid
		private var _strAuth:String; 	// session_key
		private var _strApiKey:String;
		private var _fbp:FacebookProxy;
		private var _strUserThumbnailUrl:String;

		// GetItems populates this cache when it is passed a nStart value of 0 and
		// pulls items from the cache for nStart values > 0
		private var _adctItemInfoCache:Array;
		private var _adctFriendInfoCache:Array;
		private var _dctUserInfoCache:Object;
		
		private var _fnComplete:Function = null;
		private var _lconFacebook:DynamicLocalConnection = null;
		private var _fLconFacebookConnected:Boolean = false;


		public function TellYourFriends(): void {
			var astrMatch:Array = PicnikService.serverURL.match(/\/\/([^\/]*)/i);
			var strDomain:String = "www.mywebsite.com";
			if (astrMatch)
				strDomain = (astrMatch[1] as String).toLowerCase();
			
			var strAppUrl:String = "picnik";

			if (strDomain == "local.mywebsite.com")
				strAppUrl = "picnik-local";
			else if (strDomain == "test.mywebsite.com")
				strAppUrl = "picnik-test";
				
			var strFullAppUrl:String = "http://apps.facebook.com/" + strAppUrl; 

			var dctArgs:Object = {};
			dctArgs["api_key"] = _strApiKey;
			dctArgs["content"] = LocUtil.rbSubst('FacebookStorageService', "invite_content", strFullAppUrl);
			dctArgs["type"] = "Picnik";
				
			dctArgs["action"] = strFullAppUrl;
			dctArgs["actiontext"] = Resource.getString("FacebookStorageService", "invite_header");
			dctArgs["invite"] = "true";
			dctArgs["max"] = 20;
			PicnikBase.app.NavigateToURLWithIframeBreakout("http://www.facebook.com/multi_friend_selector.php" + _fbp.BuildQuery(dctArgs), "_blank");
		}
					
		public function FacebookStorageService() {
			_strApiKey = KeyVault.GetInstance().facebook.appid;
			_fbp = new FacebookProxy(_strApiKey, KeyVault.GetInstance().facebook.priv);
		}
		
		public function GetServiceInfo(): Object {
			return {id: "Facebook",
					visible: true,
					name: "Facebook",
					create_sets: true,
					set_descriptions: true };
		}
		
		public function Authorize(strPerm:String=null, fnComplete:Function=null): Boolean {
			var strUrl:String;
			var strNext:String = PicnikService.serverURL + "/callback/facebook";
			if (strNext.toLowerCase().indexOf("local.mywebsite.com") == -1) {
				strNext = strNext.replace("http://", "https://");
			}
			
			strUrl = "http://www.facebook.com/dialog/oauth?client_id=" + _strApiKey + "&scope=user_photos,friends_photos,publish_stream";
			strUrl += "&redirect_uri=" + escape(strNext);
			
			var fnPopupOpen:Function = function(err:int, errMsg:String, ob:Object): void {
				// listen for new user properties

				_lconFacebook = new DynamicLocalConnection();
				_lconFacebook.allowPicnikDomains();
				_lconFacebook["successMethod"] = function(strCBParams:String=null): void {
					// the popup succeeded!
					if (_fnComplete != null) {
						_fnComplete(0, "", strCBParams);
						_fnComplete = null;
					}
					try {
						_lconFacebook.close();
					} catch (e:Error) {
						//
					}
					//_fLconFacebookConnected = false;
					_lconFacebook= null;
					
					DialogManager.HideBlockedPopupDialog();
				};
				
				// steveler: keeping track of the connected state can cause weird
				// lcon errors if it doesn't work the first time around.
				//if (!_fLconFacebookConnected) {
					try {
						_lconFacebook.connect("facebookAuth");
					} catch (e:Error) { /*NOP*/ }
					//_fLconFacebookConnected = true;
				//}
			}

			_fnComplete = fnComplete;
			PicnikBase.app.NavigateToURLInPopup(strUrl, 800, 800, fnPopupOpen);
			return true;

		}
		
		public function HandleAuthCallback(obParams:Object, fnComplete:Function): void {
		}
		
		public function IsLoggedIn(): Boolean {
			return _strAuth != null;
		}
		
		// Log the user in. No assumptions are to be made regarding how long the session lasts.
		//
		// fnComplete(err:Number, strError:String)
		// - None
		// - IOError
		// - InvalidUserOrPassword
		//
		// fnProgress(nPercent:Number)
		
		public function LogIn(tpa:ThirdPartyAccount, fnComplete:Function, fnProgress:Function=null): void {
			// Validate the token by doing a trivial request that will fail if the
			// session_key is no longer valid

			try {
				// Initialize these becuase GetUserInfo needs them			
				
				_fbp.token = tpa.GetToken();
				
				_GetUserInfo(function (err:Number, strError:String, dctUserInfo:Object=null): void {
					if (err != StorageServiceError.None) {
						// Clear these out so the StorageService remains pristine if the user
						// isn't logged in.
						_fbp.token = null;
						_strUserId = null;
					} else {
						_strAuth = tpa.GetToken();
					}
					fnComplete(err, strError);
				}, null, false);
			} catch (err:Error) {
				var strLog:String = "Client exception: FacebookStorageService.LogIn " + err.toString()+ "/" + tpa.GetUserId() + "/" + tpa.GetToken();
				PicnikService.LogException(strLog, err);				
				fnComplete(StorageServiceError.Unknown, err.toString() );
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

		public function LogOut(fnComplete:Function=null, fnProgress:Function=null): void {
			_strAuth = null;
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

		public function GetUserInfo(fnComplete:Function, fnProgress:Function=null): void {
			_GetUserInfo(fnComplete,fnProgress,true);
		}

		private function _GetUserInfo(fnComplete:Function, fnProgress:Function=null, fFriendsToo:Boolean=true ):void {
			_fbp.CallGraph( "/me", {}, OnGetUserInfo, { fnComplete: fnComplete, fnProgress: fnProgress, fFriendsToo: fFriendsToo } );	
		}
		
		private function OnGetUserInfo(obResp:Object, obContext:Object = null): void {
			try {
				var strError:String = "";
				var nError:Number = StorageServiceError.None;
				var fnComplete:Function = obContext.fnComplete;
				nError = CheckFacebookObject("OnGetUserInfo", obResp, true);
				if (StorageServiceError.None == nError) {
					_strUserId = obResp['id'];
					var dctUserInfo:Object = {
						username: obResp['name'],
						fullname: obResp['name'],
						webpageurl: obResp['link'],
						publish_stream: true
					}
					
					var strThumbnailUrl:String = _fbp.GetGraphUrl("/me/picture");
					if (strThumbnailUrl && strThumbnailUrl != "") {
						dctUserInfo.thumbnailurl = strThumbnailUrl;
						_strUserThumbnailUrl = strThumbnailUrl;
					}		
					
					// Use the Facebook name as a temp display name
					AccountMgr.GetInstance().tempDisplayName = dctUserInfo.fullname;

				}
			} catch (e:Error) {
				nError = StorageServiceError.Unknown;
				LogFacebookObject( "Facebook Exception: OnGetUserInfo: " + e + ", " + e.getStackTrace(), obResp );
			}
			
			fnComplete(nError, null, dctUserInfo);
			
			if (nError == StorageServiceError.None) {
				
//				var fnGetPermission:Function = function():void {
//						GetPermission( "publish_stream", function (sse:Number, strError:String, fPerm:Boolean=false):void {
//							if (sse == StorageServiceError.None)
//								dctUserInfo.publish_stream = fPerm;			
//							
//						});					
//					}
				
				if ("fFriendsToo" in obContext && obContext.fFriendsToo) {
					GetFriends(	function (sse:Number, strError:String, adctFriends:Array=null):void {
						if (sse == StorageServiceError.None)
							dctUserInfo.adctFriends = adctFriends;
						_dctUserInfoCache = dctUserInfo;
						fnComplete(nError, null, dctUserInfo);
  					});
				} else {
					_dctUserInfoCache = dctUserInfo;
					fnComplete(nError, null, dctUserInfo);
				}				
			} else {
				fnComplete(nError, strError);
			}			
		}
//		
//		private function GetPermission( strPerm:String, fnComplete:Function, fnProgress:Function=null): void {
//			var nError:Number = StorageServiceError.None;
//			try {
//				_fbp.users_hasAppPermission({ext_perm: strPerm},
//											OnGetPermission,
//											{ fnComplete: fnComplete,
//											  fnProgress: fnProgress });
//			} catch (e:Error) {
//				nError = StorageServiceError.Unknown;
//				PicnikService.LogException( "Client exception in FacebookStorageService.GetPermission", e );
//				fnComplete(nError, null, null);
//			}		
//		}
//				
//		private function OnGetPermission(xml:XML, obContext:Object = null): void {
//			var fPerm:Boolean = false;			
//			var nError:Number = StorageServiceError.None;
//			try {
//				nError = CheckFacebookXML("OnGetPermission", xml, true);
//				if (StorageServiceError.None == nError) {
//					fPerm = xml.valueOf() != "0" ? true : false;
//				}
//			} catch (e:Error) {
//				nError = StorageServiceError.Unknown;
//				LogFacebookXML( "Facebook Exception: OnGetPermission: " + e + ", " + e.getStackTrace(), xml );
//			}			
//			obContext.fnComplete(nError, null, fPerm);
//		}
//		

		public function SetUserInfo(dctUserInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			fnComplete(StorageServiceError.None, null, null);
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
		
		public function GetStoreInfo(fnComplete:Function, fnProgress:Function=null): void {
			var fnOnGetStoreInfoGetSets:Function = function (err:Number, strError:String, adctSetInfos:Array=null): void {
				try {
					if (err != StorageServiceError.None) {
						fnComplete(err, strError);
						return;
					}
					var cItems:Number = 0;
					for each (var dctSetInfo:Object in adctSetInfos)
					if (dctSetInfo.itemcount)
						cItems += dctSetInfo.itemcount;
					fnComplete(StorageServiceError.None, null, { itemcount: cItems, setcount: adctSetInfos.length });
				} catch (err:Error) {
					var strLog:String = "Client exception: FacebookStorageService.OnGetStoreInfoGetSets: ";
					strLog += _strUserId + "/" + _strAuth;
					PicnikService.LogException(strLog, err);
					fnComplete( StorageServiceError.Unknown, null );
				}				
			}
			
			GetSets( null, fnOnGetStoreInfoGetSets);
		}
		
		public function SetStoreInfo(dctStoreInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "FacebookStorageService.SetStoreInfo not implemented");
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
		private function FindProfileSet(adctSetInfos:Array): Number {
			if (adctSetInfos == null || adctSetInfos.length == 0) return -1;
			for (var i:Number = 0; i < adctSetInfos.length; i++) {
				var dctSetInfo:Object = adctSetInfos[i];
				if ('webpageurl' in dctSetInfo) {
					var strWebPageUrl:String = dctSetInfo.webpageurl;
					var iBreak:Number = strWebPageUrl.indexOf('?');
					if (iBreak > -1) {
						var obQueryParams:Object = Util.ObFromQueryString(strWebPageUrl.substr(iBreak+1));
						if ('aid' in obQueryParams && obQueryParams['aid'] == '-3') {
							return i;
						}
					}
				}
			}
			return -1; // Not found
		}
		
		public function GetSets( strUsername:String, fnComplete:Function, fnProgress:Function=null): void {
			try {
				// Get all the regular albums
				var struid:String = strUsername ? strUsername : _strUserId;
				var fFriend:Boolean = ( struid != _strUserId );
					
				GetAlbums( struid,
					function (err:Number, strError:Number, adctSetInfos:Array=null): void {
						try {
							var dctSetInfo:Object = null;
							
							if (err != StorageServiceError.None) {
								fnComplete(err, strError);
								return;
							}
//
//							var iProfileSet:Number = FindProfileSet(adctSetInfos);
//							if (iProfileSet > -1) {
//								// Found it, move it to the end
//								dctSetInfo = adctSetInfos[iProfileSet];
//								adctSetInfos.splice(iProfileSet, 1);
//								adctSetInfos.push(dctSetInfo);
//							}
//									
							// Add in the "Photos tagged with me" virtual album
							var strTitle:String = (fFriend == false) ? Resource.getString("FacebookStorageService", "pics_of_you") : Resource.getString("FacebookStorageService", "pics_of_friend");
							dctSetInfo = {
								title: strTitle,
								itemcount: 0,
								id: kstrPhotosOfYouSetId + "/" + struid,
								webpageurl: "http://www.facebook.com/photo_search.php?id=" + struid,
								readonly: true
							}
							if (!fFriend && _strUserThumbnailUrl)
								dctSetInfo.thumbnailurl = _strUserThumbnailUrl;
							adctSetInfos.unshift(dctSetInfo);
							
							fnComplete(StorageServiceError.None, null, adctSetInfos);
						} catch (err:Error) {
							var strLog:String = "Client exception: FacebookStorageService.GetSets.OnGetAlbums1: ";
							PicnikService.LogException(strLog, err);
							fnComplete( StorageServiceError.Unknown, null );
						}				
											
					});		
			} catch (err:Error) {
				var strLog:String = "Client exception: FacebookStorageService.GetSets: ";
				strLog += _strUserId + "/" + _strAuth;
				PicnikService.LogException(strLog, err);
				fnComplete( StorageServiceError.Unknown, null );
			}				
			
		}
		
		private function GetAlbums( strUserId:String, fnComplete:Function): void {
			_fbp.CallGraph( "/" + strUserId + "/albums", {}, OnGetAlbums, { fnComplete: fnComplete });
		}
		
		private function OnGetAlbums(obResp:Object, obContext:Object=null): void {
			try {
				var strError:String = "";
				var nError:Number = StorageServiceError.None;
				var fnComplete:Function = obContext.fnComplete;
				nError = CheckFacebookObject("OnGetAlbums", obResp, true);
				if (StorageServiceError.None != nError) {
					var strErr:String = Resource.getString("FacebookStorageService", "no_album_info");
					fnComplete(nError, strErr);
					return;					
				}
							
				var adctSetInfos:Array = [];
				var adctSetInfosWithCovers:Array = [];
				var apid:Array = [];
				for each (var obAlbum:Object in obResp.data) {
					var dctSetInfo:Object = {
						title: obAlbum.name,
						id: obAlbum.id,
						webpageurl: obAlbum.link,
						createddate: obAlbum.created_time,
						last_update: obAlbum.updated_time
					}
					
					if ("description" in obAlbum) {
						dctSetInfo['description'] = obAlbum['description']
					}

					if ("count" in obAlbum) {
						dctSetInfo.itemcount = Number(obAlbum.count);
					} else {
						dctSetInfo.itemcount = 0;	
					}
					
					if ("cover_photo" in obAlbum) {
						dctSetInfo.thumbnailurl = _fbp.GetGraphUrl("/" + obAlbum.cover_photo + "/picture");
					}
					
					adctSetInfos.push(dctSetInfo);
				}
				
				fnComplete(StorageServiceError.None, null, adctSetInfos);				
			} catch (err:Error) {
				var strLog:String = "Client exception: FacebookStorageService.OnGetAlbums: ";
				strLog += _strUserId + "/" + _strAuth;
				PicnikService.LogException(strLog, err, null, (obResp ? "" : "(obResp is null)"));
			}				
				
		}
		
		public function CreateSet(dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			_fbp.PostGraph("/me/albums", { name: dctSetInfo.title, description: dctSetInfo.description},
			 	function (obResp:Object, obContext:Object=null): void {
			 		try {
						var strError:String = "";
						var nError:Number = StorageServiceError.None;
						nError = CheckFacebookObject("OnCreateSet", obResp, true);
						if (StorageServiceError.None != nError) {
							var strErr:String = Resource.getString("FacebookStorageService", "create_set_failed");
							fnComplete(nError, strErr);
							return;					
						}
						
						var dctNewSetInfo:Object = {
							title: dctSetInfo.title,
							itemcount: 0,
							id: obResp['id'],
							description: dctSetInfo.description
						}
			
						fnComplete(StorageServiceError.None, null, dctNewSetInfo);
			 		} catch( err:Error ) {
						var strLog:String = "Client exception: FacebookStorageService.CreateSet: ";
						strLog += _strUserId + "/" + _strAuth;
						PicnikService.LogException(strLog, err, null, (obResp ? "" : "(obResp is null)"));
						fnComplete( StorageServiceError.Unknown, null );
			 		}
				});					
		}
		
		public function DeleteSet(strSetId:String, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "FacebookStorageService.DeleteSet not implemented");
		}
		
		public function GetSetInfo(strSetId:String, fnComplete:Function, fnProgress:Function=null): void {			
			Debug.Assert(false, "FacebookStorageService.GetSetInfo not implemented");
		}
		
		public function SetSetInfo(strSetId:String, dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "FacebookStorageService.SetSetInfo not implemented");
		}
		
		public function DeleteItem(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "FacebookStorageService.DeleteItem not implemented");
		}
		
		// Creates a new item and returns a dictionary with details about it. CreateItem is highly
		// service dependent. In an extreme case, the service may ignore any or all of the SetId,
		// ItemId, ItemInfo, and imgd parameters and return an empty ItemInfo.
		// The passed in ItemInfo may contain
		// - title (opt)
		// - description (opt)
		// - tags (opt)
		//
		// The returned ItemInfo may contain
		// - itemid
		//
		// fnComplete(err:Number, strError:String, itemInfo:ItemInfo=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		
		public function CreateItem(strSetId:String, strItemId:String, itemInfo:ItemInfo, imgd:ImageDocument,
				fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
					
			var nTries:int = 0;	
			var fnDoTheUpload:Function = function():void {		
					nTries++;		
					_fbp.Upload(imgd, strSetId, strItemId, itemInfo.title, function (obResp:Object, dResponseInfo:Object=null, obContext:Object=null): void {
						var strLog:String;
						try {
							var strError:String = "";
							var nError:Number = StorageServiceError.None;
							nError = CheckFacebookObject("OnCreateSet", obResp, true);
							if (StorageServiceError.None != nError) {
								if (nTries < 2) {
									fnDoTheUpload();
								} else {
									fnComplete(StorageServiceError.IOError, strLog );
								}
							}
							
							var id:String = obResp.id;
							
							GetItemInfo( "", obResp.id, function( nErr:Number, strErr:String, item:ItemInfo=null): void {
									var fnOnCommitRenderHistory:Function = function (err:Number, strError:String): void {
										fnComplete(StorageServiceError.None, null, item);
									}
									
									if (AccountMgr.GetInstance().isGuest)
										fnComplete(StorageServiceError.None, null, item);
									else						
										PicnikService.CommitRenderHistory(dResponseInfo.strPikId, StorageServiceUtil.GetLastingItemInfo(itemInfo),
												GetServiceInfo().id, fnOnCommitRenderHistory);
								}, null );
						} catch (err:Error) {
							strLog = "Client exception: FacebookStorageService.CreateItem ";
							PicnikService.LogException(strLog, err, null, obResp ? "" : "(obResp is null)");
							fnComplete(StorageServiceError.Unknown, null);
						}				
		
					}, irsd);
				}
			fnDoTheUpload();
		}

		public function CreateGallery(strSetId:String, gald:GalleryDocument, fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
			Debug.Assert(false, "FacebookStorageService.CreateGallery not implemented");
		}

		public function NotifyOfAction(strAction:String, imgd:ImageDocument, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void {				
			try {
				if (itemInfo && (strAction == "ShareItem")) {
					
					// pop up the Facebook sharing popup
					// http://www.facebook.com/sharer.php?u=<url to share>&t=<title of content>
					
					var strUrl:String = "http://www.facebook.com/sharer.php?u=" + encodeURIComponent(itemInfo.webpageurl);
					
					if (itemInfo.title & itemInfo.title.length) {
						strUrl += "&t=" + encodeURIComponent(itemInfo.title);
					}
					
					PicnikBase.app.NavigateToURLInPopup(strUrl, 600, 300);
				}
				
//					var aTargets:Array = [];
//					if (_adctFriendInfoCache && imgd) {
//						for each (var oTag:Object in imgd.properties.smarttags) {
//							for (var j:Number = 0; j < _adctFriendInfoCache.length; j++) {
//								if (oTag.subject == _adctFriendInfoCache[j].uid) {
//									// this subject is one of the user's friends. Target!
//									aTargets.push( oTag.subject );
//								}
//							}
//						}
//					}
//	
//					var oAttachment:Object = {
//							name: itemInfo.title.length ? itemInfo.title : null,
//							href: itemInfo.webpageurl,
//							description: itemInfo.description,
//							media: [{
//								type: 'image',
//								src: itemInfo.thumbnailurl,
//								href: itemInfo.webpageurl
//							}]
//						};
//						
//					var strMessage:String = (strAction == "ShareItem") ?
//												'shared a photo from Picnik.' :
//												'just Picniked a photo.';
//					if ('shareHeadline' in itemInfo) {
//						strMessage = itemInfo.shareHeadline;
//					}
//												
//					var oPublishArgs:Object = {
//							message: strMessage,
//							attachment: JSON.encode(oAttachment),
//							action_links: JSON.encode([ { text: 'Visit Picnik', href: 'http://apps.facebook.com/picnik/' } ])
//						};
//					
//					_fbp.stream_publish( oPublishArgs, function (xml:XML, obContext:Object=null): void {
//							fnComplete(StorageServiceError.None, null, itemInfo);
//						} );						
//				}

				fnComplete(StorageServiceError.None, null, itemInfo);

			} catch (err:Error) {
				var strLog:String = "Client exception: FacebookStorageService.NotifyOfAction: ";
				strLog += _strUserId + "/" + _strAuth;
				PicnikService.LogException(strLog, err);
			}				
				
		}

		// Returns a dictionary filled with information about the item.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - title (opt)
		// - description (opt)
		// - tags (opt)
		// - webpageurl (opt)
		// - id (req)
		// - setid (opt)
		// - width (opt)
		// - height (opt)
		// - size (opt) -- in bytes
		// - sourceurl (req)
		// - thumbnailurl (opt)
		// - createddate (opt)
		// - last_update (opt)
		//
		// fnComplete(err:Number, strError:String, itemInfo:ItemInfo=null)
		// - None
		// - IOError
		// - NotLoggedIn
		// - ItemNotFound
		//
		// fnProgress(nPercent:Number)

		public function GetItemInfo(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void {
			_fbp.CallGraph( "/" + strItemId , {}, OnGetItemInfo, { fnComplete: fnComplete, fnProgress: fnProgress, strItemId: strItemId, strSetId:strSetId });
		}
		
		private function OnGetItemInfo(obResp:Object, obContext:Object=null): void {
			try {
				
				var fnComplete:Function = obContext.fnComplete;
				var fnProgress:Function = obContext.fnProgress;
				var strItemId:String = obContext.strItemId;
				var strError:String = "";
				var nError:Number = StorageServiceError.None;
				nError = CheckFacebookObject("OnGetItemInfo", obResp, true);
				if (StorageServiceError.None != nError) {
					var strErr:String = Resource.getString("FacebookStorageService", "no_photo_info");
					fnComplete(nError, strErr);
					return;					
				}
				
				var itemInfo:ItemInfo = ItemInfoFromPhoto(obResp);
				itemInfo.setid = obContext.strSetId;
				fnComplete(StorageServiceError.None, null, itemInfo);

			} catch (err:Error) {
				var strLog:String = "Client exception: FacebookStorageService.OnGetItemInfo: ";
				strLog += _strUserId + "/" + _strAuth;
				PicnikService.LogException(strLog, err, null, (obResp ? "": "(obResp is null)"));
				fnComplete(StorageServiceError.Unknown, null);
			}				
		}

		public function GetItemInfos(apartialItemInfos:Array, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "FacebookStorageService.GetItemInfos not implemented");
		}
				

		// Updates item info
		// Currently support 'title' only
		public function SetItemInfo(strSetId:String, strItemId:String, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "FacebookStorageService.SetItemInfo not implemented");
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
		
		public function GetItems(strSetId:String, strSort:String, strFilter:String, nStart:Number, nCount:Number, fnComplete:Function, fnProgress:Function=null): void {
			try {
				var userid:String = null;
				if (nStart == 0 || _adctItemInfoCache == null) {
					if (strSetId.indexOf( kstrPhotosOfYouSetId ) == 0 ) {
						userid = strSetId.substr( kstrPhotosOfYouSetId.length + 1 );
						_fbp.CallGraph("/"+userid+"/photos", {format:"json",limit:1000,offset:0}, OnGetItems,
							{ fnComplete: fnComplete, fnProgress: fnProgress, strSetId: strSetId, nCount: nCount, sortBy: 'createddate', sortDescending:true });
						
					} else {
						_fbp.CallGraph("/"+strSetId+"/photos",{format:"json",limit:1000,offset:0}, OnGetItems,
							{ fnComplete: fnComplete, fnProgress: fnProgress, strSetId: strSetId, nCount: nCount, sortBy: 'createddate', sortDescending:true });
					}
				} else {
					PicnikBase.app.callLater(fnComplete, [ StorageServiceError.None, null, _adctItemInfoCache.slice(nStart, nStart + nCount) ]);
				}
			} catch (err:Error) {
				var strLog:String = "Client exception: FacebookStorageService.GetItems: ";
				strLog += _strUserId + "/" + _strAuth;
				PicnikService.LogException(strLog, err);
			}		
		}
		
		// ProcessServiceParams
		// does storage-service-specific processing of parameters that were given to us
		// via the an invocation of Picnik As Service.
		// see IStorageService::ProcessServiceParams comments
		public function ProcessServiceParams(dctParams:Object, fnComplete:Function, fnProgress:Function=null):void {			
			try {
				// store a local var with "this" that it'll be available within the callbacks below
				var ssThis:IStorageService = this;
				// first, we must log in!
				if( !IsLoggedIn() ) {
					var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount("Facebook");
					this.LogIn( tpa,
						function( err:Number, strError:String ): void {					
							if (err == StorageServiceError.None) {
								// login was successful -- invoke ProcessServiceParams again
								// UNDONE: add something to dctParams to prevent infinite loopage
								ProcessServiceParams( dctParams, fnComplete, fnProgress );
							} else {
								// We weren't able to login, so redirect to the facebook authorize page
								tpa.SetToken( "", true )
								ssThis.Authorize();
								return;
							}
						});
					return;
				}
							
				// we are properly authorized, so process the command							
				if ((typeof(dctParams._ss_cmd) != undefined) && (dctParams._ss_cmd)) {
				   
				    var strUid:String = null;
				    if (typeof( dctParams._ss_user_id ) != undefined) {
				    	strUid = dctParams._ss_user_id;
				    }
				    var strPid:String = null;
				    if (typeof( dctParams._ss_item_id ) != undefined) {
				    	strPid = dctParams._ss_item_id;
				    }
				    var strAid:String = null;
				    if (typeof( dctParams._ss_set_id ) != undefined) {
				    	strAid = dctParams._ss_set_id;
				    }		
				}				
			} catch (err:Error) {
				var strLog:String = "Client exception: FacebookStorageService.ProcessServiceParams: ";
				strLog += _strUserId + "/" + _strAuth;
				PicnikService.LogException(strLog, err);
			}
			fnComplete(StorageServiceError.None, null, {} );																
			return;
		}
		
		private function OnGetItems(obResp:Object, obContext:Object=null): void {
			try {
				var strError:String = "";
				var nError:Number = StorageServiceError.None;
				var fnComplete:Function = obContext.fnComplete;
				nError = CheckFacebookObject("OnGetAlbums", obResp, true);
				if (StorageServiceError.None != nError) {
					var strErr:String = Resource.getString("FacebookStorageService", "no_photo_list");
					fnComplete(nError, strErr);
					return;					
				}
				
				var aitemInfos:Array = [];
				for each (var obPhoto:Object in obResp.data) {
					var itemInfo:ItemInfo = ItemInfoFromPhoto(obPhoto);
					if ('strSetId' in obContext) {
						itemInfo.setid = obContext.strSetId;
					}
					aitemInfos.push(itemInfo);
				}
				
				if ('sortBy' in obContext) {
					var nOrder:int = 1;
					if ('sortDescending' in obContext && obContext['sortDescending']) {
						nOrder = -1;
					}
					aitemInfos.sort( function(a:Object,b:Object):Number { return( a[obContext['sortBy']] < b[obContext['sortBy']] ? -1*nOrder : a[obContext['sortBy']] == b[obContext['sortBy']] ? 0 : 1*nOrder ); } );
						
				}
				
				_adctItemInfoCache = aitemInfos;
				fnComplete(StorageServiceError.None, null, aitemInfos.slice(0, obContext.nCount));
			} catch (err:Error) {
				var strLog:String = "Client exception: FacebookStorageService.OnGetItems: ";
				strLog += "/" + _strUserId + "/" + _strAuth;
				PicnikService.LogException(strLog, err, null, (obResp ? "" : "(obResp is null)"));
				fnComplete(StorageServiceError.Unknown, Resource.getString("FacebookStorageService", "no_items_exception"));
			}

		}
		
		
		private function ItemInfoFromPhoto(ph:Object): ItemInfo {
			var itemInfo:ItemInfo = new ItemInfo( {
				id: ph.id,
				serviceid: "Facebook",
				overwriteable: false
			} );
				
			if ('from' in ph && ph.from && 'id' in ph.from) {
				itemInfo['ownerid'] = ph.from.id;
			}
			if ('name' in ph) {
				itemInfo['title'] = ph.name;
			}
			if ('link' in ph) {
				itemInfo['webpageurl'] = ph.link;
			}
			if ('source' in ph) {
				itemInfo['sourceurl'] = ph.source;
				itemInfo['thumbnailurl'] = ph.source;
			}
			if ('created_time' in ph) {
				itemInfo['createddate'] = ph.created_time;
			}
			
			// new FB doesn't support overwriting photos...?
//			if (_strUserId == itemInfo.ownerid)
//				itemInfo.overwriteable = true;
			
			return itemInfo;
		}		

		
		private function CheckFacebookObject(strFunc:String, obj:Object, fLog:Boolean=true):Number {		
			var nError:Number = StorageServiceError.None;
			if (!obj || "error" in obj) {
				nError = StorageServiceError.IOError;
				if (fLog) {
					var strError:String = "Facebook SS err: " + strFunc + ":";
					if (obj) strError += String(obj['error']['message']);
					LogFacebookObject(strError, obj);
				}
			}
			return nError;
		}		

	
		private function LogFacebookObject(strPrologue:String, obj:Object):void {		
			var strError:String = strPrologue + "/";
			if (!obj) strError += "(obj is null)";			
			PicnikService.Log(strError, PicnikService.knLogSeverityDebug);
		}				
		
		
		// Returns a dictionary filled with information about the logged in user.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - uid (req)
		// - name (opt)
		// - picurl (opt)
		//
		// fnComplete(err:Number, strError:String, dctUserInfo:Object=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)

		public function GetFriends(fnComplete:Function, fnProgress:Function=null): void {
			_fbp.CallGraph("/" + _strUserId + "/friends", {}, OnGetFriends, { fnComplete: fnComplete, fnProgress: fnProgress });
		}
		
		private function OnGetFriends(obResp:Object, obContext:Object=null): void {
			try {
				var fnComplete:Function = obContext.fnComplete;
				
				var nError:Number = CheckFacebookObject("OnGetFriends", obResp, true);
				if (StorageServiceError.None != nError) {
					var strErr:String = Resource.getString("FacebookStorageService", "no_friends");
					fnComplete(nError, strErr);
					return;					
				}
				
				var adctFriendsInfo:Array = [];
	
				for each (var ob:Object in obResp.data) {
					var dctFriendInfo:Object = {
						uid: ob.id,
						name: ob.name,
						picurl: _fbp.GetGraphUrl("/" + ob.id + "/picture")
					};
					
					adctFriendsInfo.push(dctFriendInfo);					
				}
				adctFriendsInfo.sort( function(a:Object,b:Object):Number { return( a['name'] < b['name'] ? -1 : a['name'] > b['name'] ? 1 : 0 ); } );
				
				fnComplete(StorageServiceError.None, null, adctFriendsInfo);
			} catch (err:Error) {
				var strLog2:String = "Client exception: FacebookStorageService.OnGetFriends: ";
				strLog2 += _strUserId + "/" + _strAuth;
				PicnikService.LogException(strLog2, err, null, (obResp ? "" : "(obResp is null)"));
				fnComplete(StorageServiceError.Unknown, Resource.getString("FacebookStorageService", "no_friends_exception") );
			}
		}
		
		// See IStorageService.GetResourceURL for this method's documentation		
		public function GetResourceURL(strResourceId:String): String {
			Debug.Assert(false, "FacebookStorageService.GetResourceURL not implemented");
			return null;
		}
		
		// See IStorageService.WouldLikeAuth for this method's documentation		
		public function WouldLikeAuth(): Boolean {
			return false;
		}
	}
}
