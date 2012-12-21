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
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.containers.TitleWindow;
	import mx.core.Application;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;

	public class PaletteWindow extends TitleWindow {
		// The amount of vertical spacing between PaletteWindows
		private const kcyPadding:Number = 10;
		private var _nPriority:Number = 0;
		
		public function PaletteWindow() {
			super();
			addEventListener(FlexEvent.SHOW, OnShow);
			addEventListener(FlexEvent.ADD, OnAdd);
			addEventListener(FlexEvent.REMOVE, OnRemove);
		}
		
		public function get priority(): Number {
			return _nPriority;
		}
		
		public function set priority(nPriority:Number): void {
			_nPriority = nPriority;
		}
		
		// When a palette window is shown, make sure it doesn't stomp an existing
		// palette window. Drop it in below or to the right as necessary.
		// NOTE: no smarts here for going off the bottom of the screen
		protected function OnShow(evt:FlexEvent): void {
			// Enumerate all peer PaletteWindows
			for (var i:Number = 0; i < parent.numChildren; i++) {
				var rcThis:Rectangle = new Rectangle(x, y, width, height);
				var pwndPeer:PaletteWindow = parent.getChildAt(i) as PaletteWindow;
				if (pwndPeer == null || pwndPeer == this || !pwndPeer.visible)
					continue;
				var rcPeer:Rectangle = new Rectangle(pwndPeer.x, pwndPeer.y, pwndPeer.width, pwndPeer.height);
				if (rcThis.intersects(rcPeer)) {
					if (priority > pwndPeer.priority)
						pwndPeer.y = y + height + kcyPadding;
					else
						y = pwndPeer.y + pwndPeer.height + kcyPadding;
				}
			}
		}
		
		private function OnAdd(evt:FlexEvent): void {
			removeEventListener(FlexEvent.ADD, OnAdd);
			Application.application.addEventListener(ResizeEvent.RESIZE, OnApplicationResize);
		}
		
		private function OnRemove(evt:FlexEvent): void {
			removeEventListener(FlexEvent.REMOVE, OnRemove);
			Application.application.removeEventListener(ResizeEvent.RESIZE, OnApplicationResize);
		}
		
		private function OnApplicationResize(evt:ResizeEvent): void {
			var ptConstrained:Point = ConstrainPosition(x, y)
			if (ptConstrained.x != x || ptConstrained.y != y)
	        	move(ptConstrained.x, ptConstrained.y);
		}
		
	    /**
	     *  @private
	     *  Horizontal location where the user pressed the mouse button
	     *  on the titlebar to start dragging, relative to the original
	     *  horizontal location of the Panel.
	     */
	    private var regX:Number;
	   
	    /**
	     *  @private
	     *  Vertical location where the user pressed the mouse button
	     *  on the titlebar to start dragging, relative to the original
	     *  vertical location of the Panel.
	     */
	    private var regY:Number;

	    /**
	     *  Called when the user starts dragging a Panel
	     *  that has been popped up by the PopUpManager.
	     */
		override protected function startDragging(evt:MouseEvent): void {
	        regX = evt.stageX - x;
	        regY = evt.stageY - y;
	       
	        systemManager.addEventListener(
	            MouseEvent.MOUSE_MOVE, systemManager_mouseMoveHandler, true);
	
	        systemManager.addEventListener(
	            MouseEvent.MOUSE_UP, systemManager_mouseUpHandler, true);
	
	        systemManager.stage.addEventListener(
	            Event.MOUSE_LEAVE, stage_mouseLeaveHandler);
		}
		
	    /**
	     *  Called when the user stops dragging a Panel
	     *  that has been popped up by the PopUpManager.
	     */
		override protected function stopDragging(): void {
	        systemManager.removeEventListener(
	            MouseEvent.MOUSE_MOVE, systemManager_mouseMoveHandler, true);
	
	        systemManager.removeEventListener(
	            MouseEvent.MOUSE_UP, systemManager_mouseUpHandler, true);
	
	        systemManager.stage.removeEventListener(
	            Event.MOUSE_LEAVE, stage_mouseLeaveHandler);
	
	        regX = NaN;
	        regY = NaN;
		}
		
	    /**
	     *  @private
	     */
	    private function systemManager_mouseMoveHandler(event:MouseEvent):void
	    {
	    	// during a drag, only the Panel should get mouse move events
	    	// (e.g., prevent objects 'beneath' it from getting them -- see bug 187569)
	    	// we don't check the target since this is on the systemManager and the target
	    	// changes a lot -- but this listener only exists during a drag.
	    	event.stopImmediatePropagation();
	    	
	    	var pt:Point = ConstrainPosition(event.stageX - regX, event.stageY - regY);
	    		
	        move(pt.x, pt.y);
	    }
	   
	    private function ConstrainPosition(x:Number, y:Number): Point {
	    	// Use the Application instance instead of the stage because the stage resizes when
	    	// DisplayObjects go off its edges.
	    	var rcConstraint:Rectangle = new Rectangle(0, 0,
	    			Application.application.width - width, Application.application.height - height);
	    	rcConstraint.inflate(width - 50, 0);
	    	rcConstraint.height += height - 25;
	    	
	    	if (x < rcConstraint.left)
	    		x = rcConstraint.left;
	    	if (x > rcConstraint.right)
	    		x = rcConstraint.right;
	    	if (y < rcConstraint.top)
	    		y = rcConstraint.top;
	    	if (y > rcConstraint.bottom)
	    		y = rcConstraint.bottom;
	    		
	    	return new Point(x, y);
	    }
	
	    /**
	     *  @private
	     */
	    private function systemManager_mouseUpHandler(event:MouseEvent):void
	    {
	        if (!isNaN(regX))
	            stopDragging();
	    }
	
	    /**
	     *  @private
	     */
	    private function stage_mouseLeaveHandler(event:Event):void
	    {
	        if (!isNaN(regX))
	            stopDragging();
	    }
	
	}
}
