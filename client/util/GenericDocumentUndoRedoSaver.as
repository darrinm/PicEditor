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
	import commands.CommandMgr;
	
	import events.ActiveDocumentEvent;
	import events.GenericDocumentEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.binding.utils.ChangeWatcher;

	public class GenericDocumentUndoRedoSaver extends EventDispatcher implements IUndoRedoSaver
	{
		private var _gend:GenericDocument;
		private var _fCanUndo:Boolean=false;
		private var _fCanRedo:Boolean=false;
		private var _fCanSave:Boolean=false;
		private var _chwDirty:ChangeWatcher;
		
		public function GenericDocumentUndoRedoSaver()
		{
		}

		[Bindable("change")]
		public function set canUndo(f:Boolean): void {
			_fCanUndo = f;
			dispatchEvent(new Event(Event.CHANGE));
		}
		public function get canUndo():Boolean
		{
			return _fCanUndo;
		}
		
		[Bindable("change")]
		public function set canRedo(f:Boolean): void {
			_fCanRedo = f;
			dispatchEvent(new Event(Event.CHANGE));
		}
		public function get canRedo():Boolean
		{
			return _fCanRedo;
		}
		
		[Bindable("change")]
		public function set canSave(f:Boolean): void {
			_fCanSave = f;
			dispatchEvent(new Event(Event.CHANGE));
		}
		public function get canSave():Boolean
		{
			return _fCanSave;
		}
		
		public function Undo(): void
		{
			CommandMgr.Execute("GenericDocument.Undo");
		}
		
		public function Redo(): void
		{
			CommandMgr.Execute("GenericDocument.Redo");
		}
		
		public function Save(): void
		{
			PicnikBase.app.DoSave();
		}
		
		public function Activate():void
		{
			PicnikBase.app.addEventListener(ActiveDocumentEvent.CHANGE, OnActiveDocumentChange);
			var gend:GenericDocument = PicnikBase.app.activeDocument as GenericDocument;
			if (gend != null) {
				MonitorGenericDocument(gend);
			} else {
				canSave = false;
				canUndo = canRedo = false;
			}
		}
		
		public function Deactivate():void
		{
			PicnikBase.app.removeEventListener(ActiveDocumentEvent.CHANGE, OnActiveDocumentChange);
			if (_gend)
				UnmonitorGenericDocument(_gend);
		}
		
		private function OnActiveDocumentChange(evt:ActiveDocumentEvent): void {
//			trace("UndoRedoSave.OnActiveDocumentChange");
			var gendOld:GenericDocument = evt.docOld as GenericDocument;
			var gendNew:GenericDocument = evt.docNew as GenericDocument;
			if (gendOld != null)
				UnmonitorGenericDocument(gendOld);
			if (gendNew != null)
				MonitorGenericDocument(gendNew);
		}
		
		private function MonitorGenericDocument(gend:GenericDocument): void {
//			trace("UndoRedoSave.MonitorGenericDocument");
			Debug.Assert(_gend != gend, "UndoRedoSave.MonitorGenericDocument already monitoring this GenericDocument!");
			_gend = gend;

			_gend.addEventListener(GenericDocumentEvent.UNDO_CHANGE, OnUndoDepthChange);
			_gend.addEventListener(GenericDocumentEvent.REDO_CHANGE, OnRedoDepthChange);
			_chwDirty = ChangeWatcher.watch(_gend, "isDirty", OnIsDirtyChange);
			
			canUndo = _gend.undoDepth > minUndoDepth;
			canRedo = _gend.redoDepth != 0;
			canSave = _gend.isDirty;
		}
		
		private function get minUndoDepth(): Number {
			// UNDONE: Set this to the minimum depth to which a user can undo.
			// For example, for auto-resizing when you open a large document
			// If this is a document setting, it will need to be serialized.
			return 0;
		}
		
		private function UnmonitorGenericDocument(gend:GenericDocument): void {
//			trace("UndoRedoSave.UnmonitorGenericDocument");
			Debug.Assert(gend == _gend, "Uh, we're not monitoring this document?");
			
			_chwDirty.unwatch();
			_chwDirty = null;
			
			_gend.removeEventListener(GenericDocumentEvent.UNDO_CHANGE, OnUndoDepthChange);
			_gend.removeEventListener(GenericDocumentEvent.REDO_CHANGE, OnRedoDepthChange);
			_gend = null;

			canSave = false;
			canUndo = canRedo = false;
		}
		
		private function OnUndoDepthChange(evt:GenericDocumentEvent): void {
			canUndo = evt.obNew > minUndoDepth;
		}
		
		private function OnRedoDepthChange(evt:GenericDocumentEvent): void {
			canRedo = evt.obNew != 0;
		}
		
		private function OnIsDirtyChange(evt:Event): void {
			canSave = _gend.isDirty;
		}
	}
}