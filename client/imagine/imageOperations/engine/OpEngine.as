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
	import imagine.imageOperations.engine.instructions.ClearVarInstruction;
	import imagine.imageOperations.engine.instructions.NamedVarInstruction;
	import imagine.imageOperations.engine.instructions.OpInstruction;
	
	import imagine.imageOperations.ImageOperation;
	import imagine.ImageDocument;
	
	import util.BitmapCache;
	import util.IDisposable;
	
	public class OpEngine implements IDisposable
	{
		private var _op:ImageOperation;
		private var _opsmc:OpStateMachine = new OpStateMachine();
		
		private var _nNextOpPos:Number = 0;
		
		public function OpEngine(op:ImageOperation)
		{
			_op = op;
		}
		
		public function Dispose(): void {
			// Called by BitmapCache.clear()
			_opsmc.Clear();
		}

		public function Clear(): void {
			_opsmc.Clear();
			BitmapCache.Clear();
		}
		
		[Bindable]
		public function set stateMachine(opsmc:OpStateMachine): void {
			_opsmc = opsmc;
		}
		public function get stateMachine(): OpStateMachine {
			return _opsmc;
		}
		
		
		private function Compile(): Array {
			// First pass, generate instructions
			// Let the operations do the work - this makes it possible
			// to create complicated/interesting ops.
			var ainst:Array = [];
			_op.Compile(ainst);
			
			// Second pass, add ClearVar to last GetVar (or SetVar) for each var name.
			// This lets us get rid of vars as soon as we can
			var obVarsSeen:Object = {};
			for (var i:Number = ainst.length - 1; i >= 0; i--) {
				var nvinst:NamedVarInstruction = ainst[i] as NamedVarInstruction;
				if (nvinst != null && !(nvinst.name in obVarsSeen)) {
					obVarsSeen[nvinst.name] = true;
					ainst.splice(i+1, 0, new ClearVarInstruction(nvinst.name));
				}
			}
			
			// Debug code
			/*
			trace("Compiled Instructions");
			for each (var inst:OpInstruction in ainst)
				trace(inst);
			*/
			
			return ainst;
		}
		
		public function Do(imgd:ImageDocument, fDoObjects:Boolean, fUseCache:Boolean): BitmapReference {
			Reset(imgd, fDoObjects, fUseCache);
			return _opsmc.run();
		}
		
		// Public for debugging purposes
		public function Reset(imgd:ImageDocument, fDoObjects:Boolean, fUseCache:Boolean): void {
			_opsmc.reset(Compile(), imgd, fDoObjects, fUseCache);
		}
	}
}