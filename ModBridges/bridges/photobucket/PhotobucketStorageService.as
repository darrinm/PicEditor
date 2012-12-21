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

package bridges.photobucket {
	import bridges.*;
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceRegistry;
	import bridges.storageservice.StorageServiceUtil;
	
	import dialogs.DialogManager;
	
	import flash.net.URLRequest;
	
	import imagine.ImageDocument;
	
	import util.DynamicLocalConnection;
	import util.IRenderStatusDisplay;
	import util.KeyVault;
	import util.RenderHelper;
	
	public class PhotobucketStorageService implements IStorageService {
		private var _strUsername:String; 	// username
		private var _strSessionKey:String; 	// session_key
		private var _strSCID:String;
		private var _pbp:PhotobucketProxy;

		private var _fnComplete:Function = null;
		private var _lconPhotobucket:DynamicLocalConnection = null;
		private var _fLconPhotobucketConnected:Boolean = false;
				
		
		// GetItems populates this cache when it is passed a nStart value of 0 and
		// pulls items from the cache for calls to GetItemInfo
	    private var _dctItemInfoCache:Object = {};
	
		public function PhotobucketStorageService() {
			_strSCID = KeyVault.GetInstance().photobucket.pub;
			_pbp = new PhotobucketProxy(_strSCID, KeyVault.GetInstance().photobucket.priv);
		}
		
		public function GetServiceInfo(): Object {
			return StorageServiceRegistry.GetStorageServiceInfo("photobucket");
		}
		
		public function Authorize(strPerm:String=null, fnComplete:Function=null): Boolean {

			var fnPopupOpen:Function = function(err:int, errMsg:String, ob:Object): void {
				// listen for new user properties

				_lconPhotobucket = new DynamicLocalConnection();
				_lconPhotobucket.allowPicnikDomains();
				_lconPhotobucket["successMethod"] = function(strCBParams:String=null): void {
					// the popup succeeded!
					if (_fnComplete != null) {
						_fnComplete(0, "", strCBParams);
						_fnComplete = null;
					}
					try {
						_lconPhotobucket.close();
					} catch (e:Error) {
						//
					}
					_fLconPhotobucketConnected = false;
					_lconPhotobucket = null;
					
					DialogManager.HideBlockedPopupDialog();
				};
				
				if (!_fLconPhotobucketConnected) {
					try {
						_lconPhotobucket.connect("photobucketAuth");
					} catch (e:Error) { /*NOP*/ }
					_fLconPhotobucketConnected = true;
				}
			}
			
			_fnComplete = fnComplete;
			PicnikBase.app.NavigateToURLInPopup("/photobucket/login", 775, 800, fnPopupOpen);
			return true;
		}		

		public function HandleAuthCallback(obParams:Object, fnComplete:Function): void {
		}
		
		public function IsLoggedIn(): Boolean {
			return _strSessionKey != null;
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
				_pbp.token = tpa.GetToken();
				_strUsername = tpa.GetUserId();
				_pbp.apiUrl = tpa.GetApiUrl();				
				
				GetUserInfo(function(err:Number, strError:String, dctUserInfo:Object=null): void {
					if (err != StorageServiceError.None) {
						// Clear these out so the StorageService remains pristine if the user
						// isn't logged in.
						_pbp.token = null;
						_strUsername = null;
					} else {
						_strSessionKey = tpa.GetToken();
					}
					fnComplete(err, strError);
				});
			} catch (err:Error) {
				var strLog:String = "Client exception: PhotobucketStorageService.LogIn " + err.toString()+ "/" + tpa.GetUserId() + "/" + tpa.GetToken() + "/" + err.getStackTrace();
				PicnikService.Log(strLog, PicnikService.knLogSeverityError);				
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
			_strSessionKey = null;
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
			_pbp.getuserinfo( {}, OnGetUserInfo, {fnComplete: fnComplete, fnProgress: fnProgress});
		}
		
		private function OnGetUserInfo(err:Number,strError:String, xml:XML, obContext:Object): void {
			var fnComplete:Function = obContext.fnComplete;
			if (err == StorageServiceError.None && xml) {
				try {
					var dctUserInfo:Object =  {
						username: String(xml.userinfo.username),
						fullname: String(xml.userinfo.username),
						webpageurl: String(xml.userinfo.album_url)
					}
					fnComplete(StorageServiceError.None, null, dctUserInfo);
					return;
				} catch (e:Error) {
					LogPhotobucketXML( "Photobucket Exception: OnGetUserInfo: " + e + ", " + e.getStackTrace(), xml );
				}
			}
			fnComplete(err, strError);
		}
		
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
			// Call GetSets and add up the # of photos/album to return { itemcount: <>, setcount: <> }
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
					var strLog:String = "Client exception: PhotobucketStorageService.OnGetStoreInfoGetSets: ";
					strLog += err.toString() + "/" + _strUsername + "/" + _strSessionKey;
					PicnikService.Log(strLog, PicnikService.knLogSeverityError);
					if (fnComplete!=null) fnComplete( StorageServiceError.Unknown, null );
				}							
			}
			
			GetSets( null, fnOnGetStoreInfoGetSets);
		}
		
		
		public function SetStoreInfo(dctStoreInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "PhotobucketStorageService.SetStoreInfo not implemented");
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
		
		public function GetSets( strUsername:String, fnComplete:Function, fnProgress:Function=null): void {
			try {
				// Get all the regular albums
				var strUsername:String = strUsername ? strUsername : _strUsername;
				_pbp.getuseralbum( {recurse: "true", media:"none"},
						OnGetSets, {fnComplete: fnComplete, fnProgress: fnProgress});
			} catch (err:Error) {
				var strLog:String = "Client exception: PhotobucketStorageService.GetSets: ";
				strLog += err.toString() + "/" + strUsername + "/" + _strSessionKey;
				PicnikService.Log(strLog, PicnikService.knLogSeverityError);
				fnComplete( StorageServiceError.Unknown, null );
			}							
		}
				
		private function OnGetSets(err:Number, strError:String, xml:XML, obContext:Object): void {
			var fnComplete:Function = obContext.fnComplete;
			if (err==StorageServiceError.None && xml) {
				try {
					fnComplete(StorageServiceError.None, null, _flattenAlbums(xml));	
					return;
				} catch (err:Error) {
					var strLog:String = "Client exception: PhotobucketStorageService.OnGetSets: ";
					strLog += _strUsername + "/" + _strSessionKey;
					if (xml) strLog += "/" + xml.toXMLString();
					else strLog += "(xml is null)";							
					PicnikService.LogException(strLog, err);
					err = StorageServiceError.Unknown;
				}
			}
			fnComplete(err,strError);
		}
		
		private function _flattenAlbums( xml:XML, strParent:String="" ):Array {
			var adctSetInfos:Array = [];					
			for each (var photoalbum:XML in xml.photoalbum) {
				var strTitle:String = String(photoalbum.@name).replace( /\//g, ' > ');
				var dctSetInfo:Object = {
					title: strTitle,
					itemcount: Number(photoalbum.@photo_count),
					setcount: Number(photoalbum.@subalbum_count),
					id: String(photoalbum.@name),
					child_sets: true
				};
				adctSetInfos.push(dctSetInfo);
				if (photoalbum.photoalbums) {
					adctSetInfos = adctSetInfos.concat(_flattenAlbums(XML(photoalbum.photoalbums), strTitle));
				}
			}
			return adctSetInfos;								
		}
		
		public function CreateSet(dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			var obParams:Object = {new_album_name: dctSetInfo.title};
			if (dctSetInfo.parent_id) {
				var strParent:String = dctSetInfo.parent_id;
				obParams.parent_album_name = strParent.substr( strParent.indexOf( "/" ) + 1 );				
			}
			_pbp.createalbum( obParams,
			 	function (err:Number,strError:String,xml:XML, obContext:Object): void {
					if (err != StorageServiceError.None || !xml ) {
						obContext.fnComplete(StorageServiceError.IOError, "There was a strange response from the Photobucket server. ");
						return;
					}
		
					var strId:String = "";
					if (dctSetInfo.parent_id)
						strId = dctSetInfo.parent_id;
					else
						strId = _strUsername;						
					strId += "/" + dctSetInfo.title;						
					
					var strTitle:String = strId.replace( /\//g, ' > ');
					var dctNewSetInfo:Object = {
						id: strId,
						title: strTitle,
						itemcount: 0,
						setcount: 0,
						child_sets: true
					};
		
					obContext.fnComplete(StorageServiceError.None, null, dctNewSetInfo);
				}, {fnComplete: fnComplete, fnProgress: fnProgress});					
		}
		
		public function DeleteSet(strSetId:String, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "PhotobucketStorageService.DeleteSet not implemented");
		}
		
		public function GetSetInfo(strSetId:String, fnComplete:Function, fnProgress:Function=null): void {			
			Debug.Assert(false, "PhotobucketStorageService.GetSetInfo not implemented");
		}
		
		public function SetSetInfo(strSetId:String, dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "PhotobucketStorageService.SetSetInfo not implemented");
		}
		
		public function DeleteItem(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "PhotobucketStorageService.DeleteItem not implemented");
		}
		
		public function NotifyOfAction( strAction:String, imgd:ImageDocument, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void {				
			fnComplete(StorageServiceError.None, null, null);		
		}
		
		public function GetItemInfos(apartialItemInfos:Array, fnComplete:Function, fnProgress:Function=null): void {			
			Debug.Assert(false, "PhotobucketStorageService.GetItemInfos not implemented");
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
			// Called on a successful save
			
			var ss:IStorageService = this;
			var fnOnRendered:Function = function (fnDone:Function, obResult:Object): void {
				if (AccountMgr.GetInstance().isGuest)
					fnDone(StorageServiceError.None, null, itemInfo);
				else
					StorageServiceUtil.CommitRenderHistory(ss, obResult, itemInfo, strSetId, fnDone, true);
			}

			if (!itemInfo.title || itemInfo.title.length == 0)
				itemInfo.title = " ";	// a space makes photobucket generate a filename

			var params:Object = {
				sessionkey: _pbp.token, apiurl: _pbp.apiUrl, title: itemInfo.title,
				description: itemInfo.description, albumname: strSetId
			}
			new RenderHelper(imgd, fnComplete, irsd).CallMethod("saveimagetophotobucket", params, fnOnRendered);
		}

		public function CreateGallery(strSetId:String, gald:GalleryDocument, fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
			Debug.Assert(false, "StorageServiceBase.CreateGallery not implemented");
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
			if (strItemId in _dctItemInfoCache) {
				fnComplete( StorageServiceError.None, null, _dctItemInfoCache[strItemId] );
			} else {
				_pbp.getuseralbum({album_name: ItemIdToAlbum(strItemId), recurse:"false", media:"photo"}, OnGetItemInfo,
						{ fnComplete: fnComplete, fnProgress: fnProgress, strItem:ItemIdToName(strItemId)});
			}
		}
		
		private function OnGetItemInfo(err:Number,strError:String,xml:XML, obContext:Object): void {
			var fnComplete:Function = obContext.fnComplete;
			try {
				if (StorageServiceError.None==err && xml) {
					var itemInfo:ItemInfo = null;
					for each (var xmlPhoto:XML in xml.photoalbum.photos.photo) {
						if (obContext.strItem == xmlPhoto.@name) {
							itemInfo = ItemInfoFromXmlPhoto(xmlPhoto, xml.photoalbum.@name);						
							break;
						}
					}
					if (itemInfo) {
						fnComplete(StorageServiceError.None, null, itemInfo);
						return;
					}
				}
				fnComplete(StorageServiceError.Unknown, null);
			} catch (err:Error) {
				var strLog:String = "Client exception: PhotobuckettorageService.OnGetItemInfo: "+_strUsername+"/"+_strSessionKey;
				PicnikService.LogException(strLog, err, null, (xml ? xml.toXMLString() : "(xml is null)"));
				fnComplete(StorageServiceError.Unknown, "Unable to retrieve items (client exception).");
			}
		}

		// Updates item info
		// Currently support 'title' only
		public function SetItemInfo(strSetId:String, strItemId:String, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "PhotobucketStorageService.SetItemInfo not implemented");
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
				
				if (nStart == 0 || _dctItemInfoCache == null) {
					_dctItemInfoCache = {};
				}
				var nPage:int = Math.floor(nStart/nCount)+1;
				_pbp.getuseralbumpaginated({album_name: strSetId, recurse:"false", media:"photo", page: nPage, perpage:nCount}, OnGetItems,
							{ fnComplete: fnComplete, fnProgress: fnProgress, nCount: nCount });
			} catch (err:Error) {
				var strLog:String = "Client exception: PhotobucketStorageService.GetItems: "+_strUsername+"/"+_strSessionKey;
				PicnikService.LogException(strLog, err);
			}												
		}
		
		private function OnGetItems(err:Number,strError:String,xml:XML, obContext:Object): void {
			var fnComplete:Function = obContext.fnComplete;
			try {
				if (StorageServiceError.None==err && xml) {
					var aitemInfos:Array = [];
					for each (var xmlPhoto:XML in xml.photoalbum.photos.photo) {
						var itemInfo:ItemInfo = ItemInfoFromXmlPhoto(xmlPhoto, xml.photoalbum.@name);
						aitemInfos.push(itemInfo);
						_dctItemInfoCache[itemInfo.id] = itemInfo;
					}				
					fnComplete(StorageServiceError.None, null, aitemInfos.slice(0, obContext.nCount));
					return;
				}
				fnComplete(StorageServiceError.Unknown, null);
			} catch (err:Error) {
				var strLog:String = "Client exception: PhotobuckettorageService.OnGetItems: "+_strUsername+"/"+_strSessionKey;
				PicnikService.LogException(strLog, err, null, (xml ? xml.toXMLString() : "(xml is null)"));
				fnComplete(StorageServiceError.Unknown, "Unable to retrieve items (client exception).");
			}
		}

		
		// ProcessServiceParams
		// does storage-service-specific processing of parameters that were given to us
		// via the an invocation of Picnik As Service.
		// see IStorageService::ProcessServiceParams comments
		public function ProcessServiceParams(dctParams:Object, fnComplete:Function, fnProgress:Function=null):void {
			fnComplete(StorageServiceError.None, null, {} );																
		}
		
		private function LogPhotobucketXML(strPrologue:String, xml:XML):void {		
			var strError:String = strPrologue + "/";
			if (xml) strError += xml.toXMLString();
			else strError += "(xml is null)";			
			PicnikService.Log(strError, PicnikService.knLogSeverityDebug);
		}		
		
		// Album == SetId
		private function AlbumAndNameToItemId(strAlbum:String, strName:String): String {
			return strAlbum.replace(/\//g, ':') + ':' + strName;
		}
		
		// Returns {'name':strName, 'album':strAlbum}
		private function ItemIdToAlbumAndName(strItemId:String): Object {
			var nLastSlash:Number = strItemId.lastIndexOf(":");
			var strAlbum:String = strItemId.substr(0, nLastSlash).replace(/\:/g, '/');
			var strItem:String = strItemId.substr(nLastSlash+1);
			return {'name':strItem, 'album':strAlbum};
		}

		private function ItemIdToAlbum(strItemId:String): String {
			return ItemIdToAlbumAndName(strItemId).album;
		}

		private function ItemIdToName(strItemId:String): String {
			return ItemIdToAlbumAndName(strItemId).name;
		}

		private function ItemInfoFromXmlPhoto(xmlPhoto:XML, strSetId:String): ItemInfo {
			var itemInfo:ItemInfo = new ItemInfo( {
				ownerid: String(xmlPhoto.@username),
				title: String(xmlPhoto.@name),
				webpageurl: String(xmlPhoto.browseurl),
				sourceurl: String(xmlPhoto.url),
				thumbnailurl: String(xmlPhoto.thumb),
				createddate: Number(xmlPhoto.uploaddate),
				id: AlbumAndNameToItemId(strSetId, xmlPhoto.@name),
				setid: strSetId,
				serviceid: "Photobucket"
				// UNDONE: tags?
			} );

			return itemInfo;
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
			fnComplete(StorageServiceError.None, null, null);
		}
		
		// See IStorageService.GetResourceURL for this method's documentation		
		public function GetResourceURL(strResourceId:String): String {
			Debug.Assert(false, "PhotobucketStorageService.GetResourceURL not implemented");
			return null;
		}
		
		// See IStorageService.WouldLikeAuth for this method's documentation		
		public function WouldLikeAuth(): Boolean {
			return false;
		}
	}
}
