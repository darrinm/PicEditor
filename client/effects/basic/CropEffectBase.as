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
// The cropping UI must deal with a number of constraints. When a user resizes the crop
// rectangle it must
// - stay within the image bounds
// - satisfy the user-specified proportions
// - select an appropriate orientation, if user-specified proportions are in effect

// If proportion constraints are in effect when a user sizes from an edge or corner
// - other edges must be adjusted to satisfy the proportions
// - if any edge goes off the image boundary it must be clamped and

// - sizing an edge should not cause an orientation reevaluation
// - rcdCrop x,y,width,height must be integers

package effects.basic {
	import containers.NestedControlCanvasBase;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	
	import imagine.imageOperations.CropImageOperation;
	import imagine.imageOperations.NestedImageOperation;
	import imagine.imageOperations.ResizeImageOperation;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.ComboBox;
	import mx.controls.TextInput;

	public class CropEffectBase extends CoreEditingEffect implements IOverlay {
		private static const kcxyHitPad:Number = 15; // CONFIG:

		// MXML-defined variables
		[Bindable] public var _tiCropWidth:TextInput;
		[Bindable] public var _tiCropHeight:TextInput;
		[Bindable] public var _cmboConstraints:ComboBox;
		[Bindable] public var _btnInfo:Button;
		[Bindable] public var _cbResizeToFit:CheckBox;

		public var _strYours:String;

		private var _mcOverlay:MovieClip;
		private var _rcdCrop:Rectangle;
		private var _fMouseDown:Boolean = false;
		private var _xMouseDown:Number;
		private var _yMouseDown:Number;
		private var _nHitZone:Number = -1;
		private var _rcdCropMouseDown:Rectangle;
		private var _dctProportions:Object;
		private var _fMouseDrag:Boolean = false;
		private var firstTimeInitCompleted:Boolean = false;

		public function CropEffectBase() {
			super();
		}

		private function AddDesktopResolutionToCropResolutionList():void {
			// Point out the user which desktop resolution is theirs
			var fUsersResolutionFound:Boolean = false;
			var acol:ArrayCollection = _cmboConstraints.dataProvider as ArrayCollection;
			for (var i:Number = 0; i < acol.length; i++) {
				var ob:Object = acol.getItemAt(i);
				var strConstraint:String = ob.data;
				var astrT:Array = strConstraint.split(",");
				var cx:Number = Number(astrT[0]);
				var cy:Number = Number(astrT[1]);
				if (cx == Capabilities.screenResolutionX && cy == Capabilities.screenResolutionY) {
					ob.label += _strYours;
					fUsersResolutionFound = true;
					break;
				}
			}

			// Maybe they have an unusual resolution that's not on the list. Add it to the end.
			if (!fUsersResolutionFound) {
				ob = {
			  label: Capabilities.screenResolutionX.toString() + "x" + Capabilities.screenResolutionY + " " + _strYours,
			  data: Capabilities.screenResolutionX.toString() + "," + Capabilities.screenResolutionY + ",1"
				}
				acol.addItem(ob);
			}
		}

		override public function Select(efcnvCleanup:NestedControlCanvasBase):Boolean {
			if (super.Select(efcnvCleanup)) {
				if (!firstTimeInitCompleted) {
					AddDesktopResolutionToCropResolutionList();
					firstTimeInitCompleted = true;
				}
				// Get our image operation back to the default state by deleting any nested operations
				var nestedImageOperation:NestedImageOperation = NestedImageOperation(this.operation);
				nestedImageOperation.children.splice(0, nestedImageOperation.children.length);

				var rcdCrop:Rectangle = FloorCeilRect(_imgv.GetViewRect());
				rcdCrop.inflate(Math.round(-rcdCrop.width / 6), Math.round(-rcdCrop.height / 6));
				_rcdCrop = rcdCrop;

				_mcOverlay = _imgv.CreateOverlay(this);
				_mcOverlay.OnResize = Overlay_OnResize;

				// Set initial size
				UpdateImageDimControls();
				Overlay_Update();
				return true;
			}
			return false;
		}

		override public function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null):void {
			if (_mcOverlay) {
				_imgv.DestroyOverlay(_mcOverlay);
				_mcOverlay = null;
			}
			super.Deselect(fForceRollOutEffect, efcvsNew);
		}

		override public function Apply():void {
			var nestedImageOperation:NestedImageOperation = NestedImageOperation(this.operation);
			// First push the crop operation
			nestedImageOperation.children.push(new CropImageOperation(_rcdCrop.x, _rcdCrop.y, _rcdCrop.width, _rcdCrop.height));
			if (resizeToFit) {
				var ptLimited:Point = Util.GetLimitedImageSize(Number(_tiCropWidth.text), Number(_tiCropHeight.text));
				// Then resize to target dimension if needed
				nestedImageOperation.children.push(new ResizeImageOperation(ptLimited.x, ptLimited.y));
			}
			// Open an undo transaction and apply this image operation
			// OnOpChange();
			this.UpdateBitmapData();
			super.Apply();
		}


		private function FloorCeilRect(rc:Rectangle): Rectangle {
			return new Rectangle(Math.floor(rc.x), Math.floor(rc.y), Math.ceil(rc.width), Math.ceil(rc.height));
		}


		private function GetSelectedConstraints(): Object {
			var	strConstraint:String = _cmboConstraints.selectedItem.data;
			var astrT:Array = strConstraint.split(",");
			var cx:Number = Number(astrT[0]);
			var cy:Number = Number(astrT[1]);
			if (cx == -2)
				cx = _imgd.width;
			if (cy == -2)
				cy = _imgd.height;

			return {ptProportions: new Point(cx, cy), resizeToFit: (astrT.length > 2)};
		}

		protected function OnConstraintChange(evt:Event): void {
			var obConstraints:Object = GetSelectedConstraints();

			_cbResizeToFit.selected = obConstraints.resizeToFit;
			if (obConstraints.resizeToFit) {
				_tiCropWidth.text = obConstraints.ptProportions.x;
				_tiCropHeight.text = obConstraints.ptProportions.y;
			}

			var ptProportions:Point = GetDesiredProportions();
			var rcd:Rectangle = _rcdCrop.clone();
			ReproportionRect(rcd, ptProportions);
			SetCropRect(rcd, -1, ptProportions, false, false, resizeToFit);
		}

		private function get resizeToFit(): Boolean {
			return _cbResizeToFit.selected;
		}

		protected function OnResizeToFitChange(evt:Event): void {
			UpdateImageDimControls();
			// If our drop down does not agree with the resize checkbox, clear the drop down
			if (GetSelectedConstraints().resizeToFit != resizeToFit)
				_cmboConstraints.selectedIndex = 0; // Select "no constraint"
		}

		protected function OnCropTextInputChange(evt:Event): void {
			var n:Number = Number(evt.target.text);
			if (n == 0)
				return;

			var rcd:Rectangle = _rcdCrop.clone();

			// Make sure we constrain our text input to reasonable values
			if (resizeToFit) {
				// Constrain to valid values
				if (isNaN(n)) n = 1;
				if (n < 1) n = 1;
				var ptLimited:Point;
				if (evt.target == _tiCropWidth) {
					ptLimited = Util.GetLimitedImageSize(n, rcd.height);
					n = ptLimited.x;
				} else {
					ptLimited = Util.GetLimitedImageSize(rcd.width, n);
					n = ptLimited.y;
				}
				n = Math.round(n);
				evt.target.text = n;
			}

			// If the user has reoriented a proportionalized crop, retain their orientation
			// Lock the orientation for resize to fit crops
			var ptProportions:Point = GetDesiredProportions();
			if ((rcd.height > rcd.width) && !resizeToFit) {
				var nT:Number = ptProportions.x;
				ptProportions.x = ptProportions.y;
				ptProportions.y = nT;
			}

			if (evt.target == _tiCropWidth) {
				rcd.width = n;
				if (ptProportions.x != -1)
					rcd.height = rcd.width * ptProportions.y / ptProportions.x;
				SetCropRect(rcd, 4, ptProportions, false, false, resizeToFit);

			} else {
				rcd.height = n;
				if (ptProportions.y != -1)
					rcd.width = rcd.height * ptProportions.x / ptProportions.y;
				SetCropRect(rcd, 6, ptProportions, false, false, resizeToFit);
			}
		}

		//
		// View overlay methods
		//
		private function Overlay_OnResize(): void {
			Overlay_Update();
		}

		private function Overlay_Update(): void {
			with (_mcOverlay.graphics) {
				clear();

				var rclBounds:Rectangle = _imgv.RclFromRcd(new Rectangle(0, 0, _imgd.width, _imgd.height));
				var rclCrop:Rectangle = _imgv.RclFromRcd(_rcdCrop);

				// Draw the crop box w/ muted surrounding area
				lineStyle();
				beginFill(0x707070, 0.5);
				moveTo(0, 0);
				lineTo(rclBounds.width, 0);
				lineTo(rclBounds.width, rclBounds.height);
				lineTo(0, rclBounds.height);
				lineTo(0, 0);

				lineStyle(1, 0xffffff, 0.5);
				moveTo(rclCrop.left, rclCrop.top);
				lineTo(rclCrop.right - 1, rclCrop.top);
				lineTo(rclCrop.right - 1, rclCrop.bottom - 1);
				lineTo(rclCrop.left, rclCrop.bottom - 1);
				lineTo(rclCrop.left, rclCrop.top);
				endFill();

				// Draw the drag handles
				lineStyle(1, 0xffffff, 0.5);
				beginFill(0x000000, 0.25);
				drawCircle(rclCrop.left, rclCrop.top, 7);
				drawCircle(rclCrop.left, rclCrop.bottom, 7);
				drawCircle(rclCrop.right, rclCrop.top, 7);
				drawCircle(rclCrop.right, rclCrop.bottom, 7);
				endFill();

				// Draw thirds lines
				lineStyle(1, 0xffffff, 0.3);
				moveTo(rclCrop.left + rclCrop.width / 3, rclCrop.top);
				lineTo(rclCrop.left + rclCrop.width / 3, rclCrop.bottom);
				moveTo(rclCrop.left + rclCrop.width / 3 * 2, rclCrop.top);
				lineTo(rclCrop.left + rclCrop.width / 3 * 2, rclCrop.bottom);
				moveTo(rclCrop.left, rclCrop.top + rclCrop.height / 3);
				lineTo(rclCrop.right, rclCrop.top + rclCrop.height / 3);
				moveTo(rclCrop.left, rclCrop.top + rclCrop.height / 3 * 2);
				lineTo(rclCrop.right, rclCrop.top + rclCrop.height / 3 * 2);

				// Draw the thirds lines shadows
				lineStyle(1, 0x000000, 0.1);
				moveTo(1 + rclCrop.left + rclCrop.width / 3, rclCrop.top);
				lineTo(1 + rclCrop.left + rclCrop.width / 3, rclCrop.bottom);
				moveTo(1 + rclCrop.left + rclCrop.width / 3 * 2, rclCrop.top);
				lineTo(1 + rclCrop.left + rclCrop.width / 3 * 2, rclCrop.bottom);
				moveTo(rclCrop.left, 1 + rclCrop.top + rclCrop.height / 3);
				lineTo(rclCrop.right, 1 + rclCrop.top + rclCrop.height / 3);
				moveTo(rclCrop.left, 1 + rclCrop.top + rclCrop.height / 3 * 2);
				lineTo(rclCrop.right, 1 + rclCrop.top + rclCrop.height / 3 * 2);
			}
		}

		//
		// ViewOverlayListener methods -- return true to swallow event
		//

		public function OnOverlayDoubleClick(): Boolean {
			// On double-click, synthesize a press on the Apply button
			dispatchEvent(new Event(NestedControlCanvasBase.APPLY_CLICK, true))
			return true;
		}

		// PORT: if we stay with this approach create an IViewOverlayListener interface
		// for type-safety purposes
		public function OnOverlayPress(evt:MouseEvent): Boolean {
//			trace("OnOverlayPress: mouseX: " + _mcOverlay.mouseX + ", mouseY: " + _mcOverlay.mouseY);
			_fMouseDown = true;
			var rclCrop:Rectangle = _imgv.RclFromRcd(_rcdCrop);
			_xMouseDown = _mcOverlay.mouseX;
			_yMouseDown = _mcOverlay.mouseY;
			_nHitZone = Util.HitTestPaddedRect(rclCrop, _xMouseDown, _yMouseDown, kcxyHitPad);
			_rcdCropMouseDown = _rcdCrop.clone();

			// Initialize the crop rect (to empty) if the press didn't occur inside
			// one of the crop box hit zones.
			if (_nHitZone != -1) {
				_fMouseDrag = true; // If you click on a corner, start dragging right away
			} else {
				// If you click outside of your current crop rect, wait until you drag
				// before replacing your crop rect.
				_fMouseDrag = false;
			}

			return true;
		}

		public function OnOverlayRelease(): Boolean {
//			trace("OnOverlayRelease: mouseX: " + _mcOverlay.mouseX + ", mouseY: " + _mcOverlay.mouseY);
			_fMouseDown = false;
			UpdateMouseCursor();
			return true;
		}

		public function OnOverlayReleaseOutside():Boolean {
			return this.OnOverlayRelease();
		}

		public function OnOverlayMouseMove(): Boolean {
//			trace("OnOverlayMouseMove: mouseX: " + _mcOverlay.mouseX + ", mouseY: " + _mcOverlay.mouseY);
			// Update our special mouse cursor
			UpdateMouseCursor();

			if (!_fMouseDown)
				return true;

			var dx:Number = _mcOverlay.mouseX - _xMouseDown;
			var dy:Number = _mcOverlay.mouseY - _yMouseDown;

			if (!_fMouseDrag) {
				// If dragging is false but the mouse is down, you clicked outside
				// the crop rect and have just started to move the mouse.
				if (Math.abs(dx) + Math.abs(dy) < 2) return true; // if you haven't moved it much, ignore the m ove
				else {
					_fMouseDrag = true; // Reached drag threshold
					// Create the new crop rect based on where you clicked.
					SetCropRectS(_xMouseDown, _yMouseDown, _xMouseDown, _yMouseDown, -1, GetDesiredProportions(), resizeToFit);
				}
			}

			var rclCropMouseDown:Rectangle = _imgv.RclFromRcd(_rcdCropMouseDown);

			switch (_nHitZone) {
			case -1: // outside
				SetCropRectS(_xMouseDown, _yMouseDown, _mcOverlay.mouseX, _mcOverlay.mouseY, -1, GetDesiredProportions(), resizeToFit);
				break;

			case 0: // inside
				_rcdCrop = _rcdCropMouseDown.clone();
				_rcdCrop.offset(dx / _imgv.zoom, dy / _imgv.zoom);
				if (_rcdCrop.left < 0)
					_rcdCrop.offset(-_rcdCrop.left, 0);
				else if (_rcdCrop.right > _imgd.width)
					_rcdCrop.offset(_imgd.width - _rcdCrop.right, 0);
				if (_rcdCrop.top < 0)
					_rcdCrop.offset(0, -_rcdCrop.top);
				else if (_rcdCrop.bottom > _imgd.height)
					_rcdCrop.offset(0, _imgd.height - _rcdCrop.bottom);
				_rcdCrop = FloorCeilRect(_rcdCrop);
				Overlay_Update();
				break;

			default:
				var anHZC:Array = Util.gaanHZC[_nHitZone];
				var ptProportions:Point = GetDesiredProportions();

				// If resizing from an edge then we don't want to change the orientation
				if (_nHitZone == 2 || _nHitZone == 4 || _nHitZone == 6 || _nHitZone == 8) {
					// Don't change the proportions for resized crops
					if ((rclCropMouseDown.height > rclCropMouseDown.width) && !resizeToFit) {
						var nT:Number = ptProportions.x;
						ptProportions.x = ptProportions.y;
						ptProportions.y = nT;
					}
				}
				SetCropRectS(rclCropMouseDown.left + dx * anHZC[0], rclCropMouseDown.top + dy * anHZC[1],
						rclCropMouseDown.right + dx * anHZC[2], rclCropMouseDown.bottom + dy * anHZC[3],
						_nHitZone, ptProportions, resizeToFit);
				break;
			}

			return true;
		}

		public function OnOverlayMouseMoveOutside():Boolean {
			if (this._fMouseDown) {
				return this.OnOverlayMouseMove();
			} else {
				return false;
			}
		}

		private function SetCropRectS(x1:Number, y1:Number, x2:Number, y2:Number, nHitZone:Number,
				ptProportions:Point, fResizeToFit:Boolean): void {
			var rclCrop:Rectangle = new Rectangle();
			rclCrop.left = Math.min(x1, x2);
			rclCrop.top = Math.min(y1, y2);
			rclCrop.right = Math.max(x1, x2);
			rclCrop.bottom = Math.max(y1, y2);
			SetCropRect(_imgv.RcdFromRcl(rclCrop), nHitZone, ptProportions, x1 > x2, y1 > y2, fResizeToFit);
		}

		private function SetCropRect(rcd:Rectangle, nHitZone:Number, ptProportions:Point,
				fReversedX:Boolean, fReversedY:Boolean, fResizeToFit:Boolean): void {
			// Trim the rect to fit within the document
			var rcdImage:Rectangle = new Rectangle(0, 0, _imgd.width, _imgd.height);
			_rcdCrop = Util.ConstrainRectDeluxe(rcd, nHitZone, ptProportions, fReversedX, fReversedY,
					fResizeToFit, rcdImage);
			_rcdCrop = FloorCeilRect(_rcdCrop);
			Overlay_Update();
			UpdateImageDimControls();
		}

		// Force the crop to conform to the specified proportions but change the crop
		// as little as possible in the process. This is done by making sure the crop's
		// area stays the same as its proportions change.
		private function ReproportionRect(rc:Rectangle, ptProportions:Point): void {
			var cxDim:Number = ptProportions.x;
			var cyDim:Number = ptProportions.y;
			if (cxDim == -1 || cyDim == -1)
				return;

			var nTotal:Number = rc.width + rc.height;
			var cxNew:Number = nTotal * (cxDim / (cxDim + cyDim));
			var cyNew:Number = nTotal * (cyDim / (cxDim + cyDim));

			// Center the reproportioned rect around the old rect
			rc.left += (rc.width - cxNew) / 2;
			rc.top += (rc.height - cyNew) / 2;
			rc.width = cxNew;
			rc.height = cyNew;
		}

		private function GetDesiredProportions(): Point {
			var obConstraints:Object = GetSelectedConstraints();

			var cx:Number = obConstraints.ptProportions.x;
			var cy:Number = obConstraints.ptProportions.y;

			if (resizeToFit && cx == -1 && cy == -1) {
				cx = Number(_tiCropWidth.text);
				cy = Number(_tiCropHeight.text);
			}
			return new Point(cx, cy);
		}

		private function UpdateImageDimControls(): void {
			if (!resizeToFit) {
				Debug.Assert(int(_rcdCrop.width) == _rcdCrop.width);
				Debug.Assert(int(_rcdCrop.height) == _rcdCrop.height);
				_tiCropWidth.text = String(_rcdCrop.width);
				_tiCropHeight.text = String(_rcdCrop.height);
			}
		}

		private function UpdateMouseCursor(): void {
			if (!_fMouseDown) {
				var rclCrop:Rectangle = _imgv.RclFromRcd(_rcdCrop);
				var nHitZone:Number = Util.HitTestPaddedRect(rclCrop, _mcOverlay.mouseX, _mcOverlay.mouseY, kcxyHitPad);
				_imgv.overlayCursor = Util.gacsrHitCursors[nHitZone + 1];
			}
		}
	}
}
