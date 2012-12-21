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
package imagine.imageOperations.engine.instructions
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.engine.OpStateMachine;
	
	import util.VBitmapData;
	
	public class CreateBitmapInstruction extends OpInstruction
	{
		private var _fTransparent:Boolean;
		private var _clrFill:Number;
		private var _nSkipBackForOriginal:Number;
		
		public function CreateBitmapInstruction(fTranparent:Boolean, clrFill:Number, nSkipBackForOriginal:Number=0)
		{
			super();
			_fTransparent = fTranparent;
			_clrFill = clrFill;
			_nSkipBackForOriginal = nSkipBackForOriginal;
			
			key = clrFill + ":" + _fTransparent + ":" + _nSkipBackForOriginal;	
		}
		
		protected function CalculateSize(ptOrigSize:Point): Point {
			return ptOrigSize; // override in sub-classes as needed. See PerlinSpotsNoiseInstruction
		}
		
		public override function Execute(opsmc:OpStateMachine):void {
			var bmdOrig:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-(1+_nSkipBackForOriginal)])._bmd;
			var ptSize:Point = CalculateSize(new Point(bmdOrig.width, bmdOrig.height));
			
			var bmdNew:BitmapData = VBitmapData.Construct(ptSize.x, ptSize.y, _fTransparent, _clrFill);
			PushBitmap(opsmc, bmdNew);
		}
	}
}