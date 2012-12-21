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
	import flash.utils.getQualifiedClassName;
	
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.engine.OpInstructionCache;
	import imagine.imageOperations.engine.OpStateMachine;
	
	public class OpInstruction
	{
		public function OpInstruction()
		{
		}
		
		private var _strKey:String = null;
		private var _nCachePriority:Number = 0;
		private var _opic:OpInstructionCache = null;

		public function set key(str:String): void {
			_strKey = str;
		}
		public function get key(): String {
			return _strKey;
		}
		
		/** ApplyCachedNonImageSideEffects
		 * Re-apply any non-image changes.
		 * This gets called when we are loading a cached state after this operation.
		 *
		 * For example, object operations.
		 *
		 * See: ApplyInstructions.ReapplyCachedNonImageSideEffects
		 */
		public function ReapplyCachedNonImageSideEffects(opsmc:OpStateMachine): void {
			// Override in sub-classes as needed
			// See ApplyInstructions
		}
		
		public function IsEqualTo(opinst:OpInstruction): Boolean {
			return getQualifiedClassName(this) == getQualifiedClassName(opinst) && key == opinst.key;
		}
		
		public function Execute(opsmc:OpStateMachine): void {
			// NOP
			// Override in sub-classes
		}
		
		public function UpdateCacheAfterExecute(opsmc:OpStateMachine): void {
			if (cachePriority > 0 && opsmc.useCache) {
				cacheOb = new OpInstructionCache(opsmc, cachePriority);
				if (this is IReExecutingInstruction)
					cacheOb.extraData = IReExecutingInstruction(this).GetExtraCacheParams()
			} else
				cacheOb = null; // Clear the cache
			
		}
		
		public function Dispose(): void {
			cacheOb = null;
		}
		
		public function SetCachePriorityToAtLeast(n:Number): void {
			if (cachePriority < n)
				cachePriority = n;
		}
		
		public function get cachePriority(): Number {
			return _nCachePriority;
		}
		
		public function set cachePriority(n:Number): void {
			_nCachePriority = n;
		}
		
		public function get cacheOb(): OpInstructionCache {
			return _opic;
		}
		
		public function set cacheOb(opic:OpInstructionCache): void {
			if (_opic == opic)
				return;
			if (_opic != null)
				_opic.Dispose();
			_opic = opic;
		}
		
		/**** Helper Stack Manipulation Functions ****/
		protected function Swap(opsmc:OpStateMachine): void {
			if (opsmc.bitmapStack.length < 2)
				throw new RangeError("swapping with stack which is too small. Stack: " + opsmc.bitmapStack.length);
			var bmdrOldHead:BitmapReference = opsmc.bitmapStack.pop();
			var bmdrNewHead:BitmapReference = opsmc.bitmapStack.pop();
			opsmc.bitmapStack.push(bmdrOldHead);
			opsmc.bitmapStack.push(bmdrNewHead);
		}
		
		protected function ReplaceHead(opsmc:OpStateMachine, bmdr:BitmapReference): void {
			Drop(opsmc);
			opsmc.bitmapStack.push(bmdr);
		}
		
		protected function get instructionName(): String {
			var strClassName:String = getQualifiedClassName(this);
			strClassName = strClassName.replace('::', '.');
			var iLastDot:Number = strClassName.lastIndexOf('.');
			if (iLastDot > -1)
				strClassName = strClassName.substr(iLastDot + 1);
			return strClassName;
		}
		
		public function toString(): String {
			return String(getQualifiedClassName(this).substr(37) + ": " + key).substr(0,150);			
		}
		
		protected function ReplaceHeadBitmap(opsmc:OpStateMachine, bmd:BitmapData): void {
			ReplaceHead(opsmc, BitmapReference.TakeOwnership(instructionName + " statemachine stack", bmd));
		}
		
		protected function PushBitmap(opsmc:OpStateMachine, bmd:BitmapData): void {
			opsmc.bitmapStack.push(BitmapReference.TakeOwnership(instructionName + " statemachine stack", bmd));
		}
		
		protected function Drop(opsmc:OpStateMachine, nDrop:Number=1): void {
			Pop(opsmc, 0, nDrop);
		}
		
		protected function Pop(opsmc:OpStateMachine, nSkipBack:Number=0, nPop:Number=1): void {
			if (opsmc.bitmapStack.length < (nPop + nSkipBack))
				throw new RangeError("popping with stack which is too small. Stack: " + opsmc.bitmapStack.length + ", pop: " + key);
			
			var abmrRemoved:Array = opsmc.bitmapStack.splice(opsmc.bitmapStack.length-nPop-nSkipBack,nPop);
			for each (var bmdr:BitmapReference in abmrRemoved)
				bmdr.dispose();
		}
		
		protected function Dupe(opsmc:OpStateMachine, nSkipBack:Number=0): void {
			if (opsmc.bitmapStack.length <= nSkipBack)
				throw new RangeError("duplicate with stack which is too small. Stack: " + opsmc.bitmapStack.length + ", skip: " + nSkipBack);
			var bmdr:BitmapReference = opsmc.bitmapStack[opsmc.bitmapStack.length-1-nSkipBack];
			opsmc.bitmapStack.push(bmdr.copyRef(instructionName + " statemachine stack"));
		}
	}
}