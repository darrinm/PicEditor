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
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.objectOperations.SetPropertiesObjectOperation;
	import imagine.serialization.SerializationInfo;
	
	import util.BitmapCache;
	import util.VBitmapData;
	
	[RemoteClass]
	public class DropShadowImageOperation extends BlendImageOperation {
		private var _coShadow:uint = 0;
		private var _coBackground:uint = 0xffffffff;
		private var _cxyDistance:Number = 4.0;
		private var _nShadowAlpha:Number = 1.0;
		private var _degAngle:Number = 45;
		private var _fInner:Boolean = false;
		private var _nQuality:Number = 1;
		private var _nStrength:Number = 1.0;
		private var _cxBlur:Number = 4.0;
		private var _cyBlur:Number = 4.0;
		private var _cxMax:int;
		private var _cyMax:int;
		private var _cPixelsMax:int;
		
		public function DropShadowImageOperation(cxyDistance:Number=4.0, degAngle:Number=45,
				coShadow:uint=0, coBackground:uint=0xffffffff, nShadowAlpha:Number=1.0, cxBlur:Number=4.0,
				cyBlur:Number=4.0, nStrength:Number=1.0, nQuality:int=1, fInner:Boolean=false) {
			_cxyDistance = cxyDistance;
			_degAngle = degAngle;
			_coShadow = coShadow;
			_coBackground = coBackground;
			_nShadowAlpha = nShadowAlpha;
			_cxBlur = cxBlur;
			_cyBlur = cyBlur;
			_nStrength = nStrength;
			_nQuality = nQuality;
			_fInner = fInner;
			
			_cxMax = Util.GetMaxImageWidth(1);
			_cyMax = Util.GetMaxImageHeight(1);
			_cPixelsMax = Util.GetMaxImagePixels();
		}

		public function set shadowAlpha(nAlpha:Number): void {
			_nShadowAlpha = nAlpha;
		}
		public function get shadowAlpha(): Number {
			return _nShadowAlpha;
		}
		
		public function set angle(degAngle:Number): void {
			_degAngle = degAngle;
		}
		public function get angle(): Number {
			return _degAngle;
		}
		
		public function set shadowColor(co:uint): void {
			_coShadow = co;
		}
		public function get shadowColor(): uint {
			return _coShadow;
		}
		
		public function set backgroundColor(co:uint): void {
			_coBackground = co;
		}
		public function get backgroundColor(): uint {
			return _coBackground;
		}
		
		public function set distance(cxy:Number): void {
			_cxyDistance = cxy;
		}
		public function get distance(): Number {
			return _cxyDistance;
		}
		
		public function set inner(fInner:Boolean): void {
			_fInner = fInner;
		}
		public function get inner(): Boolean {
			return _fInner;
		}
		
		public function set quality(nQuality:int): void {
			_nQuality = nQuality;
		}
		public function get quality(): int {
			return _nQuality;
		}
		
		public function set strength(nStrength:Number): void {
			_nStrength = nStrength;
		}
		public function get strength(): Number {
			return _nStrength;
		}
		
		public function set blurX(cxBlur:Number): void {
			_cxBlur = cxBlur;
		}
		public function get blurX(): Number {
			return _cxBlur;
		}
		
		public function set blurY(cyBlur:Number): void {
			_cyBlur = cyBlur;
		}
		public function get blurY(): Number {
			return _cyBlur;
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
			['shadowColor', 'backgroundColor', 'shadowAlpha',
				'distance', 'angle', 'inner', 'quality',
				'strength', 'blurX', 'blurY',
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
			Debug.Assert(xmlOp.@shadowcolor, "DropShadowOperation shadowcolor argument missing");
			_coShadow = Number(xmlOp.@shadowcolor);
				
			Debug.Assert(xmlOp.@backgroundcolor, "DropShadowOperation backgroundcolor argument missing");
			_coBackground = Number(xmlOp.@backgroundcolor);
			
			Debug.Assert(xmlOp.@shadowalpha, "DropShadowOperation alpha argument missing");
			_nShadowAlpha = Number(xmlOp.@alpha);
				
			Debug.Assert(xmlOp.@angle, "DropShadowOperation angle argument missing");
			_degAngle = Number(xmlOp.@angle);
				
			Debug.Assert(xmlOp.@distance, "DropShadowOperation distance argument missing");
			_cxyDistance = Number(xmlOp.@distance);
				
			Debug.Assert(xmlOp.@inner, "DropShadowOperation inner argument missing");
			_fInner = xmlOp.@inner == "true";
				
			Debug.Assert(xmlOp.@quality, "DropShadowOperation quality argument missing");
			_nQuality = Number(xmlOp.@quality);
				
			Debug.Assert(xmlOp.@strength, "DropShadowOperation strength argument missing");
			_nStrength = Number(xmlOp.@strength);
			
			Debug.Assert(xmlOp.@blurx, "DropShadowOperation blurx argument missing");
			_cxBlur = Number(xmlOp.@blurx);
			
			Debug.Assert(xmlOp.@blury, "DropShadowOperation blury argument missing");
			_cyBlur = Number(xmlOp.@blury);
			
			Debug.Assert(xmlOp.hasOwnProperty("@maxWidth"), "DropShadowOperation maxWidth argument missing");
			_cxMax = Number(xmlOp.@maxWidth);
			_cyMax = Number(xmlOp.@maxHeight);
			_cPixelsMax = Number(xmlOp.@maxPixels);
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <DropShadow shadowcolor={_coShadow} backgroundcolor={_coBackground} alpha={_nShadowAlpha}
					distance={_cxyDistance} angle={_degAngle} inner={_fInner} quality={_nQuality}
					strength={_nStrength} blurx={_cxBlur} blury={_cyBlur}
					maxWidth={_cxMax} maxHeight={_cyMax} maxPixels={_cPixelsMax}/>;
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			var bmdSized:BitmapData = bmdSrc;

			var flt:DropShadowFilter = new DropShadowFilter(_cxyDistance, _degAngle, _coShadow, _nShadowAlpha,
					_cxBlur, _cyBlur, _nStrength, _nQuality, _fInner, false, false);
			var rcNewDim:Rectangle = bmdSized.generateFilterRect(bmdSrc.rect, flt);
			var dx:Number = rcNewDim.width - bmdSrc.width;
			var dy:Number = rcNewDim.height - bmdSrc.height;
			var cxNewDim:Number = rcNewDim.width;
			var cyNewDim:Number = rcNewDim.height;
			
			// HACK: the DropShadowFilter needs more working space than its output. Through
			// empirical testing I've found it to be about 2x the amount it inflates the
			// output by. 1.5x wasn't enough.
			var cxIntermediary:Number = bmdSrc.width + (dx * 2);
			var cyIntermediary:Number = bmdSrc.height + (dy * 2);
			
			var dctPropertySets:Object = {};
			var ptT:Point = Util.GetLimitedImageSize(cxIntermediary, cyIntermediary, _cxMax, _cyMax, _cPixelsMax);
			if (cxIntermediary > ptT.x || cyIntermediary > ptT.y) {
				var nShrinkFactor:Number = ptT.x / cxIntermediary;

				// Try to get the scaled image out of the cache
				bmdSized = null;
				if (fUseCache) bmdSized = BitmapCache.Lookup(this, "DropShadowOperation.sized", nShrinkFactor.toString(), bmdSrc);
				if (!fUseCache || !bmdSized) {
					// Use ceil so we'll always create a bitmap at least 1 pixel wide/high
					bmdSized = VBitmapData.Construct(Math.ceil(bmdSrc.width * nShrinkFactor), Math.ceil(bmdSrc.height * nShrinkFactor), true, 0x00FFFFFF);
					var mat:Matrix = new Matrix();
					mat.scale(bmdSized.width / bmdSrc.width, bmdSized.height / bmdSrc.height);
					bmdSized.draw(bmdSrc, mat, null, null, null, true);
					if (fUseCache) {
						BitmapCache.Set(this, "DropShadowOperation.sized", nShrinkFactor.toString(), bmdSrc, bmdSized);
					}
				}

				// These dimensions are used to create the new canvas so make sure they're integers and not smaller than 1
				cxNewDim = Math.ceil(cxNewDim * nShrinkFactor);
				cyNewDim = Math.ceil(cyNewDim * nShrinkFactor);
				rcNewDim.x = Math.round(rcNewDim.x * nShrinkFactor);
				rcNewDim.y = Math.round(rcNewDim.y * nShrinkFactor);
				
				// Resize all the DocumentObjects too
				if (fDoObjects)
					SetPropertiesObjectOperation.ScaleDocumentObjects(dctPropertySets, imgd, nShrinkFactor);
			}
			
			// Now we know the size of our target canvas, create it, filled with the background color.
			var bmdT:BitmapData = VBitmapData.Construct(cxNewDim, cyNewDim, true, _coBackground);
			
			// Draw the image and its shadow and alpha into a temp bitmap
			bmdT.applyFilter(bmdSized, bmdSized.rect, new Point(-rcNewDim.x, -rcNewDim.y), flt);
			
			// Draw the image + shadow into a final bitmap to merge in its alpha
			// UNDONE: use this opportunity to trim back the intermediary space added above
			var bmdOut:BitmapData = VBitmapData.Construct(cxNewDim, cyNewDim, true, _coBackground);
			bmdOut.draw(bmdT);
			bmdT.dispose();
			
			if (bmdSized != bmdSrc) DisposeIfNotNeeded(bmdSized);
			
			// Reposition the DocumentObjects too
			if (fDoObjects) {
				SetPropertiesObjectOperation.OffsetDocumentObjects(dctPropertySets, imgd, -rcNewDim.x, -rcNewDim.y);
				SetPropertiesObjectOperation.SetProperties(dctPropertySets, imgd);
			}
					
			return bmdOut;
		}
	}
}
