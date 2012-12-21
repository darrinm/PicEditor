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
package imagine.imageOperations.engine
{
	import flash.display.BitmapData;
	
	import imagine.imageOperations.engine.instructions.IReExecutingInstruction;
	import imagine.imageOperations.engine.instructions.OpInstruction;
	
	import imagine.ImageDocument;
	
	import util.VBitmapData;
	
	/** OpStateMachine
	 * This holds the state of an operation:
	 *   - the current instruction pointer
	 *   - the stack
	 *   - the instruction list (including attached cache)
	 *   - the setvar dictionary
	 * It knows how to execute the next instruction and when it is done.
	 * It also knows which ImageDocument and original bitmap it is using.
	 */
	public class OpStateMachine
	{
		private var _fUseCache:Boolean = true;
		private var _fDoObjects:Boolean = true;
		private var _imgd:ImageDocument = null;
		private var _bmdOriginal:BitmapData;
		private var _nNextInstruction:Number = 0;
		private var _fReExecuting:Boolean = false;

		[Bindable] public var instructions:Array = [];
		[Bindable] public var bitmapStack:Array = [];
		[Bindable] public var namedBitmaps:Object = {};
		
		private const knMaxBitmapMemory:Number = 600 * 1024 * 1024; // 600 MB
		
		public function OpStateMachine()
		{
		}
		
		public function get nextInstructionIndex(): Number {
			return _nNextInstruction;
		}
		
		private function TrimCache(): void {
			// Keep track of total memory useage. Clear caches if we get too high
			if (VBitmapData.s_nEstimatedBytesUndisposed > knMaxBitmapMemory) {
				// First, collect instructions with caches
				var ainst:Array = [];
				var opinst:OpInstruction;
				for each (opinst in instructions)
					if (opinst.cacheOb != null)
						ainst.push(opinst);

				ainst.sortOn("cachePriority", Array.NUMERIC | Array.DESCENDING);
				// Lowest priority at the bottom.
						
				while (ainst.length > 0 && VBitmapData.s_nEstimatedBytesUndisposed > knMaxBitmapMemory)
					OpInstruction(ainst.pop()).cacheOb = null;
			}
		}
		
		public function BmdPeek(): BitmapData {
			return BitmapReference(bitmapStack[bitmapStack.length-1])._bmd;
		}
		
		public function Clear(): void {
			ClearStack();
			ClearNamed();
			RemoveInstructionsFrom(0);
		}
		
		public function reset(ainst:Array, imgd:ImageDocument, fDoObjects:Boolean, fUseCache:Boolean): void {
			ClearStack();
			ClearNamed();
			imageDocument = imgd;
			doObjects = fDoObjects;
			useCache = fUseCache;
			for (var i:Number = 0; i < ainst.length; i++) {
				var opinstNew:OpInstruction = ainst[i];
				var opinstCurrent:OpInstruction = (i >= instructions.length) ? null : instructions[i];
				if (opinstNew.IsEqualTo(opinstCurrent)) {
					// Leave it be
					opinstNew.Dispose(); // Get rid of the old one.
				} else {
					RemoveInstructionsFrom(i);
					instructions.push(opinstNew);
				}
			}
			RemoveInstructionsFrom(ainst.length); // Remove any extra instructions at the end.
		}
		
		public function ClearStack(): void {
			while (bitmapStack.length > 0) {
				var bmdr:BitmapReference = bitmapStack.pop();
				bmdr.dispose();
			}
		}
		
		public function ClearNamed(): void {
			for (var strKey:String in namedBitmaps) {
				var bmdr:BitmapReference = namedBitmaps[strKey];
				bmdr.dispose();
				delete namedBitmaps[strKey];
			}
		}
		
		private function RemoveInstructionsFrom(i:Number): void {
			while (instructions.length > i) {
				var opinst:OpInstruction = instructions.pop();
				opinst.Dispose();
			}
		}
		
		public function run(): BitmapReference {
			start();
			while (hasInstructionsLeft) {
				runNext();
			}
			return GetResult();
		}
		
		public function get hasInstructionsLeft(): Boolean {
			return _nNextInstruction < instructions.length;
		}
		
		public function GetResult(): BitmapReference {
			if (bitmapStack.length > 1)
				throw new Error("Too many bitamps left on stack");
			else if (bitmapStack.length < 1)
				throw new Error("No bitmaps left on stack");
			for (var strKey:String in namedBitmaps)
				throw new Error("Undisposed named bitmap: " + strKey);
			
			var bmdr:BitmapReference = bitmapStack.pop();
			if (bmdr == null)
				throw new Error("bitmap ref result is null");
				
			bmdr.validate("Invalid result");
			return BitmapReference.Repurpose(bmdr, "State Machine Result");
		}
		
		public function runNext(): void {
			var opinst:OpInstruction = instructions[_nNextInstruction];
			_nNextInstruction++;
			if (_fReExecuting)
				IReExecutingInstruction(opinst).ReExecute(this, opinst.cacheOb.extraData);
			else
				opinst.Execute(this);
			_fReExecuting = false;
			opinst.UpdateCacheAfterExecute(this);
			TrimCache();
		}
		
		private function GetLastCachePos(): Number {
			for (var i:Number = instructions.length-1; i >= 0; i--) {
				// If we find a cache entry at position i, it means we don't need to run that instruction
				var opinst:OpInstruction = instructions[i];
				if (opinst.cacheOb != null) {
					// Found one.
					return i;
				}
			}
			return -1;
		}
		
		public function start(): void {
			// First, set up our stack
			ClearStack();
			ClearNamed();
			// Start with our last cached entry
			var iLastCachePos:Number = GetLastCachePos();
			if (iLastCachePos == -1) {
				// No cache
				bitmapStack.push(BitmapReference.NewExternalReference("statemachine original", original));
				_nNextInstruction = 0;
			} else {
				// Found a cache.
				// Apply the cache to restore our state, then start with the next instruction
				var opinst:OpInstruction = OpInstruction(instructions[iLastCachePos]);
				opinst.cacheOb.Restore(this);
				_nNextInstruction = iLastCachePos;
				
				// Play back cached non-image side effects
				for (var i:Number = 0; i <= iLastCachePos; i++)
					OpInstruction(instructions[i]).ReapplyCachedNonImageSideEffects(this);
				
				if (!(opinst is IReExecutingInstruction))
					_nNextInstruction += 1;
				else
					_fReExecuting = true;
			}
		}
		
		public function set imageDocument(imgd:ImageDocument): void {
			if (_imgd != imgd) {
				_imgd = imgd;
			}
			original = imgd.background;
		}
		
		public function get imageDocument(): ImageDocument {
			return _imgd;
		}
		
		public function set original(bmd:BitmapData): void {
			if (_bmdOriginal == bmd)
				return;
			_bmdOriginal = bmd;
			ClearCache();
		} 
		
		public function get original():BitmapData {
			return _bmdOriginal;
		}
		
		public function set useCache(f:Boolean): void {
			if (_fUseCache == f)
				return;
			_fUseCache = f;
			if (!_fUseCache)
				ClearCache();
		}
		public function get useCache(): Boolean {
			return _fUseCache;
		}
		
		public function set doObjects(f:Boolean): void {
			_fDoObjects = f;
		}  
		public function get doObjects(): Boolean {
			return _fDoObjects;
		}
		
		private function ClearCache(): void {
			for each (var opinst:OpInstruction in instructions)
				opinst.cacheOb = null;
		}
	}
}