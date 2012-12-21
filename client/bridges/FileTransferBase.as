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
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.events.EventDispatcher;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.utils.ByteArray;
	
	import imagine.ImageDocument;
	
	import mx.resources.ResourceBundle;
	
	import util.metadata.ImageMetadata;
	
	public class FileTransferBase extends EventDispatcher
	{
   		[ResourceBundle("FileTransferBase")] protected static var _rb:ResourceBundle;
   		
		protected var _itemInfo:ItemInfo;
		protected var _fnComplete:Function;
		protected var _fnProgress:Function;
		protected var _dobContent:DisplayObject = null;
		protected var _imgd:ImageDocument = null;
		protected var _fStarted:Boolean = false;
		protected var _fCanceled:Boolean = false;
		protected var _fAsyncIO:Boolean = true;
		protected var _fid:String;
		protected var _fRetry:Boolean = false;
		protected var _nRetries:Number = 0;
		protected var _strInitiator:String="Unknown";
		protected var isLocal:Boolean = false;
		
		public var transferType:String;

		// fnComplete(err:Number, strError:String, ftb:FileTransferBase)
		// fnProgress(strStatus:String, nFractionDone:Number)
		public function FileTransferBase(itemInfo:ItemInfo = null, strInitiator:String=null, fnComplete:Function = null, fnProgress:Function = null)
		{
			Init(itemInfo, strInitiator, fnComplete, fnProgress);
		}
		
		// The results of the transfer. Null if it failed.
		public function get content(): DisplayObject {
			return _dobContent;
		}
		
		// The results of the transfer. Null if it failed. Pre-initialized.
		public function get imgd(): ImageDocument {
			return _imgd;
		}
		
		public function get started(): Boolean {
			return _fStarted;
		}
		
		public function Init(itemInfo:ItemInfo = null, strInitiator:String=null, fnComplete:Function = null, fnProgress:Function = null): void
		{
			_fCanceled = false;
			_itemInfo = itemInfo;
			_strInitiator = strInitiator;
			if (_strInitiator == null)
				strInitiator = "null";
			_fnComplete = fnComplete;
			_fnProgress = fnProgress;
			if (AccountMgr.GetInstance().GetUserAttribute("forcesyncuploaddownload", "") == "true") {
				_fAsyncIO = false;
			} else {
				_fAsyncIO = true;
			}
			transferType = type;
		}
		
		public function get type(): String {			
			return "transfer";
		}
		
		public function get itemInfo(): ItemInfo {
			return _itemInfo;
		}
		
		public function set fid(fid:String): void {
			_fid = fid;
		}
		
		public function get fid(): String {
			return _fid;
		}
		
		public function set completeCallback(fn:Function): void {
			_fnComplete = fn;
		}
		
		public function get completeCallback(): Function {
			return _fnComplete;
		}
		
		public function set progressCallback(fn:Function): void {
			_fnProgress = fn;
		}
		
		public function get progressCallback(): Function{
			return _fnProgress;
		}
		
		// User hit cancel. Log as a cancel, then cleanup
		public function UserCancel(): void {
			Cancel();
		}
		
		public function Cancel(): void {
			_fCanceled = true;
			// Clean up
			// Override in sub-classes
		}
		
		public function StartWithRetry(): void {
			_fRetry = true;
			Start();
		}
		
		public function Start(): void {
			// Override in sub-classes. Call super.Start() to set fStarted
			_fStarted = true;
			_fCanceled = false;
		}
		
		private function AddFirstLogDetails(astrInfo:Array): void {
			astrInfo.push("loc:" + _strInitiator);
			astrInfo.push("os:" + Capabilities.os);
			astrInfo.push("fv:" + Capabilities.version);
			astrInfo.push("fid:" + _fid);
			astrInfo.push("rtr:" + _nRetries);
		}

		public function AddExtraLogDetails(astrInfo:Array): void {
			// Override in sub-classes
		}
		
		private function AddLastLogDetails(astrInfo:Array): void {
			astrInfo.push("ttl:" + _itemInfo.title);
			astrInfo.push("async:" + _fAsyncIO);
			astrInfo.push("mem:" + Util.FormatBytes(System.totalMemory));
			astrInfo.push("ua:" + Util.userAgent);
		}
		
		// FT:LocalUpload/Error:
		// FT:LocalUpload/Success
		// FT:RemoteUpload/Error
		// FT:RemoteUpload/Success
		// FT:LocalDownload/Error
		// FT:LocalDownload/Success
		// FT:RemoteDownload/Error
		// FT:RemoteDownload/Success
		protected function LogComplete(strError:String=null, fForceSuccess:Boolean=false): void {
			var fSuccess:Boolean = fForceSuccess || (strError == null);
			var nSeverity:Number = fSuccess ? PicnikService.knLogSeverityMonitor : PicnikService.knLogSeverityWarning;
			var strLoc:String = isLocal ? "Local" : "Remote";
			var strResult:String = fSuccess ? "Success" : "Error";
			
			var strLog:String = "Upld," + strLoc + type + "," + strResult + ",";
			var astrInfo:Array = [];
			if (strError == null)
				strError = "None";
			astrInfo.push("err:" + String(strError).substr(0,20));
			AddFirstLogDetails(astrInfo);
			astrInfo.push("error:" + strError);
			AddExtraLogDetails(astrInfo);
			AddLastLogDetails(astrInfo);
			PicnikService.Log(strLog + astrInfo.join(","), nSeverity);
			if (!fSuccess)
				Util.UrchinLogReport("/error/upload/" + strLoc + type + "/" + strError);
		}
		
		protected function ExtractMetadata(ldr:Loader): void {
			// Flash wraps a SWF around the loaded image. We scan the SWF looking for the
			// embedded image.
			// CONSIDER: we could parse the SWF to deal with this more robustly
			
			try {
				// Flash versions 9.0.47 and earlier don't have contentLoaderInfo.bytes!
				// Right now we only need the metadata for FP10-specific local saving but
				// down the road we might want to use it for something else, e.g. display
				// to the user.
				var baSWF:ByteArray = ldr.contentLoaderInfo.bytes;
				
				// Scan the first 200 bytes looking for a JPEG
				try {
					for (var i:int = 0; i < 200; i++)
						if (baSWF[i] == 0xff && baSWF[i + 1] == 0xd8 &&
								!(baSWF[i + 2] == 0xff && baSWF[i + 3] == 0xd8)) // JPEG SOI marker
							break;
				} catch (err:Error) {
					return;
				}
				if (i == 200)
					return;
				
				baSWF.position = i; // Set position to the start of the JPEG data
				var meta:ImageMetadata = ImageMetadata.Extract(baSWF);
				_itemInfo.metadata = meta;
			} catch (err:Error) {
				return;
			}
		}
	}
}
