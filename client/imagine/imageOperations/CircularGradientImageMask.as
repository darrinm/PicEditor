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
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class CircularGradientImageMask extends ShapeGradientImageMask
	{
		public function CircularGradientImageMask(rcBounds:Rectangle = null) {
			super(rcBounds);
		}

		override protected function get shapeType(): String {
			return "Circular";
		}

		override public function DrawOutline(gr:Graphics, xOff:Number, yOff:Number, cxWidth:Number, cyHeight:Number): void {
			gr.drawEllipse(xOff, yOff, cxWidth, cyHeight);
		} 

		override protected function generateGradientSubMask(): BitmapData {
			var bmdMask:BitmapData;
			var rcAbsSubMask:Rectangle = getAbstractGradientSubMaskRect();
			var rcCroppedSubMask:Rectangle = getCroppedGradientSubMaskRect();
			if (rcCroppedSubMask.isEmpty())
				return null;
				
			var nOuterRadius:Number = Math.max(_nInnerRadius, _nOuterRadius);
			bmdMask = VBitmapData.Construct(rcCroppedSubMask.width, rcCroppedSubMask.height, true, 0, 'circular gradient sub-mask'); // Fill with alpha 0
			var shp:Shape = new Shape();
			var strFillType:String = GradientType.RADIAL;
			var acoColors:Array = [0,0];
			var anAlphas:Array = [_nInnerAlpha,_nOuterAlpha];

			var anRatios:Array = [255 * _nInnerRadius/nOuterRadius,255];
			var mat:Matrix = new Matrix();
			mat.createGradientBox(rcAbsSubMask.width, rcAbsSubMask.height, 0, 0, 0);
			
			mat.translate(rcAbsSubMask.x - rcCroppedSubMask.x, rcAbsSubMask.y - rcCroppedSubMask.y);
			// Our center is at nWidth/2, nHeight/2
			shp.graphics.beginGradientFill(strFillType, acoColors, anAlphas, anRatios, mat);
			shp.graphics.drawRect(0, 0, rcCroppedSubMask.width, rcCroppedSubMask.height);

			bmdMask.draw(shp);
			return bmdMask;
		}
	}
}
