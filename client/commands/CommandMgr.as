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
package commands {
	public class CommandMgr {
		private static var s_dctCommands:Object = {};
		
		public static function Execute(strCommand:String): void {
			// UNDONE: dispatch an Event.COMPLETE when Command completes
			var cmd:Command = s_dctCommands[strCommand];
			cmd.Execute();
		}
		
		public static function Register(cmd:Command): void {
			// No two commands should share the same name
			Debug.Assert(!(cmd.name in s_dctCommands), "duplicate Command name!");
			
			s_dctCommands[cmd.name] = cmd;
		}
		
		public static function Unregister(cmd:Command): void {
			delete s_dctCommands[cmd.name];
		}
		
		public static function AddEventListener(strCommand:String, strEvent:String, fnListener:Function): void {
			var cmd:Command = s_dctCommands[strCommand];
			cmd.addEventListener(strEvent, fnListener);
		}
		
		public static function RemoveEventListener(strCommand:String, strEvent:String, fnListener:Function): void {
			var cmd:Command = s_dctCommands[strCommand];
			cmd.removeEventListener(strEvent, fnListener);
		}
	}
}
