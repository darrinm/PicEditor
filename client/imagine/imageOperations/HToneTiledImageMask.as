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
	import flash.display.StageQuality;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import mx.core.Application;
	
	import util.BitmapCache;
	import util.VBitmapData;
	
	[RemoteClass]
	public class HToneTiledImageMask extends TiledImageMask
	{
		public function HToneTiledImageMask(rcBounds:Rectangle = null) {
			super(rcBounds);
		}
		
		protected override function calcTileMaskKey(): String {
			var anKey:Array = [_nTileWidth, _nTileHeight, _nPaddingLeft, _nPaddingTop, _nPaddingRight, _nPaddingBottom];
			return anKey.join(",");
		}
				
		protected override function generateTileMask(): BitmapData {
			var bmdMask:BitmapData = VBitmapData.Construct(_nTileWidth, _nTileHeight, true, 0); // Fill with alpha 0
			var shp:Shape = new Shape();
			var strFillType:String = GradientType.LINEAR;
			var acoColors:Array = [0,0];
			var anAlphas:Array = [1.0,0.2];
			var anRatios:Array = [0,255];
			var mat:Matrix = new Matrix();
			var nWidth:Number = _nTileWidth - _nPaddingLeft - _nPaddingRight;
			var nHeight:Number = _nTileHeight - _nPaddingTop - _nPaddingBottom;
			mat.createGradientBox(nWidth*1.25,
								  nHeight*1.25/2,
								  270 * Math.PI/180,
								  _nPaddingLeft - (nWidth*1.25-nWidth)/2,
								  _nPaddingTop - (nHeight*1.25-nHeight)/2);
			shp.graphics.beginGradientFill(strFillType, acoColors, anAlphas, anRatios, mat, "reflect");
			shp.graphics.drawRect(_nPaddingLeft, _nPaddingTop,
									nWidth,
									nHeight);
			bmdMask.draw(shp);
			return bmdMask;
		}

		override protected function getTileMask(): BitmapData {
			var bmdTileMask:BitmapData = BitmapCache.Lookup(this, "HToneTiledImageTileMask", calcTileMaskKey(), null);
			if (!bmdTileMask) {
				bmdTileMask = generateTileMask();
				BitmapCache.Set(this, "HToneTiledImageTileMask", calcTileMaskKey(), null, bmdTileMask);
			}
			return bmdTileMask;
		}
	}
}