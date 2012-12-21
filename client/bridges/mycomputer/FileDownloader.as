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
	import dialogs.EasyDialogBase;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	
	import imagine.imageOperations.FishEyeImageOperation;
	
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.resources.ResourceBundle;
	
	import util.LocUtil;

	[Event(name="do_basic_download", type="flash.events.Event")]

	public class FileDownloader extends EventDispatcher
	{
		private var _idnldParent:IDownloadParent;
		private var _urlr:URLRequest;
		private var _ba:ByteArray;
		private var _fr:FileReference;

   		[ResourceBundle("MyComputerOutBridge")] private var _rb:ResourceBundle;

		public function FileDownloader(idnldParent:IDownloadParent) {
			_idnldParent = idnldParent;
		}

		// strError is either IOError or SecurityError
		// strErrorText is evt.text
		private function HandleError(strErrorType:String, strErrorText:String, fSaveOver:Boolean, strFileName:String, fImmediateFailure:Boolean=false): void {
			// PicnikService.knLogSeverityWarning;
			var strError:String = "ERROR:out.bridge.mycomputer." + (_ba ? "localsave." : "download.") + strErrorType + ": " + strErrorText + ", " + GetCapabilities() + ", " + fSaveOver + ", " + strFileName;
			trace(strError);
			if (strError.length > 1010) strError = strError.substr(0,1010) + "...";
			// UNDONE: only send this when the user gives up?
			PicnikService.Log(strError, PicnikService.knLogSeverityWarning);
			
			var strButton1:String = Resource.getString("MyComputerOutBridge", fSaveOver ? "rename_download" : "ok");
			var strButton2:String = Resource.getString("MyComputerOutBridge", "BasicDownloader");
 			var strMessage:String = Resource.getString("MyComputerOutBridge", fSaveOver ? "failed_to_download_over": "failed_to_download");
 			
 			if (!Util.FlashVersionIsAtLeast([10, 0 , 32, 0])) {
 				var strUpgrade:String = Resource.getString("MyComputerOutBridge", "upgradeFlash");
 				strUpgrade = strUpgrade.replace('"event:"', '"http://www.adobe.com/go/getflashplayer" target="_blank"');
 				strMessage += "\n<br/>\n<br/>" + strUpgrade;
 			}
 			
 			var fFailedVistaSave:Boolean = false;
			
			// If this is an IOError #2038 during a local save, the OS is Vista, and the browser
			// is IE then most likely the problem is that the user's browser is running in Protected
			// Mode which limits saving to the Desktop directory. Present the user with the option
			// to add Picnik to their trusted sites and try again or fall back to the remotely
			// rendered download solution. UNDONE: falling back to basic downloader for now
			if (fImmediateFailure) {
				// UNDONE: Special message in this case? Upgrade your browser?
			} else if (strErrorType == "IOError" && _ba != null && Util.IsVista() && Util.IsInternetExplorer()) {
				fFailedVistaSave = true;
				strMessage = Resource.getString("MyComputerOutBridge", "failed_vista_local_save");
				strButton1 = Resource.getString("MyComputerOutBridge", "try_again");
				strButton2 = Resource.getString("MyComputerOutBridge", "download_save");
			}
			
			var fnOnClick:Function = function(obResult:Object): void {
				if (obResult && obResult['success']) {
					if (fFailedVistaSave) {
						dispatchEvent(new Event("try_again_download"));
					} else if (fSaveOver) {
						// clicked the first button && trying to overwrite: rename the download
						dispatchEvent(new Event("do_renamed_download"));
					}
				} else {
					if (fFailedVistaSave) {
						dispatchEvent(new Event("do_render_download"));
					} else {
						// in both cases, clicking the 2nd button leads to Basic Downloader
						dispatchEvent(new Event("do_basic_download"));
					}
				}
			}

			EasyDialogBase.Show(Application.application as UIComponent,
					[strButton1, strButton2],
					Resource.getString("MyComputerOutBridge", "failed_to_download_title"),
					strMessage, fnOnClick, false);
		}

		public function Download(urlr:URLRequest, baData:ByteArray, strExtension:String, strFileName:String): void {
			var strDebug:String = "1";
			try {
				_urlr = urlr;
				_ba = baData;
				
				// This must be called directly in response to (on the stack of) a mouse click
				var fnRetry:Function = function(): void {
					new FileDownloader(_idnldParent).Download(urlr, baData, strExtension, strFileName);
				}
				
				var fCanceled:Boolean = false;
				
				var fnCancel:Function = function(): void {
					// FileReference.cancel has no effect on FileReference.save (FP bug!) other than
					// being really slow.
					if (_fr != null && _ba == null)
						_fr.cancel(); // Make sure we stop the download
					fCanceled = true;
				}
				
				var fSaveOver:Boolean = false;
				var strSaveFileName:String = "<unknown>";
				
				var fnOnSelect:Function = function(evt:Event): void {
					_idnldParent.SetFileNameBase(GetBase(_fr.name));
					
					// The user chose a target. We can look at _fr.name to see the file name. Make sure it is valid
					if (!FileNameValid(_fr.name, strExtension)) {
						fnCancel();
						strFileName = GetBase(_fr.name) + "." + strExtension;
						
						[ResourceBundle("BadFileNameDialog")] var rb:ResourceBundle;
						var strHeadline:String = Resource.getString('BadFileNameDialog', '_txtHeader');
						var strText:String = LocUtil.rbSubst('BadFileNameDialog', '_txtBody',
							_fr.name, strExtension, strFileName);
						
						EasyDialogBase.Show(
							_idnldParent.component,
							[Resource.getString('BadFileNameDialog', '_btnYes'), Resource.getString('BadFileNameDialog', '_btnCancel')],
							strHeadline,
							strText,
							fnRetry);
					} else {
						// Show the busy dialog
						_idnldParent.DownloadStarted(fnOnDownloadCancel);
					}
					try {
						var nSize:Number = _fr.size;
						fSaveOver = true;
					} catch (e2:Error) {
						fSaveOver = false;
					}
					strSaveFileName = _fr.name;
				}
				
				var fnOnOpen:Function = function(evt:Event): void {
					if (fCanceled)
						fnCancel(); // Make sure we cancel
				}
				
				var fnOnDownloadCancel:Function = function(dctResult:Object): void {
					// User canceled the download while it was in progress.
					if (fCanceled) return;
					fnCancel();
					_idnldParent.DownloadFinished(false);
				}
				
				var fnOnProgress:Function = function(evt:ProgressEvent): void {
					if (fCanceled) return;
					_idnldParent.DownloadProgress(evt);
				}
				
				var fnOnComplete:Function = function(evt:Event): void {
					if (fCanceled) return;
					_idnldParent.DownloadFinished(true, _fr.name);
				}
				
				var fnOnSecurityError:Function = function(evt:SecurityErrorEvent): void {
					if (fCanceled) return;
					_idnldParent.DownloadFinished(false);
					HandleError("SecurityError", evt.text, fSaveOver, strSaveFileName);
				}
		
				var fnOnIOError:Function = function(evt:IOErrorEvent): void {
					if (fCanceled) return;
					_idnldParent.DownloadFinished(false);
					HandleError("IOError", evt.text, fSaveOver, strSaveFileName);
				}
				
				var nStartTime:Number = new Date().time;
				
				var fnOnCancelSelect:Function = function(evt:Event): void {
					if (fCanceled) return;
					var nCancelTime:Number = new Date().time;
					_idnldParent.DownloadFinished(false);
					if ((nCancelTime - nStartTime) < 75) { // 75 ms is too fast for a user. Must have been "auto-closed"
						// Auto-canceled. Protected mode problem.
						HandleError("IOError", "ProtectedModeAutoCancelBug", fSaveOver, strSaveFileName, true); 
					}
				}
				
				strDebug = "2";
			
				_fr = new FileReference();
				strDebug = "3";
				_fr.addEventListener(Event.SELECT, fnOnSelect);
				_fr.addEventListener(ProgressEvent.PROGRESS, fnOnProgress);
				_fr.addEventListener(Event.OPEN, fnOnOpen);
				_fr.addEventListener(Event.COMPLETE, fnOnComplete);
				_fr.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnOnSecurityError);
				_fr.addEventListener(IOErrorEvent.IO_ERROR, fnOnIOError);
				_fr.addEventListener(Event.CANCEL, fnOnCancelSelect);
				strDebug = "4";
	
				if (_ba)
					_fr.save(_ba, strFileName);
				else
					_fr.download(urlr, strFileName);
				strDebug = "5";
			} catch (e:Error) {
				if (e.errorID == 2087) {
					Util.ShowAlert(
						Resource.getString("MyComputerOutBridge", "bad_filename"),
						Resource.getString("MyComputerOutBridge", "Error"),
							Alert.OK, "ERROR:out.bridge.mycomputer.FileDownloader.Download.badfilename ");
				} else {
					throw new Error("Exception in FileDownloader.Download[" + strDebug + "]: " + e + ", " + _fr + ", " + _urlr + ", " + GetCapabilities());
				}
			}
		}

		// Returns the file base name (no extension, no dot)
		private function GetBase(strFullName:String): String {
			var nBreakPos:Number = strFullName.lastIndexOf(".");
			if (nBreakPos > -1) return strFullName.substr(0, nBreakPos);
			else return strFullName;
		}

		// Returns the file extension (without the dot)
		private function GetExtension(strFullName:String): String {
			var nBreakPos:Number = strFullName.lastIndexOf(".");
			if (nBreakPos > -1) return strFullName.substr(nBreakPos + 1);
			else return strFullName;
		}

		private function FileNameValid(strFullName:String, strRequiredExtension:String): Boolean {
			var strExt:String = GetExtension(strFullName).toLowerCase();
			strRequiredExtension = strRequiredExtension.toLowerCase();
			
			if (strExt == strRequiredExtension) return true;
			if (strExt.length == 0) return false;
			if (strRequiredExtension == "tif") {
				if (strExt == "tiff") return true;
			} else if (strRequiredExtension == "jpg") {
				if (strExt == "jpeg") return true;
				if (strExt == "jfif") return true;
			}
			return false;
		}
		
		private function GetCapabilities(): String {
			var strCap:String = "";
			
			strCap += Capabilities.os + ", " + Capabilities.version + ", " + Capabilities.isDebugger + ", " + Util.userAgent;
			
			// _urlr is null when local saving
			strCap += (_urlr && _urlr.url) ? _urlr.url : "null";
			return strCap;
		}
	}
}
