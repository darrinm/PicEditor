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
package imagine.imageOperations
{
	// This is a nested image operation that first desaturates, then applies a color tint.
	// Set _bAutoLevels to true and the tint will expand to fill the range.
	// Tint works like a Color overlay in photoshop - it tries to maintain the
	// same distance between R,G,and B components, while maintaining luminosity.
	// At the upper and lower ends, clipping will occur.

	[RemoteClass]
	public class TwoToneImageOperation extends GradientMapImageOperation
	{
		private var _clrWhite:Number = 0xFF1000; // Yellow
		private var _clrBlack:Number = 0x004080; // Blue/green
		
		public function set whiteColor(clr:Number): void {
			if (_clrWhite != clr) {
				_clrWhite = clr;
				UpdateArrays();
			}
		}
		
		public function set blackColor(clr:Number): void {
			if (_clrBlack != clr) {
				_clrBlack = clr;
				UpdateArrays();
			}
		}

		public function TwoToneImageOperation()
		{
		}
		
		protected function UpdateArrays(): void {
			gradientArray = [_clrBlack, _clrWhite];
		}
	}
}