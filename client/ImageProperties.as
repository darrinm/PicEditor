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
	import flash.display.Loader;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.utils.describeType;
	
	import util.metadata.ImageMetadata;
	
	/**
	 * COMMON PROPERTIES
	 * bridge:String
	 * userid
	 * title:String
	 * tags (space separated, quoted if needed to include a space)
	 * description:String
	 * sourceurl:String
	 * thumbnailURL:String
	 * webpageURL:String
	 *
	 * FLICKR PROPERTIES
	 * flickr_isfriend:Boolean
	 * flickr_ispublic:Boolean
	 * flickr_isfamily:Boolean
	 * flickr_photo_id:String
	 *
	 * WEB PROPERTIES
	 */
	/*
	public dynamic class ImageProperties extends ObjectProxy {
		public function ImageProperties(obProps:Object=null) {
			if (obProps != null) {
				for (var strProp:String in obProps)
					this[strProp] = obProps[strProp];
			}
		}
		
		public function Serialize(): XMLNode {
			var xnod:XMLNode = new XMLNode(1, "Properties");
			for (var strProp:String in this) {
				var xnodProp:XMLNode = new XMLNode(1, strProp);
				xnodProp.nodeValue = this[strProp];
				xnod.appendChild(xnodProp);
			}
			return xnod;
		}
		
		public function Deserialize(xnod:XMLNode): Boolean {
			for each (var xnodChild:XMLNode in xnod.childNodes)
				this[xnodChild.nodeName] = xnodChild.nodeValue;
			return true;
		}
	}
	*/
	
	[Bindable] // This makes every public variable of the class bindable
	public class ImageProperties {
		private static var s_xmlTypeDesc:XML;
		
		// Common (bridge-independent) properties
	 	public var serviceid:String;			// formerly 'bridge'		
//		public var userid:String;
		public var title:String;
		public var tags:String; // (space separated, quoted if needed to include a space)
		public var description:String;
		public var sourceurl:String;
		public var baseurl:String;
		public var thumbnailurl:String;
		public var mediumThumbnailURL:String;
		public var webpageurl:String;
		public var strFormat:String;   // jpg, png, gif, etc
		public var fCanLoadDirect:Boolean = false; // does this image meet the criteria to be loaded directly?
		public var width:Number;
		public var height:Number;
		public var flickr_isfriend:Boolean;
		public var flickr_ispublic:Boolean;
		public var flickr_isfamily:Boolean;
		public var flickr_photo_id:String;
		public var flickr_owner_id:String;
		public var flickr_owner_name:String;
		public var flickr_rotation:Number;
		public var last_update:Date;
		public var etag:String;
		public var history_serviceid:String;
		public var gallery_serviceid:String;
		public var smarttags:Array;
		public var species:String;
		
		public var mycomputer_file_name:String;
		public var mycomputer_file_size:Number;
		public var mycomputer_file_type:String;
		public var mycomputer_file_creator:String;
		public var mycomputer_file_creation_date:Date;
		public var mycomputer_file_modification_date:Date;

		public var facebook_profile_owner_id:String;
		
		public var filename:String;
		
		public var setid:String;			// formerly ss_setid
		public var id:String;				// formerly ss_itemid
		public var secret:String;
		
		public var invalid_image:Boolean;
		
		// An array of { segment: int, data: ByteArray } objects containing image metadata (e.g. Exif)
		public var metadata:ImageMetadata;

		private var _ldrThumbnail:Loader;
		private var _ldrMediumThumbnail:Loader;
		
// UNDONE: bridges['flickr'], etc
//		public var flickr:FlickrImageProperties;
//		public var web:WebImageProperties;
//		public var picnik:PicnikImageProperties;
//		public var mycomputer:MyComputerImageProperties;

		public function ImageProperties(strBridge:String=null, strSourceURL:String=null,
				strTitle:String=null, strDescription:String=null) {
			/*bridge*/serviceid = strBridge;
			sourceurl = strSourceURL;
			title = strTitle;
			description = strDescription;
						
			if (/*bridge*/serviceid == "web" && sourceurl && !title) {
				title = TitleFromPathOrURL(sourceurl);
			}
		}

		// Use Get/Set methods rather than getter/setter properties so property
		// iterators (e.g. CopyTo, Serialize) will not trigger the URL load.
		public function GetThumbnail(): Loader {
			if (_ldrThumbnail == null) {
				if (thumbnailurl == null)
					return null;
					
				_ldrThumbnail = new Loader();
				_ldrThumbnail.load(new URLRequest(thumbnailurl));
			}
			return _ldrThumbnail;
		}

		public function SetThumbnail(ldr:Loader): void {
			_ldrThumbnail = ldr;
		}

		// Use Get/Set methods rather than getter/setter properties so property
		// iterators (e.g. CopyTo, Serialize) will not trigger the URL load.
		public function GetMediumThumbnail(): Loader {
			if (_ldrMediumThumbnail == null) {
				if (mediumThumbnailURL == null)
					return null;
					
				_ldrMediumThumbnail = new Loader();
				_ldrMediumThumbnail.load(new URLRequest(mediumThumbnailURL));
			}
			return _ldrMediumThumbnail;
		}

		public function SetMediumThumbnail(ldr:Loader): void {
			_ldrMediumThumbnail = ldr;
		}
		
		public function SetFid(fid:String): void {
			sourceurl = PicnikService.GetFileURL(fid);
			/*ss_item*/id = fid;
			thumbnailurl = PicnikService.GetFileURL(fid, null, "thumb320");
		}

		public static function FrToImgp(fr:FileReference, fid:String=null): ImageProperties {
			var imgp:ImageProperties;
			imgp = new ImageProperties("mycomputer", null, ImageProperties.TitleFromPathOrURL(fr.name));
			if (fid != null) imgp.SetFid(fid);
			try {
				imgp.mycomputer_file_name = fr.name;
				imgp.mycomputer_file_size = fr.size;
				imgp.mycomputer_file_type = fr.type;
				imgp.mycomputer_file_creation_date = fr.creationDate;
				imgp.mycomputer_file_modification_date = fr.modificationDate;
				imgp.mycomputer_file_creator = fr.creator;
			} catch (e:Error) {
				PicnikService.Log("Ignored Client Exception: ImageProperties.FrToImgp " + e + ", " + e.getStackTrace(), PicnikService.knLogSeverityError);
			}
			return imgp;
		}
		public static function FrToIinf(fr:FileReference, fid:String=null): ItemInfo {
			var iinf:ItemInfo;
			iinf = ItemInfo.create("mycomputer", null, ImageProperties.TitleFromPathOrURL(fr.name));

			if (fid != null) iinf.SetFid(fid);
			try {
				iinf.mycomputer_file_name = fr.name;
				iinf.mycomputer_file_size = fr.size;
				iinf.mycomputer_file_type = fr.type;
				iinf.mycomputer_file_creation_date = fr.creationDate;
				iinf.mycomputer_file_modification_date = fr.modificationDate;
				iinf.mycomputer_file_creator = fr.creator;
			} catch (e:Error) {
				PicnikService.Log("Ignored Client Exception: ImageProperties.FrToImgp " + e + ", " + e.getStackTrace(), PicnikService.knLogSeverityError);
			}
			return iinf;
		}
		
		protected static function ChopPrefix(str:String, strBreakAt:String): String {
			var ichBreak:Number = str.lastIndexOf(strBreakAt);
			if (ichBreak >= 0) return str.slice(ichBreak + 1);
			else return str;
		}
		
		protected static function ChopSuffix(str:String, strBreakAt:String): String {
			var ichBreak:Number = str.lastIndexOf(strBreakAt);
			if (ichBreak >= 0) return str.substr(0, ichBreak);
			else return str;
		}
		
		public static function TitleFromPathOrURL(strFilePathOrURL:String): String {
			var strTitle:String = strFilePathOrURL;
			strTitle = ChopPrefix(strTitle, "/");
			strTitle = ChopSuffix(strTitle, "?");
			strTitle = ChopPrefix(strTitle, "\\");
			strTitle = ChopSuffix(strTitle, ".");
			if (strTitle.length == 0) strTitle = "image";
			if (strTitle.length >= 128) strTitle = strTitle.substr(0, 127);
			return strTitle;
		}

		// Apply some web smarts to follow deep links
		// Only upgrades web bridge source
		// Returns NULL if no upgrades are possible, otherwise returns an upgraded imgp
		public function GetUpgradedImgp(): ImageProperties {
			if (/*bridge*/serviceid == "web") return ImageProperties.UpgradedImgpFromURL(sourceurl);
			return null;
		}
		
		// Apply some web smarts to follow deep links
		// Returns NULL if no upgrades are possible, otherwise returns an upgraded imgp
		public static function UpgradedImgpFromURL(strURL:String): ImageProperties {
			var rxPhoto:RegExp;
			var ob:Object;
			var imgp:ImageProperties;
			var strNewURL:String;
			
			// Flickr image page
			rxPhoto = /flickr.com\/photos\/(?P<userid>[^\/]+)\/(?P<photoid>[^\/]+)/i;
			ob = rxPhoto.exec(strURL);
			if (!ob || !ob.photoid) {
				// Flickr photo link
				rxPhoto = /flickr.com\/[0-9]*\/(?P<photoid>[0-9]+)_(?P<secret>[^\.]+)/i;
				ob = rxPhoto.exec(strURL);
			}
			if (ob && ob.photoid) {
				imgp = new ImageProperties("flickr");
				imgp.flickr_photo_id = ob.photoid;
				imgp./*ss_item*/id = ob.photoid;
				// hold onto the sourceURL in case the call to flickr getItemInfo fails (eg for private photos)
				imgp.sourceurl = strURL;
				return imgp;
			}
			
			// Google
			rxPhoto = /google.com\/images\?q=[^:]*:[^:]*:(?P<photourl>.+)/i;
			ob = rxPhoto.exec(strURL);
			if (ob && ob.photourl) {
				return new ImageProperties("web", unescape(ob.photourl));
			}
			
			// Photobucket
			rxPhoto = /[is](?P<base>[0-9]+.photobucket.com\/albums\/[a-z]?[0-9]+\/.*\/)th_(?P<title>.+)/i;
			ob = rxPhoto.exec(strURL);
			if (ob && ob.base && ob.title) {
				strNewURL = "http://i" + ob.base + ob.title;
				// Make sure this isn't a video
				rxPhoto = /\/video.*\//i;
				if (!rxPhoto.exec(strURL)) {
					return new ImageProperties("web", strNewURL);
				}
			}
			
			// DeviantArt
			rxPhoto = /tn[0-9]+\-[0-9]+\.deviantart\.com\/(?P<fs>fs[0-9]+)\/[0-9]+(?P<rest>\/.*)/i;
			ob = rxPhoto.exec(strURL);
			if (!ob) {
				// Try the other kind of url
				rxPhoto = /tn[0-9]+\-[0-9]+\.deviantart\.com\/[0-9]+\/(?P<fs>fs[0-9]+).deviantart.com(?P<rest>\/.*)/i;
				ob = rxPhoto.exec(strURL);
			}

			if (ob && ob.fs && ob.rest) {
				strNewURL = "http://ic3.deviantart.com/" + ob.fs + ob.rest;
				return new ImageProperties("web", strNewURL);
			}
			
			// Imageshack
			rxPhoto = /(?P<base>http:\/\/img[0-9]+\.imageshack\.us.*\/[^\/]*)\.th(?P<ext>\.[0-9a-zA-Z]*)/i;
			ob = rxPhoto.exec(strURL);
			if (ob && ob.base && ob.ext) {
				return new ImageProperties("web", ob.base + ob.ext);
			}
			
			// MySpace
			rxPhoto = /(?P<base>http:\/\/[^\/]*\.myspacecdn\.com\/images.*\/)[a-z](?P<file>_[^\/]*)/i;
			ob = rxPhoto.exec(strURL);
			if (ob && ob.base && ob.file) {
				strNewURL = ob.base + "l" + ob.file;
				return new ImageProperties("web", strNewURL);
			}

			// Wikimedia
			rxPhoto = /(?P<base>http:\/\/upload.wikimedia.org\/wikipedia\/[^\/]+)\/thumb(?P<path>\/[^\/]+\/[^\/]+\/[^\/]+)\/[0-9]+/i;
			ob = rxPhoto.exec(strURL);
			if (ob && ob.base && ob.path) {
				strNewURL = ob.base + ob.path;
				return new ImageProperties("web", strNewURL);
			}
			
			// fotolog
			rxPhoto = /(?P<path>http:\/\/sp.*\.fotologs\.net\/photo.+_)t(?P<ext>.[^\/]+)/i;
			ob = rxPhoto.exec(strURL);
			if (ob && ob.ext && ob.path) {
				strNewURL = ob.path + "f" + ob.ext;
				return new ImageProperties("web", strNewURL);
			}
			
			// amazon
			rxPhoto = /http:\/\/(images\.|ec[0-9]+\.images-)amazon\.com\/images\/(?P<prod>P\/|G\/.*\/)(?P<pid>[^\/_]*)(?P<size>\.[^.\/]*_SC[^.\/]*)(?P<ext>\.[^\.\/]+$)/i;
			ob = rxPhoto.exec(strURL);
			if (ob && ob.ext && ob.pid) {
				strNewURL = "http://ec1.images-amazon.com/images/P/" + ob.pid + "._SCLZZZZZZZ_" + ob.ext;
				return new ImageProperties("web", strNewURL);
			}
			
			// picasa web - remove query string
			rxPhoto = /(?P<base>http:\/\/lh[0-9]+\.google\.com\/image[^?]*)?.*/i;
			ob = rxPhoto.exec(strURL);
			if (ob && ob.base) {
				strNewURL = ob.base;
				return new ImageProperties("web", strNewURL);
			}

			return null; // No upgrades
		}
	
		// Serialize all this classes public vars as elements of an ImageProperties element
		public function Serialize(): XML {
			if (s_xmlTypeDesc == null)
				s_xmlTypeDesc = describeType(this);
				
			var xml:XML = <ImageProperties/>
			for each (var xmlAccessor:XML in s_xmlTypeDesc..accessor) {
				var strName:String = xmlAccessor.@name;
				
				var obValue:* = this[strName];
				// Skip undefined properties and Number properties with a value of NaN
				if (obValue == undefined)
					continue;
				if (obValue is Number && isNaN(obValue))
					continue;
				if (Util.IsComplexType(obValue))
					continue;

				xml.appendChild(<Property name={strName} value={String(obValue)} type={xmlAccessor.@type}/>);
			}
			return xml;
		}
		
		public function Deserialize(xml:XML): Boolean {
			Util.ObFromXmlProperties(xml, this);
			return true;
		}
		
		public function CopyTo(imgp:ImageProperties): void
		{
			if (s_xmlTypeDesc == null)
				s_xmlTypeDesc = describeType(this);
				
			for each (var xmlAccessor:XML in s_xmlTypeDesc..accessor) {
				var strName:String = xmlAccessor.@name;
				if (this[strName] != undefined)
					imgp[strName] = this[strName];
			}
		}
		
		public function toString(): String {
			return "[ImageProperties]: " + sourceurl;
		}
	}
}
