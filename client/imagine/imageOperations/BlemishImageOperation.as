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
	public class BlemishImageOperation extends BlendImageOperation {
		private var _aapt:Array;

		public function set lines(aapt:Array): void {
			// Copy the array of polylines in case the caller keeps messing with it
			_aapt = aapt ? aapt.slice() : null;
		}
		
		public function BlemishImageOperation(nAlpha:Number=NaN, aapt:Array=null) {
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
			var xml:XML = <Blemish/>;
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
			return Blemish(bmdSrc, _aapt);
		}
		
		public static function generateGradientSubMask(nWidth:Number): BitmapData {
			var _nInnerRadius:Number = 0; // applies to height if aspect != 1
			var _nOuterRadius:Number = 100; // applies to height if aspect != 1
			var bmdMask:BitmapData = VBitmapData.Construct(nWidth, nWidth, true, 0); // Fill with alpha 0
			var nOuterRadius:Number = Math.max(_nInnerRadius, _nOuterRadius);
			
			var shp:Shape = new Shape();
			var acoColors:Array = [0xFF00,0xFF];
			var anAlphas:Array = [1, 0];
			var anRatios:Array = [255 * _nInnerRadius/nOuterRadius,255];
			var mat:Matrix = new Matrix();
			mat.createGradientBox(nWidth, nWidth, 0, 0, 0);
			shp.graphics.beginGradientFill(GradientType.RADIAL, acoColors, anAlphas, anRatios, mat);
			shp.graphics.drawRect(0, 0, nWidth, nWidth);
			bmdMask.draw(shp);
			return bmdMask;
		}		
		
		
		public static function RemoveBlemish(bmdOrig:BitmapData, nWidth:Number, ptPixel:Point):void {
			nWidth = nWidth & (~1);
			var mat:Matrix = new Matrix();
			var nDist:Number = nWidth/2;
			var bmd:BitmapData = VBitmapData.Construct(nWidth, nWidth);
			var x:Number = ptPixel.x;
			var y:Number = ptPixel.y;
			var rc:Rectangle = new Rectangle(0,0,nWidth,nWidth);
			var pt:Point = new Point(0,0);
			
			//copy some bits near our bursh
			bmd.copyPixels(bmdOrig, new Rectangle(x - nWidth, y - nDist, nDist, nWidth), pt);
			bmd.copyPixels(bmdOrig, new Rectangle(x + nDist, y - nDist, nDist, nWidth), new Point(nDist,0));
			
			//fuzz them up a bit
			bmd.applyFilter(bmd, rc, pt, new BlurFilter(8,8));
			
			//setup our alpha for a gradient brush
			var bmdMask:BitmapData = generateGradientSubMask(nWidth);
			bmd.copyChannel(bmdMask, rc, pt, BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
			
			//blend result back onto original image
			mat.translate(x - nDist, y - nDist);
			bmdOrig.draw(bmd, mat, null, 'lighten');
			
			bmd.dispose();
			bmdMask.dispose();
		}
		
		public static function Blemish(bmdOrig:BitmapData, aapt:Array): BitmapData {
			var bmdTmp:BitmapData = bmdOrig.clone();
			if (!aapt)
				return bmdTmp;
				
			for each (var apt:Array in aapt) {
				RemoveBlemish(bmdTmp, apt.width, apt[0]);
			}
			
			return bmdTmp;
		}
	}
}
