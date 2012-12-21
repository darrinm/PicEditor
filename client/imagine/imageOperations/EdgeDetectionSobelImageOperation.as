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
	import flash.filters.ConvolutionFilter;
	import flash.geom.Point;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class EdgeDetectionSobelImageOperation extends BlendImageOperation {
		private var _strDirection:String = "";
		
		public function EdgeDetectionSobelImageOperation( strDirection:String="") {
			// ImageOperation constructors are called with no arguments during Deserialization
			
			_strDirection = strDirection;
		}
		
	
		public function set direction(strDirection:String): void {
			_strDirection = strDirection;
		}
		
		public function get direction(): String {
			return _strDirection;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['direction']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@direction, "EdgeDetectionImageOperation direction argument missing");
			_strDirection = String(xmlOp.@direction);
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <EdgeDetectionSobel direction={_strDirection}/>
		}
		
		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return EdgeDetect(bmdSrc, _strDirection, fUseCache);
		}
		
		private static function EdgeDetect(bmdOrig:BitmapData, strDirection:String, fUseCache:Boolean): BitmapData {
			var bmdNew:BitmapData = VBitmapData.Construct(bmdOrig.width, bmdOrig.height, true, 0xffffff);
			if (!bmdNew)
				return null;
			
			// SOBEL edge detection filter(s)
			var aMatrix:Array = [];
			if ("horizontal" == strDirection) {
				aMatrix = [	-2, 0, +2,
							-4, 0, +4,
							-2, 0, +2 ];
			} else {
				aMatrix = [	+2, +4, +2,
							 0,  0,  0,
							-2, -4, -2 ];
			}
			var flt:ConvolutionFilter = new ConvolutionFilter( 3, 3, aMatrix, 4, 128 );
			bmdNew.applyFilter(bmdOrig, bmdOrig.rect, new Point(0, 0), flt);
			return bmdNew;
		}
	}
}
