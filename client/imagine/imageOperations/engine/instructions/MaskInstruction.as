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
	import flash.geom.Rectangle;
	
	import imagine.imageOperations.ImageMask;
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.engine.OpStateMachine;
	
	public class MaskInstruction extends OpInstruction implements IReExecutingInstruction
	{
		private var _msk:ImageMask;
		
		public function MaskInstruction(msk:ImageMask, nCachePriority:Number=100)
		{
			super();
			SetCachePriorityToAtLeast(nCachePriority);
			_msk = msk;
			key = _msk.Bounds + ":" + _msk.nOuterAlpha + ":" + _msk.inverted;
		}
		
		public override function Execute(opsmc:OpStateMachine):void {
			DoMask(opsmc, false);
		}
		
		public function ReExecute(opsmc:OpStateMachine, obExtraCacheParams:Object): void {
			DoMask(opsmc, true, obExtraCacheParams);
		}
		
		public function GetExtraCacheParams(): Object {
			return _msk.GetKeyForCurrentState();
		}

		private function DoMask(opsmc:OpStateMachine, fFromCache:Boolean, obExtraCacheParams:Object=null): void {
			var bmdrMasked:BitmapReference;
			if (fFromCache)
				bmdrMasked = opsmc.bitmapStack.pop();

			var bmdrBase:BitmapReference = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-2]);
			var bmdrApplied:BitmapReference = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-1]);
			
			var bmdMasked:BitmapData;
			
			var bmdrDrawOver:BitmapReference = _msk.inverted ? bmdrBase : bmdrApplied;
			var bmdrDrawUnder:BitmapReference = _msk.inverted ? bmdrApplied : bmdrBase;
			var rcDirty:Rectangle;
			var rcTarget:Rectangle; // Dirty rect in local coords
			
			if (!fFromCache) {
				// Use the entire bounds
				bmdrMasked = bmdrDrawUnder.deepCopy("paint mask composite");
				rcDirty = _msk.GetChangesFromState(null); // Mask coordinates
				rcTarget = _msk.Bounds;
			} else {
				// Update the dirty region using bmdDrawUnder
				rcDirty = _msk.GetChangesFromState(obExtraCacheParams);
				
				// If width/height == 0 we're done
				if (rcDirty.width > 0 && rcDirty.height > 0) {
					rcTarget = rcDirty.clone();
					rcTarget.x += _msk.Bounds.x;
					rcTarget.y += _msk.Bounds.y;
					bmdrMasked._bmd.copyPixels(bmdrDrawUnder._bmd, rcTarget, rcTarget.topLeft);
				}
			}
			if (rcDirty.width > 0 && rcDirty.height > 0) {
				// At this point, bmdMasked is our composite with
				// our dirty rect filled in with bmdDrawUnder
				// Draw into this with bmdDrawOver using our mask
				// Note that we have bmdBounds.topLeft as an offset
				// and rcDirty as a dirty rect relative to the mask
				bmdrMasked._bmd.copyPixels(bmdrDrawOver._bmd, rcTarget, rcTarget.topLeft, _msk.Mask(bmdrBase._bmd), rcTarget.topLeft, true);
				_msk.DoneDrawing();
			}
				
			// All done. Push the composite onto (or back onto) the stack
			opsmc.bitmapStack.push(bmdrMasked);
		}
	}
}