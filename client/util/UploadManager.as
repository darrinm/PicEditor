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
	import bridges.Uploader;
	
	import flash.events.EventDispatcher;
	
	
	/** Upload Manager class
	 * Conceptionally, this class keeps track of uploads.
	 * When you get a list of fids from the server, this track can give you upload progress for those fids
	 * This class knows how many uploads are in progress and can delay starting one until another completes
	 * When add uploads to the upload stack, items at the bottom which will not be accessible are removed.
	 * This class gets involved once we get a fid.
	 *
	 * General use:
	 * 1. Use the Uploader class to start/stop uploads
	 * 2. Use the UploadManager class to find running/pending uploads 
	 */

	[Event(name="uploadcanceled", type="flash.events.Event")]

	public class UploadManager extends EventDispatcher
	{
		private static var _uplm:UploadManager = null;
		
		public static const UPLOADCANCELED:String = "uploadcanceled";
		
		private var _obFidsInProgress:Object = {};
		private var _aPendingUploads:Array = [];
		private var _aActiveUploads:Array = [];
		private static const knMaxActiveUploads:Number = 1;
		[Bindable] public var uploading:Boolean = false;
				
		// This is called by Uploader.Cancel(). Call that if you want to cancel an upload. 
		public static function CancelUpload(fid:String): void {
			Instance()._CancelUpload(fid);
		}
		
		public static function CancelAll(): void {
			Instance()._CancelAll();
		}

		public static function GetProgress(fid:String): Number {
			return Instance()._GetProgress(fid);
		}
		
		public static function GetPendingFile(fid:String): IPendingFile {
			var pf:IPendingFile = GetUpload(fid);
			if (pf == null)
				pf = new PendingFileWrapper();
			return pf;
		}
		
		public static function GetUpload(fid:String): Uploader {
			return Instance()._GetUpload(fid);
		}
		
		public static function Instance(): UploadManager {
			if (_uplm == null)
				_uplm = new UploadManager();
			
			return _uplm;
		}
		
		// Start this upload as soon as we have a slot		
		public static function Enqueue(fid:String, upldr:Uploader): void {
			Instance()._Enqueue(fid, upldr);
		}
		// uplodr.public function DoUpload(): void {
		
		// The upload is finished. Remove it from our lists.
		public static function UploadDone(fid:String, err:Number): void {
			Instance()._UploadDone(fid, err);
		}
		
		public function UploadManager() {
		}
		
		// Cancel all active uploads
		// This finds active uploads and calls Uploader.Cancel() for each one
		private function _CancelAll(): void {
			for each (var upldr:Uploader in _obFidsInProgress) {
				upldr.Cancel();
			}
		}
		
		// Remove an upload from our lists
		// This is called by Uploader.Cancel(). Call that if you want to cancel an upload. 
		private function _CancelUpload(fid:String): void {
			dispatchEvent(new Event(UPLOADCANCELED));
			if (fid == null) throw new Error("Cancel null fid");
			var upldr:Uploader = _GetUpload(fid);
				
			if (fid in _obFidsInProgress)
				delete _obFidsInProgress[fid];
			
			DoUploadsLater();
			
			var nRemove:Number;
			nRemove = _aActiveUploads.indexOf(upldr);
			if (nRemove >= 0) {
				_aActiveUploads.splice(nRemove, 1);
			} else {
				nRemove = _aPendingUploads.indexOf(upldr);
				if (nRemove >= 0) {
					_aPendingUploads.splice(nRemove, 1);
					uploading = _aPendingUploads.length > 0;
				}
			}
			if (upldr != null)
				upldr.CancelFileReferenceUpload(); // Make sure we stop the upload
		}
		
		private function _Enqueue(fid:String, upldr:Uploader): void {
			if (fid == null) throw new Error("Enqueue for null fid");
			if (upldr == null) throw new Error("uploader is null");
			var upldrExisting:Uploader = _GetUpload(fid);
			if (upldrExisting) {
				if (upldr == upldrExisting)
					throw new Error("Re-adding uploader");
				else
					throw new Error("duplicate fid");
			}
			_obFidsInProgress[fid] = upldr;
			_aPendingUploads.push(upldr);
			uploading = _aPendingUploads.length > 0;
			DoUploadsLater(); // Start the first upload
		}
		
		// The upload is finished. Remove it from our lists.
		private function _UploadDone(fid:String, err:Number): void {
			if (fid == null) throw new Error("UploadDone for null fid");
			var strError:String = "";
			var upldr:Uploader = _GetUpload(fid);
			if (upldr == null) strError += "uploader not in _obFidsInProgress. ";
			var nRemove:Number = _aActiveUploads.indexOf(upldr);
			if (nRemove == -1)
				strError += "uploader not in active uploads. ";
			else
				_aActiveUploads.splice(nRemove, 1);
			
			// Start the next upload
			DoUploadsLater();
			
			if (strError.length > 0)
				throw new Error(strError);
		}
		
		private function _GetUpload(fid:String): Uploader {
			if (fid == null) return null;
			if (!(fid in _obFidsInProgress)) return null;
			return _obFidsInProgress[fid];
		}

		// Call later makes it possible for us to add a list of items and then
		// start loading the last added item first.
		private function DoUploadsLater(): void {
			PicnikBase.app.callLater(DoUploads);
		}
		
		private function DoUploads(): void {
			if (_aActiveUploads.length < knMaxActiveUploads && _aPendingUploads.length > 0) {
				var upldr:Uploader = _aPendingUploads.pop();
				uploading = _aPendingUploads.length > 0;
				_aActiveUploads.push(upldr);
				upldr.DoUpload();
			}
		}
		
		public function _GetProgress(fid:String): Number {
			return _GetUpload(fid) ? _GetUpload(fid).progress : 1;
		}
	}
}