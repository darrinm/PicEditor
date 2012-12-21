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
package controls {
	
	import events.SlideShowAction;
	
	import flash.events.Event;
	
	import interfaces.slide.*;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.collections.CursorBookmark;
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.controls.RadioButton;
	import mx.controls.SWFLoader;
	import mx.controls.Text;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.events.DragEvent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.managers.DragManager;
	
	import overlays.*;
	
	import util.GalleryItem;
	import util.IAssetSource;
	import util.ImagePropertiesUtil;
	import util.LocUtil;
	import util.TipManager;

	public class GalleryPreviewBase extends Canvas {
		// MXML-defined variables
		[Bindable] public var _imgPreview:Image;
		[Bindable] public var _cnvPreview:Canvas;
		
		private var _itemInfo:ItemInfo;
		private var _ldrGallery:SWFLoader;
		private var _swfGallery:ISlideShowLoader = null;
		private var _nGallerySwfRetries:Number = 0;				
		private var _afnOnGalleryLoaded:Array = null;

		public function GalleryPreviewBase() {
			super();
			addEventListener( FlexEvent.INITIALIZE, OnInitialize );
		}
		
		public function Resize():void {
			OnImagePreviewResize(null);
		}
		
		public function Activate():void {
			if (_swfGallery) {
				_swfGallery.SetActive(true);
			}
		}
		
		public function Deactivate():void {
			if (_swfGallery) {
				_swfGallery.SetActive(false);
			}
		}
		
		protected function OnInitialize(evt:FlexEvent): void {
			//addEventListener(ResizeEvent.RESIZE, OnImageContainerResize);
			if (_imgPreview) _imgPreview.addEventListener(ResizeEvent.RESIZE, OnImagePreviewResize);
		}
		
		[Bindable]
		public function get itemInfo():ItemInfo {
			return _itemInfo;
		}
		
		public function set itemInfo( ii:ItemInfo ):void {
			_itemInfo = ii;
			_getGallerySwf( function( ldrSlideshow:SWFLoader, issl:ISlideShowLoader ):void {
		       		_initGallery();
				} );		
		}
		
		private function _getGallerySwf( fnOnLoaded:Function ): ISlideShowLoader {
			if (_swfGallery) {
				if (fnOnLoaded != null)
					fnOnLoaded( _ldrGallery, _swfGallery );
			} else {
				if (!_afnOnGalleryLoaded) {
					_afnOnGalleryLoaded = [fnOnLoaded];
					_loadGallerySwf();	
				} else {
					if (fnOnLoaded != null) _afnOnGalleryLoaded.push( fnOnLoaded );
				}
			}			
			return _swfGallery;			
		}
		
		private function _loadGallerySwf(): void {
			var strUrl:String = "/slide/slide.swf?refer=client.GalleryPreview";
			if (_nGallerySwfRetries > 0) {
				strUrl += "?cb=" + new Date().time;
			}
			_ldrGallery = new SWFLoader();
			_ldrGallery.percentWidth = 100;
			_ldrGallery.percentHeight = 100;
			_ldrGallery.load(strUrl );
			_ldrGallery.addEventListener(Event.COMPLETE, _onGallerySwfLoaded);			
		}
        	
        private function _onGallerySwfLoaded(evt:Event): void {        	
        	try {
        		var b:Boolean = ("getVersionStamp" in evt.target.content && evt.target.content['getVersionStamp']() != PicnikBase.getVersionStamp());
        		b = false;
        		if (b) {
        			_nGallerySwfRetries++;
        			if (_nGallerySwfRetries == 3) {
        				return;
        			}
        			_loadGallerySwf();
        			return;
        		}
	        	_swfGallery = evt.target.content as ISlideShowLoader;
	        } catch (e:Error) {
	        	// trap security errors here, in case we're loading cross-domainly
				trace("Unable to init slideshowSWF");
	        	_swfGallery = null;
	        }
	       
			// call all the callbacks that want to get a pointer to the slideshow
        	if (_afnOnGalleryLoaded) {
        		for each (var fnOnLoaded:Function in _afnOnGalleryLoaded) {
        			if (fnOnLoaded != null)
        				fnOnLoaded( _ldrGallery, _swfGallery );
        		}
        		_afnOnGalleryLoaded = null;
        	}
        }   
        		
        private function _initGallery(): void {
        	if (!_swfGallery || !itemInfo) return;
        	
        	_swfGallery.SetServerRoot(PicnikService.serverURL);
        	_swfGallery.SetUserActionOverride( function(action:SlideShowAction): Boolean { return false; } );
        	_swfGallery.SetControlVisible("share", false);
        	_swfGallery.SetControlVisible("Button_Captions", false);    	
        	_swfGallery.LoadSlideShowFromId( itemInfo.id + "_" + itemInfo.secret );
			if (_imgPreview) {				
				_imgPreview.source = null;
				_imgPreview.source = _ldrGallery.content;
				_swfGallery.Resize(_imgPreview.width, _imgPreview.height);
			}
			_swfGallery.SetActive(true);
        }	       

		private function OnImageContainerResize( evt:ResizeEvent ): void {
			// scale canvas enclosing image to have a 4/3 aspect ratio, and
			// be as large as possible but not over 600x450
			var w:Number = _cnvPreview.width;
			var h:Number = _cnvPreview.height;
			var mw:Number = Math.min(600, w);
			var mh:Number = Math.min(450, h);
			if (w < 1 || h < 1)
				return;
				
			var aspect:Number = w/h;
			if (aspect > 4.0/3.0)
				h = w * 3.0/4.0;
			else
				w = h * 4.0/3.0;

			if (w > mw) {
				var dw:Number = w / mw;
				w /= dw;
				h /= dw;
			}
			if (h > mh) {
				var dh:Number = h / mh;
				w /= dh;
				h /= dh;
			}

			_cnvPreview.maxWidth = w;
			_cnvPreview.maxHeight = h;
		}
		

		private function OnImagePreviewResize( evt:ResizeEvent ): void {
			_getGallerySwf( function( ldrSlideshow:SWFLoader, issl:ISlideShowLoader ):void {						
					if (issl && _imgPreview) {
						issl.Resize(_imgPreview.width, _imgPreview.height);
					}
				} ); 			
		}		
	}
}
