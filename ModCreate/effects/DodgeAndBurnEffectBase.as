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
package effects {
	/*** Old, non-smart method
	 * See version at or prior to svn revision 12616 for CS4 "preserve tones" version
	 * which is much slower but has better results
	 ***/
	
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import imagine.imageOperations.AdjustCurvesImageOperation;
	import imagine.imageOperations.ISimpleOperation;
	import imagine.imageOperations.paintMask.OperationStrokes;
	import imagine.imageOperations.paintMask.PaintMaskController;

	public class DodgeAndBurnEffectBase extends PaintOnEffectBase {
		[Bindable] public var opStrokes:OperationStrokes;
		
		// These are at 50%
        private static var kaaptTargetCurves:Array = [
				/*darken highlights:*/ [{x:0, y:0}, {x:255, y:231}],
				/*darken shadows:*/ [{x:24, y:0}, {x:255, y:255}],
				/*darken midtones:*/ [{x:0, y:0}, {x:83, y:72}, {x:255, y:255}],
				/*lighten highlights:*/ [{x:0, y:0}, {x:230, y:255}],
				/*lighten mids:*/ [{x:0, y:0}, {x:29, y:40}, {x:71, y:85}, {x:255, y:255}],
				/*lighten shadows:*/ [{x:0, y:25}, {x:255, y:255}],
                ];
               
		override protected function SliderToBrushSize(nSliderVal:Number): Number {
			return (Math.pow(1.03, nSliderVal) * 21.9)-20.9;
		}
		
		public function DodgeAndBurnEffectBase(): void {
		}
		
		protected function BrushSizeToSlider(nBrushSize:Number): Number {
			return Math.log((nBrushSize + 20.9)/21.9)/Math.log(1.03);
		}
		
		override protected function InitController(): void {
			opStrokes = new OperationStrokes();
			_mctr = new PaintMaskController(opStrokes);
		}
		
		private var _nArea:Number = 0;
		
		protected function set area(n:Number): void {
			_nArea = n;
			OnOpChange();
		}
		
		private function get currentOp(): ISimpleOperation {
			var sop:AdjustCurvesImageOperation = new AdjustCurvesImageOperation();
			var aptFifty:Array = kaaptTargetCurves[_nArea];
			var apt:Array = [];
			var nStrength:Number = 2; // From 0 to 2
			for each (var pt:Object in aptFifty) {
				apt.push(new Point(pt.x, pt.x + (pt.y - pt.x) * nStrength / 0.5));
			}
			sop.MasterCurve = apt;
			return sop;
		}
		
		public override function OnOverlayPress(evt:MouseEvent): Boolean {
			this._nBrushHardness = 0;
			
			_mctr.additive = true;
			// New way
			brushAlpha = 0.05;
			_mctr.brushAlpha = brushAlpha;
			
			// Old way
			
			_mctr.brushSpacing = 0.25;
			_mctr.extraStrokeParams = {strokeOperation:currentOp};
			return super.OnOverlayPress(evt);
		}
		
		override public function OnOverlayRelease():Boolean {
			brushAlpha = 1; // Reset the brush alpha so our brush size slider looks nice
			return super.OnOverlayRelease();
		}
	}
}
