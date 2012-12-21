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
	import containers.NestedControlCanvasBase;
	
	import controls.BrushSizeAndEraserButton;
	import controls.HSliderPlus;
	
	import flash.events.Event;
	import flash.geom.Point;
	import flash.utils.getQualifiedClassName;
	
	import imagine.imageOperations.paintMask.Brush;
	import imagine.imageOperations.paintMask.PaintMaskController;
	
	import mx.controls.Button;
	
	import util.IPaintEffect;

	public class PaintOnEffectBase extends DrawOverlayEffectCanvas implements IPaintEffect {
		[Bindable] public var _sldrBrushSize:HSliderPlus;
		[Bindable] public var _btnEraser:Button;
		[Bindable] protected var _mctr:PaintMaskController;
		
		private var _br:Brush = null;
		
		protected function get brush(): Brush {
			if (_br == null) _br = CreateBrush();
			return _br;
		}
		
		protected function set brush(br:Brush): void {
			_br = br;
			_mctr.brush = br;
		}
		
		public function PaintOnEffectBase(): void {
			InitController();
		}
		
		protected function InitController(): void {
			_mctr = new PaintMaskController();
		}

		override protected function OnInitialize(evt:Event): void {
			super.OnInitialize(evt);
			_mctr.addEventListener(Event.CHANGE, OnMaskChange);
			_mctr.mask.inverted = false;
//			_mctr.brush = brush;
		}
		
		public function get paintMaskController(): PaintMaskController {
			return _mctr;
		}
		
		private function OnMaskChange(evt:Event): void {
			OnOpChange();
		}
		
		public override function OnImageChange(evt:Event):void {
			super.OnImageChange(evt);
			_mctr.width = imagewidth;
			_mctr.height = imageheight;
		}
		
		protected function SliderToBrushSize(nSlider:Number): Number {
			return nSlider;
		}
		
		protected function GetBrushSize(): Number {
			var nSliderValue:Number;
			if ('_brshbtn' in this)
				return (this['_brshbtn'] as BrushSizeAndEraserButton).value;
			return Math.round(SliderToBrushSize(_sldrBrushSize.value));
		}
		
		protected override function StartDrag(ptd:Point):void {
			try {
				if (_mctr) {
					_mctr.brush = brush;
					_mctr.mask.inverted = false;
					_br.diameter = GetBrushSize();
					
					var nSpacing:Number = 0.25;
					if ("_nSpacing" in this)
						nSpacing = this["_nSpacing"];
					_mctr.brushSpacing = nSpacing;
					
					if ("_sldrHardness" in this)
						_nBrushHardness = this["_sldrHardness"].value;
					_br.hardness = _nBrushHardness;
	
	/*				
					if ("_sldrStrength" in this)
						_mctr.brushAlpha = this["_sldrStrength"].value;
	*/
					if ("brushAlpha" in this)
						_mctr.brushAlpha = this["brushAlpha"];
								
					if ("brushRotation" in this)
						_mctr.brushRotation = this["brushRotation"];
					
					_mctr.erase = inEraseMode;
					_mctr.StartDrag(ptd);			
				}
			} catch (e:Error) {
				HandleError("StartDrag", e, _mctr);
				throw e;
			}
		}
		
		protected function get inEraseMode(): Boolean {
			if ('_brshbtn' in this) {
				var brshbtn:BrushSizeAndEraserButton = this['_brshbtn'];
				return brshbtn._btnEraser && brshbtn._btnEraser.selected;
			}
			return _btnEraser && _btnEraser.selected;
		}
		
		protected override function ContinueDrag(ptd:Point):void {
			try {
				if (_fOverlayMouseDown && _mctr)
					_mctr.ContinueDrag(ptd);
			} catch (e:Error) {
				HandleError("ContinueDrag", e, _mctr);
				throw e;
			}
		}

		public override function OnOverlayRelease():Boolean {
			try {
				if (_fOverlayMouseDown && _mctr && brushActive) {
					_mctr.FinishDrag();
				}
			} catch (e:Error) {
				HandleError("OnOverlayRelease", e, _mctr);
				throw e;
			}
			return super.OnOverlayRelease();
		}
		
		override public function Select(efcnvCleanup:NestedControlCanvasBase): Boolean {
			try {
				var fSelected:Boolean = super.Select(efcnvCleanup);
				if (fSelected) {
					_mctr.Reset();
					_mctr.PrepareForNextStroke();
				}
			} catch (e:Error) {
				HandleError("Select", e, _mctr);
				throw e;
			}
			return fSelected;
		}
	}
}
