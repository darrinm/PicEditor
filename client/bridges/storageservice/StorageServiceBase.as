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

package bridges.storageservice {
	import imagine.ImageDocument;
	
	import util.IRenderStatusDisplay;
	
	public class StorageServiceBase implements IStorageService {
		[ArrayElementType("ItemInfo")] protected var _aitemInfoCache:Array = null;
		private var _afnGetSetsCallbacks:Array = [];
		
		public function HandleAuthCallback(obParams:Object, fnComplete:Function): void {
		}
		
		protected function CommitRenderHistory(obRenderResult:Object, itemInfo:ItemInfo, strSetId:String, fnComplete:Function=null, fTrancateId:Boolean=false): void {
			StorageServiceUtil.CommitRenderHistory(this, obRenderResult, itemInfo, strSetId, fnComplete, fTrancateId);
		}

		public function GetStoreInfo(fnComplete:Function, fnProgress:Function=null): void {
			// Call GetSets and add up the # of photos/album to return { itemcount: <>, setcount: <> }
			var fnOnGetSets:Function = function(err:Number, strError:String, adctSetInfos:Array=null): void {
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

			GetSets(null, fnOnGetSets);
		}

		public function GetSets(strUsername:String, fnComplete:Function, fnProgress:Function=null): void {
			_afnGetSetsCallbacks.push(fnComplete);
			if (_afnGetSetsCallbacks.length == 1) {
				// if there's only one callback in the list (ie., our callback),
				// then there are no outstanding getsets calls and we should launch one
				_GetSets(strUsername, _OnGetSets, fnProgress);
			}
		}

		protected function _GetSets(strUsername:String, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "StorageServiceBase._GetSets not implemented");
			fnComplete(StorageServiceError.Unknown, null, null);
		}
		
		private function _OnGetSets(err:Number, strError:String, adctSetInfo:Array=null): void {
			for each (var fnCallback:Function in _afnGetSetsCallbacks) {
				fnCallback(err, strError, adctSetInfo);
			}
			_afnGetSetsCallbacks = [];
		}
				
		public function GetItemInfo(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void {
			if (null==_aitemInfoCache && null != strSetId) {
				// populate item info cache by calling GetItems
				GetItems(strSetId, null, null, 0, 0,
					function(err:Number, strError:String, aitemInfo:Array=null): void {
						if (!_aitemInfoCache && err == StorageServiceError.None) {
							err = StorageServiceError.Unknown;
							strError = "no StorageServiceError but itemcache isn't initialized";
						}
						
						if (err != StorageServiceError.None) {
							fnComplete(err, strError);
						} else {
							GetItemInfo(strSetId, strItemId, fnComplete, fnProgress);
						}
					}, null);
				return;
			}

			var fnOnUpdateItemCache:Function = function(err:Number, strError:String, obContext:Object=null): void {
				if (err != StorageServiceError.None) {
					obContext.fnComplete(err, strError, null);
					return;
				}
				var itemInfo:ItemInfo = obContext ? FindCachedItemInfo(obContext.id) : null;
				if (itemInfo) {
					obContext.fnComplete(StorageServiceError.None, null, itemInfo);			
				} else if (obContext) {
					obContext.fnComplete(StorageServiceError.ItemNotFound, null, null);
				}
			}

			var itemInfo:ItemInfo = FindCachedItemInfo(strItemId);
			if (itemInfo) {				
				if ('partial' in itemInfo && itemInfo['partial']) {
					// we need to ask for complete item info
					UpdateItemCache(strSetId, strItemId, fnOnUpdateItemCache, {id:strItemId, fnComplete:fnComplete});
				} else {
					PicnikBase.app.callLater(fnComplete,
							[StorageServiceError.None, null, itemInfo]);
				}
			} else {
				// try to find this item
				UpdateItemCache(strSetId, strItemId, fnOnUpdateItemCache, {id:strItemId, fnComplete:fnComplete});
			}
		}	

		public function GetItems(strSetId:String, strSort:String, strFilter:String, nStart:Number, nCount:Number, fnComplete:Function, fnProgress:Function=null): void {
			try {
				if (nStart == 0 || _aitemInfoCache == null) {
					var fnOnFillItemCache:Function = function(err:Number, strError:String, obContext:Object = null): void {
						if (null == _aitemInfoCache) _aitemInfoCache = [];			
						if (obContext && obContext.fnComplete)
							obContext.fnComplete(err, strError, _aitemInfoCache);
					}
		
					FillItemCache(strSetId, strSort, strFilter, fnOnFillItemCache, {fnComplete:fnComplete, fnProgress:fnProgress });
				} else {
					PicnikBase.app.callLater(fnComplete, [ StorageServiceError.None, null, _aitemInfoCache.slice(nStart, nStart + nCount) ]);
				}
			} catch (err:Error) {
				PicnikService.LogException("Client exception: StorageServiceBase.GetItems", err);
			}												
		}
		
		protected function FillItemCache(strSetId:String, strSort:String, strFilter:String, fnComplete:Function, obContext:Object): void {
			Debug.Assert(false, "StorageServiceBase.FillItemCache is not implemented");
			fnComplete(StorageServiceError.Unknown, "", obContext);
		}
			
		public function GetItemInfos(apartialItemInfos:Array, fnComplete:Function, fnProgress:Function=null): void {
			try {
				var fnOnFillItemCache2:Function =  function(err:Number, strError:String, obContext:Object = null): void {
					if (null == _aitemInfoCache) _aitemInfoCache = [];			
					if (obContext && obContext.fnComplete)
						obContext.fnComplete(err, strError, _aitemInfoCache);
				}
				FillItemCache2(apartialItemInfos, fnOnFillItemCache2, {fnComplete:fnComplete, fnProgress:fnProgress });
			} catch (err:Error) {
				PicnikService.LogException("Client exception: StorageServiceBase.GetItemInfos", err);
			}												
		}
				
		protected function FillItemCache2(aitemInfos:Array, fnComplete:Function, obContext:Object): void {
			// UNDONE: create a default implementation that fills out the data by calling GetItemInfo on each item
			Debug.Assert(false, "StorageServiceBase.FillItemCache2 is not implemented");
			fnComplete(StorageServiceError.Unknown, "", obContext);
		}

		protected function UpdateItemCache(strSetId:String, strItemId:String, fnComplete:Function, obContext:Object): void {
			Debug.Assert(false, "StorageServiceBase.UpdateItemCache is not implemented");
			fnComplete(StorageServiceError.Unknown, "", obContext);
		}

		// methods for managing the cached item info
		protected function FindCachedItemInfo(strItemId:String):ItemInfo {
			if (!_aitemInfoCache) return null;
			for (var i:Number = 0; i < _aitemInfoCache.length; i++) {
				if (_aitemInfoCache[i].id == strItemId) {
					return _aitemInfoCache[i];
				}
			}
			return null;
		}	

		protected function UpdateCachedItemInfo(itemInfo:ItemInfo): void {
			if (!_aitemInfoCache) _aitemInfoCache = [];
			for (var i:Number = 0; i < _aitemInfoCache.length; i++) {
				if (_aitemInfoCache[i].id == itemInfo.id) {
					_aitemInfoCache[i] = itemInfo;
					return;
				}
			}
			_aitemInfoCache.push(itemInfo);
		}	
		
		protected function StoreCachedItemInfo(itemInfo:ItemInfo): void {
			if (!_aitemInfoCache) _aitemInfoCache = [];
			_aitemInfoCache.push(itemInfo);
		}
				
		protected function ClearCachedItemInfo(): void {
			_aitemInfoCache = null;
		}
		
		protected function InitCachedItemInfo(): void {
			ClearCachedItemInfo();
			_aitemInfoCache = [];			
		}
				
		// The rest of these functions are stubbed out.
		// This just saves you time so that you don't need to implement them,
		// although you probably do want to override some of these.
		public function GetServiceInfo(): Object {
			Debug.Assert(false, "StorageServiceBase.GetServiceInfo is not implemented");
			return {};
		}
		
		public function Authorize(strPerm:String=null, fnComplete:Function=null): Boolean {
			Debug.Assert(false, "StorageServiceBase.Authorize is not implemented");
			return false;
		}

		public function LogIn(tpa:ThirdPartyAccount, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "StorageServiceBase.LogIn is not implemented");
		}
		
		public function IsLoggedIn(): Boolean {
			Debug.Assert(false, "StorageServiceBase.IsLoggedIn is not implemented");
			return false;
		}
		
		public function LogOut(fnComplete:Function=null, fnProgress:Function=null): void {
			Debug.Assert(false, "StorageServiceBase.LogOut is not implemented");
		}
		
		public function GetUserInfo(fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "StorageServiceBase.GetUserInfo is not implemented");
		}
			
		public function SetUserInfo(dctUserInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "StorageServiceBase.SetUserInfo not implemented");
		}
		
		public function SetStoreInfo(dctStoreInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "StorageServiceBase.SetStoreInfo not implemented");
		}
		
		public function CreateSet(dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "StorageServiceBase.CreateSet not implemented");
		}
		
		public function DeleteSet(strSetId:String, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "StorageServiceBase.DeleteSet not implemented");
		}
		
		public function GetSetInfo(strSetId:String, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "StorageServiceBase.GetSetInfo not implemented");
		}
		
		public function SetSetInfo(strSetId:String, dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "StorageServiceBase.SetSetInfo not implemented");
		}
		
		public function DeleteItem(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "StorageServiceBase.DeleteItem not implemented");
		}
		
		public function NotifyOfAction(strAction:String, imgd:ImageDocument, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "StorageServiceBase.NotifyOfAction not implemented");
		}
		
		public function ProcessServiceParams(dctParams:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "StorageServiceBase.ProcessServiceParams not implemented");
			fnComplete(StorageServiceError.None, null, {} );																
		}				

		public function CreateItem(strSetId:String, strItemId:String, itemInfo:ItemInfo, imgd:ImageDocument, fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
			Debug.Assert(false, "StorageServiceBase.CreateItem not implemented");
		}

		public function CreateGallery(strSetId:String, gald:GalleryDocument, fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
			Debug.Assert(false, "StorageServiceBase.CreateGallery not implemented");
		}

		public function SetItemInfo(strSetId:String, strItemId:String, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "StorageServiceBase.SetItemInfo not implemented");
		}
		
		public function GetFriends(fnComplete:Function, fnProgress:Function=null): void {			
			fnComplete(StorageServiceError.Unknown, null, null); // default is to return no friends
		}

		// See IStorageService.GetResourceURL for this method's documentation		
		public function GetResourceURL(strResourceId:String): String {
			// Assume that strResourceId is actually a valid URL to the resource.
			return strResourceId;
		}

		// See IStorageService.WouldLikeAuth for this method's documentation		
		public function WouldLikeAuth(): Boolean {
			return false;
		}
	}
}
