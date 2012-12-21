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
	
	[RemoteClass]
	public class BWImageOperation extends ColorMatrixImageOperation {
		private var _coFilter:Number = -1;
	
		// Luminance color weights
		private const knLumR:Number = 0.3086;
		private const knLumG:Number = 0.6094;
		private const knLumB:Number = 0.0820;
		
		public function set filtercolor(coFilter:Number): void {
			if (_coFilter != coFilter) {
				_coFilter = coFilter;
				updateMatrix();
			}
		}
		
		private function updateMatrix(): void {
			// Use the filter color to create a color map
			// Default color is white - no filter.
			// Filter strength is euqual to the saturation of the target color
			var nR:Number = RGBColor.RedFromUint(_coFilter);
			var nG:Number = RGBColor.GreenFromUint(_coFilter);
			var nB:Number = RGBColor.BlueFromUint(_coFilter);
	
			// 1. Multiply default luminosity by filter (max strength)
			var nLumFiltR:Number = knLumR * nR;
			var nLumFiltG:Number = knLumG * nG;
			var nLumFiltB:Number = knLumB * nB;
			
			// 2. Normailze (sum should equal 1)
			var nLumFiltSum:Number = nLumFiltR + nLumFiltG + nLumFiltB;
			nLumFiltR /= nLumFiltSum;
			nLumFiltG /= nLumFiltSum;
			nLumFiltB /= nLumFiltSum;

			_anMatrix = [
					nLumFiltR, nLumFiltG, nLumFiltB, 0, 0,
					nLumFiltR, nLumFiltG, nLumFiltB, 0, 0,
					nLumFiltR, nLumFiltG, nLumFiltB, 0, 0,
					0, 0, 0, 1, 0 ];
		}
		
		public function BWImageOperation() {
			// ImageOperation constructors are called with no arguments during Deserialization
			updateMatrix();
		}
	}
}
