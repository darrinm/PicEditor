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
	public class AlphaMapImageOperation extends ColorMatrixImageOperation {
		private var _coFilter:Number = 0;
	
		public function set Color(coFilter:Number): void {
			if (_coFilter != coFilter) {
				_coFilter = coFilter;
				updateMatrix();
			}
		}
		
		private function updateMatrix(): void {
			
			// Use the filter color to create a color map
			var nR:Number = RGBColor.RedFromUint(_coFilter);
			var nG:Number = RGBColor.GreenFromUint(_coFilter);
			var nB:Number = RGBColor.BlueFromUint(_coFilter);

			_anMatrix = [
					0, 0, 0, 0, nR,
					0, 0, 0, 0, nG,
					0, 0, 0, 0, nB,
				   -1, 0, 0, 0, 255 ];
		}
		
		public function AlphaMapImageOperation() {
			// ImageOperation constructors are called with no arguments during Deserialization
			updateMatrix();
		}
	}
}
