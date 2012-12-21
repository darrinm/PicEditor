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
package {
	import errors.AssertionFailedError;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	import mx.containers.TitleWindow;
	import mx.containers.VBox;
	import mx.controls.HRule;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.controls.TextInput;
	import mx.managers.PopUpManager;
	
	public class Debug {
		private static var _twDebug:TitleWindow;
		private static var _vbx:VBox;
		
		private static var _snMilliPrev:Number = 0;
		
		public static function TraceTime(str:String): void {
			var nMilliNow:Number = new Date().time;
			var strElapsed:String = (_snMilliPrev == 0) ? "start" : String(nMilliNow - _snMilliPrev);
			_snMilliPrev = nMilliNow;
			trace(str + ": " + strElapsed + " (" + nMilliNow + ")");
		}
		
		public static function Show(strName:String, bmd:BitmapData): void {
			if (_twDebug == null) {
				_twDebug = new TitleWindow();
				_twDebug.height = 1000;
				PopUpManager.addPopUp(_twDebug, PicnikBase.app);
				_vbx = new VBox();
				_vbx.percentHeight = 100;
				_vbx.percentWidth = 100;
				_twDebug.addChild(_vbx);
			}
			
			var hr:HRule = new HRule();
			_vbx.addChild(hr);
			
			var lbl:Label = new Label();
			lbl.text = strName;
			_vbx.addChild(lbl);
			
			var strOut:String = null;
			if (bmd == null) {
				strOut = "null";
			} else {
				try {
					var n:Number = bmd.width;
				} catch (e:Error) {
					strOut = "invalid";
				}
			}
			if (strOut == null) {
				var img:Image = new Image();
				img.width = 100;
				img.height = img.width * 6/8;
				img.source = new Bitmap(bmd.clone());
				_vbx.addChild(img);
			} else {
				var lbl2:TextInput = new TextInput();
				lbl2.text = "No image: [" + strOut + "]";
				_vbx.addChild(lbl2);
				hr.percentWidth = 100;
			}
		}
		
		public static function Assert(f:Boolean, strMessage:String=null, obExtra:Object=null): void {
			if (!f) {
				var strOut:String = "";
				if (strMessage)
					// UNDONE: Log something here?
					// PicnikService.Log(strMessage, PicnikService.knLogSeverityError);
					strOut += " " + strMessage;
				if (obExtra != null)
					strOut += " " + String(obExtra);
				trace("Assert!" + strOut);
				throw new AssertionFailedError(strOut);
			}
		}
	}
}
