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
	import imagine.ImageDocument;
	import util.IRenderStatusDisplay;
	
	// UNDONE: Hierarchical storage
	// All dates (createddate, last_update) are Numbers in milliseconds since midnight January 1, 1970, universal time
	public interface IStorageService {
		// Returns a dictionary filled with information about the storage service (ServiceInfo).
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - id (req) -- a computer-readable globally unique id for the service
		// - name (opt) -- a human readable name for the service
		// - create_sets (opt) -- whether or not sets can be created within the store [UNDONE: should be a StoreInfo field]
		// - set_descriptions (opt) -- whether or not the service's sets contain a description field [UNDONE: should be a StoreInfo field]
		// - login_lifetime (opt) -- in seconds, how long a session lasts before it logs out
		// - has_rotated_originals
		// - visible -- ?
		//
		// UNDONE: how to keep evildoers from spoofing other services? GUID?
		function GetServiceInfo(): Object;
		
		// Authorize will navigate the user away to a third-party authentication page.
		// If navigation is disabled or we were otherwise unable to kick off the
		// authentication process, then this function will return false.  Otherwise: true.
		//
		// fnComplete(err:Number, strError:String, strUserId:String=null, strToken:String=null)
		function Authorize(strPerm:String=null, fnComplete:Function=null): Boolean;

		// Authorize will navigate the user away to a third-party authentication page.
		// If navigation is disabled or we were otherwise unable to kick off the
		// authentication process, then this function will return false.  Otherwise: true.
		// fnComplete: function OnCallbackComplete(): void;
		function HandleAuthCallback(obParams:Object, fnComplete:Function): void;
		
		// Log the user in. It is assumed the lifetime is infinite unless GetServiceInfo()
		// specifies a login_lifetime property.
		//
		// fnComplete(err:Number, strError:String)
		// - None
		// - IOError
		// - InvalidUserOrPassword
		//
		// fnProgress(nPercent:Number)
		
		function LogIn(tpa:ThirdPartyAccount, fnComplete:Function, fnProgress:Function=null): void;
		
		// Log the user out.
		//
		// fnComplete(err:Number, strError:String)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)

		function LogOut(fnComplete:Function=null, fnProgress:Function=null): void;
		
		function IsLoggedIn(): Boolean;
		
		// Returns a dictionary filled with information about the logged in user (UserInfo).
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - username (req)
		// - fullname (opt)
		// - thumbnailurl (opt)
		// - webpageurl (opt)
		// - is_pro (opt)
		//
		// fnComplete(err:Number, strError:String, dctUserInfo:Object=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		
		function GetUserInfo(fnComplete:Function, fnProgress:Function=null): void;
		
		function SetUserInfo(dctUserInfo:Object, fnComplete:Function, fnProgress:Function=null): void;
				
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

		function GetFriends(fnComplete:Function, fnProgress:Function=null): void;
						
		// Returns a dictionary filled with information about the service's item store (StoreInfo).
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - itemcount (opt)
		// - setcount (opt)
		//
		// It is assumed that there is only one store per service.
		//
		// fnComplete(err:Number, strError:String, dctStoreInfo:Object=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		
		function GetStoreInfo(fnComplete:Function, fnProgress:Function=null): void; // dctStoreInfo
		
		function SetStoreInfo(dctStoreInfo:Object, fnComplete:Function, fnProgress:Function=null): void;
		
		// Returns an array of dictionaries filled with information about the sets (SetInfos).
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// strUsername is optional.  If null, return sets for the currently logged in user
		//
		// - id (req)
		// - itemcount (req)
		// - title (opt)
		// - description (opt)
		// - thumbnailurl (opt)
		// - webpageurl (opt)
		// - last_update (opt)
		// - createddate (opt)
		// - readonly (opt)
		// - child_sets (opt) -- returned from GetSets/GetSetInfo if the set is allowed to have children
		// - parent_id (opt) -- only used with CreateSet, if supported
		// -
		//
		// fnComplete(err:Number, strError:String, adctSetInfo:Array=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		
		// UNDONE: strUsername should be strUserId?
		function GetSets(strUsername:String, fnComplete:Function, fnProgress:Function=null): void; // adctSetInfo
		
		function CreateSet(dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void; // dctSetInfo
		
		function DeleteSet(strSetId:String, fnComplete:Function, fnProgress:Function=null): void;
		
		// Returns a dictionary filled with information about the set (SetInfo).
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
		
		function GetSetInfo(strSetId:String, fnComplete:Function, fnProgress:Function=null): void; // dctSetInfo
		
		function SetSetInfo(strSetId:String, dctSetInfo:Object, fnComplete:Function, fnProgress:Function=null): void; //
		
		function DeleteItem(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void;
		
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
		
		function CreateItem(strSetId:String, strItemId:String, itemInfo:ItemInfo, imgd:ImageDocument,
				fnComplete:Function, irsd:IRenderStatusDisplay=null): void;
		
		// Creates a new gallery and returns a dictionary with details about it. CreateGallery is highly
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
		
		function CreateGallery(strSetId:String, gald:GalleryDocument, fnComplete:Function, irsd:IRenderStatusDisplay=null): void;
		
		// Returns a dictionary filled with information about the item (ItemInfo).
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - id (req)
		// - sourceurl (req)
		// - serviceid (req)
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
		//
		// fnComplete(err:Number, strError:String, itemInfo:ItemInfo=null)
		// - None
		// - IOError
		// - NotLoggedIn
		// - ItemNotFound
		//
		// fnProgress(nPercent:Number)
		
		function GetItemInfo(strSetId:String, strItemId:String, fnComplete:Function, fnProgress:Function=null): void; // itemInfo
		
		function SetItemInfo(strSetId:String, strItemId:String, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void;
		
		// Returns an array of dictionaries filled with information about the items (ItemInfos, see GetItemInfo).
		// apartialItemInfos is an array of item infos with (at a minimum) the .id field set.  Some storage services
		// may require additional information.
		//
		// fnComplete(err:Number, strError:String, aitemInfos:Array=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		
		function GetItemInfos(apartialItemInfos:Array, fnComplete:Function, fnProgress:Function=null): void;
		
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
		
		function GetItems(strSetId:String, strSort:String, strFilter:String, nStart:Number, nCount:Number, fnComplete:Function, fnProgress:Function=null): void;
		
		// Posts additional meta information to the service indicating that the
		// user has taken the given action.
		// This is used, for example, to post notices to a Facebook user's news feed
		// strAction should always be "CreateItem".  Other values are unsupported
		// UNDONE: define standardized action types
		
		function NotifyOfAction(strAction:String, imgd:ImageDocument, itemInfo:ItemInfo, fnComplete:Function, fnProgress:Function=null): void;
		
		// ProcessServiceParams
		// does storage-service-specific processing of parameters that were given to us
		// via the an invocation of Picnik As Service.
		//
		// dctParams contains all service params, some of which may begin with _ss. 
		// Some typical examples, all optional:
		//	- _ss_item_id
		//  - _ss_user_id
		//  - _ss_set_id
		//  - _ss_cmd
		//
		// fnComplete(err:Number, strError:String, dctResult:Array=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// 	dctResult contains
		//		- load (optional) -- contains an imageproperties object describing an image to load
		//		- ss (req) -- the storage service object
		//
		// fnProgress(nPercent:Number)

		function ProcessServiceParams(dctParams:Object, fnComplete:Function, fnProgress:Function=null): void;
		
		// Given a storage service-specific resource id, return a URL that can be used to request
		// the resource. This is currently being used by the YahooMailStorageService to incorporate
		// unexpired credentials into the URL. The storage service returns specially-protocoled
		// URLs as sourceurls (e.g. ss:{serviceid}?{resourceid}) and consumers of sourceurls know to
		// resolve them via GetResourceURL before use. The StorageServcieRegistry facilitates this.
		
		function GetResourceURL(strResourceId:String): String;
		
		// Most storage services can only do processing if we we're auth'd to the third party, but
		// sometimes an extra (user-driven) step is required before auth can happen.  If the storage
		// service is waiting for auth to happen before doing some processing, this function will return
		// true.  Bridges that are interested can ping this function and prompt the user to connect. 
		function WouldLikeAuth():Boolean;
	}
}
