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
// UNDONE: escape key to cancel color change

package controls {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.containers.Canvas;
	import mx.core.FlexSprite;
	import mx.managers.SystemManager;
	
	import overlays.helpers.Cursor;
	
	import util.VBitmapData;

	[Event(name="change", type="flash.events.Event")]
	[Event(name="complete", type="flash.events.Event")]
   
	public class EyeDropperButton extends Canvas {
		private var _clrLive:Number = 0;
		protected var _bmdSnapshot:BitmapData;
		private var _sprModal:FlexSprite;
		
		public function EyeDropperButton() {
			addEventListener(MouseEvent.CLICK, OnClick);
		}
		
		[Inspectable]
		[Bindable(event="change")]
		public function set color(clr:Number): void {
			setStyle("backgroundColor", clr);
			dispatchEvent(new Event("change"));
		}
		
		public function get color(): Number {
			return getStyle("backgroundColor") as Number;
		}
		
		private function OnClick(evt:MouseEvent): void {
			// Show the eye-dropper cursor
			Cursor.csrEyedropper.Apply();
			
			// Watch mouse moves so we can update the color to whatever the mouse is over
			// when it is outside the ColorPicker.
			_bmdSnapshot = new VBitmapData(stage.stageWidth, stage.stageHeight, true, 0xffffffff, "Eye dropper snapshot");
			try {
				_bmdSnapshot.draw(stage);
			} catch (err:Error) {
				// The draw above can fail if DisplayObjects on the stage don't allow crossdomain access.
				if (PicnikBase.app.zoomView != null) {
					var mat:Matrix = new Matrix();
					var pt:Point = PicnikBase.app.zoomView.localToGlobal(new Point());
					mat.translate(pt.x, pt.y);
					_bmdSnapshot.draw(PicnikBase.app.zoomView, mat);
				}
			}
			
			// Throw up an overlay covering the whole SWF so we can swallow all mouse events.
			_sprModal = new FlexSprite();
			_sprModal.tabEnabled = false;
			_sprModal.alpha = 0;
			var gr:Graphics = _sprModal.graphics;
			var rcScreen:Rectangle = systemManager.screen;
			gr.clear()
			gr.beginFill(0xffffff, 100);
			gr.drawRect(rcScreen.x, rcScreen.y, rcScreen.width, rcScreen.height);
			gr.endFill();
			
	        _sprModal.addEventListener(MouseEvent.MOUSE_MOVE, OnModalMouseMove);
	        _sprModal.addEventListener(MouseEvent.MOUSE_DOWN, OnModalMouseDown);
//	        _sprModal.addEventListener(MouseEvent.MOUSE_WHEEL, OnModalMouseWheel);
	       
	        // Set the resize handler so the modal object can stay the size of the screen
	        systemManager.addEventListener(Event.RESIZE, OnSystemManagerResize);
	       
	        // Add the modal sprite on top of everything
			systemManager.rawChildren.addChild(_sprModal);
		}
		
		private function OnSystemManagerResize(evt:Event): void {
			if (_sprModal) {
		        var rcScreen:Rectangle = SystemManager(evt.target).screen; 
	            _sprModal.width = rcScreen.width;
	            _sprModal.height = rcScreen.height;
	            _sprModal.x = rcScreen.x;
	            _sprModal.y = rcScreen.y;
	  		}
		}

		private function Cleanup(): void {
			Cursor.csrSystem.Apply();
			DisposeSnapshot();
			if (_sprModal) {
		        _sprModal.removeEventListener(MouseEvent.MOUSE_MOVE, OnModalMouseMove);
		        _sprModal.removeEventListener(MouseEvent.MOUSE_DOWN, OnModalMouseDown);
//		        _sprModal.removeEventListener(MouseEvent.MOUSE_DOWN, OnModalMouseWheel);
		        systemManager.rawChildren.removeChild(_sprModal);
		        _sprModal = null;
			}
			dispatchEvent(new Event(Event.COMPLETE));
		}

		private function OnModalMouseMove(evt:MouseEvent): void {
			if (_bmdSnapshot == null)
				return;
				
			// Show eye-dropper mouse cursor
			Cursor.csrEyedropper.Apply();
			
			// CONSIDER: a new property specifying the DisplayObject to sample when the mouse is over it.
			UpdateColor(evt.stageX, evt.stageY);
			
			evt.updateAfterEvent();
		}
		
		// Override in sub-classes for multi-color selection.
		protected function UpdateColor(xPos:Number, yPos:Number): void {
			var clr:uint = _bmdSnapshot.getPixel(xPos, yPos);
			color = clr;
		}
		
		private function OnModalMouseDown(evt:MouseEvent): void {
			Cleanup();
		}
		
		/* UNDONE: it would be nice to pass mouse wheel events through so the user could zoom while
				choosing colors. But smarts are needed to pass the event on and regenerate the
				snapshot. CONSIDER: don't snapshot, just draw the stage into a single-point BitmapData.
				Would it be fast enough?
		private function OnModalMouseWheel(evt:MouseEvent): void {
			var ptGlobal:Point = new Point(evt.stageX, evt.stageY);
			var adob:Array = stage.getObjectsUnderPoint(ptGlobal);
			for each (var dob:DisplayObject in adob) {
				if (dob == _sprModal)
					continue;
				var ptLocal:Point = dob.globalToLocal(ptGlobal);
				trace(ptGlobal + ", " + ptLocal);
				dob.dispatchEvent(new MouseEvent(evt.type, evt.bubbles, evt.cancelable, ptLocal.x, ptLocal.y,
						evt.relatedObject, evt.ctrlKey, evt.altKey, evt.shiftKey, evt.buttonDown, evt.delta));
			}
		}
		*/
		
		private function DisposeSnapshot(): void {
			if (_bmdSnapshot) {
				_bmdSnapshot.dispose();
				_bmdSnapshot = null;
			}
		}
	}
}
