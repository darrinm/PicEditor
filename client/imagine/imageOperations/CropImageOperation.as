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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class CropImageOperation extends BlendImageOperation {
		private var _x:Number = 0;
		private var _y:Number = 0;
		private var _cx:Number = 0;
		private var _cy:Number = 0;
		
		public function CropImageOperation(x:Number=NaN, y:Number=NaN, cx:Number=NaN, cy:Number=NaN) {
			// ImageOperation constructors are called with no arguments during Deserialization
			if (isNaN(x))
				return;
			
			// We can't really crop to a partial pixel so inflate to the nearest integer bounds
			_x = Math.floor(x);
			_y = Math.floor(y);
			_cx = Math.ceil(cx);
			_cy = Math.ceil(cy);
		}
		
		public function set x(x:Number): void {
			_x = x;
		}
		
		public function get x(): Number {
			return _x;
		}
		
		public function set y(y:Number): void {
			_y = y;
		}
		
		public function get y(): Number {
			return _y;
		}
		
		public function set width(cx:Number): void {
			if (cx < 1)
				PicnikService.Log("Invalid crop width set: " + cx, PicnikService.knLogSeverityError);
			_cx = cx;
		}
		
		public function get width(): Number {
			return _cx;
		}
		
		public function set height(cy:Number): void {
			if (cy < 1)
				PicnikService.Log("Invalid crop height set: " + cy, PicnikService.knLogSeverityError);
			_cy = cy;
		}
		
		public function get height(): Number {
			return _cy;
		}
			
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			// We can't really crop to a partial pixel so inflate to the nearest integer bounds
			Debug.Assert(xmlOp.@x, "CropImageOperation x argument missing");
			_x = Math.floor(Number(xmlOp.@x));
			Debug.Assert(xmlOp.@y, "CropImageOperation y argument missing");
			_y = Math.floor(Number(xmlOp.@y));
			
			Debug.Assert(xmlOp.@width, "CropImageOperation width argument missing");
			_cx = Math.ceil(Number(xmlOp.@width));
			Debug.Assert(xmlOp.@height, "CropImageOperation height argument missing");
			_cy = Math.ceil(Number(xmlOp.@height));
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Crop x={_x} y={_y} width={_cx} height={_cy}/>
		}

		private static var _srzinfo:SerializationInfo = new SerializationInfo(['x', 'y', 'width', 'height']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}

		override public function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			// Oops, we have serialized some .pik files with invalid crop rectangles.
			// We can't repair them on deserialization because then we don't have
			// access to the image's dimensions then. Repair them here.
			if (_cx < 1)
				_cx = bmdSrc.width - _x;
			if (_cy < 1)
				_cy = bmdSrc.height - _y;
			
			// Create a new VBitmapData w/ the cropped dimensions
			var bmdNew:BitmapData = VBitmapData.Construct(_cx, _cy, true, NaN);
			if (!bmdNew)
				return null;
			
			// Copy the cropped pixels from the old bitmap to the new
			bmdNew.copyPixels(bmdSrc, new Rectangle(_x, _y, _cx, _cy), new Point(0, 0));
			
			// Crop all the DocumentObjects too
			if (fDoObjects) {
				var dctPropertySets:Object = {};
				SetPropertiesObjectOperation.OffsetDocumentObjects(dctPropertySets, imgd, -_x, -_y);
				SetPropertiesObjectOperation.SetProperties(dctPropertySets, imgd);
			}
			return bmdNew;
		}
	}
}
