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
package effects
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	
	import overlays.helpers.Cursor;
	
	import util.SplineInterpolator;

	[Event(name="change", type="flash.events.Event")]
	[Event(name="edited", type="flash.events.Event")]
	
	public class CurveBox extends UIComponent
	{
		public var _apts:Array = new Array();

		private var _bmdBackground:BitmapData = null;
		[Bindable] public var xDrag:Number = -1;
		[Bindable] public var yDrag:Number = -1;
		[Bindable] public var strXDrag:String = "";
		[Bindable] public var strYDrag:String = "";
		[Bindable] public var pointsString:String = "";
		[Bindable] public var pointsArray:Array = null;
		
		private var _fHasCursor:Boolean = false;
		private var _fMouseDown:Boolean = false;
		private var knBorderWidth:Number = 2;
		private var _acbSubCurves:Array = [];
		
		private var _clrLine:Number = 0;		
		private var _clrBg:uint = 0xffffff;
		private var _clrBorder:uint = 0x999999;
		
		private const _clrGrid:uint = 0xe5e5e5;
		private const _clrCrossHairs:uint = 0xcccccc;

		private var _iDrag:Number = -1; // The point being dragged, -1 if none
		private var _si:SplineInterpolator = null;
		
		private var _fRemovedPoint:Boolean = false;
		
		public function set bmdBackground(bmd:BitmapData) : void {
			_bmdBackground = bmd;
			invalidateProperties();
		}
		
		public function set inPointsArray(apts:Array): void {
			setPoints(apts);
		}
		
		// apts is either an array of numbers (first x, then y, etc) or an array of points.
		public function setPoints(apts:Array): void {
			if (apts[0] is Number) {
				_apts = [];
				// Convert an array of numbers into an array of points.
				for (var i:Number = 0; (i+1) < apts.length; i += 2) {
					_apts.push(new Point(apts[i], apts[i+1]));
				}
			} else if (apts[0] is Point) {
				_apts = apts.slice(); // Copy the array of points so we don't accidentally modify it.
			} else {
				_apts = [];
				for each (var obPoint:Object in apts)
					_apts.push(new Point(obPoint.x, obPoint.y));
			}
			_si = null;
			invalidateProperties();
		}
		
		public function set subCurves(acbSubCurves:Array): void {
			_acbSubCurves = acbSubCurves;
			if (_acbSubCurves == null) _acbSubCurves = [];
			invalidateProperties();
		}
		
		[Bindable]
		public function set backgroundColor(clrBg:uint): void {
			_clrBg = clrBg;
			invalidateProperties();
		}
		public function get backgroundColor():uint {
				return _clrBg;
		}
		
		[Bindable]
		public function set lineColor(clrLine:uint): void {
			_clrLine = clrLine;
			invalidateProperties();
		}
		public function get lineColor():uint {
				return _clrLine;
		}
		
		[Bindable]
		public function set borderColor(clrBorder:uint): void {
			_clrBorder = clrBorder;
			invalidateProperties();
		}
		public function get borderColor():uint {
				return _clrBorder;
		}
		
		public function CurveBox() {
			_apts.push(new Point(0,0));
			_apts.push(new Point(255,255));
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
			addEventListener(MouseEvent.ROLL_OUT, OnRollOut);
			addEventListener(MouseEvent.ROLL_OVER, OnRollOver);
			ChangeWatcher.watch(this, "width", OnSizeChange);
			ChangeWatcher.watch(this, "height", OnSizeChange);
		}
		
		public function set startOffset(n:Number): void {
			_apts[0] = new Point(-n, -n);
			_si = null;
			invalidateProperties();
		}
		
		public function set endOffset(n:Number): void {
			_apts[_apts.length-1] = new Point(255+n, 255+n);
			_si = null;
			invalidateProperties();
		}
		
		private function OnSizeChange(evt:Event): void {
			invalidateProperties();
		}
		
		private function get blackPoint(): Point {
			return _apts[0];
		}
		
		private function get whitePoint(): Point {
			return _apts[_apts.length-1];
		}
		
		public function get spline(): SplineInterpolator {
			if (_si == null) {
				if (_apts == null) return null;
				_si = new SplineInterpolator();
				for each (var pt:Point in _apts) {
					_si.add(pt.x, pt.y);
				}
			}

			return _si;
		}
		
		// Returns mouse click behavior
		// n >= 0 means the mouse will drag point with index == n
		// n == -1 means the mouse will insert a new point
		// n < -1 means the mouse will do nothing (arrow cursor)
		// Point is in curve coordinates, e.g. 0,0 is black, black, etc.
		public function getHitZone(pt:Point): Number {
			// First, test for out of bounds
			if (pt.x < -knBorderWidth || pt.y < -knBorderWidth || pt.x > 257 || pt.y > 257) {
				return -knBorderWidth; // Out of bounds
			}
			// Left edge
			if (pt.x <= blackPoint.x) return 0;
			// Right edge
			if (pt.x >= whitePoint.x) return _apts.length-1;
			
			// Now check for line nearness
 			var y:Number = Math.max(0,Math.min(255,spline.Interpolate(pt.x)));
 			if (Math.abs(y - pt.y) <= 32) {
 				// close to the line
 				// Find the nearest point
 				var nClosestPoint:Number = -1;
 				var nPrevClosestDist:Number = 9; // One greater than our min dist
 				for (var i:Number = 0; i < _apts.length; i++) {
 					var nDist:Number = Math.abs(_apts[i].x - pt.x);
 					if (nDist < nPrevClosestDist) {
 						nPrevClosestDist = nDist;
 						nClosestPoint = i;
 					} 
 					if (_apts[i].x > pt.x) break;
 				}
 				return nClosestPoint;
 			}
 			return -2; // Not near line
		}
		
		// Returns true if this generates an interesting array
		// In other words, more than one point and not (0,0), (255,255)
		public function get isCurve(): Boolean {
			if (_apts.length < 2) return false;
			for each (var pt:Point in _apts) {
				if (pt.x != pt.y) return true; // This is not the default straight line
			}
			return false;
		}
		
		private function InsertPointBefore(iInsertBefore:Number, ptNew:Point): void {
			if (iInsertBefore >= 0 && iInsertBefore <= _apts.length) {
				for (var i:Number = _apts.length - 1; i >= iInsertBefore; i--) {
					_apts[i+1] = _apts[i];
				}
				_apts[iInsertBefore] = new Point(ptNew.x, ptNew.y);
			}
		}

		private function RemovePoint(iRemove:Number): void {
			if (iRemove > -1 && iRemove < _apts.length) {
				for (var i:Number = iRemove; i < (_apts.length-1); i++) {
					_apts[i] = _apts[i+1];
				}
			}
			_apts.length -= 1;
		}
		
		public function OnMouseDown(evt:MouseEvent): void {
			var ptCurveClick:Point = MouseEventToCurvePoint(evt);
			var nHitPoint:Number = getHitZone(ptCurveClick);
			if (nHitPoint > -2) {
				if (evt.ctrlKey) {
					// Remove a point, if clicked
					// Do not remove endpoints 
					if (nHitPoint >= 1 && nHitPoint < (_apts.length-1)) {
						RemovePoint(nHitPoint);
						_si = null;
						invalidateProperties();
						dispatchEvent(new Event("edited"));
					}
				} else {
					if (nHitPoint >= 0) {
						_iDrag = nHitPoint;
					} else {
						// Insert a point. Figure out where.
						var iInsertBefore:Number = FindFirstPointAfter(ptCurveClick.x);
						if (iInsertBefore != -1) {
							InsertPointBefore(iInsertBefore, ptCurveClick);
							_iDrag = iInsertBefore;
							invalidateProperties();
							_si = null;
						}
					}
					if (_iDrag > -1) {
						if (stage) {
							stage.addEventListener(MouseEvent.MOUSE_UP, OnMouseUp, false);
							stage.addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove, false);
							SetCursor(Cursor.csrMoveSmall);
						}
						dispatchEvent(new Event("edited"));
					}
				}
			} else {
				if (evt.ctrlKey && evt.altKey && evt.shiftKey) {
					// ctrl-alt-shift click on background reveals editable coords
					var ti:TextInput = new TextInput();
					ti.text = pointsString;
					ti.width = width;
					PopUpManager.addPopUp(ti, this, true);
					PopUpManager.centerPopUp(ti);
					var re:RegExp = /\{x\:(\d+)\, y\:(\d+)\}/gi;
					ti.addEventListener(KeyboardEvent.KEY_DOWN, function(evt:KeyboardEvent): void {
						if (evt.keyCode != Keyboard.ENTER)
							return;
							
						_apts.length = 0;
						while (true) {
							var obResult:Object = re.exec(ti.text);
							if (obResult == null)
								break;
							_apts.push(new Point(Number(obResult[1]), Number(obResult[2])));									
						}
						PopUpManager.removePopUp(ti);
						invalidateProperties();
						_si = null;
						dispatchEvent(new Event("edited"));

					});
				}
			}
		}
		public function OnMouseUp(evt:MouseEvent): void {
			if (_iDrag > -1) {
				if (stage) {
					stage.removeEventListener(MouseEvent.MOUSE_UP, OnMouseUp, false);
					stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove, false);
					UpdateCursor(evt);
				}
				if (!_fRemovedPoint) {
					invalidateProperties();
				}
			}
			xDrag = -1;
			yDrag = -1;
			strXDrag = "";
			strYDrag = "";
			_fRemovedPoint = false;
			_iDrag = -1;
		}
		
		private function OnRollOut(evt:MouseEvent): void {
			strXDrag = "";
			strYDrag = "";
			SetCursor(null);
		}
		
		private function OnRollOver(evt:MouseEvent): void {
			if (evt.buttonDown) {
				SetCursor(Cursor.csrMoveSmall);
			}
		}
		
		private function MouseEventToCurvePoint(evt:MouseEvent): Point {
			return MouseToCurvePoint(globalToLocal(new Point(evt.stageX, evt.stageY)));
		}
		
		private function MouseToCurvePoint(ptMouse:Point): Point {
			var nViewSize:Number = getViewSize();
			var x:Number = ((ptMouse.x - knBorderWidth) * 255 / nViewSize);
			var y:Number = ((knBorderWidth + nViewSize - ptMouse.y) * 255 / nViewSize);
			return new Point(x, y);
		}
		
		private function CurveToMousePoint(ptCurve:Point): Point {
			var nViewSize:Number = getViewSize();
			var x:Number = (ptCurve.x * nViewSize / 255 + knBorderWidth);
			var y:Number = (knBorderWidth + nViewSize) - (ptCurve.y * nViewSize / 255);
			return new Point(x, y);
		}
		
		private function HitZoneToCursor(nHitZone:Number): Cursor {
			if (nHitZone == -1) return Cursor.csrCross;
			if (nHitZone >= 0) return Cursor.csrMoveSmall;
			return Cursor.csrArrow;
		}
		
		private function SetCursor(csr:Cursor): void {
			if (csr == null) {
				if (_fHasCursor) {
					_fHasCursor = false;
					stage.removeEventListener(MouseEvent.ROLL_OUT, OnRollOut);
					Cursor.RemoveAll();
				}
			} else {
				// Setting the cursor
				if (!_fHasCursor) {
					_fHasCursor = true;
					stage.addEventListener(MouseEvent.ROLL_OUT, OnRollOut);
				}
				csr.Apply();
			}
		}
		
		private function UpdateCursor(evt:MouseEvent): void {
			var ptCurve:Point = MouseEventToCurvePoint(evt);
			SetCursor(HitZoneToCursor(getHitZone(ptCurve)));
		}
		
		private function OnMouseMove(evt:MouseEvent): void {
			var ptCurve:Point = MouseEventToCurvePoint(evt);
			if (!evt.buttonDown) {
				ptCurve.x = Math.round(ptCurve.x);
				ptCurve.y = Math.round(ptCurve.y);
				if (ptCurve.x >= 0 && ptCurve.x <= 255 && ptCurve.y >= 0 && ptCurve.y <= 255) {
					strXDrag = ptCurve.x.toString();
					strYDrag = ptCurve.y.toString();
				} else {
					strXDrag = "";
					strYDrag = "";
				}
				// Update the cursor
				UpdateCursor(evt);
			} else if (_iDrag > -1) {
				var nMinX:Number = 0;
				var nMaxX:Number = 255;
				if (_iDrag > 0) nMinX = (_apts[_iDrag - 1] as Point).x + 4;
				var iNextPoint:Number = _iDrag + (_fRemovedPoint?0:1);
				if (iNextPoint < _apts.length) nMaxX = (_apts[iNextPoint] as Point).x - 4;
				const nMinY:Number = 0;
				const nMaxY:Number = 255;
				
				
				// Test for out of bounds
				var fOutOfBounds:Boolean = false;
				if ((_iDrag > 0 && _iDrag < (_apts.length - 1)) || _fRemovedPoint) {
					// Point can be removed. Check for bounds
					fOutOfBounds = ptCurve.x < (nMinX-1) || ptCurve.x > (nMaxX + 1) || ptCurve.y < (nMinY-1) || ptCurve.y > (nMaxY+1);
				}
				if (fOutOfBounds != _fRemovedPoint) {
					if (fOutOfBounds) {
						xDrag = -1;
						yDrag = -1;
						strXDrag = "";
						strYDrag = "";
						// Remove the point
						invalidateProperties();
						_si = null;
						RemovePoint(_iDrag);
					} else {
						// Insert a point (the position will be set below)
						InsertPointBefore(_iDrag, new Point(0,0));
					}
					_fRemovedPoint = fOutOfBounds;
				}
				if (!_fRemovedPoint) {
					var ptDrag:Point = _apts[_iDrag] as Point;
					xDrag = Math.max(Math.min(Math.round(ptCurve.x), nMaxX), nMinX);
					yDrag = Math.max(Math.min(Math.round(ptCurve.y), nMaxY), nMinY);
					strXDrag = xDrag.toString();
					strYDrag = yDrag.toString();
					ptDrag.x = xDrag;
					ptDrag.y = yDrag;
					invalidateProperties();
					_si = null;
				}
			}
		}
		
		// Returns -1 if none found
		private function FindNearestPoint(x:Number, y:Number): Number {
			var iNearestPoint:Number = -1;
			var nNearestDist:Number = Number.MAX_VALUE;
			const knMaxDist:Number = 16;
			
			var i:Number = 0;
			for each (var pt:Point in _apts) {
				var nDist:Number = Math.sqrt((pt.x - x)*(pt.x - x) + (pt.y - y)*(pt.y - y));
				if (nDist < nNearestDist) {
						nNearestDist = nDist;
						iNearestPoint = i;
				}
				i++;
			}
			if (nNearestDist > knMaxDist) return -1;
			return iNearestPoint;
		}

		private function FindFirstPointAfter(x:Number): Number {
			var i:Number = 0;
			for each (var pt:Point in _apts) {
				if (pt.x >= x) return i;
				i++;
			}
			return -1;
		}

		
		protected override function measure():void {
			super.measure();
			measuredWidth = 256 + knBorderWidth * 2;
			measuredHeight = 256 + knBorderWidth * 2;
			measuredMinWidth = 50;
			measuredMinHeight = 50;
		}
		
		private function MoveToCurve(ptCurve:Point): void {
			var ptDraw:Point = CurveToMousePoint(ptCurve);
			graphics.moveTo(ptDraw.x, ptDraw.y);
		}
			
		private function LineToCurve(ptCurve:Point): void {
			var ptDraw:Point = CurveToMousePoint(ptCurve);
			graphics.lineTo(ptDraw.x, ptDraw.y);
		}
		
		private function DrawCurve(si:SplineInterpolator, clr:Number, nAlpha:Number=1): void {
			graphics.lineStyle(1, clr, nAlpha, true);
			// ptCurve keeps track of where we are in the curve
			var ptCurve:Point = new Point();
			// ptDraw keeps track of x drawing position
			// Start drawing at the end of the border
			var ptDraw:Point = new Point(knBorderWidth,0);
			// Convert the x drawing position into a correspoinding curve position
			ptCurve = MouseToCurvePoint(ptDraw);
			ptCurve.y = Math.max(Math.min(si.Interpolate(ptCurve.x), 255), 0);
			MoveToCurve(ptCurve);
			while (ptCurve.x <= 255) { // Loop until we go beyond the end of the curve
				ptDraw.x += 1;
				// Convert the x drawing position into a correspoinding curve position
				ptCurve = MouseToCurvePoint(ptDraw);
				ptCurve.y = Math.max(Math.min(si.Interpolate(ptCurve.x), 255), 0);
				LineToCurve(ptCurve);
			}
		}
		
		protected function getViewSize(): Number {
			return Math.max(1,Math.min(width - 2 * knBorderWidth, height - 2 * knBorderWidth));
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			var nViewSize:Number = getViewSize();
			if (nViewSize < 2) return;
			
			var gr:Graphics = this.graphics;
			gr.clear();
			gr.beginFill(backgroundColor);
			if (_bmdBackground)  {
				var mat:Matrix = new Matrix();
				mat.translate(knBorderWidth, knBorderWidth);
				gr.beginBitmapFill(_bmdBackground, mat);
			}
			gr.drawRect(0,0,nViewSize+knBorderWidth*2,nViewSize+knBorderWidth*2);
			gr.endFill();
	
			gr.lineStyle(1, 0, 1, true);
			gr.lineStyle(1, _clrBorder);
			gr.moveTo(0,0);
			gr.lineTo(0, nViewSize+knBorderWidth*2);
			gr.lineTo(nViewSize+knBorderWidth*2, nViewSize+knBorderWidth*2);
			gr.lineTo(nViewSize+knBorderWidth*2, 0);
			gr.lineTo(0, 0);
			
			// Draw child curves
			for each (var cb:CurveBox in _acbSubCurves) {
				if (cb.isCurve) {
					DrawCurve(cb.spline, cb.lineColor, 0.4);
				}
			}
	
			// Draw the grid
			gr.lineStyle(1, _clrGrid, 1, true);
			var anGridLines:Array = [64, 128, 191];
			for each (var n:Number in anGridLines) {
				// Top to bottom
				MoveToCurve(new Point(n, 0));
				LineToCurve(new Point(n, 255));
				// Right to left
				MoveToCurve(new Point(0, n));
				LineToCurve(new Point(255, n));
			}
			MoveToCurve(new Point(0,0));
			LineToCurve(new Point(255, 255));
			
			var ptDraw:Point;
			
			// If we are dragging a point, draw cross hairs
			if (_iDrag > -1 && !_fRemovedPoint) {
				gr.lineStyle(1, _clrCrossHairs, 1, true);
				var ptCurve:Point = _apts[_iDrag];
				MoveToCurve(new Point(ptCurve.x,0));
				LineToCurve(new Point(ptCurve.x,255)); 
				MoveToCurve(new Point(0, ptCurve.y));
				LineToCurve(new Point(255, ptCurve.y)); 
			}

			// Draw the points
			gr.lineStyle(1, _clrLine, 1, false);
			ptDraw = CurveToMousePoint(new Point(64,128));
			
			var strPoints:String = "[";
			var aobPoints:Array = new Array();
			for each (var pt:Point in _apts) {
				ptDraw = CurveToMousePoint(pt);
				gr.drawCircle(ptDraw.x+.5, ptDraw.y+.5, 3.5);
				if (strPoints.length > 1) strPoints += ", ";
				strPoints += "{x:" + pt.x + ", y:" + pt.y + "}";
				aobPoints.push({x:pt.x, y:pt.y});
			}
			strPoints += "]";
			pointsString = strPoints;
			pointsArray = aobPoints;
	
			// Draw the curve
			DrawCurve(spline, lineColor);
			
			dispatchEvent(new Event("change"));
		}
	}
}
