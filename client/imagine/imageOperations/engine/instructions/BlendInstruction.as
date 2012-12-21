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
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.engine.OpStateMachine;
	
	import util.VBitmapData;
	
	public class BlendInstruction extends OpInstruction
	{
		private var _nAlpha:Number;
		private var _strBlendMode:String;
		private var _matTransform:Matrix=null;
		
		public function BlendInstruction(nAlpha:Number, strBlendMode:String, matTransform:Matrix=null)
		{
			super();
			_nAlpha = nAlpha;
			if (strBlendMode == null)
				strBlendMode = BlendMode.NORMAL;
			_strBlendMode = strBlendMode;
			_matTransform = matTransform;
			key = strBlendMode + ":" + _nAlpha + ":" + _matTransform;
			
			if (_matTransform != null && _strBlendMode == flash.display.BlendMode.ALPHA)
				throw new Error("Not yet implemented: alpha blend mode + transform matrix");
		}
		
		public override function Execute(opsmc:OpStateMachine):void {
			if (_nAlpha == 0) {
				// Normall, this operation takes the first bitmap and blends it with the second, then replaces the first bitmap with the result.
				// If alpha = 0, the result will be the second bitmap. So, we can drop the first bitmap and duplicate the second
				Drop(opsmc);
				Dupe(opsmc);
				return;
			}
			var bmdBase:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-2])._bmd;
			var bmdApplied:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-1])._bmd;
			
			var bmdNew:BitmapData;
			if (_strBlendMode == flash.display.BlendMode.ALPHA && !bmdBase.transparent) {
				bmdNew = VBitmapData.Construct(bmdBase.width, bmdBase.height, true, NaN, "BlendInstruction");
				bmdNew.draw(bmdBase);
			} else {
				bmdNew = bmdBase.clone();
			}
			var ctrns:ColorTransform = null;
			if (_nAlpha < 1) {
				ctrns = new ColorTransform();
				ctrns.alphaMultiplier = _nAlpha;
			}
			// UNDONE: Add support for R,G,B (and combination?) blend modes
			if (_strBlendMode == flash.display.BlendMode.ALPHA) {
				if (_matTransform != null)
					throw new Error("Not yet implemented: alpha blend mode + transform matrix");
				bmdNew.copyChannel(bmdApplied, bmdApplied.rect, new Point(0,0), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
			} else {
				var w:Number = bmdApplied.width;
				bmdNew.draw(bmdApplied, _matTransform, ctrns, _strBlendMode);
			}
			ReplaceHeadBitmap(opsmc, bmdNew);
		}
	}
}