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
	import util.VBitmapData;
	import flash.geom.Point;
	import flash.display.BitmapData;
	import flash.filters.ConvolutionFilter;
	
	import imagine.ImageDocument;
	
	[RemoteClass]
	public class EdgeDetectionLaplaceImageOperation extends BlendImageOperation {
		private var _strDirection:String = "";
		
		public function EdgeDetectionLaplaceImageOperation() {
			// ImageOperation constructors are called with no arguments during Deserialization
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <EdgeDetectionLaplace/>
		}
		
		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return EdgeDetect(bmdSrc, fUseCache);
		}
		
		private static function EdgeDetect(bmdOrig:BitmapData, fUseCache:Boolean): BitmapData {
			var bmdNew:BitmapData = VBitmapData.Construct(bmdOrig.width, bmdOrig.height, true, 0xffffff);
			if (!bmdNew)
				return null;
			
			// LAPLACE edge detection filter
			var aMatrix:Array = [	-1,-1,-1,-1,-1,
									-1,-1,-1,-1,-1,
									-1,-1,24,-1,-1,
									-1,-1,-1,-1,-1,
									-1,-1,-1,-1,-1 ];
			var flt:ConvolutionFilter = new ConvolutionFilter( 5,5, aMatrix );
			bmdNew.applyFilter(bmdOrig, bmdOrig.rect, new Point(0, 0), flt);			
			return bmdNew;
		}
	}
}
