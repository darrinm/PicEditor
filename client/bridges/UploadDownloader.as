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
	import dialogs.EasyDialogBase;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import imagine.ImageDocument;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.resources.ResourceBundle;
	
	import util.DrawUtil;
	
	public class UploadDownloader extends FileTransferBase
	{
   		[ResourceBundle("UploadDownloader")] private var _rb:ResourceBundle;
   		
		private var _upldr:Uploader;
		private var _dnldr:Downloader;
		private var _fDownloadMadeProgress:Boolean = false;
		private var _nPctReportedComplete:Number = 0;
		private var _frLocalLoad:FileReference;
		private var _fr:FileReference;
		private var _fLocalLoad:Boolean = false;

		private var _fReturned:Boolean = false;
		
		// This class handles the complexity of asynchronous upload/downloads (when enabled)
		public function UploadDownloader(fr:FileReference, strInitiator:String, fnComplete:Function = null, fnProgress:Function = null) {
			// Try to load the bits straight from the local HD into the player if possible
			if (Util.DoesUserHaveGoodFlashPlayer10())
				_frLocalLoad = fr;
			_fr = fr;
			_itemInfo = ImageProperties.FrToIinf(fr);
			_upldr = new Uploader(fr, "upDownRemote", OnUploadComplete, OnUploadProgress);
			_upldr.logComplete = false; // We own this one. We'll log the results before we return
			_dnldr = new Downloader(_itemInfo, "upDownRemote", OnDownloadComplete, OnDownloadProgress);
			super(_itemInfo, strInitiator, fnComplete, fnProgress);
		}
		
		public override function AddExtraLogDetails(astrInfo:Array):void {
			if (_upldr != null)
				_upldr.AddExtraLogDetails(astrInfo);
		}

		public override function Cancel(): void {
			_upldr.Cancel();
			_dnldr.Cancel();
		}
		
		public override function UserCancel(): void {
			_upldr.UserCancel();
			_dnldr.UserCancel();
		}

		public override function get type(): String {
			if (_dnldr.started)
				return _dnldr.type;
			else if (_frLocalLoad)
				return "local";
			else
				return _upldr.type;
		}
		
		public override function Start(): void {
			super.Start();

			// Attempt the local load first. We can't do it in with the upload because
			// FileReference.load and .upload reuse the same events (e.g. Event.COMPLETE)
			// and handlers can't differentiate well.
			if (_frLocalLoad)
				LocalLoad();
			else
				_upldr.Start();
			_fReturned = false;
		}
		
		public override function get imgd(): ImageDocument {
			// Successful local loading fills in _imgd
			return _imgd ? _imgd : _dnldr.imgd;
		}
		
		public override function get fid(): String {
			return _upldr.fid;
		}
		
		private function OnUploadComplete(err:Number, strError:String, upldr:FileTransferBase): void {
			if (_fCanceled || _fReturned) return;
			var nStage:Number = 0;
			try {
				if (err != ImageDocument.errNone) {
					nStage = 1;
					// Upload failed, we're done.
					_fReturned = true;
					_fnComplete(err, "uploading: " + strError, this);
					nStage = 2;
				} else {
					nStage = 3;
					// Upload succeeded. Start the download if it needs to be.
					if (!_dnldr.started)
					{
						nStage = 4;
						_dnldr.fid = _upldr.fid;
						_dnldr.StartWithRetry();
					}
					else
					{
						nStage = 5;
						_dnldr.RetryAtWill();
					}
					nStage = 6;
				}
			} catch (e:Error) {
				PicnikService.Log("Client Exception: " + e + ", " + e.getStackTrace() + ", stage=" + nStage, PicnikService.knLogSeverityError);
				throw e;
			}
		}

		private function OnUploadProgress(strAction:String, nPctDone:Number): void {
			if (_fCanceled) return;
			if (_fnProgress != null && !_fDownloadMadeProgress) {
				_nPctReportedComplete = nPctDone;
				_fnProgress(strAction, nPctDone/2);
				var nBytesDone:Number = nPctDone * _upldr.filesize;
				if (!_upldr.useAsyncIO)
					_fAsyncIO = false;
				if (_fAsyncIO && nBytesDone > 1000 && !_dnldr.started) {
					_dnldr.fid = _upldr.fid;
					_dnldr.StartWithRetry();
				}
			}
		}

		private function OnDownloadProgress(strAction:String, nPctDone:Number): void {
			if (_fCanceled) return;
			if (_fnProgress != null && nPctDone > 0) {
				_fDownloadMadeProgress = true;
				var nPctTotalDone:Number = (_nPctReportedComplete/2) + (1-(_nPctReportedComplete/2)) * nPctDone;
				_fnProgress(null, nPctTotalDone);
			}
		}

		private function OnDownloadComplete(err:Number, strError:String, dnldr:FileTransferBase): void {
			if (_fCanceled || _fReturned) return;
			
			if (err == ImageDocument.errNone && imgd == null) {
				// Download success without an image? Wait a while, then return a custom error.
				// If the download failed, wait a bit for the upload to fail before returning a non-error
				var fnReturn:Function = function(evt:Event): void {
					if (_fReturned || _fCanceled) return;
					_fReturned = true;
					LogComplete("downloading: imgd == null");
					_fnComplete(ImageDocument.errBaseImageDownloadFailed, "downloading: Unknown error");
				}
				
				var tmr:Timer = new Timer(300, 1);
				tmr.addEventListener(TimerEvent.TIMER, fnReturn);
				tmr.start();
			} else {
				_fReturned = true;
				
				// We're done. Log success (if we were successful)
				if (err == ImageDocument.errNone && dnldr is Downloader && !_fLocalLoad && _upldr != null) {
					var nTotalTime:Number = Downloader(dnldr)._nTimeComplete - _upldr._nStartTime;
					var strMessage:String = "UploadTime," + (_fAsyncIO ? "Async" : "Sync") + "," + nTotalTime + "," + Downloader(dnldr)._nBytes;
					PicnikService.Log(strMessage, PicnikService.knLogSeverityMonitor);
				} 
				
				
				LogComplete((err == ImageDocument.errNone) ? null : "downloading: " + strError);
				_fnComplete(err, "downloading: " + strError, this);
			}
		}
		
		// Load the file directly from the local filesystem. Handle a number of conditions:
		// - file formats the client doesn't know how to handle: TIFF, BMP, PCX, PDF
		// - image dimensions the client can't handle: >4000x4000
		// - SWFs! Prevent Actionscript code injection attacks.
		// - local load failure -- assume FileReference.upload would also fail in this case.
		// - file size is greater than what we accept as an upload (16MB)
		//
		// If the local load failed to pull in the bits or the file is a format Picnik can't
		// handle at all, return failure to the caller.
		// If the local load succeeded but the client can't deal with the image due to format or
		// or dimensions, kick off the upload to the server w/ simultaneous download (business as
		// usual).
		// If the local load succeeded, kick off the upload to the server w/o simultaneous download.
		private function LocalLoad(): void {
			var ftb:FileTransferBase = this;  // Because anonymous functions have funny ideas about 'this'
			
			isLocal = true;
			
			try {
				if (_frLocalLoad.size >= 1 << 24) {
					Cancel(); // Cleanup
					LogComplete("File bigger than 16mb", true);
					_fnComplete(ImageDocument.errUploadExceedsSizeLimit, "The file exceeds Picnik's 16 megabyte limit", ftb);
					_frLocalLoad = null;
					return;
				}
			} catch (e:Error) {
				// Error can be thrown if file size is 0. An open question is whether the file size is
				// truly 0 or just unknow and the file is still able to be uploaded.
			}
			
			var fnOnLocalLoadComplete:Function = function (err:Number, strError:String=null): void {
//				trace("fnOnLocalLoadComplete: " + (getTimer() - cmsStart));
				if (err != ImageDocument.errNone) {
					Cancel(); // Cleanup
					LogComplete("Local load failed: " + err + ", " + strError);
					_fnComplete(err, strError, ftb);
					_frLocalLoad = null;
					return;
				}
				
				var baData:ByteArray = ("dataOverride" in _frLocalLoad) ? _frLocalLoad["dataOverride"] : _frLocalLoad.data;
				
				// NOTE: Log calls use _frLocalLoad for context so don't clear it out until we're done
				// reporting local load errors.
				_frLocalLoad = null;

				// Sniff the loaded bits. If it smells like a SWF avoid potential Actionscript injection
				// attacks by not Loader.loadBytes it.
				var b1:int = baData.readUnsignedByte(); // 'F'? or 'C'?
				var b2:int = baData.readUnsignedByte(); // 'W'?
				var b3:int = baData.readUnsignedByte(); // 'S'?
				if ((b1 == 0x46 || b1 == 0x43) && b2 == 0x57 && b3 == 0x53) {
					Cancel(); // Cleanup
					_fnComplete(ImageDocument.errUnsupportedFileFormat, "Unsupported file format", ftb);
					return;
				}
				baData.position = 0;
				
				// UNDONE: write a TIFF importer
				// UNDONE: write a BMP importer
				// UNDONE: write a PDF importer
				// UNDONE: write a PCX importer
				// Right now these formats all cause Loader.loadBytes to fail in which case we fall
				// back to the slow, resource intensive upload/convert/download approach.
				
				var ldr:Loader = new Loader();
				var fnOnLoadBytesComplete:Function = function (evt:Event): void {
//					trace("fnOnLoadBytesComplete: " + (getTimer() - cmsStart));
					var bm:Bitmap;
					var bmdDispose:BitmapData = null;
					try {
						ExtractMetadata(ldr);
						
						// If the content was not successfully instantiated as a Bitmap forget all about local
						// loading and do things the slow way (upload/convert/download).
						
						// BST: 12/30/09:We have some cases where the bitmap is non-null but the size is 0x0
						// We should treat this as a load failure and fall back to the old upload method.
						bm = ldr.content as Bitmap;
						if (bm == null || bm.width == 0 || bm.height == 0) {
							_upldr.Start();
							return;
						}
						
						transferType = "local";
						
						// If the loaded Bitmap exceeds our dimension limits, scale it down.
						var ptT:Point = Util.GetLimitedImageSize(bm.width, bm.height);
						var cxNew:int = ptT.x;
						var cyNew:int = ptT.y;
						if (bm.width > cxNew || bm.height > cyNew) {
	//						trace("local loaded bitmap is too big: " + bm.width + "x" + bm.height + " -> " + cxNew + "x" + cyNew);
							
							var bmdNew:BitmapData = DrawUtil.GetResizedBitmapData(bm, cxNew, cyNew, true);
							bmdDispose = bmdNew; // Make sure we clean up when we are done
							if (!bmdNew) {
								Cancel(); // Cleanup
								LogComplete("out of memory");
								_fnComplete(ImageDocument.errOutOfMemory, "Out of memory", ftb);
								return;
							}
							
							var bmdOld:BitmapData = bm.bitmapData;
							bm.bitmapData = bmdNew;
							bmdOld.dispose();
						}
					} catch (e:Error) {
						err = ImageDocument.errBaseImageLocalLoadFailed;
						strError = "Exception:1: " + e;
						Cancel(); // Cleanup
						LogComplete("Local load init err: " + err + ": " + strError);
						_fnComplete(err, strError, ftb);
						return;
					}
					
					try {
						var imgd:ImageDocument = new ImageDocument();
						var strId:String = itemInfo.title ? itemInfo.title.substr(0, ImageDocument.kcchFileNameMax) : null;
						err = imgd.InitFromDisplayObject(strId, ImageDocument.kfidAwaitingBackgroundUpload, bm, itemInfo.asImageProperties());
						if (bmdDispose != null)
							bmdDispose.dispose();
						if (err != ImageDocument.errNone) {
							strError = "Failed to initialize: " + err;
							try {
								strError += "{bm:";
								strError += bm;
								strError += "." + bm.width + "x" + bm.height;
								if (bm != null) {
									strError += "|bmd:" + bm.bitmapData;
									if (bm.bitmapData != null) {
										strError += "." + bm.bitmapData.width + "x" + bm.bitmapData.height;
									}
								}
								strError += "}";
							} catch (e:Error) {
								trace("Ignoring: " + e + ", " + e.getStackTrace());
							}
							
						}
					} catch (e:Error) {
						err = ImageDocument.errBaseImageLocalLoadFailed;
						strError = "Exception:2: " + e;
						
						// A little extra info to help catch some ArgumentError exceptions being logged
						if (e.errorID == 2015)
							strError += "itemInfo.title: " + itemInfo.title + ", ldr.content: " + ldr.content + ", itemInfo: " + itemInfo;
					}
					
					if (err != ImageDocument.errNone) {
						Cancel(); // Cleanup
						LogComplete(strError);
						_fnComplete(err, strError, ftb);
						return;
					}
					_imgd = imgd;
					
					// Return the locally loaded image to the caller
					_fnComplete(ImageDocument.errNone, null, ftb);
					
					// Start the upload of the image to the server, but w/o a corresponding download
					// - update the imgd with a fid after the upload successfully completes
					
					// Let the uploader log the result (success/failure)
					_upldr = new Uploader(_fr, "upDownBgnd", OnBackgroundUploadComplete, OnBackgroundUploadProgress, null, true);
					_imgd.uploaderInProgress = _upldr;
					_upldr.StartWithRetry();
					Util.EnableNavigateAwayWarning(Resource.getString("UploadDownloader", "navigate_away_warning"));
				}
				
				var fnOnLoadBytesIOError:Function = function (evt:IOErrorEvent): void {
//					trace("fnOnLoadBytesIOError: " + evt);
					//if (evt.text.indexOf("#2124") != -1) // "Error #2124: Loaded file is an unknown type."
					_upldr.Start();
				}
				
				ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, fnOnLoadBytesComplete);
				ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, fnOnLoadBytesIOError);
				ldr.loadBytes(baData);
			}
			
			var fnOnLocalLoadProgress:Function = function (cbLoaded:Number, cbTotal:Number): void {
//				trace("fnOnLocalLoadProgress: " + cbLoaded + " of " + cbTotal);
			}
			
			// Read the file data
			try {
				var cmsStart:int = getTimer();
				var iul:ImageUploadListener = new ImageUploadListener(_frLocalLoad, fnOnLocalLoadProgress, fnOnLocalLoadComplete);
				if ("LoadOverride" in _frLocalLoad)
					_frLocalLoad["LoadOverride"]();
				else
					_frLocalLoad.load();
			} catch (e:Error) {
				LogComplete("Exception:3: " + e);
				_fnComplete(ImageDocument.errBaseImageLocalLoadFailed, "Exception:3: " + e, ftb);
			}
		}
		
		private function OnBackgroundUploadComplete(err:Number, strError:String, upldr:FileTransferBase): void {
//			trace("OnBackgroundUploadComplete: " + err + ", " + strError);
			_imgd.uploaderInProgress = null;
			if (err == ImageDocument.errNone) {
				_imgd.baseImageFileId = _upldr.fid;
				Util.DisableNavigateAwayWarning();
			} else {
				// Only show this dialog if the user can't do a local save
				if (!Util.DoesUserHaveLocalSaveFlashPlayerAndBrowser()) {
					EasyDialogBase.Show(Application.application as UIComponent,
							[Resource.getString("MyComputerInBridge", "retry_upload_now"),
								Resource.getString("MyComputerInBridge", "retry_upload_at_save")],
							Resource.getString("MyComputerInBridge", "upload_failed_title"),
							Resource.getString("MyComputerInBridge", "upload_failed_message"),
							function (obResult:Object): void {
								// success means retry now
								_upldr.Cancel();
								if (obResult.success) {
									_upldr = new Uploader(_fr, "upDownPromptBgndRetry", OnBackgroundUploadComplete, OnBackgroundUploadProgress, null, true);
									// Let this one log the results.
									_imgd.uploaderInProgress = _upldr;
									_upldr.StartWithRetry();
								} else {
									// Prep the ImageDocument so we'll retry the upload at save time
									_imgd.failedUpload = _fr;
								}
							});
				}
			}
		}
		
		private function OnBackgroundUploadProgress(strAction:String, nPctDone:Number): void {
//			trace("OnBackgroundUploadProgress: " + strAction + ", " + nPctDone);
		}
	}
}
