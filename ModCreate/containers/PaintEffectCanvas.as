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
package containers {
	import creativeTools.BrushPaletteWindow;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import imagine.imageOperations.paintMask.PaintMaskController;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.controls.Button;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	
	import util.IPaintEffect;

	public class PaintEffectCanvas extends DrawOverlayEffectCanvas implements IPaintEffect {
		[Bindable] public var _btnBrushPalette:Button;
		private var _chwReverse:ChangeWatcher;
		private var _chwBrushSize:ChangeWatcher;
		[Bindable] protected var _mctr:PaintMaskController  = new PaintMaskController();
		
		//
		// Manage the UI
		//
		
		override protected function OnInitialize(evt:Event): void {
			super.OnInitialize(evt);
			_mctr.addEventListener(Event.CHANGE, OnMaskChange);
			addEventListener(FlexEvent.CREATION_COMPLETE,
				function(evt:Event): void {
					_mctr.mask.inverted = maskIsInverted;
				});
		}
		
		public function get paintMaskController(): PaintMaskController {
			return _mctr;
		}
		
		private function get maskIsInverted(): Boolean {
			return (parent == null || brushPalette == null ) ? true : (!brushPalette.reverse);
		}
		
		public override function OnImageChange(evt:Event):void {
			super.OnImageChange(evt);
			_mctr.width = imagewidth;
			_mctr.height = imageheight;
		}
		
		private function OnMaskChange(evt:Event): void {
			OnOpChange();
		}
		
		override protected function OnAllStagesCreated(): void {
			super.OnAllStagesCreated();
			brushPalette.active = isBrushPalettePersistentlyActive;
			_btnBrushPalette.addEventListener(MouseEvent.CLICK, OnBrushPaletteClick);
		}
		
		protected function get isBrushPalettePersistentlyActive(): Boolean {
			return AccountMgr.GetInstance().GetUserAttribute("PaintEffectCanvas.fBrushPaletteActive", true);
		}

		protected function set isBrushPalettePersistentlyActive(fActive:Boolean): void {
			AccountMgr.GetInstance().SetUserAttribute("PaintEffectCanvas.fBrushPaletteActive", fActive);
		}

		protected function TakeBrushPaletteState(): void {
			_btnBrushPalette.selected = brushPalette.active;
			brushActive = brushPalette.active;
			_cxyBrush = brushPalette.size;
			if (brushPalette.active && showBrushPalette)
				ShowBrushPalette();
		}
		
		private var _fShowBrushPalette:Boolean = true;
		
		protected function get showBrushPalette(): Boolean {
			return _fShowBrushPalette;
		}
		
		protected function set showBrushPalette(fShow:Boolean): void {
			_fShowBrushPalette = fShow;
		}
		
		private function ShowBrushPalette(fActivate:Boolean=false): void {
			var pwndBrush:BrushPaletteWindow = brushPalette;
			if (pwndBrush.parent != Application.application) {
				pwndBrush.parent.removeChild(pwndBrush);
				Application.application.addChild(pwndBrush);
			}
			pwndBrush.visible = true;
//			_btnBrushPalette.selected = true;
			if (fActivate) {
				isBrushPalettePersistentlyActive = true;
				pwndBrush.active = true;
			}
			pwndBrush.addEventListener(CloseEvent.CLOSE, OnBrushPaletteClose);
		}

		private function HideBrushPalette(fDeactivate:Boolean=false): void {
			brushPalette.visible = false;
//			_btnBrushPalette.selected = false;
			if (fDeactivate) {
				isBrushPalettePersistentlyActive = false;
				brushPalette.active = false;
			}
			brushPalette.removeEventListener(CloseEvent.CLOSE, OnBrushPaletteClose);
		}
		
		private function OnBrushPaletteClose(evt:CloseEvent): void {
			CloseBrushPalette();
		}
		
		public function CloseBrushPalette(): void {
			HideBrushPalette(true);
			_btnBrushPalette.selected = false;
			brushActive = false;
		}
		
		public function OpenBrushPalette(): void {
			ShowBrushPalette();
		}

		[Bindable]
		public function get brushPalette(): BrushPaletteWindow {
			var uic:Object = Util.FindAncestorById(this, "creativeTools");
			if (uic == null)
				uic = Util.FindAncestorById(this, "_cvsEditCreate");
			if (uic == null)
				return null;
				
			return uic._pwndBrush as BrushPaletteWindow;
		}
		
		// This is just here to make everything nice and bindable w/o compiler complaints
		public function set brushPalette(pwnd:BrushPaletteWindow): void {
		}
		
		private function OnBrushPaletteClick(evt:MouseEvent): void {
			var fActive:Boolean = _btnBrushPalette.selected;
			if (fActive)
				ShowBrushPalette(true);
			else
				HideBrushPalette(true);
			brushActive = fActive;
		}

		override public function Select(efcnvCleanup:NestedControlCanvasBase): Boolean {
			var fWasSelected:Boolean = IsSelected();
			var fSelected:Boolean = super.Select(efcnvCleanup);
			if (fSelected && !fWasSelected) {
				TakeBrushPaletteState();
				_chwBrushSize = ChangeWatcher.watch(brushPalette, "size", OnBrushSizeChange);
				_chwReverse = ChangeWatcher.watch(brushPalette, "reverse", OnReverse);
				// Reset our mask
				_mctr.Reset();
				_mctr.width = imagewidth;
				_mctr.height = imageheight;
				brushPalette.reverse = false;
				brushPalette.paint = false;
			}
			return fSelected;
		}
		
		override public function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null): void {
			if (IsSelected()) {
				// If there is new effect being shown and it is a PaintEffectCanvas,
				// don't hide the BrushPaletteWindow.
				if (efcvsNew == null || !(efcvsNew is PaintEffectCanvas))
					HideBrushPalette();
				_chwReverse.unwatch();
				_chwBrushSize.unwatch();
			}
				
			super.Deselect(fForceRollOutEffect, efcvsNew);
		}
		
		private function OnReverse(evt:Event): void {
			_mctr.mask.inverted = maskIsInverted;
			brushPalette.paint = !maskIsInverted;
			OnOpChange();
		}

		private function OnBrushSizeChange(evt:Event): void {
			_cxyBrush = brushPalette.size;
		}

		//
		// Manage the mask
		//
		
		protected override function StartDrag(ptd:Point):void {
			try {
				if (_mctr) {
					_mctr.mask.inverted = maskIsInverted;
					_mctr.brush = brushPalette.brush;
					_mctr.brushAlpha = brushPalette.strength;
					_mctr.erase = brushPalette.paint == maskIsInverted;
					_mctr.StartDrag(ptd);			
				}
			} catch (e:Error) {
				HandleError("StartDrag", e, _mctr);
				throw e;
			}
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
				HandleError("FinishDrag", e, _mctr);
				throw e;
			}
			return super.OnOverlayRelease();
		}
	}
}
