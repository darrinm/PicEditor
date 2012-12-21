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
	import flash.geom.Point;
	import flash.display.BitmapData;
	
	import imagine.ImageDocument;
	
	/*
		There are two main edge detection image operations. 
			A is a faster, lower quality edge detection
			B is a slower, higher quality edge detection
			
		The two algorithms use the same edge detection algorithm (Sobel),
		but differ in their pre- and post-processing algorithms.		
	*/
	
	[RemoteClass]
	public class EdgeDetectionAImageOperation extends NestedImageOperation {
		
		protected var _nDetail:Number = 0;
		protected var _nContrast:Number = 0;
		protected var _nQuality:Number = 0;
		protected var _opShrink:ResizeImageOperation;
		protected var _opGrow:ResizeImageOperation;

		public function set detail(nDetail:Number): void {
			_nDetail = nDetail;			
			updateChildren();
		}

		public function set contrast(nContrast:Number): void {
			_nContrast = nContrast;			
			updateChildren();
		}
		
		public function set quality(nQuality:Number): void {
			_nQuality = nQuality;			
			updateChildren();
		}

		public function EdgeDetectionAImageOperation() {
			updateChildren();
		}		
		
		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			_opShrink.width = bmdSrc.width / ( 1 + ( (100-_nQuality) / 50 ) );
			_opShrink.height = bmdSrc.width / ( 1 + ( (100-_nQuality) / 50 ) );
			_opGrow.width = bmdSrc.width;
			_opGrow.height = bmdSrc.height;
			return super.ApplyEffect( imgd, bmdSrc, fDoObjects, fUseCache );			
		}		
		
		private function updateChildren(): void {
			_aopChildren.length = 0;

			_opShrink = new ResizeImageOperation;
			_opShrink.Timing = "Edge/Shrink";
			push( _opShrink );
			
			// Also apply a contrast boost to get rid of unnecessary detail
			var opContrast:SimpleColorMatrixImageOperation = new SimpleColorMatrixImageOperation();
			opContrast.Contrast = (100-_nDetail);
			opContrast.Timing = "Edge/Contrast";
			push( opContrast );
			// Remember this version
			push(new imagine.imageOperations.SetVar("edgedetectimgop_orig"));

			{
				// Do edge detection horizontally 			
				var opSobelH:EdgeDetectionSobelImageOperation = new EdgeDetectionSobelImageOperation( "horizontal" )
				opSobelH.Timing = "Edge/SobelH";
				push(opSobelH);

				// Save it
				push(new imagine.imageOperations.SetVar("horizontal"));
			}			

			{
				// get the original back again
				push(new GetVarImageOperation("edgedetectimgop_orig"));
				
				// Do edge detection vertically 			
				var opSobelV:EdgeDetectionSobelImageOperation = new EdgeDetectionSobelImageOperation( "vertical" )
				opSobelV.Timing = "Edge/SobelV";
				push(opSobelV);
			}			
			
			// combine the horizontal and vertical
			var opMultiply:GetVarImageOperation = new GetVarImageOperation( "horizontal", "darken" );
			opMultiply.Timing = "Edge/Combine";
			push( opMultiply );			
			
			var opBlur:BlurImageOperation = new BlurImageOperation( NaN, 2, 2, 2 );
			opBlur.Timing = "Edge/Blur";
			push( opBlur );
			
			// give it an A-shaped curve to make the lines black
			var nAdjust:Number = _nContrast;
			var opCurveV:AdjustCurvesImageOperation = new AdjustCurvesImageOperation();
			opCurveV.MasterCurve = [{x:0, y:0},
									{x:1+nAdjust, y:1},
									{x:126-nAdjust/5, y:254},
									{x:127, y:255},
									{x:128+nAdjust/5, y:254},
									{x:254-nAdjust, y:1},
									{x:255, y:0}];			
			opCurveV.Timing = "Edge/CurveV";
			push( opCurveV );
			
			// make it b&w
			var opBW:BWImageOperation = new BWImageOperation;
			opBW.Timing = "Edge/BW";
			push( opBW );		
		
			// grow it
			_opGrow = new ResizeImageOperation;
			_opGrow.smoothing = true;
			_opGrow.Timing = "Edge/Grow";
			push( _opGrow );		
		}
		
	}
}
