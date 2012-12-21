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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	import util.BitmapCache;
	import util.VBitmapData;
	
	[RemoteClass]
	public class BorderImageOperation extends BlendImageOperation {
		protected var _coOuter:Number = 0;
		protected var _cxyOuterThickness:Number = 0;
		protected var _coInner:Number = 0;
		protected var _cxyInnerThickness:Number = 0;
		protected var _cxyCornerRadius:Number = 0;
		private var _cyCaption:int = 0;
		private var _cxMax:int;
		private var _cyMax:int;
		private var _cPixelsMax:int;

		public function BorderImageOperation() {
			_cxMax = Util.GetMaxImageWidth(1);
			_cyMax = Util.GetMaxImageHeight(1);
			_cPixelsMax = Util.GetMaxImagePixels();
		}

		public function set outerthickness(cxyOuterThickness:Number): void {
			_cxyOuterThickness = int(cxyOuterThickness);
		}
		
		public function get outerthickness(): Number {
			return _cxyOuterThickness;
		}
		
		public function set innerthickness(cxyInnerThickness:Number): void {
			_cxyInnerThickness = int(cxyInnerThickness);
		}
		
		public function get innerthickness(): Number {
			return _cxyInnerThickness;
		}
		
		public function set outercolor(coOuter:Number): void {
			_coOuter = coOuter;
		}
		
		public function get outercolor(): Number {
			return _coOuter;
		}
		
		public function set innercolor(coInner:Number): void {
			_coInner = coInner;
		}
		
		public function get innercolor(): Number {
			return _coInner;
		}
		
		public function set cornerradius(cxyCornerRadius:Number): void {
			_cxyCornerRadius = int(cxyCornerRadius);
		}
		
		public function get cornerradius(): Number {
			return _cxyCornerRadius;
		}
		
		public function set captionheight(cyCaption:Number): void {
			_cyCaption = int(cyCaption);
		}
		
		public function get captionheight(): Number {
			return _cyCaption;
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
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(
			['outerthickness', 'innerthickness', 'outercolor', 'innercolor', 'cornerradius', 'captionheight',
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
			Debug.Assert(xmlOp.@outercolor, "BorderImageOperation outercolor argument missing");
			_coOuter = Number(xmlOp.@outercolor);
				
			Debug.Assert(xmlOp.@innercolor, "BorderImageOperation innercolor argument missing");
			_coInner = Number(xmlOp.@innercolor);
				
			Debug.Assert(xmlOp.@outerthickness, "BorderImageOperation outerthickness argument missing");
			_cxyOuterThickness = Number(xmlOp.@outerthickness);
				
			Debug.Assert(xmlOp.@innerthickness, "BorderImageOperation innerthickness argument missing");
			_cxyInnerThickness = Number(xmlOp.@innerthickness);
				
			Debug.Assert(xmlOp.@cornerradius, "BorderImageOperation cornerradius argument missing");
			_cxyCornerRadius = Number(xmlOp.@cornerradius);
			
			Debug.Assert(xmlOp.@cornerradius, "BorderImageOperation cornerradius argument missing");
			if (xmlOp.@captionheight != "")
				_cyCaption = Number(xmlOp.@captionheight);
			
			Debug.Assert(xmlOp.hasOwnProperty("@maxWidth"), "BorderImageOperation maxWidth argument missing");
			_cxMax = Number(xmlOp.@maxWidth);
			_cyMax = Number(xmlOp.@maxHeight);
			_cPixelsMax = Number(xmlOp.@maxPixels);
			
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Border outercolor={_coOuter} innercolor={_coInner} outerthickness={_cxyOuterThickness}
					innerthickness={_cxyInnerThickness} cornerradius={_cxyCornerRadius}
					captionheight={_cyCaption}
					maxWidth={_cxMax} maxHeight={_cyMax} maxPixels={_cPixelsMax}/>;
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			var cxyTotalThickness:Number = 2 * (_cxyInnerThickness + _cxyOuterThickness);
			var bmdSized:BitmapData = bmdSrc;
			var cxNewDim:Number = bmdSized.width + cxyTotalThickness;
			var cyNewDim:Number = bmdSized.height + cxyTotalThickness + _cyCaption;
			var cxyCornerRadius:Number = _cxyCornerRadius;
			
			var mat:Matrix;
			var dctPropertySets:Object = {};
			
			var ptT:Point = Util.GetLimitedImageSize(cxNewDim, cyNewDim, _cxMax, _cyMax, _cPixelsMax);
			var cxImageMax:int = ptT.x;
			var cyImageMax:int = ptT.y;
			if (cxNewDim > cxImageMax || cyNewDim > cyImageMax) {
				var cxTargetMax:Number = cxImageMax - cxyTotalThickness;
				var nShrinkFactor:Number = cxTargetMax / bmdSrc.width;

				// Try to get the scaled image out of the cache
				bmdSized = null;
				if (fUseCache) bmdSized = BitmapCache.Lookup(this, "BorderImageOperation.sized", nShrinkFactor.toString(), bmdSrc);
				if (!fUseCache || !bmdSized) {
					bmdSized = VBitmapData.Construct(bmdSrc.width * nShrinkFactor, bmdSrc.height * nShrinkFactor, true);
					mat = new Matrix();
					mat.scale(bmdSized.width / bmdSrc.width, bmdSized.height / bmdSrc.height);
					bmdSized.draw(bmdSrc, mat, null, null, null, true);
					if (fUseCache) {
						BitmapCache.Set(this, "BorderImageOperation.sized", nShrinkFactor.toString(), bmdSrc, bmdSized);
					}
				}
				cxNewDim = bmdSized.width + cxyTotalThickness;
				cyNewDim = bmdSized.height + cxyTotalThickness + _cyCaption;

				// Resize all the DocumentObjects too
				if (fDoObjects)
					SetPropertiesObjectOperation.ScaleDocumentObjects(dctPropertySets, imgd, nShrinkFactor);
			}
			cxyCornerRadius = Math.min(bmdSized.width/2, bmdSized.height/2, cxyCornerRadius);
			
			// Now we know the size of our target canvas, create it, filled with the outer border color.
			var bmdOut:BitmapData = VBitmapData.Construct(cxNewDim, cyNewDim, true, _coOuter);
			var spr:Sprite = new Sprite();
			
			// If there is an inner border draw it into the sprite which will later be drawn to the
			// output image.
			if (_cxyInnerThickness > 0) {
				var rcInnerBorder:Rectangle = new Rectangle(_cxyOuterThickness, _cxyOuterThickness,
						bmdSized.width + 2 * _cxyInnerThickness, bmdSized.height + 2 * _cxyInnerThickness);
				spr.graphics.beginFill(_coInner & 0xffffff, 1.0);
				var cxyRadius:Number = cxyCornerRadius == 0 ? 0 : (cxyCornerRadius + _cxyInnerThickness) * 2;
				spr.graphics.drawRoundRect(rcInnerBorder.x, rcInnerBorder.y, rcInnerBorder.width, rcInnerBorder.height,
						cxyRadius, cxyRadius);
				spr.graphics.endFill();
			}
			
			var ptInset:Point = new Point(_cxyInnerThickness + _cxyOuterThickness, _cxyInnerThickness + _cxyOuterThickness);
			var bm:Bitmap = new Bitmap(bmdSized);
			bm.x = ptInset.x;
			bm.y = ptInset.y;
			spr.addChild(bm);
			
			// Reposition the DocumentObjects too
			if (fDoObjects) {
				SetPropertiesObjectOperation.OffsetDocumentObjects(dctPropertySets, imgd, ptInset.x, ptInset.y);
				SetPropertiesObjectOperation.SetProperties(dctPropertySets, imgd);
			}

			// If the inner border's corners are rounded the photo needs its corners rounded too. Use a mask
			// to do the job.					
			if (cxyCornerRadius >= 1) {
				var shpMask:Shape = new Shape();
				shpMask.graphics.beginFill(0xffffff, 1.0);
				shpMask.graphics.drawRoundRect(ptInset.x, ptInset.y, bmdSized.width, bmdSized.height, cxyCornerRadius * 2, cxyCornerRadius * 2);
				shpMask.graphics.endFill();
				
				// If the mask is not added as a spr child then strange things happen for images > 4096 pixels wide/tall.
				// RepairedDraw draws the sprite twice but the shadow transform is carried over from the first draw
				// to the second one!
				spr.addChildAt(shpMask, 0);
				bm.mask = shpMask;
			}
			VBitmapData.RepairedDraw(bmdOut, spr);
			
			if (bmdSized != bmdSrc) DisposeIfNotNeeded(bmdSized);
			return bmdOut;
		}
	}
}
