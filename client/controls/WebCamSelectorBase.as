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
package controls
{
	import mx.containers.Canvas;
	import flash.media.Camera;
	import flash.events.Event;
	import mx.events.FlexEvent;
	
	public class WebCamSelectorBase extends Canvas
	{
		public function WebCamSelectorBase(): void {
			super();
			Init();
		}

		// Use _aobCameraList for data binding. Array of camera objects
		// with .label = name and .data = id (to use with GetCamera)
		public var _aobCameraList:Array = new Array();
		private var _cameraOb:Object = null;
		
		[Bindable (event="ChangeCameraList")]
		public function get cameraList(): Array {
			return _aobCameraList;
		}
		
		[Bindable (event="change")]
		public function get camera(): Camera {
			if (_cameraOb == null) return null;
			return Camera.getCamera(_cameraOb.data.toString());
		}
		
		public function set cameraOb(ob:Object): void {
			if (_cameraOb != ob && ob != null) {
				_cameraOb = ob;
				dispatchEvent(new Event("change"));
			}
		}
		
		protected function Init(): void {
			var astrCameraNames:Array = Camera.names;
			var nPos:Number = 0;
			var strCameraName:String;
			for each (strCameraName in astrCameraNames) {
				_aobCameraList.push({label: strCameraName, data: nPos});
				nPos++;
			}
			
			// Sort these first, in this order.
			const kastrPreferredCameras:Array = ["USB Video Class Video", "IIDC FireWire Video"];
			var astrPreferredCameras:Array = kastrPreferredCameras.slice();
			var strDefaultCameraName:String = Camera.getCamera().name;
			if (astrPreferredCameras.indexOf(strDefaultCameraName) == -1) astrPreferredCameras.push(strDefaultCameraName);
			
			var nSwapHead:Number = 0; // Swap position
			for each (var strPreferedCameraName:String in astrPreferredCameras) {
				for (nPos = nSwapHead; nPos < _aobCameraList.length; nPos++) {
					if (_aobCameraList[nPos].label == strPreferedCameraName) {
						if (nPos != nSwapHead) {
							// Swap nPos with nSwapHead
							var obSwap:Object = _aobCameraList[nPos];
							_aobCameraList[nPos] = _aobCameraList[nSwapHead];
							_aobCameraList[nSwapHead] = obSwap;
						}
						nSwapHead++;
					}
				}
			}
			
			// Now rename our cameras
			const kaobRenames:Array = [{oldName:"USB Video Class Video", newName:"built-in iSight"},
					{oldName:"IIDC FireWire Video", newName:"External firewire camera"}];
					
			for each (var obRename:Object in kaobRenames) {
				for each (var obCam:Object in _aobCameraList) {
					if (obCam.label == obRename.oldName) obCam.label = obRename.newName;
				}
			}
			
			if (_aobCameraList.length > 0) cameraOb = _aobCameraList[0];
			dispatchEvent(new Event("ChangeCameraList"));
		}
	}
}