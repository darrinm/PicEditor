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
// GlobaEventManager watches ALL keyboard and mouse events to retain miscellaneous
// state various parts of the app are interested in but don't want to track themselves.
// E.g. current state of the mouse button and the shift, control, and alt modifier keys

package util {
	import flash.display.Stage;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.core.Application;
	
	public class GlobalEventManager {
		public static const kmodCtrl:uint = 0x0001;
		public static const kmodShift:uint = 0x0002;
		public static const kmodAlt:uint = 0x0004;
		public static const kmodMouseButton:uint = 0x0008;
		public static const OBJECT_CONSTRAINT:String = "object_constraint";
		public static const BRUSH_CONSTRAINT:String = "brush_constraint";
		
		private static var s_fEnabled:Boolean = false;
		private static var stage:Stage;
		private static var s_mod:uint = 0;
		private static var s_nConstraintAxis:int = -1; // 0 = x, 1 = y, -1 = unconstrained
		private static var s_strConstraintMode:String = BRUSH_CONSTRAINT;
		private static var s_xStageShift:Number = Number.NEGATIVE_INFINITY;
		private static var s_yStageShift:Number = Number.NEGATIVE_INFINITY;
		private static var s_xStageDown:Number = Number.NEGATIVE_INFINITY;
		private static var s_yStageDown:Number = Number.NEGATIVE_INFINITY;
		
		public static function set enable(fEnable:Boolean): void {
			stage = Application.application.stage;
			s_fEnabled = fEnable;
			if (s_fEnabled) {
				stage.addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
				stage.addEventListener(KeyboardEvent.KEY_UP, OnKeyUp);
				
				stage.addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown, true, 1000);
				stage.addEventListener(MouseEvent.MOUSE_UP, OnMouseUp, true, 1000);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove, true, 1000);
			
				// For some reason mouse move events events generated while off the stage aren't sent
				// to fCapture=true handlers so we also have to set targeting/bubble up phase listener
				stage.addEventListener(MouseEvent.MOUSE_UP, OnMouseUp, false, 1000);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove, false, 1000);
			} else {
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
				stage.removeEventListener(KeyboardEvent.KEY_UP, OnKeyUp);
				
				stage.removeEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown, true);
				stage.removeEventListener(MouseEvent.MOUSE_UP, OnMouseUp, true);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove, true);
				stage.removeEventListener(MouseEvent.MOUSE_UP, OnMouseUp, false);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove, false);
			}
		}
		
		public static function get constraintMode(): String {
			return s_strConstraintMode;
		}
		
		public static function set constraintMode(strConstraintMode:String): void {
			s_strConstraintMode = strConstraintMode;
		}

		public static function GetHeldModifiers(): uint {
			return s_mod;
		}
		
		public static function GetAxisConstrainedMousePosition(): Point {
			var pt:Point = new Point(stage.mouseX, stage.mouseY);
			if ((s_mod & kmodShift) == 0)
				return pt;
				
			var nConstraintAxis:int = (s_mod & kmodMouseButton) != 0 ? s_nConstraintAxis : CalcConstraintAxis(pt);
				
			switch (nConstraintAxis) {
			case 0: // x-axis constrained
				pt.x = s_xStageShift;
				break;
				
			case 1: // y-axis constrained
				pt.y = s_yStageShift;
				break;
			}
			return pt;
		}
		
		private static function OnKeyDown(evt:KeyboardEvent): void {
//			trace(evt.keyCode + ", " + evt.charCode + ", " + evt.currentTarget + ", " + evt.target + ", " + evt.eventPhase);
			UpdateHeldModifiers(evt.shiftKey, evt.ctrlKey, evt.altKey);
		}

		// UNDONE: possible to miss key up events? How to reset modifier state then?		
		private static function OnKeyUp(evt:KeyboardEvent): void {
			UpdateHeldModifiers(evt.shiftKey, evt.ctrlKey, evt.altKey);
		}
		
		private static function OnMouseDown(evt:MouseEvent): void {
			UpdateHeldModifiers(evt.shiftKey, evt.ctrlKey, evt.altKey);
			s_mod |= kmodMouseButton;
			s_xStageDown = evt.stageX;
			s_yStageDown = evt.stageY;
			
			if (s_strConstraintMode == OBJECT_CONSTRAINT) {
				s_nConstraintAxis = -1;
				s_xStageShift = evt.stageX;
				s_yStageShift = evt.stageY;
			} else {
				s_nConstraintAxis = CalcConstraintAxis(new Point(stage.mouseX, stage.mouseY));
			}
		}
		
		private static function OnMouseUp(evt:MouseEvent): void {
			// Do this before clearing the mouse button flag because we want
			// GetAxisConstrainedMousePosition to follow the button-down rules.
			if (s_strConstraintMode == BRUSH_CONSTRAINT) {
				var ptConstrained:Point = GetAxisConstrainedMousePosition();
				s_xStageShift = ptConstrained.x;
				s_yStageShift = ptConstrained.y;
			}
			s_mod &= ~kmodMouseButton;
		}
		
		private static function OnMouseMove(evt:MouseEvent): void {
			UpdateHeldModifiers(evt.shiftKey, evt.ctrlKey, evt.altKey);
			
			if ((s_mod & (kmodMouseButton | kmodShift)) == (kmodMouseButton | kmodShift)) {
				if (s_nConstraintAxis == -1) {
					if (Math.abs(stage.mouseX - s_xStageShift) > 5 || Math.abs(stage.mouseY - s_yStageShift) > 5)
						s_nConstraintAxis = CalcConstraintAxis(new Point(stage.mouseX, stage.mouseY));
				}
			}
		}
		
		// Update global keyboard modifier state
		private static function UpdateHeldModifiers(fShift:Boolean, fCtrl:Boolean, fAlt:Boolean): void {
			// UNDONE: send a MOUSE_MOVE through if the modifier key state has changed
			var modOld:uint = s_mod;
			s_mod &= ~(kmodAlt | kmodShift | kmodCtrl);
			if (fAlt)
				s_mod |= kmodAlt;
			if (fShift)
				s_mod |= kmodShift;
			if (fCtrl)
				s_mod |= kmodCtrl;
			
			if (fShift) {
				// If this is not a repeated down event update the shift point
				if ((modOld & kmodShift) == 0) {
					if ((s_mod & kmodMouseButton) == 0) { // mouse button up
						s_xStageShift = stage.mouseX; 					
						s_yStageShift = stage.mouseY;
					} else {
						s_xStageShift = s_strConstraintMode == BRUSH_CONSTRAINT ? stage.mouseX : s_xStageDown; 					
						s_yStageShift = s_strConstraintMode == BRUSH_CONSTRAINT ? stage.mouseY : s_yStageDown;
					}
				}
			} else {
				s_xStageShift = Number.NEGATIVE_INFINITY;
				s_yStageShift = Number.NEGATIVE_INFINITY;
			}
		}
		
		// Return the axis the mouse has moved move the least away from since the shift key was pressed
		private static function CalcConstraintAxis(pt:Point): int {
			if (Math.abs(pt.x - s_xStageShift) < Math.abs(pt.y - s_yStageShift)) {
				return 0; // x-axis
			} else {
				return 1; // y-axis
			}
		}
	}
}
