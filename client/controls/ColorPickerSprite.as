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
	import mx.core.SpriteAsset;
	import flash.display.GradientType;
	import flash.geom.Matrix;
	
	public class ColorPickerSprite extends SpriteAsset
	{
		private var _clrLeft:uint = 0x808080;
		private var _clrRight:uint = 0x808080;
		
		public function ColorPickerSprite() {
			updateGraphics();
		}
		
		public function updateGraphics(): void {
			var cxTotalBoxWidth:Number = 32;

			var x:Number = 2;
			var y:Number = 1;
			var cxWidth:Number = cxTotalBoxWidth/2;
			var cyHeight:Number = 25;
			var cxyEllipseRadius:Number = 0;
			
			graphics.clear();
			
			graphics.beginFill(0, 0);
			graphics.lineStyle(3, 0, 1, true);
			var aclrs:Array = [0xC0C0C0, 0xffffff];
			var anAlphas:Array = [1, 1];
			var anRatios:Array = [0, 255];
			var mat:Matrix = new Matrix();
			mat.createGradientBox(cxTotalBoxWidth, cyHeight, Math.PI / 2, x, y);
			graphics.lineGradientStyle(GradientType.LINEAR, aclrs, anAlphas, anRatios, mat);
			graphics.drawRoundRect(x, y, cxTotalBoxWidth-1, cyHeight-1, cxyEllipseRadius * 2);
			
			graphics.lineStyle(0, 0, 0);

			cxyEllipseRadius = 0;
			
			graphics.beginFill(_clrLeft);
			graphics.drawRoundRectComplex(x, y, cxWidth, cyHeight, cxyEllipseRadius, 0, cxyEllipseRadius, 0);

			x += cxWidth;
			graphics.beginFill(_clrRight);
			graphics.drawRoundRectComplex(x, y, cxWidth, cyHeight, 0, cxyEllipseRadius, 0, cxyEllipseRadius);
		}
		
		public function set Left(clr:uint): void {
			if (_clrLeft != clr) {
				_clrLeft = clr;
				updateGraphics();
			}
		}

		public function set Right(clr:uint): void {
			if (_clrRight != clr) {
				_clrRight = clr;
				updateGraphics();
			}
		}
	}
}