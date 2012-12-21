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
	import errors.InvalidBitmapError;
	
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	import util.DrawUtil;
	import util.VBitmapData;

	[RemoteClass]
	public class PostalFrameImageOperation extends BlendImageOperation {
		private var _clrOutline:Number;
		private var _clrBackground:Number;
		private var _nThickness:Number;
		private var _nHoliness:Number;
		private var _nSpacing:Number;
		private var _cxMax:int;
		private var _cyMax:int;
		private var _cPixelsMax:int;
				
		public function PostalFrameImageOperation( outlineColor:Number=0xBBBBBB, backgroundColor:Number=0xFFFFEE,
							thickness:Number=0.05, holiness:Number=0.4, spacing:Number=2 ) {
			_clrOutline = outlineColor;
			_clrBackground = backgroundColor;
			_nThickness = thickness;
			_nHoliness = holiness;
			_nSpacing = spacing;
			_cxMax = Util.GetMaxImageWidth(1);
			_cyMax = Util.GetMaxImageHeight(1);
			_cPixelsMax = Util.GetMaxImagePixels();
		}

		public function set outlineColor(co:Number): void {
			_clrOutline = co;
		}
		
		public function get outlineColor(): Number {
			return _clrOutline;
		}

		public function set backgroundColor(co:Number): void {
			_clrBackground = co;
		}

		public function get backgroundColor(): Number {
			return _clrBackground;
		}

		// border thickness as a fraction of the image's largest dimension
		// appropriate values: 0.01 - 0.25
		public function set thickness(n:Number): void {
			_nThickness = n;
		}

		public function get thickness(): Number {
			return _nThickness;
		}

		// hole radius as a fraction of the border thickness
		// appropriate values: 0.1 - 1.0
		public function set holiness(n:Number): void {
			_nHoliness = n;
		}

		public function get holiness(): Number {
			return _nHoliness;
		}

		// hole spacing as a multiple of hole diameter
		// appropriate values: 1.0 or higher
		public function set spacing(n:Number): void {
			_nSpacing = n;
		}
				
		public function get spacing(): Number {
			return _nSpacing;
		}

		public function set maxImageWidth(n:Number): void {
			_cxMax = n;
		}
		
		public function get maxImageWidth(): Number {
			return _cxMax;
		}
		
		public function set maxImageHeight(n:Number): void {
			_cyMax = n;
		}
		
		public function get maxImageHeight(): Number {
			return _cyMax;
		}
		
		public function set maxPixels(n:Number): void {
			_cPixelsMax = n;
		}
		
		public function get maxPixels(): Number {
			return _cPixelsMax;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo([
			'outlineColor', 'backgroundColor', 'thickness', 'holiness', 'spacing', 'maxImageWidth', 'maxImageHeight', 'maxPixels']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@outlineColor, "PostalFrame outlineColor argument missing");
			_clrOutline = Number(xmlOp.@outlineColor);
			Debug.Assert(xmlOp.@backgroundColor, "PostalFrame backgroundColor argument missing");
			_clrBackground = Number(xmlOp.@backgroundColor);
			Debug.Assert(xmlOp.@thickness, "PostalFrame thickness argument missing");
			_nThickness = Number(xmlOp.@thickness);
			Debug.Assert(xmlOp.@holiness, "PostalFrame holiness argument missing");
			_nHoliness = Number(xmlOp.@holiness);
			Debug.Assert(xmlOp.@spacing, "PostalFrame spacing argument missing");
			_nSpacing = Number(xmlOp.@spacing);
			
			Debug.Assert(xmlOp.hasOwnProperty("@maxWidth"), "PostalFrame maxWidth argument missing");
			_cxMax = Number(xmlOp.@maxWidth);
			_cyMax = Number(xmlOp.@maxHeight);
			_cPixelsMax = Number(xmlOp.@maxPixels);
			return true;
		}
		
		override protected function SerializeSelf():XML {
			return <PostalFrame outlineColor={_clrOutline} backgroundColor={_clrBackground} thickness={_nThickness}
					holiness={_nHoliness} spacing={_nSpacing}
					maxWidth={_cxMax} maxHeight={_cyMax} maxPixels={_cPixelsMax}/>;
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			try {
				var nLargest:Number = Math.max( bmdSrc.width, bmdSrc.height );
				var nThickness:Number = nLargest * _nThickness;	// add some percent to the size
				var cxNewDim:Number = bmdSrc.width + nThickness*2;
				var cyNewDim:Number = bmdSrc.height + nThickness*2;
				var mat:Matrix;
				var dctPropertySets:Object = {};
				var nShrinkFactor:Number = 1;
				
				var ptT:Point = Util.GetLimitedImageSize(cxNewDim, cyNewDim, _cxMax, _cyMax, _cPixelsMax);
				var cxImageMax:int = ptT.x;
				var cyImageMax:int = ptT.y;
				if (cxNewDim > cxImageMax || cyNewDim > cyImageMax) {
					var cxyTargetMax:Number = cxImageMax / (1 + _nThickness*2);
					nShrinkFactor = cxyTargetMax / bmdSrc.width;
					nThickness = cxyTargetMax * _nThickness;
	
					cxNewDim = bmdSrc.width * nShrinkFactor + nThickness*2;
					cyNewDim = bmdSrc.height * nShrinkFactor + nThickness*2;
	
					// Resize all the DocumentObjects too
					if (fDoObjects)
						SetPropertiesObjectOperation.ScaleDocumentObjects(dctPropertySets, imgd, nShrinkFactor);
				}
				
				nLargest = Math.max( cxNewDim, cyNewDim );

				// Reposition the DocumentObjects too
				if (fDoObjects) {
					SetPropertiesObjectOperation.OffsetDocumentObjects(dctPropertySets, imgd, nThickness, nThickness);
					SetPropertiesObjectOperation.SetProperties(dctPropertySets, imgd);
				}
				// create a bigger framing bmp big
				var bmdTmp:BitmapData = VBitmapData.Construct(cxNewDim, cyNewDim, true, _clrBackground);

				// draw the inner bmp smaller
				var mat2:Matrix = new Matrix();
				mat2.scale(nShrinkFactor, nShrinkFactor);
				mat2.translate(nThickness, nThickness);
				
				bmdTmp.draw(bmdSrc,mat2,null, null, null, true);
				
				// draw circles all the way around to simulate perforations			
				var nCircleRadius:Number = nThickness * _nHoliness; 
				var nSpacing:Number = nCircleRadius * 2 * _nSpacing;
				var nIters:Number = nLargest / nSpacing + 1;
				
				var fnDrawPerforation:Function = function(shp:Shape, i:Number, fVert:Boolean): void {
					// left/ride sides
					if (fVert && i * nSpacing < cyNewDim/2) {
						shp.graphics.drawCircle( 0, cyNewDim/2 - nSpacing * i, nCircleRadius);
						shp.graphics.drawCircle( cxNewDim, cyNewDim/2 - nSpacing * i, nCircleRadius);
						if (i > 0) {
							shp.graphics.drawCircle( 0, cyNewDim/2 + nSpacing * i, nCircleRadius);
							shp.graphics.drawCircle( cxNewDim, cyNewDim/2 + nSpacing * i, nCircleRadius);
						}
					}
					// top/bottom sides
					if (!fVert && i * nSpacing < cxNewDim/2) {
						shp.graphics.drawCircle( cxNewDim/2 - nSpacing * i, 0, nCircleRadius);
						shp.graphics.drawCircle( cxNewDim/2 - nSpacing * i, cyNewDim, nCircleRadius);
						if (i > 0) {
							shp.graphics.drawCircle( cxNewDim/2 + nSpacing * i, 0, nCircleRadius);
							shp.graphics.drawCircle( cxNewDim/2 + nSpacing * i, cyNewDim, nCircleRadius);
						}
					}				
				}
				
				// draw the lines
				var shp:Shape = new Shape();
				shp.graphics.lineStyle( 2, _clrOutline );
				shp.graphics.drawRect(0, 0, cxNewDim-1, cyNewDim-1);
				for (var i:Number = 0; i < nIters; i++) {					
					fnDrawPerforation(shp, i, true);					
					fnDrawPerforation(shp, i, false);					
				}
				// hit all four corners, too								
				shp.graphics.drawCircle( 0, 0, nCircleRadius);
				shp.graphics.drawCircle( cxNewDim, 0, nCircleRadius);
				shp.graphics.drawCircle( 0, cyNewDim, nCircleRadius);
				shp.graphics.drawCircle( cxNewDim, cyNewDim, nCircleRadius);
				VBitmapData.RepairedDraw(bmdTmp, shp);
				
				// next, draw the circles for a perforation mask
				var bmdMask:BitmapData = VBitmapData.Construct(cxNewDim, cyNewDim, true, 0xFFFFFFFF);
				shp = new Shape();
				shp.graphics.lineStyle(0);
				for (i = 0; i < nIters; i++) {					
					shp.graphics.beginFill(0x000000);
					fnDrawPerforation(shp, i, true);					
					shp.graphics.endFill();
					shp.graphics.beginFill(0x000000);
					fnDrawPerforation(shp, i, false);
					shp.graphics.endFill();
				}
				
				// hit all four corners, too								
				VBitmapData.RepairedDraw(bmdMask, shp);
				shp.graphics.clear()
				shp.graphics.beginFill(0x000000);
				shp.graphics.drawCircle( 0, 0, nCircleRadius);
				shp.graphics.drawCircle( cxNewDim, 0, nCircleRadius);
				shp.graphics.drawCircle( 0, cyNewDim, nCircleRadius);
				shp.graphics.drawCircle( cxNewDim, cyNewDim, nCircleRadius);
				VBitmapData.RepairedDraw(bmdMask, shp);
				bmdMask.copyChannel(bmdMask,bmdMask.rect,new Point(0,0),BitmapDataChannel.RED,BitmapDataChannel.ALPHA);
				
				var bmdOut:BitmapData = VBitmapData.Construct(cxNewDim, cyNewDim, true, 0xFFFFFFFF);
				bmdOut.copyPixels(bmdTmp, bmdTmp.rect, new Point(0,0), bmdMask );
				
				bmdMask.dispose();
				bmdTmp.dispose();
				
			} catch (e:Error) {
				throw new InvalidBitmapError( InvalidBitmapError.ERROR_MEMORY );
			}
			return bmdOut;
		}
	}
}
