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
// UNDONE: PerfectMemory support

package {
	import bridges.Bridge;
	import bridges.Downloader;
	import bridges.FileTransferBase;
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceUtil;
	
	import dialogs.BusyDialogBase;
	import dialogs.DialogManager;
	import dialogs.IBusyDialog;
	
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import imagine.ImageDocument;
	
	import mx.controls.Alert;
	import mx.resources.ResourceBundle;
	
	import util.Cancelable;
	import util.ExternalService;
	import util.LocUtil;
	import util.RenderHelper;
			
	public class PicnikAsService {
		private var _bsy:IBusyDialog;
		private var _obSvcParameters:Object = null;
		private var _obUserParameters:Object = null;
		private var _imgd:ImageDocument;
		private var _fActive:Boolean = false;
		private var _fReplace:Boolean = false; // "Global" used to remember state from Render to OnRender calls
		private var _canDownload:Cancelable;
			
  		[Bindable] [ResourceBundle("PicnikAsService")] protected var rb:ResourceBundle;

		[Bindable] public var exportButtonTitle:String;
		[Bindable] public var exportButtonHeight:Number = 20; // Default is 20
		[Bindable] public var googlePlusUI:Boolean = false; // Super lite has no accounts, no premium, no "open in Picnik", etc. Used for GooglePlus
		
		public function PicnikAsService(dctParameters:Object=null) {
			exportButtonTitle = Resource.getString('PicnikAsService', 'export');

			// Report any so messages
			if ('somsg' in PicnikBase.app.parameters) {
				PicnikService.Log("Using so params: " + unescape(PicnikBase.app.parameters['somsg']), PicnikService.knLogSeverityWarning);
			}
			
			// Load the service cookies
			_obSvcParameters = dctParameters ? dctParameters : GetCookiedParameters("svc_parameters");
			
			// BEGIN: Handle corrupted service paramters which contain only and "repeatLoad=true"
			// The bug which caused this state has been fixed, so this should eventually go away
			var fHasRealParams:Boolean = false;
			for (var strParam:String in _obSvcParameters) {
				if (strParam != "_repeatLoad") {
					fHasRealParams = true;
					break;
				}
			}
			if (!fHasRealParams) _obSvcParameters = null; 
			// END: Handle corrupted service paramters which contain only and "repeatLoad=true"

			
			_obUserParameters = GetCookiedParameters("svc_user_parameters");
			if (_obSvcParameters != null)
				_fActive = true;
			else {
				_obSvcParameters = new Object();
			}
			
			// If we were launched with a ?host=somebody parameter, then convert that host into an apikey
			if (!_obSvcParameters._apikey && PicnikBase.app.parameters["host"]) {
				_obSvcParameters._apikey = ServiceManager.HostToApiKey(PicnikBase.app.parameters["host"].toLowerCase());
				_fActive = true;
			}
			
			// copy default settings for some of our better-known API users.						
			if (_obSvcParameters._apikey) {
				var obDefaults:Object = ServiceManager.GetDefaultParameters(_obSvcParameters._apikey);
				if (obDefaults) {
					for (var param:String in obDefaults) {
						if (!(param in _obSvcParameters))
							_obSvcParameters[param] = obDefaults[param];
					}
				}
			}
							
			if (_obUserParameters == null)
				_obUserParameters = new Object();
				
			if (_fActive) { // We have service params
				_obSvcParameters.fFirstLoad = !("_repeatLoad" in _obSvcParameters);
				if (_obSvcParameters.fFirstLoad) {
					var strParameters:String = GetParamCookie("svc_parameters");
					if (strParameters && !('svc_parameters' in PicnikBase.app.parameters))
						Session.GetCurrent().SetSOCookie("svc_parameters", strParameters + "&_repeatLoad=true");
				}
				
				if (GetServiceParameter("_premium", "false") != "false") {
					PicnikConfig.freePremium = true;
				}				
			}
		}

		private function ClearSvcCookies(): void {
			Session.GetCurrent().SetSOCookie("svc_parameters", null);
			Session.GetCurrent().SetSOCookie("svc_user_parameters", null);
		}
		
		// Check to see if Picnik is being used as a service
		public function IsServiceActive(): Boolean {
			return _fActive;
		}
		
		// Return a string describing the service we're working with. This is machine-readable
		// guaranteed to be unique. Use GetServiceFriendlyName below if you plan to present the
		// name to humans.
		public function GetServiceName(): String {
			if (_fActive && _obSvcParameters._apikey)
				return ServiceManager.GetAttribute(_obSvcParameters._apikey, "service", null );
			return null;
		}
			
		public function GetServiceFriendlyName(): String {
			if (_fActive && _obSvcParameters._apikey)
				return ServiceManager.GetAttribute(_obSvcParameters._apikey, "friendly_name", null );
			return null;
		}
			
		[Bindable]
		public function get apikey(): String {
			return _obSvcParameters._apikey;
		}		
		public function set apikey(strApiKey:String): void {
			_obSvcParameters._apikey = strApiKey;
		}
				
		private function get isFirstLoad(): Boolean {
			return _obSvcParameters.fFirstLoad;
		}
		
		public function get willLoadServiceDocument(): Boolean {
			return _fActive && ((_obSvcParameters._import && isFirstLoad) || _obSvcParameters._ss_cmd);
		}

		public function GetServiceParameters(): Object {
			return _obSvcParameters;
		}
		
		public function GetServiceParameter( strParam:String, strDefault:String = ""): String {
			if ( !_obSvcParameters || !(strParam in _obSvcParameters) ) {
				return ServiceManager.GetAttribute(apikey, strParam, strDefault );
			}
			return String(_obSvcParameters[strParam]);
		}
		
		public function GetUserParameters(): Object {
			return _obUserParameters;
		}
		
		public function UpdateDeepLink(): void {
			if (!_fActive)
				return;
			
			// Navigate to the requested UI deep link, or /edit by default
			if (!PicnikBase.DeepLink || PicnikBase.DeepLink.length == 0)
				PicnikBase.DeepLink = "/edit";
				
			var strDefault:String = "/edit";
			if (PicnikBase.app.multiMode)
				strDefault = "/home/welcome";
			var gald:GalleryDocument = PicnikBase.app.activeDocument as GalleryDocument;
			if (gald != null)
				strDefault = "/gallery_share";
				
			if (IsServiceActive())
				PicnikBase.DeepLink = GetServiceParameter( "_page", strDefault );
		}
		
		// Returns true if we should hide the upgrade bar.  Usually this is because
		// Picnik appears embedded in a third party site.
		public function get hideUpgradeBar(): Boolean {
			if (!_fActive || _obSvcParameters == null || !("_apikey" in _obSvcParameters))
				return false;
			
			return ServiceManager.GetAttribute(_obSvcParameters._apikey, "hide_upgrade_bar", false);
		}
		
		public function get hideAllAds(): Boolean {
			if (!_fActive || _obSvcParameters == null || !("_apikey" in _obSvcParameters))
				return false;
			
			return GetServiceParameter("_noads", "false") != "false";
		}
		
		
		public function get hideFullscreenAds(): Boolean {
			if (!_fActive || _obSvcParameters == null || !("_apikey" in _obSvcParameters))
				return false;
			
			return hideAllAds || ServiceManager.GetAttribute(_obSvcParameters._apikey, "hide_fullscreen_ads", false);
		}
		
		public function get hideWelcomeTips(): Boolean {
			if (!_fActive || _obSvcParameters == null || !("_apikey" in _obSvcParameters))
				return false;
			
			return ServiceManager.GetAttribute(_obSvcParameters._apikey, "hide_welcome_tips", false);
		}
		
		public function get hideBannerAds(): Boolean {
			if (!_fActive || _obSvcParameters == null || !("_apikey" in _obSvcParameters))
				return false;
			
			return hideAllAds || ServiceManager.GetAttribute(_obSvcParameters._apikey, "hide_banner_ads", false);
		}
		
		public function get freemiumModel(): Boolean {
			if (!_fActive || _obSvcParameters == null || !("_apikey" in _obSvcParameters))
				return false;
			
			return ServiceManager.GetAttribute(_obSvcParameters._apikey, "freemium_model", false);
		}
		
		// Returns true if we should show the "lite" UI.
		public function get showLiteUI(): Boolean {
			if (!_fActive || _obSvcParameters == null || !("_apikey" in _obSvcParameters))
				return false;
			
			return ServiceManager.GetAttribute(_obSvcParameters._apikey, "lite_ui", false);
		}
		
		// Act on any service request		
		// Returns true if we're processing asynchronously (and therefore have popped some UI)
		public function ProcessServiceParametersPreUI(fnDone:Function): Boolean {
			if (!_fActive) {
				fnDone();
				return false;
			}

			if ('_export_button_height' in _obSvcParameters) {
				try {
					exportButtonHeight = Number(_obSvcParameters._export_button_height);
				} catch (e:Error) {
					trace("Ignoring exception: " + e.toString() + ", " + e.getStackTrace());
				}
			}
			
			if ('_google_plus_ui' in _obSvcParameters)
				googlePlusUI = String(_obSvcParameters._google_plus_ui).toLowerCase() == 'true';
			
			// Configure our UI for 'export' mode
			var strExport:String = _obSvcParameters._export;
			if (strExport) {
				var strExportLabel:String = _obSvcParameters._export_title;
				if (strExport == "FlickrExport") {
					strExportLabel = Resource.getString("PicnikAsService", "SaveToFlickr");
				}
				if (strExportLabel) {
					exportButtonTitle = strExportLabel;
				}

				// UNDONE: do we want to do this earlier?
				// Don't remove the cookie because we want to stay in export
				// mode even if the user refreshes the page.
			}
			
			// see if we're in "single doc" or "multi" modes			
			if (GetServiceParameter("_exclude").indexOf("in") != -1)			
				PicnikBase.app.singleDocMode = true;

			// Is service being invoked?
			var strSS:String = _obSvcParameters._ss;			
			if (!strSS) {
				fnDone();
				return false;
			}
			
			var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount(strSS);
			if (tpa == null) {
				fnDone();
				return false;
			}

			// extract multi information
			if (GetServiceParameter("_multi").length > 0) {
				PicnikBase.app.multi.defaultService = strSS;
				PicnikBase.app.multi.Deserialize( GetServiceParameter("_multi") );
			}

			var ss:IStorageService = tpa.storageService;
			
			// Define this callback as a closure so it will have convenient access to ss, tpa, fnDone, etc
			var fnOnServiceParamsProcessed:Function = function(err:Number, strError:String, dctResult:Object=null): void {
				
				if (err != StorageServiceError.None) {
					// clear the svc cookies so that we don't keep trying to load
					ClearSvcCookies();
					
					_bsy.Hide();
					_bsy = null;
					
					if (err == StorageServiceError.PendingAuth) {
						// we'll pop up a dialog asking the user to connect for further processing
						fnDone();
						return;
					}
					
					if (dctResult && dctResult.page)
						_obSvcParameters._page = dctResult.page;									

					PicnikBase.app.OnDownloadError( err, strError, true /*fRetry*/,
						function( obResult:Object ):void {
							if ('retry' in obResult && obResult['retry']) {
								ProcessServiceParametersPreUI( fnDone );
							} else {
								fnDone();
							}
						} );
					return;
				}

				var imgpToLoad:ImageProperties = null;
				var galleryToLoad:ItemInfo = null;
				
				if (dctResult.load) {
					var itemInfo:ItemInfo = dctResult.load;
					// NOTE: "show" as a species is legacy and has never been live
					if (itemInfo.hasOwnProperty("species") && (itemInfo.species == "show" || itemInfo.species == "gallery")) {
						galleryToLoad = itemInfo;
					} else {
						imgpToLoad = dctResult.load.asImageProperties();
					}
				}
				if (PicnikBase.app.multi.items && PicnikBase.app.multi.items.length > 0) {
					if (PicnikBase.app.multi.items.length > 1) {
						PicnikBase.app.multiMode = true;
						PicnikBase.app.activeDocument = null;								
						_bsy.Hide();
						_bsy = null;
						fnDone();
						return;
					} else {
						imgpToLoad = PicnikBase.app.multi.items[0].asImageProperties();
						PicnikBase.app.multi.RemoveItems();
					}
				}				

				var fnOnInitFromIdProgress:Function = function (nPercentDone:Number, strStatus:String): void {}

				if (imgpToLoad) {								
					// Test to see if there is a .pik file corresponding to this item (Perfect Memory)
					var imgd:ImageDocument = new ImageDocument();
					var strImageId:String = imgpToLoad./*bridge*/serviceid + "_" + imgpToLoad./*ss_item*/id;
					
					var fnOnInitFromIdComplete:Function = function (nError:Number, strError:String=null, xml:XML=null): void {
						if (nError != 0) {
							// No .pik file has been associated with this item; continue loading
							// it straight from the storage service.
							var fnOnDownloadComplete:Function = function (err:Number, strError:String, dnldr:FileTransferBase): void {
								fnDone();
								OnDownloadDone(err, strError, dnldr);
							}

							_canDownload = new Cancelable(this, fnOnDownloadComplete);
						
							// UNDONE: imgp.fCanLoadDirect
							var dnldr:Downloader = new Downloader(ItemInfo.FromImageProperties(imgpToLoad), "/PicnikAsService", _canDownload.callback,
									OnDownloadProgress);
							dnldr.Start();
							PicnikService.Log("PicnikAsService loading " + imgpToLoad.sourceurl);
						} else {
							// We were able to load from some magic local id
							// UNDONE: test this code path to make sure it works
							_bsy.Hide();
							_bsy = null;
							PicnikBase.app.activeDocument = imgd;								
							fnDone();
						}
					}
					
					var fnOnGetPerfectMemoryFid:Function = function (err:Number, strError:String, fid:String=null, strAssetMap:String=null): void {
						if (fid != null) {
							imgd.InitFromPicnikFile(fid, strAssetMap, imgpToLoad, fnOnInitFromIdProgress, fnOnInitFromIdComplete);
						} else {
							// UNDONE: old-style perfect memory lookup. Remove after build xx when old perfect memory
							// files are migrated and GetPerfectMemoryFid does the fallback handling (use update_date
							// when etag lookup fails).
							// Test to see if there is a Perfect Memory .pik file corresponding to this item
							imgd.InitFromIdWithMetadata(strImageId, imgpToLoad, fnOnInitFromIdProgress, fnOnInitFromIdComplete);
						}
					}
	
					// Test to see if there is a new style Perfect Memory .pik file corresponding to this item
					StorageServiceUtil.GetPerfectMemoryFid(imgpToLoad./*bridge*/serviceid, imgpToLoad./*ss_item*/id, imgpToLoad.etag, fnOnGetPerfectMemoryFid);

				} else if (galleryToLoad) {
					var gdoc:GalleryDocument = new GalleryDocument();

					var fnOnGalleryInitFromIdComplete:Function = function (nError:Number, strError:String=null, xml:XML=null): void {
							_bsy.Hide();
							_bsy = null;
							if (nError != GalleryDocument.errNone) {	
								PicnikBase.app.OnDownloadError(nError, strError, false /*fRetry*/, function (obResult:Object): void {});				
								fnDone();
								return;
							}
							PicnikBase.app.activeDocument = gdoc;								
							fnDone();
						};
										
					gdoc.InitFromPicnikFile(galleryToLoad, fnOnInitFromIdProgress, fnOnGalleryInitFromIdComplete);					
				} else {
					// turns out there was nothing for us to load.  Tell the app to move on
					_bsy.Hide();
					_bsy = null;
					fnDone();
				}
			}

			if (ss) {
				
				ss.ProcessServiceParams(_obSvcParameters, fnOnServiceParamsProcessed);
				
				// BEGIN flickrhack. Use this hack to make local flickr testing work corrrectly.
				// Uncomment these lines, and comment out the next two...
				// To use the hack, hit cancel after a few seconds of waiting for the image to load.

				var fnRetryOnCancel:Function = function(dctResult:Object): void {
						ss.ProcessServiceParams(_obSvcParameters, fnOnServiceParamsProcessed);
				}				
				_bsy = BusyDialogBase.Show(PicnikBase.app, Resource.getString('PicnikAsService', 'loading'), BusyDialogBase.SERVICE_LOAD,
					"ProgressWithCancel", 0, fnRetryOnCancel);
				// END flickrhack. Comment out the next two lines if you're using it.
				
				//_bsy = BusyDialogBase.Show(PicnikBase.app, Resource.getString('PicnikAsService', 'loading'), BusyDialogBase.SERVICE_LOAD,
				//	"ProgressWithCancel", 0, OnDownloadCancel);
				return true;
			}
			fnDone();
			return false;
		}
		
		// Act on any service request		
		public function ProcessServiceParametersPostUI(): void {			
			if (!_fActive)
				return;
				
			// handle co-branding and welcome dialogs
			if (_obSvcParameters._apikey) {
				ServiceManager.LoadCobrandImage(_obSvcParameters._apikey);
				ServiceManager.ShowWelcomeDialog(_obSvcParameters._apikey);
			}

/* NOTE: PicnikBase.ChangeTabs now checks for and handles the _exclude API parameter
			// exclude any tabs the partner doesn't like
			var astrExclude:Array;
			if (_obSvcParameters._exclude) {
				astrExclude = (_obSvcParameters._exclude as String).split(",");
			} else {
				astrExclude = new Array();
			}
			PicnikBase.app.RemoveTabs(astrExclude);
*/												
			// handle import URL, but only if this is a first-time load
			// (otherwise, the restorestate code will take care of us)
			var strImport:String = isFirstLoad ? _obSvcParameters._import : null;
			if (strImport) {
				// Close any open documents.
				PicnikBase.app.activeDocument = null;
								
				if (strImport != "none") {
					// report that we're loading
					ExternalService.GetInstance().ReportState("photo_loading");

					// get title, possibly change "C:\bla\bla\bla\image.jpg"
					// to just "image.jpg"
					var strTitle:String = _obSvcParameters._title;
					var patDirectoryPrefix:RegExp = /^.*[\/\\]/;
					if (strTitle != null) strTitle = strTitle.replace(patDirectoryPrefix, "");
					var imgp:ImageProperties = new ImageProperties("PAS", null, strTitle);
					
					var fAddToRecentUploads:Boolean = ServiceManager.GetAttribute(_obSvcParameters._apikey, "add_imports_to_recent_imports", false);

					// the import image may be on a remote server or may have been posted
					// to mywebsite.com. Remote images are prefixed with a scheme (e.g. "http://").
					// Posted images have no prefix.
					
					if (strImport.indexOf("://") != -1) {
						if (imgp.fCanLoadDirect) {
							// UNDONE:
							// BUGBUG: huh? imgp doesn't have sourceurl at this point
	//						strBaseImageName = imgp.sourceurl;
	//						strImport = imgp.sourceurl;
						}
					} else {
						strImport = PicnikService.GetTempURL(strImport);
					}
					imgp.sourceurl = strImport;
					
					// Start the import
					_bsy = BusyDialogBase.Show(PicnikBase.app, Resource.getString("PicnikAsService", "loading"), BusyDialogBase.IMPORT_LOAD,
							"ProgressWithCancel", 0, OnDownloadCancel);
					
					_canDownload = new Cancelable(this, OnDownloadDone);
					var dnldr:Downloader = new Downloader(ItemInfo.FromImageProperties(imgp), "/PicnikAsService/import", _canDownload.callback,
							OnDownloadProgress);
					if (fAddToRecentUploads) {
						dnldr.fileType = "i_mycomput";
						dnldr.temporary = AccountMgr.GetInstance().isGuest;
					}
						
					dnldr.Start();
					PicnikService.Log("PicnikAsService importing" + imgp.sourceurl);
				}
			} else {
				if (showLiteUI && !PicnikBase.app.flickrlite && !PicnikBase.app.multiMode) {
					// we must be given an import URL if we're showing the lite UI					
					PicnikBase.app.OnDownloadError(PicnikService.errBadParams, "Missing import URL", false /*fRetry*/, 
							function (obResult:Object): void {});								
				} else if( !_obSvcParameters._ss_cmd ) {
					// reset the activeDocument so that the zoomview will display the correct state
					PicnikBase.app.activeDocument = null;
				}
			}
		}
				
		private function OnDownloadCancel(dctResult:Object): void {
			if (_bsy) {
				_bsy.Hide();
				_bsy = null;
			}
			PicnikBase.app.OnDownloadCancel();
			if (_canDownload) _canDownload.Cancel();
		}
		
		private function OnDownloadProgress(strStatus:String, nFractionDone:Number): void {
			if (_bsy)
				_bsy.progress = nFractionDone * 100;
		}
		
		private function OnDownloadDone(err:Number, strError:String, dnldr:FileTransferBase): void {
			if (!_bsy) {
				// If we've been cancelled, then the _bsy dialog will have gone away. 
				// That's how we know to ignore this callback
				return;
			}

			_bsy.Hide();
			_bsy = null;
			
			if (err != ImageDocument.errNone) {
				PicnikBase.app.OnDownloadError(err, strError, false /*fRetry*/, function (obResult:Object): void {});				
				return;
			}
			
			PicnikBase.app.activeDocument = dnldr.imgd;
		}
		
		// User has clicked the Export button.
		// If the service initiator has specified _replace="ask" we present a dialog to
		// user asking if they want to overwrite the old image or save a new one.
		public function ExportClick(): void {
			_imgd = PicnikBase.app.activeDocument as ImageDocument;
			if (!_imgd)
				return;
				
			// HACK: we have a special case where we pull up the flickr export dialog
			if (_obSvcParameters._export == "FlickrExport") {
				PicnikBase.app.FlickrSave();		
			} else {
				if (_obSvcParameters._replace == "ask" && _obSvcParameters._imageid) {
					DialogManager.Show('ConfirmOverwriteDialog',PicnikBase.app, OnConfirmOverwrite,
						{ strURLOld: _obSvcParameters._original_thumb,
							imgd: _imgd,
							fShowSaveOver: true});
				} else if (_obSvcParameters._replace == "confirm" && _obSvcParameters._imageid) {
					DialogManager.Show('ConfirmOverwriteDialog',PicnikBase.app, OnConfirmOverwrite,
						{ strURLOld: _obSvcParameters._original_thumb,
							imgd: _imgd,
							fShowSaveOver: false});
				} else {
					DoExport(_obSvcParameters._replace == "yes");
				}
			}
		}

		private function OnConfirmOverwrite(obResult:Object): void {
			if (obResult.success) {
				DoExport(obResult.saveover);
			}
		}
		
		private function DoExport(fReplace:Boolean): void {
	    	var actl:IActionListener = PicnikBase.app._tabn.selectedChild as IActionListener;
	    	if (actl)
				actl.PerformActionIfSafe(new Action(_DoExport, fReplace));
			else
				_DoExport(fReplace);
		}
		
		private function _DoExport(fReplace:Boolean): void {
			var fBrowserExport:Boolean = _obSvcParameters._export_agent == "browser";
				
			var nWidth:int = _imgd.width;
			var nHeight:int = _imgd.height;
			var nAspect:Number = _imgd.width / _imgd.height;
			var nScale:Number = 1;
			
			var nOutWidth:Number = _obSvcParameters._out_maxwidth ? int(_obSvcParameters._out_maxwidth) : 0;
			var nOutHeight:Number = _obSvcParameters._out_maxheight ? int(_obSvcParameters._out_maxheight) : 0;
			var nOutSize:Number = _obSvcParameters._out_maxsize ? int(_obSvcParameters._out_maxsize) : 0;
			if (nOutWidth > 0 && nWidth * nScale > nOutWidth) {
				nScale = nOutWidth / nWidth;	
			}
			if (nOutHeight > 0 && nHeight * nScale > nOutHeight) {
				nScale = nOutHeight / nHeight;	
			}
			if (nOutSize > 0) {
				if (nWidth * nScale > nOutSize) {
					nScale = nOutSize / nWidth;	
				}
				if (nHeight * nScale > nOutSize) {
					nScale = nOutSize / nHeight;
				}				
			}
			
			// Pass all user parameters on with the export.
			if (fBrowserExport) {
				var obRenderParams:Object = { history: true };
				if (_obSvcParameters._out_quality)
					obRenderParams.quality = _obSvcParameters._out_quality * 10;
				if (_obSvcParameters._out_format)
					obRenderParams.format = _obSvcParameters._out_format;
					
				if (nScale < 1) {
					obRenderParams.width = Math.ceil(nWidth*nScale);
					obRenderParams.height = Math.ceil(nHeight*nScale);
				}
					
				_fReplace = fReplace;
				_bsy = BusyDialogBase.Show(PicnikBase.app, Resource.getString('PicnikAsService', 'rendering'), BusyDialogBase.SERVICE_EXPORT, "ProgressWithCancel", 0, OnRenderCancel);
				new RenderHelper(_imgd, OnRenderDone, _bsy).Render(obRenderParams);
				PicnikService.Log("PAS rendering");
			} else {
				var obPostParams:Object = {}
				if (_obSvcParameters._export_field)
					obPostParams._export_field = _obSvcParameters._export_field;
				if (fReplace)
					obPostParams._replace = "yes";
				if (_obSvcParameters._imageid)
					obPostParams._imageid = _obSvcParameters._imageid;
				if (_obSvcParameters._thumbs && _obSvcParameters._thumbs != "no")
					obPostParams._thumbs = _obSvcParameters._thumbs;
				if (_obSvcParameters._out_quality)
					obPostParams.quality = _obSvcParameters._out_quality * 10;
				if (_obSvcParameters._out_format)
					obPostParams.format = _obSvcParameters._out_format;
				
				// If we're posting via our server rather than the browser prefix "up_" so
				// the server can distinguish user parameters from its own.
				for (var strParam:String in _obUserParameters)
					obPostParams["up_" + strParam] = _obUserParameters[strParam];
				
				var strSending:String = _obSvcParameters._host_name ? LocUtil.rbSubst('PicnikAsService', 'exporting_to',  _obSvcParameters._host_name) : Resource.getString("PicnikAsService", "exporting");
				_bsy = BusyDialogBase.Show(PicnikBase.app, strSending, BusyDialogBase.SERVICE_EXPORT, "ProgressWithCancel", 0, OnPostCancel);

				var strExportURL:String = _obSvcParameters._export;
				new RenderHelper(_imgd, OnPostDone, _bsy).PostImage(strExportURL, Math.ceil(nWidth*nScale), Math.ceil(nHeight*nScale), obPostParams);
				
				PicnikService.Log("PAS posting to " + strExportURL);
			}
		}
		
		private function OnRenderCancel(obResult:Object): void {
			// UNDONE: _imgd.CancelSave()
			_bsy.Hide();
		}
		
		private function OnPostCancel(obResult:Object): void {
			// UNDONE: _imgd.CancelSave()
			_bsy.Hide();
		}
		
		private function OnPostProgress(nPercentComplete:Number, strStatus:String): void {
			_bsy.progress = nPercentComplete;
		}
		
		private function OnPostDone(err:Number, strError:String, nHttpStatus:Number=0, dResponseInfo:Object=null, strResponse:String=null): void {
			_bsy.Hide();
			if (err != ImageDocument.errNone) {
	 			if (err == StorageServiceError.ChildObjectFailedToLoad) {
	 				Bridge.DisplayCouldNotProcessChildrenError();
	 			} else {
					Util.ShowAlert(Resource.getString('PicnikAsService', 'save_failed') /*+ strError*/, Resource.getString("PicnikAsService", "error"), Alert.OK,
							"PicnikAsService.OnPostDone: err: " + err + ", strError: " + strError);
				}
			} else if (Math.floor( nHttpStatus / 100 ) == 4) {
				// 400 error failure -- the remote API partner server is borked
				Util.ShowAlert(Resource.getString('PicnikAsService', 'remote_failed') /*+ strError*/, Resource.getString("PicnikAsService", "error"), Alert.OK,
							"PicnikAsService.OnPostDone: err: " + err + ", strError: " + strError);				
			} else {
				PicnikBase.app.Notify(Resource.getString("PicnikAsService", "saved"));

				// After the history has been committed we can carry on to export URL.
				var fnOnCommitRenderHistory:Function = function (err:Number, strError:String): void {
					
					// 3. redirect to redirect link
					// UNDONE: pass parameters?
				
					var strRedirectURL:String = _obSvcParameters._redirect;
					if (!strRedirectURL) {
						if (dResponseInfo['strLocationUrl'])
							strRedirectURL = dResponseInfo['strLocationUrl'];
						else
							strRedirectURL = _obSvcParameters._export;
					}
					
					PicnikBase.app.activeDocument.isDirty = false;

					// register an API key hit with Google Analytics
					if (apikey && apikey.length > 0)
						Util.UrchinLogReport("/api/" + apikey + "/save" );
					
					if (strRedirectURL.toLowerCase().indexOf('http://') != 0 &&
						strRedirectURL.toLowerCase().indexOf('https://') != 0) {
						strRedirectURL = 'http://' + strRedirectURL.replace(":", "");
					}
					
					if (strRedirectURL != "none") {
						// close the currently open document				
						PicnikBase.app.activeDocument = null;

						// Clear out our service cookies before we leave
						ClearSvcCookies();
						PicnikBase.app.NavigateToURL(new URLRequest(strRedirectURL), "_self");
					}
				}
					
				// Life is good. Commit the rendered .pik (and all its companion files) to the History
				var iinf:ItemInfo = StorageServiceUtil.GetLastingItemInfo(ItemInfo.FromImageProperties(_imgd.properties));
				if (AccountMgr.GetInstance().isGuest)
					fnOnCommitRenderHistory(StorageServiceError.None, null);
				else				
					PicnikService.CommitRenderHistory(dResponseInfo.strPikId, iinf, ServiceManager.ApiKeyToService(apikey), fnOnCommitRenderHistory);			
			}
		}
		
		private function OnRenderDone(err:Number, strError:String, obResult:Object=null): void {
			if (err != PicnikService.errNone) {
	 			if (err == StorageServiceError.ChildObjectFailedToLoad) {
	 				Bridge.DisplayCouldNotProcessChildrenError();
	 			} else {
					Util.ShowAlert(Resource.getString('PicnikAsService', 'render_failed') /*+ strError*/, Resource.getString('PicnikAsService', 'error'), Alert.OK,
							"PicnikAsService.OnRenderDone: err: " + err + ", strError: " + strError);
	 			}
				return;
			}

			// After the history has been committed we can carry on to export URL.
			var fnOnCommitRenderHistory:Function = function (err:Number, strError:String): void {
				var strParam:String
				var obImageInfo:Object = {};

				var strImageURL:String = obResult.strUrl;
				
				var strExportField:String = "file";
				if (_obSvcParameters._export_field)
					strExportField = _obSvcParameters._export_field;
				obImageInfo[strExportField] = strImageURL;
				
				if (_obSvcParameters._imageid && _fReplace) // _fReplace is a global used to remember the value after this callback
					obImageInfo._imageid = _obSvcParameters._imageid;
	
				if (_obSvcParameters._thumbs && _obSvcParameters._thumbs != "no") {
					obImageInfo._thumb320 = obResult.thumb320url;
					obImageInfo._thumb100 = obResult.thumb100url;
					obImageInfo._thumb75 = obResult.thumb75url;
				}

				// Pass on all the user parameters
				for (strParam in _obUserParameters)
					obImageInfo[strParam] = _obUserParameters[strParam];
				for (strParam in _obSvcParameters) {
					if (strParam.indexOf("_user_") == 0) {
						obImageInfo[strParam.substr("_user_".length)] = _obSvcParameters[strParam];
					}	
				}
						
				var fnCommonCleanupTasks:Function = function():void {
						_bsy.Hide();

						// close the currently open document				
						PicnikBase.app.activeDocument = null;
							
						ExternalService.GetInstance().ReportState("app_close", null);

						// register an API key hit with Google Analytics
						if (apikey && apikey.length > 0)
							Util.UrchinLogReport("/api/" + apikey + "/save" );
							
						// Clear out our service cookies before we leave
						ClearSvcCookies();
						
					}

				var strExportUrl:String = _obSvcParameters._export;
				PicnikBase.app.ExitFullscreenMode(); // Make sure we exit full screen mode before closing Picnik.
				
				if (PicnikBase.app.thirdPartyEmbedded && strExportUrl.indexOf("javascript:") == 0) {
					ExternalService.GetInstance().ReportState( "photo_saved", obImageInfo, strExportUrl.substr("javascript:".length));
					fnCommonCleanupTasks();
					
				} else {
					var urlv:URLVariables = new URLVariables();
	
					// Pass on all the user parameters
					for (strParam in obImageInfo)
						urlv[strParam] = obImageInfo[strParam];
						
					// if the export URL has built-in query args,
					// make sure that it ends in either a '&' or a '?'
					strExportUrl = _obSvcParameters._export;
					if (strExportUrl.indexOf("?") != -1 &&
							strExportUrl.charAt( strExportUrl.length - 1 ) != "&" &&
							strExportUrl.charAt( strExportUrl.length - 1 ) != "?") {
						strExportUrl += "&";
					}
					
					var urlr:URLRequest = new URLRequest(strExportUrl);
					urlr.data = urlv;
					if (_obSvcParameters._export_method == "POST")
						urlr.method = URLRequestMethod.POST;

					fnCommonCleanupTasks();

					PicnikBase.app.NavigateToURL(urlr, "_self");
				}
			}
			
			// Life is good. Commit the rendered .pik (and all its companion files) to the History
			var iinf:ItemInfo = StorageServiceUtil.GetLastingItemInfo(ItemInfo.FromImageProperties(_imgd.properties));
			if (AccountMgr.GetInstance().isGuest)
				fnOnCommitRenderHistory(StorageServiceError.None, null);
			else				
				PicnikService.CommitRenderHistory(obResult.strPikId, iinf, ServiceManager.ApiKeyToService(apikey), fnOnCommitRenderHistory);
		}
		
		private function GetParamCookie(strCookie:String): String {
			if (strCookie in PicnikBase.app.parameters) {
				return PicnikBase.app.parameters[strCookie];
			} else {
				return Session.GetCurrent().GetSOCookie(strCookie, null);
			}
		}
		
		private function GetCookiedParameters(strCookie:String): Object {
			var obRet:Object = null;
			try {
				var strParameters:String = GetParamCookie(strCookie);

				// UNDONE: what about robustness in the face of refresh?
				if (strParameters) strParameters = Util.RemoveQuotes(strParameters);
				if (strParameters == null || strParameters.length == 0)
					obRet = null;
				else
					obRet = Util.ObFromQueryString(strParameters, true);
			} catch (e:Error) {
				trace("Error in PicnikAsService:GetCookiedParameters: " + e + ": " + e.getStackTrace());
				obRet = null;
			}
			return obRet;
		}
		
		public function HasImport(): Boolean {
			return GetImportUrl() != null;
		}
		
		public function GetImportUrl(): String {
			var strImportUrl:String = Session.GetCurrent().GetSOCookie("import", null);
			if (strImportUrl == null) return null;
			return Util.RemoveQuotes(strImportUrl);
		}
		
	}
}
