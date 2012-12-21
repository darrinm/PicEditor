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
package bridges.mycomputer
{
	import bridges.Bridge;
	import bridges.Downloader;
	import bridges.FileTransferBase;
	import bridges.UploadDownloader;
	import bridges.Uploader;
	import bridges.picnik.PicnikStorageService;
	
	import dialogs.BusyDialogBase;
	import dialogs.EasyDialogBase;
	import dialogs.IBusyDialog;
	import dialogs.UploadLimitExceededDialog;
	
	import events.NavigationEvent;
	
	import flash.errors.IOError;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.net.URLRequest;
	
	import imagine.ImageDocument;
	
	import mx.core.UIComponent;
	import mx.resources.ResourceBundle;
	import mx.utils.URLUtil;
	
	import util.Navigation;
	
	/*** Virtual MyComputer In Bridge
	 * This is a helper class that can be used
	 * to perform uploads from anywhere
	 */
	public class UploadInterface
	{
		protected var _bsy:IBusyDialog;
		private var _nFileListLimit:Number = 0;
		private var _nFileUploadLimit:Number = 0;
		
		public static const knGuestFileListLimit:Number = 1;
		public static const knRegisteredFileListLimit:Number = 5;
		public static const knPaidFileListLimit:Number = 100;

   		[ResourceBundle("MyComputerInBridge")] private var _rb:ResourceBundle;

		private var _dnldr:FileTransferBase = null;
		private var _fr:FileReference;
		private var _frl:FileReferenceList = null;
		public var _fDownloadingSample:Boolean = false;
		private var _fUploadForOpen:Boolean = true;
		private var _fDownloadStarted:Boolean = false;
		
		private var _evtPostLoadDestination:NavigationEvent = null;
		private var _strPostLoadDestination:String = null;
		
		public var _tpa:ThirdPartyAccount; // UNDONE: Do we need this?
		
		private var _uicOwner:UIComponent;

		public function UploadInterface(owner:UIComponent) {
			// UNDONE: loc "Recent Uploads"?
			_uicOwner = owner;
			_tpa = new ThirdPartyAccount("RecentImports", new PicnikStorageService("i_mycomput", "recentuploads", "Recent Uploads"));
			_nFileListLimit = knPaidFileListLimit;
			_nFileUploadLimit = knPaidFileListLimit;
		}
		
		private function get picnikStorageService():PicnikStorageService {
			return _tpa.storageService as PicnikStorageService;
		}
		
		private function HideBusyDialog(): void {
			if (_bsy) {
				_bsy.Hide();
				_bsy = null;	
			}
		}
		
		public static function GetFileListLimitForUserType(fIsPaid:Boolean, fIsGuest:Boolean): Number {
			var nFileListLimit:Number;
			
			if (fIsPaid)
				nFileListLimit = knPaidFileListLimit;
			else if (!fIsGuest)
				nFileListLimit = knRegisteredFileListLimit;
			else
				nFileListLimit = knGuestFileListLimit;

			if (nFileListLimit < 1) nFileListLimit = 1;
			return Math.round(nFileListLimit);
		}
		
		private function Initialize(): void {
			HideBusyDialog();
			var actm:AccountMgr = AccountMgr.GetInstance();
			_nFileListLimit = GetFileListLimitForUserType(actm.isPaid, actm.isGuest);
			_nFileUploadLimit = GetFileListLimitForUserType(actm.isPaid, actm.isGuest);
		}
		
		public static function MakeImageFileFilter(): Array {
			var afltr:Array = [
				new FileFilter(
					"Images (*.JPG;*.GIF;*.PNG;*.BMP;*.TGA;*.TIF;*.TIFF;*.XBM;*.PPM;*.JPEG;*.JPE)",
					"*.jpg; *.jpeg; *.jpe; *.gif; *.png; *.bmp; *.tif; *.tiff; *.tga; *.xbm; *.ppm;" +
					"*.JPG; *.JPEG; *.JPE; *.GIF; *.PNG; *.BMP; *.TIF; *.TIFF; *.TGA; *.XBM; *.PPM;",
					// UNDONE: I have no idea if these are the right 'macType's
					"JPEG;GIF;PNG;BMP;TIFF;TGA;XBM;PPM"
				),
				new FileFilter("All Files (*.*)", "*.*", "????")
			];
			return afltr;
		}
		
		public function SingleFileUpload(fnOnComplete:Function): void {
			DoUploadTo(false, new NavigationEvent(null, null, null), true); // Go nowhere
		}

		public function DoUpload(fUploadForOpen:Boolean=true, fGoToCreate:Boolean=false): void {
			_strPostLoadDestination = fGoToCreate ? PicnikBase.EDIT_CREATE_TAB: null;
			DoUploadTo(fUploadForOpen, null);
		}

		public function DoUploadTo(fUploadForOpen:Boolean=true, evtPostLoadDestination:NavigationEvent=null, fSingleFileUpload:Boolean=false): void {
			Initialize();
			if (fSingleFileUpload)
				_nFileUploadLimit = 1;
			_fUploadForOpen = fUploadForOpen;
			
			_evtPostLoadDestination = evtPostLoadDestination;
			
			var afltr:Array = MakeImageFileFilter();

			// NOTE: we MUST hold a reference to the FileReference instance or it will go away
			var fSuccess:Boolean;
			
			if (_nFileUploadLimit == 1) {
				_fr = new FileReference();
				_fr.addEventListener(Event.SELECT, OnFileSelect);
				fSuccess = _fr.browse(afltr);
				_frl = null;
			} else {
				_frl = new FileReferenceList();
				_frl.addEventListener(Event.SELECT, OnFileSelect);
				fSuccess = _frl.browse(afltr);
				_fr = null;
			}
			Debug.Assert(fSuccess, "FileReference.browse failed");
		}
		
		private function ShowLimitDialog(): void {
			UploadLimitExceededDialog.Show(PicnikBase.app, _nFileUploadLimit);
		}
		
		// aiinfPending is an array of ItemInfos, one for each pending upload
		protected function OnAddedNewFids(aiinfPending:Array): void {
			// Override in sub-classes
			// mcib.RefreshItemlist()
			// mcib._tlst.AnimateScrollToHead();
		}
		
		protected function ValidateOverwrite(fnContinue:Function, fnCanceled:Function=null): void {
			// Override in sub-classes
			fnContinue();
		}
		
		private function UploadSynchronously(afr:Array): void {
			if (afr.length > _nFileUploadLimit) {
				afr.length = _nFileUploadLimit;
				ShowLimitDialog();
			}
			afr = afr.reverse();
			var fnOnCreateManyFiles:Function = function(err:Number, strError:String, aobCreated:Array=null): void {
				try {
					if (err != PicnikService.errNone) {
						// Show an error
						ReportError(".onCreateManyFiles", err, strError);
					} else {
						
						// Create the impage props and add them to our tile list
						var aiinfPending:Array = [];
						for (var i:Number = 0; i < afr.length && i < aobCreated.length; i++) {
							var upldr:Uploader = new Uploader(afr[i], "inMulti", null, null, aobCreated[i].fid);
							upldr.importurl = aobCreated[i].importurl;
							upldr.StartWithRetry();
							picnikStorageService.PushNewFid(upldr.fid, afr[i]);
							aiinfPending.push(upldr.itemInfo);
						}
						// We have our FIDs. Now load them
						OnAddedNewFids(aiinfPending);
					}
				} catch (e:Error) {
					ReportException(".onCreateManyFiles", e);
				}
			}
			
			// First, create the file references - note, this may break for flash 10?
			PicnikService.CreateManyFiles(afr.length, {"strType": "i_mycomput"}, fnOnCreateManyFiles);
		}
		
		private function OnFileSelect(evt:Event): void {
			try {
				if (_fr) {
					_fr.removeEventListener(Event.SELECT, OnFileSelect);
				} else {
					_frl.removeEventListener(Event.SELECT, OnFileSelect);
				}
				_fDownloadingSample = false;
				
				var afrSource:Array = _fr ? [ _fr ] : _frl.fileList;
				
				// Report the upload
				// We want to look in GA and see:
				// Distribution of # of files opened
				// Times users exceed their limit
				// Log like this:
				//   /r/MultiFileUpload/{One or Many}/{Under or Over limit}/{Limit}/{Attempted}
				var strReport:String = "/MultiFileUpload/" + _nFileUploadLimit;
				strReport += (afrSource.length > 1) ? "/ManyFiles" : "/OneFile";
				strReport += (afrSource.length > _nFileUploadLimit) ? "/OverLimit" : "/UnderLimit";				
				strReport += "/" + afrSource.length;
				Util.UrchinLogReport(strReport);

				var afr:Array = [];
				var fError:Boolean = false;
				var err:Error = null;
				for each (var fr:FileReference in afrSource) {
					// Flash will throw an IOError exception if the file's size is zero, can't be opened or read,
					// or a similar error is encountered in accessing the file. Watch for it and report the
					// problem to the user.
					try {
						var cb:Number = fr.size;
						afr.push(fr);
					} catch (err1:IOError) {
						// "If the file cannot be opened or read, or if a similar error is encountered in accessing
						// the file, an exception is thrown with a message indicating a file I/O error."
						err = err1;
					} catch (err2:IllegalOperationError) {
						// "If the FileReference.browse(), FileReferenceList.browse(), or FileReference.download()
						// method was not called successfully, an exception is thrown with a message indicating that
						// functions were called in the incorrect sequence or an earlier call was unsuccessful."
						err = err2;
					}
				}
				
				if (afr.length == 1 && _fUploadForOpen) {
					_dnldr = new UploadDownloader(afr[0], "myComputerIn", OnComplete, OnProgress);
					ValidateOverwrite(DoUploadFile);
				} else if (afr.length > 0) {
					UploadSynchronously(afr);
				} else if (err != null) {
					ReportException(".select", err, "file_error");
				}				
				_fr = null;
				_frl = null;
			} catch (e:Error) {
				ReportException(".select.2", e);
			}
		}
		
		private function ReportError(strArea:String, err:Number, strError:String, strUserErrorKey:String="transfer_failed_upload", fInfo:Boolean=false): void {
			Util.AlertLogging("ERROR:in.bridge.mycomputer" + strArea + ": " + err + ", " + strError, null,
					fInfo ? PicnikService.knLogSeverityInfo : PicnikService.knLogSeverityWarning);
			ReportShowDialog(strUserErrorKey);
		}
		
		private function ReportException(strArea:String, e:Error, strUserErrorKey:String="transfer_failed_upload"): void {
			Util.AlertLogging("ERROR:in.bridge.mycomputer" + strArea + ": ", e);
			ReportShowDialog(strUserErrorKey);
		}

		// helper function for ReportError/ReportException.  Nobody else should call this.
		private function ReportShowDialog(strUserErrorKey:String): void {
			var f:Boolean = strUserErrorKey == "transfer_failed_upload";

			var astrButtons:Array = [];
			var strMsg:String;
			
			if (f) {
				astrButtons.push(Resource.getString("MyComputerInBridge", "retry_upload_basic"));
				astrButtons.push(Resource.getString("MyComputerInBridge", "Cancel"));
				strMsg = "upload_failed_message_basic";
			} else {
				astrButtons.push(Resource.getString("MyComputerInBridge", "OK"));
				strMsg = strUserErrorKey;
			}
					
			EasyDialogBase.Show(PicnikBase.app, astrButtons,
					Resource.getString("MyComputerInBridge", "upload_failed_title"),
					Resource.getString("MyComputerInBridge", strMsg),
					function (obResult:Object): void {
						// success means use the basic uploader, but only if we
						// get the generic failed-to-upload message, and not something
						// about file format, file size, etc, where the basic uploader
						// couldn't help
						if (f && obResult.success) {
							PicnikBase.app.NavigateToURL(new URLRequest(PicnikBase.gstrSoMgrServer +'/go/upload'));
						}
					});
		}
		
		private function DoUploadFile(): void {
			try {
				_bsy = BusyDialogBase.Show(_uicOwner, Resource.getString("MyComputerInBridge", "Uploading"), BusyDialogBase.LOAD_USER_IMAGE, "ProgressWithCancel", 0, OnBusyCancel);
				if (_dnldr) _dnldr.Start();
			} catch (e:Error) {
				ReportException(".DoUploadFile", e);
			}
		}

		public function LoadSample(strPath:String, evtPostLoadDest:NavigationEvent=null): void {
			Initialize();
			_evtPostLoadDestination = evtPostLoadDest;
			var strURL:String = URLUtil.getFullURL(PicnikService.serverURL, strPath);
			var imgp:ImageProperties = new ImageProperties("web", strURL);
			_dnldr = new Downloader(ItemInfo.FromImageProperties(imgp), "/MyComputerInBridge/sample", OnComplete, OnProgress);
			_fDownloadingSample = true;
			ValidateOverwrite(DoDownloadSampleImage);
		}
		
		private function DoDownloadSampleImage(): void {
			_bsy = BusyDialogBase.Show(_uicOwner, Resource.getString("MyComputerInBridge", "Downloading"), BusyDialogBase.LOAD_SAMPLE_IMAGE,
					"ProgressWithCancel", 0, OnBusyCancel);
			if (_dnldr) {
				_dnldr.transferType = "sample";
				_dnldr.StartWithRetry();	
			}
		}

		private function OnComplete(err:Number, strError:String, dnldr:FileTransferBase): void {
			try {
				HideBusyDialog(); // Comment out this line to keep the busy dialog around for testing/layout
				if (dnldr == null) {
					// we've been cancelled! do nothing!
					return;
				}
				if (err != ImageDocument.errNone || dnldr.imgd == null) {
					// Upload/download failed. Display an error.
					var strUserErrorKey:String = "transfer_failed_upload";
					var fInfo:Boolean = false;
					switch (err) {
					case ImageDocument.errUploadExceedsSizeLimit:
						strUserErrorKey = "upload_exceeds_limit";
						fInfo = true;
						break;
						
					case ImageDocument.errUnsupportedFileFormat:
						strUserErrorKey = "unsupported_file_format";
						fInfo = true;
						break;
					}
					ReportError(".OnComplete", err, strError, strUserErrorKey, fInfo);
				} else {
					ReportSuccess(dnldr.transferType);
					// Success! Open the image
					PicnikBase.app.activeDocument = dnldr.imgd;
					if (_evtPostLoadDestination)
						Navigation.GoToEvent(_evtPostLoadDestination);
					else if (_strPostLoadDestination) {
						PicnikBase.app.NavigateTo(_strPostLoadDestination);
						_strPostLoadDestination = null;
					} else
						PicnikBase.app.NavigateTo(PicnikBase.EDIT_CREATE_TAB);
				}
			} catch (e:Error) {
				ReportException(".OnComplete", e);
			}
			_dnldr = null;
		}

		private function ReportSuccess(strTransferType:String): void {
			Bridge.DoReportSuccess(false, _fDownloadingSample ? 'sample' : 'mycomputer', null, strTransferType);
		}

		private function OnProgress(strAction:String, nPctDone:Number): void {
			if (_bsy != null) {
				if (strAction != null) _bsy.message = strAction;
				_bsy.progress = nPctDone * 100;
			}
		}

		private function OnBusyCancel(dctResult:Object): void {
			_dnldr.UserCancel();
			_dnldr = null;
			HideBusyDialog();
		}
	}
}