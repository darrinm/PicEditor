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
package bridges
{
	import imagine.documentObjects.DocumentStatus;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
	import imagine.ImageDocument;
	
	import mx.core.Application;
	import mx.utils.URLUtil;
	
	import util.AssetMgr;
	import util.IPendingAsset;
	import util.IPendingFile;
	import util.UploadManager;

	[Event(name="progress", type="flash.events.ProgressEvent")]
	
	public class Uploader extends FileTransferBase implements IPendingFile, IPendingAsset {
		protected var _fr:FileReference;
		public var importurl:String = null;
		public var fallbackimporturl:String = null;
		private var _nProgress:Number = 0;
		private var _iul:ImageUploadListener;
		private var _nStatus:Number = DocumentStatus.Loading;
		private var _afnOnLoad:Array = [];
		
		public var logComplete:Boolean = true;
		
		public var _nStartTime:Number = 0;
		
		public static var _fUseFallbackUploadUrls:Boolean = false;
		
		[Bindable] public static var _nForceUploadFailureMode:Number = 0; // Default to nso failure
		
		// Callback signatures:
		//   fnProgress(cbUploaded:Number, cbTotal:Number): void
		//   fnComplete(err:Number, strError:String, upldr:FileTransferBase, fidAsset:String=null): void
		public function Uploader(fr:FileReference, strInitiator:String, fnComplete:Function=null, fnProgress:Function=null, fidIn:String=null, fLocal:Boolean=false) {
			_fr = fr;
			_itemInfo = ImageProperties.FrToIinf(_fr, fidIn);
			_fid = fidIn;
			isLocal = fLocal;
			
			super(_itemInfo, strInitiator, fnComplete, fnProgress);
		}
		
		public function get useAsyncIO(): Boolean {
			return ShouldUseAsyncIO();
		}
		
		private function ShouldUseAsyncIO(): Boolean {
			if (Util.DoesUserHaveGoodFlashPlayer10() || _fUseFallbackUploadUrls || !PicnikConfig.uploadsUseAsyncIO)
				return false;
			else				
				return true;
		}
		
		public function Unwatch(): void {
			// Do nothing
		}
		
		[Bindable ("statusupdate")]
		public function set status(n:Number): void {
			if (_nStatus == n) return;
			_nStatus = n;
			dispatchEvent(new Event("statusupdate"));
			DoCallbacks();
		}
		
		public function get status(): Number {
			return _nStatus;
		}
		
		// From the Flex 3 docs:
		// "The size of the file on the local disk in bytes. If size is 0, an exception is thrown."
		public function get filesize(): Number {
			return _fr.size;
		}
		
		public function CancelFileReferenceUpload(): void {
			if (_fr) {
				try {
					_fr.cancel();
					_fr = null;
				} catch (e:Error) {}
			}
		}
		
		public override function Cancel(): void {
			CancelFileReferenceUpload();
			if (_fid) UploadManager.CancelUpload(_fid);
		}

		public override function get type(): String {
			return "upload";
		}
		
		override public function Start(): void {
			super.Start();
			/*
			var strDetails:String = "name: " + _itemInfo.mycomputer_file_name +
					", size: " + _itemInfo.mycomputer_file_size +
					", type: " + _itemInfo.mycomputer_file_type +
					", creation date: " + _itemInfo.mycomputer_file_creation_date +
					", modification date: " + _itemInfo.mycomputer_file_modification_date +
					", creator: " + _itemInfo.mycomputer_file_creator;
			Log("/start", strDetails);
			*/
			if (_fid == null)
				CreateFid();
			else
				EnqueueUpload();
		}
		
		override public function AddExtraLogDetails(astrInfo:Array):void {
			try {
				if (_strFailInfo != null)
					astrInfo.push("finf:" + _strFailInfo);
				astrInfo.push("nm:" + _itemInfo.mycomputer_file_name);
				astrInfo.push("sz:" + _itemInfo.mycomputer_file_size);
				astrInfo.push("typ:" + _itemInfo.mycomputer_file_type);
				astrInfo.push("cdt:" + _itemInfo.mycomputer_file_creation_date);
				astrInfo.push("mdt:" + _itemInfo.mycomputer_file_modification_date);
				astrInfo.push("ctr:" + _itemInfo.mycomputer_file_creator);
			} catch (e:Error) {
				trace("Ignoring error: " + e);
				// Ignore errors
			}
		}
		
		private var _strFailInfo:String = null;
		
		private function PrepareFailureLogParams(fnDone:Function): void {
			// Try some tests and include the results in our logs
			try {
				var strUrl1Base:String = URLUtil.getProtocol(importurl) + "://" + URLUtil.getServerNameWithPort(importurl);
				var strUrl2Base:String = PicnikService.serverURL;
			} catch (e:Error) {
				_strFailInfo = "Exception " + e.toString();
				fnDone();
				return;
			}
			DoTests([
				{urlbase: strUrl1Base, postsize:20000, type:"large_post_to_upload_server"},
				{urlbase: strUrl1Base, postsize:1000, type:"small_post_to_upload_server"},
				{urlbase: strUrl1Base, postsize:0, type:"get_to_upload_server"},
				{urlbase: strUrl2Base, postsize:20000, type:"large_post_to_rest_server"},
				{urlbase: strUrl2Base, postsize:1000, type:"small_post_to_rest_server"},
				{urlbase: strUrl2Base, postsize:0, type:"get_to_rest_server"}],
				fnDone);
		}
		
		private function DoTests(aobTests:Array, fnDone:Function): void {
			if (aobTests == null || aobTests.length < 1) {
				_strFailInfo = "all_tests_failed";
				fnDone();
				return;
			}
			
			// We have one or more tests to perform.
			
			// Get the first test
			var obTest:Object = aobTests.shift();
			var nPostSize:Number = obTest.postsize;
			// Run the test
			var strUrl:String = obTest.urlbase + "/fileimport?failtest=true&nocache=" + Math.random();
			var urlr:URLRequest = new URLRequest(strUrl);
			if (nPostSize > 0) {
				urlr.method = URLRequestMethod.POST
				var baData:ByteArray = new ByteArray();
				while (baData.length < nPostSize)
					baData.writeByte(uint(Math.random() * 256));
				urlr.data = baData;
			}
			var urll:URLLoader = new URLLoader(urlr);
			urll.load(urlr);
			
			var msStart:Number = new Date().time;
			var fnOnSuccess:Function = function(): void {
				var msElapsed:Number = (new Date().time) - msStart;
				_strFailInfo = obTest.type + " " + msElapsed;
				fnDone();
			};
			
			var fnOnError:Function = function(): void {
				_strFailInfo = obTest.type;
				DoTests(aobTests, fnDone);
			};
			
			urll.addEventListener(Event.COMPLETE, function(evt:Event): void {
				var strData:String = urll.data;
				if (nPostSize == 0 && strData == "OK") {
					fnOnSuccess();
				} else if (strData == nPostSize.toString()) {
					fnOnSuccess();
				} else {
					fnOnError();
				}
			});
			
			urll.addEventListener(IOErrorEvent.IO_ERROR, fnOnError);
			urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnOnError);
		}

		protected override function LogComplete(strError:String=null, fForceSuccess:Boolean=false):void {
			var fnLogComplete:Function = super.LogComplete;
			
			if (logComplete) {
				// Prepare extra log params
				if (!fForceSuccess && strError != null) {
					PrepareFailureLogParams(function(): void {
						fnLogComplete(strError, fForceSuccess);
					});
				} else {
					super.LogComplete(strError, fForceSuccess);
				}
			}
		}
		
		private function CreateFid(): void {
			var fnOnCreateFile:Function = function (err:Number, strError:String, fidCreated:String=null,
					strAsyncImportUrl:String=null, strSyncImportUrl:String=null, strFallbackImportUrl:String=null): void {
				if (err != PicnikService.errNone) {
					OnUploadDone(err, "createfid:" + strError);
				} else {
					fallbackimporturl = strFallbackImportUrl;
					if (_fUseFallbackUploadUrls && fallbackimporturl != null)
						importurl = strFallbackImportUrl;
					else if (useAsyncIO)
						importurl = strAsyncImportUrl;
					else
						importurl = strSyncImportUrl;
						
					// Choose the proper import url and fallback url
					// If we have failed once, use the fallback url
					// and set async to false
					_fid = fidCreated;
					EnqueueUpload();
				}
			}

			AssetMgr.CreateAsset({strType:"i_mycomput"}, fnOnCreateFile);
		}
		
		// Start this upload as soon as an upload slot becomes available
		private function EnqueueUpload(): void {
			if (_fid == null) throw new Error("Enqueue upload with null fid");
			if (importurl == null) throw new Error("Enqueue upload with null importurl");
			UploadManager.Enqueue(_fid, this);
		}

		// This should only be called by UploadManager.		
		public function DoUpload(): void {
			_nStartTime = new Date().time;
			if (_fid == null) throw new Error("DoUpload with null fid");
			if (importurl == null) throw new Error("DoUpload with null importurl");
			
			// A reference must be kept to the FileReference somewhere until
			// the upload completes or it will be canceled when the object is garbage
			// collected. ImageUploadListener will hang on to fr so we have to hang
			// on to the ImageUploadListener.
			_iul = new ImageUploadListener(_fr, OnUploadProgress, OnUploadDone);
			if (_nForceUploadFailureMode == 1)
				importurl = "http://test_fail.mywebsite.com/test_forced_upload_failure";
			else if (_nForceUploadFailureMode == 2)
				importurl = "http://test.mywebsite.com/test_forced_upload_failure";
			AssetMgr.StartUpload(_fr, importurl);
		}
		
		[Bindable("progress")]
		public function set progress(n:Number): void {
			if (_nProgress == n) return;
			_nProgress = n;
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, uint(n * 100),100));
		}
		
		public function get progress(): Number {
			return _nProgress;
		}
		
		override public function toString(): String {
			return _fid + ": Uploader: " + (_fr ? _fr.name : "null") + ", " + progress;
		}
		
		
		private function OnUploadProgress(cbLoaded:Number, cbTotal:Number): void {
			var nPctDone:Number = 0;
			if (cbLoaded > 0 && cbTotal > 0) {
				nPctDone = cbLoaded / cbTotal;
			}
			// Don't report we are done until we are really done
			// If we have uploaded all the bytes, wait for the server to respond
			// before setting the progress to 1.
			if (nPctDone >= 1) nPctDone = 0.9999;
			progress = nPctDone;
			if (_fnProgress != null) {
				_fnProgress(Resource.getString("FileTransferBase", "Uploading"), nPctDone);
			}
		}
		
		private function OnUploadDone(err:Number, strError:String, fidAsset:String=null): void {
			if (err != ImageDocument.errNone) {
				if (_fid) {
					// Something didn't work. Try the other URLs
					_fUseFallbackUploadUrls = true;
					// Handle failed uploads
					if (_fRetry && _nRetries < 3) {
						if (fallbackimporturl != null)
							importurl = fallbackimporturl;
						
						_nRetries++;
						
						// Let the calling error handler unwind before restarting the upload
						PicnikBase.app.callLater(DoUpload);
						return;
					}
					UploadManager.UploadDone(_fid, err);
				}
				Cancel(); // Cleanup
				LogComplete(strError);
			} else {
				if (_fid)
					UploadManager.UploadDone(_fid, err);
				LogComplete();
			}
			if (_fnComplete != null) _fnComplete(err, strError, this);
			_fr = null;
			progress = (err == PicnikService.errNone) ? 1 : 0;
			status = (err == PicnikService.errNone) ? DocumentStatus.Loaded : DocumentStatus.Error;
		}
		
		// public function fnComplete(err:Number, strError:String, dctProps:Array=null): void
		public function GetFileProperties(strProps:String, fnComplete:Function): void {
			var fnOnLoad:Function = function(): void {
				PicnikService.GetFileProperties(_fid, null, strProps, fnComplete);
			}
			AddOnLoadCallback(fnOnLoad);
		}
		
		public function AddOnLoadCallback(fnOnLoad:Function): void {
			_afnOnLoad.push(fnOnLoad);
			Application.application.callLater(DoCallbacks);
		}
		
		private function DoCallbacks(): void {
			if (status == DocumentStatus.Error || status >= DocumentStatus.Loaded) {
				while (_afnOnLoad.length > 0) {
					var fnOnLoad:Function = _afnOnLoad.pop();
					fnOnLoad();
				}
			}
		}
	}
}
