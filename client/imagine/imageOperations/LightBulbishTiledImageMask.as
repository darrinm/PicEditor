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
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import util.BitmapCache;
	import util.VBitmapData;
	
	[RemoteClass]
	public class LightBulbishTiledImageMask extends TiledImageMask
	{
		public function LightBulbishTiledImageMask(rcBounds:Rectangle = null) {
			super(rcBounds);
		}
	
		override protected function generateTileMask(): BitmapData {
			var bmdMask:BitmapData = VBitmapData.Construct(_nTileWidth, _nTileHeight, true, 0); // Fill with alpha 0
			var shp:Shape = new Shape();
			var strFillType:String = GradientType.RADIAL;
			var acoColors:Array = [0,0];
			var anAlphas:Array = [_alphaMax,_alphaMin];
			var anRatios:Array = [0,255];
			var nWidth:Number = _nTileWidth - _nPaddingLeft - _nPaddingRight;
			var nHeight:Number = _nTileHeight - _nPaddingTop - _nPaddingBottom;
			var tx:Number = _nPaddingLeft - (nWidth*_nScaleWidth-nWidth)/2;
			var ty:Number = _nPaddingTop - (nHeight*_nScaleHeight-nHeight)/2;
			var mat:Matrix = new Matrix();
			mat.createGradientBox(nWidth*_nScaleWidth,
								  nHeight*_nScaleHeight,
								  Math.PI * -0.75,
								  tx, ty);
			shp.graphics.beginGradientFill(strFillType, acoColors, anAlphas, anRatios, mat, "pad", "rgb", 0.3 );
			shp.graphics.drawRect(_nPaddingLeft, _nPaddingTop,
									nWidth,
									nHeight);
			shp.graphics.endFill();
			shp.graphics.lineStyle( nWidth * 0.05, 0, 0.2 );
			shp.graphics.drawEllipse(_nPaddingLeft + nWidth/4, _nPaddingTop+nHeight/4,
									nWidth * 0.5,
									nHeight * 0.5);
			bmdMask.draw(shp);
			return bmdMask;
		}

		override protected function getTileMask(): BitmapData {
			var bmdTileMask:BitmapData = BitmapCache.Lookup(this, "LightBulbishTiledImageMask", calcTileMaskKey(), null);
			if (!bmdTileMask) {
				bmdTileMask = generateTileMask();
				BitmapCache.Set(this, "LightBulbishTiledImageMask", calcTileMaskKey(), null, bmdTileMask);
			}
			return bmdTileMask;
		}				
	}
}
