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
	import containers.NestedControlCanvasBase;
	
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import imagine.imageOperations.ISimpleOperation;
	import imagine.imageOperations.OffsetImageOperation;
	import imagine.imageOperations.paintMask.OperationStrokes;
	import imagine.imageOperations.paintMask.PaintMaskController;
	
	import util.DashedLine;

	public class CloneEffectBase extends PaintOnEffectBase {
		[Bindable] public var opStrokes:OperationStrokes;
		[Bindable] public var eraseMode:Boolean = false;
		[Bindable] public var anchorMode:Boolean = false;
		
		private var _xOffset:Number = 0;
		private var _yOffset:Number = 0;
		private var _ptdCloneFrom:Point = null;
		private var _fModKey:Boolean = false;

		override protected function SliderToBrushSize(nSliderVal:Number): Number {
			return (Math.pow(1.03, nSliderVal) * 21.9)-20.9;
		}
		
		public function CloneEffectBase(): void {
			addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
			addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown, true);
			addEventListener(KeyboardEvent.KEY_UP, OnKeyUp);
			addEventListener(KeyboardEvent.KEY_UP, OnKeyUp, true);
		}
		
		private function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.ctrlKey && !anchorMode) {
				eraseMode = false;
				anchorMode = true;
				UpdateOverlay();
			}
		}
		
		override public function Select(efcnvCleanup:NestedControlCanvasBase): Boolean {
			var fSelected:Boolean = super.Select(efcnvCleanup);
			if (fSelected) {
				_xOffset = 0;
				_yOffset = 0;
				_ptdCloneFrom = null;
				anchorMode = true;
				eraseMode = false;
				stage.addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
				stage.addEventListener(KeyboardEvent.KEY_UP, OnKeyUp);
			}
			return fSelected;
		}
		
		override public function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null):void {
			super.Deselect(fForceRollOutEffect, efcvsNew);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
			stage.removeEventListener(KeyboardEvent.KEY_UP, OnKeyUp);
		}

		private function OnKeyUp(evt:KeyboardEvent): void {
			if (anchorMode && (hasOffset || _ptdCloneFrom)) {
				anchorMode = false;
				UpdateOverlay();
			}
		}
		
		private function get hasOffset(): Boolean {
			return _xOffset != 0 || _yOffset != 0;
		}
		
		protected function BrushSizeToSlider(nBrushSize:Number): Number {
			return Math.log((nBrushSize + 20.9)/21.9)/Math.log(1.03);
		}
		
		override protected function InitController(): void {
			opStrokes = new OperationStrokes();
			_mctr = new PaintMaskController(opStrokes);
		}
		
		private function get currentOp(): ISimpleOperation {
			return new OffsetImageOperation(_xOffset, _yOffset);
		}

		public override function OnOverlayPress(evt:MouseEvent): Boolean {
			_fModKey = evt.ctrlKey;
			return super.OnOverlayPress(evt);
		}
		
		public override function OnOverlayRelease():Boolean {
			anchorMode = false;
			return super.OnOverlayRelease();
		}

		protected override function ContinueDrag(ptd:Point):void {
			if (anchorMode) {
				_ptdCloneFrom = ptd.clone();
			} else {
				super.ContinueDrag(ptd);
			}
		}

		override public function UpdateOverlay(): void {
			if (!_mcOverlay)
				return;

			if (anchorMode) {
				_mcOverlay.graphics.clear();
			} else {
				super.UpdateOverlay();
				if (eraseMode) return;
			}
			
			// These are in document coordinates
			var ptd:Point = _ptdCloneFrom;
			if (ptd == null && hasOffset) {
				ptd = overlayMouseAsPtd;
				ptd.x += _xOffset;
				ptd.y += _yOffset;
			}
			if (anchorMode) {
				ptd = overlayMouseAsPtd;
			}
			
			if (ptd == null || isNaN(ptd.x) || isNaN(ptd.y)) return;
			ptd.x = Math.round(ptd.x);
			ptd.y = Math.round(ptd.y);
			
			var rcd:Rectangle = new Rectangle(ptd.x - (_cxyBrush / 2), ptd.y - (_cxyBrush / 2), _cxyBrush, _cxyBrush);
			var rcl:Rectangle = _imgv.RclFromRcd(rcd);
			
			var ptv:Point = _imgv.PtvFromPtd(ptd);

			const knBarOut:Number = 4;
			const knBarIn:Number = 0;
			const knCrossSize:Number = 4;
			const knShadowAlpha:Number = 0.35;
			var clr:Number = anchorMode ? 0xffffff : 0xbbe57f;
			var dl:DashedLine;
			
			// Draw cursor's shadow
			var nShOff:Number = 1;
			dl = new DashedLine(_mcOverlay, 5, 5);
			dl.lineStyle(1, 0, knShadowAlpha);
			dl.ellipse(rcl.left + nShOff, rcl.top + nShOff, rcl.width, rcl.height);
			
			_mcOverlay.graphics.lineStyle(1, 0x000000, knShadowAlpha, false);
			//_mcOverlay.graphics.drawEllipse(rcl.x + nShOff, rcl.y + nShOff, rcl.width, rcl.height);
			
			// top bar
			_mcOverlay.graphics.moveTo(ptv.x + nShOff, rcl.top - knBarOut + nShOff);
			_mcOverlay.graphics.lineTo(ptv.x + nShOff, rcl.top + knBarIn + nShOff);
			
			// bottom bar
			_mcOverlay.graphics.moveTo(ptv.x + nShOff, rcl.bottom - knBarIn + nShOff);
			_mcOverlay.graphics.lineTo(ptv.x + nShOff, rcl.bottom + knBarOut + nShOff);
			
			// left bar
			_mcOverlay.graphics.moveTo(rcl.left + nShOff - knBarOut, ptv.y + nShOff);
			_mcOverlay.graphics.lineTo(rcl.left + nShOff + knBarIn, ptv.y + nShOff);
			
			// right bar
			_mcOverlay.graphics.moveTo(rcl.right + nShOff - knBarIn, ptv.y + nShOff);
			_mcOverlay.graphics.lineTo(rcl.right + nShOff + knBarOut, ptv.y + nShOff);
			
			// horizontal crossbar
			_mcOverlay.graphics.moveTo(ptv.x + nShOff - knCrossSize, ptv.y + nShOff);
			_mcOverlay.graphics.lineTo(ptv.x + nShOff + knCrossSize, ptv.y + nShOff);
			
			// vertical crossbar
			_mcOverlay.graphics.moveTo(ptv.x + nShOff, ptv.y + nShOff - knCrossSize);
			_mcOverlay.graphics.lineTo(ptv.x + nShOff, ptv.y + nShOff + knCrossSize);
			
			// Draw cursor
			nShOff = 0;
			dl = new DashedLine(_mcOverlay, 5, 5);
			dl.lineStyle(1, clr, 1);
			dl.ellipse(rcl.left + nShOff, rcl.top + nShOff, rcl.width, rcl.height);
			_mcOverlay.graphics.lineStyle(1, clr, 1.0, false);
			// _mcOverlay.graphics.drawEllipse(rcl.x + nShOff, rcl.y + nShOff, rcl.width, rcl.height);

			// top bar
			_mcOverlay.graphics.moveTo(ptv.x + nShOff, rcl.top - knBarOut + nShOff);
			_mcOverlay.graphics.lineTo(ptv.x + nShOff, rcl.top + knBarIn + nShOff);
			
			// bottom bar
			_mcOverlay.graphics.moveTo(ptv.x + nShOff, rcl.bottom - knBarIn + nShOff);
			_mcOverlay.graphics.lineTo(ptv.x + nShOff, rcl.bottom + knBarOut + nShOff);
			
			// left bar
			_mcOverlay.graphics.moveTo(rcl.left + nShOff - knBarOut, ptv.y + nShOff);
			_mcOverlay.graphics.lineTo(rcl.left + nShOff + knBarIn, ptv.y + nShOff);
			
			// right bar
			_mcOverlay.graphics.moveTo(rcl.right + nShOff - knBarIn, ptv.y + nShOff);
			_mcOverlay.graphics.lineTo(rcl.right + nShOff + knBarOut, ptv.y + nShOff);
			
			// horizontal crossbar
			_mcOverlay.graphics.moveTo(ptv.x + nShOff - knCrossSize, ptv.y + nShOff);
			_mcOverlay.graphics.lineTo(ptv.x + nShOff + knCrossSize, ptv.y + nShOff);
			
			// vertical crossbar
			_mcOverlay.graphics.moveTo(ptv.x + nShOff, ptv.y + nShOff - knCrossSize);
			_mcOverlay.graphics.lineTo(ptv.x + nShOff, ptv.y + nShOff + knCrossSize);
		}

		override protected function get inEraseMode(): Boolean {
			return eraseMode;
		}
		
		protected override function StartDrag(ptd:Point):void {
			if (anchorMode) {
				_ptdCloneFrom = ptd.clone();
			} else {
				if (_ptdCloneFrom != null) {
					_xOffset = _ptdCloneFrom.x - ptd.x;
					_yOffset = _ptdCloneFrom.y - ptd.y;
					_ptdCloneFrom = null;
				}
				if (hasOffset) {
					_mctr.erase = eraseMode;
					
					_mctr.additive = true;
					
					/*
					// New way
					_mctr.brushAlpha = 0.3;
					*/
					
					// Old way
					
					_mctr.brushSpacing = 0.25;
					_mctr.extraStrokeParams = {strokeOperation:currentOp};
					super.StartDrag(ptd);
				}
			}
		}
	}
}
