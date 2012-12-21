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
package controls
{
	import mx.controls.Button;

	public class ColorPickerButton extends ResizingButton
	{
		private var _clrLeft:uint = 0x808080;
		private var _clrRight:uint = 0x808080;
		
		public function set clrRight(clr:uint): void {
			if (_clrRight != clr) {
				_clrRight = clr;
				setColors();
			}
		}
		
		public function set clrLeft(clr:uint): void {
			if (clr != _clrLeft) {
				_clrLeft = clr;
				setColors();
			}
		}
		
		public function ColorPickerButton()
		{
			super();
			setStyle("icon", ColorPickerSprite);
		}
		
		protected function setColors(): void {
			var sprColor:ColorPickerSprite = null;
			for (var i:Number = 0; i < numChildren; i++) {
				sprColor = getChildAt(i) as ColorPickerSprite;
				if (sprColor) {
					sprColor.Left = _clrLeft;
					sprColor.Right = _clrRight;
				}
			}
		}
		
		protected function get ColorSprite(): ColorPickerSprite {
			for (var i:Number = 0; i < numChildren; i++) {
				if (getChildAt(i) is ColorPickerSprite) return getChildAt(i) as ColorPickerSprite;
			}
			return null;
		}
	}
}