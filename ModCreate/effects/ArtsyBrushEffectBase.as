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
	import controls.ComboBoxPlus;
	import controls.HSBColorPicker;
	import controls.HSliderFastDrag;
	
	import flash.display.Bitmap;
	import flash.display.BlendMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import imagine.imageOperations.paintMask.Brush;
	import imagine.imageOperations.paintMask.DisplayObjectBrush;
	import imagine.imageOperations.paintMask.DoodleStrokes;
	import imagine.imageOperations.paintMask.PaintMaskController;
	
	import mx.controls.CheckBox;
	import mx.events.FlexEvent;
	import mx.utils.ObjectProxy;

	public class ArtsyBrushEffectBase extends PaintOnEffectBase {
		[Bindable] public var _cpkrBrush:HSBColorPicker;
		[Bindable] public var doodleStrokes:DoodleStrokes;
		[Bindable] public var _cbBlendMode:ComboBoxPlus;
		[Bindable] public var _cboxBrushes:ComboBoxPlus;
		[Bindable] public var _chkbAirbrush:CheckBox;
		[Bindable] public var _chkbAutoRotate:CheckBox;
		[Bindable] public var _sldrRotation:HSliderFastDrag;
		
		private var _aobBrushes:Array = null;
		
		override protected function OnAllStagesCreated(): void {
			super.OnAllStagesCreated();
			_chkbAutoRotate.addEventListener(Event.CHANGE, OnAutoRotateChange);
		}
		
   		protected function GetBrushes(astrBrushes:Array): Array {
   			if (_aobBrushes == null) {
   				// ArtsyBrushEffect doesn't need brushes fully initialized
	   			DisplayObjectBrush.Init(function (err:Number, strError:String): void {});
	   			
	   			_aobBrushes = [];
	   			for (var i:int = 0; i < astrBrushes.length; i++) {
	   				var strBrushId:String = astrBrushes[i];
	   				var cls:Class = DisplayObjectBrush.GetBrushClass(strBrushId);
	   				var ob:Object = new cls();
	   				// For some reason ImageEx doesn't like to be given Bitmaps. It does OK when it creates
	   				// the Bitmaps itself from their class though.
	   				if (ob is Bitmap)
	   					ob = cls;
	   				_aobBrushes.push(new ObjectProxy({ label: Resource.getString("ArtsyBrushEffect", strBrushId),
	   						icon: ob, data: strBrushId }));
	   			}
	   		}
			return _aobBrushes;
		}

		protected function SelectBrush(obItem:Object): void {
			if (obItem) {
				brush = CreateBrush();
			} else {
				_cboxBrushes.selectedIndex = 0;
			}
		}
		
		override protected function CreateBrush(): Brush {
			return new DisplayObjectBrush(100, 0.5, _cboxBrushes && _cboxBrushes.selectedItem ? _cboxBrushes.selectedItem.data : "picnik_logo");
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
		
		private function OnAutoRotateChange(evt:Event): void {
			if (!_chkbAutoRotate.selected)
				_nAutoRotateAngle = 0.0;
		}
		
		public override function OnOverlayPress(evt:MouseEvent): Boolean {
/*			
			if (_tmrAirbrush == null) {
				_tmrAirbrush = new Timer(100);
				_tmrAirbrush.addEventListener(TimerEvent.TIMER, OnAirbrushTimer);
			}
			if (_chkbAirbrush.selected)
				_tmrAirbrush.start();
*/			
			_nBrushHardness = 1;
			_mctr.extraStrokeParams = {
				color: _cpkrBrush.selectedColor, blendmode: _cbBlendMode.value, autoRotate: _chkbAutoRotate.selected,
				autoRotateStartAngle: _nAutoRotateAngle + brushRotation
			}
			return super.OnOverlayPress(evt);
		}
		
		private var _aptDeltaHistory:Array = [];
		private var _ptMousePrev:Point;
		private var _nAutoRotateAngle:Number;
		
		public override function OnOverlayMouseMove(): Boolean {
			// If auto-rotate is on and the mouse is not down, reorient the brush.
			var ptNew:Point = new Point(mouseX, mouseY);
			if (_chkbAutoRotate.selected && !_fOverlayMouseDown && _ptMousePrev) {
				var ptDelta:Point = ptNew.subtract(_ptMousePrev);
				_aptDeltaHistory.push(ptDelta);
				ptDelta = new Point();
				for each (var pt:Point in _aptDeltaHistory)
					ptDelta = ptDelta.add(pt);
				_nAutoRotateAngle = Util.GetOrientation(new Point(), ptDelta);
				if (_aptDeltaHistory.length > 10)
					_aptDeltaHistory.shift();
			}
			_ptMousePrev = ptNew;
			return super.OnOverlayMouseMove();
		}
		
/*
		private var _tmrAirbrush:Timer;

		public override function OnOverlayRelease():Boolean {
			_tmrAirbrush.stop();
			return super.OnOverlayRelease();
		}

		private function OnAirbrushTimer(evt:TimerEvent): void {
			_mctr.FinishDrag();
			_mctr.StartDrag(overlayMouseAsPtd);
		}
*/

		private var _bmPreview:Bitmap;

		override public function UpdateOverlay(): void {
			if (!_mcOverlay)
				return;
			
			_mcOverlay.graphics.clear();
			if (_mcOverlay.numChildren > 0)
				_mcOverlay.removeChildAt(0);
			
			if (!brushActive || _fOverlayMouseDown)
				return;
				
			// These are in document coordinates
			var ptd:Point = overlayMouseAsPtd;
			ptd.x = Math.round(ptd.x);
			ptd.y = Math.round(ptd.y);
			if (isNaN(ptd.x) || isNaN(ptd.y))
				return;

			var ptv:Point = _imgv.PtvFromPtd(ptd);
			if (_bmPreview != null)
				_bmPreview.bitmapData.dispose();
				
			var strBlendMode:String = _cbBlendMode.value as String;
			var co:uint = strBlendMode != "impression" ? _cpkrBrush.selectedColor : 0x000000;
			_bmPreview = CreateBrushPreview(co, brushAlpha, _nAutoRotateAngle + brushRotation).bm;
			_bmPreview.blendMode = strBlendMode != "impression" ? strBlendMode : BlendMode.NORMAL;
			
			// UNDONE: integerize this coord in such a way as it will exactly match what will be drawn in the doc
			_bmPreview.x = ptv.x - (_bmPreview.width / 2);
			_bmPreview.y = ptv.y - (_bmPreview.height / 2);
			_mcOverlay.addChild(_bmPreview);
		}
	}
}
