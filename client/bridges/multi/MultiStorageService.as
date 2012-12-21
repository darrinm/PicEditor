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

package bridges.multi {
	import bridges.*;
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceBase;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceRegistry;
	
	import imagine.ImageDocument;
	
	import util.IRenderStatusDisplay;
	
	public class MultiStorageService extends StorageServiceBase {			
	
		public function MultiStorageService() {
		}
		
		public function SetMultiItems( adctItemInfos:Object ):void {
			ClearCachedItemInfo();
			for (var i:Number = 0; i < adctItemInfos.length; i++ ) {
				StoreCachedItemInfo( adctItemInfos[i] );
			}
		}
		
		public override function GetServiceInfo(): Object {
			return StorageServiceRegistry.GetStorageServiceInfo("multi");
		}
		
		public override function IsLoggedIn(): Boolean {
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
		
		public override function LogIn(tpa:ThirdPartyAccount, fnComplete:Function, fnProgress:Function=null): void {
			if (fnComplete != null)
				PicnikBase.app.callLater(fnComplete, [StorageServiceError.None, null, {}]);
		}
				
		// Log the user out.
		//
		// fnComplete(err:Number, strError:String)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)

		public override function LogOut(fnComplete:Function=null, fnProgress:Function=null): void {
			if (fnComplete != null)
				PicnikBase.app.callLater(fnComplete, [StorageServiceError.None, null, {}]);
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
			if (fnComplete != null)
				PicnikBase.app.callLater(fnComplete, [StorageServiceError.None, null, {}]);
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
		// strUsername is currenlty ignored
		
		protected override function _GetSets(strUsername:String, fnComplete:Function, fnProgress:Function=null): void {
			var dctSetInfo:Object = {
				title: "Multi",
				itemcount: _aitemInfoCache ? _aitemInfoCache.length : 0,
				id: "Multi"
			}
			fnComplete( StorageServiceError.None, "", [dctSetInfo] );
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
		
		public override function CreateItem(strSetId:String, strItemId:String, itemInfo:ItemInfo, imgd:ImageDocument,
				fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
					
			var ss:IStorageService = AccountMgr.GetStorageService( itemInfo.serviceid );
			ss.CreateItem( strSetId, strItemId, itemInfo, imgd, fnComplete, irsd);
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
		
		protected override function FillItemCache( strSetId:String, strSort:String, strFilter:String, fnComplete:Function, obContext:Object ): void {
			PicnikBase.app.callLater(fnComplete, [StorageServiceError.None, null, obContext]);
			// do nothing... the cache is filled up front
		}
		
		protected override function UpdateItemCache( strSetId:String, strItemId:String, fnComplete:Function, obContext:Object ): void {
			var itemInfo:ItemInfo = FindCachedItemInfo(strItemId);
			if (itemInfo) {				
				if ('serviceid' in itemInfo && itemInfo['serviceid'].length > 0) {
					// ask the service to get more info about this guy.
					var ss:IStorageService = AccountMgr.GetStorageService( itemInfo.serviceid );
					ss.GetItemInfo( strSetId, strItemId,
						function(err:Number, strError:String, itemInfo:ItemInfo=null):void {
							if (err==StorageServiceError.None) {
								UpdateCachedItemInfo( itemInfo );
							}
							fnComplete( StorageServiceError.None, null, obContext );
						});
					return;	
				}
			}
			PicnikBase.app.callLater(fnComplete, [StorageServiceError.None, null, obContext]);
		}
		
		public override function GetFriends(fnComplete:Function, fnProgress:Function=null): void {
			PicnikBase.app.callLater( fnComplete, [StorageServiceError.Unknown, null]);
		}	
	}
}
