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
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	[RemoteClass]
	public class OffsetImageOperation extends BlendImageOperation implements ISimpleOperation {
		private var _cxOffset:Number = 0;
		private var _cyOffset:Number = 0;
		
		public function OffsetImageOperation(cxOffset:Number=0, cyOffset:Number=0) {
			// ImageOperation constructors are called with no arguments during Deserialization
			_cxOffset = cxOffset;
			_cyOffset = cyOffset;
		}
		
		public function set xOffset(val:Number): void {
			_cxOffset = val;
		}
		
		public function get xOffset(): Number {
			return _cxOffset;
		}
		
		public function set yOffset(val:Number): void {
			_cyOffset = val;
		}
		
		public function get yOffset(): Number {
			return _cyOffset;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['xOffset', 'yOffset']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			if (xmlOp.hasOwnProperty('@xOffset'))
				_cxOffset = Number(xmlOp.@xOffset);
			if (xmlOp.hasOwnProperty('@yOffset'))
				_cyOffset = Number(xmlOp.@yOffset);
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Offset xOffset={_cxOffset} yOffset={_cyOffset}/>
		}

		public function ApplySimple(bmdSrc:BitmapData, bmdDst:BitmapData, rcSource:Rectangle, ptDest:Point): void {
			bmdDst.copyPixels(bmdSrc, rcSource, ptDest);
			var rcSrcOffset:Rectangle = rcSource.clone();
			rcSrcOffset.offset(_cxOffset, _cyOffset);
			bmdDst.copyPixels(bmdSrc, rcSrcOffset, ptDest);
		}
		
		override public function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean,
				fUseCache:Boolean): BitmapData {

			// Create a new VBitmapData w/ the resized dimensions
			var bmdNew:BitmapData = bmdSrc.clone();
			var matOffset:Matrix = new Matrix();
			matOffset.translate(_cxOffset, _cyOffset);
			bmdNew.draw(bmdSrc, matOffset, null, null, null, true);
			return bmdNew;
		}
	}
}
