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
package bridges.storageservice {
	import util.PicnikFile;
	
	public class StorageServiceUtil	{
		public static function CommitRenderHistory(ss:IStorageService, obRenderResult:Object, itemInfo:ItemInfo, strSetId:String, fnComplete:Function=null, fTruncateId:Boolean=false): void {
			var strPikId:String = obRenderResult.pikid.value;
			var strNewItemId:String = obRenderResult.itemid.value;
			
			// HACK: The 'slice' is to remove the '!' prefix added by the server to keep the
			// HTTPService's ObjectProxy from converting the id into a Number (which doesn't
			// work because the number is too big and precision is lost in the process).
			if (fTruncateId)
				strNewItemId = String(strNewItemId).slice(1);

			var fnOnCommitRenderHistory:Function = function (err:Number, strError:String): void {
				if (fnComplete != null)
					fnComplete(PicnikService.errNone, null,
							new ItemInfo({ serviceid: ss.GetServiceInfo().id, setid: strSetId, id: strNewItemId }));
			}
			var temiLasting:ItemInfo = StorageServiceUtil.GetLastingItemInfo(itemInfo);
			temiLasting.setid = strSetId;
			
			PicnikService.CommitRenderHistory(strPikId, temiLasting, ss.GetServiceInfo().id, fnOnCommitRenderHistory);
		}
		
		public static function NullChildrenToEmptyString(ob:Object): void {
			for (var strKey:String in ob) {
				if (ob[strKey] == null)
					ob[strKey] = "";
			}
		}
		
		// Returns null if none found
		public static function StorageServiceFromImageProperties(imgp:ImageProperties): IStorageService {
			if (imgp == null || imgp./*bridge*/serviceid == null) return null;
			var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount(imgp./*bridge*/serviceid);
			if (!tpa || !tpa.storageService) {
				if (imgp./*bridge*/serviceid.toLowerCase() == "picnik") {
					// return PicnikStorageService.GetInstance();
					return null; // This picnik storage service has no _aitemInfoCache and so won't worok
				} else {
					return null;
				}
			}
			return tpa.storageService;
		}

		// Convert a picnik file into iteminfo
		// obSignUrls is either a string which is appended to the path, or
		// a function which has its result appended to the path.
		public static function ItemInfoFromPicnikFileProps(dctProps:Object, obSignUrls:Object=null, strServiceId:String = "Picnik"): ItemInfo {
			var itemInfo:ItemInfo = new ItemInfo();
			itemInfo.id = dctProps.nFileId;
			itemInfo.serviceid = strServiceId;
			itemInfo.md5sum = dctProps.strMD5;
			
			// Transfer iteminfo props and build the assetmap
			var strAssetMap:String = "";
			
			var strType:String = ('strType' in dctProps) ? dctProps.strType : null;
			var fHistoryFile:Boolean = strType == "history";
			var fPicnikFile:Boolean = strType.indexOf("mypicnik") == 0;
			
			// This is the creative way we've encoded My Picnik album ids
			if (strType == "mypicnik:p" && "strName" in dctProps)
				itemInfo.setid = dctProps.strName;
			
			if (fHistoryFile) {
				itemInfo.pikid = dctProps.nFileId;
				itemInfo.species = "pik";
			}
			
			for (var strProp:String in dctProps) {
				if (strProp == "iteminfo:id" || strProp == "iteminfo:setid")
					continue;
				
				// Transfer iteminfo prop
				if (strProp.indexOf("iteminfo:") == 0) {
					itemInfo[strProp.slice(9)] = dctProps[strProp];
					
				// Build the asset map
				} else if (strProp.indexOf("ref:asset") == 0) {
					strAssetMap += strProp.slice(9) + ":" + dctProps[strProp] + ",";
				}
			}				
			if (strAssetMap != "")
				itemInfo.assetmap = strAssetMap.slice(0, -1); // remove trailing ','
				
			// Pre-assetmap History entries have a reference to their base image. Use it to
			// fabricate an assetmap.
			else if ("ref:history:baseimage" in dctProps)
				itemInfo.assetmap = "0:" + dctProps["ref:history:baseimage"];

			if (isNaN(Number(dctProps.dtModified))) {
				trace("DWM: dtModified must be a number of seconds, not " + dctProps.dtModified);
				PicnikService.Log("DWM: dtModified must be a number of seconds, not " + dctProps.dtModified, PicnikService.knLogSeverityError);
			}
			if (isNaN(Number(dctProps.dtCreated))) {
				trace("DWM: dtCreated must be a number of seconds, not " + dctProps.dtCreated);
				PicnikService.Log("DWM: dtCreated must be a number of seconds, not " + dctProps.dtCreated, PicnikService.knLogSeverityError);
			}
			itemInfo.last_update = Number(dctProps.dtModified) * 1000; // convert to milliseconds					
			itemInfo.createddate = Number(dctProps.dtCreated) * 1000; // convert to milliseconds

			// "species" is our name for "document type", e.g. gallery, image, pik			
			if (String(dctProps.strType).indexOf("mypicnik:") == 0) {
				switch (dctProps.strType) {
				case "mypicnik:p":
					itemInfo.species = "pik";
					break;
					
				case "mypicnik:i":
					itemInfo.species = "image";
					break;
					
				case "mypicnik:g":
					itemInfo.species = "gallery";
					break;
				}
			} else if (dctProps.strType == "greeting") {
				itemInfo.species = "greeting";
			} else if ("strName" in dctProps) {	
				itemInfo.species = dctProps.strName;
				
				// NOTE: "show" as a species is legacy and has never been live
				if (itemInfo.species == "show")
					itemInfo.species = "gallery";
			}
				
			if ("strAccessAuth" in dctProps) {
				switch (dctProps.strAccessAuth) {
				case "public":
					itemInfo.access = GenericDocument.kAccessReadOnly;
					break;
				case "secret":
					itemInfo.access = GenericDocument.kAccessLimited;
					break;
				case "owner":
					itemInfo.access = GenericDocument.kAccessFull;
					break;
				default:
					itemInfo.access = GenericDocument.kAccessNone;					
					break;
				}
			}
			if ("strSecret" in dctProps)
				itemInfo.secret = dctProps.strSecret;
			if ("strOwnerId" in dctProps)
				itemInfo.ownerid = dctProps.strOwnerId;
				
			var obUrls:Object;			
			if (fHistoryFile) {
				obUrls = {
					baseurl: itemInfo.id + "/baseimage",	
					thumbnailurl: itemInfo.id + "/thumb320",
					sourceurl: itemInfo.id + "/render"
				}
				if ("render:format" in dctProps)
					obUrls['sourceurl'] += "." + dctProps['render:format'];
				
				PicnikFile.GetThumbUrls(itemInfo.id, obUrls);
			} else {
				switch (itemInfo.species) {
				case "pik":
					itemInfo.pikid = dctProps.nFileId;
					obUrls = {
	//					baseurl: itemInfo.id + "/mypicnik:baseimage",	
						thumbnailurl: itemInfo.id + "/thumb320",
						sourceurl: itemInfo.id + "/render"
					}
					if ("render:format" in dctProps)
						obUrls["sourceurl"] += "." + dctProps["render:format"];
					
					PicnikFile.GetThumbUrls(itemInfo.id, obUrls);
					break;
					
				case "gallery":
					obUrls = {
						thumbnailurl: itemInfo.id + "/preview/thumb320" + "?v=" + itemInfo.version,
						sourceurl: itemInfo.id + "?v=" + itemInfo.version
					}					
					break;
				
				case "greeting":
					obUrls = {
						thumbnailurl: itemInfo.id + "_" + itemInfo.secret + "/thumb320",
						sourceurl: itemInfo.id + "_" + itemInfo.secret
					}
					break;
				
				case "image":
				default:
					// The fid we have is a pointer to an existing image file. This flag tells downloading
					// bridges (StorageServiceInBridgeBase) to use a clone of this fid.
					itemInfo.fUseExistingFid = true;
					obUrls = {
						thumbnailurl: itemInfo.id + "/thumb320",
						sourceurl: itemInfo.id
					}
					break;
				}
			}
			
			for (var strKey:String in obUrls) {
				if (typeof(obUrls[strKey]) == "undefined")
					continue;
					
				var strPath:String = "file/" + obUrls[strKey];
				if (obSignUrls is String) {
					var strSignUrls:String = obSignUrls as String;
					if (strPath.indexOf("?") != -1 && strSignUrls.indexOf("?") != -1) {
						strSignUrls = strSignUrls.replace("?", "&");
					}
					strPath += strSignUrls;
				} else if (obSignUrls is Function) {
					strPath += obSignUrls(strPath);
				}
				itemInfo[strKey] = PicnikService.serverURL + "/" + strPath;
			}
			
			AddWebpageUrl(itemInfo);
			AddEmbedUrl(itemInfo);

			return itemInfo;
		}
			
		private static function AddWebpageUrl( itemInfo:ItemInfo ):void {
			var strId:String = itemInfo.id;
			if (itemInfo.serviceid == "Show") {
				if ('secret' in itemInfo && itemInfo.secret && itemInfo.secret.length > 0)
					strId += '_' + itemInfo.secret;
				itemInfo.webpageurl = PicnikService.serverURL + "/show/id/" + strId;
				if ('title' in itemInfo) { 					
					var strTitle:String = itemInfo.title.toLowerCase();
					strTitle = strTitle.replace( /[^a-z0-9\s-]/g, "" );
					strTitle = strTitle.replace( /\s+/g, " " );
					strTitle = strTitle.replace( /\s/g, "-" );				
					itemInfo.webpageurl += "/t/" + strTitle;
				}
			}
			else if (itemInfo.serviceid == "Greeting") {
				if ('secret' in itemInfo && itemInfo.secret && itemInfo.secret.length > 0)
					strId += '_' + itemInfo.secret;
				itemInfo.webpageurl = PicnikService.serverURL + "/greeting/" + strId;
			}
		}	

		private static function AddEmbedUrl( itemInfo:ItemInfo ):void {
			if (itemInfo.serviceid == "Show") {
				var strId:String = itemInfo.id;
				if ('secret' in itemInfo && itemInfo.secret && itemInfo.secret.length > 0) {
					strId += '_' + itemInfo.secret;
				}
				itemInfo.embedCode =
					'<div style="width:WIDTHpx;font:0.7em \'Trebuchet MS\',sans-serif; ">'+
					'<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0" '+
					'width="WIDTH" height="HEIGHT"><param name="FlashVars" value="galleryid='+strId+'"/>'+
					'<param name="allowFullScreen" value="true"/><param name="allowscriptaccess" value="always"/><param name="wmode" value="transparent"/>'+
					'<param name="movie" value="'+PicnikService.serverURL+'/slide/slide.swf"/><embed src="'+PicnikService.serverURL+'/slide/slide.swf" width="WIDTH" height="HEIGHT" wmode="transparent" allowScriptAccess="always" FlashVars="galleryid='+strId+'">'+
					'</embed></object>'+
					'<div style="float:left"><a href="'+itemInfo.webpageurl+'">&quot;<b>'+itemInfo.title+'</b>&quot;</a></div>'+					
					'<div style="float:right"><a href="http://www.mywebsite.com" target="_blank">Create a free slideshow with Picnik!</a></div></div>';
			}
		}	
			
		// Not every ItemInfo property makes sense to save for later reuse. These are the ones that do.
		//
		// Guidelines:
		// - preserve properties that may be valid across services
		// - don't preserve properties unique to a service (e.g. id, setid, ownerid)
		// - when saving to Picnik.com, source properties may be preserved iteminfo:source_id,
		//   iteminfo:source_setid, iteminfo:source_serviceid
		// UNDONE: serviceid?
		private static var s_astrLastingProps:Array = [
			"id", "setid", "serviceid", "filename", "title", "description", "tags", "ownerid",
			"flickr_ispublic", "flickr_isfriend", "flickr_isfamily", "history_serviceid"
		]

		public static function GetLastingItemInfo(itemInfo:ItemInfo): ItemInfo {
			var itemInfoRet:ItemInfo = new ItemInfo();
			for each (var strProp:String in s_astrLastingProps) {
				// Only return initialized properties since these will be persisted and there's no point
				// wasting space on undefined props.
				if (itemInfo[strProp] != undefined)
					itemInfoRet[strProp] = itemInfo[strProp];
			}
			
			return itemInfoRet;
		}
		
		public static function GetPerfectMemoryFid(strServiceId:String, strServiceImageId:String, strEtag:String,
				fnOnComplete:Function): void {
			var fnOnGetFileList:Function = function (err:Number, strError:String, adctProps:Array=null): void {
				if (err != PicnikService.errNone || adctProps == null) {
					fnOnComplete(err, strError, null);
					return;
				}
				
				var itemInfo:ItemInfo = ItemInfoFromPicnikFileProps(adctProps[0]);
				fnOnComplete(err, strError, itemInfo.id, itemInfo.assetmap);
			}
			
			var strName:String = strServiceId + "_" + strServiceImageId + (strEtag ? "etag" + strEtag : "");
			PicnikService.GetFileList('strName LIKE "' + strName + '%", strType="perfectmem"', null, null, 0, 1, null, false, fnOnGetFileList);
		}
	}
}
