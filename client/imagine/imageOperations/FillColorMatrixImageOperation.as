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
	import com.gskinner.geom.ColorMatrix;
	import flash.geom.Point;
	import flash.display.BitmapData;
	import flash.filters.ColorMatrixFilter;
	import overlays.helpers.RGBColor;
	
	[RemoteClass]
	public class FillColorMatrixImageOperation extends ColorMatrixImageOperation {
		private var _clr:Number = 0;
		
		public function set Color(clr:Number): void {
			_clr = clr;
			updateMatrix();
		}
		
		private function updateMatrix(): void {
			Matrix = [0, 0, 0, 0, RGBColor.RedFromUint(_clr),
				0, 0, 0, 0, RGBColor.GreenFromUint(_clr),
				0, 0, 0, 0, RGBColor.BlueFromUint(_clr),
				0, 0, 0, 1, 0]
		}
		
		//	cmat.adjustSaturation(20);
		//	cmat.adjustContrast(40);
		//	cmat.adjustBrightness(-20);
		
		public function FillColorMatrixImageOperation () {
			// ImageOperation constructors are called with no arguments during Deserialization
			updateMatrix();
		}
	}
}
