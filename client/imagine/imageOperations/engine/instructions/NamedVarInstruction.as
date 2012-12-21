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
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.engine.OpStateMachine;
	
	public class NamedVarInstruction extends OpInstruction
	{
		private var _strName:String;
		
		public function NamedVarInstruction(strName:String)
		{
			super();
			_strName = strName;
			key = _strName;
		}
		
		protected function get nameKey(): String {
			return "SV:" + name;
		}
		
		public function get name(): String {
			return _strName;
		}
		
		protected function ClearVar(opsmc:OpStateMachine): void {
			if (nameKey in opsmc.namedBitmaps) {
				var bmdr:BitmapReference = opsmc.namedBitmaps[nameKey];
				delete opsmc.namedBitmaps[nameKey];
				bmdr.dispose();
			}
		}
	}
}