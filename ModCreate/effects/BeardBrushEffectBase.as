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
	import controls.BrushSizeAndEraserButton;
	import controls.ComboBoxPlus;
	import controls.HSBColorPicker;
	import controls.HSliderFastDrag;
	
	import flash.display.Bitmap;
	import flash.display.BlendMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import imagine.imageOperations.paintMask.BeardHairBrush;
	import imagine.imageOperations.paintMask.Brush;
	import imagine.imageOperations.paintMask.CircularBrush;
	import imagine.imageOperations.paintMask.DisplayObjectBrush;
	import imagine.imageOperations.paintMask.DoodleStrokes;
	import imagine.imageOperations.paintMask.PaintMaskController;
	
	import mx.controls.CheckBox;
	import mx.events.FlexEvent;
	import mx.utils.ObjectProxy;

	public class BeardBrushEffectBase extends PaintOnEffectBase {
		[Bindable] public var doodleStrokes:DoodleStrokes;
		
		// private static const kclrDefaultColors:Array = [393216, 918530, 1115652, 1115909, 920071, 1182215, 1313289, 1248009, 1640967, 1379595, 1444874, 1444874, 1772299, 1576461, 1641996, 1576461, 1707534, 1642505, 1707789, 1969930, 1838857, 1773578, 1708559, 1839373, 10191493, 10061703, 10325125, 10849423, 11114387, 13285299];
		private var _aclrBeard:Array = null;
		[Bindable] public var swatchColors:Array = null;
		[Bindable] public var _brshbtn:BrushSizeAndEraserButton;
		[Bindable] public var _bhb:BeardHairBrush;
		[Bindable] public var _brEraser:CircularBrush;
		
		private var _fBrushValid:Boolean = false;
		
		[Bindable]
		public function set beardColors(aclr:Array): void {
			swatchColors = aclr;
			_aclrBeard = aclr;
			InvalidateBrush();
		}
		public function get beardColors(): Array {
			return _aclrBeard;
		}
		
		protected override function commitProperties():void {
			super.commitProperties();
			if (!_fBrushValid)
				ValidateBrush();
		}
		
		private function ValidateBrush(): void {
			if (_bhb == null)
				return;
			_bhb.UpdateHairSamples();
			_nBrushHardness = (_brshbtn != null && _brshbtn.eraseMode) ? 0.35 : 1;
			callLater(function(): void {
				_fBrushValid = true;
			});
		}
		
		protected function InvalidateBrush(): void {
			_fBrushValid = false;
			invalidateProperties();
		}
		
		override protected function CreateBrush(): Brush {
			return new CircularBrush(_cxyBrush, 0); // UNDONE: Add diameter
		}
		
		override protected function SliderToBrushSize(nSliderVal:Number): Number {
			return (Math.pow(1.03, nSliderVal) * 21.9)-20.9;
		}
		
		protected function BrushSizeToSlider(nBrushSize:Number): Number {
			return Math.log((nBrushSize + 20.9)/21.9)/Math.log(1.03);
		}
		
		override protected function InitController(): void {
			doodleStrokes = new DoodleStrokes();
			_mctr = new PaintMaskController(doodleStrokes);
		}
		
		public override function OnOverlayPress(evt:MouseEvent): Boolean {
			if (!_fBrushValid)
				return false;
			if (_brshbtn.eraseMode) {
				_nBrushHardness = 0.35;
				brush = _brEraser;
			} else {
				brush = _bhb;
				_mctr.extraStrokeParams = {
					autoRotate: true,
					autoRotateStartAngle: _nAutoRotateAngle
				};
			}
			return super.OnOverlayPress(evt);
		}
		
		private var _ptMousePrev:Point;
		private var _nAutoRotateAngle:Number = 0;
		
		public override function OnOverlayMouseMove(): Boolean {
			// If auto-rotate is on and the mouse is not down, reorient the brush.
			var ptNew:Point = new Point(mouseX, mouseY);
			if (_ptMousePrev != null && !_fOverlayMouseDown)
				_nAutoRotateAngle = Util.GetOrientation(_ptMousePrev, ptNew);
			_ptMousePrev = ptNew;
			return super.OnOverlayMouseMove();
		}
	}
}
