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
package bridges.yahoomail
{
	import bridges.storageservice.StorageServiceError;
	
	import flash.events.EventDispatcher;
	
	import mx.core.Application;
	
	/*** YahooMailFolder
	 * This class is used to control access to items within a specific Yahoo Mail folder.
	 * The IDs used should be unique - e.g. UserID + Folder name
	 */
	public class YahooMailFolder extends EventDispatcher
	{
		// ID related
		private var _strSetId:String;
		private var _strYahooToken:String;
		private var _strSort:String;
		private var _strFilter:String;

		// State
		private var _aitemInfoCache:Array = [];
		private var _fFullyPopulated:Boolean = false;
		private var _fActive:Boolean = false; // Only one active folder a time. Inactive folders stop looking deeper (return immediately?)
		private var _obPendingGetItemRequest:Object = null;
		
		// Bindable state for UI
		[Bindable] public var cMessagesScanned:Number = 0;
		[Bindable] public var cImagesFound:Number = 0;
		
		// Parent objects
		private var _ymp:YahooMailProxy;
		private var _ymss:YahooMailStorageService;
		
		// Statics
		private static var _obFolders:Object = {}; // Folder cache
		private static var _obMessageCache:Object = {}; // To make reset more efficient
		private static var _ymfActive:YahooMailFolder = null;

		private static function GetUniqueFolderId(strSetId:String, strSort:String, strFilter:String, strYahooToken:String): String {
			// Use a character not allowed in a set/user name to join the two
			return strSort + "@" + strFilter + "@" + strYahooToken + "@" + strSetId;
		}
		
		public static function GetFolder(strSetId:String, strSort:String, strFilter:String, strYahooToken:String, ymss:YahooMailStorageService): YahooMailFolder {
			var strId:String = GetUniqueFolderId(strSetId, strSort, strFilter, strYahooToken);
			if (!(strId in _obFolders))
				_obFolders[strId] = new YahooMailFolder(strSetId, strSort, strFilter, strYahooToken, ymss);
				
			return _obFolders[strId];
		}
		
		// YahooMailFolder.GetFolder() should be the only function which calls this
		public function YahooMailFolder(strSetId:String, strSort:String, strFilter:String, strYahooToken:String, ymss:YahooMailStorageService)
		{
			_ymss = ymss;
			_ymp = ymss.GetProxy();
			_strSetId = strSetId;
			_strYahooToken = strYahooToken;
			_strSort = strSort;
			_strFilter = strFilter;
			Reset();
		}
		
		public override function toString(): String {
			return "YMF[" + _strSetId + ", " + _fActive + ", " + _obPendingGetItemRequest + "]";
		}
		
		public static function SetActive(ymf:YahooMailFolder): void {
			if (_ymfActive == ymf) return;
			if (_ymfActive != null)
				_ymfActive.active = false;
			_ymfActive = ymf;
			if (_ymfActive != null)
				_ymfActive.active = true;
		}
		
		public function Activate(): void {
			SetActive(this);
		}
		
		private function set active(f:Boolean): void {
			if (_fActive == f) return;
			_fActive = f;
			if (!_fActive) {
				TerminateActiveGetItemsRequest();
			}
		}
		
		public function Reset(): void {
			TerminateActiveGetItemsRequest();
			_aitemInfoCache.length = 0;
			_aitemInfoCache.cmidMax = 0;
			cImagesFound = 0;
			cMessagesScanned = 0;
			_fFullyPopulated = false;
		}
		
		public function GetCache(): Array {
			return _aitemInfoCache;
		}
		
		
		// fnComplete(err:Number, strError:String, adctItemInfo:Array=null)
		// - None
		// - IOError
		// - NotLoggedIn
		
		public function ReadMail(nStart:Number, nCount:Number, fnComplete:Function): void {
			// If we have cached results to return, return them.
			if (_fFullyPopulated || (nStart + nCount) <= _aitemInfoCache.length) {
				Application.application.callLater(fnComplete, [ StorageServiceError.None, null, _aitemInfoCache.slice(nStart, nStart + nCount) ]);
				return;
			}
			
			// Not enough in the cache and we aren't done yet. Start digging.
			TerminateActiveGetItemsRequest(); // Make sure there are no other outstanding requests
			_obPendingGetItemRequest = {fTerminated:false, fnComplete:fnComplete, nStart:nStart, nCount:nCount};
			GetItems(_obPendingGetItemRequest);
		}
		
		private function TerminateActiveGetItemsRequest(): void {
			if (_obPendingGetItemRequest == null) return;
			if (_obPendingGetItemRequest.fTerminated) return;
			_obPendingGetItemRequest.fTerminated = true;
			_obPendingGetItemRequest.fnComplete(StorageServiceError.None, null, _aitemInfoCache.slice(_obPendingGetItemRequest.nStart, _obPendingGetItemRequest.nStart + _obPendingGetItemRequest.nCount));
			_obPendingGetItemRequest = null;
		}
		
		private function GetMidCacheKey(mid:String): String {
			return _strYahooToken + ": " + mid;
		}
		
		private function ResetMidCache(mid:String): void {
			_obMessageCache[GetMidCacheKey(mid)] = [];
		}
		
		private function AddToMidCache(mid:String, itemInfo:ItemInfo): void {
			_obMessageCache[GetMidCacheKey(mid)].push(itemInfo);
		}
		
		private function GetItems(obRequest:Object): void {
			// OK, this is a little exciting. What we are doing here is:
			// 1. ListMessages (no filtering, even messages that don't have 'official' attachments have embedded image "parts")
			// 2. GetMessage all of them so we can look inside for "parts"
			// 3. Create ItemInfos for all message parts of type "image"
			var strSort:String = (_strSort == null) ? "date" : _strSort;
			
			var imidStart:int = _aitemInfoCache.cmidMax;
			const kcmidBatch:int = 80; // Get 80 messages at a time
			const kctmiMax:int = 1000; // Only look for 1000 images (more takes too long)
			
			var fnGetMoreMessages:Function = function (): void {
				try {
					var fnOnListMessages:Function = function (err:Number, strError:String, obResponse:Object, obContext:Object): void {
						if (obRequest.fTerminated) return;
						
						// HACK: Yahoo can surprise us with API flakiness. The best thing we can do is to just ignore
						// these errors, skip the batch of messages involved, and keep going.
						if (err == StorageServiceError.Unknown || err == StorageServiceError.InvalidServiceResponse) {
							imidStart += kcmidBatch;
							
							// We have no way of knowing how many messages are left to ask for. This ListMessages may have been
							// for the last valid range of messages we can request or there may be thousands left. Stop at 1000
							// messages to avoid spinning forever.
							if (imidStart >= 1000) {
								_fFullyPopulated = true;
								if (_obPendingGetItemRequest == obRequest) _obPendingGetItemRequest = null;
								obRequest.fnComplete(StorageServiceError.None, null, _aitemInfoCache.slice(obRequest.nStart, obRequest.nStart + obRequest.nCount));
								return;
							}
							fnGetMoreMessages();
							return;
						}
						
						if (err != StorageServiceError.None || obResponse == null) {
							if (_obPendingGetItemRequest == obRequest) _obPendingGetItemRequest = null;
							obRequest.fnComplete(err, strError);
							return;
						}
						
						try {
							var cmid:int = obResponse.result.messageInfo.length;
							imidStart += cmid;
							
							var adctMidRequests:Array = [];
							for each (var obMessageInfo:Object in obResponse.result.messageInfo)
								if (obMessageInfo.size > 20000)
									adctMidRequests.push({ mid: obMessageInfo.mid, blockImages: "none" });
								
							if (adctMidRequests.length == 0) {
								if (cmid < kcmidBatch) {
									_fFullyPopulated = true;
									if (_obPendingGetItemRequest == obRequest) _obPendingGetItemRequest = null;
									obRequest.fnComplete(StorageServiceError.None, null, _aitemInfoCache.slice(obRequest.nStart, obRequest.nStart + obRequest.nCount));
								} else {
									fnGetMoreMessages();
								}
								return;
							}
							
							// Extract the mid requests not in the cache
							var adctMidRequestsNotInCache:Array = [];
							var obMessageRequest:Object;
							for each (obMessageRequest in adctMidRequests)
								if (!(GetMidCacheKey(obMessageRequest.mid) in _obMessageCache))
									adctMidRequestsNotInCache.push(obMessageRequest);

							var fnOnGetMessage:Function = function (err:Number, strError:String, obResponse:Object, obContext:Object): void {
								if (obRequest.fTerminated) return;
								try {
									// HACK: Once again Yahoo may surprise us with API flakiness. The best thing we can do is to just ignore
									// these errors, skip the batch of messages involved, and keep going.
									if (err == StorageServiceError.Unknown || err == StorageServiceError.InvalidServiceResponse) {
										// UNDONE: will skipping a batch of messages screw up the cache?
										fnGetMoreMessages();
										return;
									}
									
									if (err != StorageServiceError.None || obResponse == null) {
										if (_obPendingGetItemRequest == obRequest) _obPendingGetItemRequest = null;
										obRequest.fnComplete(err, strError);
										return;
									}
									_aitemInfoCache.cmidMax += cmid;
									cMessagesScanned = _aitemInfoCache.cmidMax;
									
									// Now, put our results in the cache
									var itemInfo:ItemInfo;
									for each (var dctMessage:Object in obResponse.result.message) {
										ResetMidCache(dctMessage.mid);
										for each (var dctPart:Object in dctMessage.part) {
											// I am seeing a lot of useless little white image attachments, e.g. "~WRD132.jpg" and
											// small white spacer gifs. Filter them out.
											if (dctPart.size < 1024)
												continue;
												
											if (dctPart.type == "image" ||
													// Some image attachments are typed as "application"!
													(dctPart.type == "application" && YahooMailStorageService.IsImageFileType(dctPart.filename))) {
												itemInfo = _ymss.ItemInfoFromMessagePart(dctMessage, dctPart, _strSetId);
												AddToMidCache(dctMessage.mid, itemInfo);
												// Don't add them yet - see the next loop
											}
										}
									}
									
									// next, get all of our items from the cache
									for each (obMessageRequest in adctMidRequests) {
										var aItemInfos:Array = _obMessageCache[GetMidCacheKey(obMessageRequest.mid)];
										for each (itemInfo in aItemInfos) {
											_aitemInfoCache.push(itemInfo);
											cImagesFound = _aitemInfoCache.length;
										}
									}
									
									// If fewer messages than requested were returned (EOM) or we've reached our cache
									// limit, mark the cache as fully populated.
									if (cmid < kcmidBatch || _aitemInfoCache.length >= kctmiMax)
										_fFullyPopulated = true;
										
									// If we've have the requested items now, return them
									if (_fFullyPopulated || _aitemInfoCache.length >= obRequest.nStart + obRequest.nCount) {
										if (_obPendingGetItemRequest == obRequest) _obPendingGetItemRequest = null;
										obRequest.fnComplete(StorageServiceError.None, null, _aitemInfoCache.slice(obRequest.nStart, obRequest.nStart + obRequest.nCount));
										return;
									} else {
										fnGetMoreMessages();
									}
								} catch (err:Error) {
									YahooMailStorageService.LogYahooMailResponse("YahooMail Exception: OnGetItems: " + err + ", " + err.getStackTrace(), obResponse);
									if (_obPendingGetItemRequest == obRequest) _obPendingGetItemRequest = null;
									obRequest.fnComplete(StorageServiceError.Exception, null);
								}
							}

							if (adctMidRequestsNotInCache.length == 0) {
								Application.application.callLater(fnOnGetMessage, [StorageServiceError.None, null, {result:{message:[]}}, null]);
							} else {
								_ymp.GetMessage({ truncateAt: 1, fid: _strSetId, message: adctMidRequestsNotInCache }, fnOnGetMessage);
							}
						} catch (err:Error) {
							YahooMailStorageService.LogYahooMailResponse("YahooMail Exception: OnGetItems: " + err + ", " + err.getStackTrace(), obResponse);
							if (_obPendingGetItemRequest == obRequest) _obPendingGetItemRequest = null;
							obRequest.fnComplete(StorageServiceError.Exception, null);
						}
					}
					
					_ymp.ListMessages({ fid: _strSetId, sortKey: strSort, sortOrder: "down", // filterBy: { hasAttachment: 1 },
//								startMid: imidStart, numMid: kcmidBatch, startInfo: 0, numInfo: 0 }, fnOnListMessages);
							startMid: 0, numMid: 0, startInfo: imidStart, numInfo: kcmidBatch }, fnOnListMessages);
				} catch (err:Error) {
					PicnikService.LogException("Client exception: YahooMailStorageService.GetItems: ", err);
					if (_obPendingGetItemRequest == obRequest) _obPendingGetItemRequest = null;
					obRequest.fnComplete(StorageServiceError.Exception, null);
				}												
			}
			
			fnGetMoreMessages();
		}
	}
}