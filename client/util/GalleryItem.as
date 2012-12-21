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
package util
{
	import imagine.documentObjects.DocumentStatus;
	import imagine.documentObjects.IDocumentStatus;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import interfaces.slide.IImage;
	
	[Bindable]
	public class GalleryItem extends EventDispatcher implements IDocumentStatus
	{
		private var _dai:int = -1;
		private var _title:String = '';
		private var _caption:String = '';
		private var _strThumbUrl:String = '';
		private var _strUrl:String = '';
		private var _ssid:String = '';
		private var _ss:String = '';
		private var _strOwner:String = '';
		private var _strOwnerName:String = '';
		private var _strId:String = '';
		private var _dtCreated:Number = 0;
		private var _nRotation:Number = 0;
		private var _fActive:Boolean = false;
		private var _fIsBeingDragged:Boolean = false;
		
		private var _oPendingAssetSrc:IAssetSource = null;
		
		private var _gald:GalleryDocument;
		private var _nStatus:Number = DocumentStatus.Loading;
		private var _fCanDisplay:Boolean = true;
		private var _fLoadingSizes:Boolean = false;
		
		private var _anRetries:Array = [];
		private static const knMaxRetries:Number = 3;
		private static const knRetriesRetryPoint:Number = 2;
		
		[Embed(source="/assets/bitmaps/loadErrorFill.gif")]
		public static var s_clsErrorFill:Class;
		
		private const kErrNone:int = 0;
		private const kErrUnknown:int = 1;
		private const kBadAssetIndex:int = 2;	// asset couldn't be allocated
		private const kBadAssetFile:int = 3;	// asset couldn't be imported
		
		public function GalleryItem(dai:Number = -1, strThumbUrl:String = null) {
			_dai = dai;
			_strThumbUrl = strThumbUrl;
			_strId = Util.GetRandomId(4);	// gives us ~14M ids
			_dtCreated = new Date().time;
		}

		public static function Create(doc:GalleryDocument, asrc:IAssetSource): GalleryItem { 
			var giNew:GalleryItem = new GalleryItem();
			giNew.document = doc;
			giNew.assetSource = asrc;
			giNew.createFromAsset();			
			return giNew;
		}		

		public static function CreateFromImage(doc:GalleryDocument, iimg:IImage): GalleryItem { 
			var giNew:GalleryItem = new GalleryItem();
			giNew.document = doc;
			
			// we want set created to 0 (instead of "now") if there's no created date already set on the image
			giNew.created = 0;
			
			// copy the props over from the IImage object
			for (var k:String in iimg.oProps) {
				if (k in giNew) {
					giNew[k] = iimg.oProps[k];
				}										
			}
			
			var ss:String = iimg.GetProperty('ss');
			if (!ss || ss.length == 0 || ss == "Picnik") {
				giNew.url = null;	// don't set url -- we'll calculate it dynamically.
			}
			giNew.thumbUrl = iimg.GetThumbUrl();
			giNew.status = DocumentStatus.Loaded;
			return giNew;
		}				
		
		private function createFromAsset():void {
			//Trace("Create from asset");
			var giThis:GalleryItem = this;
			//trace( "GalleryItem:createFromAsset "+id );
 			var fnOnAssetCreated:Function = function(err:Number, strError:String, fidCreated:String=null): void {
 				//Trace("OnAssetCreated");
 				if (err != PicnikService.errNone) {
					giThis.HandleLoadFailure(kBadAssetIndex);
 				} else {
 					if (null == giThis.thumbUrl) {
 						giThis.thumbUrl = assetSource.thumbUrl;
 						giThis.url = assetSource.thumbUrl;
 					}
 					giThis.status = DocumentStatus.Loading;
 					giThis.ownerid = AccountMgr.GetInstance().GetUserId();
					giThis.ownername = AccountMgr.GetInstance().displayName;
					giThis.LoadSizesAndRotation();					
	 				giThis.dispatchEvent( new Event( Event.CHANGE ) );
 				}
 			}
 						
 			dai = document.CreateAsset( assetSource, fnOnAssetCreated, true );
			url = assetSource.sourceUrl ? assetSource.sourceUrl : assetSource.thumbUrl;
			thumbUrl = assetSource.thumbUrl;
			ss = "ext";
 			status = DocumentStatus.Loading;			
		}
		
		public function get active():Boolean {
			return _fActive;
		}
		
		public function set isBeingDragged(f:Boolean): void {
			_fIsBeingDragged = f;
		}
		
		public function get isBeingDragged(): Boolean {
			return _fIsBeingDragged;
		}
		
		public function set active(f:Boolean):void {
			_fActive = f;
			if (_fActive) {
				if (status == DocumentStatus.Static && dai >= 0) {
					status = DocumentStatus.Loading;
					//Trace("Change Active: Call Load sizes");
					LoadSizesAndRotation();
				}
			} else {
				//Trace("Change Active: Call Unload");
				Unload();
			}
		}
		
		public function get valid():Boolean {
			if (ss == "ext") {
				if (url == null || url.length == 0 || url == "/fid_error") {
					// external images MUST have an url
					return false;	
				}
			}
			return true;
		}

		public function set document(gald:GalleryDocument): void {
			_gald = gald;
		}
		
		public function get document(): GalleryDocument {
			return _gald;
		}
				
		public function get assetSource():IAssetSource {
			return _oPendingAssetSrc;
		}
		
		public function set assetSource(asrc:IAssetSource):void {
			_oPendingAssetSrc = asrc;
		}	
					
		public function get dai():int {
			return _dai;
		}
		public function set dai(dai:int):void {
			_dai = dai;
		}
		
		public function get thumbUrl():String {
			return _strThumbUrl;
		}
		public function set thumbUrl(strThumbUrl:String):void {
			_strThumbUrl = strThumbUrl;
		}
						
		public function get url():String {
			return _strUrl;
		}
		public function set url(strUrl:String):void {
			_strUrl = strUrl;
		}
				
		public function get ssid():String {
			return _ssid;
		}
		public function set ssid(id:String):void {
			_ssid = id;
		}
				
		public function get ss():String {
			return _ss;
		}
		public function set ss(s:String):void {
			_ss = s;
		}
				
		public function get title():String {
			return _title;
		}
		public function set title(t:String):void {
			_title = t ? t : "";
		}
		
		public function get caption():String {
			return _caption;
		}
		public function set caption(caption:String):void {
			_caption = caption ? caption : "";
		}
				
		public function get ownerid():String {
			return _strOwner;
		}
		public function set ownerid(o:String):void {
			_strOwner = o ? o : "";
		}
				
		public function get ownername():String {
			return _strOwnerName;
		}
		public function set ownername(o:String):void {
			_strOwnerName = o ? o : "";
		}	
					
		public function get created():Number {
			return _dtCreated;
		}

		public function set created(d:Number):void {
			_dtCreated = d;
		}
		
		public function get id():String {
			return _strId;
		}
		public function set id(i:String):void {
			_strId = i ? i : "";
		}
		
		// this function returns a list of all the properties that
		// the slideshow SWF player object is interested in.
		public function GetProperties(): Object {
			return {url: url,
					thumbUrl: thumbUrl,
					title: title,
					caption: caption,
					ownerid: ownerid,
					ownername: ownername,
					created: created,
					ss: ss,
					ssid: ssid,
					id: id,
					rotation: rotation };
		}		
		
		// IDocumentStatus methods
		public function set status(nStatus:Number): void {
			if (_nStatus == nStatus)
				return;				
			_nStatus = nStatus;
		}
		
		public function get status(): Number {
			return _nStatus;
		}
		
		// independent of the item data, can we currently display this image?
		// flag is raised when we give up trying to load the image.
		public function set canDisplay(b:Boolean): void {
			if (_fCanDisplay == b)
				return;				
			_fCanDisplay = b;
		}
		public function get canDisplay(): Boolean {
			return _fCanDisplay;
		}
		
		public function set rotation(nRotation:int): void {
			if (_nRotation == nRotation)
				return;				
			_nRotation = nRotation;
		}
		
		public function get rotation(): int {
			return _nRotation;
		}
		
		private function LoadSizesAndRotation(): void {
			//Trace("LoadSizesAndRotation - Call Get Properties");
			if (_fLoadingSizes) return;
			_fLoadingSizes = true;	
			//trace( "GalleryItem:LoadSizesAndRotation "+id );			
			document.GetAssetProperties(dai, "nWidth,nHeight,nRotation,strMimeType", OnGetFileProperties);
		}
		
		private function OnGetFileProperties(err:Number, strError:String, dctProps:Object=null): void {
			//Trace("On Got properties");
			_fLoadingSizes = false;

			if (err != PicnikService.errNone) {
				// Huh? Something is broken. Give up.
				HandleLoadFailure(kBadAssetFile);
				//trace("Photo.OnGetFileProperties error: " + err + ", " + strError);
				return;
			}
//			if (dctProps.nWidth == undefined || dctProps.nHeight == undefined) {
//				// Huh? Something is broken. Give up.
//				HandleLoadFailure(kBadAssetFile);
//				//trace("Photo.OnGetFileProperties error: properties undefined");
//				return;
//			}

			if (dctProps.nRotation != undefined)
				rotation = dctProps.nRotation;

			ss = "Picnik";
			ssid = document.GetAsset(dai);
				 			
			status = DocumentStatus.Loaded;
			if (!ss || ss.length == 0 || ss == "Picnik") {
				url = null;			
			}
			dispatchEvent( new Event( Event.CHANGE ) );
		}

		public function Unload(): void {
			//Trace("Unload");
			status = DocumentStatus.Static;
			//trace("Unloading GalleryItem " + this.id);
		}
		
		/*
		private static var _nNextID:Number = 1;
		private var _nID:Number = -1;
		private function Trace(str:String): void {
			if (_nID < 0) _nID = _nNextID++;
			trace("GI[" + _nID + ", " + _fActive + ", " + _fLoadingSizes + "]: " + str + "\t\t\t\t\t\t" + _strUrl);
		}
		*/
		
		private function GiveUp():void {
			// Treat it as an externally-hosted file and hope for the best for later.
			ss = "ext";
			dai = -1;
			status = DocumentStatus.Static;
			canDisplay = false;
			dispatchEvent( new Event( Event.CHANGE ) );
			return;			
		}
		
		private function HandleLoadFailure( nType:int ): void {
			//Trace("Handle load failure: " + nType);
			if (_anRetries[nType] != undefined)
				_anRetries[nType]++;
			else
				_anRetries[nType] = 1;

			//trace("GalleryItem:HandleLoadFailure " + nType + "(" + _anRetries[nType] + ") " + id);
			
			if (nType == kBadAssetIndex) {
				if (_anRetries[nType] >= knMaxRetries) {
					GiveUp();
					return;	
				}
				
				// reimport the asset. 
				if (null !== assetSource) {
					createFromAsset();
				} else if (null != url && url.length > 0) {
					// If we don't have an asset source, create one from the url.
					assetSource = new RemoteAssetSource( url, "web", new ImageProperties("web", url) );
					createFromAsset();
				} else {
					// If we don't have a URL, then whoops!
					GiveUp();
				}
			} else if (nType == kBadAssetFile) {
				if (_anRetries[nType] >= knMaxRetries) {
					// we're retried too many times -- try to recreate the asset from scratch
					_anRetries[nType] = knRetriesRetryPoint;
					HandleLoadFailure(kBadAssetIndex);
					return;	
				}
				
				// retry the get properties call
				LoadSizesAndRotation();
				return;
			}
		}
										
		public function copyTo( itm:GalleryItem ):void {
			itm.dai = dai;
			itm.thumbUrl = thumbUrl;
			itm.url = url;
			itm.caption = caption;
			itm.title = title;
			itm.id = id;
			itm.ownerid = ownerid;
			itm.ownername = ownername;
			itm.created = created;
			itm.ss = ss;
			itm.ssid = ssid;
			itm.status = status;
			itm.rotation = rotation;
			itm.document = document;
		}
		
		public function toXml(): XML {
			// to save space, we only save fields that aren't readily calculatable or defaults
			
			var xml:XML = <item id={id} created={created} ssid={ssid} active={active}/>;
			if (ss && ss.length > 0 && ss != "Picnik") {
				xml.@ss = ss;
			}
			if (dai >= 0) {
				xml.@dai = dai;
			}
			if (ownerid && ownerid != document.GetProperty("ownerid")) {
				xml.@ownerid = ownerid;
			}
			if (ownername && ownername != document.GetProperty("ownername")) {
				xml.@ownername = ownername;
			}
			if (title && title.length) {
				xml.@title = title;
			}
			if (caption && caption.length) {
				xml.@caption = caption;
			}
			if (url && url != PicnikService.GetFileURL(ssid) || (!ss && ss != "Picnik")) {
				xml.@url = url;
			}
			if (thumbUrl && thumbUrl != PicnikService.GetFileURL(ssid, null, "thumb320") || (!ss && ss != "Picnik")) {
				xml.@thumbUrl = thumbUrl;
			}

			if (rotation != 0) {
				xml.@rotation = rotation;
			}
			return xml;
		}
		
		public function toAMF(): Object {
			// to save space, we only save fields that aren't readily calculatable or defaults
			
			var obItem:Object = {id:id, created:created, ssid:ssid, active:active};
			if (ss && ss.length > 0 && ss != "Picnik") {
				obItem.ss = ss;
			}
			if (dai >= 0) {
				obItem.dai = dai;
			}
			if (ownerid && ownerid != document.GetProperty("ownerid")) {
				obItem.ownerid = ownerid;
			}
			if (ownername && ownername != document.GetProperty("ownername")) {
				obItem.ownername = ownername;
			}
			if (title && title.length) {
				obItem.title = title;
			}
			if (caption && caption.length) {
				obItem.caption = caption;
			}
			if (url && url != PicnikService.GetFileURL(ssid) || (!ss && ss != "Picnik")) {
				obItem.url = url;
			}
			if (thumbUrl && thumbUrl != PicnikService.GetFileURL(ssid, null, "thumb320") || (!ss && ss != "Picnik")) {
				obItem.thumbUrl = thumbUrl;
			}

			if (rotation != 0) {
				obItem.rotation = rotation;
			}
			return obItem;
		}
		
		public static function fromXml( doc:GalleryDocument, xmlItem:XML ): GalleryItem {
			var item:GalleryItem = new GalleryItem();

			item.document = doc;
			item.id = xmlItem.@id;
			item.created = xmlItem.@created;

			if (xmlItem.hasOwnProperty('@ss'))
				item.ss = xmlItem.@ss;
			else
				item.ss = "Picnik";
								
			if (xmlItem.hasOwnProperty('@dai'))
				item.dai = xmlItem.@dai;
			else
				item.dai = -1;
								
			if (xmlItem.hasOwnProperty('@url'))
				item.url = xmlItem.@url;
			else if (item.dai >= 0) {
				item.url = doc.GetAssetURL(item.dai);
			}
				
			if (xmlItem.hasOwnProperty('@thumbUrl'))
				item.thumbUrl = xmlItem.@thumbUrl;
			else if (item.dai >= 0) {
				item.thumbUrl = doc.GetAssetURL(item.dai, "thumb320");
			}

			if (xmlItem.hasOwnProperty('@caption'))
				item.caption = xmlItem.@caption;
				
			if (xmlItem.hasOwnProperty('@title'))
				item.title = xmlItem.@title;
				
			if (xmlItem.hasOwnProperty('@ownerid'))
				item.ownerid = xmlItem.@ownerid;
			else
				item.ownerid = AccountMgr.GetInstance().GetUserId();
				
			if (xmlItem.hasOwnProperty('@ownername'))
				item.ownername = xmlItem.@ownername;
			else
				item.ownername = AccountMgr.GetInstance().name;

			if (xmlItem.hasOwnProperty('@rotation'))
				item.rotation = xmlItem.@rotation;
				
			if (item.dai >= 0) {				
				item.status = DocumentStatus.Static;
			} else {
				item.ssid = xmlItem.@ssid;
				item.status = DocumentStatus.Loaded;
			}		
			
			if (xmlItem.hasOwnProperty('@active'))
				item.active = xmlItem.@active;
			else
				item.active = true;

			return item;
		}

		public static function fromAMF( doc:GalleryDocument, obItem:Object ): GalleryItem {
			var item:GalleryItem = new GalleryItem();

			item.document = doc;
			item.id = obItem.id;
			item.created = obItem.created;

			if (obItem.hasOwnProperty('ss'))
				item.ss = obItem.ss;
			else
				item.ss = "Picnik";
					
			if (obItem.hasOwnProperty('@dai'))
				item.dai = obItem.dai;
			else
				item.dai = -1;
												
			if (obItem.hasOwnProperty('url'))
				item.url = obItem.url;
			else if (item.dai >= 0) {
				item.url = doc.GetAssetURL(item.dai);
			}
				
			if (obItem.hasOwnProperty('thumbUrl'))
				item.thumbUrl = obItem.thumbUrl;
			else if (item.dai >= 0) {
				item.thumbUrl = doc.GetAssetURL(item.dai, "thumb320");
			}

			if (obItem.hasOwnProperty('caption'))
				item.caption = obItem.caption;
				
			if (obItem.hasOwnProperty('title'))
				item.title = obItem.title;
				
			if (obItem.hasOwnProperty('ownerid'))
				item.ownerid = obItem.ownerid;
			else
				item.ownerid = AccountMgr.GetInstance().GetUserId();
				
			if (obItem.hasOwnProperty('ownername'))
				item.ownername = obItem.ownername;
			else
				item.ownername = AccountMgr.GetInstance().name;

			if (obItem.hasOwnProperty('rotation'))
				item.rotation = obItem.rotation;
				
			if (item.dai >= 0) {				
				item.status = DocumentStatus.Static;
			} else {
				item.ssid = obItem.ssid;
				item.status = DocumentStatus.Loaded;
			}		
			
			if (obItem.hasOwnProperty('active'))
				item.active = obItem.active;
			else
				item.active = true;

			return item;
		}
	}
}
