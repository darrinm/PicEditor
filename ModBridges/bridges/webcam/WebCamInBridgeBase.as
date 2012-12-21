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
package bridges.webcam {
	import bridges.Bridge;
	
	import controls.WebCamSelector;
	import controls.WebCamSelectorBase;
	
	import dialogs.BusyDialogBase;
	import dialogs.IBusyDialog;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.net.URLLoader;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.utils.ByteArray;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import imageUtils.PNGEnc;
	
	import imagine.ImageDocument;
	
	import mx.containers.Box;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.core.BitmapAsset;
	import mx.events.StateChangeEvent;
	import mx.resources.ResourceBundle;
	import mx.utils.StringUtil;
	
	import util.AssetMgr;
	import util.Cancelable;
	import util.VBitmapData;
	
	public class WebCamInBridgeBase extends Bridge {
		// MXML-specified variables
		[Bindable] public var _btnTakePhoto:Button;
		[Bindable] public var _btnTryCameraAgain:Button;
		[Bindable] public var _btnKeepPhoto:Button;
		[Bindable] public var _imgPreview:Image;
		[Bindable] public var _bxWcs:Box;
		[ResourceBundle("WebCamInBridge")] private var _rb:ResourceBundle;
				
		public var _strUploadedNotifyMessage:String;

		private var _cam:Camera;
		private var _vid:Video;
		private var _bmd:BitmapData;
		private var _bm:BitmapAsset;
		private var _iidCameraUpdate:Number;
		private var _urll:URLLoader;
		private var _iidWaitForShow:Number;
		
		private var _strImageName:String;
		private var _imgp:ImageProperties;
		private var _bsy:IBusyDialog;
		private var _canUpload:Cancelable;
		
		private var _wcs:WebCamSelectorBase = null;
		
		public function WebCamInBridgeBase() {
			super();
		}
	
		public override function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
			
			switch (currentState) {
			case null:
				SetupCamera();
				break;
			
			case "take_photo":
				_vid.attachCamera(_cam);
				_iidCameraUpdate = setInterval(OnCameraUpdateInterval, 33)
				break;
			}
		}
		
		public override function OnDeactivate(): void {
			super.OnDeactivate();
			
			switch (currentState) {
			case "take_photo":
				if (_vid)
					_vid.attachCamera(null);
				if (_iidCameraUpdate)
					clearInterval(_iidCameraUpdate);
				break;
			}
		}
		
		// Try to get the right camera
		// Includes some smarts for iSight cameras, which aren't always the default camera.
		private function GetCamera(): Camera {
			var cam:Camera = null;
			if (Camera.names.length < 2) {
				cam = Camera.getCamera(); // Only one camera
			} else {
				if (_wcs == null) {
					_wcs = new WebCamSelector();
					_bxWcs.addChild(_wcs);
					_wcs.addEventListener("change", OnCameraSelectorCameraChange);
				}
				cam = _wcs.camera;
			}
			return cam;
		}
		
		protected function OnCameraSelectorCameraChange(evt:Event): void {
			camera = _wcs.camera;
		}
		
		public function set camera(cam:Camera): void {
			if (_cam != cam) {
				_cam = cam;
				if (_cam) {
					_vid.attachCamera(_cam);
					_cam.addEventListener(StatusEvent.STATUS, OnCameraStatus);
					_cam.setMode(640, 480, 30);
				}
				if (!_cam || _cam.muted) {
					Security.showSettings(SecurityPanel.PRIVACY);
					currentState = "need_permission";
					return;
				}
				
				currentState = "take_photo";
			}
		}
		
		private function SetupCamera(): void {
			// Check if the user has a camera
			if (Camera.names.length == 0) {
				currentState = "no_camera";
				return;
			}
			
			_cam = GetCamera();
			_cam.addEventListener(StatusEvent.STATUS, OnCameraStatus);
			_cam.setMode(640, 480, 30);
			
			// Might return null (user won't give us permission to use their camera)
			if (!_cam || _cam.muted) {
				Security.showSettings(SecurityPanel.PRIVACY);
				currentState = "need_permission";
				return;
			}
			
			currentState = "take_photo";
		}
		
		override protected function OnStateChange(evt:StateChangeEvent): void {
			super.OnStateChange(evt);
			
			switch (evt.newState) {
			case "take_photo":
				if (_imgPreview.source == null) {
					if (_cam.width == 0 || _cam.height == 0) {
						PicnikService.Log("Client webcam bad size: " + _cam.width + "x" + _cam.height, PicnikService.knLogSeverityWarning);
						// UNDONE: we could throw an exception or handle the error here, but in the
						// interests of keeping this change small I'm leaving the following code path unmodified 					
					}
					
					// Create a BitmapData object, same size as Camera and make it visible
					_bmd = new VBitmapData(_cam.width, _cam.height, false, 0xffffffff, "web cam photo");
					_bm = new BitmapAsset(_bmd);
					
					_imgPreview.source = _bm;
					
					// Attach Camera to a flash.media.Video instance
					_vid = new Video(_cam.width, _cam.height);
				}
				_vid.attachCamera(_cam);
				// Start a timer to copy the video image to the visible BitmapData
				_iidCameraUpdate = setInterval(OnCameraUpdateInterval, 33);
				break;
				
			default:
				if (_vid)
					_vid.attachCamera(null);
				if (_iidCameraUpdate)
					clearInterval(_iidCameraUpdate);
				break;
			}
		}
		
		private function OnCameraStatus(evt:StatusEvent): void {
			if (evt.code == "Camera.Muted")
				currentState = "need_permission";
			else
				currentState = "take_photo";
		}
		
		private function OnCameraUpdateInterval(): void {
 			// Flip along x axis to act like a mirror
 			var mat:Matrix = new Matrix();
 			mat.a = -1;
 			mat.tx = _bmd.width;
			_bmd.draw(_vid, mat);
		}
		
		protected function TryCameraAgain(): void {
			SetupCamera();
		}
		
		// This event handler is set in WebCamInBridge.mxml
		protected function OnTakePhotoClick(evt:MouseEvent): void {
			if (currentState == "take_photo") {
				currentState = "keep_photo";
			} else {
				currentState = "take_photo";
			}
		}
		
		// This event handler is set in WebCamInBridge.mxml
		public function OnKeepPhotoClick(evt:MouseEvent): void {
			ValidateOverwrite(DoUploadFile);
		}
		
		private function DoUploadFile(): void {
			_bsy = BusyDialogBase.Show(this, Resource.getString("WebCamInBridge", "Uploading"),BusyDialogBase.LOAD_WEBCAM_IMAGE, "ProgressWithCancel", 0, OnUploadCancel);
			
			// HACK: Wait 250 ms for the busy dialog to have faded in
			// UNDONE: create an incremental, async PNG encoder
			_iidWaitForShow = setInterval(OnBusyShow, 250);
		}
		
		private function OnBusyShow(): void {
			clearInterval(_iidWaitForShow);
			
			// Compress the image (type 1 is slower but gives us files ~60% the size of type 0)
			var abImageData:ByteArray = imageUtils.PNGEnc.encode(_bmd, 1);
			
			_imgp = new ImageProperties("webcam", null, Resource.getString("WebCamInBridge", "Webcam_photo"),
						StringUtil.substitute(Resource.getString("WebCamInBridge", "Taken_on"), util.LocUtil.shortDate(new Date())));
			
			PicnikService.Log("WebCamInBridge uploading photo");
			_canUpload = new Cancelable(this, OnUploadComplete);
			AssetMgr.PostAsset(abImageData, "image/png", "i_webcam", true, null, OnUploadProgress, _canUpload.callback);
		}
		
		private function OnUploadCancel(dctResult:Object): void {
			_bsy.Hide();
			_bsy = null;
			_canUpload.Cancel();
		}
		
		private function OnUploadProgress(strStatus:String, nFractionDone:Number): void {
			if (_bsy)
				_bsy.progress = nFractionDone * 100;
		}
		
		private function OnUploadComplete(err:Number, strError:String, fidAsset:String=null): void {
			if (_bsy) {
				_bsy.Hide();
				_bsy = null;
			}
			if (err != ImageDocument.errNone) {
				Util.ShowAlert(Resource.getString("WebCamInBridge", "upload_failed"), Resource.getString("WebCamInBridge", "Error"), Alert.OK,
						"ERROR:in.bridge.webcam.upload: " + err + ", " + strError);
			} else {
				var imgd:ImageDocument = new ImageDocument();
				var bmTemp:Bitmap = new Bitmap(_bmd); // Create a full sized bitmap incase _bm is scaled
				err = imgd.InitFromDisplayObject(_strImageName, fidAsset, bmTemp, _imgp);
				if (err == ImageDocument.errNone) {
					ReportSuccess(null, "upload");
					imgd.isDirty = true;
					PicnikBase.app.Notify(_strUploadedNotifyMessage);
					
					PicnikBase.app.activeDocument = imgd;
					PicnikBase.app.NavigateTo(PicnikBase.EDIT_CREATE_TAB);
				
					// Set the current state back to "take_photo" for the next time around
					currentState = "take_photo";
				} else {
					Util.ShowAlert(Resource.getString("WebCamInBridge", "upload_failed"),
							Resource.getString("WebCamInBridge", "Error"), Alert.OK,
							"ERROR:in.bridge.webcam.upload:2: init from display object failed");
				}
			}
		}
	}
}
