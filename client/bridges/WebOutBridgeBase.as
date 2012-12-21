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
package bridges {
	import dialogs.IBusyDialog;
	import dialogs.BusyDialogBase;
	import flash.events.*;
	import mx.events.FlexEvent;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.ProgressBar;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import mx.controls.TextInput;
	import events.ActiveDocumentEvent;
	import mx.resources.ResourceBundle;
	
	public class WebOutBridgeBase extends OutBridge {
		[Bindable] public var _cboxFormat:ComboBox;
		[Bindable] public var _btnSave:Button;
		[Bindable] public var _tiURL:TextInput;
		[Bindable] public var _tiWidth:TextInput;
		[Bindable] public var _tiHeight:TextInput;
   		[ResourceBundle("WebOutBridge")] private var _rb:ResourceBundle;

		public var _strFileSavedNotifyMessage:String;

		public var _bsy:IBusyDialog;
		
		public function WebOutBridgeBase() {
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}

		private function OnCreationComplete(evt:FlexEvent):void {
			_btnSave.addEventListener(MouseEvent.CLICK, OnSaveClick);
			_cboxFormat.addEventListener(Event.CHANGE, OnFormatChange);
		}		

		override protected function OnActiveDocumentChange(evt:ActiveDocumentEvent): void {
			super.OnActiveDocumentChange(evt);
			if (_imgd != null) {
				_tiWidth.text = String(_imgd.width);
				_tiHeight.text = String(_imgd.height);
			}
		}
		
		private function OnFormatChange(evt:Event): void {
			currentState = _cboxFormat.selectedItem.data;
		}
		
		private function OnSaveClick(evt:MouseEvent): void {
			_bsy = BusyDialogBase.Show(this, Resource.getString("WebOutBridge", "Saving"), "", 0.5, OnSaveCancel);
//			var cxDim:Number = _cmboImageSize.selectedItem.data;
//			var cyDim:Number = cxDim;
			var cxDim:Number = 0;
			var cyDim:Number = 0;
			if (cxDim == 0) cxDim = _imgd.width;
			if (cyDim == 0) cyDim = _imgd.height;
			
			_imgd.Post(_tiURL.text, cxDim, cyDim, null, OnPostDone);
		}
				
		private function OnFileDownloadProgress(evt:ProgressEvent): void {
			if (_bsy)
				_bsy.progress = (evt.bytesLoaded / evt.bytesTotal) * 100;
		}
				
		private function OnPostDone(err:Number, strError:String): void {
			_bsy.Hide()
			_bsy = null;
			if (err == 0) {
				ReportSuccess(null, "export");
				PicnikBase.app.Notify(_strFileSavedNotifyMessage, 1000);
			} else {
				Util.ShowAlert( Resource.getString("WebOutBridge", "unable_to_save"), Resource.getString("WebOutBridge", "Error"), Alert.OK,
						"ERROR:out.bridge.web.post: " + err + ", " + strError);
			}
		}
		
		private function OnSaveCancel(dctResult:Object): void {
			// May already have been hidden by OnDownloadCancel
			if (_bsy) {
				_bsy.Hide();
				_bsy = null;
			}
		}
	}
}
