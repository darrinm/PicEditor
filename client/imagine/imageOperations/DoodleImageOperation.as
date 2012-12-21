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
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationUtil;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	[RemoteClass]
	public class DoodleImageOperation extends BlendImageOperation {
		private var _aapt:Array;

		public function set lines(aapt:Array): void {
			// Copy the array of polylines in case the caller keeps messing with it
			_aapt = aapt ? aapt.slice() : null;
		}
		
		public function DoodleImageOperation(nAlpha:Number=NaN, aapt:Array=null) {
			_nAlpha = nAlpha;
			if (aapt)
				_aapt = aapt.slice();
		}
	
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			_aapt = new Array();
			for each (var xmlLine:XML in xmlOp.PolyLine) {
				var apt:Array = new Array();
				apt.width = Number(xmlLine.@width);
				apt.color = Number(xmlLine.@color);
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
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_aapt);
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_aapt = SerializationUtil.CleanSrlzReadValue(input.readObject());
		}
		
		override protected function SerializeSelf(): XML {
			var xml:XML = <Doodle/>;
			for each (var apt:Array in _aapt) {
				var xmlLine:XML = <PolyLine width={apt.width} color={apt.color}/>;
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
			return Doodle(bmdSrc, _aapt);
		}
		
		public static function Doodle(bmdOrig:BitmapData, aapt:Array): BitmapData {
			var bmdTmp:BitmapData = bmdOrig.clone();
			if (!aapt)
				return bmdTmp;
				
			var shp:Shape = new Shape();
			with (shp.graphics) {
				for each (var apt:Array in aapt) {
					lineStyle(apt.width, apt.color, 1, false);
					moveTo(apt[0].x, apt[0].y);
					
					// If we just have a start point, make up a very close by end point so
					// we'll draw a dot.
					if (apt.length == 1) {
						lineTo(apt[0].x + 0.2, apt[0].y);
					} else {
						for (var i:Number = 1; i < apt.length; i++)
							lineTo(apt[i].x, apt[i].y);
					}
				}
			}
			
			bmdTmp.draw(shp);
			return bmdTmp;
		}
	}
}
