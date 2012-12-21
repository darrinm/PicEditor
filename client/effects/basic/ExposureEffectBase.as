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
	
	import controls.HSliderFastDrag;
	
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.utils.getTimer;
	
	import imageUtils.Channel;
	import imageUtils.Histogram;
	
	import imagine.imageOperations.BlurImageOperation;
	import imagine.imageOperations.LocalContrastImageOperation;
	import imagine.imageOperations.NestedImageOperation;
	import imagine.imageOperations.PaletteMapImageOperation;
	
	import mx.controls.Button;
	import mx.controls.HSlider;
	import mx.effects.Resize;
	import mx.events.SliderEvent;
		
	public class ExposureEffectBase extends CoreEditingEffect {
		// MXML-defined variables
		[Bindable] public var _sldrContrast:HSlider;
		[Bindable] public var _btnAutoFix:Button;

		[Bindable] public var _sldrExposure:HSlider;
		[Bindable] public var _sldrShadows:HSlider;
		[Bindable] public var _sldrHighlights:HSlider;
		
		public var _strAutoFixNotifyMessage:String;
			
		private var _nContrastSliderPrev:Number = Number.MAX_VALUE;
		private var _nExposureSliderPrev:Number = Number.MAX_VALUE;
		private var _nLevelMinPrev:Number = Number.MAX_VALUE;
		private var _nLevelMaxPrev:Number = Number.MAX_VALUE;

		private var _hgOrig:Histogram;
		private var _chnlRGB:Channel;
		private var _chnlRGBOrig:Channel;
		private var _nMedianOrig:Number;
		private var _nMedian:Number;
		private var _nGamma:Number = 1.0;

		public override function OnSelectedEffectReallyDone():void {
			super.OnSelectedEffectReallyDone();
			// When NestedControlCanvasBase first calculates the height of this control,
			// the help text isn't laid out and wrapped yet, so the initial height that we animate to is too low.
			// This block makes sure that we animate to the true full height of the control in that case.
			UpdateHeight();
			if (this.height != this.fullHeight) {
				var resize:Resize = new Resize(this);
				resize.heightFrom = this.height;
				resize.heightTo = this.fullHeight;
				resize.duration = 200;
				resize.play();
			}
		}

		override public function Select(efcnvCleanup:NestedControlCanvasBase):Boolean {
			if (super.Select(efcnvCleanup)) {
	
				_sldrContrast.value = 0;
				_sldrExposure.value = 0;
				_sldrShadows.value = 0;
				_sldrHighlights.value = 0;

				_nContrastSliderPrev = 0;
				_nExposureSliderPrev = 0;
				_nLevelMinPrev = 0;
				_nLevelMaxPrev = 255;

				// Clear any operations left from our last invocation
				var nestedImageOperation:NestedImageOperation = NestedImageOperation(this.operation);
				nestedImageOperation.children = new Array();

				SetLevels(0, 255);

				// No changes allowed until we have a histogram
				this.enabled = false;
				// Histogram calculation is async
				_hgOrig = new Histogram();
				_hgOrig.Calculate(_imgd.background, Channel.kichnlRGB, true, OnHistogramCalcDone);
				return true;
			}
			return false;
		}
		
		override public function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null):void {
			super.Deselect(fForceRollOutEffect, efcvsNew);
		}
		
		private function OnHistogramCalcDone():void {
			this.enabled = true;
			_chnlRGBOrig = _hgOrig.channels[Channel.kichnlRGB];
			_nMedian = _nMedianOrig = _chnlRGBOrig.GetMedian();
			_chnlRGB = _chnlRGBOrig.Clone();
		}

		protected function OnAutoFixClick(evt:MouseEvent): void {
			/* Timing test (AMD64 x2 2.4GHz, whales_3072x2048.jpg):
			* PaletteMap took 110.2 ms
			* ColorMatrix took 54.8 ms
			if (false) {
				var pal:Palette = new Palette();
				pal.AdjustBrightness(_sldrBrightness.value);
				pal.Clamp();
				var ampco:Array = pal.GetPaletteMapArrays();
				
				var cmsStart:Number = getTimer();
				for (var i:Number = 0; i < 10; i++) {
					var bmd:BitmapData = PaletteMapImageOperation.ApplyPaletteMap(_bmdOrig, ampco[0], ampco[1], ampco[2]);
					bmd.dispose();
				}
				trace("PaletteMap took " + ((getTimer() - cmsStart) / 10) + " ms");
				
				var cmat:Array = CalcCombinedColorMatrix();
				cmsStart = getTimer();
				for (var i:Number = 0; i < 10; i++) {
					var bmd:BitmapData = ColorMatrixImageOperation.ApplyColorMatrix(_bmdOrig, cmat);
					bmd.dispose();
				}
				trace("ColorMatrix took " + ((getTimer() - cmsStart) / 10) + " ms");
				return;
			}
			*/
			
			var ob:Object = _chnlRGBOrig.GetMinMax(0.1, 0.1); // CONFIG:
			SetLevels(ob.min, ob.max);
			PicnikBase.app.Notify(_strAutoFixNotifyMessage);
		}
		
		protected function OnExposureSliderChange(evt:Event): void {
			_nGamma = GammaFromSliderPos(_sldrExposure.value);
			ApplyChanges();
		}
		
		public function HighlightsUpdated(nSliderVal:Number): void {
			// As the slider goes from 0 to 100, the max val goes from 255 to 128
			var nMaxVal:Number = 255 - (nSliderVal * 1.27);
			// Don't update if the slider is maxed and the max val out of range (<128)
			if (nSliderVal == 100 && LevelMax <= 128) return;
			// Make sure we limit any auto-adjust to reasonable values before dragging the slider.
			var nMinVal:Number = (LevelMax != nMaxVal && LevelMin > 127) ? 127 : LevelMin;
			SetLevels(nMinVal, nMaxVal);
		}

		public function ShadowsUpdated(nSliderVal:Number): void {
			// As the slider goes from 0 to 100, the min val goes from 0 to 127
			var nMinVal:Number = nSliderVal * 1.27;
			// Don't update if the slider is maxed and the min val is >= 127
			if (nSliderVal == 100 && nMinVal >= 127) return;
			// Make sure we limit any auto-adjust to reasonable values before dragging the slider.
			var nMaxVal:Number = (LevelMin != nMinVal && LevelMax < 128) ? 128 : LevelMax;
			SetLevels(nMinVal, nMaxVal);
		}
		
		private var _nMinVal:Number = 0;
		private var _nMaxVal:Number = 255;

		private function get LevelMin(): Number {
			return _nMinVal;
		}

		private function get LevelMax(): Number {
			return _nMaxVal;
		}
		
		private function SetLevels(min:Number, max:Number):void {
			if (min != LevelMin || max != LevelMax) {
				_nMinVal = min;
				// Shadow slider value goes from 0 to 100 as min slider goes from 0 to 127
				_sldrShadows.value = Math.min(100, min/1.27);
				_nMaxVal = max;
				// Highlight slider value goes from 0 to 100 as max slider goes from 255 to 128
				_sldrHighlights.value = Math.min(100, (255-max)/1.27);
				ApplyChanges();
			}
		}

		protected function OnContrastSliderChange(evt:SliderEvent): void {
			ApplyChanges();
		}

		private function ApplyChanges(): void {
			var nStart:Number = getTimer();

			// Don't waste time updating if the relevant state hasn't changed
			if (_sldrContrast.value == _nContrastSliderPrev &&
					_sldrExposure.value == _nExposureSliderPrev &&
					LevelMin == _nLevelMinPrev &&
					LevelMax == _nLevelMaxPrev
					) {
				return;
			}
				
			_nContrastSliderPrev = _sldrContrast.value;
			_nExposureSliderPrev = _sldrExposure.value;
			_nLevelMinPrev = LevelMin;
			_nLevelMaxPrev = LevelMax;

			var nestedImageOperation:NestedImageOperation = NestedImageOperation(this.operation);
			nestedImageOperation.children = new Array();
			
			// If the user changed something then create an undo transaction
			var fPaletteMap:Boolean = (_sldrContrast.value != 0 || LevelMin != 0 || LevelMax != 255 || _sldrExposure.value != 0);
			if  (fPaletteMap) {
				var chnlMap:Channel = CalcCombinedMap();

				if (fPaletteMap) {
					var mpcoRed:Array = chnlMap.GetPaletteMapArray(Channel.kichnlRed);
					var mpcoGreen:Array = chnlMap.GetPaletteMapArray(Channel.kichnlGreen);
					var mpcoBlue:Array = chnlMap.GetPaletteMapArray(Channel.kichnlBlue);
					nestedImageOperation.children.push(new PaletteMapImageOperation(mpcoRed, mpcoGreen, mpcoBlue));
				}
				
				// Update Histogram
				_chnlRGB = _chnlRGBOrig.Clone();
				_chnlRGB.Remap(chnlMap);
			}

			this.OnOpChange();

			
	//		trace("nMedian old: " + _nMedian + ", nMedian new: " + _chnlRGB.GetMedian());
	//		_nMedian = _chnlRGB.GetMedian(); // UNDONE: not good to have CalcCombinedMap use the _nMedian it influences
			updateSpeed = getTimer() - nStart;
		}
		
		// constant for contrast calculations: (thanks to Grant Skinner)
		private static var DELTA_INDEX:Array = [
			0,    0.01, 0.02, 0.04, 0.05, 0.06, 0.07, 0.08, 0.1,  0.11,
			0.12, 0.14, 0.15, 0.16, 0.17, 0.18, 0.20, 0.21, 0.22, 0.24,
			0.25, 0.27, 0.28, 0.30, 0.32, 0.34, 0.36, 0.38, 0.40, 0.42,
			0.44, 0.46, 0.48, 0.5,  0.53, 0.56, 0.59, 0.62, 0.65, 0.68,
			0.71, 0.74, 0.77, 0.80, 0.83, 0.86, 0.89, 0.92, 0.95, 0.98,
			1.0,  1.06, 1.12, 1.18, 1.24, 1.30, 1.36, 1.42, 1.48, 1.54,
			1.60, 1.66, 1.72, 1.78, 1.84, 1.90, 1.96, 2.0,  2.12, 2.25,
			2.37, 2.50, 2.62, 2.75, 2.87, 3.0,  3.2,  3.4,  3.6,  3.8,
			4.0,  4.3,  4.7,  4.9,  5.0,  5.5,  6.0,  6.5,  6.8,  7.0,
			7.3,  7.5,  7.8,  8.0,  8.4,  8.7,  9.0,  9.4,  9.6,  9.8,
			10.0
		];
		
		private function CalcCombinedMap():Channel {
			var chnlMap:Channel = new Channel(256);
			chnlMap.SetIdentityMapping();
			
			if (LevelMin != 0 || LevelMax != 255)
				chnlMap.StretchLevels(LevelMin, LevelMax);
			
			if (_nGamma != 1.0)
				chnlMap.AdjustGamma(_nGamma);
	
			// Convert slider range (-100, 100) to a linear-feeling multiplier
			if (_sldrContrast.value != 0) {
				if (_sldrContrast.value < 0)
					chnlMap.AdjustContrast(1 + (_sldrContrast.value / 100), _nMedian);
				else {
					var nValue:Number = _sldrContrast.value;
					
					// Get the decimal fraction
					var nFraction:Number = nValue % 1;
					nValue = int(nValue);

					// Use the fraction to interpolate
					var nMultiplier:Number = 1 + (DELTA_INDEX[nValue] * (1 - nFraction));
					// Add the fractional portion as long as we don't extend beyond the range of DELTA_INDEX
					if ((nValue + 1) < DELTA_INDEX.length) {
						nMultiplier += DELTA_INDEX[nValue + 1] * nFraction;
					}
					chnlMap.AdjustContrast(nMultiplier, _nMedian);
				}
			}
			
			chnlMap.Clamp();
			return chnlMap;
		}
	
		/*
		private function CalcCombinedColorMatrix():Array {
			var cmat:ColorMatrix = new ColorMatrix();
			cmat.adjustBrightness(_sldrBrightness.value);
			if (_anMin) {
				cmat.concat([	255 / (_anMax[0] - _anMin[0]), 0, 0, 0, 0,
								0, 255 / (_anMax[1] - _anMin[1]), 0, 0, 0,
								0, 0, 255 / (_anMax[2] - _anMin[2]), 0, 0,
								0, 0, 0, 1, 0 ]);
				cmat.concat([ 	1, 0, 0, 0, -_anMin[0],
								0, 1, 0, 0, -_anMin[1],
								0, 0, 1, 0, -_anMin[2],
								0, 0, 0, 1, 0 ]);
			}
			// UNDONE: adjust contrast around the median w/ our own matrix math
			cmat.adjustContrast(_sldrContrast.value);
			return cmat;
		}
		*/
		

		// Returns a value in the range from -100 to 100
		// nGamma must be in the range from 0.1 to 10.0
		private function SliderPosFromGamma(nGamma:Number):Number {
			Debug.Assert(nGamma >= 0.1 && nGamma <= 10.0, "SliderPosFromGamma 0.1 <= nGamma <= 10.0");
				
			return Math.round(100 * (Math.log(1.0 / nGamma) / Math.LN10));
		}
		
		// Returns a value in the range from 0.1 to 10.0
		// nPos must be in the range from -100 to 100
		private function GammaFromSliderPos(nPos:Number):Number {
			Debug.Assert(nPos >= -100 && nPos <= 100, "GammaFromSliderPos -100 <= nPos <= 100");
				
			return 1.0 / Math.pow(10, nPos / 100.0)
		}
	}
}
