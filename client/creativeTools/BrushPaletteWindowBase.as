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
package creativeTools
{
	import containers.PaletteWindow;
	
	import controls.HSliderPlus;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import imagine.imageOperations.paintMask.CircularBrush;
	
	import mx.events.FlexEvent;
	import mx.events.SliderEvent;
	
	import util.VBitmapData;

	public class BrushPaletteWindowBase extends PaletteWindow {
		[Bindable] public var _sldrSize:HSliderPlus;
		[Bindable] public var _sldrHardness:HSliderPlus;
		[Bindable] public var _sldrStrength:HSliderPlus;
		[Bindable] public var brush:CircularBrush;
		[Bindable] public var strength:Number;
		
		private var _bmdBrush:BitmapData;
		private var _bm:Bitmap;
		
		public function BrushPaletteWindowBase() {
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}
		
		private function OnCreationComplete(evt:FlexEvent): void {
			_sldrSize.addEventListener(SliderEvent.THUMB_PRESS, OnSizeThumbPress);
			_sldrSize.addEventListener(SliderEvent.THUMB_RELEASE, OnSizeThumbRelease);
			_sldrSize.addEventListener(SliderEvent.THUMB_DRAG, OnSizeThumbPress);
			_sldrHardness.addEventListener(SliderEvent.THUMB_PRESS, OnSizeThumbPress);
			_sldrHardness.addEventListener(SliderEvent.THUMB_RELEASE, OnSizeThumbRelease);
			_sldrHardness.addEventListener(SliderEvent.THUMB_DRAG, OnSizeThumbPress);
			_sldrStrength.addEventListener(SliderEvent.THUMB_PRESS, OnSizeThumbPress);
			_sldrStrength.addEventListener(SliderEvent.THUMB_RELEASE, OnSizeThumbRelease);
			_sldrStrength.addEventListener(SliderEvent.THUMB_DRAG, OnSizeThumbPress);
		}
		
		private function OnSizeThumbPress(evt:SliderEvent): void {
			if (_bm) {
				rawChildren.removeChild(_bm);
				_bm = null;
				_bmdBrush.dispose();
			}
			brush.dispose();
			var rc:Rectangle = brush.GetDrawRect(new Point(0, 0), 0x000000);
			_bmdBrush = new VBitmapData(rc.width, rc.height, true, 0x00ffffff, "Brush Palette Preview");			
			_bm = new Bitmap(_bmdBrush);
			_bm.scaleX = PicnikBase.app.zoomView.imageView.zoom;
			_bm.scaleY = PicnikBase.app.zoomView.imageView.zoom;
			rawChildren.addChild(_bm);
			brush.DrawInto(_bmdBrush, _bmdBrush, new Point(rc.width / 2, rc.height / 2), strength, 0x000000);
			_bm.x = mouseX - (rc.width * _bm.scaleX) / 2;
			_bm.y = mouseY - (rc.height * _bm.scaleX) / 2;
			_bm.alpha = 0.75;
		}
		
		private function OnSizeThumbRelease(evt:SliderEvent): void {
			if (_bm) {
				rawChildren.removeChild(_bm);
				_bm = null;
				_bmdBrush.dispose();
			}
		}
	}
}
