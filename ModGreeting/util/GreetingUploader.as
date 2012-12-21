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
	import dialogs.BusyDialogBase;
	import dialogs.IBusyDialog;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import imageUtils.PNGEnc;
	
	import imagine.ImageDocument;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.resources.ResourceBundle;

	public class GreetingUploader {
		[ResourceBundle("GreetingUploader")] private var _rb:ResourceBundle;
		
		private var _bsy:IBusyDialog;
		private var _iidWaitForShow:Number;
		private var _fnUploadComplete:Function;
		private var _canUpload:Cancelable;
		private var _bmd:BitmapData;

		public function DoUploadFile(bsy:IBusyDialog, bmd:BitmapData, fnUploadComplete:Function): void {
			_fnUploadComplete = fnUploadComplete;
			_bmd = bmd;
			_bsy = bsy;
			
			
			// Compress the image (type 1 is slower but gives us files ~60% the size of type 0)
			// TODO(darrinm): Consider compressing as JPEG instead.
			// UNDONE: create an incremental, async PNG encoder
			var abImageData:ByteArray = imageUtils.PNGEnc.encode(_bmd, 1);
			
			_canUpload = new Cancelable(this, OnUploadComplete);
			AssetMgr.PostAsset(abImageData, "image/png", "greeting", false, null, OnUploadProgress, _canUpload.callback);
			
		}
		
		public function CancelUploadFile():void {
			if (_canUpload) {
				_canUpload.Cancel();
			}
		}
		
		private function OnBusyShow(): void {
			_iidWaitForShow = setInterval(OnBusyShow, 500);	
			clearInterval(_iidWaitForShow);
			
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
			
			var iinf:ItemInfo = null;
			if (err != ImageDocument.errNone) {
				Util.ShowAlert(Resource.getString("GreetingUploader", "upload_failed"), Resource.getString("GreetingUploader", "error"), Alert.OK,
						"ERROR:in.bridge.sendgreeting.upload: " + err + ", " + strError);
			} else {
				// Steve wants an ItemInfo for handy access to the fid's sourceurl and thumbnailurl.
				iinf = ItemInfo.create("sendgreeting");
				iinf.SetFid(fidAsset);
			}
			
			if (_fnUploadComplete != null)
				_fnUploadComplete(iinf);
		}
	}
}
