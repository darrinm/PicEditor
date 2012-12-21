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
package imagine.documentObjects {
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.IOErrorEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.Dictionary;
	
	public class GalleryThumbView extends Sprite {

		private var _fnLoaded:Function = null;
		private var _dctImagesByLoaderInfo:Dictionary = null;
		private var _aImages:Array = [
						{name:"size", x:0, y:0, w: 373, h:241},
						{name:"framebg", x:0,y:0, url: PicnikService.GetAssetURL("graphics/gallery_frame_bg.png")},
						{name:"image2", x:25,y:75,r:-17,w:155,h:155,mask:true,url:null},
						{name:"image3", x:201,y:35,r:13,w:155,h:155,mask:true,url:null},
						{name:"image1", x:115,y:48,w:155,h:155,mask:true,url:null},
						{name:"frame", x:0,y:0, url: PicnikService.GetAssetURL("graphics/gallery_frame.png")} ];


		public function GalleryThumbView(): void {
		}
		
		[Bindable]
		public function set image1(s:String): void {
			var ob:Object = FindByName('image1');
			if (ob && 'url' in ob && ob['url'] != s) {
				CancelImage(ob);
				ob['url'] = s;
			}
		}	
			
		public function get image1(): String {
			var ob:Object = FindByName('image1');
			if (ob) return ob['url'];
			return null;
		}
		
		[Bindable]
		public function set image2(s:String): void {
			var ob:Object = FindByName('image2');
			if (ob && 'url' in ob && ob['url'] != s) {
				CancelImage(ob);
				ob['url'] = s;
			}
		}	
			
		public function get image2(): String {
			var ob:Object = FindByName('image2');
			if (ob) return ob['url']
			return null;
		}
		
		[Bindable]
		public function set image3(s:String): void {
			var ob:Object = FindByName('image3');
			if (ob && 'url' in ob && ob['url'] != s) {
				CancelImage(ob);
				ob['url'] = s;
			}
		}	
			
		public function get image3(): String {
			var ob:Object = FindByName('image3');
			if (ob) return ob['url']
			return null;
		}

		public function LoadImages( fnLoaded:Function ): void {
			_fnLoaded = fnLoaded;
			if (_dctImagesByLoaderInfo == null) {
				_dctImagesByLoaderInfo = new Dictionary();
				for (var i:int = 0; i < _aImages.length; i++) {
					var obImage:Object = _aImages[i];
					if (obImage['name'] == 'size') {
						var g:Graphics = graphics;							
						g.beginFill(0xffffff, 0);
						g.drawRect(obImage.x, obImage.y, obImage.w, obImage.h);			
					} else if ('url' in obImage && obImage['url'] != null && !('dob' in obImage)) {
						obImage.dob = null; // set to "loading" state
						_dctImagesByLoaderInfo[LoadImage(obImage)] = obImage;
					}
				}
			}
			CheckAllLoadsComplete();
		}		

		// Start to load an image object. Returns the loaderInfo for this load.
		private function LoadImage(obImage:Object): LoaderInfo {		
			// Load background image from external URL
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, OnLoadComplete);
			loader.contentLoaderInfo.addEventListener(
					IOErrorEvent.IO_ERROR, loader_ioErrorHandler);	
			var loaderContext:LoaderContext = new LoaderContext();
			loaderContext.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
			loaderContext.checkPolicyFile = true;
			loader.load(new URLRequest(obImage.url), loaderContext);		

			return loader.contentLoaderInfo;
		}
		
		// Start to load an image object. Returns the loaderInfo for this load.
		private function CancelImage(obImage:Object): void {
			for (var k:Object in _dctImagesByLoaderInfo) {
				if (_dctImagesByLoaderInfo[k] == obImage) {
					delete _dctImagesByLoaderInfo[k];
					if ('dob' in obImage) {
						delete obImage['dob'];
					}
				}
			}  		
		}
		
		private function CheckAllLoadsComplete(): void {
			if (null == _fnLoaded)
				return;
			
			for (var i:int = 0; i < _aImages.length;i++) {
				if ('url' in _aImages[i] && _aImages[i]['url'] != null &&
					'dob' in _aImages[i] && _aImages[i]['dob'] == null &&
					!('error' in _aImages[i])) {
					// still loading
					return;
				}
			}
			
			// we're complete (or as complete as we're going to be), so add all the images			
			for (i = 0; i < _aImages.length;i++) {
				AddImage(_aImages[i]);
			}
						
			_fnLoaded(this);
			_fnLoaded = null;
		}

		private function loader_ioErrorHandler(event:IOErrorEvent): void {
			var ldrinf:LoaderInfo = LoaderInfo(event.target);
			var obImage:Object = _dctImagesByLoaderInfo[ldrinf];
			obImage.error = event.text;
			CheckAllLoadsComplete();
		}
		
		// Called when an image loads
		// Look up the image object by loaderInfo and update the image object dob (display object)
		private function OnLoadComplete(event:Event): void {
			var ldrinf:LoaderInfo = LoaderInfo(event.target);
			
			var obImage:Object = _dctImagesByLoaderInfo[ldrinf];
			if (obImage) {
				obImage.dob = DisplayObject(ldrinf.loader);
				obImage.width = ldrinf.width;
				obImage.height = ldrinf.height;
				try {
					(obImage.dob as Bitmap).smoothing = true;
				} catch (e:Error) {
					// ignore
				}				
			}
			CheckAllLoadsComplete();
		}
		
		private function FindByName(strName:String): Object {
			for (var i:int = 0; i < _aImages.length; i++) {
				if (_aImages[i]['name'] == strName)
					return _aImages[i];
			}
			return null;
		}

		private function AddImage(obImage:Object): void {
			var dob:DisplayObject = DisplayObject(obImage.dob);
			if (dob != null) {
				dob.x = obImage.x;
				dob.y = obImage.y;

				var xOff:Number = 0;
				var yOff:Number = 0;
				
				if ('w' in obImage) {
					// scale it
					var nScale:Number = Math.max(obImage.w / dob.width, obImage.h / dob.height);
					dob.scaleX = nScale;
					dob.scaleY = nScale;
					
					xOff = (obImage.w - dob.width) / 2;
					yOff = (obImage.h - dob.height) / 2;
					dob.x += xOff;
					dob.y += yOff;
				}
				
				if ('r' in obImage) {
					// layer it
					dob.rotation = obImage['r'];					
				}
				
				addChild(obImage.dob);
				
				if ('mask' in obImage) {
					// mask it					
					var mask:Sprite = new Sprite();
					mask.graphics.beginFill(0xFF0000);
					mask.graphics.drawRect(obImage.x, obImage.y, obImage.w, obImage.h);
					if ('r' in obImage) {
						mask.rotation = obImage['r'];					
					}			
					
					// offset the mask appropriately
					if (dob.rotation != 0) {
						var mat:Matrix = new Matrix();
						mat.rotate(Util.RadFromDeg(dob.rotation));
						var ptMask:Point = mat.transformPoint(new Point(obImage.x, obImage.y));
						mask.x += obImage.x - ptMask.x;
						mask.y += obImage.y - ptMask.y;
					}
												
					addChild(mask);					
					dob.mask = mask;
				}
			}
		}
		
	}
}
