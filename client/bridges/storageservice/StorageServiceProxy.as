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
	
	import util.IProxyHandle;
	import util.IRenderStatusDisplay;
	import util.ModLoader;
	
	public class StorageServiceProxy implements IStorageService, IProxyHandle {

		private var _ss:IStorageService;
		private var _obInfo:Object;
		private var _ldr:ModLoader;
		private var _afnCallbacks:Array = [];
		
		static private var s_modules:Object = {};
		
		public function GetProxiedService(): IStorageService {
			return _ss;
		}
		
		public function StorageServiceProxy( obInfo:Object ) {
			_obInfo = obInfo;
		}
		
		public function GetServiceInfo():Object {
			return _obInfo;
		}
		
		public function HandleAuthCallback(obParams:Object, fnComplete:Function): void {
			ProxyStorageServiceCall(
				function():void{ _ss.HandleAuthCallback( obParams, fnComplete ) },
				fnComplete );			
		}
		
		public function GetStoreInfo(fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.GetStoreInfo( fnComplete, fnProgress ) },
				fnComplete );			
		}

		public function GetSets(strUsername:String, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.GetSets( strUsername, fnComplete, fnProgress ) },
				fnComplete );			
		}
				
		public function GetItemInfo(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.GetItemInfo( strSetId, strItemId, fnComplete, fnProgress ) },
				fnComplete );			
		}	

		public function GetItems(strSetId:String, strSort:String, strFilter:String, nStart:Number, nCount:Number, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.GetItems( strSetId, strSort, strFilter, nStart, nCount, fnComplete, fnProgress ) },
				fnComplete );												
		}
			
		public function GetItemInfos(apartialItemInfos:Array, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.GetItemInfos( apartialItemInfos, fnComplete, fnProgress ) },
				fnComplete );												
		}
						
		// BUGBUG(steveler): this function is not asynchronous
		public function Authorize(strPerm:String=null, fnComplete:Function=null): Boolean {
			ProxyStorageServiceCall(
				function():void{ _ss.Authorize( strPerm, fnComplete ) },
				fnComplete );												
			return false;
		}

		public function LogIn(tpa:ThirdPartyAccount, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.LogIn( tpa, fnComplete, fnProgress ) },
				fnComplete );												
		}
		
		public function IsLoggedIn(): Boolean {
			if (!_ss) {
				return false;
			}
			return _ss.IsLoggedIn();
		}
		
		public function LogOut(fnComplete:Function=null, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.LogOut( fnComplete, fnProgress ) },
				fnComplete );												
		}
		
		public function GetUserInfo(fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.GetUserInfo( fnComplete, fnProgress ) },
				fnComplete );												
		}
			
		public function SetUserInfo(dctUserInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.SetUserInfo( dctUserInfo, fnComplete, fnProgress ) },
				fnComplete );												
		}
		
		public function SetStoreInfo(dctStoreInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.SetStoreInfo( dctStoreInfo, fnComplete, fnProgress ) },
				fnComplete );												
		}
		
		public function CreateSet(dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.CreateSet( dctSetInfo, fnComplete, fnProgress ) },
				fnComplete );												
		}
		
		public function DeleteSet(strSetId:String, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.DeleteSet( strSetId, fnComplete, fnProgress ) },
				fnComplete );												
		}
		
		public function GetSetInfo(strSetId:String, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.GetSetInfo( strSetId, fnComplete, fnProgress ) },
				fnComplete );												
		}
		
		public function SetSetInfo(strSetId:String, dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.SetSetInfo( strSetId, dctSetInfo, fnComplete, fnProgress ) },
				fnComplete );												
		}
		
		public function DeleteItem(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.DeleteItem( strSetId, strItemId, fnComplete, fnProgress ) },
				fnComplete );												
		}
		
		public function NotifyOfAction(strAction:String, imgd:ImageDocument, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.NotifyOfAction( strAction, imgd, itemInfo, fnComplete, fnProgress ) },
				fnComplete );												
		}
		
		// BUGBUG(steveler): this function is not asynchronous
		public function ProcessServiceParams(dctParams:Object, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.ProcessServiceParams( dctParams, fnComplete, fnProgress ) },
				fnComplete );												
		}				

		public function CreateItem(strSetId:String, strItemId:String, itemInfo:ItemInfo, imgd:ImageDocument, fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.CreateItem( strSetId, strItemId, itemInfo, imgd, fnComplete, irsd ) },
				fnComplete );												
		}

		public function CreateGallery(strSetId:String, gald:GalleryDocument, fnComplete:Function, irsd:IRenderStatusDisplay=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.CreateGallery( strSetId, gald, fnComplete, irsd ) },
				fnComplete );												
		}

		public function SetItemInfo(strSetId:String, strItemId:String, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void {
			ProxyStorageServiceCall(
				function():void{ _ss.SetItemInfo( strSetId, strItemId, itemInfo, fnComplete, fnProgress ) },
				fnComplete );												
		}
		
		public function GetFriends(fnComplete:Function, fnProgress:Function=null): void {			
			ProxyStorageServiceCall(
				function():void{ _ss.GetFriends( fnComplete, fnProgress ) },
				fnComplete );												
		}

		// See IStorageService.GetResourceURL for this method's documentation		
		// BUGBUG(steveler): this function is not asynchronous
		public function GetResourceURL(strResourceId:String): String {
			// Assume that strResourceId is actually a valid URL to the resource.
			return strResourceId;
		}

		// See IStorageService.WouldLikeAuth for this method's documentation		
		// BUGBUG(steveler): this function is not asynchronous
		public function WouldLikeAuth(): Boolean {
			return false;
		}

		private function ProxyStorageServiceCall( ssCall:Function, fnComplete:Function ): void {
			if (!_ss) {
				LoadStorageService( function(nError:Number, strError:String):void {
						if (_ss && nError == StorageServiceError.None) {
							ssCall();
						} else {
							fnComplete( nError, strError );
						}
					});
			} else {
				ssCall();
			}
		}
		
		public function ProxyLoad(ldr:ModLoader): void {
			_ldr = ldr;
			_ldr.LoadSWF( this );
		}
		
		public function ProxyLoaded(obModBridges:Object):void {
			var nError:int = StorageServiceError.None;
			if (obModBridges && 'GetStorageService' in obModBridges) {
				_ss = obModBridges['GetStorageService'](_obInfo.id);
			} else {
				nError = StorageServiceError.Unknown
			}
			
			for (var i:int = 0; i < _afnCallbacks.length; i++) {
				_afnCallbacks[i](nError, null);
			}
			_afnCallbacks = [];
		}
		
		public function get logText():String {
			if (_obInfo) return "StorageServiceProxy." + _obInfo.id;
			return "StorageServiceProxy";
		}		
		
		private function LoadStorageService( fnCallback:Function ): void {
			_afnCallbacks.push(fnCallback);
			if (_obInfo.module in s_modules && s_modules[_obInfo.module]['module'] != null) {
				ProxyLoaded(s_modules[_obInfo.module]['module']);
			} else {
				if (!(_obInfo.module in s_modules) || s_modules[_obInfo.module]['loader'] == null) {
					s_modules[_obInfo.module] = {
						loader: new ModLoader( _obInfo.module, function(obResult:Object):void {
							s_modules[_obInfo.module]['module'] = obResult;
						}),
						module: null
					};
					
				}
				ProxyLoad(s_modules[_obInfo.module]['loader']);
			}
		}
	}
}
