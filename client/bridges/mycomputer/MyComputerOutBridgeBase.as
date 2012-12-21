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
package bridges.mycomputer {
	import bridges.FileTransferBase;
	import bridges.OutBridge;
	import bridges.Uploader;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceUtil;
	
	import controls.HSliderPlus;
	import controls.ResizingLabel;
	
	import dialogs.BusyDialogBase;
	import dialogs.EasyDialogBase;
	import dialogs.IBusyDialog;
	
	import events.ActiveDocumentEvent;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.StageQuality;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import imageUtils.PNGEnc;
	
	import imagine.ImageDocument;
	import imagine.documentObjects.DocumentObjectContainer;
	import imagine.documentObjects.DocumentStatus;
	import imagine.documentObjects.Target;
	
	import mx.containers.Box;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	import mx.controls.ProgressBar;
	import mx.controls.TextInput;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.SliderEvent;
	import mx.events.SliderEventClickTarget;
	import mx.resources.ResourceBundle;
	import mx.utils.Base64Encoder;
	
	import util.AlchemyJPEGEncoder;
	import util.DrawUtil;
	import util.RenderHelper;
	import util.VBitmapData;
	
	import validators.PicnikNumberValidator;
	
	public class MyComputerOutBridgeBase extends OutBridge implements IDownloadParent {
		import flash.display.BitmapData;
		
		[Bindable] public var _cboxFormat:ComboBox;
		[Bindable] public var _btnDownload:Button;
		[Bindable] public var _btnRetryUpload:Button;
		[Bindable] public var _tiWidth:TextInput;
		[Bindable] public var _tiHeight:TextInput;
		[Bindable] public var _tiPercent:TextInput;
		[Bindable] public var _tiFileNameBase:TextInput;
		[Bindable] public var _sldrQuality:HSliderPlus;
		[Bindable] public var _vldWidth:PicnikNumberValidator;
		[Bindable] public var _vldHeight:PicnikNumberValidator;
		[Bindable] public var _vldPercent:PicnikNumberValidator;
		[Bindable] public var _lbQualityDescription:ResizingLabel;
		[Bindable] public var _pbarEncoding:ProgressBar;
		[Bindable] public var _bxEncoding:Box;
		[Bindable] public var _maxScale:int = 100;
		[Bindable] public var _maxWidth:int = 1;
		[Bindable] public var _maxHeight:int = 1;

   		[ResourceBundle("MyComputerOutBridge")] private var _rb:ResourceBundle;
   		
   		[Bindable] public static var _fForceEncodingFail:Boolean = false;

		private static const knCollageTemplatePreviewSize:Number = 135;
		private var _cxNew:Number, _cyNew:Number, _nNewPercent:Number;
		public var _strFileSavedNotifyMessage:String;
		private var _urlr:URLRequest;
		private var _fWidthValid:Boolean = true;
		private var _fHeightValid:Boolean = true;
		private var _fPercentValid:Boolean = true;
		[Bindable] public var fSizeValid:Boolean = true;
		private var _astrMsgs:Array;
		private var _upldr:Uploader;
		private var _bsy:IBusyDialog;
		private var _fReadyToSave:Boolean = false;
		[Bindable] protected var _jenc:AlchemyJPEGEncoder;
		private var _dctRenderOptions:Object;
		private var _fLocalSave:Boolean; // Save-in-progress is a local save
		
		private var _fWaitingToStartDownload:Boolean = false;
		
		private var _fdldr:FileDownloader; // Hang on to this so it is not garbage collected
		
		// This map derives Photoshop "Save for Web"-equivalent compression settings to be passed to libjpeg.
// Original:
//		private static var s_anQualityMap:Array =     [  0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
//		private static var s_anSubsamplingMap:Array = [  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  0 ];
// Tweaked to disable chroma subsampling for quality 7-10 and to top out at 98 instead of 100:
//		private static var s_anQualityMap:Array =     [  0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 98 ];
//		private static var s_anSubsamplingMap:Array = [  2,  2,  2,  2,  2,  2,  2,  0,  0,  0,  0 ];
// According to:
// http://blogs.gnome.org/raphael/2007/10/23/mapping-jpeg-compression-levels-between-adobe-photoshop-and-gimp-24/
//		private static var s_anQualityMap:Array =     [  0, 60, 70, 74, 79, 86, 85, 90, 93, 96, 98 ];
//		private static var s_anSubsamplingMap:Array = [  2,  2,  2,  2,  2,  2,  2,  0,  0,  0,  0 ];
// New and improved -- a close match for Photoshop but increases average file size significantly:
		private static var s_anQualityMap:Array =     [  0, 26, 39, 54, 67, 78, 86, 88, 92, 96, 98 ];
		private static var s_anSubsamplingMap:Array = [  2,  2,  2,  2,  2,  2,  2,  2,  2,  0,  0 ];
		
		public function MyComputerOutBridgeBase() {
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
			_astrMsgs = [
				Resource.getString("MyComputerOutBridge", "Quality1"),
				Resource.getString("MyComputerOutBridge", "Quality2"),
				Resource.getString("MyComputerOutBridge", "Quality3"),
				Resource.getString("MyComputerOutBridge", "Quality4"),
				Resource.getString("MyComputerOutBridge", "Quality5"),
				Resource.getString("MyComputerOutBridge", "Quality6"),
				Resource.getString("MyComputerOutBridge", "Quality7"),
				Resource.getString("MyComputerOutBridge", "Quality8"),
				Resource.getString("MyComputerOutBridge", "Quality9"),
				Resource.getString("MyComputerOutBridge", "Quality10") ];
		}
		
		protected function IsCollageTemplate(imgd:ImageDocument): Boolean {
			if (!imgd) return false; // No doc
			if (!AccountMgr.GetInstance().isCollageAuthor) return false; // Only collage authors can publish collage templates
			// This is an admin with a doc. Look for a target
			// Eventually, we may need to look in child objects too
			for (var i:Number = 0; i < imgd.numChildren; i++) {
				if (imgd.getChildAt(i) is Target)
					return true;
			}
			return false;
		}

		public function UpdateOKBtn(strName:String, fValid:Boolean):void {
			if (strName == 'width')
				_fWidthValid = fValid;
			else if (strName == 'percent')
				_fPercentValid = fValid;
			else
				_fHeightValid = fValid;				
			
			fSizeValid = (_fWidthValid && _fHeightValid && _fPercentValid);
		}

		private function OnCreationComplete(evt:FlexEvent):void {
			_btnDownload.addEventListener(MouseEvent.CLICK, OnDownloadClick);
			_btnRetryUpload.addEventListener(MouseEvent.CLICK, OnRetryUploadClick);
			_cboxFormat.addEventListener(Event.CHANGE, OnFormatChange);
			_tiWidth.addEventListener(Event.CHANGE, OnTextInputChange);
			_tiHeight.addEventListener(Event.CHANGE, OnTextInputChange);
			_tiPercent.addEventListener(Event.CHANGE, OnTextInputChange);
			/* These event listeners are declared in MXML so they are added
			   only when the bridge is in the state that shows the slider.
			_sldrQuality.addEventListener(SliderEvent.CHANGE, OnQualitySliderChange);
			_sldrQuality.addEventListener(SliderEvent.THUMB_RELEASE, OnQualitySliderThumbRelease);
			*/
		}

		protected function OnQualitySliderChange(evt:SliderEvent): void {
			var nQuality:Number = Math.round(_sldrQuality.value * 10) / 10;
			_lbQualityDescription.text = _astrMsgs[nQuality - 1];
			ShowEncodingProgress();
			if (_jenc && _jenc.status == AlchemyJPEGEncoder.ENCODING)
				_jenc.Abort();
			if (evt.clickTarget == SliderEventClickTarget.TRACK)
				Reencode();
		}
		
		private function ShowEncodingProgress(): void {
			fileSizeString = "";
			if (_pbarEncoding)
				_pbarEncoding.setProgress(0, 100);
		}
		
		protected function OnQualitySliderThumbRelease(evt:SliderEvent): void {
			Reencode();
		}
		
		private function OnTextInputChange(evt:Event):void {
			var fUpdateHW:Boolean = false;
			var n:Number = Number(evt.target.text);
			
			if (evt.target == _tiPercent) {
				_vldPercent.validate(null, true);
				_nNewPercent = n;
				n = Math.round((n / 100) * _imgd.width);
				fUpdateHW = true;
			}
			
			if (evt.target == _tiWidth || fUpdateHW) {
				_vldWidth.validate(null, true);
				_cxNew = n;
				_cyNew = _cxNew * (_imgd.height / _imgd.width);
			} else {
				_vldHeight.validate(null, true);
				_cyNew = n;
				_cxNew = _cyNew * (_imgd.width / _imgd.height);
			}
			
			if (fUpdateHW == false)
				_nNewPercent = Math.round((_cxNew / _imgd.width) * 100);
			
			UpdateImageDimControls();

			ShowEncodingProgress();

			if (fSizeValid) {
				// Wait a little while before encoding because the encoding is
				// synchronous and will interrupt further typing.
				if (_tmrStartEncode != null) {
					_tmrStartEncode.stop();
					_tmrStartEncode.removeEventListener(TimerEvent.TIMER_COMPLETE, OnStartEncodeTimerComplete);
				}
				_tmrStartEncode = new Timer(500, 1);
				_tmrStartEncode.addEventListener(TimerEvent.TIMER_COMPLETE, OnStartEncodeTimerComplete);
				_tmrStartEncode.start();
			}
		}
		
		private function OnStartEncodeTimerComplete(evt:TimerEvent): void {
			_tmrStartEncode.removeEventListener(TimerEvent.TIMER_COMPLETE, OnStartEncodeTimerComplete);
			_tmrStartEncode = null;
			Reencode();
		}
		
		private function UpdateImageDimControls(): void {
			_tiWidth.text = String(Math.max(1, Math.round(_cxNew)));
			_tiHeight.text = String(Math.max(1, Math.round(_cyNew)));
			if (_nNewPercent)
				_tiPercent.text = String(Math.round(_nNewPercent));
			
			_vldWidth.validate();
			_vldHeight.validate();
			_vldPercent.validate();
			
			// HACK: Flex's focusRect updating is buggy (at least through 3.1) so we force it to do the right thing
			Util.UpdateFocusRect(_tiWidth);
			Util.UpdateFocusRect(_tiHeight);
			Util.UpdateFocusRect(_tiPercent);
		}
		
		override public function OnActivate(strCmd:String=null):void {
			if (!Util.DoesUserHaveLocalSaveFlashPlayerAndBrowser()) {
				_jenc = null;
			} else if (_jenc == null) {
				_jenc = AlchemyJPEGEncoder.GetInstance();
				_jenc.addEventListener(ProgressEvent.PROGRESS, OnJpegEncoderProgress);
				_jenc.addEventListener(Event.COMPLETE, OnJpegEncoderComplete);
			}
			
			super.OnActivate(strCmd);
			if (_tiFileNameBase.text.length == 0) _tiFileNameBase.text = "image";
		}
		
		private function ResetFormat(): void {
			if (_cboxFormat && _imgd && _imgd.numChildrenLoading > 0)
				_cboxFormat.selectedIndex = 0;
		}
		
		override public function OnDeactivate(): void {
			super.OnDeactivate();
			AbortEncodeImage();
		}

		override protected function OnActiveDocumentChange(evt:ActiveDocumentEvent): void {
			super.OnActiveDocumentChange(evt); // sets _imgd appropriately
			if (_imgd != null) {
				_tiWidth.text = String(_imgd.width);
				_tiHeight.text = String(_imgd.height);
				_tiPercent.text = "100";	// reset to 100
				_tiFileNameBase.text = _imgd.properties.title;
				if (_tiFileNameBase.text.length == 0)
					_tiFileNameBase.text = "image";
				var ptLimited:Point = Util.GetLimitedImageSize(_imgd.width * 8000, _imgd.height * 8000);
				_maxWidth = ptLimited.x;
				_maxHeight = ptLimited.y;
				_maxScale = 100 * _maxWidth / _imgd.width;
				
				ResetFormat();
			
				Reencode();
			}
		}
		
		private function OnFormatChange(evt:Event): void {
			currentState = _cboxFormat.selectedItem.data;
			Reencode();
		}
		
		private function Reencode(): void {
			AbortEncodeImage();
			
			if (localSaveMakesSense) {
				if (!_fEncodePending) {
					_fEncodePending = true;
					ShowEncodingProgress();
					encoding = true;
					callLater(EncodeImage)
				}
			}
		}
		
		private function get localSaveMakesSense(): Boolean {
			if (_imgd == null)
				return false;

			// Collage templates must be rendered by the server and saved with special data
			// (e.g. preview image, # targets) attached.
			if (IsCollageTemplate(_imgd))
				return false;
				
			// If AlchemyLib failed to load local saving isn't an option
			if (_jenc == null || _jenc.status == AlchemyJPEGEncoder.LOAD_FAILED)
				return false;
				
			// if this is a format we know how to encode locally
			if (_cboxFormat.selectedItem.data != "jpg") // && _cboxFormat.selectedItem.data != "png")
				return false;
				
			return true;
		}
		
		[Bindable]
		public function get encoding(): Boolean {
			return _fEncoding;
		}
		
		public function set encoding(f:Boolean): void {
			_fEncoding = f;
			if (f)
				ShowEncodingProgress();
		}
		
		protected function set documentReadyToSave(fReady:Boolean): void {
			_fReadyToSave = fReady;
			
			if (fReady)
				Reencode();
		}
		
		protected function get documentReadyToSave(): Boolean {
			return _fReadyToSave;
		}
		
		[Bindable] protected var fileSizeString:String;
		
		private var _tmrStartEncode:Timer;
		private var _msEncodeStart:int;
		private var _fEncoding:Boolean = false;
		private var _fEncodePending:Boolean = false;

		// NOTE: because of its use of the Alchemy JPEG encoder, this function requires Flash 10
		private function EncodeImage(): void {
			_fEncodePending = false;
			
			if (!fSizeValid) {
				// If we're already encoding an image, abandon it
				AbortEncodeImage();
				return;
			}
			
			try {	
				// Disable the Save button (automatic via binding to 'encoding')
				encoding = true;
				
				_msEncodeStart = getTimer();
	
				// Snapshot the image, the size we want it to be
				var cx:int = Number(_tiWidth.text);
				if (cx == 0)
					cx = _imgd.width;
				var cy:int = Number(_tiHeight.text);
				if (cy == 0)
					cy = _imgd.height;
					
				var baEncoding:ByteArray;
				if (cx != _imgd.width || cy != _imgd.height) {
					// Before compressing resize the image to the requested size. Also change any transparent areas to white.
					var bmdEncoding:BitmapData = DrawUtil.GetResizedBitmapData(_imgd.composite, cx, cy, false, 0xffffffff);
					baEncoding = bmdEncoding.getPixels(bmdEncoding.rect);
					bmdEncoding.dispose();
				} else {
					// Before compressing change any transparent areas to white.
					var bmdT:BitmapData = new VBitmapData(_imgd.composite.width, _imgd.composite.height, false, 0xffffffff, "JPEG encoding tmp");
					bmdT.draw(_imgd.composite);
					baEncoding = bmdT.getPixels(bmdT.rect);
					bmdT.dispose();
				}
	
				// Transfer metadata from the base image, if there is one, to the output image			
				var aobSegments:Array = (_imgd.baseImageAssetIndex != -1 && _imgd.properties.metadata) ?
						_imgd.properties.metadata.segments : null;
				var iQuality:int = Math.round(_sldrQuality.value);
	
				// This is an async operation which fires PROGRESS and COMPLETE events
				_dctRenderOptions = { width: cx, height: cy, format: "jpg", quality: s_anQualityMap[iQuality] }
				_jenc.Encode(baEncoding, cx, cy, s_anQualityMap[iQuality], aobSegments, s_anSubsamplingMap[iQuality]);
			} catch (err:Error) {
				// If we have a problem setting up for a local save, fall back to the remote save
				encoding = false;
			}
		}
		
		private function OnJpegEncoderProgress(evt:ProgressEvent): void {
			if (_pbarEncoding)
				_pbarEncoding.setProgress(evt.bytesLoaded, evt.bytesTotal);
		}
		
		private function OnJpegEncoderComplete(evt:Event=null): void {
			if (_fForceEncodingFail)
				_jenc.data = null;
				
			if (_jenc.data)
				fileSizeString = Util.FormatBytes(_jenc.data.length);

			if (_jenc.status != AlchemyJPEGEncoder.ABORTING && _jenc.status != AlchemyJPEGEncoder.ENCODING)
				encoding = false;
		}
		
		private function AbortEncodeImage(): void {
			if (_jenc)
				_jenc.Abort();
			encoding = false;
		}
		
		////// BEGIN: IDownloadParent implementation
		public function get component(): UIComponent {
			return this;
		}
		
		public function DownloadStarted(fnOnDownloadCancel:Function): void {
			HideBusyDialog();
			
			var strStatus:String = Resource.getString("MyComputerOutBridge",
					_fLocalSave ? "saving" : "Rendering");
			var strState:String = _fLocalSave ? "" : "ProgressWithCancel";
			_bsy = BusyDialogBase.Show(this, strStatus,
					BusyDialogBase.SAVE_USER_IMAGE, strState, 0.5, fnOnDownloadCancel);
		}
		
		public function DownloadProgress(evt:ProgressEvent): void {
			if (_bsy == null)
				return;
				
			if (!_fLocalSave)
				_bsy.message = Resource.getString("MyComputerOutBridge", "Downloading");
			_bsy.progress = (evt.bytesLoaded / evt.bytesTotal) * 100;
		}
		
		public function DownloadFinished(fSuccess:Boolean, strFileName:String=null): void {
			// If this is a local save and the user is registered then we need to create
			// a History entry for it.
			if (fSuccess && _fLocalSave && !AccountMgr.GetInstance().isGuest && !(_imgd.numChildrenLoading > 0 || _imgd.childStatus == DocumentStatus.Error)) {
				var fnOnHistoryEntryCreated:Function = function (err:Number, strError:String=null): void {
					// Treat the save as successful even if the history entry couldn't be created
					_DownloadFinished(true, strFileName);
				}
				
				CreateHistoryEntry(_imgd, _dctRenderOptions, fnOnHistoryEntryCreated);
			} else {
				_DownloadFinished(fSuccess, strFileName);
			}
		}
		
		private function _DownloadFinished(fSuccess:Boolean, strFileName:String=null): void {
			HideBusyDialog();
			if (fSuccess) {
				_imgd.properties.filename = strFileName;
				var imgpSaveProps:ImageProperties = new ImageProperties;
				_imgd.properties.CopyTo(imgpSaveProps);
				imgpSaveProps./*bridge*/serviceid = "mycomputer";
				_imgd.lastSaveInfo = imgpSaveProps;
				
				var strEvent:String = "/standard";
				try {
					strEvent += "/" + _cboxFormat.selectedItem['data'];					
				} catch (e:Error) {
					trace("Ignoring error: ", e);
				}
				ReportSuccess(strEvent, _fLocalSave ? "localsave" : "download");
				_imgd.isDirty = false;
				PicnikBase.app.Notify(_strFileSavedNotifyMessage);
				PicnikBase.app.OnSaveComplete();
				PicnikBase.app.NavigateToService(PicnikBase.OUT_BRIDGES_TAB, "postsave");
			}
		}
		
		public function SetFileNameBase(strName:String): void {
			_tiFileNameBase.text = strName;
		}
		////// END: IDownloadParent implementation
		
		private function OnRetryUploadClick(evt:MouseEvent): void {
			// Show busy dialog
			_bsy = BusyDialogBase.Show(this, Resource.getString("MyComputerInBridge", "Uploading"),
					BusyDialogBase.LOAD_USER_IMAGE, "ProgressWithCancel", 0, OnRetryUploadCancel);
			
			// Create a new Uploader, clone of the one in the document
			_upldr = new Uploader(_imgd.failedUpload, "outBridgeRetry", OnRetryUploadComplete, OnRetryUploadProgress, null, true);
			
			// Start the upload
			_upldr.StartWithRetry();
		}
		
		// Handle upload retry cancel
		private function OnRetryUploadCancel(dctResult:Object): void {
			_upldr.UserCancel();
			_upldr = null;
			HideBusyDialog();
		}
		
		// Handle upload retry progress
		private function OnRetryUploadProgress(strAction:String, nPctDone:Number): void {
			if (_bsy != null) {
				if (strAction != null) _bsy.message = strAction;
				_bsy.progress = nPctDone * 100;
			}
		}

		// Handle upload retry success, failure
		private function OnRetryUploadComplete(err:Number, strError:String, upldr:FileTransferBase): void {
//			trace("OnRetryUploadComplete: " + err + ", " + strError);
			HideBusyDialog();
			
			_imgd.uploaderInProgress = null;
			if (err == ImageDocument.errNone) {
				_imgd.failedUpload = null;
				_imgd.baseImageFileId = _upldr.fid;
				_upldr = null;
			} else {
				_upldr.Cancel();
				_upldr = null;
				Util.ShowAlert(Resource.getString("MyComputerInBridge", "transfer_failed_upload"),
						Resource.getString("MyComputerInBridge", "Error"), Alert.OK,
						"ERROR:out.bridge.mycomputer.onComplete: " + err + ", " + strError);
			}
		}
		
		private function HideBusyDialog(): void {
			_fWaitingToStartDownload = false;
			if (_bsy)
				_bsy.Hide();
			_bsy = null;
		}
		
		private function OnDownloadClick(evt:MouseEvent=null): void {
			// If shift key is held force the save to happen via render/download
			// even if the user is local save capable.
			DoDownload(evt.shiftKey ? true : false);
		}
		
		private function AddTargets(aTargets:Array, dobc:DocumentObjectContainer): void {
			for (var i:Number = 0; i < dobc.numChildren; i++) {
				var dobChild:DisplayObject = dobc.getChildAt(i);
				if (dobChild is Target) {
					aTargets.push(dobChild);
				} else if (dobChild is DocumentObjectContainer) {
					AddTargets(aTargets, dobChild as DocumentObjectContainer);
				}
			}
		}
		
		private function AddCollageTemplateOptions(oRenderOptions:Object): void {
			// Optimize the document first. This clears out the undo/redo history if possible
			// and optimizes the referenced asset map.
			_imgd.Optimize();
			
			// Create preview PNG
			
			// First, turn off target display
			var aTargets:Array = [];
			AddTargets(aTargets, _imgd.documentObjects);
			
			var aPrevVals:Array = [];
			var tgt:Target;
			for each (tgt in aTargets) {
				aPrevVals.push(tgt.drawPlaceholder);
				tgt.drawPlaceholder = false;
				tgt.Validate();
			}
			_imgd.documentObjects.Validate();

			var nScale:Number = Math.min(1, knCollageTemplatePreviewSize/ _imgd.width, knCollageTemplatePreviewSize/ _imgd.height);
			var bmd:BitmapData = new VBitmapData(_imgd.width * nScale, _imgd.height * nScale, true, 0, "template preview");
			var mat:Matrix = new Matrix();
			mat.scale(nScale, nScale);

			// Crank StageQuality to max for the best possible Resize filtering
			// Use the systemManager.stage instead of application.stage because in some fast loading
			// cases (e.g. no base image) we can reach this point before the application.stage has
			// been initialized.
			var strQuality:String = Application.application.systemManager.stage.quality;
			
			// NOTE: this causes callLaters and Event.RENDER to be dispatched immediately
			Application.application.systemManager.stage.quality = StageQuality.BEST;
			
			bmd.draw(_imgd.documentObjects, mat, null, null, null, true);
			
			// Restore StageQuality so everything doesn't bog down
			Application.application.systemManager.stage.quality = strQuality;
			
			var abImageData:ByteArray = imageUtils.PNGEnc.encode(bmd, 1);
// DWM: this is a quick & dirty way of displaying a BitmapData on-screen at the upper-left corner
//			Application.application.stage.addChild(new Bitmap(bmd.clone()));
			bmd.dispose();
			
			var b64enc:Base64Encoder = new Base64Encoder();
			b64enc.encodeBytes(abImageData);
			
			oRenderOptions.strCollageTemplatePreview = b64enc.drain();
			oRenderOptions.nCollageTargets = aTargets.length;
			
			// Reset target display values
			for (var i:Number = 0; i < aTargets.length; i++) {
				Target(aTargets[i]).drawPlaceholder = aPrevVals[i];
			}
		}
		
		private function DoDownload(fForceDownload:Boolean=false): void {
			if (_fWaitingToStartDownload) return;

			var strDebugLoc:String = "A";
			try {
				if (_imgd == null) throw new Error("Trying to download null imagedocument");
				if (fForceDownload && _jenc)
					_jenc.data = null;
				_fLocalSave = _jenc != null && _jenc.data != null;
					
				strDebugLoc += ",B";
				// build up options array
				var oRenderOptions:Object = { history: !AccountMgr.GetInstance().isGuest };
				strDebugLoc += ",C";
				oRenderOptions.width = _tiWidth.text;
				oRenderOptions.height = _tiHeight.text;
				strDebugLoc += ",D[" + _tiWidth.text + ", " + _tiHeight.text + "]";
				oRenderOptions.format = _cboxFormat.selectedItem['data'];
				strDebugLoc += ",E[" + oRenderOptions.format + "]";
				if (oRenderOptions.format == 'jpg')
					oRenderOptions.quality = Math.round(_sldrQuality.value * 10);
	
				var strExtension:String = oRenderOptions.format;

				try {
					if (IsCollageTemplate(_imgd))
						AddCollageTemplateOptions(oRenderOptions);
				} catch (e:Error) {
					trace(e);
					Alert.show("Error preparing collage template for render: " + e, "Error");
					// Mostly ignore the error.
				}
				strDebugLoc += ",E.1"
				if (!_fLocalSave) {
					strDebugLoc += ",E.2"
					_urlr = new RenderHelper(_imgd, null).GetRenderThrough(oRenderOptions, "mycomputer");
					if (_urlr == null) {
						var strStatus:String = "";
						if (_imgd == null) strStatus = "imgd is null";
						else strStatus = "imgd.childStatus = " + _imgd.childStatus + ", imgd.numChildrenLoading = " + _imgd.numChildrenLoading;
						throw new Error("GetRenderThrough() failed: " + strStatus);
					}
					strDebugLoc += ",G[" + (_urlr ? _urlr.url : "<null>") + "]";
				}
				strDebugLoc += ",G.2";

				_fdldr = new FileDownloader(this);
				strDebugLoc += ",H";
				_fdldr.addEventListener("do_basic_download", function(evt:Event): void { OnBasicDownload() });
				_fdldr.addEventListener("do_renamed_download", function(evt:Event): void { OnRenamedDownload() });
				_fdldr.addEventListener("do_render_download", function(evt:Event): void { DoDownload(true) });
				_fdldr.addEventListener("try_again_download", function(evt:Event): void { DoDownload() });

				// BST 4/2/09: Fixed Error #2041 (duplicate download dialogs) thrown when we try to show the download dialog twice
				// One possible repro: give the Save Photo button focus, click on it and hit the space bar at the same time.
				// There are probably other repros too, but this is the easiest one to find.
				_fWaitingToStartDownload = true;
				strDebugLoc += ",H2";
				_fdldr.Download(_urlr, _fLocalSave ? _jenc.data : null, strExtension, GetDownloadImageName(strExtension));
				strDebugLoc += ",I";
			} catch (e:Error) {
				_fWaitingToStartDownload = false;
				trace("Error saving: " + e + ", " + e.getStackTrace() + "\nDebugLoc = " + strDebugLoc);
				if (e.errorID == 2087) {
					Util.ShowAlert(
						Resource.getString("MyComputerOutBridge", "bad_filename"),
						Resource.getString("MyComputerOutBridge", "Error"),
							Alert.OK, "ERROR:out.bridge.mycomputer.DoDownload.badfilename ");
				} else {
					Util.ShowAlert(
						Resource.getString("MyComputerOutBridge", "failed_to_render"),
						Resource.getString("MyComputerOutBridge", "Error"),
							Alert.OK, "ERROR:out.bridge.mycomputer.DoDownload.unknownerror ");
					PicnikService.LogException("ERROR:out.bridge.mycomputer.OnDownloadClick", e, null, strDebugLoc);
				}
			}
		}
		
		protected function OnRenamedDownload(): void {
			_tiFileNameBase.text = alternateFilename(_tiFileNameBase.text);
			DoDownload();
		}
		
		// given a (suffix-less) filename, provide an alternate name for it. 
		// if given 'foo', will return 'foo_picnik'
		// if given 'foo_picnik', will return 'foo_picnik1'
		// if given 'foo_picnik1', will return 'foo_picnik2'
		// if given 'foo_picnik2', will return 'foo_picnik3', etc.
		public static function alternateFilename(filename:String) : String {
			if (filename.match(/_picnik$/) != null)
				return filename.replace(/_picnik$/, '_picnik1');
			var m1:Array = filename.match(/_picnik(?P<id>\d+)$/);
			if (m1 != null) {
				var i:int = int(m1[1]) + 1;
				return filename.replace(/_picnik\d+$/, '_picnik' + i.toString());
			}
			return filename + "_picnik";
		}

		protected function OnBasicDownload(): void {
			_fDoCancel = false;
			DownloadStarted(OnBasicDownloadCancel);
			// build up options array
			var oRenderOptions:Object = { history: !AccountMgr.GetInstance().isGuest };
			oRenderOptions.width = _tiWidth.text;
			oRenderOptions.height = _tiHeight.text;
			oRenderOptions.format = _cboxFormat.selectedItem['data'];
			if (oRenderOptions.format == 'jpg') {
				oRenderOptions.quality = Math.round(_sldrQuality.value * 10);
			}
			_FileExtension = oRenderOptions.format;
			
			new RenderHelper(_imgd, OnImageDocumentRenderDone, _bsy).Render(oRenderOptions);
			
			PicnikService.Log("MyComputerOutBridge downloading " + _imgd.properties.title + ", width: " +
					oRenderOptions.width + ", height: " + oRenderOptions.height + ", format: " +
					oRenderOptions.format + (oRenderOptions.format == "jpg" ? (", quality: " + oRenderOptions.quality) : ""));
		}

		private function OnBasicDownloadCancel(dctResult:Object): void {
			DownloadFinished(false);
			_fDoCancel = true;
		}
		
		private var _fDoCancel:Boolean;
		private var _FileExtension:String;

		// UNDONE: retrieve history base name
		private function OnImageDocumentRenderDone(err:Number, strError:String, obResult:Object=null): void {
			HideBusyDialog();
 			if (_fDoCancel) {
 				// operation cancelled, do nothing.
 			} else if (err != PicnikService.errNone) {
				if (err == StorageServiceError.ChildObjectFailedToLoad) {
					DisplayCouldNotProcessChildrenError();					
				} else {
					Util.ShowAlert(
						Resource.getString("MyComputerOutBridge", "failed_to_render"),
						Resource.getString("MyComputerOutBridge", "Error"),
							Alert.OK, "ERROR:out.bridge.mycomputer.render: " + err + ", " + strError);
				}
			} else {
				var itemInfo:ItemInfo = StorageServiceUtil.GetLastingItemInfo(ItemInfo.FromImageProperties(_imgd.properties));
				if (!AccountMgr.GetInstance().isGuest)
					PicnikService.CommitRenderHistory(obResult.strPikId, itemInfo, 'mycomputer');
				
				const max_axis:Number = 300;
				var w:Number = Number(_tiWidth.text);
				var h:Number = Number(_tiHeight.text);
				var r:Number = Math.min(max_axis / w, max_axis / h);
				if (r < 1.0) {
					w *= r;
					h *= r;
				}

				ReportSuccess("/basic", "download");
				
				var url_vars:String =	"?url=" + escape(obResult.strUrl) +
										"&name=" + escape(_tiFileNameBase.text + "." + _FileExtension) +
										"&w=" + int(w).toString() +
										"&h=" + int(h).toString();
				var req:URLRequest;
				if (PicnikBase.app.canNavParentFrame) {
					PicnikBase.app.NavigateToURLWithIframeHelp("/go/download" + url_vars, "_self");
				} else {
					EasyDialogBase.Show(PicnikBase.app,
						[Resource.getString("Picnik", "ok")],
						Resource.getString("MyComputerOutBridge", "photoready"),
						Resource.getString("MyComputerOutBridge", "clicktodownload"),
						function( obResult:Object ): void {
								PicnikBase.app.NavigateToURLWithIframeHelp("/go/download" + url_vars + "&popped=1", "_blank");
							} );
				}
			}
		}			

		private function GetDownloadImageName(strExtension:String): String {
			// file download does not allow the following chars:
			// /, \, :, *, ?, ", <, >, |, %
			var strDownloadImageName:String = "";
			try {
				var strNotAllowed:String = "/\\:*?\"<>|%";
				for (var i:Number = 0; i < _tiFileNameBase.text.length; i++) {
					var ch:String = _tiFileNameBase.text.charAt(i);
					if (strNotAllowed.indexOf(ch) == -1) strDownloadImageName += ch;
				}
	
				if ( ("."+strExtension) != strDownloadImageName.substr( -1 * (strExtension.length+1) ) ) {
					strDownloadImageName += "." + strExtension;
				}
			} catch (e:Error) {
				var strFileNameBase:String = (_tiFileNameBase == null) ? "<null>" : _tiFileNameBase.text;
				throw new Error("Exception in GetDownloadImageName: " + e + ": " + strExtension + ", " + strDownloadImageName + ", " + strFileNameBase);
			}
	
			return strDownloadImageName;
		}
		
		// NOTE: because of its use of the Alchemy JPEG encoder, this function requires Flash 10
		private function CreateHistoryEntry(imgd:ImageDocument, dctRenderOptions:Object,
				fnOnHistoryEntryCreated:Function): void {
			// Size image down to a 320x320 thumbnail
			var ptSize:Point = Util.GetLimitedImageSize(imgd.composite.width, imgd.composite.height, 320, 320);
			var bmdThumbnail:BitmapData = DrawUtil.GetResizedBitmapData(imgd.composite, ptSize.x, ptSize.y, false, 0xffffffff);
			var baThumbnail:ByteArray = bmdThumbnail.getPixels(bmdThumbnail.rect);
			
			// JPEG compress it. Quality == 8, no chroma subsampling
			baThumbnail = _jenc.Encode(baThumbnail, bmdThumbnail.width, bmdThumbnail.height, 92,
					null, 0, false);
			bmdThumbnail.dispose();
			
			// Let the server know which asset, if any, to transfer metadata from if it is ever called
			// upon to render this image.
			dctRenderOptions["metadataasset"] = imgd.baseImageAssetIndex;
			
			// Augment the render options with some other properties we want attached to
			// the created PicnikFile entry.
			dctRenderOptions["history:serviceid"] = "mycomputer";
			
			var dctItemInfo:Object = StorageServiceUtil.GetLastingItemInfo(
					ItemInfo.FromImageProperties(imgd.properties));
			for (var strProp:String in dctItemInfo)
				dctRenderOptions["history:iteminfo:" + strProp] = dctItemInfo[strProp];
				
			dctRenderOptions["history:iteminfo:history_serviceid"] = "mycomputer";
			PicnikService.CreateHistoryEntry(imgd.Serialize(true), imgd.GetSerializedAssetMap(true),
					dctRenderOptions, dctItemInfo, "mycomputer", baThumbnail, fnOnHistoryEntryCreated);
		}
	}
}
