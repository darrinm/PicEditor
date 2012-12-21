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
package util
{
	import flash.events.IEventDispatcher;
	
	/** IUndoRedoSaver
	 * This interface represents something which can be undone/redone and maybe saved.
	 * This is the glue between the UndoRedoSave object (a group of buttons)
	 *  and the some item with undo support.
	 */
	public interface IUndoRedoSaver extends IEventDispatcher
	{
		function get canUndo(): Boolean; // Bindable
		function get canRedo(): Boolean; // Bindable
		function get canSave(): Boolean; // Bindable
		
		function Undo(): void;
		function Redo(): void;
		function Save(): void;
		
		function Activate(): void;
		function Deactivate(): void;
	}
}