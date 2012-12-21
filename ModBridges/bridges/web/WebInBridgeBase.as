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
package bridges.web {
	import bridges.Bridge;
	import bridges.BridgeItemEvent;
	import bridges.Downloader;
	import bridges.FileTransferBase;
	import bridges.IAutoFillSource;
	import bridges.flickr.FlickrProxy;
	import bridges.flickr.FlickrStorageService;
	import bridges.storageservice.*;
	
	import controls.list.PicnikTileList;
	
	import dialogs.BusyDialogBase;
	import dialogs.IBusyDialog;
	
	import flash.events.*;
	import flash.net.URLRequest;
	import flash.utils.*;
	
	import imagine.ImageDocument;
	
	import mx.collections.ICollectionView;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.TextInput;
	import mx.events.CollectionEvent;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;
	import mx.resources.ResourceBundle;
	import mx.utils.StringUtil;
	
	import urlkit.rules.UrlValueRule;
	
	import util.Cancelable;
	import util.KeyVault;
	
	public class WebInBridgeBase extends Bridge implements IAutoFillSource {
		// MXML-specified variables
		[Bindable] public var _tlst:PicnikTileList;
		[Bindable] public var _tiURL:TextInput;
		[Bindable] public var _btnOpen:Button;
		[Bindable] public var _uvrUrl:UrlValueRule;
   		[ResourceBundle("WebInBridge")] protected static var _rb:ResourceBundle;
		
		private static const kcxThumbnail:Number = 160; // CONFIG:
		private static const kcyThumbnail:Number = 160; // CONFIG:

		private var _bsy:IBusyDialog;
		private var _fShowingFlickrThumbnails:Boolean = false;

		private var _strCurrentAction:String = null;
		private var _itemInfo:ItemInfo;
		private var _canDownloadOp:Cancelable = null;
		private var _coll:ICollectionView;
		
		public override function GetMenuItems(): Array {
			if (_fShowingFlickrThumbnails)
				return [Bridge.EDIT_ITEM, Bridge.EMAIL_ITEM, Bridge.DOWNLOAD_ITEM, Bridge.OPEN_ITEMS_FLICKRPAGE];
			else
				return [Bridge.EDIT_ITEM, Bridge.EMAIL_ITEM, Bridge.DOWNLOAD_ITEM];
		}
		
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			_tlst.addEventListener(BridgeItemEvent.ITEM_ACTION, OnBridgeItemAction);
			_tlst.addEventListener(ListEvent.ITEM_CLICK, OnTileListItemClick);
			_tlst.addEventListener(CollectionEvent.COLLECTION_CHANGE, OnCollectionChange);
			_btnOpen.addEventListener(MouseEvent.CLICK, OnOpenClick);
			_tiURL.addEventListener(FlexEvent.ENTER, OnURLEnter);
			
			// Listen for a hash query 'url=' parameter
			_uvrUrl.addEventListener(Event.CHANGE, OnQueryUrlChange);
			OnCollectionChange();
		}
		
		private function OnCollectionChange(evt:Event=null): void {
			collection = _tlst ? _tlst.dataProvider as ICollectionView : null;
		}
		
		[Bindable]
		public function set collection(coll:ICollectionView): void {
			_coll = coll;
		}
		public function get collection(): ICollectionView {
			return _coll;
		}
		
		// Handle 'url=' hash query parameter
		private function OnQueryUrlChange(evt:Event): void {
			if (_uvrUrl.stringValue) {
				_tiURL.text = _uvrUrl.stringValue;
				_uvrUrl.stringValue = null;
				UpdateOrReturn(_tiURL.text);
			}
		}
		
		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
			_tiURL.setFocus();
			
			if (PicnikBase.app.AsService().HasImport()) {
				_tiURL.text = PicnikBase.app.AsService().GetImportUrl();
				Session.GetCurrent().SetSOCookie("import", null);
				
				// clear out import in case we've got something like &import=http://... in the url
				if ("import" in PicnikBase.app.parameters)
					PicnikBase.app.parameters["import"] = null;

				UpdateOrReturn(_tiURL.text);
			}
		}
		
		private function OnOpenClick(evt:MouseEvent): void {
			Open();
		}
		
		private function OnURLEnter(evt:FlexEvent): void {
			Open();
		}
		
		private function Open(): void {
			if (_tiURL.text == "") {
				// Heh, interesting photo easter egg
				PicnikService.Log("WebInBridge Flickr Interesting easter egg");
				ShowBusy();
				var flkrp:FlickrProxy = new FlickrProxy(KeyVault.GetInstance().flickr.pub, KeyVault.GetInstance().flickr.priv);
				flkrp.interestingness_getList({ extras: "original_format", per_page: "500" }, OnInterestingnessGetList);
				_fShowingFlickrThumbnails = true;
				
			} else if (_tiURL.text.indexOf("flickr:") != -1) {
				// Heh, Flickr search easter egg
				PicnikService.Log("WebInBridge Flickr Search easter egg");
				ShowBusy();
				flkrp = new FlickrProxy(KeyVault.GetInstance().flickr.pub, KeyVault.GetInstance().flickr.priv);

				var dctSearch:Object = {
					tag_mode: "all", sort: "interestingness-desc",
					extras: "original_format", per_page: "500"
				}

				var strArgs:String = StringUtil.trim(_tiURL.text.slice(7));
				var astrArgsRaw:Array = strArgs.split(" ");
				var astrArgs:Array = [];
				var fTextSearch:Boolean = false;
				var strGroup:String = null;
				var dctGroups:Object = {
					picnikers: "38017790@N00", textures: "604871@N20", collage: "47411174@N00"
				}
				
				for each (var str:String in astrArgsRaw) {
					if (str.charAt(0) == "-") {
						if (str.indexOf("-sort:") != -1) {
							// Will be one of: date-posted-desc, date-posted-asc, date-taken-asc, date-taken-desc,
							// interestingness-desc, interestingness-asc, relevance
							dctSearch.sort = str.slice(6);
						} else if (str.indexOf("-license:") != -1) {
							// Will be one or more (comma separated) of:
							// 4 -- "Attribution License"
							// 6 --"Attribution-NoDerivs License"
							// 3 -- "Attribution-NonCommercial-NoDerivs License"
							// 2 -- "Attribution-NonCommercial License"
							// 1 -- "Attribution-NonCommercial-ShareAlike License"
							// 5 -- "Attribution-ShareAlike License"
							// 7 -- "No known copyright restrictions"
							dctSearch.license = str.slice(9);
						} else if (str == "-text") {
							fTextSearch = true;
						} else if (str == "-safe") {
							dctSearch.safe_search = "1";
						} else if (str.indexOf("-group:") != -1) {
							strGroup = str.slice(7);
							if (strGroup in dctGroups)
								strGroup = dctGroups[strGroup];
							dctSearch.group_id = strGroup;
						}
					} else {
						astrArgs.push(str);
					}
				}
				
				if (!fTextSearch) {
					var strTags:String = astrArgs.join(",");
					if (strTags != null && strTags != "")
						dctSearch.tags = strTags;
				} else {
					dctSearch.text = astrArgs.join(" ");
				}
				
				var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount("Flickr");
				if (tpa != null && tpa.GetToken() != null)
					dctSearch.auth_token = tpa.GetToken();
				if (strGroup != null) {
					flkrp.groups_pools_getPhotos(dctSearch, OnInterestingnessGetList);
				} else {
					flkrp.photos_search(dctSearch, OnInterestingnessGetList);
				}
				_fShowingFlickrThumbnails = true;
				
			} else {
				// UNDONE: validate _tiInput.text (legal chars, length)
				// Hmm.. UpdateOrReturn's call to NormalizeURL does this validation but
				// nothing is reported to the user if it fails
				PicnikService.Log("WebInBridge getting " + _tiURL.text);
				UpdateOrReturn(_tiURL.text);
				_fShowingFlickrThumbnails = false;
			}
		}
		
		private function OnInterestingnessGetList(rsp:XML): void {
			HideBusy();
			if (rsp.@stat != "ok")
				return;
				
			var aob:Array = new Array();
			var xlph:XMLList = rsp.photos.photo;
			for each (var ph:XML in xlph) {
				var itemInfo:ItemInfo = FlickrStorageService.ItemInfoFromPhoto(ph);
				var imgp:ImageProperties = itemInfo.asImageProperties();
				aob.push(imgp);
			}
			_tlst.dataProvider = aob;
		}
		
		private function OnTileListItemClick(evt:ListEvent): void {
//			_tiURL.text = IDataRenderer(evt.itemRenderer).data.thumbUrl;
		}

		private function OnBridgeItemAction(evt:BridgeItemEvent): void {
			switch (evt.action) {
			case Bridge.EDIT_ITEM:
			case Bridge.EMAIL_ITEM:
			case Bridge.DOWNLOAD_ITEM:
				// Email and download start by getting the image.
				DownloadImage(ItemInfo.FromImageProperties(evt.bridgeItemData as ImageProperties), evt.action);
				break;
				
			case Bridge.OPEN_ITEMS_FLICKRPAGE:
				PicnikBase.app.NavigateToURL(new URLRequest(evt.bridgeItemData.webpageurl), "_blank");
				break;
				
			case Bridge.ADD_GALLERY_ITEM:
				addGalleryItem(evt);
				break;
				
			}
		}

		// If strURL is a web page, update the ImageListView and the current directory.
		// If strURL is an image, return it to the FileDialog's caller for processing.
		private function UpdateOrReturn(strURL:String, fReturnOnly:Boolean=false): void {
			
			// If the URL has no trailing ".com" etc, add ".com"
			var nRestIndex:Number = strURL.indexOf("://");
			nRestIndex = (nRestIndex == -1) ? 0 : nRestIndex + 3;
			var strRest:String = strURL.substr(nRestIndex);
			if ((strRest.indexOf('.') == -1) && (strRest.indexOf('/') == -1)) {
				strURL += ".com";
			}
			
			strURL = Util.NormalizeURL(strURL);

			if (!fReturnOnly) {
				var imgp:ImageProperties = ImageProperties.UpgradedImgpFromURL(strURL);
				if (imgp) {
					if (this is WebInBasket) {
						if (imgp.sourceurl) {
							OnGetImageURLsDone(PicnikService.errNone, null, imgp.sourceurl, [ imgp.sourceurl ]);
							return;
						}
					} else {
						DownloadImage(ItemInfo.FromImageProperties(imgp));
						return;
					}
				}
			}
			
			var strQuerylessURL:String = Util.GetQuerylessURL(strURL);
			var ichExt:Number = strQuerylessURL.lastIndexOf(".");
			if (ichExt != -1) {
				var strExt:String = strQuerylessURL.slice(ichExt + 1).toLowerCase();
				switch (strExt) {
				case "jpg":
				case "jpeg":
				case "gif":
				case "png":
				case "bmp":
				case "tif":
				case "tiff":
				// UNDONE: the rest of the extensions we support
					if (this is WebInBasket) {
						OnGetImageURLsDone(PicnikService.errNone, null, strURL, [ strURL ]);
					} else {
						DownloadImage(ItemInfo.FromImageProperties(new ImageProperties("web", strURL)), null, !fReturnOnly);
					}
					return;
				}
			}
			
			// Go get the thing pointed at by the URL. If it's HTML, pull all the IMGs out of it.
			// If it's an image, return it to the caller for opening.
			_tiURL.text = strURL;
			_tiURL.setSelection(_tiURL.text.length, _tiURL.text.length);
			ShowBusy();
			PicnikService.GetImagesFromUrl(strURL, OnGetImageURLsDone, OnGetImageURLsProgress);
		}

		private function OnGetImageURLsProgress(cbLoaded:Number, cbTotal:Number): void {
			// UNDONE:
		}
		
		private function OnGetImageURLsDone(err:Number, strError:String, strURL:String=null, astrImageURLs:Array=null): void {
			HideBusy();
			
			// After deactivation residual, non-cancelable operations may complete. Don't act on them.
			if (!active)
				return;
			
			switch (err) {
			case PicnikService.errNone:
				// OK, this is a web page
				_tiURL.text = strURL;
				_tiURL.setSelection(0, _tiURL.text.length);
	
				// Start the async process of popluating the ImageListView
				PopulateTileList(astrImageURLs);
				break;
	
			// If the requested URL points to something, but not HTML, and not an
			// unsupported image type then it must be an image we can load! Return it.
			case PicnikService.errHTTPNotHTML:
				var strURL:String = _tiURL.text;
				DownloadImage(ItemInfo.FromImageProperties(new ImageProperties("web", strURL)));
				return;
				
			case PicnikService.errHTTPFormatNotSupported:
				Util.ShowAlert(Resource.getString("WebInBridge", "unable_to_load_page"), Resource.getString("WebInBridge", "Error"), Alert.OK,
						"ERROR:in.bridge.web.get_image_urls: " + err + ", " + strError);
				break;
				
			case PicnikService.errHTTPNotFound:
				Util.ShowAlertWithoutLogging(Resource.getString("WebInBridge", "couldnt_find_page"), Resource.getString("WebInBridge", "Error"), Alert.OK);
				break;			
				
	//		case PicnikService.errHTTP*:
			default:
				Util.ShowAlert(Resource.getString("WebInBridge", "unable_to_load_page"), Resource.getString("WebInBridge", "Error"), Alert.OK,
						"ERROR:in.bridge.web.get_image_urls: " + err + ", " + strError);
				break;
			}
		}
	
		private function PopulateTileList(astrImageURLs:Array): void {
			var aob:Array = new Array();
			for (var i:Number = 0; i < astrImageURLs.length; i++) {
				var imgp:ImageProperties = new ImageProperties("web", astrImageURLs[i], null,
						StringUtil.substitute( Resource.getString("WebInBridge", "default_description"), _tiURL.text) );
				imgp.thumbnailurl = astrImageURLs[i];
				imgp.webpageurl = _tiURL.text;
				imgp.title = ImageProperties.TitleFromPathOrURL(imgp.sourceurl);
				aob.push(imgp);
			}
			
			_tlst.dataProvider = aob;
		}
		
		private function DownloadImage(itemInfo:ItemInfo, strAction:String=null, fUpgrade:Boolean=true): void {
			if (fUpgrade) {
				_itemInfo = ItemInfo.FromImageProperties(
					itemInfo.asImageProperties().GetUpgradedImgp()); // Look for upgrades (e.g. find the bigger version)
				if (_itemInfo == null)
					_itemInfo = itemInfo; // No upgrades found
			} else {
				_itemInfo = itemInfo;
			}
			_strCurrentAction = strAction;
			ValidateOverwrite(DoDownloadImage);
		}
				
		private function DoDownloadImage(): void {
			_bsy = BusyDialogBase.Show(PicnikBase.app, Resource.getString("WebInBridge", "Loading"), BusyDialogBase.LOAD_USER_IMAGE, "ProgressWithCancel", 0, OnDownloadCancel);

			var fSS:Boolean = false;
			var strService:String = PicnikBase.app.ImagePropertyBridgeToService(_itemInfo./*bridge*/serviceid);
			if (strService) {
				var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount(strService);
				if (tpa != null) {	
					var ss:IStorageService = tpa.storageService;
					ss.GetItemInfo( _itemInfo./*ss_*/setid, _itemInfo./*ss_item*/id, OnGetItemInfo );
					fSS = true;
				}
			}
			
			if (!fSS) DoDownloadImage2(_itemInfo);
		}
		
		private function OnGetItemInfo( err:Number, strError:String, itemInfo:ItemInfo ): void {
			if (err == StorageServiceError.None) {
				_itemInfo = itemInfo;
			}
			DoDownloadImage2(_itemInfo);
		}
		
		private function DoDownloadImage2(iinfo:ItemInfo): void {
			_canDownloadOp = new Cancelable(this, OnDownloadDone);
			var dnldr:Downloader = new Downloader(iinfo, "/WebInBridge", _canDownloadOp.callback, OnDownloadProgress);
			dnldr.Start();
		}
		
		private function OnDownloadCancel(dctResult:Object): void {
			_bsy.Hide();
			_bsy = null;
			_canDownloadOp.Cancel();
		}
		
		private function OnDownloadProgress(strStatus:String, nFractionDone:Number): void {
			if (_bsy)
				_bsy.progress = nFractionDone * 100;
		}
		
		private function OnDownloadDone(err:Number, strError:String, dnldr:FileTransferBase): void {
			// we'll only process the "OnDownloadDone" if the _bsy box is still around. 
			// if it's not around, then we've been cancelled.
			if (_bsy && dnldr != null) {
				_bsy.Hide();
				_bsy = null;
				if (err != ImageDocument.errNone) {
					var strT:String = Resource.getString("WebInBridge", "failed_to_download");
					if (strError.search(/^Error #2035/) != -1)
						strT = Resource.getString("WebInBridge", "cant_find_url");
					Util.ShowAlert(strT, Resource.getString("WebInBridge", "Error"), Alert.OK,
							"ERROR:in.bridge.web.download: " + err + ", " + strError);
					return;
				}
				
				ReportSuccess(null, "import");
				PicnikBase.app.activeDocument = dnldr.imgd;
									
				// Go to the next destination:
				NavigateToAction(_strCurrentAction);
			}
		}
	}
}
