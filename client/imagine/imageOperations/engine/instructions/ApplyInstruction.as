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
	
	import imagine.imageOperations.BlendImageOperation;
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.engine.OpStateMachine;
	
	import imagine.imageOperations.ImageOperation;
	
	import imagine.ImageUndoTransaction;
	
	import util.VBitmapData;
	
	public class ApplyInstruction extends OpInstruction
	{
		protected var _op:ImageOperation;
		private var _aopCachedNonImageSideEffectOps:Array = null;
		
		public function ApplyInstruction(op:ImageOperation, strKey:String)
		{
			super();
			_op = op;
			key = strKey;
		}
		
		override public function ReapplyCachedNonImageSideEffects(opsmc:OpStateMachine): void {
			if (_aopCachedNonImageSideEffectOps == null || _aopCachedNonImageSideEffectOps.length == 0)
				return; // Nothing to do

		
			for each (var op:ImageOperation in _aopCachedNonImageSideEffectOps) {
				op.Do(opsmc.imageDocument, true, opsmc.useCache);
			}
		}

		private function GetImageOpName():String {
			var strClassName:String = getQualifiedClassName(_op);
			if (strClassName.indexOf('.') > -1) {
				strClassName = strClassName.replace('::', '.');
			} else {
				strClassName = strClassName.substr(17); // Lop off "imageOperations."
			}
			return strClassName;
		}
		
		protected function DoApply(opsmc:OpStateMachine, bmdSource:BitmapData): BitmapData {
			var fDoObjects:Boolean = opsmc.doObjects;
			if (_op is BlendImageOperation && BlendImageOperation(_op).ignoreObjects)
				fDoObjects = false;
			return _op.ApplyEffect(opsmc.imageDocument, bmdSource, fDoObjects, opsmc.useCache);
		}
		
		override public function Execute(opsmc:OpStateMachine): void {
			var bmdrSource:BitmapReference = opsmc.bitmapStack[opsmc.bitmapStack.length-1];
			var bmdSource:BitmapData = bmdrSource._bmd;
			
			_aopCachedNonImageSideEffectOps = null;
			var ut:ImageUndoTransaction = opsmc.imageDocument.pendingUndoTransaction;
			var iopBeforeApply:int = 0;
			if (ut)
				iopBeforeApply = ut.aop.length;
			
			var bmdOut:BitmapData = DoApply(opsmc, bmdSource);
			
			if (ut)
				_aopCachedNonImageSideEffectOps = ut.aop.slice(iopBeforeApply);
				
			if (bmdOut == null) {
				// Object only operation. Leave stack as is.
			} else if (bmdOut == bmdSource) {
				opsmc.bitmapStack.push(bmdrSource.copyRef(instructionName + " statemachine stack"));
			} else {
				opsmc.bitmapStack.push(BitmapReference.TakeOwnership(instructionName + " statemachine stack", bmdOut));
				if (bmdOut is VBitmapData && VBitmapData(bmdOut)._strDebugName == "untitled")
					VBitmapData(bmdOut)._strDebugName = "Applied " + GetImageOpName();
			}
		}
	}
}