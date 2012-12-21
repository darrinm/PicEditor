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
package imagine.imageOperations {
	import flash.filters.ColorMatrixFilter;
	import overlays.helpers.RGBColor;
	import flash.display.BlendMode;
	
	[RemoteClass]
	public class IRImageOperation extends NestedImageOperation {
		// Configs
		private var _nGreenGlow:Number = 5;
		private var _nGreenGlowAlpha:Number = .25;
		private var _nRedWeight:Number = -.5;
		
		public function set greenglow(nGreenGlow:Number): void {
			_nGreenGlow = nGreenGlow;
			updateChildren();
		}
		
		public function set greenglowalpha(nGreenGlowAlpha:Number): void {
			_nGreenGlowAlpha = nGreenGlowAlpha;
			updateChildren();
		}

		public function set redweight(nRedWeight:Number): void {
			_nRedWeight = nRedWeight;
			updateChildren();
		}

		private function updateChildren(): void {
			/*
			Nest
			- Nest, blend = screen, 25%
			- - ColorMatrix: Select green channel
			- - Blur (3?)
			- ColorMatrix: 2G -.6R -.4B
			*/
			
			_aopChildren.length = 0;
			
			var opGreenGlow:NestedImageOperation = new NestedImageOperation();

			var anGreenOnlyMatrix:Array = [
					0, 0, 0, 0, 0,
					0, 1, 0, 0, 0,
					0, 0, 0, 0, 0,
					0, 0, 0, 1, 0 ];
			var opGreenOnly:ColorMatrixImageOperation = new ColorMatrixImageOperation(anGreenOnlyMatrix);
			opGreenGlow.push(opGreenOnly);
			var opBlur:BlurImageOperation = new BlurImageOperation(1, _nGreenGlow, _nGreenGlow, 3);
			opGreenGlow.push(opBlur);
			opGreenGlow.BlendMode = flash.display.BlendMode.SCREEN;
			opGreenGlow.BlendAlpha = _nGreenGlowAlpha;
			push(opGreenGlow);
			
			var nBlueWeight:Number = -1 - _nRedWeight;
			
			var anIRMatrix:Array = [
					_nRedWeight, 2, nBlueWeight, 0, 0,
					_nRedWeight, 2, nBlueWeight, 0, 0,
					_nRedWeight, 2, nBlueWeight, 0, 0,
					0, 0, 0, 1, 0 ];
			var opIR:ColorMatrixImageOperation = new ColorMatrixImageOperation(anIRMatrix);
			push(opIR);
		}
		
		public function IRImageOperation() {
			// ImageOperation constructors are called with no arguments during Deserialization
			updateChildren();
		}
	}
}
