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
	public class OpInstructionCache
	{
		// Public for debugging
		public var _abmdrStack:Array = [];
		
		// public for debugging
		public var _obNamed:Object = {};
		
		private var _nPriority:Number;
		private var _opsmc:OpStateMachine;
		public var extraData:Object = null; // Used to keep track of state for ReExecuting instructions, e.g. mask
		
		public function OpInstructionCache(opsmc:OpStateMachine, nPriority:Number)
		{
			_opsmc = opsmc;
			_nPriority = nPriority;
			for each (var bmdr:BitmapReference in _opsmc.bitmapStack)
				_abmdrStack.push(bmdr.copyRef("statemachine stack cache"));
			
			for (var strKey:String in _opsmc.namedBitmaps)
				_obNamed[strKey] = BitmapReference(_opsmc.namedBitmaps[strKey]).copyRef("statemachine name cache: " + strKey);
		}
		
		public function Restore(opsmc:OpStateMachine): void {
			opsmc.ClearNamed();
			opsmc.ClearStack();
			for each (var bmdr:BitmapReference in _abmdrStack)
				_opsmc.bitmapStack.push(bmdr.copyRef("statemachine stack"));
			
			for (var strKey:String in _obNamed)
				_opsmc.namedBitmaps[strKey] = BitmapReference(_obNamed[strKey]).copyRef("statemachine named vars: " + strKey);
			
		}
		
		public function Dispose(): void {
			while (_abmdrStack.length > 0)
				BitmapReference(_abmdrStack.pop()).dispose();
			
			for (var strKey:String in _obNamed) {
				BitmapReference(_obNamed[strKey]).dispose();
			}
			_obNamed = {};
		}
		
		public function get priority(): Number {
			return _nPriority;
		}
	}
}