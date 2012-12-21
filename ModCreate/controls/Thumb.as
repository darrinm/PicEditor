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
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.controls.Image;

	/**
	 * Dispatched when the thumb position changes (and needs to be redrawn)
	 */
	[Event(name="change", type="flash.events.Event")]
	
	public class Thumb extends Image
	{
		private var _tsldrParent:ThumbSlider;
		private var _nID:Number = -1;
		
		private var _fMouseDown:Boolean = false;
		private var _cxMouseDragOffset:Number = 0;
		private var _xMin:Number = 0;
		private var _xMax:Number = 0;
		
		public function Thumb(tsldrParent:ThumbSlider, nID:Number): void {
			super();
			_tsldrParent = tsldrParent;
			_nID = nID;
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
		}
		
		public function set xMin(n:Number): void {
			_xMin = n;
		}
		
		public function set xMax(n:Number): void {
			_xMax = n;
		}
		
		// Measure distance from an event in the x dimension
		public function DistFrom(evt:MouseEvent): Number {
			var ptClick:Point = new Point(evt.stageX, evt.stageY);
			ptClick = globalToLocal(ptClick);
			return Math.abs(width/2 - ptClick.x);
		}
		
		// This may be called by the container. Don't use localX, localY
		public function OnMouseDown(evt:MouseEvent): void {
			if (stage) {
				_fMouseDown = true;
				stage.addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
				// Move the thumb to the mouse
				var ptClick:Point = new Point(evt.stageX, evt.stageY);
				ptClick = globalToLocal(ptClick);
				_cxMouseDragOffset -= ptClick.x + width/2;
			}
		}
		
		protected function moveToEvt(evt:MouseEvent): void {
			var ptMouse:Point = globalToLocal(new Point(evt.stageX, evt.stageY));
			// If the user clicked 10 pixels to the left of the left edge of our thumb, ptMouse.x == -10
			moveTo(x + ptMouse.x - width/2);
		}
		
		protected function moveTo(xTo:Number): void {
			xTo = Math.round(xTo); 
			if (xTo < _xMin) xTo = _xMin;
			if (xTo > _xMax) xTo = _xMax;
			this.x = xTo;
			dispatchEvent(new Event("change"));
		}
		
		protected function OnMouseMove(evt:MouseEvent): void {
			moveToEvt(evt);
		}
		
		protected function OnMouseUp(evt:MouseEvent): void {
			moveToEvt(evt);
			stage.removeEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
		}
	}
}