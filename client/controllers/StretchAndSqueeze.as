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
// UNDONE: OPT: is there a way to set width/height w/o causing parent to updateDisplayList?
// UNDONE: dragging to an irretrievable position
// UNDONE: proximity fade in/out
// UNDONE: use style parameters to determine drop shadow args, circle radius,

package controllers {
	import imagine.documentObjects.DocumentObjectUtil;
	import imagine.documentObjects.IDocumentObject;
	import imagine.documentObjects.StretchAndSqueezeDocumentObject;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	import mx.controls.Text;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.core.Application;
	import mx.events.PropertyChangeEvent;
	import mx.managers.IFocusManagerComponent;
	
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	import overlays.helpers.Cursor;
	
	import picnik.util.Animator;
	
	import util.GlobalEventManager;
	
	public class StretchAndSqueeze extends MoveSizeRotate {			
		protected var _nMouseZone:Number;
		
		public function StretchAndSqueeze(imgv:ImageView, dob:DisplayObject, fCrop:Boolean=true) {
			super(imgv,dob,fCrop);
			_fRecordUndoHistory = false;
			_fSymmetricResize = true;
		}
		
		public function get stretch():Point {
			var sasDoco:StretchAndSqueezeDocumentObject = target as StretchAndSqueezeDocumentObject;
			return new Point(sasDoco.xStretch, sasDoco.yStretch);
		}
		
		public function set stretch(p:Point):void {
			var sasDoco:StretchAndSqueezeDocumentObject = target as StretchAndSqueezeDocumentObject;
			sasDoco.xStretch = p.x;
			sasDoco.yStretch = p.y;
		}
		
		override protected function Draw(nHiZone:Number): void {
			var rcl:Rectangle = view.RcvFromRcd(docLocalRect);
			with (graphics) {
				clear();
				// Draw controller shadow
				var rclShadow:Rectangle = rcl.clone();
				rclShadow.offset(1, 1);
				DrawController(graphics, rclShadow, stretch, 0x000000, 0.4, nHiZone);
				
				// Draw controller
				DrawController(graphics, rcl, stretch, 0xffffff, 0.8, nHiZone);
			}
		}
		
		override protected function _UpdateDisplayList(): void {
			Draw(this._fMouseDown ? _nHitZone : _nMouseZone);
		}
		
		// CONFIG:
		private static const kcxyHandle:Number = 10;
		private static const kcxyHalfHandle:Number = kcxyHandle / 2;
		private static const kcxyHitHandle:int = kcxyHandle * 2;
		private static const kcxyDotSize:Number = 0.5;
		private static const knDotSpacer:int = 30;
		private static const knDashSize:Number = 0.09;
		private static const knOffsetScaler:Number = 8;	// determines how much dots move around

		private function DrawController(gr:Graphics, rcl:Rectangle, ptStretcher:Point, co:Number, nAlpha:Number, nHiZone:Number): void {
			with (gr) {
				var ptStretcherTransformed:Point = StretchToControlPoint(rcl, stretch);

				// draw transparent rects to define the hit points
				lineStyle(1, co, 0.0);
				beginFill(0xff00ff, 0.0);
				drawCircle(rcl.left + rcl.width/2, rcl.top, kcxyHitHandle);
				drawCircle(rcl.left, rcl.bottom - rcl.height/2, kcxyHitHandle);
				drawCircle(rcl.right, rcl.top + rcl.height/2, kcxyHitHandle);
				drawCircle(rcl.right, rcl.bottom - rcl.height/2, kcxyHitHandle);
				drawCircle(ptStretcherTransformed.x, ptStretcherTransformed.y, kcxyHitHandle);
				endFill();
				// need separate begin/end or the intersections end up getting cut out of the fill
				beginFill(0xff00ff, 0.0);
				drawEllipse(rcl.left - kcxyHandle, rcl.top - kcxyHandle, rcl.width + kcxyHandle, rcl.height + kcxyHandle);
				endFill();
				
				var nDotsX:int = Math.min(15, Math.max(6,Math.round(rcl.width / knDotSpacer)));
				var nDotsY:int = Math.min(15, Math.max(6,Math.round(rcl.height / knDotSpacer)));
				nDotsX -= nDotsX % 2; // keep it even-numbered 'cause it looks cooler
				nDotsY -= nDotsY % 2;
				var offsetX:Number = ((nDotsX+1) % 2) / 2;	// add in a half-position if we're even so...
				var offsetY:Number = ((nDotsY+1) % 2) / 2;  // that placement is correct
				
				// draw a grid of little dots to demonstrate what's going on
				lineStyle(1, co, nAlpha * (this._fMouseDown ? 0.4 : 0.1));
				for (i = 0; i < nDotsX; i++) {
					for (j = 0; j < nDotsY; j++) {
						// set x,y to iterate over the range -1 .. 1
						var x:Number = (i + offsetX - Math.floor(nDotsX/2)) / (nDotsX/2);			
						var y:Number = (j + offsetY - Math.floor(nDotsY/2)) / (nDotsY/2);
						var dst:Number = Math.sqrt(x*x + y*y);
						
						var hx1:Number = ((i-1) + offsetX - Math.floor(nDotsX/2)) / (nDotsX/2);			
						var hy1:Number = (j + offsetY - Math.floor(nDotsY/2)) / (nDotsY/2);
						var hd1:Number = Math.sqrt(hx1*hx1 + hy1*hy1);
						
						var hx2:Number = ((i+1) + offsetX - Math.floor(nDotsX/2)) / (nDotsX/2);			
						var hy2:Number = (j + offsetY - Math.floor(nDotsY/2)) / (nDotsY/2);
						var hd2:Number = Math.sqrt(hx2*hx2 + hy2*hy2);
						
						var vx1:Number = (i + offsetX - Math.floor(nDotsX/2)) / (nDotsX/2);			
						var vy1:Number = ((j-1) + offsetY - Math.floor(nDotsY/2)) / (nDotsY/2);
						var vd1:Number = Math.sqrt(vx1*vx1 + vy1*vy1);
						
						var vx2:Number = (i + offsetX - Math.floor(nDotsX/2)) / (nDotsX/2);			
						var vy2:Number = ((j+1) + offsetY - Math.floor(nDotsY/2)) / (nDotsY/2);
						var vd2:Number = Math.sqrt(vx2*vx2 + vy2*vy2);
						
						if (dst > 1) {
							continue;
						}
						
						x *= 1 + knOffsetScaler * (1-dst) * stretch.x/nDotsX;
						y *= 1 + knOffsetScaler * (1-dst) * stretch.y/nDotsY;
						
						hx1 *= 1 + knOffsetScaler * (1-hd1) * stretch.x/nDotsX;
						hy1 *= 1 + knOffsetScaler * (1-hd1) * stretch.y/nDotsY;
						hx2 *= 1 + knOffsetScaler * (1-hd2) * stretch.x/nDotsX;
						hy2 *= 1 + knOffsetScaler * (1-hd2) * stretch.y/nDotsY;
						vx1 *= 1 + knOffsetScaler * (1-vd1) * stretch.x/nDotsX;
						vy1 *= 1 + knOffsetScaler * (1-vd1) * stretch.y/nDotsY;
						vx2 *= 1 + knOffsetScaler * (1-vd2) * stretch.x/nDotsX;
						vy2 *= 1 + knOffsetScaler * (1-vd2) * stretch.y/nDotsY;
						
						// draw a dot!
						moveTo(rcl.left + rcl.width/2 + rcl.width/2 * (x*(1-knDashSize) + hx1*knDashSize),
							rcl.top + rcl.height/2 + rcl.height/2 * (y*(1-knDashSize) + hy1*knDashSize));
						lineTo(rcl.left + rcl.width/2 + rcl.width/2 * (x*(1-knDashSize) + hx2*knDashSize),
							rcl.top + rcl.height/2 + rcl.height/2 * (y*(1-knDashSize) + hy2*knDashSize));
						moveTo(rcl.left + rcl.width/2 + rcl.width/2 * (x*(1-knDashSize) + vx1*knDashSize),
							rcl.top + rcl.height/2 + rcl.height/2 * (y*(1-knDashSize) + vy1*knDashSize));
						lineTo(rcl.left + rcl.width/2 + rcl.width/2 * (x*(1-knDashSize) + vx2*knDashSize),
							rcl.top + rcl.height/2 + rcl.height/2 * (y*(1-knDashSize) + vy2*knDashSize));
						
					}
				}
				
				// Draw the circle
				//lineStyle(2, co, nAlpha - 0.1);
				//drawEllipse(rcl.left, rcl.top, rcl.width, rcl.height);
				
				// Draw the corner handles
				lineStyle(2, co, nAlpha * (nHiZone == 2 ? 1 : 0.8));
				drawCircle(rcl.left + rcl.width/2, rcl.top, kcxyHalfHandle);
				lineStyle(2, co, nAlpha * (nHiZone == 8 ? 1 : 0.8));
				drawCircle(rcl.left, rcl.bottom - rcl.height/2, kcxyHalfHandle);
				lineStyle(2, co, nAlpha * (nHiZone == 4 ? 1 : 0.8));
				drawCircle(rcl.right, rcl.top + rcl.height/2, kcxyHalfHandle);
				lineStyle(2, co, nAlpha * (nHiZone == 6 ? 1 : 0.8));
				drawCircle(rcl.right - rcl.width/2, rcl.bottom, kcxyHalfHandle);

				// Draw the stretcher handle as a diamond
				lineStyle(2, co, nAlpha * (nHiZone == 9 ? 1 : 0.8));
				moveTo( ptStretcherTransformed.x - kcxyHandle, ptStretcherTransformed.y );
				lineTo( ptStretcherTransformed.x, ptStretcherTransformed.y - kcxyHandle);
				lineTo( ptStretcherTransformed.x + kcxyHandle, ptStretcherTransformed.y );
				lineTo( ptStretcherTransformed.x, ptStretcherTransformed.y + kcxyHandle );
				lineTo( ptStretcherTransformed.x - kcxyHandle, ptStretcherTransformed.y );
				
				//drawCircle(ptStretcherTransformed.x, ptStretcherTransformed.y, kcxyHalfHandle);
			}
		}
		
		private function SquareToCircleScaler( ptStretch:Point ): Number {
			var dstScale:Number = 1;
			if (ptStretch.x != 0 && ptStretch.y != 0) {
				//scale to fit inside the circle
				var slope:Number = ptStretch.y / ptStretch.x;
				// calculate distance to the edge of the square
				// y = slope * x
				if (slope < 1 && slope > -1) {
					// x = 1; y = slope
					dstScale = Math.sqrt( 1 + slope*slope );
				} else {
					// y = 1; x = 1/slope
					dstScale = Math.sqrt( 1 + 1/(slope*slope) );	
				}
			}
			return dstScale;
		}
		
		private function StretchToControlPoint( rcl:Rectangle, ptStretch:Point ): Point {
			// transforms the x,y stretch point to fit within the effect's bounding oval
			var dstScale:Number = SquareToCircleScaler(ptStretch);
			var cxlCenter:Number = (rcl.width / 2 - kcxyHandle) * ptStretch.x/dstScale;
			var cylCenter:Number = (rcl.height / 2 - kcxyHandle) * ptStretch.y/dstScale;
			return new Point( (rcl.left+rcl.right)/2 + cxlCenter, (rcl.top+rcl.bottom)/2  - cylCenter );
		}
		
		private function ControlPointToStretch( rcl:Rectangle, ptStretch:Point ): Point {
			var cxUnscaled:Number = ptStretch.x / (rcl.width / 2 - kcxyHandle);
			var cyUnscaled:Number = ptStretch.y / (rcl.height / 2 - kcxyHandle);
			var dstScale:Number = SquareToCircleScaler(new Point(cxUnscaled, cyUnscaled));
				
			cxUnscaled = Math.max(-1, Math.min(1,cxUnscaled*dstScale));
			cyUnscaled = Math.max(-1, Math.min(1,cyUnscaled*dstScale));
			return new Point( cxUnscaled, -cyUnscaled );
		}
		
		override protected function UpdateMouseCursor(evt:MouseEvent): void {
			if (!_fMouseDown) {
				var rcl:Rectangle = GetViewBounds();
				
				var nMouseZone:Number = _nMouseZone;
				if (evt) {
					nMouseZone = HitTestTarget(rcl, evt.localX, evt.localY);
				}				
				
				if (nMouseZone != _nMouseZone || _imgv.imageViewCursor == null) {
					_nMouseZone = nMouseZone;
					Draw(_nMouseZone);
					if (_nMouseZone != -1) {
						if (IDocumentObject(target).isFixed)
							_imgv.imageViewCursor = Cursor.csrArrowSelect;
						else
							_imgv.imageViewCursor = GetCursor(_nMouseZone);
						
					} else {
						_imgv.imageViewCursor = null;
					}
				}
			}
		}
				
		override protected function HitTestTarget(rcl:Rectangle, xl:Number, yl:Number): Number {
			// We override hitpoint #9 (rotate handle) to be our stretcher handle instead
			// The rectangle is centered on 0,0 and (xl,yl) is relative to that center.
			var ptStretch:Point = StretchToControlPoint(rcl, stretch);
			var rclStretcherHandle:Rectangle = new Rectangle(
				ptStretch.x + Math.round(-kcxyHitHandle / 2),
				ptStretch.y + Math.round(-kcxyHitHandle / 2),
				kcxyHitHandle,
				kcxyHitHandle);
			if (rclStretcherHandle.contains(xl, yl))
				return 9;
			return Util.HitTestPaddedRect(rcl, xl, yl, kcxyHitPad, false);
		}
		
		override protected function OnStageCaptureMouseMoveInZone(nHitZone:Number, evt:MouseEvent): void {
			if (nHitZone == 9) {
				var rcl:Rectangle = view.RcvFromRcd(docLocalRect);
				var ptStage:Point = GlobalEventManager.GetAxisConstrainedMousePosition()				
				var ptdMouse:Point = view.PtdFromPts(ptStage);
				var ptd:Point = new Point(ptdMouse.x - docX, ptdMouse.y - docY);
				var ptv:Point = view.PtvFromPtd(ptd);
				stretch = ControlPointToStretch( rcl, ptv );	
			} else {
				super.OnStageCaptureMouseMoveInZone(nHitZone,evt);
			}
		}

		override protected function OnMouseDownHitTest(evt:MouseEvent): Number {
			return HitTestTarget(GetViewBounds(), evt.localX, evt.localY);
		}
		
		override protected function GetCursor( nHitZone:int ): Cursor {
			if (nHitZone == 9 ) {
				if (_fMouseDown) {
					return Cursor.csrHandGrab;
				}
				return Cursor.csrHand;
			}
			return super.GetCursor(nHitZone);
		}
				
		override protected function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.DELETE || evt.keyCode == Keyboard.BACKSPACE) {
				// eat the delete
				return;
			}
			super.OnKeyDown(evt);
		}
		
		override protected function get minSize(): Point {
			return new Point(100,100);
		}		
		
		override protected function FadeOut(): void {
			// overridden because we don't want the control to fade in and out
			alpha=1.0;
		}
		override protected function FadeIn(): void {
			// overridden because we don't want the control to fade in and out
			alpha=1.0;
		}
		
		
	}
}
