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
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import picnik.util.Animator;
	
	import util.BindableDynamicObject;

	public class TwoPointOverlayEffectCanvasBase extends OverlayEffectCanvasBase {
		// pos properties are 'x' and 'y' and are in document coordinates
		[Bindable] public var startPos:BindableDynamicObject;
		[Bindable] public var endPos:BindableDynamicObject;
		
		private var _sprStart:Sprite;
		private var _sprEnd:Sprite;
		private var _sprMouseDown:Sprite;
		private var _xsMouseDown:int;
		private var _ysMouseDown:int;
		private var _dxsMouseDown:int;
		private var _dysMouseDown:int;
		private var _amtr:Animator;
		
		public override function Select(efcnvCleanup:NestedControlCanvasBase): Boolean {
			var fSelected:Boolean = super.Select(efcnvCleanup);
			if (fSelected) {
				_sprStart = CreateCircleSprite(15, 0xffffff, 1.0, "start");
				_mcOverlay.addChild(_sprStart);
				_sprEnd = CreateCircleSprite(15, 0xffffff, 1.0, "end");
				_mcOverlay.addChild(_sprEnd);
			}
			return fSelected;
		}
		
		public override function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null): void {
			_sprStart = null;
			_sprEnd = null;
			return super.Deselect(fForceRollOutEffect, efcvsNew);
		}
		
		public override function UpdateOverlay(): void {
			if (!_mcOverlay)
				return;
			
			var ptvStart:Point = _imgv.PtvFromPtd(new Point(startPos.x, startPos.y));
			var ptvEnd:Point = _imgv.PtvFromPtd(new Point(endPos.x, endPos.y));
			
			_sprStart.x = ptvStart.x;
			_sprStart.y = ptvStart.y;
			_sprEnd.x = ptvEnd.x;
			_sprEnd.y = ptvEnd.y;
		}
		
		private function CreateCircleSprite(cxyRadius:int, co:uint=0xffffff, nAlpha:Number=1.0, strName:String=null): Sprite {
			var spr:Sprite = new Sprite();

			with (spr.graphics) {
				// Draw shadow
				spr.graphics.lineStyle(2, 0x000000, 0.3);
				drawCircle(1, 1, cxyRadius);
				
				// Draw controller
				spr.graphics.lineStyle(2, co, nAlpha);
				beginFill(0x000000, 0.01); // Fill the circle so it can be clicked
				drawCircle(0, 0, cxyRadius);
				endFill();
			}

			spr.buttonMode = true;
			spr.name = strName;
			spr.addEventListener(MouseEvent.MOUSE_DOWN, OnCircleMouseDown);
			return spr;
		}
		
		private function OnCircleMouseDown(evt:MouseEvent): void {
			evt.stopImmediatePropagation();
			
			var spr:Sprite = evt.target as Sprite;
			_sprMouseDown = spr;
			_xsMouseDown = evt.stageX;
			_ysMouseDown = evt.stageY;
			_dxsMouseDown = _xsMouseDown - spr.x;
			_dysMouseDown = _ysMouseDown - spr.y;
			Util.CaptureMouse(stage, OnCircleMouseMove, OnCircleMouseUp);
			
			FadeTo(0.2);
		}
		
		private function OnCircleMouseMove(evt:MouseEvent): void {
			var spr:Sprite = _sprMouseDown;
			spr.x = evt.stageX - _dxsMouseDown;
			spr.y = evt.stageY - _dysMouseDown;
			var ptd:Point = _imgv.PtdFromPtv(new Point(spr.x, spr.y));
			var obPos:BindableDynamicObject = spr.name == "start" ? startPos : endPos;
			obPos.x = ptd.x;
			obPos.y = ptd.y;
			OnOpChange();
//			OnBufferedOpChange();
		}
		
		private function OnCircleMouseUp(evt:MouseEvent): void {
			FadeTo(1.0);
		}

		private function FadeTo(nAlpha:Number): void {
			if (_amtr)
				_amtr.Dispose();
			_amtr = new Animator(_mcOverlay, "alpha", _mcOverlay.alpha, nAlpha, 150, null, false, true);
		}
	}
}
