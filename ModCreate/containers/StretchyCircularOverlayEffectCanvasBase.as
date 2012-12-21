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
package containers
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import imagine.imageOperations.CircularGradientImageMask;
	
	import picnik.util.Animator;
	
	import util.BindableDynamicObject;


	public class StretchyCircularOverlayEffectCanvasBase extends OverlayEffectCanvasBase {
		[Bindable] public var _msk:CircularGradientImageMask;
		[Bindable] public var minRadius:Number = 20;
		[Bindable] public var maxRadius:Number = Number.POSITIVE_INFINITY;
		
		private var _asprDragPoints:Array = [];
		private var _sprMouseDown:Sprite;
		private var _nAngleMouseDown:Number;
		private var _xsMouseDown:int;
		private var _ysMouseDown:int;
		private var _dxsMouseDown:int;
		private var _dysMouseDown:int;
		private var _amtr:Animator;

		private var _nWidthRadius:Number = 100;
		private var _nHeightRadius:Number = 100;

		private const _knDragPoints:Number = 8;
		
		[Bindable]
		public function get widthRadius():Number {
			return _nWidthRadius;
		}
		
		public function set widthRadius(n:Number): void {
			_nWidthRadius = n;
		}
		
		[Bindable]
		public function get heightRadius():Number {
			return _nHeightRadius;
		}
		
		public function set heightRadius(n:Number): void {
			_nHeightRadius = n;
		}
		
		public override function Select(): Boolean {
			var fSelected:Boolean = super.Select();
			if (fSelected) {
				var i:int = 0;
				var sprDragPoint:Sprite;
				
				for (i = 0; i < _knDragPoints; i++) {
					sprDragPoint = CreateCircleSprite(5, 0xf3fddf, 0.3, "_"+i);
					_asprDragPoints.push(sprDragPoint);
					_mcOverlay.addChild(sprDragPoint);
				}				
			}
			
			return fSelected;
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

		public override function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null): void {
			_asprDragPoints = [];
			return super.Deselect(fForceRollOutEffect, efcvsNew);
		}
				
		public override function hitDragArea(): Boolean {
			if (!_mcOverlay) return false;
			if (!_msk) return false;

			// Convert overlay coordinates to doc coordinates.
			var ptd:Point = overlayMouseAsPtd;
			// Convert distance coords to 1x1 circle. Add +10 to give a little buffer.
			var xd:Number = (_xFocus - ptd.x) / (_nWidthRadius + 10);
			var yd:Number = (_yFocus - ptd.y) / (_nHeightRadius + 10);
			var cxyDistFromFocus:Number = Math.sqrt(xd * xd + yd * yd);
			return cxyDistFromFocus <= 1;
		}
		
		public override function UpdateOverlay(): void {
			if (!_mcOverlay) return;
			if (!_msk) return;
			
			var i:int;
			var sprDragPoint:Sprite;
			var nAngle:Number;
			var pt:Point;
						
			// dragpoints are in view coordinates
			for (i = 0; i < _knDragPoints; i++) {
				sprDragPoint = _asprDragPoints[i];
				nAngle = AngleForPosition(i, _knDragPoints);
				pt = new Point(_msk.xCenter + _nWidthRadius * Math.sin(nAngle),
							   _msk.yCenter + _nHeightRadius * Math.cos(nAngle));
				pt = _imgv.PtvFromPtd(pt);
				sprDragPoint.x = pt.x;
				sprDragPoint.y = pt.y;
			}
						
			// circle is in document coordinates
			var rcd:Rectangle = new Rectangle(_msk.xCenter, _msk.yCenter, _nWidthRadius, _nHeightRadius);
			var rcl:Rectangle = _imgv.RclFromRcd(rcd);
			var xCenter:Number = rcl.x;
			var yCenter:Number = rcl.y;
			const cxyCrossHairRadius:Number = 10;
			rcl.x -= rcl.width;
			rcl.width *= 2;
			rcl.y -= rcl.height;
			rcl.height *= 2;

			_mcOverlay.graphics.clear();
			_mcOverlay.graphics.lineStyle(1, 0x000000, 0.3, true);
			_mcOverlay.graphics.drawEllipse(rcl.x+1, rcl.y+1, rcl.width, rcl.height);
			
			_mcOverlay.graphics.moveTo(1+xCenter - cxyCrossHairRadius, 1+yCenter);
			_mcOverlay.graphics.lineTo(1+xCenter + cxyCrossHairRadius, 1+yCenter);
			_mcOverlay.graphics.moveTo(1+xCenter, 1+yCenter - cxyCrossHairRadius);
			_mcOverlay.graphics.lineTo(1+xCenter, 1+yCenter + cxyCrossHairRadius);
			
			_mcOverlay.graphics.lineStyle(1, 0xffffff, 0.3, true);
			_mcOverlay.graphics.drawEllipse(rcl.x, rcl.y, rcl.width, rcl.height);

			_mcOverlay.graphics.moveTo(xCenter - cxyCrossHairRadius, yCenter);
			_mcOverlay.graphics.lineTo(xCenter + cxyCrossHairRadius, yCenter);
			_mcOverlay.graphics.moveTo(xCenter, yCenter - cxyCrossHairRadius);
			_mcOverlay.graphics.lineTo(xCenter, yCenter + cxyCrossHairRadius);
		}
		
		private function OnCircleMouseDown(evt:MouseEvent): void {
			evt.stopImmediatePropagation();
			
			var i:int = 0;
			var spr:Sprite = evt.target as Sprite;
			_sprMouseDown = spr;
			for( i = 0; i < _knDragPoints; i++ ) {
				if (_sprMouseDown == _asprDragPoints[i]) {
					_nAngleMouseDown = AngleForPosition(i,_knDragPoints);
					break;
				}
			}
			_xsMouseDown = evt.stageX;
			_ysMouseDown = evt.stageY;
			_dxsMouseDown = _xsMouseDown - spr.x;
			_dysMouseDown = _ysMouseDown - spr.y;
			Util.CaptureMouse(stage, OnCircleMouseMove, OnCircleMouseUp);			
			FadeTo(0.0);
		}
		
		private function AngleForPosition(n:int, nPoints:int):Number {
			return Math.PI * 2 / nPoints * n;
		}
		
		private function OnCircleMouseMove(evt:MouseEvent): void {
			var spr:Sprite = _sprMouseDown;
			
			spr.x = evt.stageX - _dxsMouseDown;
			spr.y = evt.stageY - _dysMouseDown;
			var ptd:Point = _imgv.PtdFromPtv(new Point(spr.x, spr.y));
			
			// constrain the point based on the angle
			var nMinX:Number = Number.NEGATIVE_INFINITY;
			var nMaxX:Number = Number.POSITIVE_INFINITY;
			var nMinY:Number = Number.NEGATIVE_INFINITY;
			var nMaxY:Number = Number.POSITIVE_INFINITY;
						
			var nSin:Number = Math.sin(_nAngleMouseDown);
			var nCos:Number = Math.cos(_nAngleMouseDown);
			
			// rounding errors mean we can't compare directly to zero
			if (nSin >= -0.001) {
				nMinX = _msk.xCenter;
			}
			if (nSin <= 0.001) {
				nMaxX = _msk.xCenter;
			}
			if (nCos >= -0.001) {
				nMinY = _msk.yCenter;
			}
			if (nCos <= 0.001) {
				nMaxY = _msk.yCenter;
			}
			
			if (ptd.x < nMinX) ptd.x = nMinX;
			if (ptd.y < nMinY) ptd.y = nMinY;						
			if (ptd.x > nMaxX) ptd.x = nMaxX;						
			if (ptd.y > nMaxY) ptd.y = nMaxY;						

			var nAspect:Number = _nWidthRadius / _nHeightRadius;
			var nWidth:Number = _nWidthRadius;
			var nHeight:Number = _nHeightRadius;
			
			// figure out which parameters give us an ellipse through this point
			if (nMinX == nMaxX) {
				// we're only moving the height
				nHeight = Math.abs(ptd.y - _msk.yCenter);
			} else if (nMinY == nMaxY) {
				// we're only moving the width
				nWidth = Math.abs(ptd.x - _msk.xCenter);				
			} else {
				// we're at one of the 45-degree points.
				nHeight = Math.abs((ptd.y - _msk.yCenter) / nCos);
				nWidth = Math.abs((ptd.x - _msk.xCenter) / nSin);								
			}
			
			// set the new sizes
			heightRadius = Math.min(maxRadius,Math.max(minRadius,nHeight));
			widthRadius = Math.min(maxRadius,Math.max(minRadius,nWidth));
			
			OnOpChange();
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
