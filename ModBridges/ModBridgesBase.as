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
	import bridges.facebook.FacebookBasket;
	import bridges.facebook.FacebookInBridge;
	import bridges.facebook.FacebookOutBridge;
	import bridges.facebook.FacebookStorageService;
	import bridges.flickr.FlickrBasket;
	import bridges.flickr.FlickrInBridge;
	import bridges.flickr.FlickrOutBridge;
	import bridges.flickr.FlickrSaveDialog;
	import bridges.flickr.FlickrStorageService;
	import bridges.gallery.GalleryInBridge;
	import bridges.gallery.GalleryStorageService;
	import bridges.history.HistoryBasket;
	import bridges.history.HistoryInBridge;
	import bridges.history.HistoryStorageService;
	import bridges.photobucket.PhotobucketBasket;
	import bridges.photobucket.PhotobucketInBridge;
	import bridges.photobucket.PhotobucketOutBridge;
	import bridges.photobucket.PhotobucketStorageService;
	import bridges.picasaweb.PicasaWebBasket;
	import bridges.picasaweb.PicasaWebInBridge;
	import bridges.picasaweb.PicasaWebOutBridge;
	import bridges.picasaweb.PicasaWebStorageService;
	import bridges.postsave.PostSave;
	import bridges.printer.PrinterOutBridge;
	import bridges.storageservice.IStorageService;
	import bridges.twitter.TwitterInBridge;
	import bridges.twitter.TwitterOutBridge;
	import bridges.twitter.TwitterStorageService;
	import bridges.web.WebInBasket;
	import bridges.web.WebInBridge;
	import bridges.webcam.WebCamInBridge;
	import bridges.yahoomail.YahooMailBasket;
	import bridges.yahoomail.YahooMailInBridge;
	import bridges.yahoomail.YahooMailInBridgeBase;
	import bridges.yahoomail.YahooMailStorageService;
	import bridges.yahoomail.YahooMailWelcome;
	
	import containers.ResizingDialog;
	
	import dialogs.DialogHandle;
	
	import module.PicnikModule;
	
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;

	public class ModBridgesBase extends PicnikModule {

		public function GetStorageService(strId:String): IStorageService {
			if (strId.toLowerCase() == "facebook") {
				return new FacebookStorageService();
			}
			if (strId.toLowerCase() == "picasaweb") {
				return new PicasaWebStorageService();
			}
			if (strId.toLowerCase() == "photobucket") {
				return new PhotobucketStorageService();
			}
			if (strId.toLowerCase() == "yahoomail") {
				return new YahooMailStorageService();
			}
			if (strId.toLowerCase() == "flickr") {
				return new FlickrStorageService();
			}
			if (strId.toLowerCase() == "twitter") {
				return new TwitterStorageService();
			}
			if (strId.toLowerCase() == "show") {
				return new GalleryStorageService();
			}
			if (strId.toLowerCase() == "history") {
				return new HistoryStorageService();
			}
			return null;
		}			
		
		private var _aSupportedBridges:Array = [
			{ id: "_brgPrinterOut",
				cls: PrinterOutBridge },
			
			{ id: "_brgPostSave",
				cls: PostSave },
			
			{ id: "_brgWebIn",
				cls: WebInBridge },
			
			{ id: "_brgWebInBasket",
				cls: WebInBasket,
				instanceId: "_brgWebIn" },
			
			{ id: "_brgWebCamIn",
				cls: WebCamInBridge },
			
			{ id: "_brgFacebookIn",
				cls: FacebookInBridge },
			
			{ id: "_brgFacebookInBasket",
				cls: FacebookBasket,
				instanceId: "_brgFacebookIn" },
			
			{ id: "_brgFacebookOut",
				cls: FacebookOutBridge },

			{ id: "_brgPicasaWebIn",
				cls: PicasaWebInBridge },
			
			{ id: "_brgPicasaWebInBasket",
				cls: PicasaWebBasket,
				instanceId: "_brgPicasaWebIn" },
			
			{ id: "_brgPicasaWebOut",
				cls: PicasaWebOutBridge },
			
			{ id: "_brgPhotobucketIn",
				cls: PhotobucketInBridge },
			
			{ id: "_brgPhotobucketInBasket",
				cls: PhotobucketBasket,
				instanceId: "_brgPicasaWebIn" },
			
			{ id: "_brgPhotobucketOut",
				cls: PhotobucketOutBridge }	,
				
			{ id: "_brgYahooMailIn",
				cls: YahooMailInBridge },
			
			{ id: "_brgYahooMailInBasket",
				cls: YahooMailBasket,
				instanceId: "_brgYahooMailIn" },
			
			{ id: "_brgYahooMailWelcome",
				cls: YahooMailWelcome },

			{ id: "_brgFlickrIn",
				cls: FlickrInBridge},
			
			{ id: "_brgFlickrInBasket",
				cls: FlickrBasket,
				instanceId: "_brgFlickrIn" },
			
			{ id: "_brgFlickrOut",
				cls: FlickrOutBridge },
			
			{ id: "_brgTwitterOut",
				cls: TwitterOutBridge},
			
			{ id: "_brgGalleryIn",
				cls: GalleryInBridge},
			
			{ id: "_brgHistoryIn",
				cls: HistoryInBridge},
			
			{ id: "_brgHistoryInBasket",
				cls: HistoryBasket,
				instanceId: "_brgHistoryIn" },
		];
			
		public function GetActivatableChild( id:String ):IActivatable {
			for (var i:int = 0; i < _aSupportedBridges.length; i++) {
				if (_aSupportedBridges[i].id == id) {
					var oBridge:Object = _aSupportedBridges[i];
					if (!('instance' in oBridge)) {
						oBridge.instance = new oBridge.cls();
						oBridge.instance.id = ('instanceId' in oBridge) ? oBridge.instanceId : oBridge.id;
						oBridge.instance.includeInLayout = false;
						oBridge.instance.visible = false;
						this.addChild(oBridge.instance);	
					}
					return oBridge.instance;
				}
			}
			return null;
		}
		
		public function Show(strDialog:String, uicParent:UIComponent=null, fnComplete:Function=null, obParams:Object=null): DialogHandle {
			var dlg:Object = null;
			
			var dialogHandle:DialogHandle = new DialogHandle(strDialog, uicParent, fnComplete, obParams);
			
			// TODO (steveler) : move this over to a DialogRegistry class
			switch (strDialog) {
				case "FlickrSaveDialog":
					dlg = new FlickrSaveDialog();
					break;
				default:
					Debug.Assert(false, "Requesting unknown dialog " + strDialog);
					break;
			}
			var resizingDialog:ResizingDialog = dlg as ResizingDialog;
			if (null != resizingDialog) {
				if (uicParent == null) uicParent = PicnikBase.app;
				resizingDialog.Constructor(fnComplete, uicParent, obParams);
				ResizingDialog.Show(resizingDialog, uicParent);
			}		
			
			if (null != dlg) {
				dialogHandle.IsLoaded = true;
				dialogHandle.dialog = dlg;
			}
			
			return dialogHandle;
		} 				
	}
}
