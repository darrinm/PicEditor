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
package
{
	import util.BindableDynamicObject;

	[Bindable("propertyChange")]
	dynamic public class ItemInfo extends BindableDynamicObject
	{
		public function ItemInfo(obProps:Object=null) {
			super(obProps);
		}
		
		public static function create(strServiceId:String=null, strSourceURL:String=null,
				strTitle:String=null, strDescription:String=null): ItemInfo
		{
			var itemInfo:ItemInfo = new ItemInfo();
			itemInfo.serviceid = strServiceId;
			itemInfo.sourceurl = strSourceURL;
			itemInfo.title = strTitle;
			itemInfo.description = strDescription;
						
			if (itemInfo.serviceid == "web" && itemInfo.sourceurl && !itemInfo.title) {
				itemInfo.title = ImageProperties.TitleFromPathOrURL(itemInfo.sourceurl);
			}
			return itemInfo;
		}

		protected override function dictionaryAlias(name:*): *
		{
			if (this.getProperty_raw('serviceid') == 'flickr') {
		    	if (name == 'flickr_photo_id')
		    		name = 'id';
	    		else if (name == 'flickr_owner_id')
	    			name = 'ownerid';
	    		else if (name == 'flickr_owner_name')
	    			name = 'ownername';
	  		} else if (this.getProperty_raw('serviceid') == 'mycomputer') {
	  			if (name == 'mycomputer_file_modification_date')
	  				name = 'last_update';
	  			else if (name == 'mycomputer_file_name')
	  				name = 'filename';
	  		}
			return name;		
		}
		
		public function asImageProperties(): ImageProperties {
			
			// Capture as many image properties as we have available
			var imgp:ImageProperties = new ImageProperties(this.serviceid,
					this.sourceurl, this.title, this.description);
			imgp.thumbnailurl = this.thumbnailurl;
			imgp./*ss_*/setid = this.setid;
			imgp./*ss_item*/id = this.id;
			if (this.secret)
				imgp.secret = this.secret;
			imgp.webpageurl = this.webpageurl;
			if (this.baseurl)
				imgp.baseurl = this.baseurl;
			if (this.sourceurl)
				imgp.sourceurl = this.sourceurl;
			if (this.last_update)
				imgp.last_update = new Date(this.last_update);
			
			if (this.tags)
				imgp.tags = this.tags;
			if (this.filename)
				imgp.filename = this.filename;
			if (this.etag)
				imgp.etag = this.etag;
			if (this.history_serviceid)
				imgp.history_serviceid = this.history_serviceid;
			if (this.gallery_serviceid)
				imgp.gallery_serviceid = this.gallery_serviceid;
			if (this.invalid_image)
				imgp.invalid_image = this.invalid_image;
			if (this.smarttags) {
				if (this.smarttags is Array)
					imgp.smarttags = this.smarttags;
				// UNDONE: handle smartags conversion to/from text
			}
			if (this.species)
				imgp.species = this.species;
			if (this.metadata)
				imgp.metadata = this.metadata;
				
			if (this.serviceid == "flickr") {
				imgp.flickr_photo_id = this.id;
				imgp.flickr_owner_id = this.ownerid;
				imgp.flickr_owner_name = this.ownername;
				imgp.flickr_ispublic = this.flickr_ispublic;
				imgp.flickr_isfriend = this.flickr_isfriend;
				imgp.flickr_isfamily = this.flickr_isfamily;
				imgp.flickr_rotation = this.flickr_rotation;
				
				// move these to the general case when we support direct uploading from other sites
				imgp.fCanLoadDirect = this.fCanLoadDirect;
				imgp.height = this.height;
				imgp.width = this.width;
				imgp.strFormat = this.strFormat;
			}
			
			return imgp;
		}

		public static function FromImageProperties(imgp:ImageProperties): ItemInfo {
			if (imgp == null)
				return null;
				
			var itemInfo:ItemInfo = ItemInfo.create(imgp./*bridge*/serviceid, imgp.sourceurl, imgp.title, imgp.description);
//			var itemInfo:ItemInfo = new ItemInfo();
			
			itemInfo.id = imgp./*ss_item*/id;
			itemInfo.secret = imgp.secret;
			itemInfo.setid = imgp./*ss_*/setid;
//			itemInfo.serviceid = imgp./*bridge*/serviceid;
//			itemInfo.sourceurl = imgp.sourceurl;
			itemInfo.thumbnailurl = imgp.thumbnailurl;
			itemInfo.webpageurl = imgp.webpageurl;
			itemInfo.filename = imgp.filename;
//			itemInfo.title = imgp.title;
//			itemInfo.description = imgp.description;
			itemInfo.tags = imgp.tags;
			itemInfo.width = imgp.width;
			itemInfo.height = imgp.height;
			itemInfo.etag = imgp.etag;
			itemInfo.history_serviceid = imgp.history_serviceid;
			itemInfo.smarttags = imgp.smarttags;
			itemInfo.species = imgp.species;

			if (imgp.last_update)
				itemInfo.last_update = imgp.last_update.getTime();
			if (imgp.invalid_image)
				itemInfo.invalid_image = imgp.invalid_image;
			if (imgp.metadata)
				itemInfo.metadata = imgp.metadata;
			
			switch (imgp./*bridge*/serviceid) {
			case "flickr":
				itemInfo.id = imgp.flickr_photo_id; // overrides imgp.ss_itemid
				itemInfo.ownerid = imgp.flickr_owner_id;
				itemInfo.ownername = imgp.flickr_owner_name;
				itemInfo.flickr_ispublic = imgp.flickr_ispublic;
				itemInfo.flickr_isfriend = imgp.flickr_isfriend;
				itemInfo.flickr_isfamily = imgp.flickr_isfamily;
				itemInfo.flickr_rotation = imgp.flickr_rotation;
				break;
				
			case "mycomputer":
				if (imgp.mycomputer_file_modification_date)
					itemInfo.last_update = imgp.mycomputer_file_modification_date.getTime();
				itemInfo.filename = imgp.mycomputer_file_name;
				break;
			
			case "PAS":
				break;
			}
			
			return itemInfo;
		}

		public function SetFid(fid:String): void {
			this.sourceurl = PicnikService.GetFileURL(fid);
			this./*ss_item*/id = fid;
			this.thumbnailurl = PicnikService.GetFileURL(fid, null, "thumb320");
		}
    }
}
