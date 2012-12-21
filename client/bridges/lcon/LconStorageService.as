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
package bridges.lcon {
	import bridges.IStorageService;
	import bridges.StorageServiceError;
	
	import flash.net.LocalConnection;
	
	import imagine.ImageDocument;
	
	// UNDONE: Hierarchical storage
	public class LconStorageService implements IStorageService {
		static private const kstrOutConnection:String = "app#com.picnik.Companion:LconStorageService";
		static private const kstrInConnection:String = "_LconStorageServiceReturn";
		
		private var _lcOut:LocalConnection = new LocalConnection();
		private var _lcIn:LocalConnection = new LocalConnection();
		private var _fLoggedIn:Boolean = false;
		
		// Returns a dictionary filled with information about the storage service.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - id (req) -- a computer-readable globally unique id for the service
		// - name (opt) -- a human readable name for the service
		//
		// UNDONE: how to keep evildoers from spoofing other services? GUID?
		public function GetServiceInfo(): Object {
			return { id: "Lcon", visible: false };
		}
		
		//
		public function Authorize(): Boolean {
			return false;
		}

		public function HandleAuthCallback(obParams:Object, fnComplete:Function): Boolean {
			return false; // Let the server handle it
		}
		
		// Log the user in. It is assumed the lifetime...
		//
		// fnComplete(err:Number, strError:String)
		// - None
		// - IOError
		// - InvalidUserOrPassword
		//
		// fnProgress(nPercent:Number)
		
		public function LogIn(strId:String, strToken:String, fnComplete:Function, fnProgress:Function=null): void {
			_lcIn.client = this;
//			_lcIn.allowDomain("app#com.picnik.Companion");
			_lcIn.allowDomain("*");
			_lcIn.connect(kstrInConnection);
			Call("ConnectInit", null, kstrInConnection);
			
			if (fnComplete != null)
				fnComplete(StorageServiceError.None, null);
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
			fnComplete(StorageServiceError.None, null);
		}
		
		public function IsLoggedIn(): Boolean {
			if (!_fLoggedIn) {
				LogIn(null, null, null);
				_fLoggedIn = true;
			}
			return true;
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
			Call("GetUserInfo", function (dctUserInfo:Object): void {
				fnComplete(StorageServiceError.None, null, dctUserInfo);
			});
		}
		
		public function SetUserInfo(dctUserInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "LconStorageService.SetUserInfo not implemented");
		}
		
		// Returns a dictionary filled with information about the service's item store.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// -
		//
		// It is assumed that there is only one store per service.
		//
		// fnComplete(err:Number, strError:String, dctStoreInfo:Object=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		
		public function GetStoreInfo(fnComplete:Function, fnProgress:Function=null): void {
			fnComplete(StorageServiceError.None, null, new Object());
		}
		
		public function SetStoreInfo(dctStoreInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "LconStorageService.SetStoreInfo not implemented");
		}
		
		// Returns an array of dictionaries filled with information about the sets.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - title (opt)
		// - thumbnailurl (opt)
		//
		// fnComplete(err:Number, strError:String, adctSetInfos:Array=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		//
		// strUsername is currently ignored.
		
		public function GetSets( strUsername:String, fnComplete:Function, fnProgress:Function=null): void {
			Call("GetSets", function (adctSetInfos:Object): void {
				fnComplete(StorageServiceError.None, null, adctSetInfos);
			});
		}
		
		public function CreateSet(dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "LconStorageService.CreateSet not implemented");
		}
		
		public function DeleteSet(strSetId:String, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "LconStorageService.DeleteSet not implemented");
		}
		
		// Returns a dictionary filled with information about the set.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - sort values (opt)
		//
		// fnComplete(err:Number, strError:String, dctStoreInfo:Object=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		
		public function GetSetInfo(strSetId:String, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "LconStorageService.GetSetInfo not implemented");
		}
		
		public function SetSetInfo(strSetId:String, dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "LconStorageService.SetSetInfo not implemented");
		}
		
		public function DeleteItem(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "LconStorageService.DeleteItem not implemented");
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
				fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "LconStorageService.CreateItem not implemented");
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
		//
		// fnComplete(err:Number, strError:String, itemInfo:ItemInfo=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		
		public function GetItemInfo(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "LconStorageService.GetItemInfo not implemented");
		}
		
		public function SetItemInfo(strSetId:String, strItemId:String, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void {
			Debug.Assert(false, "LconStorageService.SetItemInfo not implemented");
		}
		
		// Returns an array of dictionaries filled with information about the items.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - sort values (opt)
		//
		// fnComplete(err:Number, strError:String, adctItemInfos:Array=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		// UNDONE: standard sorts
		
		public function GetItems(strSetId:String, strSort:String, strFilter:String, nStart:Number, nCount:Number, fnComplete:Function, fnProgress:Function=null): void {
			Call("GetItems", function (adctItemInfos:Object): void {
				fnComplete(StorageServiceError.None, null, adctItemInfos);
			}, strSetId, strSort, nStart, nCount);
		}
		
		//
		//
		//
		
		private var _iCall:Number = 0;
		private var _dctPending:Object = new Object();

		private function Call(strFuncName:String, fnComplete:Function=null, ...avArgs:*): void {
			var iCall:Number = -1;	// -1 = don't want fnComplete callback
			if (fnComplete != null) {
				iCall = _iCall++;
				_dctPending[iCall] = fnComplete;
			}
			
			if (avArgs && avArgs.length != 0) {
				avArgs.unshift(iCall);
				avArgs.unshift(strFuncName);
				avArgs.unshift(kstrOutConnection);
				_lcOut.send.apply(_lcOut, avArgs);
//				_lcOut.send.apply(_lcOut, kstrOutConnection, strFuncName, iCall, avArgs);
			} else
				_lcOut.send(kstrOutConnection, strFuncName, iCall);
		}

		public function Return(iCall:Number, avArgs:*=null): void {
			if (iCall == -1)
				return;
			if (_dctPending[iCall]) {
				(_dctPending[iCall] as Function).apply(null, avArgs);
				delete _dctPending[iCall];
			}
		}
	}
}
