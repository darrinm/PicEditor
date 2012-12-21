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
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.InterpolationMethod;
	import flash.display.Shape;
	import flash.display.SpreadMethod;
	import flash.filters.BlurFilter;
	import flash.filters.DisplacementMapFilter;
	import flash.filters.DisplacementMapFilterMode;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class FishEyeImageOperation extends BlendImageOperation {
		private var _xCenter:Number;
		private var _yCenter:Number;
		private var _xStretch:Number;
		private var _yStretch:Number;
		private var _xAspect:Number;
		private var _yAspect:Number;
		private var _nStrength:Number;
		private var _nSize:Number;
		private var _xSkew:Number;
		private var _ySkew:Number;

		public function set x(x:Number): void {
			_xCenter = x;
		}
		
		public function get x(): Number {
			return _xCenter;
		}
		
		public function set y(y:Number): void {
			_yCenter = y;
		}
		
		public function get y(): Number {
			return _yCenter;
		}
		
		public function set strength(n:Number): void {
			_nStrength = Math.floor(n);
		}		
		
		public function get strength(): Number {
			return _nStrength;
		}		
		
		public function set size(n:Number): void {
			_nSize = Math.floor(n);
		}		
		
		public function get size(): Number {
			return _nSize;
		}		
		
		public function set xSkew(n:Number): void {
			_xSkew = Math.floor(n);
		}		
		
		public function get xSkew(): Number {
			return _xSkew;
		}		
		
		public function set ySkew(n:Number): void {
			_ySkew = Math.floor(n);
		}		
		
		public function get ySkew(): Number {
			return _ySkew;
		}		
		
		public function set xStretch(n:Number): void {
			_xStretch = n;
		}		
		
		public function get xStretch(): Number {
			return _xStretch;
		}		
		
		public function set yStretch(n:Number): void {
			_yStretch = n;
		}			
		
		public function get yStretch(): Number {
			return _yStretch;
		}			
		
		public function set xAspect(n:Number): void {
			_xAspect = n;
		}		
		
		public function get xAspect(): Number {
			return _xAspect;
		}		
		
		public function set yAspect(n:Number): void {
			_yAspect = n;
		}		
		
		public function get yAspect(): Number {
			return _yAspect;
		}		
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo([
			'x',
			'y',
			'strength',
			'size',
			'xSkew',
			'ySkew',
			'xStretch',
			'yStretch',
			'xAspect',
			'yAspect']);

		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		public function FishEyeImageOperation(x:Number=NaN, y:Number=NaN, strength:Number=NaN, size:Number=NaN, xSkew:Number=0.5, ySkew:Number=0.5, xStretch:Number=1, yStretch:Number=1, xAspect:Number=1, yAspect:Number=1) {
			_xCenter = x;
			_yCenter = y;
			_nStrength = strength;
			_nSize = size;
			_xSkew = xSkew;
			_ySkew = ySkew;
			_xStretch = xStretch;
			_yStretch = yStretch;
			_xAspect = xAspect;
			_yAspect = yAspect;
		}

		override protected function DeserializeSelf(xmlOp:XML): Boolean {
//			if (xmlOp.@alpha.toString().length > 0) _nAlpha = Number(xmlOp.@alpha);
			Debug.Assert(xmlOp.@x, "FishEyeImageOperation x parameter missing");
			_xCenter = Number(xmlOp.@x);
			Debug.Assert(xmlOp.@y, "FishEyeImageOperation y parameter missing");
			_yCenter = Number(xmlOp.@y);
			Debug.Assert(xmlOp.@strength, "FishEyeImageOperation strength parameter missing");
			_nStrength = Number(xmlOp.@strength);			
			Debug.Assert(xmlOp.@size, "FishEyeImageOperation size parameter missing");
			_nSize = Number(xmlOp.@size);			
			Debug.Assert(xmlOp.@xSkew, "FishEyeImageOperation xSkew parameter missing");
			_xSkew = Number(xmlOp.@xSkew);			
			Debug.Assert(xmlOp.@ySkew, "FishEyeImageOperation ySkew parameter missing");
			_ySkew = Number(xmlOp.@ySkew);		
			if (xmlOp.hasOwnProperty("@xStretch")) {
				_xStretch = Number(xmlOp.@xStretch);
			} else {
				_xStretch = 1;
			}
			if (xmlOp.hasOwnProperty("@yStretch")) {
				_yStretch = Number(xmlOp.@yStretch);
			} else {
				_yStretch = 1;
			}
			if (xmlOp.hasOwnProperty("@xAspect")) {
				_xAspect = Number(xmlOp.@xAspect);
			} else {
				_xAspect = 1;
			}
			if (xmlOp.hasOwnProperty("@yAspect")) {
				_yAspect = Number(xmlOp.@yAspect);
			} else {
				_yAspect = 1;
			}
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <FishEye x={_xCenter} y={_yCenter} strength={_nStrength} size={_nSize} xSkew={_xSkew} ySkew={_ySkew} xStretch={_xStretch} yStretch={_yStretch} xAspect={_xAspect} yAspect={_yAspect}/>
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return FishEye(bmdSrc, _xCenter, _yCenter, _nStrength, _nSize, _xSkew, _ySkew, _xStretch, _yStretch, _xAspect, _yAspect);
		}
		
		private static const knResolution:int = 32;		// bigger == nicer fisheye, but slower
		private static const knScaleFactor:Number = 0.5;	// calibrated so that we don't exceed +/- 128
		
		private static function CreateFishEyeDisplacementBitmap(nWidth:Number, nHeight:Number, xCenter:Number, yCenter:Number, nStrength:Number, nSize:Number, xSkew:Number, ySkew:Number, xStretch:Number, yStretch:Number, xAspect:Number, yAspect:Number):BitmapData {
			var nMax:int = Math.max(nWidth,nHeight);
			var nMin:int = Math.min(nWidth,nHeight);			
			var nChunkSize:Number = nMax * 1.0 / knResolution;
			var xSide:int = Math.ceil(nWidth/nChunkSize);
			var ySide:int = Math.ceil(nHeight/nChunkSize);
			var nRadius:Number = nMin/nChunkSize * nSize * 0.5;
			var dbmd:BitmapData = VBitmapData.Construct(xSide, ySide, false, 0x8080, "fish eye displacement");
			
			xCenter = xCenter/nWidth * xSide;
			yCenter = yCenter/nHeight * ySide;

		 	for( var y:int = 0; y < ySide; y++ ) {
				var dy:Number = yAspect * (y - yCenter) + 0.5;
				for(var x:int = 0; x < xSide; x++) {
		  			var dx:Number = xAspect * (x - xCenter) + 0.5;
		  			var d:Number = Math.sqrt(dx * dx + dy * dy);
		  			if(d < nRadius) {
						var t:Number = d == 0 ? 0 : Math.sin(Math.PI / 2 * d / nRadius);
						t = t * t;
						var xfactor:Number = (dx - x*(xSkew-0.5)) * (t - 1) / xSide * knScaleFactor * 6 * xStretch;
						var yfactor:Number = (dy - y*(ySkew-0.5)) * (t - 1) / ySide * knScaleFactor * 6 * yStretch;
						var xoffset:Number = Math.max( Math.min( xfactor * 0xff * nStrength, 127 ), -128 );
						var yoffset:Number = Math.max( Math.min( yfactor * 0xff * nStrength, 127 ), -128 );
						var blue:int = 128 + xoffset;
						var green:int = 128 + yoffset;
						dbmd.setPixel(x, y, green << 8 | blue);
		  			} else {
		  			}
				} 
		  	}
		  			      			
			// used for masks and displacement
			var bmd:BitmapData = VBitmapData.Construct(nWidth, nHeight, true, 0x8080);
			var matr:Matrix = new Matrix();
			matr.scale(nWidth / xSide, nHeight / ySide );
			bmd.draw(dbmd,matr,null,null,null,true);
			dbmd.dispose();			
			return bmd;
		}

		public static function FishEye(bmdOrig:BitmapData, xCenter:Number, yCenter:Number, nStrength:Number, nSize:Number, xSkew:Number, ySkew:Number, xStretch:Number, yStretch:Number, xAspect:Number, yAspect:Number): BitmapData {
			var nMax:int = Math.max(bmdOrig.width,bmdOrig.height);
			var nMin:int = Math.min(bmdOrig.width,bmdOrig.height);
			var bmdFinal:BitmapData = bmdOrig.clone();
			var nPixels:Number = Math.floor(nMin * (nSize/100));
			var nScale:int = Math.floor((Math.sqrt( nPixels * nPixels * 2 ) - nPixels)/2);
			
			if (nPixels == 0) {
				return bmdFinal;
			}
			
			var bmdDisplacement:BitmapData = CreateFishEyeDisplacementBitmap(
												nPixels, nPixels,
												Math.floor(nPixels/2), Math.floor(nPixels/2),
												nStrength/100.0, 1.0, xSkew/100.0, ySkew/100.0,
												xStretch, yStretch, xAspect, yAspect);
			//return bmdDisplacement;
			
			
			// Apply the blurred displacement map to the original bitmap
			var fltDisplacement:DisplacementMapFilter = new DisplacementMapFilter(bmdDisplacement,
					new Point(Math.floor(xCenter-nPixels/2), Math.floor(yCenter-nPixels/2)), BitmapDataChannel.BLUE, BitmapDataChannel.GREEN, nScale, nScale,
					DisplacementMapFilterMode.COLOR, 0x000000 /*black*/, 1.0 );
			bmdFinal.applyFilter(
					bmdOrig,
					new Rectangle(Math.floor(xCenter-nPixels/2), Math.floor(yCenter-nPixels/2),nPixels, nPixels),
					new Point(Math.floor(xCenter-nPixels/2), Math.floor(yCenter-nPixels/2)),
					fltDisplacement);
			bmdDisplacement.dispose();
			return bmdFinal;
		}
	}
}
