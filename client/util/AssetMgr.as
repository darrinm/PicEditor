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
package util {
	import bridges.Uploader;
	import bridges.storageservice.StorageServiceRegistry;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import util.assets.ICreator;
	import util.assets.imported.ImportTracker;
	
	public class AssetMgr {
		static private var s_iul:ImageUploadListener;
		static private var s_urll:URLLoaderPlus;
		
		// public function fnComplete(err:Number, strError:String, dctProps:Array=null): void
		public static function GetFileProperties(fid:String, strProps:String, fnComplete:Function): void {
			var ipa:IPendingAsset = FindPendingAsset(fid);
			if (ipa != null) {
				ipa.GetFileProperties(strProps, fnComplete);
			} else {
				var fnOnGetProperties:Function = function(err:Number, strError:String, dctProps:Object=null): void {
					if (err != PicnikService.errNone) {
						fnComplete(err, strError);
					} else {
						// Got props. See if our load is complete
						// If we have an md5 sum, our state is loaded
						if (SafeGet(dctProps, "strMD5").length > 4) { // Loaded
							fnComplete(err, strError, dctProps);
						} else {
							// Not complete. See if it is loading
							var nImportStatus:Number = ImportTracker.Instance().GetImportStatus(fid);
							if (nImportStatus == ImportTracker.knFinished) {
								// Asset failed to import. Return an error.
								fnComplete(PicnikService.errFail, "Asset import failed");
							} else {
								// Reconnect to the outstanding import
								ipa = ImportManager.Instance().Reimport(fid, nImportStatus, ImportTracker.Instance().GetUrl(fid));
								ipa.GetFileProperties(strProps, fnComplete);
							}
						}
					}
				}
				PicnikService.GetFileProperties(fid, null, AddExtraProps(strProps), fnOnGetProperties);
			}
		}
		
		public static function FindPendingAsset(fid:String): IPendingAsset {
			var ipa:IPendingAsset = null;
			if (fid != null && fid.length > 0) {
				ipa = ImportManager.Instance().FindImportByFid(fid);
				if (ipa == null)
					ipa = UploadManager.GetUpload(fid);
			}
			return ipa;
		}
		
		// Callback signatures:
		//   fnCreated(err:Number, strError:String, fidCreated:String=null): void
		//   fnProgress(cbUploaded:Number, cbTotal:Number): void
		//   fnComplete(err:Number, strError:String, fidAsset:String=null): void
		public static function UploadAsset(fr:FileReference, fnCreated:Function, fnProgress:Function, fnComplete:Function, fidPreCreated:String=null, strPreImportUrl:String=null): Boolean {
			var fDone:Boolean = false;
			var fid:String = fidPreCreated;
			var fnOnUploadImageDone:Function = function (err:Number, strError:String, fidCreated:String=null, strImportUrl:String=null): void {
				s_iul = null;
				fDone = true;
				if (fnComplete != null)
					fnComplete(err, strError, fidCreated);
			}

			var fnOnCreateFile:Function = function (err:Number, strError:String, fidCreated:String=null, strAsyncImportUrl:String=null, strSyncImportUrl:String=null, strFallbackImportUrl:String=null): void {
				fid = fidCreated;
				
				if (fnCreated != null)
					fnCreated(err, strError, fidCreated);
					
				if (err != PicnikService.errNone) {
					s_iul = null;
					if (fnComplete != null)
						fnComplete(err, strError);
					return;
				}
				var strImportUrl:String = Uploader._fUseFallbackUploadUrls ? strFallbackImportUrl : strImportUrl;
				StartUpload(fr, strImportUrl);
			}
			
			// A reference must be kept to the FileReference somewhere until
			// the upload completes or it will be canceled when the object is garbage
			// collected. ImageUploadListener will hang on to fr so we have to hang
			// on to the ImageUploadListener.
			s_iul = new ImageUploadListener(fr, fnProgress, fnOnUploadImageDone);
			
			var obFileProps:Object = { strType:"i_mycomput" };
			if (fidPreCreated) {
				PicnikBase.app.callLater(fnOnCreateFile, [PicnikService.errNone, "no error", fidPreCreated, strPreImportUrl, strPreImportUrl, strPreImportUrl, strPreImportUrl]);
			} else {
				CreateAsset(obFileProps, fnOnCreateFile);
			}
			return true;
		}
		
		public static function SafeFilename(fr:FileReference): String {
			var strFilename:String = "";
			try {
				if (fr) strFilename = fr.name;
			} catch (e:Error) {
				// Ignore errors
			}
			return strFilename;
		}
		
		public static function SafeTitle(fr:FileReference): String {
			var strTitle:String = SafeFilename(fr);
			var nBreak:Number = strTitle.lastIndexOf('.');
			if (nBreak > 0) strTitle = strTitle.substr(0, nBreak);
			return strTitle;
		}
		
		public static function StartUpload(fr:FileReference, strImportUrl:String): void {
				// Let the server know the maximum image size this client can handle.
			strImportUrl = AppendMaxSizeParams(strImportUrl);
			var urlr:URLRequest = new URLRequest(strImportUrl);
			urlr.method = URLRequestMethod.POST;
			var urlVars:URLVariables = new URLVariables();
			try {
				// From the Flex 3 docs:
				// "The size of the file on the local disk in bytes. If size is 0, an exception is thrown."
				urlVars._filesize = fr.size;
			} catch (err:Error) {
				// The _filesize is optional
			}
			urlVars._fTemporary = AccountMgr.GetInstance().isGuest ? 1 : 0;
			urlVars._filename = SafeFilename(fr);
			urlVars._title = SafeTitle(fr);
			urlr.data = urlVars;
			
			fr.upload(urlr);
		}
		
		// Callback signatures:
		//   fnCreated(err:Number, strError:String, fidCreated:String=null): void
		//   fnProgress(cbUploaded:Number, cbTotal:Number): void
		//   fnComplete(err:Number, strError:String, fidAsset:String=null): void
		public static function PostAsset(baData:ByteArray, strContentType:String, strType:String, fTemporary:Boolean,
				fnCreated:Function, fnProgress:Function, fnComplete:Function): Boolean {
			var fnOnCreateFile:Function = function (err:Number, strError:String, fidCreated:String=null, strAsyncImportUrl:String=null, strSyncImportUrl:String=null, strFallbackImportUrl:String=null): void {
				if (fnCreated != null)
					fnCreated(err, strError, fidCreated);
					
				if (err != PicnikService.errNone) {
					s_urll = null;
					if (fnComplete != null)
						fnComplete(err, strError);
					return;
				}
				
				var fnOnUploadImageDone:Function = function (err:Number, strError:String): void {
					s_urll = null;
					if (fnComplete != null)
						fnComplete(err, strError, fidCreated);
				}
				
				// Let the server know the maximum image size this client can handle.
				// var strImportUrl:String = Uploader._fUseFallbackUploadUrls ? strFallbackImportUrl : strSyncImportUrl;
				var strImportUrl:String = strAsyncImportUrl;
				strImportUrl = AppendMaxSizeParams(strImportUrl);
				var urlr:URLRequest = new URLRequest(strImportUrl);
				urlr.method = "POST";
				urlr.data = baData;
				urlr.contentType = strContentType;
				s_urll = new URLLoaderPlus(); // Hang on to the URLLoader so it won't get GC'ed while pending
				new ImageUploadListener(s_urll, fnProgress, fnOnUploadImageDone);
				s_urll.load(urlr);
			}
			
			var obFileProps:Object = { fTemporary: fTemporary ? 1 : 0 };
			if (strType)
				obFileProps['strType'] = strType;
			CreateAsset(obFileProps, fnOnCreateFile);
			return true;
		}
		
		//public static function SerializeThumbSizes(anPreCreateSizes:Array): String {
		//	return anPreCreateSizes.join(',');
		//}		

		// Clone an asset
		//
		// Callback signatures:
		//   fnComplete(err:Number, strError:String, fidCreated:String=null): void
		public static function CloneAsset(fidToClone:String, strType:String, fnComplete:Function): Boolean {
			var obFileProps:Object = { fTemporary: 1 };
			if (strType)
				obFileProps['strType'] = strType;
			_CloneAsset(fidToClone, obFileProps, fnComplete);
			return true;
		}
		
		// Import an asset from a 3rd-party site. The import process will take in any image, make it
		// picnik.swf compatible (resize, reformat), and return a fid that can be used to construct
		// a URL to download the image. Callbacks are provided to deliver the fid immediately after
		// it is created and after the whole import is complete. Downloads can begin from the fid
		// as soon as it is returned and the download will happen in parallel with the import.
		//
		// If a special parameter "_cookie" is appended to strUrl it will be stripped and passed
		// as a "cookie" parameter to the fileimport request.
		//
		// Callback signatures:
		//   fnCreated(err:Number, strError:String, fidCreated:String=null): void
		//   fnProgress(cbUploaded:Number, cbTotal:Number): void
		//   fnComplete(err:Number, strError:String, fidAsset:String=null): void
		public static function ImportAsset(strUrl:String, strType:String, fTemporary:Boolean, fnCreated:Function, fnProgress:Function, fnComplete:Function, ctr:ICreator): Boolean {
			Debug.Assert(ctr != null);
			var fnOnCreateFile:Function = function (err:Number, strError:String, fidCreated:String=null, strImportUrl:String=null): void {
				if (fnCreated != null) {
					fnCreated(err, strError, fidCreated);
				}
					
				if (err != PicnikService.errNone) {
					if (fnComplete != null)
						fnComplete(err, strError);
					return;
				}
				
				// Some URLs need 3rd-party credentials appended to them before they can be used to request
				// resources from the 3rd-party.
				strUrl = StorageServiceRegistry.GetResourceURL(strUrl);

				// Let the server know the maximum image size this client can handle.
				strImportUrl = AppendMaxSizeParams(strImportUrl);
				
				// HACK: If strUrl has our special _cookie parameter appended, strip it and add a cookie
				// parameter to the import url.
				var ichCookie:Number = strUrl.indexOf("&_cookie=");
				var strCookie:String = null;
				if (ichCookie != -1) {
					strCookie = decodeURIComponent(strUrl.slice(ichCookie + 9));
					strUrl = strUrl.slice(0, ichCookie);
				}
				
				var obParams:Object = { url: strUrl, fTemporary: fTemporary ? 1 : 0 };
				if (strCookie)
					obParams.cookie = strCookie;
				
				var urlr:URLRequest = new URLRequest(PicnikService.AppendParams(strImportUrl, obParams, false));
				var urll:URLLoader = new URLLoader();
				
				var nStart:Number = new Date().time;
				
				var fnOnLoadIOError:Function = function (evt:IOErrorEvent): void {
					var nEnd:Number = new Date().time;
					
					// UNDONE: import retrying
					ImportTracker.Instance().ImportCompleted(fidCreated);
					if (fnComplete != null)
						fnComplete(PicnikService.errFileIOError, "Failed to load");
					trace("Failed to load resource. milis = " + (nEnd - nStart) + ", fidCreated = " + fidCreated + ", evt.text = " + evt.text + ", url = " + urlr.url + ", strImportUrl = " + strImportUrl);
				}
				
				var fnOnLoadComplete:Function = function (evt:Event): void {
					ImportTracker.Instance().ImportCompleted(fidCreated);
					if (fnComplete != null)
						fnComplete(0, null, fidCreated);
				}
				
				urll.addEventListener(IOErrorEvent.IO_ERROR, fnOnLoadIOError);
				urll.addEventListener(Event.COMPLETE, fnOnLoadComplete);
				
				urll.load(urlr);
				ImportTracker.Instance().ImportStarted(fidCreated);
			}
			
			ctr.Create(fnOnCreateFile);
			return true;
		}
		
		// Callback signature:
		//   fnComplete(err:Number, strError:String, fidAsset:String=null, strAsyncImportUrl:String=null, strSyncImportUrl:String=null, strFallbackImportUrl:String=null): void
		public static function CreateAsset(dctProperties:Object, fnComplete:Function): void {
			PicnikService.CreateFile(dctProperties, fnComplete);
		}

		// Callback signature:
		//   fnComplete(err:Number, strError:String, fidAsset:String=null): void
		private static function _CloneAsset(fidToClone:String, dctProperties:Object, fnComplete:Function): void {
			PicnikService.CloneFile(fidToClone, dctProperties, fnComplete);
		}
		
		private static function AddExtraProps(strProps:String): String {
			var astrProps:Array = strProps.split(",");
			const kastrExtraProps:Array = ["strMD5"];
			for each (var strExtraProp:String in kastrExtraProps) {
				if (astrProps.indexOf(strExtraProp) == -1)
					astrProps.push(strExtraProp);
			}
			return astrProps.join(",");
		}

		// Looks up a string value in an object. Returns the default value if the key is missing or the value is null		
		private static function SafeGet(ob:Object, strKey:String, strDefault:String=""): String {
			var strVal:String = strDefault;
			if ((strKey in ob) && (ob[strKey] != null))
				strVal = ob[strKey];
			return strVal;
		}
		
		private static function AppendMaxSizeParams(strUrl:String): String {
			var cxMax:int = Util.GetMaxImageWidth(1);
			var cyMax:int = Util.GetMaxImageHeight(1);
			strUrl += strUrl.indexOf("?") == -1 ? "?" : "&";
			strUrl += "maxWidth=" + cxMax + "&maxHeight=" + cyMax;
			if (Util.GetFlashPlayerMajorVersion() >= 10)
				strUrl += "&maxPixels=" + Util.GetMaxImagePixels();
			return strUrl;
		}
	}
}
