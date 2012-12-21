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
package controls.shapeList
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	
	import mx.core.UIComponent;

	[Event(name="complete", type="flash.events.Event")]

	// This class looks like an image
	// - but it has a souce URL, an image width, and an index (0 based)
	// So, if the source image is 200x45, the width is 40 and the offset is 2,
	// the image will a 40x45 image taken from 80,0 to 120,45 
	public class ImageSlice extends UIComponent
	{
		private var _strUrl:String;
		private var _nWidth:Number;
		private var _nHeight:Number;
		private var _nOffset:Number;
		
		private var _fUrlInvalid:Boolean = false;
		private var _fPosInvalid:Boolean = false;
		private var _fSourceImageInvalid:Boolean = false;
		
		private var _fLoading:Boolean = false;
		private var _ptSized:Point = null;
		
		private var _bm:Bitmap = null;
		
		private var _sprMask:Sprite = null;
		
		private var _nCornerRadius:Number = 0;
		private var _ptMaskSize:Point = null;
		
		public function ImageSlice()
		{
			super();
			_bm = new Bitmap();
			addChild(_bm);
			
			_sprMask = new Sprite();
			addChild(_sprMask);
			mask = _sprMask;
		}
		
		public function get bitmap(): Bitmap {
			return _bm;
		}
		
		private function ParseString(str:String): Object {
			var obResult:Object = null;
			
			if (str == null) return obResult;
			try {
				var astrParts:Array = str.split('|', 4);
				obResult = {};
				obResult.width = Number(astrParts[0]);
				obResult.height = Number(astrParts[1]);
				obResult.offset = Number(astrParts[2]);
				obResult.url = astrParts[3];
				if (PicnikBase.isDesktop && obResult.url.indexOf("../") == 0)
					obResult.url = obResult.url.slice(2);
			} catch (e:Error) {
				trace("Error parsing string: " + e);
				obResult = null;
			}
			return obResult;
		}
		
		private var _strLoadError:String = null;		
		
		private function DoneLoading(): void {
			_fLoading = false;
			if (_strLoadError == null)
				dispatchEvent(new Event(Event.COMPLETE));
			else
				dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, _strLoadError));
		}
		
		// void fnDone:Function = function(obInfo:Object, strError:String): void {
		public static function LoadSlices(strUrl:String, ptSize:Point, fnDone:Function): void {
			ImageSliceLoader.GetSlice(strUrl, ptSize, 0,
				function(bmd:BitmapData, obInfo:Object, strError:String): void {
					fnDone(obInfo, strError);
				});
		}
		
		private function SetSource(obSource:Object): void {
			if (obSource == null) {
				SetSource({url:null, width:1, height:1, offset:0});
			} else {
				_fLoading = true;
				_strLoadError = null;
				_strUrl = PicnikBase.StaticSource(obSource.url) as String;
				_nWidth = obSource.width;
				_nHeight = obSource.height;
				_nOffset = obSource.offset;
				_ptSized = null;
				invalidateSize();
				invalidateDisplayList();
				if (_strUrl == null) {
					_bm.bitmapData = null;
					DoneLoading();
				} else {
					ImageSliceLoader.GetSlice(_strUrl, new Point(_nWidth, _nHeight), _nOffset,
						function(bmd:BitmapData, obInfo:Object, strError:String): void {
							// Just in case this gets called again before it returns
							if (obInfo.url != _strUrl || obInfo.offset != _nOffset) return;
							_bm.bitmapData = bmd;
							_strLoadError = strError;
							DoneLoading();
						});
				}
			}
		}

		public function set cornerRadius(n:Number): void {
			if (_nCornerRadius == n)
				return;
			_nCornerRadius = n;
			InvalidateMask();
		}
		
		private function RedrawMask(): void {
			_sprMask.graphics.clear();
			_sprMask.graphics.beginFill(0, 1);
			_sprMask.graphics.drawRoundRect(0, 0, _nWidth, _nHeight, _nCornerRadius * 2, _nCornerRadius * 2);
			_sprMask.graphics.endFill();
			_ptMaskSize = new Point(_nWidth, _nHeight);
		}
		
		private function InvalidateMask(): void {
			_ptMaskSize = null;
		}
		
		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (_ptSized == null || _ptSized.x != unscaledWidth || _ptSized.y != unscaledHeight) {
				_ptSized = new Point(unscaledWidth, unscaledHeight);
				// Relayout our bitmap
				// We have an unscaled size.
				// Scale our bitmap to fit
				_bm.width = _nWidth;
				_bm.height = _nHeight;
				
				// Scale to fit (no cropping, no distortion)
				var nScale:Number = Math.min(unscaledWidth / _nWidth, unscaledHeight / _nHeight);
				_bm.scaleX = nScale;
				_bm.scaleY = nScale;
				
				_bm.x = (unscaledWidth - (_nWidth * nScale)) / 2;
				_bm.y = (unscaledHeight - (_nHeight * nScale)) / 2;
			}
			
			if (_ptMaskSize == null || _ptMaskSize.x != _nWidth || _ptMaskSize.y != _nHeight)
				RedrawMask();
		}
		
		protected override function measure():void {
			super.measure();
			measuredHeight = _nHeight;
			measuredWidth = _nWidth;
		}
		
		public function set source(ob:Object): void {
			if (ob == null)
				SetSource(null)
			else if ('url' in ob && 'width' in ob && 'offset' in ob)
				SetSource(ob);
			else
				SetSource(ParseString(String(ob)));
		}
		
		public function get source(): Object {
			if (_strUrl == null) return null;
			return _nWidth + "|" + _nHeight + "|" + _nOffset + "|" + _strUrl;
		}
	}

}
import mx.core.Application;
import flash.display.BitmapData;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.events.Event;
import flash.net.URLRequest;
import flash.display.Loader;
import flash.geom.Point;
import flash.display.Bitmap;
import flash.geom.Rectangle;

class ImageSliceLoader {
	private static var _obLoaders:Object = {};
	
	private var _aobCallbacks:Array = [];
	private var _abmd:Array = null;
	private var _strError:String = null;
	private var _strUrl:String;
	private var _ptSliceSize:Point;
	
	private var _ldr:Loader = null;
	private var _urlr:URLRequest = null;
	private var _nRetriesRemaining:Number = 1; // Retry once
	
	public function ImageSliceLoader(strUrl:String, ptSliceSize:Point): void {
		_strUrl = strUrl;
		_ptSliceSize = ptSliceSize;
		_urlr = new URLRequest(PicnikBase.StaticUrl(_strUrl));
		_ldr = new Loader();
		_ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, OnLoadComplete);
		_ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, OnLoadError);
		_ldr.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnLoadError);
		StartLoad();
	}
	
	private function OnLoadError(evt:Event): void {
		trace("Load error: " +evt + ", retries left = " + _nRetriesRemaining);
		if (_nRetriesRemaining > 0) {
			_nRetriesRemaining -= 1;
			StartLoad();
		} else {
			_strError = "Load error: " + evt;
			DoCallbacksIfDone();
		}
	}
	
	private function OnLoadComplete(evt:Event): void {
		try {
			_abmd = [];
			var bmdAll:BitmapData = (_ldr.content as Bitmap).bitmapData;
			for (var y:Number = 0; y < bmdAll.height; y += _ptSliceSize.y) {
				for (var x:Number = 0; x < bmdAll.width; x += _ptSliceSize.x) {
					var bmdSlice:BitmapData = new BitmapData(_ptSliceSize.x, _ptSliceSize.y, true, 0);
					bmdSlice.copyPixels(bmdAll, new Rectangle(x, y, _ptSliceSize.x, _ptSliceSize.y), new Point(0,0));
					_abmd.push(bmdSlice);
				}
			}
			_ldr.unload();
		} catch (e:Error) {
			_strError = "Error parsing load results: " + e;
			_abmd = null;
		}
		DoCallbacksIfDone();
	}
	
	private function StartLoad(): void {
		_ldr.load(_urlr);
	}
	
	// var fnDone:Function = function(bmd:BitmapData, obInfo:Object, strError:String): void {
	public static function GetSlice(strUrl:String, ptSliceSize:Point, nOffset:Number, fnDone:Function): void {
		if (!(strUrl in _obLoaders)) {
			_obLoaders[strUrl] = new ImageSliceLoader(strUrl, ptSliceSize);
		}
		return ImageSliceLoader(_obLoaders[strUrl])._GetSlice(nOffset, fnDone);
	}
	
	// var fnDone:Function = function(bmd:BitmapData, obInfo:Object, strError:String): void {
	private function _GetSlice(nOffset:Number, fnDone:Function): void {
		_aobCallbacks.push({fnDone:fnDone, nOffset:nOffset});
		Application.application.callLater(DoCallbacksIfDone);
	}
	
	private function DoCallbacksIfDone(): void {
		if (_abmd != null || _strError != null) {
			while (_aobCallbacks.length > 0) {
				var obCallback:Object = _aobCallbacks.pop();
				var fnDone:Function = obCallback.fnDone;
				var nOffset:Number = obCallback.nOffset;
				
				var strError:String = _strError;
				var bmd:BitmapData = null;
				if (!strError && _abmd) {
					if (_abmd.length > nOffset)
						bmd = _abmd[nOffset];
					else	
						strError = "Index out of range. Have " + _abmd.length + " slices, requesting " + nOffset;
				}
				if (bmd == null && strError == null) strError = "unknown error";
				var obInfo:Object = {url:_strUrl, offset:nOffset, numSlices:_abmd ? _abmd.length : 0};
				obInfo.size = _ptSliceSize;
				fnDone(bmd, obInfo, strError);
			}
		}
	}
}
