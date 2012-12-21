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
package bridges.picnik {
	import bridges.*;
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceBase;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceRegistry;
	import bridges.storageservice.StorageServiceUtil;
	
	import flash.net.FileReference;
	import flash.utils.getTimer;
	
	import imagine.ImageDocument;
	
	import mx.core.Application;
	
	import util.AssetMgr;
	import util.IRenderStatusDisplay;
	import util.UploadManager;
	
	public class PicnikStorageService extends StorageServiceBase {
		static private var s_ss:PicnikStorageService;
		
		// GetItems populates this cache when it is passed a nStart value of 0 and
		// pulls items from the cache for nStart values > 0
		private var _afidRecentlyHidden:Array;
		private var _cmsItemInfoCacheTimestamp:int;
		
		private var _strTypes:String;	// types of items we're looking at ("history", "i_mycompute", "share")
		private var _strId:String;		// default id for the set of items we'll return
		private var _strTitle:String;	// default title for the set of items we'll return
		
		public var fileListLimit:Number = 1000; 					// Only show this many files
		public var storageLimit:Number = Number.POSITIVE_INFINITY; 	// If we have more than this many files, delete the rest
		
		public var forceListCache:Boolean = false; // When true, we will ue our cache for the next get list call

		private var _afnOnGetInfo:Array = [];
		
		static public function GetInstance(i:Number): PicnikStorageService {
			if (!s_ss)
				s_ss = new PicnikStorageService(null, "picnik", "Picnik");
			return s_ss;
		}
		
		// For history, these are:
		// 	history, history, History
		// For recent uploads, these become:
		// 	i_mycompute, uploads, Recent Uploads
		// For the Picnik save & share service, use:
		//	share, share, Share
		public function PicnikStorageService(strTypes:String, strId:String = null, strTitle:String = null) {
			_strTypes = strTypes;
			_strId = strId || strTypes;
			_strTitle = strTitle || strTypes;
		}
		
		override public function GetServiceInfo(): Object {
			return StorageServiceRegistry.GetStorageServiceInfo("picnik");
		}

		override public function Authorize(strPerm:String=null, fnComplete:Function=null): Boolean {
			return true;
		}
		
		override public function IsLoggedIn(): Boolean {
			return true;
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
			_aitemInfoCache = null;
			_cmsItemInfoCacheTimestamp = 0;
			
			var aargs:Array;
			if (AccountMgr.GetInstance().isGuest)
				aargs = [ StorageServiceError.InvalidUserOrPassword, "PicnikStorageService.LogIn: guest users have no history" ];
			else
				aargs = [ StorageServiceError.None, "" ];
				
			// callLater to preserve expected async semantics
			PicnikBase.app.callLater(fnComplete, aargs);
		}
		
		// Log the user out.
		//
		// fnComplete(err:Number, strError:String)
		// - None
		// - IOError
		// - NotLoggedIn
	
		// fnProgress(nPercent:Number)

		override public function LogOut(fnComplete:Function=null, fnProgress:Function=null): void {
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
			// callLater to preserve expected async semantics
			PicnikBase.app.callLater(fnComplete, [ StorageServiceError.None, null, { username: AccountMgr.GetInstance().displayName } ]);
		}

		// Get info wraps GetItems in a locked way - only one call at a time is allowed in
		// the routine - multiple calls share results.
		// This is used by GetStoreInfo and GetSets
		// fnComplete(err:Number, strError:String, cFiles:Number=-1)
		// - None
		// - IOError
		// - NotLoggedIn
		private function GetInfo(fnComplete:Function): void {
			_afnOnGetInfo.push(fnComplete);
			if (_afnOnGetInfo.length <= 1) {
				var fnOnGetItems:Function = function (err:Number, strError:String, adctItemInfos:Array): void {
					var cFiles:Number = adctItemInfos ? adctItemInfos.length : -1;
					while (_afnOnGetInfo.length > 0) {
						var fnOnGetInfo:Function = _afnOnGetInfo.pop();
						fnOnGetInfo(err, strError, cFiles);
					}
				}
				GetItems(null, null, null, 0, fileListLimit, fnOnGetItems);
			}
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
			var fnOnGetInfo:Function = function (err:Number, strError:String, cFiles:Number): void {
				if (err != StorageServiceError.None)
					fnComplete(err, strError);
				else
					fnComplete(StorageServiceError.None, null, { itemcount: cFiles });
			}
			
			GetInfo(fnOnGetInfo);
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
			var fnOnGetInfo:Function = function (err:Number, strError:String, cFiles:Number): void {
				if (err != StorageServiceError.None)
					fnComplete(err, strError);
				else
					fnComplete(StorageServiceError.None, null, [ { id: _strId, itemcount: cFiles, title: _strTitle, readonly: true } ]);
			}
			
			GetInfo(fnOnGetInfo);
		}
		
		public function DeleteAll(fnComplete:Function=null): void {
			
			var fnOnDeleted:Function = function(err:Number, strError:String): void {
				_aitemInfoCache.length = 0; // clear the cache
				if (fnComplete != null) fnComplete(err, strError);
			}
			
			if (isHistory || isMyPicnik) {
				PicnikService.DeleteMany(GetQuery(), fnOnDeleted);
			} else {
				// Hide only (for recent uploads because we need to keep these files around for rendering)
				var fnOnGotItems:Function = function(err:Number, strError:String, aitemInfo:Array=null): void {
					if (err != PicnikService.errNone) {
						if (fnComplete != null) fnComplete(err, strError);
					} else {
						HideItemInfos(aitemInfo, fnOnDeleted);
					}
				}
				
				GetItems(null, null, null, 0, fileListLimit, fnOnGotItems);
			}
		}
				
		override public function DeleteItem(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void {
			var fnOnDelete:Function = function (err:Number, strError:String): void {
				switch (err) {
				case PicnikService.errNone:
					err = StorageServiceError.None;
					strError = null;
					break;
					
				default:
					err = StorageServiceError.Unknown;
					break;
				}
				RemoveFromCache(strItemId);
				
				if (fnComplete != null) fnComplete(err, strError);
			}
			
			// Delete .pik file and the files it references
			if (isHistory || isMyPicnik)
				PicnikService.DeleteFile(strItemId, fnOnDelete);
			else
				HideFiles([strItemId], fnOnDelete);
		}
		
		private function RemoveFromCache(strItemId:String): void {
			if (_aitemInfoCache) {
				var nDelete:Number = -1;
				for (var i:Number = 0; i < _aitemInfoCache.length; i++) {
					if (_aitemInfoCache[i].id == strItemId) {
						nDelete = i;
						break;
					}
				}
				if (nDelete > -1)
					_aitemInfoCache.splice(nDelete, 1);
			}
		}
		
		// Creates a new item and returns a dictionary with details about it. CreateItem is highly
		// service dependent. In an extreme case, the service may ignore any or all of the SetId,
		// ItemId, ItemInfo, and imgd parameters and return an empty ItemInfo.
		// The passed in ItemInfo may contain any fields listed in GetItemInfo below but it
		// is up to the service which ones it chooses to use.
		// strItemId (opt) -- if non-null CreateItem will overwrite the specified item
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

		// UNDONE: update ImageDocument after transfer
		override public function CreateItem(strSetId:String, strItemId:String, itemInfo:ItemInfo, imgd:ImageDocument,
				fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
			if (strSetId == null)
				strSetId = "workspace";
			
			// CONSIDER: what is appropriate at the level beneath gallery, history, mypicnik?
			// / save pik (w/ replace if strItemId specified)
			// - UNDONE: attach thumbnail
			// * attach render props
			// * attach iteminfo props
			// * put it in strSetId album (strName = strSetId)
			// * force render (until client-side thumbnail creation is done)
			// / strType?
			// - return ???

			// Called when SaveRenderExport has finished (successfully or not)			
			var fnOnSaveRenderExportComplete:Function = function (err:Number, strError:String,
					dctFileProps:Object=null): void {
				if (err != StorageServiceError.None) {
					fnComplete(err, strError, null);
					return;
				}
				
				var temiNew:ItemInfo = StorageServiceUtil.ItemInfoFromPicnikFileProps(dctFileProps,
						"?userkey=" + PicnikService.GetUserToken());
				fnComplete(StorageServiceError.None, null, temiNew);
			}

			var dctSaveParams:Object = { data: String(imgd.Serialize(true)) };
			// UNDONE: dctSaveParams.thumbnail
			var strAssetMap:String = imgd.GetSerializedAssetMap(true);
			if (strAssetMap)
				dctSaveParams.assetMap = strAssetMap;
			if (strItemId)
				dctSaveParams.fid = int(strItemId);
				
			var dctItemInfo:Object = StorageServiceUtil.GetLastingItemInfo(
					ItemInfo.FromImageProperties(imgd.properties));
			dctItemInfo.serviceid = GetServiceInfo().id;
			delete dctItemInfo.history_serviceid;
			
			var dctFileProperties:Object = {
				strType: itemType, // UNDONE:
				strName: strSetId,
				fTemporary: 0,
				strMimeType: itemMimeType // UNDONE:
			}
			for (var strProp:String in dctItemInfo)
				dctFileProperties["iteminfo:" + strProp] = dctItemInfo[strProp];
			dctSaveParams.properties = dctFileProperties;
			
			// UNDONE: use caller-specified format/quality
			// UNDONE: if not caller-specified, match the format/quality of the base image
			// UNDONE: if no base image (e.g. collage), set format=jpg, quality=85 (same as save-to-Flickr has been using)
			// (same as FlickrStorageService for now)
			var dctRenderParams:Object = {
				width: imgd.width, height: imgd.height, format: "jpg", quality: 85,
				metadataAsset: imgd.baseImageAssetIndex
			}
			if (strAssetMap)
				dctRenderParams.assetMap = strAssetMap;
			
			PicnikService.SaveRenderExport("save,render", strItemId, null, dctSaveParams, dctRenderParams, null, null,
					fnOnSaveRenderExportComplete, null);
		}
		
		// These are meant to be overridden by subclasses
		protected function get itemType(): String {
			return "mypicnik:p";
		}
		
		protected function get itemMimeType(): String {
			return "text/xml";
		}
		
		override public function CreateGallery(strSetId:String, gald:GalleryDocument, fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
			Debug.Assert(false, "PicnikStorageService.CreateGallery not implemented");
		}

		// Returns a dictionary filled with information about the item.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - id (req)
		// - sourceurl (req)
		// - title (opt)
		// - description (opt)
		// - tags (opt)
		// - webpageurl (opt)
		// - setid (opt)
		// - width (opt)
		// - height (opt)
		// - size (opt) -- in bytes
		// - thumbnailurl (opt)
		// - createddate (opt)
		// - last_update (opt)
		// - ownerid (opt)
		// - baseurl (opt) [legacy, remove after build xx]
		// - thumb100url (opt)
		// - thumb320url (opt)
		// - thumb75url (opt)
		// - pikid (opt)
		// - assetmap (opt)
		//
		// fnComplete(err:Number, strError:String, itemInfo:ItemInfo=null)
		// - None
		// - IOError
		// - NotLoggedIn
		// - ItemNotFound
		//
		// fnProgress(nPercent:Number)

		override public function GetItemInfo(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void {
			var fnOnGetFileProperties:Function = function (err:Number, strError:String, dctProps:Object=null): void {
				if (err != PicnikService.errNone) {
					if (err == PicnikService.errAuthFailed)
						fnComplete(StorageServiceError.LoginFailed, strError, null);
					else
						fnComplete(StorageServiceError.Unknown, strError, null);
					return;
				}
				
				if (dctProps == null) {
					fnComplete(StorageServiceError.None, null, null);
					return;
				}
				
				var itemInfo:ItemInfo = StorageServiceUtil.ItemInfoFromPicnikFileProps(dctProps, "?userkey=" + PicnikService.GetUserToken());
				fnComplete(StorageServiceError.None, null, itemInfo);
			}
			
			// parse the secret out of the id
			var strSecret:String = null;
			var nUnderscore:int = strItemId.indexOf("_");
			if (nUnderscore != -1) {
				strSecret = strItemId.substr( nUnderscore + 1 );
				strItemId = strItemId.substr( 0, nUnderscore );			
			}
			
			PicnikService.GetFileProperties(strItemId, strSecret, null, fnOnGetFileProperties);
		}

		// Updates item info. The item is moved to the album specified by strSetId.
		// SetItemInfo is currently used for renaming (changing iteminfo:title) items.
		override public function SetItemInfo(strSetId:String, strItemId:String, itemInfo:ItemInfo, fnComplete:Function,
				fnProgress:Function=null): void {
			var fnSetFilePropertiesComplete:Function = function (err:Number, strError:String): void {
				fnComplete(err == PicnikService.errNone ? StorageServiceError.None : StorageServiceError.Unknown, strError);
			}

			// Only some iteminfo properties are valid for a stored item			
			var dctItemInfo:Object = StorageServiceUtil.GetLastingItemInfo(itemInfo);
			dctItemInfo.serviceid = GetServiceInfo().id;
			delete dctItemInfo.history_serviceid;
			
			var dctFileProperties:Object = {};
			for (var strProp:String in dctItemInfo)
				dctFileProperties["iteminfo:" + strProp] = dctItemInfo[strProp];
			if (strSetId != null)
				dctFileProperties.strName = strSetId;
				
			// UNDONE: this adds and changes props but doesn't clear out old ones. This is probably
			// true for most StorageService implementations.
			PicnikService.SetFileProperties(dctFileProperties, strItemId, fnSetFilePropertiesComplete);
		}
		
		public function PushNewFid(fid:String, fr:FileReference=null, strType:String="i_mycomput"): void {
			if (_aitemInfoCache) {
				_aitemInfoCache.splice(0,0,PicnikStorageService.NewFidToItemInfo(fid, fr, strType));
				Application.application.callLater(LimitListSize);
				forceListCache = true;
			}
		}
		
		public static function NewFidToItemInfo(fid:String, fr:FileReference=null, strType:String="i_mycomput"): Object {
			var dctProps:Object = NewFidToPicnikFileProps(fid, fr, strType);
			var itemInfo:ItemInfo = StorageServiceUtil.ItemInfoFromPicnikFileProps(dctProps, "?userkey=" + PicnikService.GetUserToken());
			return itemInfo;
		}
		
		private static function NewFidToPicnikFileProps(fid:String, fr:FileReference=null, strType:String="i_mycomput"): Object {
			var dctProps:Object = {};
			
			dctProps['iteminfo:title'] = AssetMgr.SafeTitle(fr);
			dctProps['iteminfo:filename'] = AssetMgr.SafeFilename(fr);
			dctProps.nFileId = fid;
			dctProps.strOwnerId = AccountMgr.GetInstance().GetUserId();
			dctProps.strType = strType;
			dctProps.dtCreated = new Date();
			dctProps.dtModified = new Date();
			return dctProps;
		}
		
		private function get isHistory(): Boolean {
			return _strTypes == "history";
		}
		
		private function get isMyPicnik(): Boolean {
			return _strTypes == "mypicnik";
		}
		
		private function HideItemInfos(aitemInfosToDelete:Array, fnDone:Function=null): void {
			var afidToHide:Array = [];
			for each (var itemInfo:ItemInfo in aitemInfosToDelete) {
				if (_afidRecentlyHidden==null || !(itemInfo.id in _afidRecentlyHidden)) {
					afidToHide.push(itemInfo.id);
				}
			}
			var fnOnHideFiles:Function = function (err:Number, strError:String): void {
				if (err != PicnikService.errNone) {
					trace("Error hiding extra files: " + err + ", " + strError);
				}
				if (fnDone != null)
					fnDone(err, strError);
			}
			// UNDONE: what if afidToHide is zero-length?  the REST call will fail
			HideFiles(afidToHide, fnOnHideFiles);
		}
		
		private function HideFiles(afid:Array, fnDone:Function): void {
			if (!_afidRecentlyHidden) {
				_afidRecentlyHidden = afid;
			} else {
				_afidRecentlyHidden.splice(-1,0,afid);				
			}			
			for each (var fid:String in afid) {
				var upldr:Uploader = UploadManager.GetUpload(fid);
				if (upldr)
					upldr.Cancel();
				else
					UploadManager.CancelUpload(fid);
			}
			PicnikService.SetManyFileProperties({strType:'hidden', fTemporary:1}, afid, fnDone);
		}
		
		private function LimitListSize(): void {
			if (_aitemInfoCache) {
				// First, delete extra files
				if (_aitemInfoCache.length > storageLimit) {
					// Delete (hide) and remove from the list
					HideItemInfos(_aitemInfoCache.splice(storageLimit, _aitemInfoCache.length - storageLimit));
				}
				
				// Next, hide extra files (in case our show limit is less than our storage limit)
				if (_aitemInfoCache.length > fileListLimit) {
					// Remove from the list but don't delete (hide)
					_aitemInfoCache.splice(fileListLimit, _aitemInfoCache.length - fileListLimit);
				}
			}
		}
		
		// Returns an array of dictionaries filled with information about the items (ItemInfos, see GetItemInfo).
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - sort values (opt)
		//
		// fnComplete(err:Number, strError:String, aitemInfo:Array=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		// UNDONE: standard sorts
		
		override public function GetItems(strSetId:String, strSort:String, strFilter:String, nStart:Number, nCount:Number, fnComplete:Function, fnProgress:Function=null): void {
			// If the ItemInfo cache is less than 5 seconds old return items directly from it.
			// This keeps us from hammering the server when the history is being displayed (it
			// redundantly GetItems to populate the # of photos, sets, and the list of items).
			LimitListSize();
			
			var cmsNow:int = getTimer();
			if (_aitemInfoCache && ( (_cmsItemInfoCacheTimestamp + (5 * 1000) >= getTimer()) || forceListCache)) {
				forceListCache = false;
				PicnikBase.app.callLater(fnComplete, [ StorageServiceError.None, null, _aitemInfoCache.slice(nStart, nStart + nCount) ]);
				return;
			}
				
			var fnOnGetFileList:Function = function (err:Number, strError:String, adctProps:Array=null): void {
				if (err != PicnikService.errNone) {
					fnComplete(StorageServiceError.Unknown, strError, null);
					return;
				}
				
				var afidsToDelete:Array = [];
				
				var aitemInfos:Array = new Array();
				for each (var dctProps:Object in adctProps) {
					// Temporary file logic
					if ("fTemporary" in dctProps) {
						if (dctProps['strType'] == "history")
							continue; // Don't show temporary history files
						// Otherwise, assume a 24 hour expiry.
						// We will probably want to change this at some point
					}
					
					if (dctProps['strType'] != "history") {
						if (!('strMD5' in dctProps) || !dctProps['strMD5'] || dctProps['strMD5'].length < 1) {
							// No md5 - check to see if we are currently uploading this file
							if (!('nFileId' in dctProps) || UploadManager.GetUpload(dctProps['nFileId']) == null) {
								if ('nFileId' in dctProps)
									afidsToDelete.push(dctProps['nFileId']);
								continue; // No MD5 and not pending
							}
						}
					}
											
					var itemInfo:ItemInfo = StorageServiceUtil.ItemInfoFromPicnikFileProps(dctProps, "?userkey=" + PicnikService.GetUserToken());
					aitemInfos.push(itemInfo);
				}

				// UNDONE: hang onto the ItemInfos for GetItemInfo until PicnikService.GetFileInfo(strFileId) is implemented
				_aitemInfoCache = aitemInfos;
				LimitListSize();
				_cmsItemInfoCacheTimestamp = getTimer();
				fnComplete(StorageServiceError.None, null, _aitemInfoCache.slice(nStart, nStart + nCount));
				
				if (afidsToDelete.length > 0)
					Application.application.callLater(HideFiles, [afidsToDelete, null]);
			}

			try {
				if (nStart == 0 || _aitemInfoCache == null) {
					PicnikService.GetFileList(GetQuery(), defaultOrderBy, "desc", 0, fileListLimit, null, includePending, fnOnGetFileList, null);
				} else {
					PicnikBase.app.callLater(fnComplete, [ StorageServiceError.None, null, _aitemInfoCache.slice(nStart, nStart + nCount) ]);

				}
			} catch (err:Error) {
				var strLog:String = "Client exception: PicnikService.GetFileList";
				PicnikService.LogException(strLog, err);
			}												
		}
		
		private function GetQuery(): String {
			var strQuery:String = null;
			if (_strTypes && _strTypes.length > 0) {
				if (_strTypes.indexOf(',') > -1) {
					// UNDONE: Add logic for selecting multiple types
					throw new Error("Not yet implemented");
				} else {
					strQuery = "strType LIKE " + _strTypes + "%";
				}
			}
			return strQuery;
		}
		
		// ProcessServiceParams
		// does storage-service-specific processing of parameters that were given to us
		// via the an invocation of Picnik As Service.
		// see IStorageService::ProcessServiceParams comments
		public override function ProcessServiceParams(dctParams:Object, fnComplete:Function, fnProgress:Function=null):void {			
			try {
				// store a local var with "this" that it'll be available within the callbacks below
				var ssThis:IStorageService = this;
				if( !IsLoggedIn() ) {
					// this is pretty much impossible. We ARE picnik. How can we not be logged in?
					Debug.Assert( IsLoggedIn(), "ProcessServiceParams: user not logged in." );
					fnComplete(StorageServiceError.None, null, {} );																
					return;
				}
							
				// we are properly authorized, so process the command							
				if ((typeof(dctParams._ss_cmd) == undefined) || (!dctParams._ss_cmd)) {
					fnComplete(StorageServiceError.None, null, {} );																
					return;
				}

				if (dctParams._ss_cmd == "edit" || dctParams._ss_cmd == "share") {
					if ((typeof(dctParams._ss_item_id) == undefined) || (!dctParams._ss_item_id)) {
						fnComplete(StorageServiceError.None, null, {} );																
						return;
					}
												
					GetItemInfo( null, dctParams._ss_item_id,
							function( err:Number, strError:String, itemInfo:ItemInfo=null ): void {
								try {
									if (err != StorageServiceError.None) {
										fnComplete( err, strError, {ss: ssThis} );
									} else if (!itemInfo) {
										fnComplete( err, strError, {ss: ssThis} );
									} else {
										fnComplete( err, strError, { load: itemInfo, ss: ssThis } );
									}
								} catch (err:Error) {
									var strLog3:String = "Client exception: PicnikStorageService.ProcessServiceParams.OnGetItems: ";
									PicnikService.LogException(strLog3, err);
								}									
							});
					return;
				}										
			} catch (err:Error) {
				var strLog:String = "Client exception: PicnikStorageService.ProcessServiceParams ";
				PicnikService.LogException(strLog, err);
			}

			fnComplete(StorageServiceError.None, null, {} );																
			return;
		}
				
		
		// This exists so derived classes can override it
		protected function get includePending(): Boolean {
			return true;
		}
		
		// This exists so derived classes can override it
		protected function get defaultOrderBy(): String {
			return null;
		}
		
		// Returns an array of dictionaries filled with information about the logged in user's friends.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - uid (req)
		// - name (opt)
		// - picurl (opt)
		//
		// fnComplete(err:Number, strError:String, adctFriendsInfo:Array=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)

		override public function GetFriends(fnComplete:Function, fnProgress:Function=null): void {
			// callLater to preserve expected async semantics
			PicnikBase.app.callLater(fnComplete, [ StorageServiceError.None, null, [] ]);
		}
	}
}
