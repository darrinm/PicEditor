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
	import imagine.imageOperations.engine.OpStateMachine;
	
	public class ApplyObjectInstruction extends ApplyInstruction
	{
		public function ApplyObjectInstruction(op:ImageOperation, strKey:String)
		{
			super(op, strKey);
		}
		
		protected override function DoApply(opsmc:OpStateMachine, bmdSource:BitmapData): BitmapData {
			_op.Apply(opsmc.imageDocument, bmdSource, opsmc.doObjects, opsmc.useCache);
			return null;
		}
	}
}