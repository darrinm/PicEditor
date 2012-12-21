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
package containers {
	
	import bridges.email.EmailShareBridge;
	import bridges.storageservice.StorageServiceUtil;
	
	import containers.SendGreetingContentBase;
	
	import flash.display.DisplayObject;
	
	import imagine.ImageDocument;
	
	import mx.containers.Canvas;
	import mx.containers.ViewStack;
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.resources.ResourceBundle;
	
	import pages.Page;
	
	import util.GreetingUploader;
	import util.ISendGreetingPage;
	
	import views.TargetAwareView;
	
	public class SendGreetingOutBridgesPageBase extends SendGreetingPageBase {
		[Bindable] public var _imgv:TargetAwareView;
		[Bindable] public var _brgEmailShare:EmailShareBridge;
		
		private var _imgd:ImageDocument;
		private var _cachedItemInfo:ItemInfo;

		[Bindable] [ResourceBundle("SendGreetingDialogBase")] protected var _rb:ResourceBundle;

		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
			// Grab the ImageDocument from the parent and initialize our view of it.
			if (_imgv.imageDocument == null) {
				_imgd = greetingParent.imageDocument;
				_imgv.imageDocument = _imgd;
				_imgv.zoom = _imgv.zoomMin;
				_imgv.setStyle("color", null); // Otherwise the background of the view is orange!!!
			}
			_brgEmailShare.OnActivate(strCmd);
		}
		
		override public function OnDeactivate():void {
			_brgEmailShare.OnDeactivate();
			super.OnDeactivate();
		}

		protected function GetGreetingItemInfo(fnComplete:Function): void {			
			var fnGetFileProps:Function = function(iinf:ItemInfo):void {
				if (iinf) {
					PicnikService.GetFileProperties(iinf['id'], null, null, fnOnGetFileProps);
				} else {
					fnComplete(null);
				}
			}
				
			var fnOnGetFileProps:Function = function(err:Number, strError:String, dctProps:Object=null): void {
				_cachedItemInfo = null;
				if (err == PicnikService.errNone) {
					_cachedItemInfo = StorageServiceUtil.ItemInfoFromPicnikFileProps(dctProps, null, "Greeting");
					_imgd.isDirty = false;
					_cachedItemInfo.title = _imgd.properties.title;
				}
				fnComplete(_cachedItemInfo);	
			}
				
			if (_cachedItemInfo == null || _imgd.isDirty) {
				var upl:GreetingUploader = new GreetingUploader();
				upl.DoUploadFile(null, _imgd.composite, fnGetFileProps);
			} else {
				fnComplete( _cachedItemInfo );
			}
		}
	}
}
