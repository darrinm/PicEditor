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
package imagine.documentObjects
{
	/** FrameObject
	 * This is a frame.
	 * Set the layout to an array of shape params.
	 * Create a single guid for a frame in a create/undo loop (e.g. an effect).
	 * The frame uses a cache to keep track of shapes. An effect can create and dispose of
	 * a global cache list. When a frame is created, it first looks there (by name) for
	 * a cache to use. If none is found, it creates it's own (and does not add it to the cache).
	 * This way:
	 *  - A frame object created in an effect will re-use the same cache each time and so will not re-load images on small changes.
	 *  - When the effect is done, it releases the cache (but the frame object might still be holding on to it)
	 *  - Let GC clean up frame objects with un-referenced caches.
	 */
	import imagine.documentObjects.frameObjects.ClipartLoader;
	import imagine.documentObjects.frameObjects.FrameLoader;
	import imagine.documentObjects.frameObjects.FrameObjectEvent;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.filters.BitmapFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import mx.core.Application;
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	import overlays.helpers.RGBColor;
	
	import util.FilterParser;
	import util.VBitmapData;
	
	[RemoteClass]
	public class FrameObject extends DocumentObjectBase
	{
		private var _obLayout:Object = null;
		private var _frmldr:FrameLoader = null;
		private var _strLayout:String = null;
		private var _fNeedsRedraw:Boolean = false;
		private var _bm:Bitmap = null;
		private var _sprTemp:Sprite = new Sprite();
		private var _fInteractiveMode:Boolean = false;
		
		// In interactive mode, scale our output image down to this resolution
		private static const knInteractiveArea:Number = 1280 * 1024;
		
		public function FrameObject()
		{
			super();
		}
		
		override public function Dispose(): void {
			super.Dispose();
			if (_bm != null) {
				var bmd:BitmapData = _bm.bitmapData;
				_bm.bitmapData = null;
				if (bmd != null)
					bmd.dispose();
			}
			layout = null; // Make sure everything gets unloaded
		}
		
		override public function get showChildStatus(): Boolean {
			return false;
		}

		override public function get typeName(): String {
			return "Frame";
		}
		
		override public function get objectPaletteName(): String {
			return "Frame";
		}
		
		public override function get serializableProperties(): Array {
			return super.serializableProperties.concat([ "layout", "interactiveMode" ]);
		}
		
		override public function get isFixed(): Boolean {
			return true;
		}
		
		override public function hitTestPoint(x:Number, y:Number, fPixelTest:Boolean=false):Boolean {
			// If we are not asked for pixel testing and we don't hit our rectangle, return false
			if (!fPixelTest && !super.hitTestPoint(x, y, false))
				return false;
			// Otherwise, we are asking for pixel perfect or we hit our rectangle - so do a pixel perfect test.
			// This is different from the super-class in that when we ask for non-pixel perfect,
			// if we get a hit, we then go ahead and do pixel perfect. In other words, you have to
			// click on a shape inside a frame to get a hit.
			return super.hitTestPoint(x, y, true);
		}
		
		private function OnStatusChange(evt:Event=null): void {
			if (status != _frmldr.status) {
				status = _frmldr.status;
				Invalidate();
			}
		}
		
		override protected function Redraw():void {
			super.Redraw();
			if (status != DocumentStatus.Loaded)
				return;
			if (!_fNeedsRedraw)
				return;
			_fNeedsRedraw = false;
			if (parent == null)
				return;
			var strPrevQuality:String = null;
			if (!interactiveMode) {
				try {
					strPrevQuality = Application.application.systemManager.stage.quality;
					Application.application.systemManager.stage.quality = StageQuality.BEST;
				} catch (e:Error) {
					strPrevQuality = null;
					trace("Ignoring error: " + e);
				}
			}
			// First, make sure we have a bitmap
			if (_bm == null) {
				_bm = new Bitmap(null, PixelSnapping.AUTO, true);
				addChild(_bm);
			}

			// Remove any non-bitmap chidlren (remanents of old method of doing frames)
			var i:Number = 0;
			while (i < numChildren) {
				if (getChildAt(i) is Bitmap)
					i++;
				else
					removeChildAt(i);
			}
			
			// Get our area
			var obArea:Object = _obLayout.obArea;
			var rcArea:Rectangle = new Rectangle(obArea.x, obArea.y, obArea.width, obArea.height);
			
			var nScaleFactor:Number = 1;
			if (interactiveMode) {
				var nArea:Number = rcArea.width * rcArea.height;
				if (nArea > knInteractiveArea) {
					nScaleFactor = Math.sqrt(knInteractiveArea / nArea);
				}
			}
			
			var nPreviewWidth:Number = Math.round(rcArea.width * nScaleFactor);
			var nPreviewHeight:Number = Math.round(rcArea.height * nScaleFactor);

			// Next, clear our previous cache bitmap
			var bmd:BitmapData = _bm.bitmapData;
			
			// Dispose of a bitmap which is the wrong size.
			if (bmd != null && (bmd.width != nPreviewWidth || bmd.height != nPreviewHeight)) {
				_bm.bitmapData = null;
				bmd.dispose();
				bmd = null;
			}
			
			// Create a new bitmap data if we need one.
			if (bmd == null) {
				bmd = new VBitmapData(nPreviewWidth, nPreviewHeight, true, 0, 'frame cache');
				_bm.bitmapData = bmd;
			} else {
				bmd.fillRect(bmd.rect, 0);
			}

			// Our bitmap will be located at obArea.x, obArea.y. Our shapes will draw into 0, 0
			_bm.x = obArea.x;
			_bm.y = obArea.y;
			rcArea.x = 0;
			rcArea.y = 0;
			_bm.scaleX = rcArea.width / nPreviewWidth;
			_bm.scaleY = rcArea.height / nPreviewHeight;
			
			unscaledWidth = rcArea.width;
			unscaledHeight = rcArea.height;
			
			var rcPreview:Rectangle = new Rectangle(0, 0, nPreviewWidth, nPreviewHeight);
			
			// Draw our background filters, if we have any
			var afltBackground:Array = FilterParser.Parse(_obLayout.backgroundFilters, nScaleFactor);
			if (afltBackground.length > 0) {
				for each (var flt:BitmapFilter in afltBackground)
					if ('hideObject' in flt)
						flt['hideObject'] = true;
				DrawBlackRect(_sprTemp, rcPreview);
				_sprTemp.filters = afltBackground;
				VBitmapData.RepairedDraw(bmd, _sprTemp);
				ClearSprite(_sprTemp);
			}

			var bmdShapes:BitmapData = bmd;
			// Now see if we need to deal with group filters.
			var afltGroup:Array = FilterParser.Parse(_obLayout.groupFilters, nScaleFactor);
			if (afltGroup.length > 0) {
				bmdShapes = new VBitmapData(rcPreview.width, rcPreview.height, true, 0, 'frame layer temp');
			}
			
			var matOffset:Matrix = new Matrix();
			matOffset.translate(-_bm.x, -_bm.y);
			matOffset.scale(rcPreview.width / rcArea.width, rcPreview.height / rcArea.height);
			for each (var obShape:Object in _obLayout.shapes) {
				DrawShape(bmdShapes, obShape, matOffset, nScaleFactor);
			}

			if (bmdShapes == bmd) {
				// We're done
			} else {
				// Apply group filters to bmdShapes and draw them into bmd, then dispose of bmdShapes
				var bm:Bitmap = new Bitmap(bmdShapes, PixelSnapping.AUTO, true);
				_sprTemp.addChild(bm);
				_sprTemp.filters = afltGroup;
				VBitmapData.RepairedDraw(bmd, _sprTemp);
				bmdShapes.dispose();
				ClearSprite(_sprTemp);
			}
			if (strPrevQuality != null) {
				Application.application.systemManager.stage.quality = strPrevQuality;
			}
		}
		
		private function ClearSprite(spr:Sprite): void {
			spr.filters = null;
			spr.cacheAsBitmap = false;
			spr.graphics.clear();
			while (spr.numChildren > 0)
				spr.removeChildAt(spr.numChildren - 1);
		}
		
		private function DrawShape(bmd:BitmapData, obShape:Object, mat:Matrix, nScaleFactor:Number): void {
			var ldr:ClipartLoader = _frmldr.GetLoader(obShape.url);
			if (ldr.status >= DocumentStatus.Loaded) {
				var clpart:FrameClipartV2 = new FrameClipartV2();
				clpart.SetParams(ldr, obShape);
				_sprTemp.addChild(clpart);
				_sprTemp.filters = FilterParser.Parse(clpart.myFilters, nScaleFactor);
				VBitmapData.RepairedDraw(bmd, _sprTemp, mat);
				clpart.Clear();
				ClearSprite(_sprTemp);
			}
		}
		
		public function set interactiveMode(f:Boolean): void {
			if (_fInteractiveMode == f)
				return;
			_fInteractiveMode = f;
			_fNeedsRedraw = true;
			Invalidate();
		}
		
		public function get interactiveMode(): Boolean {
			return _fInteractiveMode;
		}
		
		public function SetLayout(obLayout:Object): void {
			_obLayout = obLayout;
			_fNeedsRedraw = true;
			
			// Make sure we have a frame loader
			if (_frmldr == null) {
				_frmldr = new FrameLoader();
				_frmldr.addEventListener(FrameObjectEvent.STATUS_CHANGED, OnStatusChange);
			}
			// Release previous children so we can re-use them
			_frmldr.UpdateShapes(_obLayout.shapes);
			Invalidate();
		}
		
		private function DrawBlackRect(spr:Sprite, rcArea:Rectangle): void {
			spr.graphics.clear();
			spr.graphics.beginFill(0, 1);
			spr.graphics.drawRect(rcArea.x, rcArea.y, rcArea.width, rcArea.height);
			spr.graphics.endFill();
		}		
		
		public static function LayoutObToStr(obLayout:Object): String {
			if (obLayout == null)
				return null;
			var ba:ByteArray = new ByteArray();
			ba.writeObject(obLayout);
			ba.compress();
			var enc:Base64Encoder = new Base64Encoder();
			enc.encodeBytes(ba);
			return enc.drain();
		}
		
		[Bindable]
		override public function set color(clr:uint): void {
			super.color = clr;
			transform.colorTransform = GetColorTransform(clr);
		}

		private function GetColorTransform(clr:Number): ColorTransform {
			var nR:Number = RGBColor.RedFromUint(clr);
			var nG:Number = RGBColor.GreenFromUint(clr);
			var nB:Number = RGBColor.BlueFromUint(clr);
			var nRM:Number = (255-nR)/255;
			var nGM:Number = (255-nG)/255;
			var nBM:Number = (255-nB)/255;
			
			return new ColorTransform(nRM, nGM, nBM, 1, nR, nG, nB);
		}

		public function set layout(strLayout:String): void {
			if (_strLayout == strLayout)
				return;
			_strLayout = strLayout;
			
			if (strLayout == null || strLayout.length == 0) {
				SetLayout({shapes:[], backgroundFilters:[], groupFilters:[], fMask:false, obArea:{x:0,y:0,width:0,height:0}});
			} else {
				var dec:Base64Decoder = new Base64Decoder();
				dec.decode(strLayout);
				var ba:ByteArray = dec.drain();
				ba.uncompress();
				ba.position = 0;
				SetLayout(ba.readObject());
			}
		}
		
		public function get layout(): String {
			return _strLayout;
		}
	}
}