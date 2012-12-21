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
package controls.thumbnails
{
	/** Thumbnail control
	 * This renders a nice thumbnail with rounded edges and a backtground color
	 */
	import controls.ImageEx;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;

	[Event(name="loadedStateChange", type="flash.events.Event")]

	public class Thumbnail extends UIComponent
	{
		public function Thumbnail()
		{
			super();
			cacheAsBitmap = true;
		}

		// Background colors
		private static const kclrLoaded:Number = 0xffffff;
		private static const kclrBroken:Number = 0xe5e5e5;
		private static const kclrLoading:Number = 0xe5e5e5;
		private static const kclrEmpty:Number = 0xe5e5e5;
		
		public static const EMPTY:Number = 0;
		public static const LOADING:Number = 1;
		public static const BROKEN:Number = 2;
		public static const LOADED:Number = 3;
		
		private var _fScaleUp:Boolean = false;
		private var _fShrinkToFit:Boolean = false; // if true, shrink instead of crop to fit
		private var _nCornerRadius:Number = 0;
		private var _nBottomCornerRadius:Number = NaN;
		private var _nCornerRadiusPercent:Number = 0;
		
		private var _nThumbSourceWidth:Number = 0;
		private var _nThumbSourceHeight:Number = 0;
		
		private var _fAnimating:Boolean = true;
		
		[Bindable] public var thumbnailWidth:Number = 1;
		[Bindable] public var thumbnailHeight:Number = 1;
		
		private var _strUrl:String = null;
		private var _nState:Number = EMPTY;
		
		private var _fThumbInvalid:Boolean = true;
		
		private var _img:ImageEx = null;
		private var _fBundled:Boolean = false;

		private var _fHasExplicitCornerRadius:Boolean = false;

		private var _nOldRotation:Number = 0;
		private var _nNewRotation:Number = 0;

		[Bindable]
		public function set source(strUrl:String): void {
//			if (strUrl != _strUrl) {
//				_nNewRotation = 0;
//			}
			_strUrl = strUrl;
			callLater(invalidateProperties);
		}
		
		public function isLoaded(): Boolean {
			return _nState == LOADED;
		}
		
		public function imagePos(): Rectangle {
			var nX:Number = 0;
			var nY:Number = 0;
			var nWidth:Number = 100;
			var nHeight:Number = 100;
			if (_img && _img.source) {
				try {
					nX = _img.x;
					nY = _img.y;
					nWidth = _img.width;
					nHeight = _img.height;
				} catch (e:Error) {
					// ignore errors - this means we are dragging an image without a thumbnail
				}
			}
			return new Rectangle(nX, nY, nWidth, nHeight);
		}
		
		public function set bundled(b:Boolean): void {
			_fBundled = b;
			invalidateProperties();
		}
		public function get bundled() : Boolean {
			return _fBundled;
		}

		protected override function commitProperties() : void {
			if (_img == null) {
				_img = new ImageEx();
				if (_fBundled)
					_img.bundled = true;
				addChild(_img);
				_img.addEventListener(Event.COMPLETE, OnImageComplete);
				_img.addEventListener(IOErrorEvent.IO_ERROR , OnImageError);
				_img.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnImageError);
				_img.x = 0;
				_img.y = 0;
				_img.width = width;
				_img.height = height;
			}
			_img.source = _strUrl;
//			_img.load(_strUrl);
			state = LOADING;

			super.commitProperties();
		}
		
		public function get source(): String {
			return _strUrl;
		}

		private function OnImageComplete(evt:Event): void {
			state = LOADED;
			_nThumbSourceWidth = isNaN(_img.contentWidth) ? _img.width : _img.contentWidth;
			_nThumbSourceHeight = isNaN(_img.contentHeight) ? _img.height : _img.contentHeight;
			InvalidateThumb();

			try {
				evt.target.content.smoothing = true;
			} catch (err:Error) {
			}
			
			UpdateAnimating();
		}
		
		public function set animating(f:Boolean): void {
			if (_fAnimating == f)
				return;
			_fAnimating = f;
			UpdateAnimating();
		}
		
		public function get animating(): Boolean {
			return _fAnimating;
		}
		
		private function UpdateAnimating(): void {
			if (!isLoaded()) return;
			if (_img.parent == null && _fAnimating)
				addChild(_img);
			else if (_img.parent != null && !_fAnimating)
				removeChild(_img);
		}
		
		private function OnImageError(evt:Event): void {
			state = BROKEN;
			trace("Load error: " + evt);
		}
		
		[Bindable]
		public function set state(n:Number): void {
			if (_nState != n) {
				_nState = n;
				InvalidateThumb();
				dispatchEvent(new Event("loadedStateChange"));
			}
		}
		
		public function get state(): Number {
			return _nState;
		}
		
		[Bindable]
		public function set scaleUp(f:Boolean): void {
			if (_fScaleUp != f) {
				_fScaleUp = f;
				InvalidateThumb();
			}
		}
		
		public function get scaleUp(): Boolean {
			return _fScaleUp;
		}
		
		[Bindable]
		public function set shrinkToFit(f:Boolean): void {
			if (_fShrinkToFit != f) {
				_fShrinkToFit = f;
				InvalidateThumb();
			}
		}
		
		public function get shrinkToFit(): Boolean {
			return _fShrinkToFit;
		}
		
		

		[Bindable]		
		public function set cornerRadiusPercent(n:Number): void {
			if (_nCornerRadiusPercent != n || _fHasExplicitCornerRadius) {
				_nCornerRadiusPercent = n;
				_fHasExplicitCornerRadius = false;
				InvalidateThumb();
			}
		}
		
		public function get cornerRadiusPercent(): Number {
			return _nCornerRadiusPercent;
		}
		
		[Bindable]
	    [PercentProxy("cornerRadiusPercent")]
		public function set cornerRadius(n:Number): void {
			if (_nCornerRadius != n || !_fHasExplicitCornerRadius) {
				_nCornerRadius = n;
				_fHasExplicitCornerRadius = true;
				InvalidateThumb();
			}
		}
		
		public function get cornerRadius(): Number {
			return _nCornerRadius;
		}
		
		[Bindable]		
		public function set bottomCornerRadius(n:Number): void {
			if (_nBottomCornerRadius != n) {
				_nBottomCornerRadius = n;
				InvalidateThumb();
			}
		}
		
		public function get bottomCornerRadius(): Number {
			return _nBottomCornerRadius;
		}
		
		private function get bottomCornerRadiusForSize(): Number {
			if (isNaN(_nBottomCornerRadius)) return topCornerRadiusForSize;
			return _nBottomCornerRadius;
		}
		
		private function get topCornerRadiusForSize(): Number {
			var n:Number = 0;
			if (_fHasExplicitCornerRadius) n = 2 * _nCornerRadius;
			else {
				n = 2 * _nCornerRadiusPercent * Math.min(width, height) / 100;
			}
			n = Math.max(0, n);
			n = Math.min(n, width, height);
			return n / 2;
		}
	
		// UNDONE: image rotation is not yet working properly.	
		public function get imageRotation(): Number {
			return _nOldRotation;	
		}
		
		public function set imageRotation(n:Number): void {
			_nNewRotation = n;
			RedrawThumb();
		}
		
		private function InvalidateThumb(): void {
			_fThumbInvalid = true;
			invalidateDisplayList();
		}
		
		private function ValidateThumb(): void {
			if (_fThumbInvalid)
				RedrawThumb();
		}
		
		private function GetColorForState(): Number {
			if (state == LOADED) return kclrLoaded;
			if (state == BROKEN) return kclrBroken;
			if (state == LOADING) return kclrLoading;
			if (state == EMPTY) return kclrEmpty;
			return kclrBroken;
		}
		
		private var _sprMask:Sprite = null;
		
		private function DrawShape(gr:Graphics): void {
			gr.drawRoundRectComplex(0, 0, width, height,
					topCornerRadiusForSize, topCornerRadiusForSize,
					bottomCornerRadiusForSize, bottomCornerRadiusForSize);
		}
		
		private function RedrawThumb(): void {
			if (_sprMask == null) {
				_sprMask = new Sprite();
				_sprMask.cacheAsBitmap = true;
				//this.mask = _sprMask;
			}
			graphics.clear();
			if (state == Thumbnail.LOADED) {
				// Draw the bitmap
				// Do some work to set up a bitmap fill
				
				// We have scale up and shrink to fit to take into consideration.
				var rcDraw:Rectangle = new Rectangle(0,0,width,height);
				
				var fFillsSpace:Boolean = true;
				if (!scaleUp) {
					if (shrinkToFit) {
						fFillsSpace = (_nThumbSourceWidth / _nThumbSourceHeight) == (width / height);
					} else {
						fFillsSpace = _nThumbSourceWidth >= width && _nThumbSourceHeight >= height;
					}
				}
				
				if (!fFillsSpace) {
					graphics.beginFill(GetColorForState());
					DrawShape(graphics);
					graphics.endFill();
				}
				_sprMask.graphics.clear();
				_sprMask.graphics.beginFill(0xffffff);
				DrawShape(_sprMask.graphics);
				_sprMask.graphics.endFill();
				_img.mask = _sprMask;
				_img.cacheAsBitmap = true;
				
				var nScale:Number;
				// Now calculate these for our bitmap and constraints.
				var fnSelect:Function = shrinkToFit ? Math.min : Math.max;
				nScale = fnSelect(width/_nThumbSourceWidth, height/_nThumbSourceHeight);
				if (!scaleUp) nScale = Math.min(1, nScale);

				var rcOffScreenThumb:Rectangle = new Rectangle(0, 0, _nThumbSourceWidth * nScale, _nThumbSourceHeight * nScale);
				
				var xOff:Number;
				var yOff:Number;
				
				// At this point, our bitmap is at 0,0 and has a width of nScale * _bmd.width
				// Center it
				rcOffScreenThumb.x = Math.round((width - rcOffScreenThumb.width)/2);
				rcOffScreenThumb.y = Math.round((height - rcOffScreenThumb.height)/2);

				_sprMask.x = Math.max(0,-rcOffScreenThumb.x);
				_sprMask.y = Math.max(0,-rcOffScreenThumb.y);
				
				_img.x = rcOffScreenThumb.x;
				_img.y = rcOffScreenThumb.y;
				_img.width = rcOffScreenThumb.width;
				_img.height = rcOffScreenThumb.height;

				if (_nNewRotation != _nOldRotation) {
					var x1:Number = (this.width/2);
					var y1:Number = (this.height/2);
					//trace("Thumbnail.RedrawThumb(): " + x1 + "/" + y1 + ", " + _nOldRotation + " -> " + _nNewRotation);
					//trace(" _img: " + _img.x + "/" + _img.y + ", "  + _img.width + "/" + _img.height);
					var rN:Number = _nNewRotation * Math.PI / 180.0;
					var rO:Number = _nOldRotation* Math.PI / 180.0;
	
					var tmat:Matrix = this.transform.matrix;
					tmat.translate(-x1, -y1);
					tmat.rotate(-rO);
					tmat.rotate( rN);
					tmat.translate( x1,  y1);
					this.transform.matrix = tmat;


					_nOldRotation = _nNewRotation;
				}
				
			} else {
				var mat:Matrix = new Matrix();
				mat.createGradientBox(width, height * .75, 0, 0);
				mat.rotate(Math.PI/2);
				graphics.beginGradientFill(GradientType.LINEAR, [GetColorForState(), 0xffffff], [1,1], [0,255], mat, SpreadMethod.PAD);
				DrawShape(graphics);
				graphics.endFill();
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			ValidateThumb();
		}
	}
}
