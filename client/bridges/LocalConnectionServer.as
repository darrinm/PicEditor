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
// Handle service requests over a well-known LocalConnection

package bridges {
	import flash.net.LocalConnection;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import imagine.ImageDocument;
	
	import util.MemoryFileReference;
	
	public class LocalConnectionServer extends Bridge {
		static private const kstrConnectionName:String = "_PicnikLconService";
		
		private var _lc:LocalConnection;
		private var _dctCalls:Object = {};
		
		public function LocalConnectionServer() {
			_lc = new LocalConnection();
			_lc.client = this;
//			_lc.allowDomain("app#com.picnik.Companion");
			_lc.allowDomain("*");
			try {
				_lc.connect(kstrConnectionName);
			} catch (err:ArgumentError) {
				// ArgumentError: Error #2082: Connect failed because the object is already connected.
				trace(err);
			}
		}
		
		public function Invoke(strLconResponse:String, strSig:String, strMethod:String, baData:ByteArray, cbTotal:int, ...avArgs:*): void {
			// if abData.length < cbTotal then create a buffering context for this invocation that will
			// collect all the data and make a single method call.
			var fnOnResponse:Function = function (...avResponse:*): void {
				var lcResponse:LocalConnection = new LocalConnection();
				if (avResponse == null)
					avResponse = [];
				avResponse.unshift(strSig);
				avResponse.unshift("Response");
				avResponse.unshift(strLconResponse);
				lcResponse.send.apply(lcResponse, avResponse);
			}
			
			avArgs.push(fnOnResponse);
			var obCall:Object;
			
			if (strSig in _dctCalls) {
				obCall = _dctCalls[strSig];
			} else {
				obCall = { data: baData, timestamp: getTimer(), method: strMethod, args: avArgs };
				_dctCalls[strSig] = obCall;
			}

			if (baData && baData.length < cbTotal) {
				obCall.data.writeBytes(baData);
				baData = obCall.data;
			}
//			trace("baData.length: " + baData.length + ", position: " + baData.position);
				
			if (baData == null || baData.length == cbTotal) {
				if (baData != null)
					avArgs.unshift(baData);
				this[strMethod].apply(this, avArgs);
			}
		}
		
		//
		// The public LocalConnection API
		//
		
		public function Edit(baData:ByteArray, strTitle:String, fnResponse:Function): void {
			// We're done as far as the caller is concerned. We don't want its progress
			// dialog staying up while the user responds to the Save Changes dialog.
			fnResponse(true);
			
			var fnOnContinueOverwrite:Function = function (): void {
				var fnOnComplete:Function = function (err:Number, strError:String, dnldr:FileTransferBase): void {
					if (dnldr == null) {
						// we've been cancelled! do nothing!
						return;
					}
					if (err != ImageDocument.errNone || dnldr.imgd == null) {
						// Upload/download failed. Display an error.
						var strUserErrorKey:String = "transfer_failed_upload";
						switch (err) {
						case ImageDocument.errUploadExceedsSizeLimit:
							strUserErrorKey = "upload_exceeds_limit";
							break;
							
						case ImageDocument.errUnsupportedFileFormat:
							strUserErrorKey = "unsupported_file_format";
							break;
						}
	//					ReportError(".OnComplete", err, strError, strUserErrorKey);
					} else {
	//					ReportSuccess(null, "localcon");
						// Success! Open the image
						PicnikBase.app.activeDocument = dnldr.imgd;
						PicnikBase.app.NavigateTo(PicnikBase.EDIT_CREATE_TAB);
					}
				}
				
				var fnOnProgress:Function = function (strAction:String, nPctDone:Number): void {
				}
				
				var fr:MemoryFileReference = new MemoryFileReference(baData, strTitle);
				var dnldr:UploadDownloader = new UploadDownloader(fr, "localcon", fnOnComplete, fnOnProgress);
				dnldr.Start();
			}
			
			ValidateOverwrite(fnOnContinueOverwrite);
		}
	}
}
