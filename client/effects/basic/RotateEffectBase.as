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
package effects.basic {
	import containers.NestedControlCanvasBase;
	
	import errors.InvalidBitmapError;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.controls.Button;
	import mx.controls.HSlider;
	import mx.events.SliderEvent;
	
	import overlays.helpers.Cursor;
	import overlays.helpers.LevelLine;
		
	public class RotateEffectBase extends CoreEditingEffect implements IOverlay {
		// MXML-defined variables
		[Bindable] public var _btnRotateLeft:Button;
		[Bindable] public var _btnRotateRight:Button;
		[Bindable] public var _btnFlipH:Button;
		[Bindable] public var _btnFlipV:Button;
		[Bindable] public var _sldrRotation:HSlider;
		
		[Bindable] public var flipH:Boolean = false;
		[Bindable] public var flipV:Boolean = false;
		
		// Rotation in 90 degrees increments from the buttons
		private var _radRotation:Number = 0.0;
		// Rotation change from slider, between -45 and 45 degrees
		private var _radFineRotation:Number = 0.0;
		
		private var _mcOverlay:MovieClip;
		private var _radAnglePrevRender:Number = 0;
		private var _lvll:LevelLine = null;
		private var _fFlipHPrevRender:Boolean = false;
		private var _fFlipVPrevRender:Boolean = false;

		// Constants
		private const knDragThreshold:Number = 10; // CONFIG: Must drag at least this many pixels

		private const knGridSpacing:Number = 30; // CONFIG: space between grid lines for rotate grid

		private const kcoGrid:uint =  0xffffff; // CONFIG: Color of grid line
		private const knGridAlpha:Number = 0.5; // CONFIG: Alpha of grid line
		private const knGridLineThickness:Number = 1; // CONFIG: Thickness of grid line

		private const kcoGridBack:uint =  0x000000; // CONFIG: Color of grid line shadow
		private const knGridBackAlpha:Number = 0.25; // CONFIG: Alpha of grid line shadow
		private const knGridBackLineThickness:Number = 1; // CONFIG: Thickness of grid line shadow

		// Min and max values for the straighten slider
		// Must be at least 44.9 degrees so that we can set this
		// based on the level line
		private const kradMaxStraighten:Number = Util.RadFromDeg(44.9999); // CONFIG
		private const kradMinStraighten:Number = Util.RadFromDeg(-44.9999); // CONFIG

		// CONFIG: These are the multipliers in the quadratic equasion used to "ramp"
		// the fine rotation slider. See SquareRamp comment for more info.
		private const knSquareFactor:Number = 2;
		private const knLinearFactor:Number = 0.1;
		private const knYMax:Number = knSquareFactor + knLinearFactor;
	
		public function RotateEffectBase() {
			super();
		}
		
		override public function Select(efcnvCleanup:NestedControlCanvasBase):Boolean {
			if (super.Select(efcnvCleanup)) {
				this._radFineRotation = 0.0;
				this._radRotation = 0.0;
				this.flipH = false;
				this.flipV = false;
				// Overlay for the LevelLine and grid
				_mcOverlay = _imgv.CreateOverlay(this);
				_mcOverlay.visible = false;
				_imgv.overlayCursor = Cursor.csrSystem; // Turn off the move cursor because do a level line instead
				dispatchEvent(new Event("radAngleChanged"));
				dispatchEvent(new Event("fineRotationDegChanged"));
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

		//
		// ViewOverlayListener methods -- return true to swallow event
		//
		
		// PORT: if we stay with this approach create an IViewOverlayListener interface
		// for type-safety purposes
		public function OnOverlayPress(evt:MouseEvent): Boolean {
			// Create our straighten drag line
			_lvll = new LevelLine(_mcOverlay.mouseX, _mcOverlay.mouseY);
			_mcOverlay.visible = true;
			UpdateLevelLine()
			return true;
		}

		public function OnOverlayRelease(): Boolean {
			if (_lvll != null) {
				_lvll.SetEnd(_mcOverlay.mouseX, _mcOverlay.mouseY);
				if (_lvll.Length >= knDragThreshold) {
					radFineRotation = (_lvll.GetStraightRad(radFineRotation));
				}
				_lvll = null;
				_mcOverlay.visible = false;
			}

			return true;
		}
		
		public function OnOverlayReleaseOutside(): Boolean {
			if (_lvll) {
				return OnOverlayRelease();
			} else {
				return false;
			}
		}

		public function OnOverlayDoubleClick(): Boolean {
			return true;
		}


		public function OnOverlayMouseMoveOutside():Boolean {
			if (_lvll) {
				return OnOverlayMouseMove();
			} else {
				return false;
			}
		}

		public function OnOverlayMouseMove(): Boolean {
			if (_lvll) {
				_lvll.SetEnd(_mcOverlay.mouseX, _mcOverlay.mouseY);
				UpdateLevelLine()
			}
			return true;
		}
		
		//
		// View overlay methods
		//

		private function UpdateLevelLine(): void {
			_lvll.Draw(_mcOverlay.graphics);
		}
		
		// Adjust a scroll offset and clipping width/height to show the grid only on the image
		private function UpdateGridCropRect(): void {
			try {
				// scrollRect the grid to the ImageView's upper-left, clip it to the scaled bitmap's width & height
				var rcl:Rectangle = _imgv.RclFromRcd(new Rectangle(0, 0, _imgd.background.width, _imgd.background.height));
				
				_mcOverlay.scrollRect = new Rectangle(_imgv.bitmapX, _imgv.bitmapY, rcl.width, rcl.height);
				//trace("rcl: x: " + rcl.x + ", y: " + rcl.y + ", w: " + rcl.width + ", h: " + rcl.height);
				//trace("dobc.x: " + _imgv.dobc.x + ", dobc.y: " + _imgv.dobc.y + ", background.width: " + _imgd.background.width + ", height: " + _imgd.background.height);
			} catch (e:InvalidBitmapError) {	
				PicnikBase.app.OnMemoryError(e);
			}				

		}

		private function UpdateGrid(): void {
			_mcOverlay.cacheAsBitmap = true; // Cache as bitmap greatly enhances drawing speed.
			with (_mcOverlay.graphics) {
				clear();
				
				// Grid coordinates are based on the image view, mapped into the overlay
				var cx:Number = _imgv.width;
				var cy:Number = _imgv.height;
				
				// CONSIDER: Optimize grid drawing by one of:
				// - Reduce the number of grid lines (for large images?)
				// - Don't draw lines that won't be needed for images that don't fill the screen
				
				// One way to reduce grid lines for large screens (limit the lines to 20 in the shorter dimension)
				//var nMinGridLines:Number = Math.min(cy/nGridSpacing, cx/nGridSpacing);
				//if (nMinGridLines > 20) nGridSpacing *= (nMinGridLines/20);
	
				// Draw horiz lines
				var i:int;
				for (i = (cy / 2) % knGridSpacing; i < cy; i += knGridSpacing) {
					lineStyle(knGridLineThickness, kcoGrid, knGridAlpha, true);
					moveTo(0, i);
					lineTo(cx - 1, i);

					lineStyle(knGridBackLineThickness, kcoGridBack, knGridBackAlpha, true);
					moveTo(1, i + 1);
					lineTo(cx - 1, i + 1);
				}
				
				// Draw vert lines
				for (i = (cx / 2) % knGridSpacing; i < cx; i += knGridSpacing) {
					lineStyle(knGridLineThickness, kcoGrid, knGridAlpha, true);
					moveTo(i, 0);
					lineTo(i, cy - 1);

					lineStyle(knGridBackLineThickness, kcoGridBack, knGridBackAlpha, true);
					moveTo(i + 1, 0);
					lineTo(i + 1, cy - 1);
				}
			}
			UpdateGridCropRect();
		}

		// CONSIDER: animate the view
		protected function OnRotateLeftClick(evt:MouseEvent): void {
			_radRotation -= Util.krad90;
			if (_radRotation <= -(Util.krad360))
				_radRotation = 0.0;
            dispatchEvent(new Event("radAngleChanged"));
			OnEffectInputsChanged();
		}
		
		protected function OnRotateRightClick(evt:MouseEvent): void {
			_radRotation += Util.krad90;
			if (_radRotation >= Util.krad360)
				_radRotation = 0.0;
            dispatchEvent(new Event("radAngleChanged"));
			OnEffectInputsChanged();
		}

		protected function OnFlipHClick(evt:MouseEvent): void {
			flipH = !flipH;
			_radRotation = -_radRotation;
			radFineRotation = -radFineRotation;
            dispatchEvent(new Event("radAngleChanged"));
			OnEffectInputsChanged();
		}
		
		protected function OnFlipVClick(evt:MouseEvent): void {
			flipV = !flipV;
			_radRotation = -_radRotation;
			radFineRotation = -radFineRotation;
            dispatchEvent(new Event("radAngleChanged"));
			OnEffectInputsChanged();
		}
		
		protected function OnRotationSliderPress(evt:Event): void {
			UpdateGrid();
			_mcOverlay.visible = true;
		}
		
		private function InDragMode(): Boolean {
			return _mcOverlay.visible;
		}
		
		protected function OnRotationSliderRelease(evt:Event): void {
			_mcOverlay.visible = false;
            dispatchEvent(new Event("radAngleChanged"));
			OnEffectInputsChanged(); // Force a redraw. Our rotation didn't change, so update display list won't call UpdateBitmapData
		}

		private function LinearRamp(nVal:Number, nInMin:Number, nInMax:Number, nOutMin:Number, nOutMax:Number): Number {
			return nOutMin +
				(nInMax - nVal) *
				(nOutMax - nOutMin) /
				(nInMax - nInMin);
		}

		// ReversSquareRamp and SquareRamp are used for ramping the slider value
		// so that the slider has more granular control near the origin.
		private function ReverseSquareRamp(nVal:Number, nInMin:Number, nInMax:Number, nOutMin:Number, nOutMax:Number): Number {
			// These functions currently use a quadratic equasion for the ramping,
			// e.g. Y = a X * X + b X, where a = knSquareFactor and b = knLinearFactor

			// First, convert input number to a 0 to 1 range with a sign
			// Note that the range of x is 0 to 1 which means
			// the range of y is 0 to a + b, or knYMax.
			var nY:Number = LinearRamp(nVal, nInMin, nInMax, -knYMax, knYMax);
			var fNeg:Boolean = nY < 0;
			nY = Math.abs(nY);
			
			// Now calc X, such that Y = a * X * X + b * X,
			// therefore (as a quadradic) a * X * X + b * X - Y = 0.
			// Which means X = -b + sqrt(b * b + 4 * a * y) / (2 * a)
			var nX:Number = (Math.sqrt(knLinearFactor * knLinearFactor + 4 * knSquareFactor * nY) - knLinearFactor) / (2 * knSquareFactor);
			if (fNeg) nX = -nX; // Add the sign back in
			
			// Convert back into output params
			nVal = LinearRamp(nX, -1, 1, nOutMin, nOutMax);
			return nVal;
		}

		// This function converts a slider value into a degree value between nOutMin and nOutMax
		// This is a non-linear conversion so that the slider has more granular control near the origin
		// See comments for ReverseSquareRamp.
		private function SquareRamp(nVal:Number, nInMin:Number, nInMax:Number, nOutMin:Number, nOutMax:Number): Number {
			// Convert the input number to a 0 to 1 range with a sign.
			var nX:Number = LinearRamp(nVal, nInMin, nInMax, -1, 1);
			var fNeg:Boolean = nX < 0;
			nX = Math.abs(nX);

			// Now calculate Y using Y = a * X * X + b * X
			// where a = knSquareFactor and b = knLinearFactor			
			var nY:Number = knSquareFactor * nX * nX + knLinearFactor * nX;
			if (fNeg) nY = -nY; // Add the sign back in
			
			// Map linearly from Y to nOutMin and nOutMax
			// Note that the range of x is 0 to 1 which means
			// the range of y is 0 to a + b, or knYMax.
			nVal = LinearRamp(nY, -knYMax, knYMax, nOutMin, nOutMax);
			return nVal;
		}

		[Bindable(event="fineRotationDegChanged")]
		public function get fineRotationSliderValue(): Number {
			return ReverseSquareRamp(radFineRotation, kradMinStraighten, kradMaxStraighten, _sldrRotation.minimum, _sldrRotation.maximum);
		}
		
		private function get radFineRotation(): Number {
			return _radFineRotation;
		}
		
		private function set radFineRotation(radAngle:Number): void {
			if (_radFineRotation != radAngle) {
				_radFineRotation = radAngle;
				dispatchEvent(new Event("fineRotationDegChanged"));
				dispatchEvent(new Event("radAngleChanged"));
				OnEffectInputsChanged();
			}
		}

		// Get the slider value as a radian
		// Must be symetric with SetStraightenSliderRads
		private function GetStraightenSliderRads(): Number {
			return SquareRamp(_sldrRotation.value, _sldrRotation.minimum, _sldrRotation.maximum, kradMinStraighten, kradMaxStraighten);
		}		
	
		protected function OnRotationSliderChange(evt:SliderEvent): void {
			radFineRotation = GetStraightenSliderRads();
		}

		[Bindable(event="fineRotationDegChanged")]
		public function get fineRotationDeg():Number {
			return Math.round(Util.DegFromRad(radFineRotation)*100)/100;
		}
		
		[Bindable(event="radAngleChanged")]
		public function get RadAngle(): Number {
			if (flipV != flipH) {
				return -(_radRotation + radFineRotation);
			} else {
				return _radRotation + radFineRotation;
			}
		}
		
		private function OnEffectInputsChanged(): void {
			_radAnglePrevRender = RadAngle;
			_fFlipHPrevRender = flipH;
			_fFlipVPrevRender = flipV;

			this.OnOpChange();
			
			if (InDragMode())
				UpdateGridCropRect();
		}
	}
}
