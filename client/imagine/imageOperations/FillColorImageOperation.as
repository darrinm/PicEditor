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
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class FillColorImageOperation extends BlendImageOperation {
		private var _co:uint;
		
		public function FillColorImageOperation(co:uint=0xffffffff) {
			_co = co;
		}
	
		public function set color(co:uint): void {
			_co = co;
		}
		
		public function get color(): uint {
			return _co;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['color']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@color, "FillColorImageOperation color parameter missing");
			_co = int(xmlOp.@color);
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <FillColor color={_co}/>
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			var bmdNew:BitmapData = VBitmapData.Construct(bmdSrc.width, bmdSrc.height, true, _co);
			return bmdNew;
		}
	}
}
