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
// Used by the MyComputerInBridge for uploads (UploadDownloader) and sample images

package bridges
{
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.Security;
	
	import imagine.ImageDocument;
	
	import mx.utils.URLUtil;
	
	import util.ImportManager;
	
	public class Downloader extends FileTransferBase
	{
		private var _idlInProgress:ImageDownloadListener = null;
		private var _fRetryWhenFinished:Boolean = false;
		private var _nWait:Number = 0;
		private var _fCreateImageDocument:Boolean = true;
		
		public var fidToClone:String = null;
		public var fileType:String = null;
		public var temporary:Boolean = true;

		public var _nTimeComplete:Number = 0;
		public var _nBytes:Number = 0;

		// fnComplete(err:Number, strError:String, ftb:FileTransferBase)
		// fnProgress(strStatus:String, nFractionDone:Number)
		public function Downloader(item:ItemInfo=null, strInitiator:String=null, fnComplete:Function=null,
				fnProgress:Function=null, nWait:Number=0, fCreateImageDocument:Boolean=true) {
			super(item, strInitiator, fnComplete, fnProgress);
			_nWait = nWait;
			_fCreateImageDocument = fCreateImageDocument;
		}
		
		public override function Cancel(): void {
			if (_idlInProgress)
				_idlInProgress.CancelDownload();
			_idlInProgress = null;
		}
		
		public override function get type(): String {
			return "download";
		}
		
		public override function Start(): void {
			super.Start();
			DoStart();
		}
		
		protected function DoStart(): void {
			// Do we have a file id yet? If not, create one. If so, proceed to download it.
			if (_fid) {
				DownloadFile();
				return;
			}
			
			var fnOnImportAssetCreated:Function = function (err:Number, strError:String,
					fidCreated:String=null): void {
				if (err != PicnikService.errNone) {
					// UNDONE: how to retry the create a few times?
					OnDownloadDone(null, err, strError, null);
					return;
				}
				
				_fid = fidCreated;
				DownloadFile();
			}
			
			ImportManager.Import(_itemInfo.sourceurl, fileType, temporary, null, fnOnImportAssetCreated);
		}
		
		private function DownloadFile(): void {
			var obParams:Object;
			if (_itemInfo.sourceurl != null)
			{
//				obParams = { url: _imgp.sourceurl };
				obParams = {};
			} else {
				obParams = { wait: 1 };
			}
			if (_nRetries > 0) {
				obParams["retry"] = _nRetries;
			}
			
			var strURL:String = PicnikService.GetFileURL(_fid, obParams);
			_idlInProgress = Downloader.DownloadImage(strURL, OnDownloadProgress, OnDownloadDone);
			_nRetries++;
		}
		
		protected function get inProgress(): Boolean {
			return _idlInProgress != null;
		}
		
		protected function OnDownloadProgress(ldr:Loader, cbLoaded:Number, cbTotal:Number, obData:Object): void {
			if (_fnProgress != null) {
				var nPctDone:Number = 0;
				if (cbLoaded > 0 && cbTotal > 0) {
					nPctDone = cbLoaded / cbTotal;
				}
				_fnProgress(Resource.getString("FileTransferBase", "Downloading"), nPctDone);
			}
		}
				
		// The upload has finished, we're ready to retry
		public function RetryAtWill(): void {
			if (inProgress) {
				_fRetryWhenFinished = true;
			} else {
				Retry();
			}
		}
		
		protected function Retry(): void {
			_fRetryWhenFinished = false;
			_fRetry = false;
			DoStart();
		}
		
		protected function OnDownloadDone(ldr:Loader, err:Number, strError:String, obData:Object): void {
			if (_fCanceled) return;
			
			_nTimeComplete = new Date().time;
			
			// First, check to make sure the image is valid by initializing the image doc
			if (err == ImageDocument.errNone) {
				if (ldr.content == null) {
					err = ImageDocument.errBaseImageDownloadFailed;
					strError = "Missing content";
				} else {
					
					try {
						_nBytes = ldr.contentLoaderInfo.bytesTotal;
					} catch (e:Error) {
						trace("Ignoring error: " + e + ", " + e.getStackTrace());
					}
					
					ExtractMetadata(ldr);
					
					if (_fCreateImageDocument) {
						try {
							_imgd = new ImageDocument();
							var strId:String = itemInfo.title ? itemInfo.title.substr(0, ImageDocument.kcchFileNameMax) : null;
							err = _imgd.InitFromDisplayObject(strId, _fid, ldr.content, itemInfo.asImageProperties());
							if (err != ImageDocument.errNone)
								strError = "Failed to initialize: " + err;
						} catch (e:Error) {
							err = ImageDocument.errBaseImageDownloadFailed;
							strError = "Exception: " + e;
							
							// A little extra info to help catch some ArgumentError exceptions being logged
							if (e.errorID == 2015)
								strError += "itemInfo.title: " + itemInfo.title + ", ldr.content: " + ldr.content + ", itemInfo: " + itemInfo;
						}
					}
				}
			}
			
			if (err != ImageDocument.errNone) {
				_imgd = null;
				_dobContent = null;
				if (_idlInProgress) {
					_idlInProgress.Dispose();
					_idlInProgress = null; // All done with the idl.
				}
				
				if (_fRetry) {
					if (_fRetryWhenFinished) {
						Retry();
					}
				} else {
					// LogComplete(strError);
					_fnComplete(err, strError, this);
				}
			} else {
				// LogComplete();
				_dobContent = ldr.content;
				_fnComplete(err, strError, this);
				
				_idlInProgress.Dispose();
				_idlInProgress = null; // All done with the idl.
			}
		}
		
		// Callback signatures:
		//   fnProgress(ldr:Loader, cbDownloaded:Number, cbTotal:Number, obData:Object): void
		//   fnDone(ldr:Loader, err:Number, strError:String, obData:Object): void
		public static function DownloadImage(strBaseImageURL:String,
				fnProgress:Function, fnDone:Function, obData:Object=null): ImageDownloadListener {
					
			// load policy file just in case we need it for a direct load. Flash caches these.
			Security.loadPolicyFile(URLUtil.getProtocol(strBaseImageURL) + "://" + 
						URLUtil.getServerNameWithPort(strBaseImageURL) +  "/crossdomain.xml");
					
			var loaderContext:LoaderContext = new LoaderContext();
			loaderContext.checkPolicyFile = true;
					
			var urlReq:URLRequest = new URLRequest(strBaseImageURL);
			var ldr:Loader = new Loader();
			var idl:ImageDownloadListener = new ImageDownloadListener(ldr, fnProgress, fnDone, obData);
			ldr.load(urlReq, loaderContext);	// The above ImageDownloadListener is responsible for calling ldr.unload()

			return idl;
		}
	}
}
