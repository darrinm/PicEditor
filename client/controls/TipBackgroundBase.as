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
package controls
{
	import flash.display.GradientType;
	import flash.display.SpreadMethod;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;
	
	import util.GooglePlusUtil;

	public class TipBackgroundBase extends UIComponent
	{
		//======== BEGIN: Look and feel constants ========
		
		// Space for the drop shadow, the thumb, and the close box
		public static const knTopMargin:Number = 4;
		public static const knRightMargin:Number = 4;
		public static const knBottomMargin:Number = 4;
		public static const knLeftMargin:Number = 4;
		
		// Padding to pull the text in from the borders
		public static const knTopPadding:Number = 4;
		public static const knRightPadding:Number = 4;
		public static const knBottomPadding:Number = 4;
		public static const knLeftPadding:Number = 4;
		
		// When the target point is more than this distance insde of our
		// rect, hide the thumb
		public static const knThumbThreshold:Number = 8;
		
		public static const knThumbWidth:Number = 32;
		public static const knThumbDepth:Number = 11;
		public static const knThumbPadding:Number = 2;

		//======== END: Look and feel constants ========
		
		public static const THUMB_SIDE_NONE:Number = -1;
		public static const THUMB_SIDE_TOP:Number = 0;
		public static const THUMB_SIDE_RIGHT:Number = 1;
		public static const THUMB_SIDE_BOTTOM:Number = 2;
		public static const THUMB_SIDE_LEFT:Number = 3;
		

		private var _nThumbSide:Number = THUMB_SIDE_NONE;
		private var _nThumbXY:Number = 0;
		
		private var _fShapesValid:Boolean = false;
		private var _ptPrevSize:Point = new Point(0,0);
		private var _uicPointAt:UIComponent;
		private var _rcPointAt:Rectangle;
		private var _xShiftFactor:Number = 0;
		private var _auicMoveBroadcasters:Array = [];
		private var _closeButtonEnabled:Boolean = true;
				
		private static function get isGooglePlus(): Boolean {
			return GooglePlusUtil.UsingGooglePlusAPIKey(PicnikBase.app.parameters);
		}
		
		public static function get clrBGColorTop(): Number {
			return isGooglePlus ? 0x202020 : 0x7e9e3c;
		} 
		
		public static function get clrBGColorBottom(): Number {
			return isGooglePlus ? 0x202020 : 0x4c5d20;
		} 

		public static function get roundedRectCornerRadius():Number {
			return isGooglePlus ? 1 : 12;
		}
		
		public static function get closeCircleRadius():Number {
			return isGooglePlus ? 11 : 11;
		}
		
		public static function get closeCircleCornerRadius():Number {
			return isGooglePlus ? 1 : 11;
		}
		
		public static function get closeCircleYOffset():Number {
			return isGooglePlus ? -4 : -4;
		}
		
		public static function get closeCircleXOffset():Number {
			return isGooglePlus ? 6 : 6;
		}
		
		public function PointThumbAtGlobalRect(rc:Rectangle, xShiftFactor:Number=0): void {
			_rcPointAt = rc;
			_xShiftFactor = xShiftFactor;
			InvalidateShapes();
		}
		
		public function PointThumbAtUIC(uic:UIComponent, xShiftFactor:Number=0): void {
			_uicPointAt = uic;
			_xShiftFactor = xShiftFactor;
			InvalidateShapes();
			
			//DYNAMIC POINTING:  Support dynamic pointing - update the pointer when the target moves
			// if (_auicMoveBroadcasters) UnListenToMoves();
			// if (fDynamic && _uicPointAt) ListenToMoves();
		}
		
		/*DYNAMIC POINTING:
		private function UnListenToMoves(): void {
			while (_auicMoveBroadcasters.length > 0) {
				var uicListen:UIComponent = _auicMoveBroadcasters.pop();
				uicListen.removeEventListener("xChanged", UpdateThumb);
				uicListen.removeEventListener("yChanged", UpdateThumb);
				uicListen.removeEventListener(ScrollEvent.SCROLL, UpdateThumb);
			}
		}
		
		private function ListenToMoves(): void {
			var uicListen:UIComponent = _uicPointAt;
			while (uicListen != null) {
				uicListen.addEventListener("xChanged", UpdateThumb);
				uicListen.addEventListener("yChanged", UpdateThumb);
				uicListen.addEventListener(ScrollEvent.SCROLL, UpdateThumb);
				_auicMoveBroadcasters.push(uicListen);
				uicListen = uicListen.parent as UIComponent;
			}
		}
		
		public function UpdateThumb(evt:Event=null): void {
			if (evt && evt.type != TimerEvent.TIMER) {
				var tmr:Timer = new Timer(100, 5);
				tmr.addEventListener(TimerEvent.TIMER, UpdateThumb);
				tmr.start();
			}
			InvalidateShapes();
		}
		*/
		
		private function InvalidateShapes(): void {
			_fShapesValid = false;
			invalidateDisplayList();
		}
		
		private function DrawShapes(): void {
			graphics.clear();
			
			var mat:Matrix = new Matrix();
			
			var rcBox:Rectangle = new Rectangle(knLeftMargin, knTopMargin, width - knLeftMargin - knRightMargin, height - knTopMargin - knBottomMargin);
			
			mat.createGradientBox(rcBox.width, rcBox.height, Math.PI/2, rcBox.x, rcBox.y);
			
			// Draw close circle
			if (closeButtonEnabled) {
				graphics.beginGradientFill(GradientType.LINEAR, [clrBGColorTop, clrBGColorBottom], [1, 1], [0x00, 0xFF], mat, SpreadMethod.PAD);
				var xCenter:Number = rcBox.right - closeCircleRadius + closeCircleXOffset;
				var yCenter:Number = rcBox.top + closeCircleRadius + closeCircleYOffset;
				if (closeCircleRadius == closeCircleCornerRadius)
					graphics.drawCircle(xCenter, yCenter, closeCircleRadius);
				else
					graphics.drawRoundRect(xCenter - closeCircleRadius, yCenter - closeCircleRadius, closeCircleRadius * 2, closeCircleRadius * 2, closeCircleCornerRadius * 2, closeCircleCornerRadius * 2);
				graphics.endFill();
			}
						
			// Draw box
			graphics.beginGradientFill(GradientType.LINEAR, [clrBGColorTop, clrBGColorBottom], [1, 1], [0x00, 0xFF], mat, SpreadMethod.PAD);
			graphics.drawRoundRect(rcBox.x, rcBox.y, rcBox.width, rcBox.height, roundedRectCornerRadius*2, roundedRectCornerRadius*2);
			graphics.endFill();
			
			// Draw thumb
			graphics.beginGradientFill(GradientType.LINEAR, [clrBGColorTop, clrBGColorBottom], [1, 1], [0x00, 0xFF], mat, SpreadMethod.PAD);
			switch (_nThumbSide) {
				case THUMB_SIDE_TOP:
					graphics.moveTo(_nThumbXY - knThumbWidth/2, rcBox.top);
					graphics.lineTo(_nThumbXY, rcBox.top - knThumbDepth);
					graphics.lineTo(_nThumbXY + knThumbWidth/2, rcBox.top);
					break;
				case THUMB_SIDE_LEFT:
					graphics.moveTo(rcBox.left, _nThumbXY - knThumbWidth/2);
					graphics.lineTo(rcBox.left - knThumbDepth, _nThumbXY);
					graphics.lineTo(rcBox.left, _nThumbXY + knThumbWidth/2);
					break;
				case THUMB_SIDE_RIGHT:
					graphics.moveTo(rcBox.right, _nThumbXY - knThumbWidth/2);
					graphics.lineTo(rcBox.right + knThumbDepth, _nThumbXY);
					graphics.lineTo(rcBox.right, _nThumbXY + knThumbWidth/2);
					break;
				case THUMB_SIDE_BOTTOM:
					graphics.moveTo(_nThumbXY - knThumbWidth/2, rcBox.bottom);
					graphics.lineTo(_nThumbXY, rcBox.bottom + knThumbDepth);
					graphics.lineTo(_nThumbXY + knThumbWidth/2, rcBox.bottom);
					break;
				
				case THUMB_SIDE_NONE:
				default:
					break;
			}
			graphics.endFill();
		}
		
		private function get pointAtRect(): Rectangle {
			if (_uicPointAt != null) {
				return _uicPointAt.getRect(stage);
			} else {
				return _rcPointAt;
			}
		}
		
		private function ValidateShapes(): void {
			if (!_fShapesValid) {
				_fShapesValid = true;
				
				var rcPointAt:Rectangle = pointAtRect; // Global coords. Might be null
				if (rcPointAt != null) {
					var pt:Point = new Point(rcPointAt.x + rcPointAt.width/2, rcPointAt.y + rcPointAt.height/2);
					pt.x += _xShiftFactor * rcPointAt.width;
					pt = globalToContent(pt);
	
					if (pt.x > 0 && pt.x < width && pt.y > 0 && pt.y < height) {
						// Point is inside. Move it out a bit to see if things get better
						var ptOffset:Point = pt.subtract(new Point(width/2, height/2));
						if (ptOffset.length > 0) {
							// Move out in a straight line
							if (Math.abs(pt.x) > Math.abs(pt.y)) pt.y = 0;
							else pt.x = 0;
							ptOffset.normalize(knThumbThreshold);
							pt = pt.add(ptOffset);
						}
					}
		
					if (pt.x > 0 && pt.x < width && pt.y > 0 && pt.y < height) {
						// point is inside
						_nThumbSide = THUMB_SIDE_NONE;
					} else {
						// Figure out which side to put the thumb on.
						// Direction of +,+ means lower right
						var ptDirection:Point = pt.subtract(new Point(width/2, height/2));
						
		/* 				if (ptDirection.x > 0) ptDirection.x -= width/2;
						else ptDirection.x += width/2;
						if (ptDirection.y > 0) ptDirection.y -= height/2;
						else ptDirection.y += height/2;
		 */				
						// Now, ptDirection is distance from center of our box
						_nThumbSide = ptDirection.y >= 0 ? THUMB_SIDE_BOTTOM : THUMB_SIDE_TOP;
						ptDirection.y = Math.abs(ptDirection.y);
						
						// check for sides
						var nHorizSide:Number = ptDirection.x < 0 ? THUMB_SIDE_LEFT : THUMB_SIDE_RIGHT;
						ptDirection.x = Math.abs(ptDirection.x) - width/2;
						ptDirection.y -= height/2;
						
						// Now ptDirection is positive offset from bottom right corner (flipped to this orientation)
						
						if (ptDirection.x > 0 && ptDirection.x > ptDirection.y) {
							_nThumbSide = nHorizSide;
						}
						  
						// Now we know the direction, place it.
						if (_nThumbSide == THUMB_SIDE_BOTTOM || _nThumbSide == THUMB_SIDE_TOP) {
							_nThumbXY = pt.x;
							_nThumbXY = Math.max(_nThumbXY, knLeftMargin + knThumbPadding + roundedRectCornerRadius + knThumbWidth/2);
							_nThumbXY = Math.min(_nThumbXY, width - knRightMargin - knThumbPadding - roundedRectCornerRadius - knThumbWidth/2);
						} else {
							_nThumbXY = pt.y;
							_nThumbXY = Math.max(_nThumbXY, knTopMargin + knThumbPadding + roundedRectCornerRadius + knThumbWidth/2);
							_nThumbXY = Math.min(_nThumbXY, height - knBottomMargin - knThumbPadding - roundedRectCornerRadius - knThumbWidth/2);
						}
					}
				}
				
				DrawShapes();
			}
		}
		
		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			if (_ptPrevSize.x != unscaledWidth || _ptPrevSize.y != unscaledHeight) {
				_fShapesValid = false;
				_ptPrevSize = new Point(unscaledWidth, unscaledHeight);
			}
			ValidateShapes();
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		protected override function measure():void {
			super.measure();
			measuredWidth = 100;
			measuredHeight = 20;
			measuredMinHeight = knTopMargin + knTopPadding + knBottomPadding + knBottomMargin;
			measuredMinWidth = knLeftMargin + knLeftPadding + knRightPadding + knRightMargin;
		}
		
		public function get closeButtonEnabled():Boolean {
			return _closeButtonEnabled;
		}
		public function set closeButtonEnabled(b:Boolean):void {
			_closeButtonEnabled = b;
		}
	}
}