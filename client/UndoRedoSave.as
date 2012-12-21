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
package {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	
	import mx.controls.Button;
	
	import util.GenericDocumentUndoRedoSaver;
	import util.IUndoRedoSaver;
	
	public class UndoRedoSave extends EventDispatcher {
		private var _btnUndo:Button;
		private var _btnRedo:Button;
		private var _btnSave:Button;
		
		private var _iursr:IUndoRedoSaver;
		
		private var _fActive:Boolean = false;
		
		public function UndoRedoSave(btnUndo:Button, btnRedo:Button, btnSave:Button, iursr:IUndoRedoSaver=null) {
			if (iursr == null) iursr = new GenericDocumentUndoRedoSaver();
			
			_btnUndo = btnUndo;
			_btnRedo = btnRedo;
			_btnSave = btnSave;
			undoRedoSaver = iursr;
			
			_btnUndo.addEventListener(MouseEvent.CLICK, OnUndoClick);
			_btnRedo.addEventListener(MouseEvent.CLICK, OnRedoClick);
			if (_btnSave != null)
				_btnSave.addEventListener(MouseEvent.CLICK, OnSaveClick);

		}
	
		[Bindable]
		public function set undoRedoSaver(iursr:IUndoRedoSaver): void {
			var fWasActive:Boolean = _fActive;
			if (fWasActive) Deactivate();
			_iursr = iursr;
			if (fWasActive) Activate();
		}
		
		public function get undoRedoSaver(): IUndoRedoSaver {
			return _iursr;
		}
		
		private function UpdateButtonEnabledState(evt:Event=null): void {
			_btnUndo.enabled = _iursr == null ? false : _iursr.canUndo;
			_btnRedo.enabled = _iursr == null ? false : _iursr.canRedo;
			if (_btnSave != null) _btnSave.enabled = _iursr == null ? false : _iursr.canSave;
		}
		
		public function Activate(): void {
			if (_fActive) throw new Error("Activating already active undo redo saver");
			_fActive = true;
			
			if (_iursr) {
				_iursr.Activate();
				_iursr.addEventListener(Event.CHANGE, UpdateButtonEnabledState);
			}
			
			UpdateButtonEnabledState();
		}
		
		public function Deactivate(): void {
			if (!_fActive) throw new Error("Deactivating already inactive undo redo saver");
			_fActive = false;

			if (_iursr) {
				_iursr.Deactivate();
				_iursr.removeEventListener(Event.CHANGE, UpdateButtonEnabledState);
			}
		}
		
		private function OnUndoClick(evt:MouseEvent): void {
			if (_iursr) _iursr.Undo();
		}
		
		private function OnRedoClick(evt:MouseEvent): void {
			if (_iursr) _iursr.Redo();
		}
				
		private function OnSaveClick(evt:MouseEvent): void {
			if (_iursr) _iursr.Save();
		}
	}
}
