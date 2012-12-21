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
	import flash.geom.Rectangle;
	
	import imagine.imageOperations.ImageMask;
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.engine.OpStateMachine;
	import imagine.serialization.SerializationUtil;
	
	public class PartialMaskInstruction extends OpInstruction
	{
		private var _msk:ImageMask;
		
		public function PartialMaskInstruction(msk:ImageMask)
		{
			super();
			_msk = msk;
			key = SerializationUtil.WriteToString(_msk);
		}

		// Copy pixels from bmdSrc to bmdDst.
		// Default alpha is 1 (bmdDst overwritten with bmdSrc)
		// Within rcAlpha, use the alpha from bmdAlpha (offset by rcAlpha.topLeft)
		// In other words, within rcAlpha:
		//    alpha = bmdAlpha[x-rcAlpha.x, y-rcAlpha.y]
		// Outside of rcAlpha: alpha = 1
		// bmdDst[x,y] = bmdSrc[x,y] * alpha + bmdDst[x,y] * (1-alpha)
		// This is useful because alpha mask copies are very slow. We can minimize the region
		// needing an alpha mask.
		// If rcAlpha is null, use bmdDst.rect
		// Assume bmdDst.rect == bmdSrc.rect
		private function FastMaskedCopy(bmdDst:BitmapData, bmdSrc:BitmapData, bmdAlpha:BitmapData, rcAlpha:Rectangle=null): void {
			if (rcAlpha && !rcAlpha.isEmpty()) {
				rcAlpha = new Rectangle(Math.round(rcAlpha.x),
					Math.round(rcAlpha.y),
					Math.round(rcAlpha.width),
					Math.round(rcAlpha.height));
				// Alpha blend applies to sub-section of image
				// This is a very slow operation, so only do it within the area where it is needed.
				
				// CONSIDER: some day we'll want to support updating from an array of alpha rectangles
				bmdDst.copyPixels(bmdSrc, rcAlpha, rcAlpha.topLeft, bmdAlpha, new Point(0,0), true);
				
				if (_msk.nOuterAlpha == 1)
					return;
				// Now copy pixels from the outlying rectangles.
				var rcCopy:Rectangle;
				var cxy:Number;
				// Top
				cxy = rcAlpha.y;
				if (cxy > 0) {
					rcCopy = new Rectangle(0, 0, bmdSrc.width, cxy);
					bmdDst.copyPixels(bmdSrc, rcCopy, rcCopy.topLeft);
				}
				// Bottom
				cxy = bmdSrc.height - (rcAlpha.y + rcAlpha.height);
				if (cxy > 0) {
					rcCopy = new Rectangle(0, bmdSrc.height - cxy, bmdSrc.width, cxy);
					bmdDst.copyPixels(bmdSrc, rcCopy, rcCopy.topLeft);
				}
				// Left
				cxy = rcAlpha.x;
				if (cxy > 0) {
					rcCopy = new Rectangle(0, rcAlpha.y, cxy, rcAlpha.height);
					bmdDst.copyPixels(bmdSrc, rcCopy, rcCopy.topLeft);
				}
				// Right
				cxy = bmdSrc.width - (rcAlpha.x + rcAlpha.width);
				if (cxy > 0) {
					rcCopy = new Rectangle(bmdSrc.width - cxy, rcAlpha.y, cxy, rcAlpha.height);
					bmdDst.copyPixels(bmdSrc, rcCopy, rcCopy.topLeft);
				}
			} else { // Alpha blend applies to entire area
				// Copy from the source to the dest, but only within our target bounds
				bmdDst.copyPixels(bmdSrc, _msk.Bounds, _msk.destPoint, bmdAlpha, new Point(0,0), true);
			}
		}
				
		public override function Execute(opsmc:OpStateMachine):void {
			var bmdBase:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-2])._bmd;
			var bmdApplied:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-1])._bmd;
			var bmdMasked:BitmapData;
			
			if (((_msk.width != bmdBase.width) || (_msk.height != bmdBase.height)) || _msk.Mask(bmdBase)) {
				if (_msk.inverted) {
					// Make a copy to not disturb the cached bitmap of the applied effect
					bmdMasked = bmdApplied.clone();
					FastMaskedCopy(bmdMasked, bmdBase, _msk.Mask(bmdBase), _msk.AlphaBounds);
				} else {
					// Make a copy to not hose the original
					bmdMasked = bmdBase.clone(); // use the full size original
					FastMaskedCopy(bmdMasked, bmdApplied, _msk.Mask(bmdBase), _msk.AlphaBounds);
				}
				ReplaceHeadBitmap(opsmc, bmdMasked);
				
			// The mask may be empty and inverted in which case we can ignore it and
			// pass on the effect. But if not inverted we want to pass on the original.
			} else {
				if (!_msk.inverted) {
					Drop(opsmc);
					Dupe(opsmc);
				}
			}
			_msk.DoneDrawing();
		}

	}
}