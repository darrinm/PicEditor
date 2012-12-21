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
package controls {
	import events.GenericDocumentEvent;
	import events.ImageDocumentEvent;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import imagine.ImageDocument;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.core.UIComponent;
	import mx.events.PropertyChangeEvent;
	
	import overlays.helpers.Cursor;
	
	public class MiniView extends UIComponent {
		private var _imgv:ImageView;
		private var _imgd:ImageDocument;
		private var _bm:Bitmap;
		private var _shpView:Shape;
		private var _chwImageDocument:ChangeWatcher;
		private var _xMouseDown:int, _yMouseDown:int;
	
		public function set imageView(imgv:ImageView): void {
			buttonMode = true; // so it'll show the system's hand cursor by default
			_imgv = imgv;
			_chwImageDocument = ChangeWatcher.watch(_imgv, "imageDocument", OnImageDocumentChange);
			_imgv.addEventListener("layoutChange", OnLayoutChange);
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
			addEventListener(MouseEvent.MOUSE_WHEEL, OnMouseWheel);
		}
		
		private var _xMouseDelta:Number, _yMouseDelta:Number;
		
		private function OnMouseDown(evt:MouseEvent): void {
			Cursor.csrHandGrab.Apply();
			Util.CaptureMouse(stage, OnCapturedMouseMove, OnCapturedMouseUp);
			
			// If the mouse is outside the view rect, center the view rect over the mouse
			var rcView:Rectangle = GetViewRect();
			if (!rcView.contains(evt.localX, evt.localY)) {
				_xMouseDelta = -(rcView.width / _bm.scaleX) / 2;
				_yMouseDelta = -(rcView.height / _bm.scaleY) / 2;
				PositionViewAt(_bm.mouseX + _xMouseDelta, _bm.mouseY + _yMouseDelta);
			} else {
				_xMouseDelta = (rcView.x / _bm.scaleX) - _bm.mouseX;
				_yMouseDelta = (rcView.y / _bm.scaleY) - _bm.mouseY;
			}
		}
		
		private function OnCapturedMouseMove(evt:MouseEvent): void {
			evt.stopImmediatePropagation();
			PositionViewAt(_bm.mouseX + _xMouseDelta, _bm.mouseY + _yMouseDelta);
			evt.updateAfterEvent();
		}
		
		private function OnCapturedMouseUp(evt:MouseEvent): void {
			UpdateCursor(evt);
		}
		
		private function OnMouseMove(evt:MouseEvent): void {
			if (evt.buttonDown)
				return;
			evt.stopImmediatePropagation();
			UpdateCursor(evt);
			evt.updateAfterEvent();
		}
		
		private function UpdateCursor(evt:MouseEvent): void {
			var rcView:Rectangle = GetViewRect();
			if (rcView.contains(evt.localX, evt.localY)) {
				Cursor.csrHand.Apply();
			} else {
				Cursor.csrSystem.Apply();
			}
		}
		
		// Zoom so the point the mouse cursor is at will stay in place (subject
		// to the usual constraints)
		private function OnMouseWheel(evt:MouseEvent): void {
			// Translate the mouseX/Y into ImageView relative coords
			var x:int = _imgv.width / 2;
			var y:int = _imgv.height / 2;
			
			// Send a faked-up mousewheel event over to the ImageView
			_imgv.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_WHEEL, true, false,
					x, y, evt.relatedObject, evt.ctrlKey, evt.altKey, evt.shiftKey, evt.buttonDown, evt.delta));
			UpdateCursor(evt);
		}
		
		private function OnImageDocumentChange(evt:PropertyChangeEvent): void {
			if (_imgd != null) {
				_imgd.removeEventListener(ImageDocumentEvent.BITMAPDATA_CHANGE, OnDocumentBitmapDataChange);
				_imgd = null;
			}
			
			if (evt.newValue != null) {
				_imgd = evt.newValue as ImageDocument;
				// Raise the priority of this event listener above the ImageView's so we'll
				// Get the BITMAPDATA_CHANGE notification before the layout change.
				_imgd.addEventListener(ImageDocumentEvent.BITMAPDATA_CHANGE, OnDocumentBitmapDataChange, false, 100);
			}
			UpdateBitmap();
		}
		
		private function OnDocumentBitmapDataChange(evt:GenericDocumentEvent): void {
			UpdateBitmap();
		}
		
		private function OnLayoutChange(evt:Event): void {
			UpdateViewRect();
		}
		
		private function UpdateBitmap(): void {
			if (_bm) {
				removeChild(_bm);
				_bm = null;
			}
			
			if (_imgd) {
				var bmd:BitmapData = _imgd.composite;
				_bm = new Bitmap(bmd);
				_bm.smoothing = true;
				var ptT:Point = Util.GetLimitedImageSize(bmd.width, bmd.height, maxWidth, maxHeight);
				width = ptT.x;
				height = ptT.y;
				_bm.scaleX = ptT.x / Number(bmd.width);
				_bm.scaleY = ptT.y / Number(bmd.height);
				
				// Put the bitmap below any other MiniView children
				addChildAt(_bm, 0);
				
				// Force the parent to reposition the MiniView according to its new dimensions
				(parent as UIComponent).validateNow();
			}
		}
		
		// Draw a rectangle representing the view area with the surrounding area muted
		private function UpdateViewRect(): void {
			if (_bm == null)
				return;
				
			if (_shpView == null) {
				_shpView = new Shape();
				// Place the view rect on top
				addChildAt(_shpView, numChildren);
			}
			
			with (_shpView.graphics) {
				clear();
			
				var rcBounds:Rectangle = new Rectangle(0, 0, _bm.width, _bm.height);
				var rcView:Rectangle = GetViewRect();
				
				lineStyle();
				beginFill(0x000000, 0.4);
				moveTo(0, 0);
				lineTo(rcBounds.width, 0);
				lineTo(rcBounds.width, rcBounds.height);
				lineTo(0, rcBounds.height);
				lineTo(0, 0);
		
				lineStyle(1, 0xffffff, 1.0);
				var xL:int = int(rcView.left) - 1;
				var xR:int = Math.min(Math.ceil(rcView.right), _bm.width);
				var yT:int = int(rcView.top) - 1;
				var yB:int = Math.min(Math.ceil(rcView.bottom), _bm.height);
				moveTo(xL, yT);
				lineTo(xR, yT);
				lineTo(xR, yB);
				lineTo(xL, yB);
				lineTo(xL, yT);
				endFill();
			}
		}
		
		// Return the view rectangle in mini-bitmap (_bm) relative coordinates
		private function GetViewRect(): Rectangle {
			var rcdView:Rectangle = _imgv.GetViewRect();
			var rcView:Rectangle = new Rectangle(rcdView.x * _bm.scaleX, rcdView.y * _bm.scaleY,
					rcdView.width * _bm.scaleX, rcdView.height * _bm.scaleY);
			return rcView;
		}
		
		private function PositionViewAt(xdView:int, ydView:int): void {
			var ptvView:Point = _imgv.PtvFromPtd(new Point(xdView, ydView));
			_imgv.viewX = -ptvView.x;
			_imgv.viewY = -ptvView.y;
		}
	}
}
