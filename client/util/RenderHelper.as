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
package util
{
	import bridges.FileTransferBase;
	import bridges.Uploader;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceUtil;
	
	import com.adobe.crypto.MD5;
	
	import imagine.documentObjects.DocumentStatus;
	
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import imagine.ImageDocument;
	
	import mx.utils.ObjectProxy;
	
	/** RenderParams
	 * This class wraps making render rest calls with the following added benefits:
	 *  - Waits for image document children to load before finishing
	 *  - Returns child load progress
	 *  - Returns error state when the document is invalid or becomes invalid while loading children
	 *  - Provides a typesafe wrapper to calls
	 *
	 * Philosophically, this should be the one place in our code that knows what the parameters
	 * are to a render function and how to wait for needed processing and return status to the caller.
	 *
	 * For type safety, these functions take an optional IRenderState object which receives a render
	 * state string (localized) for display to the user.
	 *
	 * For unification of general render params, use the RenderParams constructor
	 *
	 * For call specific params, use the RenderParams Render/Post/Save instance methods
	 *
	 */
	public class RenderHelper extends EventDispatcher
	{
		private var _imgd:ImageDocument;
		private var _fnDone:Function;
		private var _irsd:IRenderStatusDisplay;
		private var _strDefaultMessage:String;
		
		private static const kstrNoError:String = "No Error";
		
		// Keep track of renders for logging purposes
		// Eventually, we may use this to re-use previous renders
		private static var _obRenderCache:Object = null;
		
		[Bindable] public static var _nForceRenderFailureType:Number = 0; // For debug use. 0 == no failure
		
		// fnDone(err:Number, strError:String, ...): void
		public function RenderHelper(imgd:ImageDocument, fnDone:Function, irsd:IRenderStatusDisplay=null): void
		{
			_imgd = imgd;
			if (_imgd == null) throw new Error("RenderHelper.RenderHelper(): imgd is null");
			_fnDone = fnDone;
			_irsd = irsd;
			if (_irsd)
				_strDefaultMessage = _irsd.message;
		}
		
		// Rerender cases
		private static const RENDER_DUPLICATE:Number = 0;
		private static const RENDER_BIG_SIZE_DOWN:Number = 1;
		private static const RENDER_BIG_SIZE_DOWN_WITH_FORMAT_CHANGE:Number = 2;
		private static const RENDER_SMALL_SIZE_DOWN:Number = 3;
		private static const RENDER_SIZE_UP:Number = 4;
		private static const RENDER_FORMAT_CHANGE:Number = 5;
		
		private static const kastrRerenderNames:Array = [
			"Duplicate",
			"BigSizeDown",
			"BigSizeDownFormatChange",
			"SmallSizeDown",
			"SizeUp",
			"FormatChange"];

		private static const SIZE_IS_LARGER:Number = -1;
		private static const SIZE_IS_SAME:Number = 0;
		private static const SIZE_IS_SMALLER:Number = 1;
		private static const SIZE_IS_MUCH_SMALLER:Number = 2;

		
		private static function CompareSizes(nPrevSize:Number, nNewSize:Number): Number {
			if (nNewSize > nPrevSize) return SIZE_IS_LARGER;
			if (nNewSize == nPrevSize) return SIZE_IS_SAME;
			if (nNewSize > (nPrevSize/2)) return SIZE_IS_SMALLER;
			return SIZE_IS_MUCH_SMALLER;
		}
		
		private static function CompareRenders(obPrevRender:Object, obNewRender:Object): Number {
			var fFormatChange:Boolean = obPrevRender.format != obNewRender.format;
			
			// -1 is larger, 0 is duplicate, 1 is small size down, 2 is large size down
			var nSizeState:Number = Math.min(CompareSizes(obPrevRender.width, obNewRender.width),
					CompareSizes(obPrevRender.height, obNewRender.height));
			
			if (fFormatChange) {
				if (nSizeState == SIZE_IS_MUCH_SMALLER) return RENDER_BIG_SIZE_DOWN_WITH_FORMAT_CHANGE;
				return RENDER_FORMAT_CHANGE;
				// UNDONE: Handle format change from lossless formats (PNG only?)
			}
			// No format change
			if (nSizeState == SIZE_IS_SAME) return RENDER_DUPLICATE;
			if (nSizeState == SIZE_IS_MUCH_SMALLER) return RENDER_BIG_SIZE_DOWN;
			if (nSizeState == SIZE_IS_SMALLER) return RENDER_SMALL_SIZE_DOWN;
			return RENDER_SIZE_UP;
		}
		
		// Urchin log to tack re-render potential
		private static function LogRender(xmlPik:XML, imgd:ImageDocument, oRenderOptions:Object): void {
			/** Log one of:
			 * NoOp: User rendered document with no changes
			 * New render: First time a user rendered this file
			 * BigSizeDown
			 * BigSizeDownWithFormatChange
			 * SmallSizeDown (<50% width/height)
			 * FormatChange
			 * Duplicate
			 * SizeUp
			 **/
			
			// This function should never throw an exception
			try {
				var strRenderId:String = imgd.baseImageFileId + ":" + MD5.hash(String(xmlPik));
				
				if (_obRenderCache == null || _obRenderCache.id != strRenderId) {
					_obRenderCache = {id:strRenderId, aobRenders:[]};
				}
				var aobRenders:Array = _obRenderCache.aobRenders;
				
				var strRenderType:String;
				
				var xmllUndos:XMLList = xmlPik..UndoTransaction;
	
				var strFormat:String = ('format' in oRenderOptions) ? oRenderOptions.format : "jpg";
				strFormat = strFormat.toLowerCase();
				var nWidth:Number = imgd.width;
				var nHeight:Number = imgd.height;
				if ('width' in oRenderOptions && oRenderOptions.width < nWidth) {
					nHeight = Math.round(nHeight * oRenderOptions.width / nWidth);
					nWidth = Math.round(oRenderOptions.width);
				}
				if ('height' in oRenderOptions && oRenderOptions.height < nHeight) {
					nWidth = Math.round(nWidth * oRenderOptions.height / nHeight);
					nHeight = Math.round(oRenderOptions.height);
				}
				
				var obNewRender:Object = {format:strFormat, width:nWidth, height:nHeight};
				
				var fRecordRender:Boolean = true;
				
				var fNoOp:Boolean = (xmllUndos.length() == 0);
				if (fNoOp && aobRenders.length == 0)
					aobRenders.push({format:'jpg', width:imgd.width, height:imgd.height});
				if (aobRenders.length == 0) {
					// New render
					strRenderType = "B/New";
				} else {
					var nRenderType:Number = Number.MAX_VALUE;
					for each (var obPrevRender:Object in aobRenders)
						nRenderType = Math.min(nRenderType, CompareRenders(obPrevRender, obNewRender));
					if (fNoOp) {
						strRenderType = "N/";
					} else if (nRenderType <= RENDER_BIG_SIZE_DOWN_WITH_FORMAT_CHANGE) {
						strRenderType = "A/";
						fRecordRender = false; // If we optimize, we won't be doing this render.
					} else {
						strRenderType = "B/";
					}
					strRenderType += kastrRerenderNames[nRenderType];
				}
				// Record the render
				if (fRecordRender)
					aobRenders.push(obNewRender);
				Util.UrchinLogReport("/Render/" + strRenderType);
			} catch (e:Error) {
				trace("Ignoring exception in RenderHelper.LogRender: " + e + ", " + e.getStackTrace());
			}
		}
		
		private function GetProcessingMessage(nChildrenLeft:Number, nChildrenTotal:Number): String {
			return LocUtil.GetProcessingMessage(nChildrenLeft, nChildrenTotal);
		}
		
		private function SetStatusMessageToWorking(): void {
			if (_strDefaultMessage == null || _strDefaultMessage.length == 0) {
				renderStatusMessage = LocUtil.GetProcessingMessage();
			} else {
				renderStatusMessage = _strDefaultMessage;
			}
		}
		
		public function GetRenderThrough(oRenderOptions:Object = null, strHistoryServiceId:String=null): URLRequest {
			if (oRenderOptions == null) oRenderOptions = {};
			oRenderOptions.responseFormat = "redirect"; // Expecting the response as a photo
			return GetCallThrough("renderpik", oRenderOptions, strHistoryServiceId);
		}

		private function AddHistory(oRenderOptions:Object, strHistoryServiceId:String=null): void {
			if (oRenderOptions == null) return;
			if (strHistoryServiceId == null) return;
			try {
				
				oRenderOptions["history:serviceid"] = strHistoryServiceId;
				var itemInfo:ItemInfo = StorageServiceUtil.GetLastingItemInfo(ItemInfo.FromImageProperties(_imgd.properties));
				
				for (var strProp:String in itemInfo)
					oRenderOptions["history:iteminfo:" + strProp] = itemInfo[strProp];
				oRenderOptions["history:iteminfo:history_serviceid"] = strHistoryServiceId;
			} catch (e:Error) {
				throw new Error("Exception in RenderHelper.AddHistory: " + e + ", " + e.getStackTrace());
			}
		}

		public function GetCallThrough(strMethod:String, oRenderOptions:Object, strHistoryServiceId:String=null): URLRequest {
			var urlr:URLRequest = null;
			try {
				var strDebugLoc:String = "1";
				if (_imgd.childStatus == DocumentStatus.Error) {
					trace("document error");
					return null; // Error in the doc
				} else if (_imgd.numChildrenLoading > 0) {
					trace("document has children loading");
					return null;
				}
				strDebugLoc += "2";
				
				// At this point, our doc status is fine.
				// Start the render
				if (oRenderOptions == null)
					oRenderOptions = {};

				strDebugLoc += "3";
					
				AddHistory(oRenderOptions, strHistoryServiceId);
				strDebugLoc += "4";
				oRenderOptions.assetmap = _imgd.GetSerializedAssetMap(true);
				strDebugLoc += "5";
				oRenderOptions.metadataasset = _imgd.baseImageAssetIndex;
				strDebugLoc += "6";
				var xmlPik:XML = _imgd.Serialize(true);
				
				if (_nForceRenderFailureType == 1)
					urlr = new URLRequest("http://test_fail.mywebsite.com/test_forced_render_failure");
				else if (_nForceRenderFailureType == 2)
					urlr = new URLRequest("http://test.mywebsite.com/test_forced_render_failure");
				else
					urlr = new URLRequest("http://test.mywebsite.com/render_not_yet_implemented");
				strDebugLoc += "7";
				
				// Log the render after we start so the user doesn't have to wait for the logging call
				LogRender(xmlPik, _imgd, oRenderOptions);
				strDebugLoc += "8";
			} catch (e:Error) {
				throw new Error("Exception in RenderHelper.GetCallThrough: " + e + ", " + e.getStackTrace() + ", " + strDebugLoc);
			}
			return urlr;
		}
		
		private var _upldr:Uploader;
		
		// fnSuccess(fnDone:Function, obResult:Object): void
		public function CallMethod(strMethod:String, oRenderOptions:Object, fnSuccess:Function): void {
			// If the document includes a failed upload, retry

			// UNDONE: how will we cancel the upload if the user cancels the render dialog?			
			var fnOnRetryUploadCancel:Function = function (dctResult:Object): void {
				_upldr.UserCancel();
				_upldr = null;
			}

			var fnOnRetryUploadProgress:Function = function (strAction:String, nPctDone:Number): void {
				/* UNDONE: RenderHelper doesn't have access to the dialog's progress bar
				if (_bsy != null) {
					if (strAction != null) _bsy.message = strAction;
					_bsy.progress = nPctDone * 100;
				}
				*/
			}
			
			var fnOnRetryUploadComplete:Function = function (err:Number, strError:String, upldr:FileTransferBase): void {
//				trace("RenderHelper.OnRetryUploadComplete: " + err + ", " + strError);
				if (err == ImageDocument.errNone) {
					_imgd.failedUpload = null;
					_imgd.baseImageFileId = _upldr.fid;
					_upldr = null;
					
					// If user cancels save this will still get called when the background upload
					// (which isn't cancelled) completes. Don't call the method though.
					if (!_irsd.isDone)
						_CallMethod(strMethod, oRenderOptions, fnSuccess);
				} else {
					_upldr.Cancel();
					_upldr = null;
					if (_fnDone != null)
						_fnDone(StorageServiceError.IOError, "Base image failed to upload");
				}
			}

			if (_imgd.failedUpload == null) {
				// If the base image for this document is still being uploaded, swap out its upload
				// callback handlers (which would bring up a retry dialog on failure) with ones
				// appropriate for this context.
				if (_imgd.uploaderInProgress != null) {
					_upldr = _imgd.uploaderInProgress as Uploader;
					var fnPriorCompleteCallback:Function = _upldr.completeCallback;
					var fnPriorProgressCallback:Function = _upldr.progressCallback;
					_upldr.progressCallback = null;
					_upldr.completeCallback = function (err:Number, strError:String, upldr:FileTransferBase): void {
						Util.DisableNavigateAwayWarning();
						
						// Swap back the original callback handlers in case the user cancels the save
						// but the upload STILL isn't finished.
						_upldr.completeCallback = fnPriorCompleteCallback;
						_upldr.progressCallback = fnPriorProgressCallback;
						fnOnRetryUploadComplete(err, strError, upldr);
					}
				}
				// If the background has been loaded or is in the process of being loaded _CallMethod
				// knows what to do.
				_CallMethod(strMethod, oRenderOptions, fnSuccess);
				return;
			}
			renderStatusMessage = Resource.getString("OutBridges", "retrying_upload");
			_upldr = new Uploader(_imgd.failedUpload, "renderHelperRetry", fnOnRetryUploadComplete, fnOnRetryUploadProgress, null, true);
			_upldr.StartWithRetry();
		}

		private function _CallMethod(strMethod:String, oRenderOptions:Object, fnSuccess:Function): void {
			// Note that "this" might be garbage collected when this function is done
			// (before calls into our anonymous functions)
			var rhCaller:RenderHelper = this;
			
			// First, check for an error state
			if (_imgd.status == DocumentStatus.Error) {
				if (_fnDone != null) _fnDone(StorageServiceError.ChildObjectFailedToLoad, "Document status is error");
			} else {
				var nChildrenTotal:Number;
				
				var fnOnChildLoaded:Function = function (nChildrenLeft:Number): void {
					if (_imgd.status == DocumentStatus.Error) {
						if (_fnDone != null)
							_fnDone(StorageServiceError.ChildObjectFailedToLoad, "Document status is error");
						return;
					}
					
					if (nChildrenLeft < 1) {
						// Ready to begin rendering.
						rhCaller.SetStatusMessageToWorking();
						
						// Start the render
						if (oRenderOptions == null)
							oRenderOptions = {};
							
						oRenderOptions.assetmap = rhCaller._imgd.GetSerializedAssetMap(true);
						oRenderOptions.retriesleft = 2;
						
						var xmlPik:XML = rhCaller._imgd.Serialize(true);
						PicnikService.callMethod(strMethod, xmlPik, oRenderOptions, true, fnSuccess, rhCaller._fnDone);
						
						// Log the render after we start so the user doesn't have to wait for the logging call
						LogRender(xmlPik, rhCaller._imgd, oRenderOptions);
					} else {
						rhCaller.renderStatusMessage = rhCaller.GetProcessingMessage(nChildrenLeft, nChildrenTotal);
					}
				}
				
				nChildrenTotal = _imgd.WaitForChildrenToLoad(fnOnChildLoaded);
			}
		}
		
		private function set renderStatusMessage(str:String): void {
			if (_irsd) _irsd.message = str;			
		}
		
		/*
		Function: RenderImage
		
		public function fnDone(err:Number, strError:String, obResult: { strUrl:String, strPikId:String })
		*/

		public function Render(oRenderOptions:Object = null): void {
			var fnSuccess:Function = function(fnDone:Function, obResult:Object): void {
				if (fnDone != null) {
					var dResults:Object = {
							strPikId: obResult.pikid.value,
							strUrl: obResult.url_full.value
					}
					PicnikFile.GetThumbUrls( dResults.strUrl, dResults );
					fnDone(0, kstrNoError, dResults);
				}
			}
			
			CallMethod("renderpik", oRenderOptions, fnSuccess);
		}
		
		/*
		Function: EmailImage
		email image rendered from supplied pik doc to recipient
		public function fnDone(err:Number, strError:String)
		*/
		public function Email(strToName:String, strToAddr:String, strFromName:String, strFromAddr:String,
				strBccAddr:String, strSubject:String, strMessage:String, cxWidth:Number, cyHeight:Number,
				strHistoryTag:String): void {
			
			var params:Object = {
				width: cxWidth, height: cyHeight,
				fromaddr: strFromAddr, toaddr: strToAddr
			};
			
			// These parameters are all optional
			if (strFromName)
				params.fromname = strFromName;
			if (strToName)
				params.toname = strToName;
			if (strMessage)
				params.message = strMessage;
			if (strSubject)
				params.subject = strSubject;
			if (strBccAddr)
				params.bccaddr = strBccAddr;
	
			var fnOnRendered:Function = function(fnDone:Function, obResult:Object): void {
				var strPikId:String = obResult.pikid.value;
				var itemInfo:ItemInfo = StorageServiceUtil.GetLastingItemInfo(ItemInfo.FromImageProperties(_imgd.properties));
				PicnikService.CommitRenderHistory(strPikId, itemInfo, strHistoryTag, fnDone);
			}

			CallMethod("emailpik", params, fnOnRendered);
		}
	
		public function RawEmail(strTo:String, strFrom:String, strSubject:String, strMessage:String,
				strImageName:String, cxWidth:Number, cyHeight:Number, strHistoryTag:String):void {

			var fnOnRendered:Function = function(fnDone:Function, obResult:Object): void {
				var strPikId:String = obResult.pikid.value;
				var itemInfo:ItemInfo = StorageServiceUtil.GetLastingItemInfo(ItemInfo.FromImageProperties(_imgd.properties));
				PicnikService.CommitRenderHistory(strPikId, itemInfo, strHistoryTag, fnDone);
			}

			var params:Object = {
				width: cxWidth, height: cyHeight, from: strFrom, to: strTo
			};
			
			// These parameters are all optional
			if (strImageName)
				params.imagename = strImageName;
			if (strSubject)
				params.subject = strSubject;
			if (strMessage)
				params.message = strMessage;
			
			CallMethod("rawemailpik", params, fnOnRendered);
		}
		
		/*
		Function: PostImage
		post image rendered from supplied pik doc to a URL
		
		function fnDone(err:Number, strError:String=null, dResponseInfo:Object=null, strResponse:String=null): void
		 	dItemInfo:
		 		- strLocationUrl (req)
		 		- strRenderedImageId (opt)
		*/
		public function PostImage(strURL:String, cxWidth:Number, cyHeight:Number, obParams:Object=null): void {
			if (obParams == null)
				obParams = {};
			
			obParams.width = cxWidth;
			obParams.height = cyHeight;
			obParams.url = strURL;
			obParams.history = !AccountMgr.GetInstance().isGuest;
	
			CallMethod("postpik", obParams, _PostImage);
		}
		
		private function _PostImage(fnDone:Function, obResult:Object): void {
			if (fnDone == null)
				return;
				
			var strLocationUrl:String = null;
			var nHttpStatus:Number = obResult.httpStatus.value;
			if (nHttpStatus == 302)
				strLocationUrl = obResult.location.value;
			
			var strResponse:String = null;
			if (obResult.response) {
				import mx.utils.Base64Decoder;
				var strBase64CompressedResponse:String = obResult.response;
				var b64d:Base64Decoder = new Base64Decoder();
				b64d.decode(strBase64CompressedResponse);
				var baCompressedResponse:ByteArray = b64d.drain();
				baCompressedResponse.uncompress();
				strResponse = baCompressedResponse.toString();
			}
			
			var dResponseInfo:Object = { strPikId: obResult.pikid.value };
			dResponseInfo['strLocationUrl'] = strLocationUrl;
			if (obResult['strRenderedImageId'] is ObjectProxy) {
				dResponseInfo['strRenderedImageId'] = obResult['strRenderedImageId'].value;
			}
			fnDone(0, kstrNoError, nHttpStatus, dResponseInfo, strResponse);
		}
	}
}
