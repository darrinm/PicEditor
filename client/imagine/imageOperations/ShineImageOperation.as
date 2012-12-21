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
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationUtil;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class ShineImageOperation extends BlendImageOperation {
		private var _aapt:Array;

		public function set lines(aapt:Array): void {
			// Copy the array of polylines in case the caller keeps messing with it
			_aapt = aapt ? aapt.slice() : null;
		}
		
		public function ShineImageOperation(nAlpha:Number=NaN, aapt:Array=null) {
			_nAlpha = nAlpha;
			if (aapt)
				_aapt = aapt.slice();
		}
	
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_aapt);
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_aapt = SerializationUtil.CleanSrlzReadValue(input.readObject());
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			_aapt = new Array();
			for each (var xmlLine:XML in xmlOp.PolyLine) {
				var apt:Array = new Array();
				apt.width = Number(xmlLine.@width);
				var strT:String = xmlLine.toString();
				Debug.Assert(strT != "", "PolyLine child text missing");
				var dec:Base64Decoder = new Base64Decoder();
				dec.decode(strT);
				var ba:ByteArray = dec.drain();
				ba.uncompress();
				for (var i:Number = 0; i < ba.length / 4; i++) {
					var x:Number = ba.readShort();
					var y:Number = ba.readShort();
					apt.push(new Point(x, y));
				}
				_aapt.push(apt);
			}
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			var xml:XML = <Shine/>;
			for each (var apt:Array in _aapt) {
				var xmlLine:XML = <PolyLine width={apt.width} />;
				var ba:ByteArray = new ByteArray();
				for (var i:Number = 0; i < apt.length; i++) {
					var pt:Point = apt[i];
					ba.writeShort(pt.x);
					ba.writeShort(pt.y);
				}
				ba.compress();
				var enc:Base64Encoder = new Base64Encoder();
				enc.encodeBytes(ba);
				xmlLine.appendChild(new XML(enc.drain()));
				xml.appendChild(xmlLine);
			}
			return xml;
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return Shine(bmdSrc, _aapt);
		}
		
		public static function generateGradientSubMask(nWidth:Number): BitmapData {
			var bmdMask:BitmapData = VBitmapData.Construct(nWidth, nWidth, true, 0); // Fill with alpha 0
			
			var shp:Shape = new Shape();
			var acoColors:Array = [0xFF00,0xFF];
			var anAlphas:Array = [1,0];
			var anRatios:Array = [0,200];
			var mat:Matrix = new Matrix();
			mat.createGradientBox(nWidth, nWidth, 0, 0, 0);
			shp.graphics.beginGradientFill(GradientType.RADIAL, acoColors, anAlphas, anRatios, mat);
			shp.graphics.drawRect(0, 0, nWidth, nWidth);
			bmdMask.draw(shp);
			return bmdMask;
		}		

		public static function generateFillMask(nWidth:Number, nAngle:Number, fReverse:Boolean ): BitmapData {
			var bmdMask:BitmapData = VBitmapData.Construct(nWidth, nWidth, true, 0); // Fill with alpha 0
			
			var shp:Shape = new Shape();
			var acoColors:Array = [0xFF00,0xFF];
			var anAlphas:Array = fReverse ? [0,1] : [1,0];
			var anRatios:Array = fReverse ? [96,255] : [0,160];
			var mat:Matrix = new Matrix();
			mat.createGradientBox(nWidth, nWidth, nAngle, 0, 0);
			shp.graphics.beginGradientFill(GradientType.LINEAR, acoColors, anAlphas, anRatios, mat);
			shp.graphics.drawRect(0, 0, nWidth, nWidth);
			bmdMask.draw(shp);
			return bmdMask;
		}		
		
		
		public static function RemoveShine(bmdOrig:BitmapData, nWidth:Number, ptPixel:Point):void {
			nWidth = nWidth & (~1);
			var mat:Matrix = new Matrix();
			var nDist:Number = nWidth/2;
			var nDistPt7:Number = nDist * 0.7;
						   
			var bmd:BitmapData = VBitmapData.Construct(nWidth, nWidth, true);
			var bmd2:BitmapData = VBitmapData.Construct(nWidth, nWidth, true);
			var bmdFillMask:BitmapData = null;
			var x:Number = ptPixel.x;
			var y:Number = ptPixel.y;
			var rc:Rectangle = new Rectangle(0,0,nWidth,nWidth);
			var pt:Point = new Point(0,0);
			
			// copy the pixels over and blur 'em
			bmd.copyPixels(bmdOrig, new Rectangle(x - nDist, y - nDist, nWidth, nWidth), pt);
			bmd.applyFilter(bmd, rc, pt, new BlurFilter(8,8));

			//peek at some pixels around our brush to fill in the bitmap
			var apxPeeks:Array = [ { x: -1, y: -1 },
								   { x: 1, y: -1 },
								   { x: -1, y: 1 },
								   { x: 1, y: 1 } ];
			for (var i:Number = 0; i < apxPeeks.length; i++) {
				if (i != 1) continue;
				// we peek at a distance of 0.7 from the center, which
				// will put us right on the radius of the circle
				var myX:Number = nDist + apxPeeks[i].x * nDistPt7;
				var myY:Number = nDist + apxPeeks[i].y * nDistPt7;
				var rgb:uint = (0xFF << 24) + bmd.getPixel(myX, myY);
							
				bmd2.fillRect( new Rectangle( 0, 0, nWidth, nWidth ), rgb );
				bmdFillMask = generateFillMask( nWidth,
					apxPeeks[i].x == apxPeeks[i].y ? Math.PI / 4 : -1 * Math.PI / 4,
					apxPeeks[i].x > 0 ? true : false );
				bmd2.copyChannel(bmdFillMask, rc, pt, BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
				bmd.draw(bmd2, mat, null, 'normal');
				bmdFillMask.dispose();
			}

			// blur it again so people don't see the rectangles
			bmd.applyFilter(bmd, rc, pt, new BlurFilter(8,8));
				
			//setup our alpha for a gradient brush
			var bmdMask:BitmapData = generateGradientSubMask(nWidth);
			bmd.copyChannel(bmdMask, rc, pt, BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
			
			//blend result back onto original image
			mat.translate(x - nDist, y - nDist);
			bmdOrig.draw(bmd, mat, null, 'darken');
			
			bmd.dispose();
			bmd2.dispose();
			bmdMask.dispose();
		}
		
		public static function Shine(bmdOrig:BitmapData, aapt:Array): BitmapData {
			var bmdTmp:BitmapData = bmdOrig.clone();
			if (!aapt)
				return bmdTmp;
				
			for each (var apt:Array in aapt) {
				RemoveShine(bmdTmp, apt.width, apt[0]);
			}
			
			return bmdTmp;
		}
	}
}
