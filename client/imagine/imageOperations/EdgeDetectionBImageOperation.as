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
	import imagine.imageOperations.NestedImageOperation;
	import util.VBitmapData;
	import flash.geom.Point;
	import flash.display.BitmapData;
	
	/*
		There are two main edge detection image operations. 
			A is a faster, lower quality edge detection
			B is a slower, higher quality edge detection
			
		The two algorithms use the same edge detection algorithm (Sobel),
		but differ in their pre- and post-processing algorithms.		
	*/
	[RemoteClass]
	public class EdgeDetectionBImageOperation extends NestedImageOperation {
		
		protected var _nDetail:Number = 0;

		public function set detail(nDetail:Number): void {
			_nDetail = nDetail;			
			updateChildren();
		}

		public function EdgeDetectionBImageOperation() {
			updateChildren();
		}
		
		private function updateChildren(): void {
			_aopChildren.length = 0;
			
			// Apply a smoothing operation to get rid of unnecessary detail
			// var opGaussian:GaussianImageOperation = new GaussianImageOperation();
			// Use a 2 pixel blur instead. Similar (not quite as nice) and many times faster
			var opGaussian:BlurImageOperation = new BlurImageOperation(NaN,2,2,2);
			
			push( opGaussian );
			
			// Also apply a contrast boost to get rid of unnecessary detail
			var opContrast:SimpleColorMatrixImageOperation = new SimpleColorMatrixImageOperation();
			opContrast.Contrast = (100-_nDetail);
			push( opContrast );
			// Remember this version
			push(new imagine.imageOperations.SetVar("edgedetectimgop_orig"));

			{
				// Do edge detection horizontally 			
				push(new EdgeDetectionSobelImageOperation( "horizontal" ));
				
				// give it an A-shaped curve to make the lines black
				var opCurveH:AdjustCurvesImageOperation = new AdjustCurvesImageOperation();
				opCurveH.MasterCurve = [{x:0, y:0}, {x:128, y:255}, {x:255, y:0}];			
				push( opCurveH );
				
				// Save it
				push(new imagine.imageOperations.SetVar("horizontal"));
			}			

			{
				// get the original back again
				push(new GetVarImageOperation("edgedetectimgop_orig"));
				
				// Do edge detection vertically 			
				push(new EdgeDetectionSobelImageOperation( "vertical" ));
				
				// give it an A-shaped curve to make the lines black
				var opCurveV:AdjustCurvesImageOperation = new AdjustCurvesImageOperation();
				opCurveV.MasterCurve = [{x:0, y:0}, {x:128, y:255}, {x:255, y:0}];			
				push( opCurveV );
				
			}			
			
			// combine the horizontal and vertical
			push( new GetVarImageOperation( "horizontal", "multiply" ) );			
		}
		
	}
}
