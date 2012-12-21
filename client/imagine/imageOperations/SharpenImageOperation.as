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
	import com.gskinner.filters.SharpenFilter;
	
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class SharpenImageOperation extends BlendImageOperation {
		private var _nSharpness:Number = 0;
		
		public function SharpenImageOperation(nSharpness:Number=NaN) {
			// ImageOperation constructors are called with no arguments during Deserialization
			if (isNaN(nSharpness))
				return;
			
			_nSharpness = nSharpness;
			Debug.Assert(_nSharpness >= 0 && _nSharpness <= 100, "Sharpness value must 0 <= n <= 100 (attempting " + _nSharpness + ")");
		}
		
		public function set sharpness(nSharpness:Number): void {
			_nSharpness = nSharpness;
		}
		
		public function get sharpness(): Number {
			return _nSharpness;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['sharpness']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@sharpness, "SharpenImageOperation sharpness argument missing");
			_nSharpness = Number(xmlOp.@sharpness);
			Debug.Assert(_nSharpness >= 0 && _nSharpness <= 100, "Sharpness value must 0 <= n <= 100 (attempting " + _nSharpness + ")");
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Sharpen sharpness={_nSharpness}/>
		}
		
		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return Sharpen(bmdSrc, _nSharpness, fUseCache);
		}
		
		private static function Sharpen(bmdOrig:BitmapData, nSharpness:Number, fUseCache:Boolean): BitmapData {
			var bmdNew:BitmapData = VBitmapData.Construct(bmdOrig.width, bmdOrig.height, true, 0xffffff);
			if (!bmdNew)
				return null;
			
			var flt:SharpenFilter = new SharpenFilter(nSharpness);
			bmdNew.applyFilter(bmdOrig, bmdOrig.rect, new Point(0, 0), flt);
			return bmdNew;
		}
	}
}
