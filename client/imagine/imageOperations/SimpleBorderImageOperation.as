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
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	import util.BitmapCache;
	import util.VBitmapData;
	
	[RemoteClass]
	public class SimpleBorderImageOperation extends BlendImageOperation {
		protected var _co:Number = 0;
		protected var _cxLeft:Number = 0;
		protected var _cxRight:Number = 0;
		protected var _cyTop:Number = 0;
		protected var _cyBottom:Number = 0;
		private var _cxMax:int;
		private var _cyMax:int;
		private var _cPixelsMax:int;

		public function SimpleBorderImageOperation() {
			_cxMax = Util.GetMaxImageWidth(1);
			_cyMax = Util.GetMaxImageHeight(1);
			_cPixelsMax = Util.GetMaxImagePixels();
		}

		public function set left(cxLeft:Number): void {
			_cxLeft = Math.max(0,Math.round(cxLeft));
		}
		
		public function get left(): Number {
			return _cxLeft;
		}
		
		public function set right(cxRight:Number): void {
			_cxRight = Math.max(0,Math.round(cxRight));
		}
		
		public function get right(): Number {
			return _cxRight;
		}
		
		public function set top(cyTop:Number): void {
			_cyTop = Math.max(0,Math.round(cyTop));
		}
		
		public function get top(): Number {
			return _cyTop;
		}
		
		public function set bottom(cyBottom:Number): void {
			_cyBottom = Math.max(0,Math.round(cyBottom));
		}
		
		public function get bottom(): Number {
			return _cyBottom;
		}
		
		public function set color(co:Number): void {
			_co = co;
		}
		
		public function get color(): Number {
			return _co;
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
			'left', 'right', 'top', 'bottom', 'color',
			'maxImageWidth', 'maxImageHeight', 'maxPixels']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.hasOwnProperty("@color"), "SimpleBorderImageOperation color argument missing");
			_co = Number(xmlOp.@color);
				
			Debug.Assert(xmlOp.hasOwnProperty("@left"), "SimpleBorderImageOperation left argument missing");
			_cxLeft = Number(xmlOp.@left);
				
			Debug.Assert(xmlOp.hasOwnProperty("@right"), "SimpleBorderImageOperation right argument missing");
			_cxRight = Number(xmlOp.@right);
				
			Debug.Assert(xmlOp.hasOwnProperty("@top"), "SimpleBorderImageOperation top argument missing");
			_cyTop = Number(xmlOp.@top);
				
			Debug.Assert(xmlOp.hasOwnProperty("@bottom"), "SimpleBorderImageOperation bottom argument missing");
			_cyBottom = Number(xmlOp.@bottom);
			
			Debug.Assert(xmlOp.hasOwnProperty("@maxWidth"), "SimpleBorderImageOperation maxWidth argument missing");
			_cxMax = Number(xmlOp.@maxWidth);
			_cyMax = Number(xmlOp.@maxHeight);
			_cPixelsMax = Number(xmlOp.@maxPixels);

			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <SimpleBorder color={_co} left={_cxLeft} right={_cxRight} top={_cyTop} bottom={_cyBottom}
					maxWidth={_cxMax} maxHeight={_cyMax} maxPixels={_cPixelsMax}/>;
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			var cxLeft:Number = _cxLeft;
			var cxRight:Number = _cxRight;
			var cyTop:Number = _cyTop;
			var cyBottom:Number = _cyBottom;
			var cyTotalBorderHeight:Number = cyTop + cyBottom;
			var cxTotalBorderWidth:Number = cxLeft + cxRight;
			var bmdSized:BitmapData = bmdSrc;
			var cxNewDim:Number = bmdSized.width + cxTotalBorderWidth;
			var cyNewDim:Number = bmdSized.height + cyTotalBorderHeight;
			
			var mat:Matrix;
			var dctPropertySets:Object = {};
			
			var ptT:Point = Util.GetLimitedImageSize(cxNewDim, cyNewDim, _cxMax, _cyMax, _cPixelsMax);
			var cxImageMax:int = ptT.x;
			var cyImageMax:int = ptT.y;
			if (cxNewDim > cxImageMax || cyNewDim > cyImageMax) {
				var nShrinkFactor:Number = Math.min(cxImageMax / cxNewDim, cyImageMax / cyNewDim);

				cxLeft *= nShrinkFactor;
				cxRight *= nShrinkFactor;
				cyTop *= nShrinkFactor;
				cyBottom *= nShrinkFactor;
				cyTotalBorderHeight *= nShrinkFactor;
				cxTotalBorderWidth *= nShrinkFactor;
				cxNewDim *= nShrinkFactor;
				cyNewDim *= nShrinkFactor;

				// Try to get the scaled image out of the cache
				bmdSized = null;
				if (fUseCache) bmdSized = BitmapCache.Lookup(this, "SimpleBorderImageOperation.sized", nShrinkFactor.toString(), bmdSrc);
				if (!fUseCache || !bmdSized) {
					bmdSized = VBitmapData.Construct(bmdSrc.width * nShrinkFactor, bmdSrc.height * nShrinkFactor, true);
					mat = new Matrix();
					mat.scale(bmdSized.width / bmdSrc.width, bmdSized.height / bmdSrc.height);
					bmdSized.draw(bmdSrc, mat, null, null, null, true);
					if (fUseCache) {
						BitmapCache.Set(this, "SimpleBorderImageOperation.sized", nShrinkFactor.toString(), bmdSrc, bmdSized);
					}
				}

				// Resize all the DocumentObjects too
				if (fDoObjects)
					SetPropertiesObjectOperation.ScaleDocumentObjects(dctPropertySets, imgd, nShrinkFactor);
			}
			// Now we know the size of our target canvas, create it, filled with the outer border color.
			var bmdOut:BitmapData = VBitmapData.Construct(cxNewDim, cyNewDim, true, 0xff000000 | _co);

			var ptInset:Point = new Point(cxLeft, cyTop);
			bmdOut.copyPixels(bmdSized, bmdSized.rect, ptInset);
			
			// Reposition the DocumentObjects too
			if (fDoObjects) {
				SetPropertiesObjectOperation.OffsetDocumentObjects(dctPropertySets, imgd, ptInset.x, ptInset.y);
				SetPropertiesObjectOperation.SetProperties(dctPropertySets, imgd);
			}
					
			if (bmdSized != bmdSrc) DisposeIfNotNeeded(bmdSized);
			return bmdOut;
		}
	}
}
