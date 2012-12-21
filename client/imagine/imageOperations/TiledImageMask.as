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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import util.BitmapCache;
	import util.VBitmapData;
	
	[RemoteClass]
	public class TiledImageMask extends ImageMask
	{
		protected var _nTileWidth:Number = 0;
		protected var _nTileHeight:Number = 0;
		protected var _nScaleWidth:Number = 0.8;
		protected var _nScaleHeight:Number = 0.8;
		protected var _nPaddingLeft:Number = 0;
		protected var _nPaddingTop:Number = 0;
		protected var _nPaddingRight:Number = 0;
		protected var _nPaddingBottom:Number = 0;
		protected var _offsetX:Number = 0;
		protected var _offsetY:Number = 0;
		protected var _alphaMin:Number = 0.0;
		protected var _alphaMax:Number = 1.0;

		public function TiledImageMask(rcBounds:Rectangle = null) {
			super(rcBounds);
		}

		public function set tileWidth(nTileWidth:Number): void {
			_nTileWidth = Math.round(nTileWidth);
		}
		
		public function set tileHeight(nTileHeight:Number): void {
			_nTileHeight = Math.round(nTileHeight);
		}
		
		public function set scaleWidth(nScaleWidth:Number): void {
			_nScaleWidth = nScaleWidth;
		}
		
		public function set scaleHeight(nScaleHeight:Number): void {
			_nScaleHeight = nScaleHeight;
		}	

		public function set offsetX(val:Number): void {
			_offsetX = val;
		}
	
		public function set offsetY(val:Number): void {
			_offsetY = val;
		}

		public function set alphaMin(val:Number): void {
			_alphaMin = val;
		}
	
		public function set alphaMax(val:Number): void {
			_alphaMax = val;
		}	
				
		public function set paddingLeft(nSize:Number): void {
			_nPaddingLeft = Math.round(nSize);
		}
		
		public function set paddingTop(nSize:Number): void {
			_nPaddingTop = Math.round(nSize);
		}
		
		public function set paddingRight(nSize:Number): void {
			_nPaddingRight = Math.round(nSize);
		}
		
		public function set paddingBottom(nSize:Number): void {
			_nPaddingBottom = Math.round(nSize);
		}
		
		override public function writeExternal(output:IDataOutput):void {
			super.writeExternal(output);
			var obMask:Object = {};
			obMask.nTileWidth = _nTileWidth;
			obMask.nTileHeight = _nTileHeight;
			obMask.scaleWidth = _nScaleWidth;
			obMask.scaleHeight = _nScaleHeight;
			obMask.offsetX = _offsetX;
			obMask.offsetY = _offsetY;
			obMask.alphaMin = _alphaMin;
			obMask.alphaMax = _alphaMax;
			obMask.nPaddingLeft = _nPaddingLeft;
			obMask.nPaddingTop = _nPaddingTop;
			obMask.nPaddingRight = _nPaddingRight;
			obMask.nPaddingBottom = _nPaddingBottom;
			output.writeObject(obMask);
		}
		
		override public function readExternal(input:IDataInput):void {
			super.readExternal(input);
			var obMask:Object = input.readObject();
			_nTileWidth = obMask.nTileWidth;
			_nTileHeight = obMask.nTileHeight;
			_nScaleWidth = obMask.scaleWidth;
			_nScaleHeight = obMask.scaleHeight;
			_offsetX = obMask.offsetX;
			_offsetY = obMask.offsetY;
			_alphaMin = obMask.alphaMin;
			_alphaMax = obMask.alphaMax;
			_nPaddingLeft = obMask.nPaddingLeft;
			_nPaddingTop = obMask.nPaddingTop;
			_nPaddingRight = obMask.nPaddingRight;
			_nPaddingBottom = obMask.nPaddingBottom;
		}
		
		public override function Serialize(): XML {
			var xml:XML = super.Serialize();
			xml.@nTileWidth = _nTileWidth;
			xml.@nTileHeight = _nTileHeight;
			xml.@scaleWidth = _nScaleWidth;
			xml.@scaleHeight = _nScaleHeight;
			xml.@offsetX = _offsetX;
			xml.@offsetY = _offsetY;
			xml.@alphaMin = _alphaMin;
			xml.@alphaMax = _alphaMax;
			xml.@nPaddingLeft = _nPaddingLeft;
			xml.@nPaddingTop = _nPaddingTop;
			xml.@nPaddingRight = _nPaddingRight;
			xml.@nPaddingBottom = _nPaddingBottom;
			return xml;
		}

		public override function Deserialize(xml:XML): Boolean {
			var fSuccess:Boolean = super.Deserialize(xml);
			if (fSuccess) {
				Debug.Assert(xml.@nTileWidth, "TiledImageMask nTileWidth argument missing");
				_nTileWidth = Number(xml.@nTileWidth);
				Debug.Assert(xml.@nTileHeight, "TiledImageMask nTileHeight argument missing");
				_nTileHeight = Number(xml.@nTileHeight);
				Debug.Assert(xml.@scaleWidth, "TiledImageMask scaleWidth argument missing");
				_nScaleWidth = Number(xml.@scaleWidth);
				Debug.Assert(xml.@scaleHeight, "TiledImageMask scaleHeight argument missing");
				_nScaleHeight = Number(xml.@scaleHeight);
				Debug.Assert(xml.@nPaddingLeft, "TiledImageMask nPaddingLeft argument missing");
				_nPaddingLeft = Number(xml.@nPaddingLeft);
				Debug.Assert(xml.@nPaddingTop, "TiledImageMask nPaddingTop argument missing");
				_nPaddingTop = Number(xml.@nPaddingTop);
				Debug.Assert(xml.@nPaddingRight, "TiledImageMask nPaddingRight argument missing");
				_nPaddingRight = Number(xml.@nPaddingRight);
				Debug.Assert(xml.@nPaddingBottom, "TiledImageMask nPaddingBottom argument missing");
				_nPaddingBottom = Number(xml.@nPaddingBottom);
				Debug.Assert(xml.@offsetX, "TiledImageMask offsetX argument missing");
				_offsetX = Number(xml.@offsetX);
				Debug.Assert(xml.@offsetY, "TiledImageMask offsetY argument missing");
				_offsetY = Number(xml.@offsetY);
				Debug.Assert(xml.@alphaMin, "TiledImageMask alphaMin argument missing");
				_alphaMin = Number(xml.@alphaMin);
				Debug.Assert(xml.@alphaMax, "TiledImageMask alphaMax argument missing");
				_alphaMax = Number(xml.@alphaMax);
			}
			return fSuccess;
		}
		
		protected function calcTileMaskKey(): String {
			var anKey:Array = [_nTileWidth, _nTileHeight, _nPaddingLeft, _nPaddingTop, _nPaddingRight, _nPaddingBottom, _offsetX, _offsetY, _alphaMin, _alphaMax];
			return anKey.join(",");
		}
		
		protected function generateTileMask(): BitmapData {
			var bmdMask:BitmapData = VBitmapData.Construct(_nTileWidth, _nTileHeight, true, 0); // Fill with alpha 0
			var shp:Shape = new Shape();
			var strFillType:String = GradientType.RADIAL;
			var acoColors:Array = [0,0];
			var anAlphas:Array = [_alphaMax,_alphaMin];
			var anRatios:Array = [0,255];
			var mat:Matrix = new Matrix();
			var nWidth:Number = _nTileWidth - _nPaddingLeft - _nPaddingRight;
			var nHeight:Number = _nTileHeight - _nPaddingTop - _nPaddingBottom;
			mat.createGradientBox(nWidth*_nScaleWidth,
								  nHeight*_nScaleHeight,
								  0,
								  _nPaddingLeft - (nWidth*_nScaleWidth-nWidth)/2,
								  _nPaddingTop - (nHeight*_nScaleHeight-nHeight)/2);
			shp.graphics.beginGradientFill(strFillType, acoColors, anAlphas, anRatios, mat);
			shp.graphics.drawRect(_nPaddingLeft, _nPaddingTop,
									nWidth,
									nHeight);
			bmdMask.draw(shp);
			return bmdMask;
		}

		protected function getTileMask(): BitmapData {
			var bmdTileMask:BitmapData = BitmapCache.Lookup(this, "TiledImageTileMask", calcTileMaskKey(), null);
			if (!bmdTileMask) {
				bmdTileMask = generateTileMask();
				BitmapCache.Set(this, "TiledImageTileMask", calcTileMaskKey(), null, bmdTileMask);
			}
			return bmdTileMask;
		}
				
		public function getUnscaledMaskSize():Point {
			var nWidth:Number = Math.ceil(width*1.0/_nTileWidth) * _nTileWidth;
			var nHeight:Number = Math.ceil(height*1.0/_nTileHeight) * _nTileHeight;
			while(nWidth > Util.GetMaxImageWidth(nHeight)) nWidth -= _nTileWidth;				
			while(nHeight > Util.GetMaxImageHeight(nWidth)) nHeight -= _nTileHeight;				
			return new Point( nWidth, nHeight );
		}		

		protected function generateMask(): BitmapData {
			if (_rcBounds == null) {
				return null; // Bail out until we have bounds
			}
			
			var ptUnscaledMaskSize:Point = getUnscaledMaskSize();
			var bmdMask:BitmapData = VBitmapData.Construct(width, height, true, 0); // Fill with alpha 0
			BitmapCache.Set(this, "TiledImageMask", Serialize().toXMLString(), null, bmdMask);
			var mat:Matrix = new Matrix();
			mat.translate((width-ptUnscaledMaskSize.x)/2 + _offsetX, (height-ptUnscaledMaskSize.y)/2 + _offsetY);

			// tesselate the tile across the image
			var shp:Shape = new Shape();
			shp.graphics.beginBitmapFill(getTileMask());
			shp.graphics.drawRect(0, 0, ptUnscaledMaskSize.x, ptUnscaledMaskSize.y);
			shp.graphics.endFill();

			bmdMask.draw(shp,mat);			
			return bmdMask;
		}
		
		public override function Mask(bmdOrig:BitmapData): BitmapData {
			var bmdMask:BitmapData = BitmapCache.Lookup(this, "TiledImageMask", Serialize().toXMLString(), null);
			if (!bmdMask || bmdMask.width != width || bmdMask.height != height) {
				return generateMask();
			}
			return bmdMask;
		}
	}
}
