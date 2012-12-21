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
package bridges.flickr {
	import bridges.*;
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceBase;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceRegistry;
	
	import containers.ResizingDialog;
	
	import dialogs.DialogManager;
	
	import imagine.ImageDocument;
	
	import util.DynamicLocalConnection;
	import util.IRenderStatusDisplay;
	import util.KeyVault;
	import util.RenderHelper;

		
	public class FlickrStorageService extends StorageServiceBase {
		private var _strUserId:String; 	// uid
		private var _strAuth:String; 	// session_key
		private var _fIsPro:Boolean;	// is user a pro user?
		private var _flkrp:FlickrProxy;
		private var _dctPendingSetInfo:Object = null;
		private var _fnComplete:Function = null;
		private const kstrPendingSetId:String = "_pending_flickr_set_id_";

		private var _lconFlickrSuccess:DynamicLocalConnection = null;
		private var _fLconFlickrSuccessConnected:Boolean = false;

		
		public function FlickrStorageService() {
			_flkrp = new FlickrProxy(KeyVault.GetInstance().flickr.pub, KeyVault.GetInstance().flickr.priv);
		}
		
		public override function GetServiceInfo(): Object {
			return StorageServiceRegistry.GetStorageServiceInfo("flickr");
		}
		
		public override function Authorize(strPerm:String=null, fnComplete:Function=null): Boolean {
			strPerm = strPerm || "delete";
			var strLoginUrl:String = _flkrp.GetLoginURL("delete");
			_fnComplete = fnComplete;
			
			var fnPopupOpen:Function = function(err:int, errMsg:String, ob:Object): void {
				// listen for new user properties
				var strSuccessMethod:String = "successMethod";
				var strConnectionName:String = "flickrAuth";
			
				_lconFlickrSuccess = new DynamicLocalConnection();
				_lconFlickrSuccess.allowPicnikDomains();
				_lconFlickrSuccess[strSuccessMethod] = function(strCBParams:String=null): void {
					// the popup succeeded!
					if (_fnComplete != null) {
						_fnComplete(0, "", strCBParams);
						_fnComplete = null;
					}
					try {
						_lconFlickrSuccess.close();
					} catch (e:Error) {
						//
					}
					_fLconFlickrSuccessConnected = false;
					_lconFlickrSuccess = null;
					
					DialogManager.HideBlockedPopupDialog();
				};
				
				if (!_fLconFlickrSuccessConnected) {
					try {
						_lconFlickrSuccess.connect(strConnectionName);
					} catch (e:Error) { /*NOP*/ }
					_fLconFlickrSuccessConnected = true;
				}
			}
			
			PicnikBase.app.NavigateToURLInPopup(strLoginUrl, 775, 800, fnPopupOpen);
			return true;
		}

		public override function IsLoggedIn(): Boolean {
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
		
		public override function LogIn(tpa:ThirdPartyAccount, fnComplete:Function, fnProgress:Function=null): void {
			// Validate the token by doing a trivial request that will fail if the frob is no longer valid

			try {
				// Initialize these becuase GetUserInfo needs them			
				_strAuth = tpa.GetToken();
				_strUserId = tpa.GetUserId();
				
				GetUserInfo(function (err:Number, strError:String, dctUserInfo:Object=null): void {
					if (err != StorageServiceError.None) {
						// Clear these out so the StorageService remains pristine if the user
						// isn't logged in.
						_strAuth = null;
						_strUserId = null;
					} else {
						_strAuth = tpa.GetToken();
					}
					fnComplete(err, strError);
				});
			} catch (err:Error) {
				var strLog:String = "Client exception: FlickrStorageService.LogIn " + err.toString()+ "/" + tpa.GetUserId() + "/" + tpa.GetToken();
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
	
		// fnProgress(nPercent:Number)

		public override function LogOut(fnComplete:Function=null, fnProgress:Function=null): void {
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

		public override function GetUserInfo(fnComplete:Function, fnProgress:Function=null): void {
			_flkrp.auth_checkToken({auth_token:_strAuth}, OnGetUserInfo, fnComplete);
		}
		
		private function OnGetUserInfo(rsp:XML, fnComplete:Function): void {
			try {
				var strError:String = "";
				var nError:Number = StorageServiceError.None;
				var dctUserInfo:Object = null;
				
				if (rsp.@stat != "ok") {
					nError = StorageServiceError.Unknown
				} else {
					// Return all the Flickr user info retrieved along with the token
					dctUserInfo = {
						id: String(rsp.auth.user.@nsid),
						username: String(rsp.auth.user.@username),
						fullname: String(rsp.auth.user.@fullname)		
					}
					
					var fnOnGetUploadStatus:Function = function(rsp:XML):void {
							if (rsp.@stat == "ok") {
								dctUserInfo.is_pro = _fIsPro = (Number(rsp.user[0].@ispro) != 0);
								dctUserInfo.userbytes = String(rsp.user[0].bandwidth.@usedbytes);
								dctUserInfo.maxbytes = String(rsp.user[0].bandwidth.@maxbytes);
								dctUserInfo.setsremaining = String(rsp.user[0].sets.@remaining);
								_flkrp.people_getInfo({ auth_token:_strAuth, user_id:_strUserId }, fnOnPeopleGetInfo);
							} else {			
								fnComplete( nError, strError, dctUserInfo );
							}
						} 					

					var fnOnPeopleGetInfo:Function = function(rsp:XML):void {
							if (rsp.@stat == "ok") {
								var prsn:XML = rsp.person[0];
								if (Number(prsn.@iconserver) > 0)
									dctUserInfo.thumbnailurl = "http://static.flickr.com/" + prsn.@iconserver + "/buddyicons/" + prsn.@nsid + ".jpg";
								else
									dctUserInfo.thumbnailurl = "http://www.flickr.com/images/buddyicon.jpg";
							}
							fnComplete( nError, strError, dctUserInfo );
						} 					

					_flkrp.people_getUploadStatus({auth_token:_strAuth}, fnOnGetUploadStatus);
					return;
				}
			} catch (e:Error) {
				nError = StorageServiceError.Unknown;
			}
			
			fnComplete( nError, strError );			
		}
		
		protected override function _GetSets(strUsername:String, fnComplete:Function, fnProgress:Function=null):void {
			var dctParams:Object = {auth_token: _strAuth};
			if (strUsername)
				dctParams['user_id'] = strUsername;
			_flkrp.photosets_getList(dctParams, _OnGetSets, {fnComplete:fnComplete, strUserId:strUsername });
		}
			
		private function _OnGetSets(rsp:XML, obContext:Object): void {
			if (rsp.@stat == "ok") {
				var strUserId:String = obContext.strUserId ? obContext.strUserId : _strUserId;
				var aSets:Array = [];
				var xmlpset:XMLList = rsp.photosets.photoset;
				for each (var pset:XML in xmlpset) {
					var dctSetInfo:Object = {
						id: String(pset.@id),
						title: String(pset.title),
						itemcount: String(pset.@photos),
						description: String(pset.description),
						thumbnailurl: "http://static.flickr.com/" + pset.@server +"/" + pset.@primary + "_" + pset.@secret + "_s.jpg",
						webpageurl: "http://www.flickr.com/photos/" + strUserId + "/sets/" + String(pset.@id)
					};
					aSets.push( dctSetInfo );							
				}
				if (_dctPendingSetInfo)
					aSets.unshift( _dctPendingSetInfo ); 
				obContext.fnComplete( StorageServiceError.None, null, aSets );
			}	
			obContext.fnComplete( StorageServiceError.Unknown, null);
		}

		
		public override function CreateItem(strSetId:String, strItemId:String, itemInfo:ItemInfo, imgd:ImageDocument,
									fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
			
			// Called in acase of a render success
			// Process render params and call the callback function
			var fnOnRenderSuccess:Function = function(fnDone:Function, obResult:Object): void {
				var phid:String = obResult.itemid.value;

				var fnOnCreatePendingSet:Function = function (rsp:XML):void {
					// strSetId is still set to kstrPendingSetId, but the real setId
					// is now returned in rsp.  Time for a small switcheroo.
					strSetId = rsp.photoset.@id;
					if (!AccountMgr.GetInstance().isGuest)
						CommitRenderHistory(obResult, itemInfo, strSetId, fnDone);
					else
						fnDone(ImageDocument.errNone, null, null);
				}
				
				if (strSetId == kstrPendingSetId && _dctPendingSetInfo) {
					var dctParams:Object = {auth_token: _strAuth,
											title: _dctPendingSetInfo.title,
											description: _dctPendingSetInfo.description,
											primary_photo_id: phid };
					_dctPendingSetInfo = null;
					_flkrp.photosets_create(dctParams, fnOnCreatePendingSet);
				} else if (AccountMgr.GetInstance().isGuest) {
					fnDone(ImageDocument.errNone, null, null);
				} else {
					CommitRenderHistory(obResult, itemInfo, strSetId, fnDone);
				}
			}

			var params:Object = {
				authtoken: _strAuth,
				title: itemInfo.title ? itemInfo.title : "",
				description: itemInfo.description ? itemInfo.description : "",
				tags: itemInfo.tags ? itemInfo.tags : "",
				ispublic: itemInfo.flickr_ispublic ? "true" : "false",
				isfriend: itemInfo.flickr_isfriend ? "true" : "false",
				isfamily: itemInfo.flickr_isfamily ? "true" : "false",
				history: AccountMgr.GetInstance().isGuest ? "false" : "true",
				isPro: _fIsPro ? "true" : "false"
			}
			if (strSetId != null && strSetId != kstrPendingSetId)
				params['psetid'] = strSetId;
			if (strItemId)
				params['phid'] = strItemId;
			
			new RenderHelper(imgd, fnComplete, irsd).CallMethod("saveimagetoflickr", params, fnOnRenderSuccess);
		}

		public override function DeleteItem(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void {
			var fnOnDeleteItem:Function = function(rsp:XML): void {
				if (rsp.@stat != "ok") {
					// Login failed / Invalid auth token OR User not logged in / Insufficient permissions
					if (rsp.err.@code == "98" || rsp.err.@code == "99") {
						fnComplete( StorageServiceError.InvalidUserOrPassword, rsp.err.@code );
					}
				} else {
					fnComplete( StorageServiceError.None, null );
				}
			}
			
			_flkrp.photos_delete({ auth_token: _strAuth, photo_id: strItemId }, fnOnDeleteItem );
		}				

		protected override function FillItemCache( strSetId:String, strSort:String, strFilter:String, fnComplete:Function, obContext:Object ): void {
			var dctArgs:Object = {
				extras: "original_format, last_update, date_taken, date_upload",
				per_page: 500
			};
			if (_strAuth) dctArgs.auth_token = _strAuth;

			var fnOnGetItems:Function = function (rsp:XML): void {				
				ClearCachedItemInfo();
				if (rsp.@stat != "ok") {
					trace("Unable to get items " + rsp.err.@msg + " (" + rsp.err.@code + ")");
					fnComplete(StorageServiceError.IOError, rsp.err.@msg, obContext);
					return;
				}
			
				var adctSetItems:Array = [];	
				if (rsp.hasOwnProperty("photos")) {
					for each (var ph:XML in rsp.photos.photo) {
						var itemInfo:ItemInfo = ItemInfoFromPhoto(ph);
						itemInfo.setid = strSetId;
						StoreCachedItemInfo( itemInfo );
					}					
				} else {
					for each (var ph2:XML in rsp.photoset.photo) {
						if (rsp.photoset.@owner != null)
							ph2.@owner = rsp.photoset.@owner;
						var itemInfo2:ItemInfo = ItemInfoFromPhoto(ph2);
						itemInfo2.setid = strSetId;
						StoreCachedItemInfo( itemInfo2 );
					}
				}
				
				fnComplete(StorageServiceError.None, null, obContext);
			}
	
			if (strSetId && strSetId.length > 0) {			
				dctArgs["photoset_id"] = strSetId;
				_flkrp.photosets_getPhotos(dctArgs, fnOnGetItems);
			} else {	
				if ((!strSort || strSort == "recently_updated") && (null == strFilter || strFilter.length == 0)) {		
					// Get up to 500 of the user's past two years of photos in reverse order from the present
					var date:Date = new Date();
					date.setFullYear(date.getFullYear() - 2);
					dctArgs["min_date"] = String(int(date.getTime() / 1000));
					_flkrp.photos_recentlyUpdated(dctArgs, fnOnGetItems);
				} else {
					dctArgs["user_id"] = "me";
					dctArgs["sort"] = strSort;
					if (dctArgs["sort"] == "recently_updated")
						dctArgs["sort"] = "date-posted-desc";
					if (strFilter && strFilter.length > 0)
						dctArgs["text"] = strFilter;				
					_flkrp.photos_search(dctArgs, fnOnGetItems);
				}
			}		
		}

		protected override function UpdateItemCache( strSetId:String, strItemId:String, fnComplete:Function, obContext:Object ): void {
			var fnOnPhotosGetInfoEx:Function = function (rsp:XML): void {
				if (rsp.@stat != "ok") {
					trace("Unable to get photo info " + rsp.err.@msg + " (" + rsp.err.@code + ")");
					fnComplete(StorageServiceError.IOError, rsp.err.@msg, obContext);
				} else {
					var itemInfo:ItemInfo = ItemInfoFromPhotoInfo(rsp.photo[0]);
					itemInfo.setid = strSetId;
					
					UpdateCachedItemInfo(itemInfo);
					
					// Update the context with the etag-less id so cache lookups with it will work
					obContext.id = itemInfo.id;
					fnComplete(StorageServiceError.None, null, obContext);
				}
				return;
			}
			
			var dctArgs:Object = {photo_id: strItemId};
			if (_strAuth) dctArgs.auth_token = _strAuth;
			
			_flkrp.Photos_GetInfoEx(dctArgs, fnOnPhotosGetInfoEx);
		}

		protected override function FillItemCache2( apartialItemInfos:Array, fnComplete:Function, obContext:Object ): void {
			var fnOnPhotosGetInfoEx:Function = function (rsp:XML): void {
				if (rsp.@stat != "ok") {
					trace("Unable to get photo info " + rsp.err.@msg + " (" + rsp.err.@code + ")");
					fnComplete(StorageServiceError.IOError, rsp.err.@msg);
					return;
				} else {
					ClearCachedItemInfo();
					
					var itemInfo:ItemInfo = null;
					if (rsp.hasOwnProperty("photos")) {
						var fPartial:Boolean = rsp.photos.hasOwnProperty("@partial") && rsp.photos.@partial;
						for each (var xmlPhoto:XML in rsp.photos.photo) {
							itemInfo = ItemInfoFromPhotoInfo(xmlPhoto);
							itemInfo.partial = fPartial;
							StoreCachedItemInfo( itemInfo );
						}
					} else {
						itemInfo = ItemInfoFromPhotoInfo(rsp.photo[0]);
						StoreCachedItemInfo( itemInfo );
					}
				}				
				fnComplete(StorageServiceError.None, null, obContext);
			}
			
			var aIds:Array = [];
			for each( var itemInfo:Object in apartialItemInfos ) {
				aIds.push( itemInfo.id );
			}
			var dctArgs:Object = {photo_ids: aIds.join(",")};
			if (_strAuth) dctArgs.auth_token = _strAuth;
			
			
			_flkrp.Photos_GetInfoEx(dctArgs, fnOnPhotosGetInfoEx);
		}

		// Updates item info
		// Currently support 'title' only, but need to pass in description or it gets deleted
		public override function SetItemInfo(strSetId:String, strItemId:String, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void {
			var fnRename:Function = function(): void {
				// We have the description, so go ahead and call setMeta
				var dctParams:Object = {auth_token: _strAuth,
										photo_id: strItemId };
										
				if (itemInfo.hasOwnProperty("title"))
					dctParams.title = itemInfo.title;
				if (itemInfo.hasOwnProperty("description"))
					dctParams.description = itemInfo.description;
				_flkrp.photos_setMeta( dctParams, OnSetItemInfo, {fnComplete:fnComplete} );
				
			}
			if (!itemInfo.hasOwnProperty("description") || itemInfo.description == null) {
				GetItemInfo( strSetId, strItemId,
					function(err:Number, strError:String, newItemInfo:ItemInfo):void {
						if (err != StorageServiceError.None) {
							fnComplete(err, strError);
						} else {
							itemInfo.description = newItemInfo.description;
							fnRename();
						}
					}, null );
			} else {
				fnRename();
			}
		}
		
		private function OnSetItemInfo(rsp:XML, obContext:Object): void {
			if (rsp.@stat != "ok") {
				obContext.fnComplete(StorageServiceError.IOError, rsp.err.@msg);
				return;
			}
			obContext.fnComplete(StorageServiceError.None, null);
		}
		
		// ProcessServiceParams
		// does storage-service-specific processing of parameters that were given to us
		// via the an invocation of Picnik As Service.
		// see IStorageService::ProcessServiceParams comments
		public override function ProcessServiceParams(dctParams:Object, fnComplete:Function, fnProgress:Function=null): void {			
			try {
				// store a local var with "this" that it'll be available within the callbacks below
				var ssThis:IStorageService = this;
				
				// first, we must log in!
				if (!IsLoggedIn()) {
					var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount("Flickr");
					LogIn(tpa, function (err:Number, strError:String = ""): void {					
						if (err == StorageServiceError.None) {
							// login was successful -- invoke ProcessServiceParams again
							// UNDONE: add something to dctParams to prevent infinite loopage
							ProcessServiceParams(dctParams, fnComplete, fnProgress);
						} else {
							// We weren't able to login, so redirect to the flickr authorize page
							tpa.SetToken("", true);
							if (!ssThis.Authorize()) {
								// we were unable to kick off the authorize navigation,
								// (probably because we're running inside flickrlite and
								// nav is disabled) so hit the callback with an error
								fnComplete(err, strError, { ss: ssThis });								
							}
							return;
						}
					});
					return;
				}
							
				// we are properly authorized, so process the command
				if ("_ss_cmd" in dctParams) {
					if (dctParams._ss_cmd == "edit") {
						// Return a dictionary: { load: ImageProperties, ss: IStorageService }
						GetItemInfo(null, dctParams._ss_itemid,
								function (err:Number, strError:String, itemInfo:ItemInfo=null): void {
									try {
										if (err != StorageServiceError.None || itemInfo == null) {
											fnComplete(err, strError, { ss: ssThis });
										} else {
											fnComplete( err, strError, { load: itemInfo, ss: ssThis } );
										}
									} catch (err:Error) {
										var strLog3:String = "Client exception: FlickrStorageService.ProcessServiceParams.OnGetItemInfo: ";
										strLog3 += err.toString();
										PicnikService.Log(strLog3, PicnikService.knLogSeverityError);
									}									
						});
						return;
					} else if(dctParams._ss_cmd == "multi") {
						
						// we need to process any multi sets that are lingering
						// inside the multi manager. We convert those set into
						// individual items, give them to the multi mgr, and return.

						try {
							var nPending:Number = 0;
							var nIndex:Number = -1;
							var dctPendingSet:Object = null;
							var fnOnGetItems:Function = function(err:Number, strErr:String, adctSetItems:Array = null ):void {
								if (dctPendingSet) {
									PicnikBase.app.multi.RemoveSet( dctPendingSet );
									if (err == StorageServiceError.None && adctSetItems ) {
										PicnikBase.app.multi.AddItems( adctSetItems );
									}
									dctPendingSet = null;
								}
								
								// find another flickr set
								for (var i:Number = 0; i < PicnikBase.app.multi.sets.length; i++ ) {
									dctPendingSet = PicnikBase.app.multi.sets[i];
									if (dctPendingSet.serviceid.toLowerCase() == "flickr") {
										GetItems( dctPendingSet.id, null, null, 0, 500, fnOnGetItems );
										break;
									} else {
										dctPendingSet = null;
									}
								}
								
								if (!dctPendingSet) {
									fnComplete( err, strErr, {} );
								}
							};
								
							var fnOnGetItemInfos:Function = function(err:Number, strErr:String, aitemInfos:Array = null ):void {
								if (aitemInfos && err == StorageServiceError.None) {
									PicnikBase.app.multi.AddItems( aitemInfos );
								}
								
								// move on to grabbing all the sets
								fnOnGetItems( StorageServiceError.None, null, null );								
							};
															
							// find all the flickr items
							var aitems:Array = [];
							for (var i:Number = 0; i < PicnikBase.app.multi.items.length; i++ ) {
								if (PicnikBase.app.multi.items[i].serviceid.toLowerCase() == "flickr")
									aitems.push(PicnikBase.app.multi.items[i]);
							}
							if (aitems.length > 0) {
								GetItemInfos( aitems, fnOnGetItemInfos );
							} else {
								// no items to get, so get the sets instead
								fnOnGetItems( StorageServiceError.None, null, null );
							}								
																
						} catch (err:Error) {
							var strLog4:String = "Client exception: FlickrStorageService.ProcessServiceParams.Multi: ";
							strLog4 += err.toString();
							PicnikService.Log(strLog4, PicnikService.knLogSeverityError);
							PicnikBase.app.callLater(fnComplete, [StorageServiceError.Unknown, ""]);						
							return;
						}

						return;
					}					
				}
			} catch (err:Error) {
				var strLog:String = "Client exception: FlickrStorageService.ProcessServiceParams: ";
				strLog += err.toString() + "/" + _strUserId + "/" + _strAuth;
				PicnikService.Log(strLog, PicnikService.knLogSeverityError);
			}
			
			fnComplete(StorageServiceError.None, null, {} );																
		}
		
		public override function CreateSet(dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			// flickr doesn't let you create an empty set, so we'll just store the info and wait
			// until the user actually adds an image to this set.
			_dctPendingSetInfo = dctSetInfo;
			_dctPendingSetInfo.id = kstrPendingSetId;
			_dctPendingSetInfo.itemcount = 0;
			PicnikBase.app.callLater(fnComplete, [StorageServiceError.None, "", _dctPendingSetInfo]);						
		}
		
		public static function ItemInfoFromPhoto(ph:XML): ItemInfo {
			var strBaseURL:String = "http://farm" + ph.@farm + ".static.flickr.com/" +
					ph.@server +"/" + ph.@id + "_" + ph.@secret;
			var strSourceURL:String;
			if (ph.hasOwnProperty("@originalsecret"))
				strSourceURL = "http://farm" + ph.@farm + ".static.flickr.com/" +
						ph.@server +"/" + ph.@id + "_" + ph.@originalsecret + "_o." + ph.@originalformat;
			else
				strSourceURL = strBaseURL + ".jpg"
			
			// Capture as many properties as we have available
			var itemInfo:ItemInfo = new ItemInfo( {
				id: String(ph.@id),
				etag : String(ph.@secret),
				serviceid: "flickr",
				title: String(ph.@title),
				sourceurl: strSourceURL,
				thumbnailurl: strBaseURL + "_m.jpg",
				ownerid: String(ph.@owner),
				ownername: String(ph.@owner_name),
				webpageurl: "http://www.flickr.com/photos/" + ph.@owner + "/" + ph.@id,
				flickr_isfamily: ph.@isfamily == "1",
				flickr_isfriend: ph.@isfriend == "1",
				flickr_ispublic: ph.@ispublic == "1",
				last_update: Number(ph.@last_update) * 1000,
				partial: true
			});
			
			return itemInfo;
		}
		
		private function ItemInfoFromPhotoInfo(ph:XML): ItemInfo {
			var strBaseURL:String = "http://farm" + ph.@farm + ".static.flickr.com/" +
					ph.@server +"/" + ph.@id + "_" + ph.@secret;
			var strSourceURL:String;
			var fNonOriginal:Boolean = false;
			if (ph.hasOwnProperty("@originalsecret"))
				strSourceURL = "http://farm" + ph.@farm + ".static.flickr.com/" +
						ph.@server +"/" + ph.@id + "_" + ph.@originalsecret + "_o." + ph.@originalformat;
			else if (ph.hasOwnProperty("@largestsource")) {
				strSourceURL = ph.@largestsource;
				fNonOriginal = true;
			} else
				strSourceURL = strBaseURL + ".jpg";

			// get the base format. Original images may be in many formats, everything else can only be a jpg
			var strFormat:String = "jpg";
			if (ph.hasOwnProperty("@originalformat"))
				strFormat = ph.@originalformat;
			
			// Capture as many properties as we have available
			var itemInfo:ItemInfo = new ItemInfo( {
				id: String(ph.@id),
				etag : String(ph.@secret),
				serviceid: "flickr",
				title: String(ph.title),
				description: String(ph.description),
				sourceurl: strSourceURL,
				thumbnailurl: strBaseURL + "_m.jpg",
				ownerid: String(ph.owner.@nsid),
				ownername: String(ph.owner.@username),
				webpageurl: "http://www.flickr.com/photos/" + ph.owner.@nsid + "/" + ph.@id,
				strFormat: strFormat,
				fCanLoadDirect : false,
				flickr_isfamily: ph.visibility.@isfamily == "1",
				flickr_isfriend: ph.visibility.@isfriend == "1",
				flickr_ispublic: ph.visibility.@ispublic == "1",
				flickr_rotation: fNonOriginal ? 0 : String(ph.@rotation),
				width: Number(ph.@width),
				height: Number(ph.@height),
				partial: false
			} );
			if (ph.hasOwnProperty("@last_update"))
				itemInfo.last_update = Number(ph.@last_update) * 1000;
			else if (ph.hasOwnProperty("dates") && ph.dates.hasOwnProperty("@lastupdate"))
				itemInfo.last_update = Number(ph.dates.@lastupdate) * 1000;

			if (ph.tags.length() > 0) {
				var astrTags:Array = [];
				for each (var ptag:XML in ph.tags.tag) {
					// Put double-quotes around tags with spaces in them because we
					// delimit tags with spaces or commas
					if (ptag.@raw.search(/[, ]/) != -1)
						astrTags.push('"' + ptag.@raw + '"');
					else
						astrTags.push(ptag.@raw);
				}
				itemInfo.tags = astrTags.join(" ");
			}
			
			if (_strUserId == itemInfo.ownerid)
				itemInfo.overwriteable = true;

			return itemInfo;
		}		

		// Returns a dictionary filled with information about the logged in user,
		// based on the provided Flickr frob.
		// NB: this is NOT part of the standard IStorageService interface, just a
		// special case helper method for FlickrAccountBase
		
		public function GetAuthToken(strFrob:String, fnComplete:Function, fnProgress:Function=null): void {
			_flkrp.auth_getToken({frob:strFrob}, OnGetAuthToken, fnComplete);
		}
		
		private function OnGetAuthToken(rsp:XML, fnComplete:Function): void {
			try {
				var strError:String = "";
				var nError:Number = StorageServiceError.None;
				var dctInfo:Object = null;
				
				if (rsp.@stat != "ok") {
					nError = StorageServiceError.Unknown
				} else {
					// Return all the Flickr user info retrieved along with the token
					dctInfo = {
						authtoken: String(rsp.auth.token),
						nsid: String(rsp.auth.user.@nsid),
						username: String(rsp.auth.user.@username),
						fullname: String(rsp.auth.user.@fullname),
						perms: String(rsp.auth.perms)		
					}
				}
			} catch (e:Error) {
				nError = StorageServiceError.Unknown;
			}
			
			fnComplete( nError, strError, dctInfo );			
		}

	}
}
