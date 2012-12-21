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
package effects {
	import containers.DrawOverlayEffectCanvas;
	import flash.geom.Point;
	import controls.HSBColorPicker;
	import controls.HSliderPlus;
	import flash.display.Graphics;
	import imagine.imageOperations.PaintImageMask;
	import flash.geom.Rectangle;
	import mx.controls.RadioButton;
	import flash.events.MouseEvent;

	public class PaintEffectBase extends DrawOverlayEffectCanvas {
		[Bindable] public var _cpkrBrush:HSBColorPicker;
		[Bindable] public var _sldrBrushSize:HSliderPlus;
		[Bindable] public var _sldrStrength:HSliderPlus;
		[Bindable] public var _msk:PaintImageMask;
		[Bindable] public var _rbtnPaint:RadioButton;
		
		public override function OnOverlayPress(evt:MouseEvent): Boolean {
			super.OnOverlayPress(evt);
			var iptLast:Number = _aapt.length - 1;
			_aapt[iptLast].nStrength = Math.round(_sldrStrength.value);
			_aapt[iptLast].nWidth = Math.round(_sldrBrushSize.value);
			_aapt[iptLast].fPaint = _rbtnPaint.selected;  //Paint/erase
			_msk['lines'] = _aapt;
			OnOpChange();
			return true;
		}
		
		// This says "Drag", but it is called on "Move"
		public override function OnOverlayMouseDrag(): Boolean {
			super.OnOverlayMouseDrag();
			_msk['lines'] = _aapt;
			OnOpChange();
			return true;
		}

		public override function OnOverlayRelease():Boolean {
			super.OnOverlayRelease();
			var iptLast:Number = _aapt.length - 1;
			_aapt[iptLast].nStrength = Math.round(_sldrStrength.value);
			_aapt[iptLast].nWidth = Math.round(_sldrBrushSize.value);
			_msk['lines'] = _aapt;
			OnOpChange();
			return true;
		}
	}
}
