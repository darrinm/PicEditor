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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import imagine.imageOperations.ShapeGradientImageMask;

	public class CircularOverlayEffectCanvasBase extends OverlayEffectCanvasBase {
		
		protected function get effectMask(): ShapeGradientImageMask {
			if ('_msk' in this)
				return this['_msk'] as ShapeGradientImageMask;
			return null;
		}
		
		public override function hitDragArea(): Boolean {
			if (!_mcOverlay) return false;
			if (!effectMask) return false;

			// Convert overlay coordinates to doc coordinates.
			var ptd:Point = overlayMouseAsPtd;
			// Convert distance coords to 1x1 circle
			var xd:Number = (_xFocus - ptd.x) / effectMask.getWidthRadius();
			var yd:Number = (_yFocus - ptd.y) / effectMask.getHeightRadius();
			var cxyDistFromFocus:Number = Math.sqrt(xd * xd + yd * yd);
			return cxyDistFromFocus <= 1;
		}
				
		public override function UpdateOverlay(): void {
			if (!_mcOverlay) return;
			if (!effectMask) return;
			// These are in document coordinates
			var rcd:Rectangle = new Rectangle(effectMask.xCenter, effectMask.yCenter, effectMask.getWidthRadius(), effectMask.getHeightRadius());
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
			
			effectMask.DrawOutline(_mcOverlay.graphics, rcl.x+1, rcl.y+1, rcl.width, rcl.height);
			
			_mcOverlay.graphics.moveTo(1+xCenter - cxyCrossHairRadius, 1+yCenter);
			_mcOverlay.graphics.lineTo(1+xCenter + cxyCrossHairRadius, 1+yCenter);
			_mcOverlay.graphics.moveTo(1+xCenter, 1+yCenter - cxyCrossHairRadius);
			_mcOverlay.graphics.lineTo(1+xCenter, 1+yCenter + cxyCrossHairRadius);
			
			_mcOverlay.graphics.lineStyle(1, 0xffffff, 0.3, true);
			effectMask.DrawOutline(_mcOverlay.graphics, rcl.x, rcl.y, rcl.width, rcl.height);

			_mcOverlay.graphics.moveTo(xCenter - cxyCrossHairRadius, yCenter);
			_mcOverlay.graphics.lineTo(xCenter + cxyCrossHairRadius, yCenter);
			_mcOverlay.graphics.moveTo(xCenter, yCenter - cxyCrossHairRadius);
			_mcOverlay.graphics.lineTo(xCenter, yCenter + cxyCrossHairRadius);
		}
	}
}
