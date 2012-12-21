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
	import flash.display.Bitmap;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import imagine.ImageDocument;
	
	// A gaussian image operation is a kind of smoothing.
	[RemoteClass]
	public class GaussianImageOperation extends BlendImageOperation {
		
		public function GaussianImageOperation() {
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Gaussian />
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			var gaussian:ConvolutionFilter = new ConvolutionFilter(5,5,
													[ 2,4,5,4,2,
													  4,9,12,9,4,
													  5,12,15,12,5,
													  4,9,12,9,4,
													  2,4,5,4,2],115);
			
			var bmdNew:BitmapData = VBitmapData.Construct(bmdSrc.width, bmdSrc.height, true, 0xff0000ff);
			bmdNew.applyFilter(bmdSrc, bmdNew.rect, new Point(0,0), gaussian);
			return bmdNew;
		}
	}
}
