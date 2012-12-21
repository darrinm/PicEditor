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
	public class FlatCircleTiledImageMask extends TiledImageMask
	{
		public function FlatCircleTiledImageMask(rcBounds:Rectangle = null) {
			super(rcBounds);
		}
	
		override protected function generateTileMask(): BitmapData {
			var bmdMask:BitmapData = VBitmapData.Construct(_nTileWidth, _nTileHeight, true, 0); // Fill with alpha 0
			var nWidth:Number = _nTileWidth - _nPaddingLeft - _nPaddingRight;
			var nHeight:Number = _nTileHeight - _nPaddingTop - _nPaddingBottom;
			var shp:Shape = new Shape();
			shp.graphics.beginFill(0xFF, 1);
			shp.graphics.drawEllipse(_nPaddingLeft, _nPaddingTop,
									nWidth,
									nHeight);
			shp.graphics.endFill();
			bmdMask.draw(shp);
			return bmdMask;
		}

		override protected function getTileMask(): BitmapData {
			var bmdTileMask:BitmapData = BitmapCache.Lookup(this, "FlatCircleTiledImageMask", calcTileMaskKey(), null);
			if (!bmdTileMask) {
				bmdTileMask = generateTileMask();
				BitmapCache.Set(this, "FlatCircleTiledImageMask", calcTileMaskKey(), null, bmdTileMask);
			}
			return bmdTileMask;
		}				
	}
}
