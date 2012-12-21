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
	
	[RemoteClass]
	public class SimpleColorMatrixImageOperation extends ColorMatrixImageOperation {
		private var _nSat:Number = 0;
		private var _nBri:Number = 0;
		private var _nCont:Number = 0;
		private var _nHue:Number = 0;
		
		private var _fContrastAndBrighnessLinked:Boolean = false; // Set to true for better brightness/contrast sliders
		
		public function set ContrastAndBrightnessLinked(fContrastAndBrighnessLinked:Boolean): void {
			_fContrastAndBrighnessLinked = fContrastAndBrighnessLinked;
			updateMatrix();
		}
		
		public function set Saturation(nSat:Number): void {
			_nSat = nSat;
			updateMatrix();
		}
		
		public function set Hue(nHue:Number): void {
			_nHue = nHue;
			if (_nHue > 180) _nHue -=360;
			else if (_nHue < -180) _nHue +=360;
			updateMatrix();
		}
		
		public function set Brightness(nBri:Number): void {
			_nBri = nBri;
			updateMatrix();
		}
		
		public function set Contrast(nCont:Number): void {
			_nCont = nCont;
			updateMatrix();
		}
		
		private function updateMatrix(): void {
			var cmat:ColorMatrix = new ColorMatrix();
			cmat.adjustSaturation(_nSat);
			if (_fContrastAndBrighnessLinked) {
				cmat.adjustBrightnessAndContrast(_nBri, _nCont); // Adjust them together so we get smart brightness controls
			} else {
				cmat.adjustContrast(_nCont);
				cmat.adjustBrightness(_nBri);
			}
			cmat.adjustHue(_nHue);
			Matrix = cmat;
		}
		
		public function SimpleColorMatrixImageOperation() {
			// ImageOperation constructors are called with no arguments during Deserialization
			_anMatrix = new ColorMatrix();
		}
	}
}
