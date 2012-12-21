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
	
	import imagine.imageOperations.ImageOperation;
	import imagine.imageOperations.IReExecutingOperation;
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.engine.OpStateMachine;
	
	public class ApplyReExecutingInstruction extends ApplyInstruction implements IReExecutingInstruction
	{
		private var _reop:IReExecutingOperation;
		
		public function ApplyReExecutingInstruction(reop:IReExecutingOperation, strKey:String)
		{
			_reop = reop;
			super(ImageOperation(reop), strKey);
			cachePriority = 1; // We want to use the cache so we can take advantage of re-apply
		}

		// The previous results were cached. Re-load them from the cache, then call ReApplyEffect
		public function ReExecute(opsmc:OpStateMachine, obExtraCacheParams:Object): void {
			var bmdSource:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-2])._bmd;;
			var bmdPrevApplied:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-1])._bmd;
			
			_reop.ReApplyEffect(opsmc.imageDocument, bmdSource, bmdPrevApplied, obExtraCacheParams);
		}

		public function GetExtraCacheParams(): Object {
			return _reop.GetPrevApplyParams();
		}
	}
}