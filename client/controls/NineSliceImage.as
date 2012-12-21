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
package controls
{
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	
	public class NineSliceImage extends UIComponent
	{
		private var _ldr:Loader = new Loader();
		private var _fLoaded:Boolean = false;
		private var _fImageValid:Boolean = false;
		
		private var _nScale9Top:Number = 1;
		private var _nScale9Left:Number = 1;
		private var _nScale9Right:Number = 1;
		private var _nScale9Bottom:Number = 1;
		
		private var _aldrs:Array = [];
		private var _aspMasks:Array = [];
		
		private var _urlr:URLRequest = null;
		
		public function NineSliceImage()
		{
			super();
			_ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, OnComplete);
			addEventListener(ResizeEvent.RESIZE, OnResize);
		}
		
		public function set scale9Top(n:Number): void {
			_nScale9Top = n;
			InvalidateImage();
		}
		
		public function set scale9Left(n:Number): void {
			_nScale9Left = n;
			InvalidateImage();
		}
		
		public function set scale9Right(n:Number): void {
			_nScale9Right = n;
			InvalidateImage();
		}
		
		public function set scale9Bottom(n:Number): void {
			_nScale9Bottom = n;
			InvalidateImage();
		}
		
		private function OnResize(evt:ResizeEvent): void {
			InvalidateImage();
		}
		
		public function set source(value:Object):void {
			graphics.clear();
			_urlr = new URLRequest(String(value));
			_ldr.load(_urlr);
			InvalidateImage();
		}
		
		private function ConstructSegments(nInSize:Number, nOutSize:Number, nStartBorder:Number, nEndBorder:Number): Array {
			var aob:Array = [];
			var ob:Object;
			
			// First slice
			ob = {};
			ob.nSrc = 0;
			ob.wSrc = nStartBorder;
			ob.nDst = 0;
			ob.wDst = nStartBorder;
			aob.push(ob);
			
			// Middle slice
			ob = {};
			ob.nSrc = nStartBorder;
			ob.wSrc = nInSize - nStartBorder - nEndBorder;
			ob.nDst = nStartBorder;
			ob.wDst = nOutSize - nStartBorder - nEndBorder;
			aob.push(ob);
			
			// Last slice
			ob = {};
			ob.nSrc = nInSize - nEndBorder;
			ob.wSrc = nEndBorder;
			ob.nDst = nOutSize - nEndBorder;
			ob.wDst = nEndBorder;
			aob.push(ob);
			
			return aob;
		}
		
		private function RedrawImage(): void {
			if (_fImageValid) return;
			if (!_fLoaded) return;
			
			if (_nScale9Left < 1) throw new Error("left scale border must be >= 1");
			if (_nScale9Top < 1) throw new Error("top scale border must be >= 1");
			if (_nScale9Right < 1) throw new Error("right scale border must be >= 1");
			if (_nScale9Bottom < 1) throw new Error("bottom scale border must be >= 1");
			
			var nMiddleWidth:Number = _ldr.width - (_nScale9Left + _nScale9Right); 
			if (nMiddleWidth < 1) {
				throw new Error("image must be wider than left and right scale nine areas");
			}
			var nMiddleHeight:Number = _ldr.height - (_nScale9Top + _nScale9Bottom);
			if (nMiddleHeight < 1) {
				throw new Error("image must be taller than top and bottom scale nine areas");
			}
			
			// Now we have a bitmapdata. Draw it.
			var aobXSegs:Array = ConstructSegments(_ldr.width, width, _nScale9Left, _nScale9Right);
			var aobYSegs:Array = ConstructSegments(_ldr.height, height, _nScale9Top, _nScale9Bottom);
		
			var nRegion:Number = 0;
			for each (var obXSeg:Object in aobXSegs) {
				for each (var obYSeg:Object in aobYSegs) {
					DrawRegion(nRegion++, obXSeg, obYSeg);
				}
			}
			_fImageValid = true;
		}
		
		private function get loaders(): Array {
			InitLoaders();
			return _aldrs;
		}
		
		private function get masks(): Array {
			InitLoaders();
			return _aspMasks;
		}
		
		private function InitLoaders(): void {
			if (_aldrs.length == 0) {
				for (var i:Number = 0; i < 9; i++) {
					var ldr:Loader = new Loader();
					var spMask:Sprite = new Sprite();
					addChild(ldr);
					addChild(spMask);
					ldr.mask = spMask;
					_aldrs.push(ldr);
					_aspMasks.push(spMask);
				}
			}
		}
		
		private function DrawRegion(nRegion:Number, obXSeg:Object, obYSeg:Object): void {
			var ldr:Loader = loaders[nRegion];
			var spMask:Sprite = masks[nRegion];
			
			var rcSrc:Rectangle = new Rectangle(obXSeg.nSrc, obYSeg.nSrc, obXSeg.wSrc, obYSeg.wSrc);
			var rcDst:Rectangle = new Rectangle(obXSeg.nDst, obYSeg.nDst, obXSeg.wDst, obYSeg.wDst);
			
			spMask.graphics.clear();
			spMask.graphics.beginFill(0);
			spMask.graphics.drawRect(rcDst.x, rcDst.y, rcDst.width, rcDst.height);
			spMask.graphics.endFill();
			
			ldr.scaleX = rcDst.width / rcSrc.width;
			ldr.scaleY = rcDst.height / rcSrc.height;

			ldr.x = rcDst.x - rcSrc.x * ldr.scaleX;
			ldr.y = rcDst.y - rcSrc.y * ldr.scaleY;
		}
		
		private function OnComplete(evt:Event): void {
			_fLoaded = true;
			for each (var ldr:Loader in loaders) {
				ldr.load(_urlr);
			}
			InvalidateImage();
		}
		
		private function InvalidateImage(): void {
			_fImageValid = false;
			invalidateDisplayList();
		}
		
		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (!_fImageValid) RedrawImage();
		}
	}
}