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

	import imagine.ImageDocument;
	
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
	
	public class MoveSizeRotate extends DocoController {
		protected static const kcxyHitPad:Number = 15; // CONFIG:
		private static const kcxyHandle:Number = 10; // CONFIG:
		private static const kcxyHalfHandle:Number = kcxyHandle / 2;
		private static const kcxyMoveThreshold:Number = 4; // CONFIG:
			
		private var _ptdOffset:Point;
		protected var _fMouseDown:Boolean = false;
		private var _xsMouseDown:Number;
		private var _ysMouseDown:Number;
		private var _rcdMouseDown:Rectangle;
		protected var _nHitZone:Number;
		private var _xdMouseDown:Number;
		private var _ydMouseDown:Number;
		private var _dctTargetProperties:Object;
		private var _fCrop:Boolean = false;
		
		// Don't start a move until the mouse has been dragged more than a few pixels.
		// This keeps less dextrous users from accidentally moving objects.
		private var _fMoveThresholdMet:Boolean;
		
		// Use Animator instead of AnimateProperty because in Flex 2 it doesn't have a stop() method.
		// Also because it has a fFrameBased mode where it updates along with the display and doesn't
		// get locked out like timers do when mouse input is driving things.
		private var _amtr:Animator;
		private var _amtrObjectPalette:Animator;
		
		private var _fFixed:Boolean = false;
		protected var _fRecordUndoHistory:Boolean = true;
		protected var _fSymmetricResize:Boolean = false;
		
		public function MoveSizeRotate(imgv:ImageView, dob:DisplayObject, fCrop:Boolean=true) {
			_imgv = imgv;
			target = dob;
			_fCrop = fCrop;
			alpha = 0.0;
			if (dob is IDocumentObject)
				_fFixed = IDocumentObject(dob).isFixed;
			
			// This is needed to give the controller its initial width/height, without which
			// the first FadeIn won't work.
			UpdateDisplayList();
		}
		
		protected function get minSize(): Point {
			return new Point(2,10);
		}
		
		protected function get maxSize(): Point {
			return new Point(10000, 10000);
		}
		
		override public function UpdateDisplayList(): void {
			super.UpdateDisplayList();
			_UpdateDisplayList();
		}

		protected function _UpdateDisplayList(): void {
			Draw(_nHitZone);
		}
		
		
		protected function Draw(nHiZone:Number): void {
			//			var rcl:Rectangle = view.RcvFromRcd(CropToMask(docLocalRect));
			var rcl:Rectangle = view.RcvFromRcd(docLocalRect);
			with (graphics) {
				clear();
				
				// Draw an alpha-zero hit area box. OPT: is there a more efficient way to do this?
				// This article says no: http://www.rockonflash.com/blog/?p=62, unless it is OK for
				// the DisplayObject to have a blendmode of ERASE.
				lineStyle(0, 0, 0);
				var rclHitArea:Rectangle = rcl.clone();
				rclHitArea.inflate(Math.ceil(kcxyHitPad / 2), Math.ceil(kcxyHitPad / 2));
				
				// Draw 4 rects (top, bottom, left, right)
				beginFill(0xff00ff, 0.0);
				drawRect(rclHitArea.x, rclHitArea.y, rclHitArea.width, kcxyHitPad);
				drawRect(rclHitArea.x, rclHitArea.bottom - kcxyHitPad, rclHitArea.width, kcxyHitPad);
				drawRect(rclHitArea.x, rclHitArea.y + kcxyHitPad, kcxyHitPad, rclHitArea.height - (kcxyHitPad * 2));
				drawRect(rclHitArea.right - kcxyHitPad, rclHitArea.y + kcxyHitPad, kcxyHitPad, rclHitArea.height - (kcxyHitPad * 2));
				endFill();
				
				// Draw an alpha-zero rotate handle hit box
				if (!_fFixed) {
					var rclRotateHandle:Rectangle = new Rectangle(
						-Math.round(kcxyHitPad / 2), rcl.top - Util.kcyRotateHandle - 2, kcxyHitPad, kcxyHitPad); // CONFIG:
					beginFill(0xff00ff, 0.0);
					drawRect(rclRotateHandle.x, rclRotateHandle.y, rclRotateHandle.width, rclRotateHandle.height);
					endFill();
				}
				
				// Draw controller shadow
				if (!_fFixed) {
					var rclShadow:Rectangle = rcl.clone();
					rclShadow.offset(1, 1);
					DrawController(graphics, rclShadow, 0x000000, 0.3);
				}
				
				// Draw controller
				DrawController(graphics, rcl, _fCrop ? 0xffff90 : 0xffffff, 1.0);
			}
		}
		
		private function DrawController(gr:Graphics, rcl:Rectangle, co:Number, nAlpha:Number): void {
			with (gr) {
				if (!_fFixed) {
					// Draw the box
					lineStyle(2, co, nAlpha - 0.1);
					moveTo(rcl.left + kcxyHalfHandle + 2, rcl.top);
					lineTo(rcl.right - kcxyHalfHandle - 2, rcl.top);
					moveTo(rcl.right, rcl.top + kcxyHalfHandle + 2);
					lineTo(rcl.right, rcl.bottom - kcxyHalfHandle - 2);
					moveTo(rcl.right - kcxyHalfHandle - 2, rcl.bottom);
					lineTo(rcl.left + kcxyHalfHandle + 2, rcl.bottom);
					moveTo(rcl.left, rcl.bottom - kcxyHalfHandle - 2);
					lineTo(rcl.left, rcl.top + kcxyHalfHandle + 2);
	
					// Draw the corner handles
					lineStyle(2, co, nAlpha);
					drawCircle(rcl.left, rcl.top, kcxyHalfHandle);
					drawCircle(rcl.left, rcl.bottom, kcxyHalfHandle);
					drawCircle(rcl.right, rcl.top, kcxyHalfHandle);
					drawCircle(rcl.right, rcl.bottom, kcxyHalfHandle);
					
					// Draw the rotate handle
					var cxlCenter:Number = (rcl.left + rcl.right) / 2;
					drawCircle(cxlCenter, rcl.top - (Util.kcyRotateHandle - kcxyHalfHandle), kcxyHalfHandle);
					moveTo(cxlCenter, rcl.top - 2);
					lineTo(cxlCenter, rcl.top - (Util.kcyRotateHandle - kcxyHandle) + 2);
				} else {
					// Fixed box is a gray rectangle
					lineStyle(2, 0xcccccc, 1);
					rcl = rcl.clone();
					rcl.inflate(3, 3);
					rcl.width -= 1;
					moveTo(rcl.left, rcl.top);
					lineTo(rcl.right, rcl.top);
					lineTo(rcl.right, rcl.bottom);
					lineTo(rcl.left, rcl.bottom);
					lineTo(rcl.left, rcl.top);
				}
			}
		}
		
		override protected function OnTargetPropertyChange(evt:PropertyChangeEvent): void {
			super.OnTargetPropertyChange(evt);
			// UNDONE: case out the properties we really care about
//			InitializeFromDisplayObjectState();
		}
		
		protected function OnMouseDown(evt:MouseEvent): void {
			_imgv.setFocus();
			
			s_fObjectPaletteHidden = false;
			_fMouseDown = true;
			_fMoveThresholdMet = false;
			_xsMouseDown = evt.stageX;
			_ysMouseDown = evt.stageY;
			_xdMouseDown = _xd;
			_ydMouseDown = _yd;

			// Remember these properties so we can know at mouse up time if they've been changed
			_dctTargetProperties = {
				x: target.x, y: target.y,
				rotation: target.rotation,
			/* UNDONE: 3D objects
				rotationX: target.rotationX,
				rotationY: target.rotationY,
			*/
				localRect: IDocumentObject(target).localRect
			}
			
			var rcl:Rectangle = GetViewBounds();
			
			_nHitZone = OnMouseDownHitTest(evt);
			if (_nHitZone == 0)
				GlobalEventManager.constraintMode = GlobalEventManager.OBJECT_CONSTRAINT;
				
			if (IDocumentObject(target).isFixed)
				_imgv.imageViewCursor = Cursor.csrArrowSelect;
			else
				_imgv.overlayCursor = GetCursor(_nHitZone);
			Cursor.Capture();	
			_rcdMouseDown = _rcdLocal.clone();
			
			var ptdMouse:Point = view.PtdFromPts(new Point(evt.stageX, evt.stageY));
			_ptdOffset = new Point(ptdMouse.x - _xd, ptdMouse.y - _yd);
			
			// use_capture = true so we can grab these events before anyone else
			stage.addEventListener(MouseEvent.MOUSE_UP, OnStageCaptureMouseUp, true, 10);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, OnStageCaptureMouseMove, true, 10);
			
			// For some reason mouse move events events generated while off the stage aren't sent
			// to fCapture=true handlers so we also have to set targeting/bubble up phase listener
			stage.addEventListener(MouseEvent.MOUSE_UP, OnStageMouseUp, false, 10);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, OnStageMouseMove, false, 10);
			
			evt.stopImmediatePropagation();
		}

		protected function OnMouseDownHitTest(evt:MouseEvent): Number {
			// relatedObject is set when the ImageView fabricates a MouseEvent to pass
			// through to the controller to initiate a move.
			if (evt.relatedObject != null)
				return 0;
			return HitTestTarget(GetViewBounds(), evt.localX, evt.localY);
		}
		
		protected function GetCursor( nHitZone:int ): Cursor {
			return Util.gacsrHitCursors[nHitZone + 1];
		}
		
		protected function HitTestTarget(rcl:Rectangle, xl:Number, yl:Number): Number {
			return Util.HitTestPaddedRect(rcl, xl, yl, kcxyHitPad, true);
		}
		
		private static const kcxPad:int = 5;
		
		private function OnStageCaptureMouseUp(evt:MouseEvent): void {
			if (_nHitZone != 10) {
				FadeIn();
				if (s_fObjectPaletteHidden) {
					MoveObjectPaletteOutOfTheWay();
					FadeObjectPaletteTo(1.0);
				}
			}
			_fMouseDown = false;

			// Update our special mouse cursor
			Cursor.Release();
			_imgv.overlayCursor = null;			
			UpdateMouseCursor(null);
			evt.updateAfterEvent();
			
			// On Mac Firefox if the user lets up on the mouse outside the browser
			// Flash thinks it is still held down which can lead to up events going
			// to objects that don't even have the stage initialized!?!
			if (stage == null)
				return;
			
			// Don't let anyone else act on our captured events
			evt.stopImmediatePropagation();
			stage.removeEventListener(MouseEvent.MOUSE_UP, OnStageCaptureMouseUp, true);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnStageCaptureMouseMove, true);
			stage.removeEventListener(MouseEvent.MOUSE_UP, OnStageMouseUp, false);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnStageMouseMove, false);

			// Figure out which target properties have changed (if any) and add a
			// corresponding SetPropertiesObjectOperation instance to the undo stack
			var dctProperties:Object = {};
			var fChanged:Boolean = false;
			for (var strProp:String in _dctTargetProperties) {
				// Convert to strings before comparing so we can compare Rectangles as well as primitive types
				if (String(target[strProp]) != String(_dctTargetProperties[strProp])) {
					dctProperties[strProp] = target[strProp];
					fChanged = true;
				}
			}
			
			if (fChanged && _fRecordUndoHistory) {
				var imgd:ImageDocument = _imgv.imageDocument;
				// First set the target properties back to their original state so they
				// can be recorded as Undo state.
				for (strProp in dctProperties)
					target[strProp] = _dctTargetProperties[strProp];
				IDocumentObject(target).Validate();
				
				imgd.BeginUndoTransaction("Set " + ImageDocument.GetDocumentObjectType(IDocumentObject(target)) +
						" properties", false, false);
				var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(target.name, dctProperties);
				spop.Do(imgd);
				imgd.EndUndoTransaction();
				IDocumentObject(target).Validate();
			}
		}
		
		// Make sure the ObjectPalette isn't on top of the object, if possible
		private function MoveObjectPaletteOutOfTheWay(): void {
			if (!IsObjectPaletteOverlapping())
				return;
				
			var rcsTarget:Rectangle = getBounds(stage);
			var rcsPalette:Rectangle = _imgv.objectPalette.getBounds(stage);
			
			// Try to keep the palette on the same side of the shape
			if (rcsPalette.left + rcsPalette.width / 2 > rcsTarget.left + rcsTarget.width / 2) {
				// Move it to the right
				_imgv.objectPalette.x = rcsTarget.right + kcxPad;
				
				// Off the right of the application?
				if (_imgv.objectPalette.x + rcsPalette.width + kcxPad > Application.application.width) {
					// Move it to the left side if it will fit.
					if (rcsTarget.left - rcsPalette.width - kcxPad >= 0)
						_imgv.objectPalette.x = rcsTarget.left - rcsPalette.width - kcxPad;
					else
						// Otherwise, just make sure it stays on-screen
						_imgv.objectPalette.x = Application.application.width - rcsPalette.width - kcxPad;
				}
			} else {
				// Move it to the left
				_imgv.objectPalette.x = rcsTarget.left - rcsPalette.width - kcxPad;
				
				// Of the left of the application?
				if (_imgv.objectPalette.x < kcxPad) {
					//  Move it to the right side if it will fit.
					if (rcsTarget.right + rcsPalette.width + kcxPad <= Application.application.width)
						_imgv.objectPalette.x = rcsTarget.right + kcxPad;
					else
						// Otherwise, just make sure it stays on-screen
						_imgv.objectPalette.x = kcxPad;
				}
			}
		}
		
		private function OnStageMouseUp(evt:MouseEvent): void {
			OnStageCaptureMouseUp(evt);
		}
		
		private function GetDesiredProportions(): Point {
			return new Point(_rcdMouseDown.width, _rcdMouseDown.height);
		}
		
		private static var s_fObjectPaletteHidden:Boolean = false;
		
		protected function OnStageCaptureMouseMove(evt:MouseEvent): void {
			var dx:Number, dy:Number;
			
			// Don't let anyone else act on our captured events
			evt.stopImmediatePropagation();
			
			if (!_fMouseDown)
				return;

			if (_fFixed)
				return;

			// Has the mouse moved far enough to consider this a conscious attempt to
			// move the target?
			if (!_fMoveThresholdMet) {
				dx = evt.stageX - _xsMouseDown;
				dy = evt.stageY - _ysMouseDown;
				var dxy:Number = Math.sqrt(dx * dx + dy * dy);
				if (dxy < kcxyMoveThreshold)
					// No, ignore this move
					return;
					
				// Yes!
				_fMoveThresholdMet = true;
				
				if (_nHitZone != 10)
					FadeOut();
			}
			
			OnStageCaptureMouseMoveInZone(_nHitZone,evt);
			// If we updateAfterEvent on mouse moves timers and enter_frame events don't get a chance
			// to fire which hoses various animations going on (fading the controller, object palette).
			//			evt.updateAfterEvent();
			FadeObjectPaletteIfOverlapping();					
		}
		
		protected function OnStageCaptureMouseMoveInZone(nHitZone:Number, evt:MouseEvent): void {
			switch (nHitZone) {
			case -1: // outside -- ignore
			case 10: // inside text edit -- ignore
				break;
				
			case 0: // inside -- move
				var ptStage:Point = GlobalEventManager.GetAxisConstrainedMousePosition()				
				var ptdMouse:Point = view.PtdFromPts(ptStage);
				var ptd:Point = new Point(ptdMouse.x - _ptdOffset.x, ptdMouse.y - _ptdOffset.y);
				var ptdTarget:Point = target.parent.globalToLocal(ptd);

				// Rely on target property change notification to update controller's docX, docY
				target.x = ptdTarget.x;
				target.y = ptdTarget.y;
				break;
				
			case 9: // rotate handle -- rotate
				// Calculate an unrotated offset from the controller's origin
				var ptl:Point = parent.globalToLocal(new Point(evt.stageX, evt.stageY));
				ptl.offset(-x, -y);
				
				var degAngle:Number = Util.DegFromRad(Math.atan2(ptl.y, ptl.x)) + 90;
				if (degAngle > 180)
					degAngle -= 360;
				
				// Rely on target property change notification to update controller's rotation
				/* UNDONE: 3D objects
				if (evt.shiftKey) {
					target.rotationX = degAngle;
					target.rotation = _dctTargetProperties.rotation;
					target.rotationY = _dctTargetProperties.rotationY;
				} else if (evt.ctrlKey) {
					target.rotationY = degAngle;
					target.rotation = _dctTargetProperties.rotation;
					target.rotationX = _dctTargetProperties.rotationX;
				} else {
					target.rotation = degAngle;
					target.rotationX = _dctTargetProperties.rotationX;
					target.rotationY = _dctTargetProperties.rotationY;
				}
				*/
				target.rotation = degAngle;
				break;
				
			default: // a side or corner -- resize
				var ptvDelta:Point = new Point(evt.stageX - _xsMouseDown, evt.stageY - _ysMouseDown);
				var ptdDelta:Point = _imgv.PtdFromPtv(ptvDelta);
				
				// Reorient the mouse delta to match the controller's rotation
				var mat:Matrix = new Matrix();
				mat.rotate(Util.RadFromDeg(-rotation));
				var ptdOriented:Point = mat.transformPoint(ptdDelta);
				var dx:Number = ptdOriented.x;
				var dy:Number = ptdOriented.y;
				
				var doco:IDocumentObject = (target as IDocumentObject);
				var fConstrainAspectRatio:Boolean = ("hasFixedAspectRatio" in doco) ? doco["hasFixedAspectRatio"] : true; // Default is true
				if (evt.shiftKey) fConstrainAspectRatio = !fConstrainAspectRatio; // Shift key reverses constraint
				
				// Using the oriented mouse delta, calculate a resized rectangle and an
				// origin offset that will satisfy the hit zone constraints.
				var ob:Object = ResizeRect(_rcdMouseDown, new Point(0, 0), dx, dy,
						GetDesiredProportions(), _nHitZone, minSize.x, minSize.y, maxSize.x, maxSize.y, fConstrainAspectRatio);
				
				// Reorient the origin offset to remove controller's rotation
				mat.invert();
				ptdOriented = mat.transformPoint(ob.pt);

				// Update the target object rect & origin
				// Rely on target property change notifications to update controllers docX,Y, docLocalRect
				
				doco.localRect = ScaleToTarget(ob.rc);
//				doco.localRect = ob.rc;
				ptdTarget = target.parent.globalToLocal(new Point(_xdMouseDown + ptdOriented.x, _ydMouseDown + ptdOriented.y));
				target.x = ptdTarget.x;
				target.y = ptdTarget.y;
				break;
			}
		}
		
		private function OnStageMouseMove(evt:MouseEvent): void {
			OnStageCaptureMouseMove(evt);
		}
		
		private function OnMouseMove(evt:MouseEvent): void {
			// Update our special mouse cursor
			UpdateMouseCursor(evt);
			evt.updateAfterEvent();

			// We're acting on this so we don't want anybody else to
			evt.stopPropagation();
		}
		
		override protected function OnAddedToStage(evt:Event): void {
			super.OnAddedToStage(evt);
			
			MoveObjectPaletteOutOfTheWay();
			FadeIn();
			
			if (evt.target == this) {
				addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown, false, 100, true);
				addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
				stage.addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
			}
		}
		
		// When the controller is removed it must stop messing with the mouse cursor
		override protected function OnRemovedFromStage(evt:Event): void {
			super.OnRemovedFromStage(evt);
			
			// We'll get called for all children added to this instance but we don't want
			// to act on them.
			if (evt.target == this) {
				_imgv.imageViewCursor = null;
				removeEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown, false);
				removeEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
				
				// stage is null when Event.REMOVED is received. But we still need to remove
				// the global keyboard listener so use the Application.application instance.
				Application.application.stage.removeEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
			}
		}
		
		protected function OnKeyDown(evt:KeyboardEvent): void {
			// Ignore if keyboard events should go to editing a text field rather than
			// interacting with objects (for move, delete, etc)
			var fmc:IFocusManagerComponent = Application.application.focusManager.getFocus();
			if (fmc is TextArea || fmc is TextInput || fmc is mx.controls.Text)
				return;
			if (stage.focus is TextField)
				return;
			
			evt.stopPropagation();
			var imgd:ImageDocument = _imgv.imageDocument;
			var doco:IDocumentObject = target as IDocumentObject;
			if (imgd && imgd.selectedItems && imgd.selectedItems.length > 0 && doco && !_fMouseDown) {
				var xDelta:Number = 0;
				var yDelta:Number = 0;
				if (evt.keyCode == Keyboard.DELETE || evt.keyCode == Keyboard.BACKSPACE) {
					DocumentObjectUtil.Delete(doco, imgd);
				} else if (evt.keyCode == Keyboard.UP) {
					yDelta = -1;
				} else if (evt.keyCode == Keyboard.DOWN) {
					yDelta = 1;
				} else if (evt.keyCode == Keyboard.LEFT) {
					xDelta = -1;
				} else if (evt.keyCode == Keyboard.RIGHT) {
					xDelta = 1;
				}
				
				if (xDelta != 0 || yDelta != 0) {
					if (evt.ctrlKey) {
						xDelta *= 20;
						yDelta *= 20;
					}
					if (evt.shiftKey) {
						xDelta *= 5;
						yDelta *= 5;
					}
					MoveSelected(xDelta, yDelta);
				}
			}
		}
		
		private function MoveSelected(xDelta:Number, yDelta:Number): void {
			// UNDONE: Support multi-select
			var imgd:ImageDocument = _imgv.imageDocument;
			var dob:DisplayObject = target;
			var doco:IDocumentObject = target as IDocumentObject;
			if (dob && imgd.contains(dob)) {
				if (_fRecordUndoHistory) {
					var dctProperties:Object = {};
					dctProperties.x = dob.x + xDelta;
					dctProperties.y = dob.y + yDelta;
					var soop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(dob.name, dctProperties);
					imgd.BeginUndoTransaction("Set " + ImageDocument.GetDocumentObjectType(doco) +
							" properties", false, false);
					soop.Do(imgd);
					imgd.EndUndoTransaction();
				} else {
					dob.x += xDelta;
					dob.y += yDelta;
				}
			}
		}
		
		protected function UpdateMouseCursor(evt:MouseEvent): void {
			if (!_fMouseDown) {
				var rcl:Rectangle = GetViewBounds();
				var nHitZone:Number = HitTestTarget(rcl, mouseX, mouseY);
				if (nHitZone != -1) {
					if (IDocumentObject(target).isFixed)
						_imgv.imageViewCursor = Cursor.csrArrowSelect;
					else
						_imgv.imageViewCursor = GetCursor(nHitZone);
				} else {
					_imgv.imageViewCursor = null;
				}
			}
		}
		
		protected function FadeOut(): void {
			if (_amtr)
				_amtr.Dispose();
			_amtr = new Animator(this, "alpha", alpha, 0.2, 150, null, false, true);
		}
		
		protected function FadeIn(): void {
			if (_amtr)
				_amtr.Dispose();
			_amtr = new Animator(this, "alpha", alpha, 1.0, 150, null, false, true);
		}
		
		protected function FadeObjectPaletteTo(nAlpha:Number): void {
			if (_amtrObjectPalette)
				_amtrObjectPalette.Dispose();
			if (_imgv.objectPalette == null)
				return;
			_amtrObjectPalette = new Animator(_imgv.objectPalette, "alpha", _imgv.objectPalette.alpha, nAlpha, 50, null, true);
		}

		private function FadeObjectPaletteIfOverlapping(): void {
			if (_imgv.objectPalette) {
				if (IsObjectPaletteOverlapping()) {
					if (!s_fObjectPaletteHidden) {
						s_fObjectPaletteHidden = true;
						FadeObjectPaletteTo(0.0);
					}
				} else {
					/* Peter is irritated by the palettes coming and going. With this commented out it will only go.
					if (s_fObjectPaletteHidden) {
						s_fObjectPaletteHidden = false;
						FadeObjectPaletteTo(1.0);
					}
					*/
				}
			}
		}
		
		private function IsObjectPaletteOverlapping(): Boolean {
			if (_imgv.objectPalette == null)
				return false;
			var rcsTarget:Rectangle = getBounds(stage);
			var rcsPalette:Rectangle  =_imgv.objectPalette.getBounds(stage);
			return rcsTarget.intersects(rcsPalette);
		}
		
		protected function GetViewBounds(): Rectangle {
			return view.RcvFromRcd(docLocalRect);
		}
		
		private function CropToMask(rcd:Rectangle): Rectangle {
			if (!_fCrop && target.mask && target.mask is IDocumentObject) {
				var dobMask:DisplayObject = target.mask;
				var rcdMaskBounds:Rectangle = IDocumentObject(dobMask).localRect;
				rcdMaskBounds.offset(dobMask.x, dobMask.y);
				rcdMaskBounds = new Rectangle(rcdMaskBounds.left * target.scaleX, rcdMaskBounds.top * target.scaleY, rcdMaskBounds.width * target.scaleX, rcdMaskBounds.height * target.scaleY);
				return rcd.intersection(rcdMaskBounds);
			}
			return rcd;
		}
		
		protected function ResizeRect(rc:Rectangle, pt:Point, dx:Number, dy:Number,
				ptProportions:Point, nHitZone:Number, cxMin:Number, cyMin:Number,
				cxMax:Number, cyMax:Number, fConstrainAspectRatio:Boolean): Object {
			var anHZC:Array = Util.gaanHZC[nHitZone];
			
			// Force the incoming rect to be least 1 pixel wide & high
			if (rc.width < 1)
				rc.width = 1;
			if (rc.height < 1)
				rc.height = 1;
			
			var rcNew:Rectangle = rc.clone();
			var ptNew:Point = pt.clone();

			// Incorporate the size delta in a new width and height, being smart about
			// which edge(s) are being moved
			// UNDONE: sizing from center (nHitZone = 0)
			var cxNew:Number = rc.width - (dx * anHZC[0]) + (dx * anHZC[2]); // left & right
			var cyNew:Number = rc.height - (dy * anHZC[1]) + (dy * anHZC[3]); // top & bottom

			// Apply the proportions and size constraints
			var ptDim:Point = ConstrainDims(cxNew, cyNew, ptProportions, nHitZone, cxMin, cyMin, cxMax, cyMax, fConstrainAspectRatio);
			cxNew = ptDim.x;
			cyNew = ptDim.y;
			
			var nXScale:Number = cxNew / rc.width;
			var nYScale:Number = cyNew / rc.height;
			
			// Scale around origin
			rcNew.left *= nXScale;
			rcNew.top *= nYScale;
			rcNew.right *= nXScale;
			rcNew.bottom *= nYScale;
			
			// UNDONE: not good enough. Test w/ origin at top-left
			dx = (rcNew.width - rc.width) / 2;
			dy = (rcNew.height - rc.height) / 2;
			
			// Offset the origin point to keep the constrained edges pinned
			if (!_fSymmetricResize) {
				ptNew.x -= dx * anHZC[0];
				ptNew.y -= dy * anHZC[1];
				ptNew.x += dx * anHZC[2];
				ptNew.y += dy * anHZC[3];
			}
			return { rc: rcNew, pt: ptNew };
		}
		
		// Return a width and height that conform to the specified proportions and min/max dimensions.
		// A non-zero nHitZone determines whether the height is derived from the width or the other
		// way around.
		// Special ptProportions values:
		// (-1, -1) == keep proportions the same as cxNew, cyNew
		private static function ConstrainDims(cx:Number, cy:Number, ptProportions:Point, nHitZone:Number,
				cxMin:Number, cyMin:Number, cxMax:Number, cyMax:Number, fConstrainAspectRatio:Boolean): Point {
			// Avoid divide-by-zeros but hew as closely to the requested proportions as possible
			if (ptProportions.x == 0)
				ptProportions.x = Number.MIN_VALUE;
			if (ptProportions.y == 0)
				ptProportions.y = Number.MIN_VALUE;
					
			// Apply the min/max size constraint
			cx = Math.max(cx, cxMin);
			cy = Math.max(cy, cyMin);
			cx = Math.min(cx, cxMax);
			cy = Math.min(cy, cyMax);
					
			var cxNew:Number = cx;
			var cyNew:Number = cy;

			if (ptProportions.x == -1 || ptProportions.y == -1) {
				return new Point(cxNew, cyNew);
			}

			var cxDim:Number = ptProportions.x;
			var cyDim:Number = ptProportions.y;
			
			if (!fConstrainAspectRatio) {
				cxNew = Math.max(cxMin, cx);
				cyNew = Math.max(cyMin, cy);
			} else {
				switch (nHitZone) {
				// Height defines width for the top and bottom hit zones (unless the min/max range is exceeded)
				case 2:
				case 6:
					cxNew = cy * cxDim / cyDim;
					if (cxNew < cxMin) {
						cxNew = cxMin;
						cyNew = cxNew * cyDim / cxDim;
					} else if (cxNew > cxMax) {
						cxNew = cxMax;
						cyNew = cxNew * cyDim / cxDim;
					}
					break;
					
				// Width defines height for the left and right hit zones (unless the min/max range is exceeded)
				case 4:
				case 8:
					cyNew = cx * cyDim / cxDim;
					if (cyNew < cyMin) {
						cyNew = cyMin;
						cxNew = cyNew * cxDim / cyDim;
					} else if (cyNew > cyMax) {
						cyNew = cyMax;
						cxNew = cyNew * cxDim / cyDim;
					}
					break;
					
				case 1: // top-left corner
				case 5: // bottom-right corner
				case 3: // top-right corner
				case 7: // bottom-left corner
					// UNDONE: enforce max dimensions
					cxNew = Math.max(cxMin, cy * cxDim / cyDim);
					cyNew = Math.max(cyMin, cx * cyDim / cxDim);
					if (cxNew > cx) {
						cxNew = cyNew * cxDim / cyDim;
					} else if (cyNew > cy) {
						cyNew = cxNew * cyDim / cxDim;
					}
					break;
				}
			}
			return new Point(cxNew, cyNew);
		}
	}
}
