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
	import flash.geom.Matrix;
	
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.engine.OpStateMachine;
	
	import util.VBitmapData;
	
	public class ResizeInstruction extends OpInstruction
	{
		private var _nSkipBackForSize:Number;
		private var _nScale:Number;
		
		public function ResizeInstruction(nSkipBackForSize:Number=1, nScale:Number=0)
		{
			super();
			key = nSkipBackForSize + ":" + nScale;
			_nSkipBackForSize = nSkipBackForSize;
			_nScale = nScale;
		}

		public override function Execute(opsmc:OpStateMachine):void {
			var bmdBase:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-(1 + _nSkipBackForSize)])._bmd;
			var bmdResize:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-1])._bmd;
			var xScale:Number;
			var yScale:Number;
			if (_nScale == 0) {
				xScale = bmdBase.width / bmdResize.width;
				yScale = bmdBase.height / bmdResize.height;
			} else {
				xScale = _nScale;
				yScale = _nScale;
			}

			var mat:Matrix = new Matrix();
			mat.scale(xScale, yScale);

			var bmdNew:BitmapData = VBitmapData.Construct(bmdBase.width, bmdBase.height, false);
			bmdNew.draw(bmdResize, mat);

			ReplaceHeadBitmap(opsmc, bmdNew);
		}
	}
}