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
	
	import imagine.serialization.SerializationInfo;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class ColorReduceImageOperation extends PaletteMapImageOperation {
		private var _nLevels:Number;
						
		public function ColorReduceImageOperation( nLevels:Number = 3) {
			// ImageOperation constructors are called with no arguments during Deserialization
			_nLevels = nLevels;
			CalcLevels(_nLevels);
		}
				
		public function set Levels(nLevels:Number): void {
			_nLevels = nLevels;
			CalcLevels(_nLevels);
		}
		
		public function get Levels(): Number {
			return _nLevels;
		}
	
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['Levels']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		// CONSIDER: makes more sense to store as elements?
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			_nLevels = xmlOp.@levels;
			CalcLevels(_nLevels);
			return true;
		}
		
		override protected function SerializeSelf(): XML {			
			var xml:XML = <ColorReduce/>
			xml.@levels = _nLevels;
			return xml;
		}

		private function CalcLevels( nLevels:Number ): void {
			if (nLevels < 2)
				nLevels = 2;
			var nStep:int = Math.ceil(256 / nLevels);
			
			var acoRed:Array = new Array(256);
			var acoGreen:Array = new Array(256);
			var acoBlue:Array = new Array(256);
			
			// map the colors down to the requested number of levels
			for (var i:int = 0; i < 256; i++) {
				var val:int = Math.floor( i / nStep ) * 255 / (nLevels-1);
				acoBlue[i] = val;
				val <<= 8;
				acoGreen[i] = val;
				val <<= 8;
				acoRed[i] = val;
			}	
			this.Reds = acoRed;		
			this.Greens = acoGreen;		
			this.Blues = acoBlue;		
		}
	}
}
