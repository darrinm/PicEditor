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
	import flash.display.StageQuality;
	import flash.geom.Matrix;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import mx.core.Application;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class PixelateImageOperation extends BlendImageOperation {
		private var _cx:Number = 0;
		private var _cy:Number = 0;
		private var _offsetX:Number = 0;
		private var _offsetY:Number = 0;
		
		public function PixelateImageOperation(cx:Number=NaN, cy:Number=NaN) {
			// ImageOperation constructors are called with no arguments during Deserialization
			if (isNaN(cx))
				return;
				
			_cx = cx;
			_cy = cy;
		}
		
		public function set pixelWidth(val:Number): void {
			_cx = Math.max(1,val);
		}
		
		public function get pixelWidth(): Number {
			return _cx;
		}
		
		public function set pixelHeight(val:Number): void {
			_cy = Math.max(1,val);
		}
		
		public function get pixelHeight(): Number {
			return _cy;
		}
		
		public function set offsetX(val:Number): void {
			_offsetX = val;
		}
		
		public function get offsetX(): Number {
			return _offsetX;
		}
		
		public function set offsetY(val:Number): void {
			_offsetY = val;
		}
		
		public function get offsetY(): Number {
			return _offsetY;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['pixelWidth', 'pixelHeight', 'offsetX', 'offsetY']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@pixelWidth, "PixelateImageOperation pixelWidth argument missing");
			_cx = Number(xmlOp.@pixelWidth);
			Debug.Assert(xmlOp.@pixelHeight, "PixelateImageOperation pixelHeight argument missing");
			_cy = Number(xmlOp.@pixelHeight);
			Debug.Assert(xmlOp.@offsetX, "PixelateImageOperation offsetX argument missing");
			_offsetX = Number(xmlOp.@offsetX);
			Debug.Assert(xmlOp.@offsetY, "PixelateImageOperation offsetY argument missing");
			_offsetY = Number(xmlOp.@offsetY);
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Pixelate pixelWidth={_cx} pixelHeight={_cy} offsetX={_offsetX} offsetY={_offsetY}/>
		}
		
		override public function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean,
				fUseCache:Boolean): BitmapData {
			return Pixelate(imgd, bmdSrc, fDoObjects, _cx, _cy, _offsetX, _offsetY);
		}
		
		private static function Pixelate(imgd:ImageDocument, bmdOrig:BitmapData, fDoObjects:Boolean,
				cx:Number, cy:Number, offsetX:Number, offsetY:Number): BitmapData {

			var cTilesWide:Number = Math.ceil(bmdOrig.width / cx);
			var cTilesHigh:Number = Math.ceil(bmdOrig.height / cy);
			var mat1:Matrix = new Matrix();
			mat1.translate( -offsetX, -offsetY );
			mat1.scale(cTilesWide / bmdOrig.width, cTilesHigh / bmdOrig.height);
			
			var bmdSmall:BitmapData = VBitmapData.Construct(cTilesWide, cTilesHigh, true);
			if (!bmdSmall) return null;
			
			bmdSmall.draw(bmdOrig, mat1, null, null, null, false);
			
			var bmdNew:BitmapData = VBitmapData.Construct( bmdOrig.width, bmdOrig.height, true );
			var mat2:Matrix = new Matrix();
			mat2.scale( cx, cy );
			mat2.translate( (bmdOrig.width - cx*cTilesWide)/2 + offsetX, (bmdOrig.height - cy*cTilesHigh)/2 + offsetY );
			bmdNew.draw(bmdSmall, mat2, null, null, null, false );
			
			bmdSmall.dispose();

			return bmdNew;
		}
	}
}
