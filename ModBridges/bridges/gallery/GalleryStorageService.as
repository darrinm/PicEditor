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
package bridges.gallery {
	import bridges.*;
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceBase;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceRegistry;
	import bridges.storageservice.StorageServiceUtil;
	
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import imagine.ImageDocument;
	
	import util.IRenderStatusDisplay;
	import util.RenderHelper;
	
	public class GalleryStorageService extends StorageServiceBase {

		private static var s_strShareType:String = "s_gallery";
		private static var s_strServiceId:String = "Show";
				
		public var fileListLimit:Number = 1000; 					// Only show this many files
		public var storageLimit:Number = Number.POSITIVE_INFINITY; 	// If we have more than this many files, delete the rest
				
		public function GalleryStorageService() {
		}
		
		override public function GetServiceInfo(): Object {
			return StorageServiceRegistry.GetStorageServiceInfo("show");
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
			var aargs:Array;
			if (AccountMgr.GetInstance().isGuest)
				aargs = [ StorageServiceError.InvalidUserOrPassword, "GalleryStorageService.LogIn: guest users have no galleries" ];
			else
				aargs = [ StorageServiceError.None, "" ];
				
			// callLater to preserve expected async semantics
			PicnikBase.app.callLater(fnComplete, aargs);
		}
		
		override public function LogOut(fnComplete:Function=null, fnProgress:Function=null): void {
		}

		override public function GetUserInfo(fnComplete:Function, fnProgress:Function=null): void {
			// callLater to preserve expected async semantics
			PicnikBase.app.callLater(fnComplete, [ StorageServiceError.None, null, { username: AccountMgr.GetInstance().displayName } ]);
		}

		
		override protected function _GetSets(strUsername:String, fnComplete:Function, fnProgress:Function=null):void {
	
			var fnOnGetFileList:Function = function (err:Number, strError:String, adctProps:Array=null): void {
				if (err != PicnikService.errNone) {
					fnComplete(StorageServiceError.Unknown, strError, null);
					return;
				}
									
				var adctGalleryInfos:Array = new Array();
				for each (var dctProps:Object in adctProps) {
					// Temporary file logic
					if ("fTemporary" in dctProps && !dctProps.fTemporary)
						continue; // Don't show temporary galleries
					
					var dctGalleryInfo:Object = StorageServiceUtil.ItemInfoFromPicnikFileProps(dctProps, "?userkey=" + PicnikService.GetUserToken(), s_strServiceId);
					adctGalleryInfos.push(dctGalleryInfo);
				}
				fnComplete( StorageServiceError.None, null, adctGalleryInfos );
			}
			
			PicnikService.GetGalleryList(null, "desc", 0, fileListLimit, null, false, fnOnGetFileList, null);
		}
		
		
		// GetSetInfo -- info about set, natch
		// See IStorageService
		
		override public function GetSetInfo(strSetId:String, fnComplete:Function, fnProgress:Function=null): void {
			var fnOnGetGalleryProperties:Function = function (err:Number, strError:String, dctProps:Object=null): void {
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
				
				var itemInfo:ItemInfo = StorageServiceUtil.ItemInfoFromPicnikFileProps(dctProps, "?userkey=" + PicnikService.GetUserToken(), s_strServiceId);
				fnComplete(StorageServiceError.None, null, itemInfo);
			}
			
			// parse the secret out of the id
			var obIdAndSecret:Object = SplitIdAndSecret( strSetId );
			PicnikService.GetGalleryProperties(obIdAndSecret.id, obIdAndSecret.secret, null, fnOnGetGalleryProperties);
		}
		
		private function SplitIdAndSecret( strId:String ): Object {
			if (null == strId) {
				return { id:null, secret:null};
			}			
			
			// parse the secret out of the id
			var strSecret:String = null;
			var nUnderscore:int = strId.indexOf("_");
			if (nUnderscore != -1) {
				strSecret = strId.substr( nUnderscore + 1 );
				strId = strId.substr( 0, nUnderscore );			
			}
			return { id:strId, secret: strSecret };
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
		// fnComplete(err:Number, strError:String, dctItemInfo:Object=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)

		// UNDONE: update ImageDocument after transfer
		override public function CreateItem(strSetId:String, strItemId:String, itemInfo:ItemInfo, imgd:ImageDocument,
				fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
			
			// Called in a case of a render success
			// Process render params and call the callback function
			var fnOnRenderSuccess:Function = function(fnDone:Function, obResult:Object): void {
				var strSetId2:String = strSetId;
				if (strSetId2 == null)
					strSetId2 = obResult.setid.value;
				if (AccountMgr.GetInstance().isGuest)
					fnDone(StorageServiceError.None, null, itemInfo);
				else
					CommitRenderHistory(obResult, itemInfo, strSetId2, fnDone);
			}

			var dctParams:Object = {
				title: itemInfo.title ? itemInfo.title : "",
				description: itemInfo.description ? itemInfo.description : "",
				tags: itemInfo.tags ? itemInfo.tags : ""
			}
			
			if (strSetId != null)
				dctParams['setid'] = strSetId;
			else
				dctParams['defaultname'] = Resource.getString("GalleryDocument", "NewGallery");
			if (strItemId != null)
				dctParams['itemid'] = strItemId;
			
			new RenderHelper(imgd, fnComplete, irsd).CallMethod("saveimagetogallery", dctParams, fnOnRenderSuccess);
		}
		
		override public function CreateGallery(strSetId:String, gald:GalleryDocument, fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
			
			var ssThis:IStorageService = this;
			var fnOnGallerySaved:Function =  function(nError:Number, strErr:String, obRes:Object=null) : void {
					if (nError != PicnikService.errNone) {
						if (nError == PicnikService.errPermissionViolation || nError == PicnikService.errAuthFailed)
							nError = StorageServiceError.LoginFailed;
						else if (nError == PicnikService.errUserNotPremium)
							nError = StorageServiceError.UserNotPremium;
						else
							nError = StorageServiceError.Unknown;
						fnComplete(nError, "Error saving Show");
						return;
					}

					strSetId = obRes.id + "_" + obRes.strSecret;						
					ssThis.GetSetInfo(strSetId, function( nErr:Number, strErr:String, itemInfo:ItemInfo ): void {
							if (nError == PicnikService.errNone) {
								gald.OnInitFromPicnikFile( itemInfo );
								fnComplete( nErr, strErr, itemInfo );
							}
						});
					return;															
				}

			// Ready to begin rendering.
			var agutChangeList:Array = gald.GetChangeLog();
			var xmlUpdate:XML = new XML('<xmlDocument name="updategallery" encoding="utf-8" version="1"></xmlDocument>');
			for each ( var gut:GalleryUndoTransaction in agutChangeList ) {
				var xmlGut:XML = gut.toXml();					
				xmlUpdate.appendChild( xmlGut );
			}
			var oProps:Object = {}
			oProps['public'] = gald.isPublic ? "1" : "0";
			oProps['name'] = gald.name;
			var gutProps:GalleryUndoTransaction = new GalleryUndoTransaction("SetProperties",true,null,null,-1,-1,null,oProps);
			xmlUpdate.appendChild( gutProps.toXml() );

			var strLogPath:String = strSetId == null ? "/show/create" : "/show/update";
			Util.UrchinLogReport(strLogPath);

			PicnikService.UpdateGallery(strSetId, gald.info.secret, xmlUpdate, fnOnGallerySaved);												
		}
				
		// returns an object with two members: "props" and "items"
		private function ParseGalleryXml( strXml:String ): Object {
			var xml:XML = new XML(strXml);
			var xmll:XMLList = xml.*;

			if ('presentation' in xml)
				xmll = xml.presentation.*;

			var aItems:Array = [];
			var oAttrs:Object = _CollectXmlAttrs(xmll);
				
			for each (var elt:XML in xmll) {
				if (elt.name() == 'i') {
					var oItemAttrs:Object = _CollectXmlAttrs(elt.children());
					aItems.push(oItemAttrs);
				}
			}
				
			return { props:oAttrs, items:aItems };
		}
					
		// parse a list of attributes.  Used both for parsing global
		// attributes and parsing image-specific attributes.
		private function _CollectXmlAttrs(attrs:XMLList):Object {
			var attr_dict:Object = {};
			for each (var attr:XML in attrs) {
				if (attr.name() == 'a') {
					attr_dict[attr.@k] = attr.text().toString();
				}
			}
			return attr_dict;
		}

		override protected function FillItemCache( strSetId:String, strSort:String, strFilter:String, fnComplete:Function, obContext:Object): void {
			var fid:String = strSetId;
			
			var urlr:URLRequest = new URLRequest(PicnikService.GetFileURL(fid, null, null, null, false, true));
			var urll:URLLoader = new URLLoader();
			
			var fnOnLoadIOError:Function = function (evt:IOErrorEvent): void {
					if (fnComplete != null) fnComplete(StorageServiceError.InvalidServiceResponse, "Failed to load", obContext);
				}
			
			var fnOnLoadComplete:Function = function (evt:Event): void {
					try {
						var obResult:Object = ParseGalleryXml(urll.data);
						for each( var oItem:Object in obResult.items ) {
							var itemInfo:ItemInfo = new ItemInfo( { id: oItem.id } );
							if (oItem.ss)
								itemInfo.ss = oItem.ss;
							if (oItem.ss_item_id)
								itemInfo.ss_item_id = oItem.ss_item_id;
							if (oItem.ssid)
								itemInfo.ss_item_id = oItem.ss_item_id;
							if (oItem.url)
								itemInfo.sourceurl = oItem.url;
							if (oItem.thumbUrl)
								itemInfo.thumbnailurl = oItem.thumbUrl;
							if (oItem.title)
								itemInfo.title = oItem.title;
							if (oItem.caption)
								itemInfo.description = oItem.caption;
							if (oItem.owner)
								itemInfo.ownerid = oItem.owner;
							
							var o:Object = SplitIdAndSecret( strSetId );	
							itemInfo.setid = o.id;
							itemInfo.secret = o.secret;
							itemInfo.serviceid = s_strServiceId;
							itemInfo.overwriteable = false;
							itemInfo.species = "gallery";
							if (itemInfo.ownerid == AccountMgr.GetInstance().GetUserId())
								itemInfo.overwriteable = true;
							if ('ownerid' in obResult.props && obResult.props['ownerid'] == AccountMgr.GetInstance().GetUserId())
								itemInfo.overwriteable = true;
										
							StoreCachedItemInfo( itemInfo );							
						}
						fnComplete( StorageServiceError.None, null, obContext );
					} catch (err:Error) {
						var strLog:String = "Client exception: GalleryStorageService.ParseGalleryXml";
						PicnikService.LogException(strLog, err);
						fnComplete( StorageServiceError.Unknown, null, obContext );
					}												
				}

			urll.addEventListener(IOErrorEvent.IO_ERROR, fnOnLoadIOError);
			urll.addEventListener(Event.COMPLETE, fnOnLoadComplete);			
			urll.load(urlr);
		}
		
		protected override function UpdateItemCache( strSetId:String, strItemId:String, fnComplete:Function, obContext:Object ): void {
			ClearCachedItemInfo();
			FillItemCache(strSetId, null, null, fnComplete, obContext );
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
					if ((typeof(dctParams._ss_set_id) == undefined) || (!dctParams._ss_set_id)) {
						fnComplete(StorageServiceError.None, null, {} );																
						return;
					}
								
					var fnOnGetInfo:Function =
							// this function works equally well for Set infos as well as Item infos
							function( err:Number, strError:String, dctInfo:Object=null ): void {
								try {
									if (err != StorageServiceError.None) {
										fnComplete( err, strError, {ss: ssThis} );
									} else if (!dctInfo) {
										fnComplete( err, strError, {ss: ssThis} );
									} else {
										fnComplete( err, strError, { load: dctInfo, ss: ssThis } );
									}
								} catch (err:Error) {
									var strLog3:String = "Client exception: PicnikStorageService.ProcessServiceParams.OnGetItems: ";
									PicnikService.LogException(strLog3, err);
								}									
							}
					
					// if we were given a specific item to edit, then edit it. 
					// otherwise, edit the overall gallery
					if ((typeof(dctParams._ss_item_id) == undefined) || (!dctParams._ss_item_id)) {																
						GetSetInfo( dctParams._ss_set_id, fnOnGetInfo );
					} else {
						GetItemInfo( dctParams._ss_set_id, dctParams._ss_item_id, fnOnGetInfo );
					}
					return;
				}										
			} catch (err:Error) {
				var strLog:String = "Client exception: PicnikStorageService.ProcessServiceParams ";
				PicnikService.LogException(strLog, err);
			}
			fnComplete(StorageServiceError.None, null, {} );																
			return;
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

		override public function DeleteSet(strSetId:String, fnComplete:Function, fnProgress:Function=null): void {
			var ssThis:IStorageService = this;
			var fnOnGalleryDeleted:Function =  function(nError:Number, strErr:String, obRes:Object=null) : void {
					if (nError != PicnikService.errNone) {
						fnComplete(StorageServiceError.Unknown, "Error deleting Show", null);
						return;
					}
					ssThis.GetSets(null, fnComplete);
				}

			PicnikService.DeleteGallery(strSetId, fnOnGalleryDeleted);
		}

		public override function SetItemInfo(strSetId:String, strItemId:String, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void {
			if (itemInfo.title != undefined && itemInfo.title != "")
				PicnikService.RenameGallery(strItemId, itemInfo.title, fnComplete);
			else if (fnComplete != null)
				fnComplete(StorageServiceError.None, null);
		}
	}
}
