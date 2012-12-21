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
	
	public class MaskWithSourceAlphaInstruction extends OpInstruction
	{
		public function MaskWithSourceAlphaInstruction()
		{
			super();
		}
		
		public override function Execute(opsmc:OpStateMachine):void {
			var bmdBase:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-2])._bmd;
			var bmdApplied:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-1])._bmd;

			var bmdMasked:BitmapData = VBitmapData.Construct(bmdApplied.width, bmdApplied.height, true, NaN, "mask with source alpha");
			bmdMasked.copyPixels(bmdApplied, bmdApplied.rect, new Point(0, 0), bmdBase);
			ReplaceHeadBitmap(opsmc, bmdMasked);
		}
	}
}