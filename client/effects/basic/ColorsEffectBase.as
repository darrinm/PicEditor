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
	import com.gskinner.geom.ColorMatrix;
	
	import containers.NestedControlCanvasBase;
	
	import controls.ColorPickerButton;
	import controls.HSliderFastDrag;
	
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import imagine.imageOperations.ColorMatrixImageOperation;
	
	import mx.controls.Button;
	import mx.events.SliderEvent;
	
	import overlays.helpers.Cursor;
	import overlays.helpers.RGBColor;
	import overlays.helpers.WBAdjustment;
	
	import util.VBitmapData;
		
	public class ColorsEffectBase extends CoreEditingEffect implements IOverlay {
		private const NEUTRAL_GRAY:uint = 0x808080;

		// MXML-defined variables
		[Bindable] public var _sldrSaturation:HSliderFastDrag;
		[Bindable] public var _sldrTemp:HSliderFastDrag;
		[Bindable] public var _btnAutoColors:Button;
		[Bindable] public var _btnNeutralPicker:ColorPickerButton;
		[Bindable] public var _clrNeutral:uint = NEUTRAL_GRAY;
		[Bindable] public var _clrNeutralMouse:uint = NEUTRAL_GRAY;
		
		private var _mcOverlay:MovieClip = null;
		private var _nGreen:Number = 1;
		private var _bmdOrig:BitmapData = null;

		// Radius of eyedropper sample
		private static const knSampleRadius:Number = 2; // 3 pixel radius sample

		// Constants for accelerated sliding
		// Slider goes from -100 to 100
		// temp goes from -1 to 1
		// Use sign variable to make everything positive
		// Use linear dragging between 0 and kSldrSlowVal slider position
		// and 0 and kSldrSlowTemp temp
		// after that, use a quadratic equation (y = ax^2 + bx + c) that
		// satisfies the following:
		//  - dy/dx is the same as the linear slope (i.e. kSldrSlowVal/kSldrSlowTemp)
		//  - the equation includes the following points:
		//     - kSldrSlowVal, kSldrSlowTemp
		//     - 1, 100
		private static const kSldrSlowVal:Number = 75;
		private static const kSldrSlowTemp:Number = 0.25;
		
		// These constants represent the two points our equation must
		// intersect
		private static const kX1:Number = kSldrSlowVal;
		private static const kX2:Number = 100;
		private static const kY1:Number = kSldrSlowTemp;
		private static const kY2:Number = 1;
		
		// Based on those two points and the fact that dy/dx at X1 = Y1/X1
		// We can solve for our quadratic constants, a, b, and c, as follows:
		private static const knA:Number = (kY2 - kX2*kY1/kX1) / ((kX2-kX1)*(kX2-kX1));
		private static const knB:Number = kY1/kX1 - 2 * kX1 * knA;
		private static const knC:Number = kX1 * kX1 * knA;

		// -kSldrSlowVal to kSldrSlowVal translates into -kSldrSlowTemp to kSldrSlowTemp
		// kSldrSlowVal to 100 translates kSldrSlowTemp to 1
		// -kSldrSlowVal to -100 translates -kSldrSlowTemp to -1
		
		private static function TranslateSpace(n:Number, nMin:Number, nMax:Number, nNewMin:Number, nNewMax:Number): Number {
			return ((n - nMin)/(nMax-nMin)) * (nNewMax - nNewMin) + nNewMin;
		}

		protected function OnNeutralPickerClick(evt:MouseEvent): void {
			if (_btnNeutralPicker.selected) {
				_mcOverlay = _imgv.CreateOverlay(this);
				_imgv.overlayCursor = Cursor.csrEyedropper;
			} else {
				_imgv.DestroyOverlay(_mcOverlay);
				_mcOverlay = null;
				_clrNeutralMouse = _clrNeutral;
			}
		}
		
		private function AverageColor(bmdSrc:BitmapData, pt:Point, nRadius:Number): Object {
			var nRTot:Number = 0;
			var nGTot:Number = 0;
			var nBTot:Number = 0;
			var nWTot:Number = 0;
			var rcClick:Rectangle = new Rectangle(pt.x, pt.y, 0, 0);
			rcClick.inflate(nRadius, nRadius);
			rcClick = rcClick.intersection(bmdSrc.rect);
			var nMaxDist:Number = nRadius * Math.sqrt(2);
			nMaxDist *= 2; // Weaken the effect of distance
			for (var x:Number = rcClick.left; x < rcClick.right; x++) {
				for (var y:Number = rcClick.top; y < rcClick.bottom; y++) {
					var clr:uint = bmdSrc.getPixel(x, y);
					var nDist:Number = Point.distance(pt, new Point(x,y));
					var nWeight:Number = (nMaxDist - nDist) / nMaxDist;
					nWTot += nWeight;
					nRTot += RGBColor.RedFromUint(clr) * nWeight;
					nGTot += RGBColor.GreenFromUint(clr) * nWeight;
					nBTot += RGBColor.BlueFromUint(clr) * nWeight;
				}
			}
			var nR:Number = nRTot / nWTot;
			var nG:Number = nGTot / nWTot;
			var nB:Number = nBTot / nWTot;
			return {nR:nR, nG:nG, nB:nB};
		}

		private function SetNeutralColor(bmd:BitmapData, ptClick:Point): void {
			var obColor:Object = AverageColor(bmd, ptClick, knSampleRadius);
			var wba:WBAdjustment = WBAdjustment.WBToNeutralizeRGB(obColor.nR, obColor.nG, obColor.nB);
			if (wba.IsValid()) {
				_clrNeutral = RGBColor.RGBtoUint(obColor.nR, obColor.nG, obColor.nB);
				_nGreen = wba.Green();
				_sldrTemp.value = TempToTempSliderVal(wba.Temp());
				OnSettingsUpdated();
			}
		}

		public function OnOverlayMouseMove(): Boolean {
			var rclClick:Rectangle = new Rectangle(_mcOverlay.mouseX, _mcOverlay.mouseY, 0, 0);
			var rcdClick:Rectangle = _imgv.RcdFromRcl(rclClick);

			var ptClick:Point = rcdClick.topLeft;
			if (ptClick.x < 0 || ptClick.y < 0 || ptClick.x >= _bmdOrig.width || ptClick.y >= _bmdOrig.height) {
				// Out of bounds
			} else {
				var obColor:Object = AverageColor(_bmdOrig, ptClick, knSampleRadius);
				_clrNeutralMouse = RGBColor.RGBtoUint(obColor.nR, obColor.nG, obColor.nB);
			}

			return true; // handled the event.
		}

		public function OnOverlayMouseMoveOutside(): Boolean {
			return true;
		}

		public function OnOverlayPress(evt:MouseEvent): Boolean {
			var rclClick:Rectangle = new Rectangle(_mcOverlay.mouseX, _mcOverlay.mouseY, 0, 0);
			var rcdClick:Rectangle = _imgv.RcdFromRcl(rclClick);

			var ptClick:Point = rcdClick.topLeft;
			if (ptClick.x < 0 || ptClick.y < 0 || ptClick.x >= _bmdOrig.width || ptClick.y >= _bmdOrig.height) {
				// Out of bounds
			} else {
				SetNeutralColor(_bmdOrig, ptClick);
			}

			return true; // handled the event.
		}

		public function OnOverlayPressOutside(): Boolean {
			return true;
		}

		public function OnOverlayRelease(): Boolean {
			return true;
		}

		public function OnOverlayReleaseOutside(): Boolean {
			return true;
		}

		public function OnOverlayDoubleClick(): Boolean {
			return true;
		}
		
		override public function Select(efcnvCleanup:NestedControlCanvasBase):Boolean {
			if (super.Select(efcnvCleanup)) {
				_clrNeutral = NEUTRAL_GRAY;
				_clrNeutralMouse = NEUTRAL_GRAY;
				_nGreen = 1;
				_sldrSaturation.value = 0;
				_sldrTemp.value = 0;
				_bmdOrig = _imgd.background.clone();
				_btnNeutralPicker.selected = false;
				OnSettingsUpdated();
				return true;
			}
			return false;
		}
		
		override public function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null):void {
			if (_bmdOrig) {
				_bmdOrig.dispose();
				_bmdOrig = null;
			}
			if (_mcOverlay) {
				_imgv.DestroyOverlay(_mcOverlay);
				_mcOverlay = null;
			}
			super.Deselect(fForceRollOutEffect, efcvsNew);
		}

		protected function OnAutoColorsClick(evt:MouseEvent): void {
			// First, compress the bitmap to our sample size;
			var bmd:BitmapData = _bmdOrig;
			var nReduceSize:Number = 4;
			var nMaxArea:Number = 100;
			while ((bmd.width * bmd.height) > nMaxArea) {
				var bmdTmp:BitmapData = bmd;
				bmd = new VBitmapData(Math.round(bmdTmp.width/nReduceSize), Math.round(bmdTmp.height/nReduceSize));
				var matScale:Matrix = new Matrix();
				matScale.scale(1/nReduceSize, 1/nReduceSize);
				bmd.draw(bmdTmp, matScale, null, null, null, true); // Turn smoothing on
				if (bmdTmp != _bmdOrig) bmdTmp.dispose();
			}
			
			var nRTot:Number = 0;
			var nGTot:Number = 0;
			var nBTot:Number = 0;
			var nTot:Number = 0;
			
			// Now bmd is a reduced bitmap (with smoothing on), small enough to check all pixels
			for (var x:Number = 0; x < bmd.width; x++) {
				for (var y:Number = 0; y < bmd.height; y++) {
					var clr:uint = bmd.getPixel(x, y);
					nRTot += RGBColor.RedFromUint(clr);
					nGTot += RGBColor.GreenFromUint(clr);
					nBTot += RGBColor.BlueFromUint(clr);
					nTot++;
				}
			}
			bmd.dispose();
			
			var wba:WBAdjustment = WBAdjustment.WBToNeutralizeRGB(nRTot/nTot, nGTot/nTot, nBTot/nTot);
			_nGreen = wba.Green();
			_sldrTemp.value = TempToTempSliderVal(wba.Temp());
			OnSettingsUpdated();
		}

		private function TempSliderValToTemp(nSliderVal:Number): Number {
			var nSign:Number = 1;
			if (nSliderVal < 0) {
				nSliderVal = -nSliderVal;
				nSign = -1;
			}
			var nTemp:Number;
			// Now nSlider val is from 0 to 100
			if (nSliderVal < kSldrSlowVal) {
				// Slow speed
				nTemp = TranslateSpace(nSliderVal, 0, kSldrSlowVal, 0, kSldrSlowTemp);
			} else {
				// Fast speed, use y = ax^2 + bx + c
				// x = nSliderVal, a,b,c constants above, and y = return val
				var x:Number = nSliderVal;
				nTemp = knA * x * x + knB * x + knC;
			}
			return nTemp * nSign;
		}

		private function TempToTempSliderVal(nTemp:Number): Number {
			var nSign:Number = 1;
			if (nTemp < 0) {
				nTemp = -nTemp;
				nSign = -1;
			}
			if (nTemp < kSldrSlowTemp) {
				return nSign * TranslateSpace(nTemp, 0, kSldrSlowTemp, 0, kSldrSlowVal);
			} else {
				// Reverse our quadratic equation
				// given y = ax^2 + bx * c, solve for x given y
				// We know that x = (-b +- sqrt(b^2-4ac'))/(2a), where c' = c-y
				// Since we know we are on the right hand side of the curve,
				// we can assume the +- goes to +, which gives us:
				var nC:Number = knC - nTemp;
				return nSign * (Math.sqrt(knB * knB - 4 * knA * nC) - knB)/(2 * knA);
			}
		}

		protected function OnSaturationSliderChange(evt:SliderEvent): void {
			OnSettingsUpdated();
		}
		
		protected function OnHueSliderChange(evt:SliderEvent): void {
			OnSettingsUpdated();
		}

		private function OnSettingsUpdated(): void {
			
			var cmat:ColorMatrix = new ColorMatrix();
			cmat.adjustSaturation(_sldrSaturation.value);
			var wb:WBAdjustment = WBAdjustment.WBFromTempAndGreen(TempSliderValToTemp(_sldrTemp.value), _nGreen);
			cmat.adjustWB(wb.RMult, wb.GMult, wb.BMult);
			var op:ColorMatrixImageOperation = ColorMatrixImageOperation(this.operation);
			op.Matrix = cmat;
			OnOpChange();
		}
	}
}
