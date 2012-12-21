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
	import flash.filters.ColorMatrixFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import overlays.helpers.RGBColor;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class GlowImageOperation extends BlendImageOperation {
		private var _co:Number;
		private var _nGlowAlpha:Number;
		private var _xBlur:Number;
		private var _yBlur:Number;
		private var _nStrength:Number;
		private var _nQuality:Number;
		private var _fInner:Boolean;
		private var _fKnockout:Boolean;
		private var _cxMax:int;
		private var _cyMax:int;
		private var _cPixelsMax:int;
		
		public function GlowImageOperation(co:Number=NaN, nGlowAlpha:Number=NaN, xBlur:Number=NaN, yBlur:Number=NaN,
				nStrength:Number=NaN, nQuality:Number=NaN, fInner:Boolean=true, fKnockout:Boolean=false) {
			// ImageOperation constructors are called with no arguments during Deserialization
			if (isNaN(co))
				return;
			
			_co = co;
			_nGlowAlpha = nGlowAlpha;
			_xBlur = xBlur;
			_yBlur = yBlur;
			_nStrength = nStrength;
			_nQuality = nQuality;
			_fInner = fInner;
			_fKnockout = fKnockout;
			_cxMax = Util.GetMaxImageWidth(1);
			_cyMax = Util.GetMaxImageHeight(1);
			_cPixelsMax = Util.GetMaxImagePixels();
		}
		
		public function set color(co:Number): void {
			_co = co;
		}
		
		public function get color():Number {
			return _co;
		}
		
		public function set glowalpha(nGlowAlpha:Number): void {
			_nGlowAlpha = nGlowAlpha;
		}
		
		public function get glowalpha(): Number {
			return _nGlowAlpha;
		}
		
		public function set xblur(xBlur:Number): void {
			_xBlur = xBlur;
		}
		
		public function get xblur(): Number {
			return _xBlur;
		}
		
		public function set yblur(yBlur:Number): void {
			_yBlur = yBlur;
		}
		
		public function get yblur(): Number {
			return _yBlur;
		}
		
		public function set strength(nStrength:Number): void {
			_nStrength = nStrength;
		}
		
		public function get strength(): Number {
			return _nStrength;
		}
		
		public function set quality(nQuality:Number): void {
			_nQuality = nQuality;
		}
		
		public function get quality(): Number {
			return _nQuality;
		}
		
		public function set innerglow(fInner:Boolean): void {
			_fInner = fInner;
		}
		
		public function get innerglow(): Boolean {
			return _fInner;
		}
		
		public function set knockout(fKnockout:Boolean): void {
			_fKnockout = fKnockout;
		}
		
		public function get knockout(): Boolean {
			return _fKnockout;
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
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['color', 'glowalpha', 'xblur', 'yblur', 'strength', 'quality', 'innerglow', 'knockout', 'maxImageWidth', 'maxImageHeight', 'maxPixels']);

		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}

		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@color, "GlowImageOperation color argument missing");
			_co = Number(xmlOp.@color);
			Debug.Assert(xmlOp.@alpha, "GlowImageOperation alpha argument missing");
			_nGlowAlpha = Number(xmlOp.@alpha);
			Debug.Assert(xmlOp.@blurX, "GlowImageOperation blurX argument missing");
			_xBlur = Number(xmlOp.@blurX);
			Debug.Assert(xmlOp.@blurY, "GlowImageOperation blurY argument missing");
			_yBlur = Number(xmlOp.@blurY);
			Debug.Assert(xmlOp.@strength, "GlowImageOperation strength argument missing");
			_nStrength = Number(xmlOp.@strength);
			Debug.Assert(xmlOp.@quality, "GlowImageOperation quality argument missing");
			_nQuality = Number(xmlOp.@quality);
			Debug.Assert(xmlOp.@inner, "GlowImageOperation inner argument missing");
			_fInner = xmlOp.@inner == "true";
			Debug.Assert(xmlOp.@knockout, "GlowImageOperation knockout argument missing");
			_fKnockout = xmlOp.@knockout == "true";
				
			Debug.Assert(xmlOp.hasOwnProperty("@maxWidth"), "GlowImageOperation maxWidth argument missing");
			_cxMax = Number(xmlOp.@maxWidth);
			_cyMax = Number(xmlOp.@maxHeight);
			_cPixelsMax = Number(xmlOp.@maxPixels);
			return true;
		}
		
		override protected function SerializeSelf():XML {
			return <Glow color={_co} alpha={_nGlowAlpha} blurX={_xBlur} blurY={_yBlur}
					strength={_nStrength} quality={_nQuality} inner={_fInner} knockout={_fKnockout}
					maxWidth={_cxMax} maxHeight={_cyMax} maxPixels={_cPixelsMax}/>
		}
		
		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return Glow(bmdSrc, _co, _nGlowAlpha, _xBlur, _yBlur, _nStrength, _nQuality, _fInner, _fKnockout, _cxMax, _cyMax, _cPixelsMax);
		}
		
		// Given a target blur and an image dimension, calculate the
		// image scaling necessary to fit within glow blur limits
		// The limits are:
		//   - blur <= 255
		//   - blur * 3 < space around image
		//       space around image = (max image size - image dimension)
		
		private static function CalcBlurScaleFactor(nBlur:Number, cDim:Number, nMaxSize:int): Number {
			const knMaxBlur:Number = 255;
			const knSpaceReq:Number = 3; // Multiply this by the blur to get the amount of extra pixels needed.
			nMaxSize += 100;			// Pad a little so we won't end up with an nSpaceRatio of 0 (e.g. 4000 - 4000)
			
			var nScaleFactor:Number = 1;

			// Reduce the image size so that the blur applied is at or less than the max blur			
			if (nBlur > knMaxBlur) {
				nScaleFactor = knMaxBlur / nBlur;
				nBlur = knMaxBlur;
			}

			// Reduce the image size so that we have enough room to apply the blur
			var nSpaceRatio:Number = (nMaxSize - nScaleFactor * cDim) / nBlur;
			if (nSpaceRatio < knSpaceReq) nScaleFactor *= nSpaceRatio / knSpaceReq;

			return nScaleFactor;
		}
		
		public static function Glow(bmdOrig:BitmapData, co:Number, nGlowAlpha:Number, xBlur:Number, yBlur:Number,
				nStrength:Number, nQuality:Number, fInner:Boolean, fKnockout:Boolean,
				cxMax:int, cyMax:int, cPixelsMax:int):BitmapData {
			var bmdNew:BitmapData;
			
	//		trace("Glow: co: " + co + ", nGlowAlpha: " + nGlowAlpha + ", xBlur: " + xBlur +
	//				", yBlur: " + yBlur + ", nStrength: " + nStrength + ", nQuality: " + nQuality +
	//				", fInner: " + fInner + ", fKnockout: " + fKnockout)
			
			var ptLimited:Point = Util.GetLimitedImageSize(bmdOrig.width, bmdOrig.height, cxMax, cyMax, cPixelsMax);
			var nXScaleFactor:Number = CalcBlurScaleFactor(xBlur, bmdOrig.width, ptLimited.x);
			var nYScaleFactor:Number = CalcBlurScaleFactor(yBlur, bmdOrig.height, ptLimited.y);
			
			var flt:GlowFilter = new GlowFilter(co, nGlowAlpha, xBlur * nXScaleFactor, yBlur * nYScaleFactor, nStrength, nQuality, fInner, fKnockout);
			
			if (nXScaleFactor < 1 || nYScaleFactor < 1) {
				// We need to scale before we blur
				// First, apply our blur as a Red glow to a blue bitmap

				var bmdTmp:BitmapData = VBitmapData.Construct(bmdOrig.width * nXScaleFactor, bmdOrig.height * nYScaleFactor, true, 0xff0000ff);

				// CONSIDER: This algorithm assumes that our image has no transparency
				// For now, this is fine. Eventually, we may want to set up tranparency
				// in bmdTmp like this:
				//  - Set all pixels to blue, but copy alpha from bmdOrig (scaled)
			
				flt.color = 0xff0000;
				bmdTmp.applyFilter(bmdTmp, bmdTmp.rect, new Point(0, 0), flt);
				
				// Next, convert the red chanel to alpha, and RGB to the glow color
	            var matrix:Array = new Array();
	            matrix = matrix.concat([0, 0, 0, 0, RGBColor.RedFromUint(co)]); // red
	            matrix = matrix.concat([0, 0, 0, 0, RGBColor.GreenFromUint(co)]); // green
	            matrix = matrix.concat([0, 0, 0, 0, RGBColor.BlueFromUint(co)]); // blue
	            matrix = matrix.concat([1, 0, 0, 0, 0]); // alpha
	
	            var fltColorMatrix:ColorMatrixFilter = new ColorMatrixFilter(matrix);
	           
	            bmdTmp.applyFilter(bmdTmp, bmdTmp.rect, new Point(0, 0), fltColorMatrix);

				// Now, bmdTmp contains our glow (with alpha set)
				// Draw the original image, then our tmp overlay on top (scaled)
				bmdNew = bmdOrig.clone();
				if (!bmdNew)
					return null;
				var mat:Matrix = new Matrix();
				mat.scale(bmdOrig.width/bmdTmp.width, bmdOrig.height/bmdTmp.height);
				bmdNew.draw(bmdTmp, mat, null, null, null, true);
				
				// Free up temporary memory
				bmdTmp.dispose();
			} else {
				bmdNew = VBitmapData.Construct(bmdOrig.width, bmdOrig.height, true, 0xff000000);
				if (!bmdNew)
					return null;
				bmdNew.applyFilter(bmdOrig, bmdOrig.rect, new Point(0, 0), flt);
			}
//			Debug.Assert(nRet >= 0, "GlowImageOperation applyFilter returned " + nRet);
			return bmdNew;
		}
	}
}
