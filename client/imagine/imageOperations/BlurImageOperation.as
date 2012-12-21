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
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class BlurImageOperation extends BlendImageOperation {
		private var _xBlur:Number;
		private var _yBlur:Number;
		private var _nQuality:Number;
		private var _fBlurAlpha:Boolean = false;
		
		private var _nSurfaceThreshold:Number = 255;

		private static const knLumR:Number = 0.3086;
		private static const knLumG:Number = 0.6094;
		private static const knLumB:Number = 0.0820;
		
		private function cleanBlur(nBlur:Number): Number {
			if (nBlur > knMaxBlur) return knMaxBlur;
			else if (nBlur < 1) return 0; // No fractional blurring < 1
			// For very fine adjustments, blur has "wonky" zones
			// near whole numbers for which the blur increase is non-linear
			else if (nBlur > 5 && nBlur < 5.13) return 5.13;
			else if (nBlur > 4 && nBlur < 4.13) return 4.13;
			else if (nBlur >= 3 && nBlur < 3.0625) return 3.0625;
			else if (nBlur > 2 && nBlur < 2.065) return 2.065;
			else return nBlur;
		}
		
		public function set xblur(xBlur:Number): void {
			_xBlur = cleanBlur(xBlur);
		}
		
		public function get xblur(): Number {
			return _xBlur;
		}
		
		public function set yblur(yBlur:Number): void {
			_yBlur = cleanBlur(yBlur);
		}
		
		public function get yblur(): Number {
			return _yBlur;
		}
		
		public function set surfaceThreshold(n:Number): void {
			_nSurfaceThreshold = n;
		}
		
		public function get surfaceThreshold(): Number {
			return _nSurfaceThreshold;
		}
		
		public function set blurAlpha(fBlurAlpha:Boolean): void {
			_fBlurAlpha = fBlurAlpha;
		}
		
		public function get blurAlpha(): Boolean {
			return _fBlurAlpha;
		}
		
		public function set quality(nQuality:Number): void {
			_nQuality = Math.max(1, Math.min(nQuality, knMaxQuality));
		}
		
		public function get quality(): Number {
			return _nQuality;
		}
				
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['xblur', 'yblur', 'surfaceThreshold', 'blurAlpha', 'quality']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		private static const knMaxBlur:Number = 255;
		private static const knMaxQuality:Number = 15;

		override protected function get applyHasNoEffect(): Boolean {
			return (_xBlur <= 0 && _yBlur < 0) || _nQuality <= 0;
		}
		
		public function BlurImageOperation(nAlpha:Number=NaN, xBlur:Number=NaN, yBlur:Number=NaN,
				nQuality:Number=NaN, fBlurAlpha:Boolean=false) {
//			_nAlpha = nAlpha;
			_xBlur = xBlur;
			_yBlur = yBlur;
			_nQuality = nQuality;
			_fBlurAlpha = fBlurAlpha;
		}
	
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
//			if (xmlOp.@alpha.toString().length > 0) _nAlpha = Number(xmlOp.@alpha);
			Debug.Assert(xmlOp.@blurX, "BlurImageOperation blurX parameter missing");
			_xBlur = Number(xmlOp.@blurX);
			Debug.Assert(xmlOp.@blurY, "BlurImageOperation blurY parameter missing");
			_yBlur = Number(xmlOp.@blurY);
			Debug.Assert(xmlOp.@quality, "BlurImageOperation quality parameter missing");
			_nQuality = Number(xmlOp.@quality);
			
			if (xmlOp.hasOwnProperty('@surfaceThreshold'))
				_nSurfaceThreshold = Number(xmlOp.@surfaceThreshold);
			else
				_nSurfaceThreshold = 255;
			
			if (xmlOp.hasOwnProperty('@blurAlpha')) {
				_fBlurAlpha = xmlOp.@blurAlpha
			} else {
				// Default for saved ops is true to maintain legacy behavior for existing pik files.
				_fBlurAlpha = true;
			}
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Blur blurX={_xBlur} blurY={_yBlur} quality={_nQuality} blurAlpha={_fBlurAlpha} surfaceThreshold={_nSurfaceThreshold}/>
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return Blur(bmdSrc, _xBlur, _yBlur, _nQuality, _fBlurAlpha, _nSurfaceThreshold);
		}
		
		public static function Blur(bmdOrig:BitmapData, xBlur:Number, yBlur:Number, nQuality:Number, fBlurAlpha:Boolean=false, nSurfaceThreshold:Number=255):BitmapData {
			xBlur = Math.min(xBlur, knMaxBlur);
			yBlur = Math.min(yBlur, knMaxBlur);
			var flt:BlurFilter = new BlurFilter(xBlur, yBlur, nQuality);

			var rcEffect:Rectangle = bmdOrig.generateFilterRect(bmdOrig.rect, flt);
			
			var bmdTmp:BitmapData = VBitmapData.Construct(bmdOrig.width, bmdOrig.height, true, NaN);
			if (rcEffect.width > 8100 || rcEffect.height > 8100 || (rcEffect.width * rcEffect.height) > (4050 * 4050)) {
				// The blur needs more space than we have to apply at this size
				// Resize by one half, apply half the blur, then scale back up.
				var bmdScaled:BitmapData = VBitmapData.Construct(Math.ceil(bmdOrig.width/2), Math.ceil(bmdOrig.height/2), true, NaN);
				var mat:Matrix;
				
				// Draw the original into the scaled bitmap
				mat = new Matrix();
				mat.scale(0.5, 0.5);
				bmdScaled.draw(bmdOrig, mat, null, null, null, true);
				
				// Apply half the blur
				var bmdScaledBlur:VBitmapData = VBitmapData.Construct(bmdScaled.width, bmdScaled.height, true, NaN);
				flt = new BlurFilter(xBlur/2, yBlur/2, nQuality);
				bmdScaledBlur.applyFilter(bmdScaled, bmdScaled.rect, new Point(0,0), flt);
				
				bmdScaled.dispose();
				
				// Draw the blurred scaled image back into our temp image
				mat = new Matrix();
				mat.scale(2, 2);
				bmdTmp.draw(bmdScaledBlur, mat, null, null, null, true);
				
				bmdScaledBlur.dispose();
			} else {
				// We have room to apply the blur directly
				bmdTmp.applyFilter(bmdOrig, bmdTmp.rect, new Point(0,0), flt);
			}
			if (!fBlurAlpha) bmdTmp.copyChannel(bmdTmp, bmdTmp.rect, new Point(0,0), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
			
			if (nSurfaceThreshold < 255) {
				// Apply our surface threshold
				var bmdDiff:BitmapData = bmdOrig.clone();
				bmdDiff.draw(bmdTmp,null,null,BlendMode.DIFFERENCE);
				
				// We can do a fade here to save an operation if we are
				// really eager for a tad bit more speed.
				// This will require exposing another param (BlurFadePercent?)
				var nFade:Number = 0; // 0 means no fade, 255 means fully faded.
				var nMult:Number = (255 - nFade) / nSurfaceThreshold;
				
				var aMat:Array = [
					1, 0, 0, 0, 0,
					0, 1, 0, 0, 0,
					0, 0, 1, 0, 0,
					knLumR * nMult, knLumG * nMult, knLumB * nMult, 0, nFade];
				
				// BW diff in alpha channel
				var fltBW:ColorMatrixFilter = new ColorMatrixFilter(aMat);
				bmdDiff.applyFilter(bmdDiff, bmdDiff.rect, new Point(0,0), fltBW);
	
				// Now blend back in
				bmdTmp.copyPixels(bmdOrig, bmdOrig.rect, new Point(0,0), bmdDiff, new Point(0,0), true);
				
				bmdDiff.dispose();
			}
			
			return bmdTmp;
		}
	}
}
