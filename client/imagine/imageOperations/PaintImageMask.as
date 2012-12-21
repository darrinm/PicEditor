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
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.serialization.SerializationUtil;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class PaintImageMask extends ImageMask {
		protected var _aapt:Array;
		protected var _bmdCachedMask:BitmapData = null;
		protected var _bmdResultMask:BitmapData = null;
		protected var _shpLine:Shape;
		protected var _nStrength:Number;
		protected var _blurfilter:BlurFilter;
		protected var _rcUpdate:Rectangle;
		
		private var _nDebug:Number = 0;
		
		public function PaintImageMask(rcBounds:Rectangle = null) {
			super(rcBounds);
			_rcUpdate = null;
			_blurfilter = new BlurFilter(8,8);
			_nStrength = 215;
			ResetMask();
		}

		/*
		uncomment when we start to support partial updates in BlendImageOperation.as
		public override function get AlphaBounds():Rectangle {
			return _rcUpdate;
		}

		public override function get nOuterAlpha():Number {
			return 1;
		}
		*/
		
		// Range: 0-255 (0 = no effect, 255 = full strength)
		[Bindable]
		public function get strength(): Number {
			return _nStrength;
		}
		
		public function set strength(nStrength:Number): void {
			_nStrength = nStrength;
		}

		/*
		* lines array
		* each array has a fUpdated flag
		*/
		public function set lines(aapt:Array): void {
			// Copy the array of polylines in case the caller keeps messing with it
			_aapt = aapt ? aapt.slice() : null;
			if (!_aapt) ResetMask();
		}
		
		public override function Deserialize(xml:XML): Boolean {
			var fSuccess:Boolean = super.Deserialize(xml);
			if (fSuccess) {
				_aapt = new Array();
				for each (var xmlLine:XML in xml.PolyLine) {
					var apt:Array = new Array();
					apt.nWidth = Number(xmlLine.@nWidth);
					apt.nStrength = Number(xmlLine.@nStrength);
					apt.fPaint = (xmlLine.@fPaint == "true");
					apt.fUpdated = true;
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
				ResetMask();
			}
			return fSuccess;
		}
		
		override public function writeExternal(output:IDataOutput):void {
			super.writeExternal(output);
			var obMask:Object = {};
			obMask.lines = _aapt;
			output.writeObject(obMask);
		}
		
		override public function readExternal(input:IDataInput):void {
			super.readExternal(input);
			var obMask:Object = input.readObject();
			_aapt = SerializationUtil.CleanSrlzReadValue(obMask.lines);
			ResetMask();
		}
		
		public override function Serialize(): XML {
			var xml:XML = super.Serialize();
			for each (var apt:Array in _aapt) {
				var xmlLine:XML = <PolyLine nWidth={apt.nWidth} nStrength={apt.nStrength} fPaint={apt.fPaint}/>;
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
		
		private function ResetMask(): void {
			if (_bmdCachedMask) _bmdCachedMask.dispose(); // Get rid of the old mask
			_bmdCachedMask = null;
			if (_bmdResultMask) _bmdResultMask.dispose(); // Get rid of the old mask
			_bmdResultMask = null;
		}
		
		private function CreateBitmapDatas(nStrength:uint=0): void {
			_bmdCachedMask = VBitmapData.Construct(width, height, false, nStrength); // Fill blue channel with alpha 0
			_bmdResultMask = VBitmapData.Construct(width, height, true, nStrength); // Fill blue channel with alpha 0
		}

		protected function PaintMask(fCached:Boolean=true): BitmapData {
			// if fCached is true, then we only render arrays that have not yet been rendered
			// other wise, we draw all.
			if (!_bmdCachedMask)
				CreateBitmapDatas();
			
			if (!_aapt)
				return _bmdResultMask;
				
			var rcTotal:Rectangle = null;
							
			for (var iapt:Number = 0; iapt < _aapt.length; iapt++) {
				var apt:Array = _aapt[iapt];
				if (!("nStrength" in apt)) apt.nStrength = _nStrength;
				
				// if we have a cache and this line hasn't been updated, pass
				if (fCached && !apt.fUpdated)
					continue;
				
				if (!("nItems" in apt)) apt.nItems = 0;
				
				var shp:Shape = new Shape();
				var blendMode:String = (apt.fPaint) ? BlendMode.ADD : BlendMode.SUBTRACT;
				with (shp.graphics) {
					lineStyle(apt.nWidth, apt.nStrength);
					// If we just have a start point, make up a very close by end point so
					// we'll draw a dot.
					if (apt.length == 1) {
						moveTo(apt[0].x, apt[0].y);
						lineTo(apt[0].x + 0.2, apt[0].y);
					} else {
						moveTo(apt[0].x, apt[0].y);
						for (var i:Number = 0; i < apt.length; i++)
							lineTo(apt[i].x, apt[i].y);
					}
				}

				var rcT:Rectangle = shp.getBounds(shp);
				rcT.top = Math.round(rcT.top);
				rcT.left = Math.round(rcT.left);
				rcT.width = Math.round(rcT.width);
				rcT.height = Math.round(rcT.height);
				rcTotal = (rcTotal) ? rcTotal.union(rcT) : rcT;
				
				if (iapt < (_aapt.length -1)) {
					apt.fUpdated = false;
					_bmdCachedMask.draw(shp, null, null, blendMode);
				}
			}

			if (rcTotal) {
				//rcTotal = new Rectangle(0, 0, width, height); //debug, turn off update rects
				_bmdResultMask.copyPixels(_bmdCachedMask, rcTotal, rcTotal.topLeft);
				_bmdResultMask.draw(shp, null, null, blendMode);
				_bmdResultMask.copyChannel(_bmdResultMask, rcTotal, rcTotal.topLeft, BitmapDataChannel.BLUE, BitmapDataChannel.ALPHA);
				_bmdResultMask.applyFilter(_bmdResultMask, rcTotal, rcTotal.topLeft, _blurfilter);
			}
			_rcUpdate = rcTotal;
			
			return _bmdResultMask;
		}
		
		public override function Mask(bmdOrig:BitmapData): BitmapData {
			if (_bmdCachedMask == null || _bmdCachedMask.width != width || _bmdCachedMask.height != height) {
				ResetMask();
			}
			if (!_aapt || _aapt.length == 0 || _aapt[0].length == 0)
				return null;
				
			return PaintMask();
		}
	}
}
