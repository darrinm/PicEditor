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

package bridges.picasaweb {
	import bridges.*;
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceRegistry;
	import bridges.storageservice.StorageServiceUtil;
	
	import dialogs.DialogManager;
	
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	
	import imagine.ImageDocument;
	
	import mx.utils.StringUtil;
	import mx.utils.URLUtil;
	
	import util.DynamicLocalConnection;
	import util.IRenderStatusDisplay;
	import util.RenderHelper;
	
	public class PicasaWebStorageService implements IStorageService {
		private const gphoto:Namespace = new Namespace("gphoto", "http://schemas.google.com/photos/2007");
		private const media:Namespace = new Namespace("media", "http://search.yahoo.com/mrss/");
		
		private var _strAuth:String;

		private var _fnComplete:Function = null;
		private var _lconPicasawebSuccess:DynamicLocalConnection = null;
		private var _fLconPicasawebSuccessConnected:Boolean = false;
		
		public function toString(): String {
			return "[PicasaWebStorageService: " + _strAuth + ", " + useGoogleToken + "]";
		}
		
		public function GetServiceInfo(): Object {
			return StorageServiceRegistry.GetStorageServiceInfo("picasaweb");
		}
		
		// strEndPoint looks like this: /data/entry/api/...
		private function GetGDataUrl(strEndpoint:String): String {
			var strBase:String = "http://";
			strBase += "picasaweb.google.com";
			return strBase + strEndpoint;
		}
		
		public function Authorize(strPerm:String=null, fnComplete:Function=null): Boolean {
			if (useGoogleToken) {
				return true;
			}
			// These domains are pre-registered for secure use. All others are not.
			var strSecure:String = "0";
			switch (URLUtil.getServerNameWithPort(PicnikService.serverURL).toLowerCase()) {
			case "www.mywebsite.com":
			//case "local.mywebsite.com": // UNDONE: registration borked? can't use in conjunction w/ secure=1
			case "test.mywebsite.com":
				strSecure = "1";
				break;
			}

			var strUrl:String = "https://www.google.com/accounts/AuthSubRequest?next=" +
					PicnikService.serverURL + "/callback/picasaweb" +
					"&scope=http://picasaweb.google.com/data/&secure=" + strSecure + "&session=1";

			var fnPopupOpen:Function = function(err:int, errMsg:String, ob:Object): void {
				// listen for new user properties
				var strSuccessMethod:String = "successMethod";
				var strConnectionName:String = "picasawebAuth";
			
				_lconPicasawebSuccess = new DynamicLocalConnection();
				_lconPicasawebSuccess.allowPicnikDomains();
				_lconPicasawebSuccess[strSuccessMethod] = function(strCBParams:String=null): void {
					// the popup succeeded!
					if (_fnComplete != null) {
						_fnComplete(0, "", strCBParams);
						_fnComplete = null;
					}
					try {
						_lconPicasawebSuccess.close();
					} catch (e:Error) {
						//
					}
					_fLconPicasawebSuccessConnected = false;
					_lconPicasawebSuccess = null;
					
					DialogManager.HideBlockedPopupDialog();
				};
				
				if (!_fLconPicasawebSuccessConnected) {
					try {
						_lconPicasawebSuccess.connect(strConnectionName);
					} catch (e:Error) { /*NOP*/ }
					_fLconPicasawebSuccessConnected = true;
				}
			}

			_fnComplete = fnComplete;
			PicnikBase.app.NavigateToURLInPopup(strUrl, 775, 800, fnPopupOpen);
			return true;
		}
		
		public function HandleAuthCallback(obParams:Object, fnComplete:Function): void {
		}
		
		public function IsLoggedIn(): Boolean {
			return useGoogleToken || (_strAuth != null);
		}
		
		private function get useGoogleToken(): Boolean {
			return AccountMgr.GetInstance().hasGoogleCredentials;
		}
		
		// Log the user in. No assumptions are to be made regarding how long the session lasts.
		// UNDONE: CAPTCHA
		//
		// fnComplete(err:Number, strError:String)
		// - None
		// - IOError
		// - InvalidUserOrPassword
		//
		// fnProgress(nPercent:Number)
		
		public function LogIn(tpa:ThirdPartyAccount, fnComplete:Function, fnProgress:Function=null): void {
			if (useGoogleToken) {
				_strAuth = null;
				// UNDONE: Validate google token
				PicnikBase.app.callLater(fnComplete, [0, null]);
				return;
			}
			try {
				// Validate the token
				var urlr:URLRequest = new URLRequest("https://www.google.com/accounts/AuthSubTokenInfo");
				var obProxyParams:Object = AddAuthenticationHeader(urlr, tpa.GetToken());
				var fnOnLogIn:Function = function (urlr:ProxyURLLoader, err:Number, strError:String): void {
					try {
						if (err == 0) {
							var strError:String = GetRegExpMatch(urlr.data, /^Error=(\S*)/m);
							if (strError) {
								fnComplete(StorageServiceError.LoginFailed, strError);
								return;
							}
							// Make sure we get back a happy response
							var strTarget:String = GetRegExpMatch(urlr.data, /^Target=(\S*)/m);
							if (strTarget) {
								_strAuth = tpa.GetToken();
								fnComplete(0, null);
							} else {
								fnComplete(StorageServiceError.LoginFailed, "Failed login");
							}
						} else {
							fnComplete(err, strError);
						}
					} catch (e:Error) {
						PicnikService.Log("Client Exception: in PicasaWebStorageService.OnLogIn: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityError);
						throw e;
					}
				}
				
				var urll:ProxyURLLoader = new ProxyURLLoader(urlr, null, fnOnLogIn, null, null, obProxyParams);
			} catch (e:Error) {
				PicnikService.Log("Client Exception: in PicasaWebStorageService.LogIn: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityError);
				throw e;
			}
		}
		
		public static function GetRegExpMatch(str:String, re:RegExp): String {
			var astrMatch:Array = re.exec(str);
			if (astrMatch)
				return astrMatch[1];
			return null;
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
			var urlr:URLRequest = new URLRequest(GetGDataUrl("/data/entry/api/user/default"));
			var obProxyParams:Object = AddAuthenticationHeader(urlr);
			var fnOnGetUserInfo:Function = function (urlr:ProxyURLLoader, err:Number, strError:String): void {
				if (!urlr.data) {
					fnComplete(StorageServiceError.IOError, "Unable to retrieve user information");
					return;
				}
				
				default xml namespace = new Namespace("http://www.w3.org/2005/Atom");
				var xml:XML;
				try {
					xml = new XML(urlr.data);	
				} catch (err:Error) {
					fnComplete(StorageServiceError.InvalidServiceResponse, "invalid user info XML");
					return;
				}
				var dctUserInfo:Object = {
					username: String(xml.gphoto::user),
					fullname: String(xml.gphoto::nickname),
					thumbnailurl: String(xml.gphoto::thumbnail),
					webpageurl: String(xml.link.(@rel=="alternate").@href)
				}
				fnComplete(StorageServiceError.None, null, dctUserInfo);
			}
			
			var urll:ProxyURLLoader = new ProxyURLLoader(urlr, null, fnOnGetUserInfo, null, null, obProxyParams);
		}
		
		public function SetUserInfo(dctUserInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "PicasaWebStorageService.SetUserInfo not implemented");
		}
		
		// Returns a dictionary filled with information about the service's item store.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - itemcount (opt)
		// - setcount (opt)
		// - overwriteable (opt)
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
				if (err != StorageServiceError.None) {
					fnComplete(err, strError);
					return;
				}
				
				var cItems:Number = 0;
				for each (var dctSetInfo:Object in adctSetInfos)
				if (dctSetInfo.itemcount)
					cItems += dctSetInfo.itemcount;
				fnComplete(StorageServiceError.None, null, { itemcount: cItems, setcount: adctSetInfos.length });
			}
			
			GetSets( null, fnOnGetStoreInfoGetSets);
		}
		
		public function SetStoreInfo(dctStoreInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "PicasaWebStorageService.SetStoreInfo not implemented");
		}
		
		// Returns an array of dictionaries filled with information about the sets.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - id (req)
		// - itemcount (req)
		// - title (opt)
		// - thumbnailurl (opt)
		//
		// fnComplete(err:Number, strError:String, adctSetInfo:Array=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		//
		// strUsername is currently ignored
		
		public function GetSets( strUsername:String, fnComplete:Function, fnProgress:Function=null): void {
			var urlr:URLRequest = new URLRequest(GetGDataUrl("/data/feed/api/user/default?kind=album"));
			var obProxyParams:Object = AddAuthenticationHeader(urlr);
			var fnOnGetSets:Function = function (urlr:ProxyURLLoader, err:Number, strError:String): void {
				if (!urlr.data) {
					fnComplete(StorageServiceError.IOError, "Unable to retrieve album information");
					return;
				}
				
				default xml namespace = new Namespace("http://www.w3.org/2005/Atom");
				
				var xml:XML;
				try {
					xml = new XML(urlr.data);	
				} catch (err:Error) {
					fnComplete(StorageServiceError.InvalidServiceResponse, "invalid sets info XML");
					return;
				}
				var adctSetInfos:Array = [];
				for each (var xmlEntry:XML in xml.entry) {
					var dctSetInfo:Object = {
						title: String(xmlEntry.title),
						itemcount: Number(xmlEntry.gphoto::numphotos),
						thumbnailurl: String(xmlEntry.media::group[0].media::thumbnail.@url),
						id: String(xmlEntry.gphoto::id),
						overwriteable: true,
						webpageurl: String(xmlEntry.link.(@rel=="alternate").@href)
					}
					adctSetInfos.push(dctSetInfo);
				}
				fnComplete(StorageServiceError.None, null, adctSetInfos);
			}
			

			var urll:ProxyURLLoader = new ProxyURLLoader(urlr, null, fnOnGetSets, null, null, obProxyParams);
		}
		
		public function CreateSet(dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			// first we need to call getuserinfo to retrieve the username
			GetUserInfo( function(err:Number, strError:String, dctUserInfo:Object): void {
					if (err != StorageServiceError.None) {
						fnComplete( err, strError );
						return;
					}
					var strAccess:String = ('fPrivate' in dctSetInfo && dctSetInfo.fPrivate == true) ? 'private' : 'public';
					
					var urlr:URLRequest = new URLRequest(GetGDataUrl("/data/feed/api/user/" + dctUserInfo.username));
					var xml:XML =
						<entry xmlns='http://www.w3.org/2005/Atom' xmlns:media='http://search.yahoo.com/mrss/' xmlns:gphoto='http://schemas.google.com/photos/2007'>
							<gphoto:location></gphoto:location>
							<gphoto:access>{strAccess}</gphoto:access>
							<gphoto:commentingEnabled>true</gphoto:commentingEnabled>
							<gphoto:timestamp></gphoto:timestamp>
							<media:group>
								<media:keywords></media:keywords>
							</media:group>
							<category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/photos/2007#album'></category>							
						</entry>
					
					xml.appendChild( XML(<title type='text'>{dctSetInfo.title}</title>) );
					if (dctSetInfo.description)
						xml.appendChild( XML(<summary type='text'>{dctSetInfo.description}</summary>) );			
					// UNDONE: Not yet supported.
					//if ('streamid' in dctSetInfo)
					//	xml.appendChild( XML(<gphoto:streamid>{dctSetInfo.streamid}</gphoto:streamid>) );
					urlr.data = xml;
					urlr.contentType = "application/atom+xml";
					var obProxyParams:Object = AddAuthenticationHeader(urlr);
					
					// urlr.requestHeaders.push(new URLRequestHeader("Content-type", urlr.contentType));
					urlr.requestHeaders.push(new URLRequestHeader("MIME-Version", "1.0"));
					urlr.method = URLRequestMethod.POST;
					
					var fnOnCreateSet:Function = function (urlr:ProxyURLLoader, err:Number, strError:String): void {
						if (err != StorageServiceError.None) {
							fnComplete( err, strError );				
							return;
						}
						var xml:XML = XML(urlr.data);
						if (!xml || "" == String(xml.gphoto::id)) {
							fnComplete( StorageServiceError.Unknown, urlr.data );				
							return;
						}
						
						var dctSetInfo:Object = {
							title: String(xml.title),
							itemcount: Number(xml.gphoto::numphotos),
							thumbnailurl: String(xml.media::group[0].media::thumbnail.@url),
							id: String(xml.gphoto::id),
							overwriteable: true
						}			
						
						fnComplete( err, strError, dctSetInfo );							
					}
					
					var urll:ProxyURLLoader = new ProxyURLLoader(urlr, null, fnOnCreateSet, null, "POST", obProxyParams);					
								
				} );
		}
		
		public function DeleteSet(strSetId:String, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "PicasaWebStorageService.DeleteSet not implemented");
		}
		
		public function GetSetInfo(strSetId:String, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "PicasaWebStorageService.GetSetInfo not implemented");
		}
		
		public function SetSetInfo(strSetId:String, dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "PicasaWebStorageService.SetSetInfo not implemented");
		}
		
		public function NotifyOfAction(strAction:String, imgd:ImageDocument, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "PicasaWebStorageService.NotifyOfAction not implemented");
		}
		
		public function ProcessServiceParams(dctParams:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "PicasaWebStorageService.ProcessServiceParams not implemented");
			fnComplete(StorageServiceError.None, null, {} );																
		}
		
		public function GetItemInfos(apartialItemInfos:Array, fnComplete:Function, fnProgress:Function=null): void {			
			Debug.Assert(false, "PicasaWebStorageService.GetItemInfos not implemented");
		}
		
		
		
		public function DeleteItem(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void {
			// First, get item info
			var fnOnGetItemInfoForDelete:Function = function (err:Number, strError:String, obContext:Object, xml:XML=null): void {
				if (err != StorageServiceError.None || !xml) {
					fnComplete(err, "Unable to retrieve photo info for delete");
					return;
				}
				
				var xmllEdit:XMLList = xml.link.(@rel=="edit");
				if (xmllEdit.length() < 1) {
					fnComplete(StorageServiceError.IOError, "Unable to retrieve photo info for delete[2]");
					return;
				}
				// Now we have our item info.
				var strDeleteURL:String = xmllEdit[0].@href;
				
				// Really, we should do the delete
				var urlr:URLRequest = new URLRequest(strDeleteURL);
				var obProxyParams:Object = AddAuthenticationHeader(urlr);
				urlr.method = URLRequestMethod.POST;	//since we're doing a DELETE, we need to POST to our proxy
				
				var fnOnDelete:Function = function (urlr:ProxyURLLoader, err:Number, strError:String): void {
					if (err != ProxyURLLoader.kerrNone) {
						fnComplete(StorageServiceError.IOError, "Unable to delete photo: " + strError);
						return;
					}
					fnComplete(StorageServiceError.None, null);
				}
				
				var urll:ProxyURLLoader = new ProxyURLLoader(urlr, null, fnOnDelete, null, "DELETE", obProxyParams);
			}
			
			GetItemInfoXml(strSetId, strItemId, null, fnOnGetItemInfoForDelete);
		}

		// Creates a new item and returns a dictionary with details about it. CreateItem is highly
		// service dependent. In an extreme case, the service may ignore any or all of the SetId,
		// ItemId, ItemInfo, and imgd parameters and return an empty ItemInfo.
		// The passed in ItemInfo may contain
		// - title (opt)
		// - description (opt)
		// - tags (opt)
		// - setid (opt)
		// - itemid (opt) -- if present CreateItem will overwrite the existing item
		//
		// The returned ItemInfo may contain
		// - itemid (req)
		//
		// fnComplete(err:Number, strError:String, itemInfo:ItemInfo=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		
		public function CreateItem(strSetId:String, strItemId:String, itemInfo:ItemInfo, imgd:ImageDocument,
				fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
				
			var ss:IStorageService = this;
				
			var fnSaveToPicasaWeb:Function = function (dctExistingItemInfo:Object=null): void {
				var strOverwriteUrl:String = dctExistingItemInfo ? dctExistingItemInfo.editmediaurl : null;

				var fnOnRender:Function = function (fnDone:Function, obResult:Object): void {
					if (AccountMgr.GetInstance().isGuest)
						fnDone(StorageServiceError.None, null, itemInfo);
					else
						StorageServiceUtil.CommitRenderHistory(ss, obResult, itemInfo, strSetId, fnDone, true);
				}
	
				var params:Object = {
					title: itemInfo.title,
					description: itemInfo.description, tags: PicasaWebizeTags(itemInfo.tags),
					dsturl: GetGDataUrl("/data/feed/api/user/default/albumid/" + strSetId)
				};
				if (useGoogleToken)
					params.authtoken = AccountMgr.GetInstance().GetUserAttribute('strGoogleToken');
				else
					params.authtoken = _strAuth;
				
				params.fIsGoogleToken = useGoogleToken ? 'True' : 'False';

				StorageServiceUtil.NullChildrenToEmptyString(params);
				
				if (strOverwriteUrl)
					params.dsturl = strOverwriteUrl;
				if (strSetId)
					params['setid'] = strSetId;
				if (strItemId)
					params['itemid'] = strItemId;
		
				new RenderHelper(imgd, fnComplete, irsd).CallMethod("saveimagetopicasaweb", params,fnOnRender);
			}
			
			if (strItemId) {
				GetItemInfo(strSetId, strItemId,
					function (err:Number, strError:String, dctExistingItemInfo:Object=null): void {
						if (err != StorageServiceError.None) {
							fnComplete(err, strError);
							return;
						}
						
						fnSaveToPicasaWeb(dctExistingItemInfo);
					});
				return;
			}
			
			fnSaveToPicasaWeb();
		}
		
		public function CreateGallery(strSetId:String, gald:GalleryDocument, fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
			Debug.Assert(false, "StorageServiceBase.CreateGallery not implemented");
		}
		
		//		
		public function GetItemInfo(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void {
			var fnOnGetItemInfo:Function = function (err:Number, strError:String, obContext:Object, xml:XML=null): void {
				if (err != StorageServiceError.None || !xml) {
					fnComplete(err, "Unable to retrieve photo info");
					return;
				}
				
				var itemInfo:ItemInfo = ItemInfoFromXmlEntry(xml);
				fnComplete(StorageServiceError.None, null, itemInfo);
			}
			
			GetItemInfoXml(strSetId, strItemId, { fnComplete: fnComplete, fnProgress: fnProgress }, fnOnGetItemInfo);
		}

		// On complete, calls fnCompleteXML(err:Number, strError:String, obContext:Object, xml:XML=null)
		private function GetItemInfoXml(strSetId:String, strItemId:String, obContext:Object, fnCompleteXML:Function): void {
			var urlr:URLRequest = new URLRequest(GetGDataUrl("/data/entry/api/user/default/albumid/" +
					strSetId + "/photoid/" + strItemId + "?imgmax=d" ));
			var obProxyParams:Object = AddAuthenticationHeader(urlr);
			var fnOnGetItemInfoXml:Function = function (urlr:ProxyURLLoader, err:Number, strError:String): void {
				if (!urlr.data) {
					fnCompleteXML(StorageServiceError.IOError, "Unable to retrieve photo info", obContext);
					return;
				}
				
				default xml namespace = new Namespace("http://www.w3.org/2005/Atom");
				
				var xml:XML;
				try {
					xml = new XML(urlr.data);	
				} catch (err:Error) {
					fnCompleteXML(StorageServiceError.InvalidServiceResponse, "invalid item info XML", obContext);
					return;
				}
				if (xml.children().length() == 0) {
					fnCompleteXML(StorageServiceError.IOError, "Unable to retrieve photo info: " + xml.toString(), obContext);
					return;
				}
				fnCompleteXML(StorageServiceError.None, null, obContext, xml);
			}

			var urll:ProxyURLLoader = new ProxyURLLoader(urlr, null, fnOnGetItemInfoXml, null, null, obProxyParams);
		}
		
		// Updates item info
		// Currently support 'title' only
		public function SetItemInfo(strSetId:String, strItemId:String, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void {
			var fnOnGetItemInfoForSetItemInfo:Function = function (err:Number, strError:String, obContext:Object, xml:XML=null): void {
				if (err != StorageServiceError.None || !xml) {
					fnComplete(err, "Unable to retrieve photo info for set item info [" + strError + "]");
					return;
				}
				
				var xmllEdit:XMLList = xml.link.(@rel=="edit");
				if (xmllEdit.length() < 1) {
					fnComplete(StorageServiceError.IOError, "Unable to retrieve photo info for set item info[2]");
					return;
				}
				// Now we have our item info.
				
				var strUpdateURL:String = CleanItemURI(xmllEdit[0].@href);
				xml.id = ChopAt(strUpdateURL, "/"); // Drop the trailing version.
				
				CopyItemInfoToXmlEntry(xml, itemInfo); // Update the item info
				
				var urlr:URLRequest = new URLRequest(strUpdateURL);
				var obProxyParams:Object = AddAuthenticationHeader(urlr);
				
				urlr.data = xml;
				urlr.contentType = "application/atom+xml";
				// urlr.requestHeaders.push(new URLRequestHeader("Content-type", urlr.contentType));
				urlr.requestHeaders.push(new URLRequestHeader("MIME-Version", "1.0"));
				urlr.method = URLRequestMethod.POST;
				
				var fnOnSetItemInfo:Function = function (urlr:ProxyURLLoader, err:Number, strError:String): void {
					if (err != ProxyURLLoader.kerrNone) {
						fnComplete(StorageServiceError.IOError, "Unable to set photo info: " + strError);
						return;
					}
					fnComplete(StorageServiceError.None, null);
				}
				
				var urll:ProxyURLLoader = new ProxyURLLoader(urlr, null, fnOnSetItemInfo, null, "PUT", obProxyParams);
			}
			
			GetItemInfoXml(strSetId, strItemId, null, fnOnGetItemInfoForSetItemInfo);
		}

		// look for strSearchFor in strItem (from the end) and cut everything at and after it.
		private function ChopAt(strIn:String, strSearchFor:String): String {
			var nBreakPos:Number = strIn.lastIndexOf(strSearchFor);
			if (nBreakPos >= 0) return strIn.substr(0, nBreakPos);
			else return strIn;
		}
		
		private function CleanItemURI(strItemURI:String): String {
			return ChopAt(strItemURI, "?authkey");
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
		//
		// fnComplete(err:Number, strError:String, adctItemInfo:Array=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		// UNDONE: standard sorts
		
		public function GetItems(strSetId:String, strSort:String, strFilter:String, nStart:Number, nCount:Number, fnComplete:Function, fnProgress:Function=null): void {
			var urlr:URLRequest = new URLRequest(GetGDataUrl("/data/feed/api/user/default/albumid/" +
					strSetId + "?start-index=" + (nStart + 1) + "&max-results=" + nCount + "&kind=photo&imgmax=d"));
			var obProxyParams:Object = AddAuthenticationHeader(urlr);
			var fnOnGetItems:Function = function (urlr:ProxyURLLoader, err:Number, strError:String): void {
				if (!urlr.data) {
					fnComplete(StorageServiceError.IOError, "Unable to retrieve photo list");
					return;
				}
				
				default xml namespace = new Namespace("http://www.w3.org/2005/Atom");
				
				var xml:XML;
				try {
					xml = new XML(urlr.data);	
				} catch (err:Error) {
					fnComplete(StorageServiceError.InvalidServiceResponse, "invalid items info XML");
					return;
				}
				var aitemInfos:Array = [];
				for each (var xmlEntry:XML in xml.entry) {
					var itemInfo:ItemInfo = ItemInfoFromXmlEntry(xmlEntry);
					aitemInfos.push(itemInfo);
				}
				
				fnComplete(StorageServiceError.None, null, aitemInfos);
			}
			

			var urll:ProxyURLLoader = new ProxyURLLoader(urlr, null, fnOnGetItems, null, null, obProxyParams);
		}
		
		private function CopyItemInfoToXmlEntry(xmlEntry:XML, itemInfo:ItemInfo): void {
			if ("title" in itemInfo) {
				// Set the summary
				xmlEntry.summary.setChildren(itemInfo.title);
				xmlEntry.media::group[0].media::description.setChildren(itemInfo.title);
			}
			if ("tags" in itemInfo)
				xmlEntry.media::group[0].media::tags.setChildren(PicasaWebizeTags(itemInfo.tags));
				
			// UNDONE: Set other things, such as height, width, size. Set ItemInfoFromXmlEntry
		}
		
		private function ItemInfoFromXmlEntry(xmlEntry:XML): ItemInfo {
			var itemInfo:ItemInfo = new ItemInfo( {
				title: String(xmlEntry.summary),
				id: String(xmlEntry.gphoto::id),
				setid: String(xmlEntry.gphoto::albumid),
				serviceid: "PicasaWeb",
				width: Number(xmlEntry.gphoto::width),
				height: Number(xmlEntry.gphoto::height),
				size: Number(xmlEntry.gphoto::size),
				webpageurl: String(xmlEntry.link.(@rel=="alternate").@href),
				editurl: String(xmlEntry.link.(@rel=="edit").@href),
				editmediaurl: String(xmlEntry.link.(@rel=="edit-media").@href)
			} );
			
			if (xmlEntry.media::group.length() != 0) {
				if (itemInfo.title == "")
					 itemInfo.title = String(xmlEntry.media::group[0].media::description);
				itemInfo.description = String(xmlEntry.media::group[0].media::description);
				itemInfo.tags = CanonicalizeTags(String(xmlEntry.media::group[0].media::keywords));
				itemInfo.sourceurl = String(xmlEntry.media::group[0].media::content.(@medium=="image").@url);
				
				// UNDONE: we probably want to enumerate all the thumbnails and pick the one that is
				// closest to the size we like (240x240)
				itemInfo.thumbnailurl = String(xmlEntry.media::group[0].media::thumbnail[2].@url);
				itemInfo.overwriteable = true;
			}
			return itemInfo;
		}
		
		//
		// Helpers
		//
		
		private function AddAuthenticationHeader(urlr:URLRequest, strAuth:String=null): Object {
			
			if (!strAuth)
				strAuth = _strAuth;
				
//			commented out due to bug in flash -- when it gets fixed we can go back to the old way
//			NOTE: Won't work anyway unless Google adds <allow-http-request-headers-from "*"> (or *.mywebsite.com)
//			to their crossdomain.xml file.
//			See http://www.adobe.com/devnet/flashplayer/articles/flash_player9_security_update.html#policy_file
//
//			if (urlr.requestHeaders == null)
//				urlr.requestHeaders = new Array();
//			urlr.requestHeaders.push(new URLRequestHeader("Authorization", 'AuthSub token="' + strAuth + '"'));
			
			// we're temporarily passing the auth parameters as a query param
			// the server will extract the "headerhack" value and to the right thing.
			var strAuthHeader:String;
			if (useGoogleToken) {
				// Flash doesn't allow us to use the Cookie header. Our proxy converts OOB-Cookie into Cookie.
				urlr.requestHeaders = [new URLRequestHeader("OOB-Cookie", "PICNIK_SID=" + AccountMgr.GetInstance().GetUserAttribute('strGoogleToken'))];
				return {headerhack: 'X-XSRF-Same-Domain'};
			} else {
				return {headerhack: 'AuthSub token="' + strAuth + '"'};
			}
		}
		
		// The canonicalized tag format is: tag1 tag2 "tag3 with spaces" tag4
		// Deals with: "tag1,  tag2  ,  tag3 with spaces, tag4  "
		private function CanonicalizeTags(strPicasaWebTags:String): String {
			var astrTags:Array = strPicasaWebTags.split(",");
			for (var i:Number = 0; i < astrTags.length; i++) {
				var strTag:String = StringUtil.trim(astrTags[i]);
				if (strTag.indexOf(" ") != -1)
					strTag = '"' + strTag + '"';
				astrTags[i] = strTag;
			}
			return astrTags.join(" ");
		}
		
		// The Picasa Web tag format is: tag1, tag2, tag3 with spaces, tag4
		// Deals with: 'tag1  tag2  "tag3 with spaces "  tag4'
		private function PicasaWebizeTags(strCanonicalizedTags:String): String {
			if (!strCanonicalizedTags)
				return null;
				
			var astrTags:Array = strCanonicalizedTags.match(/ *([^"][^ ]+|".*")/g);
			for (var i:Number = 0; i < astrTags.length; i++) {
				var strTag:String = StringUtil.trim(astrTags[i]);
				if (strTag.charAt(0) == '"')
					strTag = StringUtil.trim(strTag.slice(1, -1));
				astrTags[i] = strTag;
			}
			return astrTags.join(", ");
		}
				
		public function GetFriends(fnComplete:Function, fnProgress:Function=null): void {
			fnComplete(StorageServiceError.Unknown, null, null);
		}
				
		// See IStorageService.GetResourceURL for this method's documentation		
		public function GetResourceURL(strResourceId:String): String {
			Debug.Assert(false, "PicasaWebStorageService.GetResourceURL not implemented");
			return null;
		}

		// See IStorageService.WouldLikeAuth for this method's documentation		
		public function WouldLikeAuth(): Boolean {
			return false;
		}
	}
}
