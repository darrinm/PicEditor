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
	
	import imagine.imageOperations.BlendImageOperation;
	import imagine.imageOperations.LocalContrastImageOperation;
	import imagine.imageOperations.NestedImageOperation;
	import imagine.imageOperations.SharpenImageOperation;
	import imagine.serialization.SerializationUtil;
	
	import mx.controls.Button;
	import mx.controls.HSlider;
	import mx.core.Container;
	import mx.effects.Fade;
	import mx.effects.Resize;
		
	public class SharpenEffectBase extends CoreEditingEffect {
		// MXML-defined variables
		[Bindable] public var _sldrSharpness:HSlider;
		[Bindable] public var _sldrRadius:HSlider;
		[Bindable] public var _sldrStrength:HSlider;
		[Bindable] public var _sldrClarity:HSlider;
		[Bindable] public var _btnUnsharp:Button;
		public var basicControls:Container;
		public var advancedControls:Container;
		public var _op:NestedImageOperation;
		public var _opClarity:LocalContrastImageOperation;
		public var _opUnsharpMask:LocalContrastImageOperation;
		public var _opSharpen:SharpenImageOperation;
		public var fadeIn:Fade;
		public var fadeOut:Fade;
		public var resize:Resize;
		
		private var _strRenderedState:String = "";

		override public function Select(efcnvCleanup:NestedControlCanvasBase):Boolean {
			_sldrSharpness.value = 0;
			_sldrRadius.value = 1;
			_sldrStrength.value = 0;
			_sldrClarity.value = 0;
			_btnUnsharp.selected = false;
			return super.Select(efcnvCleanup);
		}

		protected function toggleAdvanced(): void {
			callLater(animateToNewHeight, [this.fullHeight]);
			updateCurrentOperation();
		}

		private function animateToNewHeight(oldHeight:Number):void {
			this.UpdateHeight();

			resize.target = this;
			resize.heightTo = fullHeight;
			resize.heightFrom = oldHeight;
			resize.play();

			fadeIn.target = _btnUnsharp.selected ? advancedControls : basicControls;
			fadeOut.target = !_btnUnsharp.selected ? advancedControls : basicControls;
			this.fadeIn.play();
			this.fadeOut.play();
		}
		
		protected function updateCurrentOperation(): void {
			_op.children = [_opClarity];
			_op.push(_btnUnsharp.selected ? _opUnsharpMask : _opSharpen);
			var strNewState:String = SerializationUtil.WriteToString(operation);
			if (strNewState != _strRenderedState) {
				_strRenderedState = strNewState;
				
				OnOpChange();
			}
		}
	}
}
