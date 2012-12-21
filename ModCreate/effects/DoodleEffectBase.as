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
package effects {
	import controls.HSBColorPicker;
	
	import flash.events.MouseEvent;
	
	import imagine.imageOperations.paintMask.DoodleStrokes;
	import imagine.imageOperations.paintMask.PaintMaskController;
	
	import mx.controls.ComboBox;

	public class DoodleEffectBase extends PaintOnEffectBase {
		[Bindable] public var _cpkrBrush:HSBColorPicker;
		[Bindable] public var doodleStrokes:DoodleStrokes;
		// [Bindable] public var _cbBlendMode:ComboBoxPlus;
		
		override protected function SliderToBrushSize(nSliderVal:Number): Number {
			return (Math.pow(1.03, nSliderVal) * 21.9)-20.9;
		}
		
		protected function BrushSizeToSlider(nBrushSize:Number): Number {
			return Math.log((nBrushSize + 20.9)/21.9)/Math.log(1.03);
		}
		
		override protected function InitController(): void {
			doodleStrokes = new DoodleStrokes();
			_mctr = new PaintMaskController(doodleStrokes);
		}

		public override function OnOverlayPress(evt:MouseEvent): Boolean {
			_nBrushHardness = 1;
			// _mctr.extraStrokeParams = {color:_cpkrBrush.selectedColor, blendmode: _cbBlendMode.value};
			if (_cpkrBrush) _mctr.extraStrokeParams = {color:_cpkrBrush.selectedColor};
			return super.OnOverlayPress(evt);
		}
	}
}
