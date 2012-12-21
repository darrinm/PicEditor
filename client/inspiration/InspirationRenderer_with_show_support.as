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
package inspiration
{
	import com.adobe.utils.StringUtil;
	
	import controls.GalleryPreview;
	
	import mx.containers.Canvas;
	import mx.controls.Image;
	
	public class InspirationRenderer extends Canvas
	{
		private var _insp:Inspiration = null;
		public var _nSize:Number = 400;
		
		private var _img:Image;
		private var _gpv:GalleryPreview = null;
		private var _obSource:Object = null;
		private var _fIsShowingShow:Boolean = false;
		
		public function InspirationRenderer()
		{
			super();
		}
		
		protected override function createChildren():void {
			super.createChildren();
			_img = new Image();
			_img.percentWidth = 100;
			_img.percentHeight = 100;
			addChild(_img);
			_img.visible = false;
			
			UpdateSource();
		}
		
		private function AddGalleryPreview(item:ItemInfo): void {
			_gpv = new GalleryPreview();
			_gpv.width = width;
			_gpv.height = height;
			_gpv.itemInfo = new ItemInfo(item);
			addChild(_gpv);
			_gpv.visible = true;
			_gpv.Activate();
		}
		
		[Bindable]
		public function set inspiration(insp:Inspiration): void {
			_insp = insp;
			if (_insp == null)
				return;
			var obPhoto:Object = _insp.photos[0];
			source = GetSource();
			width = GetWidth(obPhoto);
			height = GetHeight(obPhoto);
			
		}
		
		private var _itemShow:ItemInfo = null;
		private var _strImageUrl:String = null;
		
		private function set source(ob:Object): void {
			_obSource = ob;
			UpdateSource();
		}
		
		private function UpdateSource(): void {
			if (_img == null)
				return;
			show = _obSource as ItemInfo;
			imageUrl = _obSource as String;
		}
		
		private function set show(item:ItemInfo): void {
			if (_itemShow == item)
				return;
			
			if (_gpv == null) {
				if (item != null)
					AddGalleryPreview(item);
				// else
					// GalleryPreview not yet created. Nothing to do.
			} else {
				// We have a gallery preview. Make sure we activate/deactivate and set the item info appropriately.
				if (item != null && _itemShow == null)
					_gpv.Activate();
				else if (item == null && _itemShow != null)
					_gpv.Deactivate();
	
				if (item != null) {
					_gpv.itemInfo = item;
					_gpv.width = width;
					_gpv.height = height;
				}
				_gpv.visible = item != null;
			}
			_itemShow = item;
		}
		
		private function set imageUrl(str:String): void {
			// might be null
			if (_img.source == str)
				return;
			_img.source = str;
			_img.visible = str != null;
			if (_img.visible) {
				_img.width = width;
				_img.height = height;
			}
		}
		
		private function GetSource(): Object {
			if (_insp == null)
				return null;
			var itemShow:ItemInfo = GetShowInfo();
			if (itemShow != null) {
				return itemShow;
			} else if (_insp.photos.length > 0) {
				return GetPhotoUrl(_insp.photos[0]); // First photo
			}
			return null; // default is nothing
		}
		
		private function GetShowInfo(): ItemInfo {
			if (_insp.tags == null)
				return null;
			for each (var strTag:String in _insp.tags) {
				if (StringUtil.beginsWith(strTag, 'show/id/')) {
					var astrParts:Array = strTag.substr('show/id/'.length).split('_');
					if (astrParts.length >= 2)
						return new ItemInfo({'id':astrParts[0], 'secret':astrParts[1]});
				}
			}
			return null;
		}
		
		public function get inspiration(): Inspiration {
			return _insp;
		}
						
		private function GetWidth(obPhoto:Object): Number {
			if (obPhoto.width > obPhoto.height)
				return _nSize;
			
			// Height is limiting factor (larger)
			return Math.round(_nSize * obPhoto.width / obPhoto.height);
		}
		
		private function GetHeight(obPhoto:Object): Number {
			if (obPhoto.height > obPhoto.width)
				return _nSize;
			
			// Width is limiting factor (larger)
			return Math.round(_nSize * obPhoto.height / obPhoto.width);
		}

		private function GetPhotoUrl(obPhoto:Object): String {
			if (_insp == null)
				return null;
			
			var strUrl:String = obPhoto.url;
			
			// http://lh5.ggpht.com/_sRmhDJ73ai8/TNrtOOGyACI/AAAAAAAAAC0/mQXBE4ya9sY/JollyRedNose.jpg
			// becomes
			// http://lh5.ggpht.com/_sRmhDJ73ai8/TNrtOOGyACI/AAAAAAAAAC0/mQXBE4ya9sY/s400/JollyRedNose.jpg
			var astrParts:Array = strUrl.split("/");
			var strTail:String = astrParts.pop();
			astrParts.push("s" + _nSize);
			astrParts.push(strTail);
			return astrParts.join("/");
		}
	}
}