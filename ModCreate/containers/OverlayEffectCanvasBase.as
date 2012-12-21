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
	import events.ImageViewEvent;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import imagine.ImageDocument;
	
	import overlays.helpers.Cursor;
	
	import util.GlobalEventManager;

	public class OverlayEffectCanvasBase extends EffectCanvasBase implements IOverlay
	{
		protected var _fOverlayMouseDown:Boolean = false;
		protected var _xFocus:Number = 0;
		protected var _yFocus:Number = 0;
		protected var _mcOverlay:MovieClip = null;
		private var _imgdPrev:ImageDocument = null;
		
		protected var _xDragOffset:Number = 0;
		protected var _yDragOffset:Number = 0;
		protected var _fMouseOver:Boolean = false;
		protected var _fLiveUpdate:Boolean = false;

		public function set liveUpdate(fLiveUpdate:Boolean): void {
			_fLiveUpdate = fLiveUpdate;
		}
		
		[Inspectable]
		[Bindable(event="changeFocus")]
		public function get xFocus(): Number {
			return _xFocus;
		}
		
		public function set xFocus(xFocus:Number): void {
			_xFocus = Math.round(xFocus);
		}
		
		[Inspectable]
		[Bindable(event="changeFocus")]
		public function get yFocus(): Number {
			return _yFocus;
		}
		
		public function set yFocus(yFocus:Number): void {
			_yFocus = Math.round(yFocus);
		}

		public override function Select(efcnvCleanup:NestedControlCanvasBase):Boolean {
			var fWasSelected:Boolean = IsSelected();
			var fSelected:Boolean = super.Select(efcnvCleanup);
			if (fSelected) {
				if (!fWasSelected) {
					GlobalEventManager.constraintMode = GlobalEventManager.BRUSH_CONSTRAINT;
					_imgv.addEventListener(ImageViewEvent.ZOOM_CHANGE, OnZoom);
					_imgv.addEventListener(MouseEvent.ROLL_OUT, OnRollOut);
					_imgv.addEventListener(MouseEvent.ROLL_OVER, OnRollOver);
				}
				_mcOverlay = _imgv.CreateOverlay(this);
				_imgv.overlayCursor = Cursor.csrSystem; // Turn off the move cursor because we handle drags
			}
			return fSelected;
		}
		
		public override function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null): void {
			if (IsSelected()) {
				_imgv.removeEventListener(ImageViewEvent.ZOOM_CHANGE, OnZoom);
				_imgv.removeEventListener(MouseEvent.ROLL_OUT, OnRollOut);
				_imgv.removeEventListener(MouseEvent.ROLL_OVER, OnRollOver);
			}
			if (_imgv && _mcOverlay) {
				_imgv.DestroyOverlay(_mcOverlay);
				_mcOverlay = null;
			}
			super.Deselect(fForceRollOutEffect, efcvsNew);
		}
		
		public function OverlayEffectCanvasBase() {
			super();
			this.addEventListener("changeImage", OnImageChange);
		}
		
		public function OnImageChange(evt:Event): void {
			if (_imgd && _imgd != _imgdPrev) {
				_imgdPrev = _imgd;
				_xFocus = Math.round(_imgd.width / 2);
				_yFocus = Math.round(_imgd.height / 2);
				dispatchEvent(new Event("changeFocus"));
			}
		}

		public function hitDragArea(): Boolean {
			return false;
		}

		protected function SetFocus( x:Number, y:Number ): void {
			_xFocus = x;
			_yFocus = y;			
		}
		
		// xv and yv are component coordinates (matching the view), probably from the overlay
		public function MoveFocus(xv:Number, yv:Number): void {
			var ptd:Point = PtdFromViewCoords(xv, yv);
			SetFocus(Math.round(ptd.x + _xDragOffset), Math.round(ptd.y + _yDragOffset));
			
			dispatchEvent(new Event("changeFocus")); // Dispatch this before updating
			// The above event will make sure our image operation and mask are up to
			// date when we update the overlay and the bitmap.
			UpdateOverlay();
			if (_fLiveUpdate) {
				invalidateDisplayList();
				validateDisplayList();
			}
		}
		
		public function get overlayMouseAsPtd(): Point {
			if (!_mcOverlay) return null;
			
			// Force ImageView relayout to account for the new zoom before using mouse
			// coordinates that are dependent on it.
			_imgv.validateDisplayList();

			var pt:Point = _mcOverlay.globalToLocal(GlobalEventManager.GetAxisConstrainedMousePosition());
			return PtdFromViewCoords(pt.x, pt.y);
		}

		public function PtdFromViewCoords(xv:Number, yv:Number): Point {
			return _imgv.PtdFromPtv(new Point(xv, yv));
		}
		
		public function OnOverlayPress(evt:MouseEvent): Boolean {
			ShowOverlay();
			_fOverlayMouseDown = true;
			_xDragOffset = 0;
			_yDragOffset = 0;
			
			if (!hitDragArea()) MoveFocus(_mcOverlay.mouseX, _mcOverlay.mouseY);
			// Set up drag offsets based on current x,y
			var ptd:Point = overlayMouseAsPtd;
			_xDragOffset = _xFocus - ptd.x;
			_yDragOffset = _yFocus - ptd.y;
			
			return true;
		}
		
		public function OnOverlayRelease(): Boolean {
			if (!_fMouseOver) HideOverlay();
			_fOverlayMouseDown = false;
			UpdateOverlay();
			invalidateDisplayList();
			validateDisplayList();
			return true;
		}

		public function OnOverlayMouseDrag(): Boolean {
			MoveFocus(_mcOverlay.mouseX, _mcOverlay.mouseY);
			return true;
		}
		
		public function OnOverlayMouseMove(): Boolean {
			if (_fOverlayMouseDown) return OnOverlayMouseDrag();
			else return false;
		}

		public function OnZoom(evt:Event): void {
			UpdateOverlay();
		}

		public function OnRollOut(evt:Event): void {
			_fMouseOver = false;
			if (!_fOverlayMouseDown) HideOverlay();
		}

		public function OnRollOver(evt:Event): void {
			_fMouseOver = true;
			ShowOverlay();
		}

		public function OnOverlayMouseMoveOutside(): Boolean {
			if (_fOverlayMouseDown) return OnOverlayMouseDrag();
			else return false;
		}

		public function OnOverlayReleaseOutside(): Boolean {
			return OnOverlayRelease();
		}
		
		public function OnOverlayDoubleClick(): Boolean {
			return false;
		}

		public function UpdateOverlay(): void {
			// Default is do nothing. Override in sub-classes
		}
		
		public function ShowOverlay(): void {
			if (_mcOverlay) UpdateOverlay();
			if (_mcOverlay) _mcOverlay.visible = true;
		}
		
		public function HideOverlay(): void {
			if (_mcOverlay) _mcOverlay.visible = false;
		}
		
		public function get overlayVisible(): Boolean {
			return _mcOverlay && _mcOverlay.visible;
		}

		public override function OnOpChange():void {
			if (overlayVisible) {
				UpdateOverlay();
			}
			super.OnOpChange();
		}
	}
}
