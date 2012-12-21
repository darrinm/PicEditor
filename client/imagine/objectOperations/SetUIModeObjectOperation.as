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
// This is a weird operation. It's a UI operation masquerading as an ObjectOperation so it can
// be put on the undo stack and change the UI to the appropriate mode as UndoTransactions are
// undone/redone. We're careful to not perform UI operations in the FlashRenderer.
//
// ObjectOperations are skipped when documents are loaded and played back which is a good thing
// for this UI operation because we don't want mode switching to happen then.

package imagine.objectOperations {
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	
	import mx.core.Application;
	
	[RemoteClass]
	public class SetUIModeObjectOperation extends ObjectOperation {
		private var _strMode:String;
		private var _strUndoMode:String = null;
		private var _strActivateTab:String;
		private var _strUndoActivateTab:String;
		private var _strActivateSubTab:String;
		private var _strUndoActivateSubTab:String;
		
		// ObjectOperation constructors are called with no arguments during Deserialization
		public function SetUIModeObjectOperation(strMode:String=null, strActivateTab:String=null, strActivateSubTab:String=null) {
			_strMode = strMode;
			_strActivateTab = strActivateTab;
			_strActivateSubTab = strActivateSubTab;
		}

		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			
			var obVals:Object = {};
			
			obVals.mode = _strMode;
			obVals.undoMode = _strUndoMode;
			obVals.activateTab = _strActivateTab;
			obVals.undoActivateTab = _strUndoActivateTab;
			
			obVals.activateSubTab = _strActivateSubTab;
			obVals.undoActivateSubTab = _strUndoActivateSubTab;
			
			output.writeObject(obVals);
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			var obVals:Object = input.readObject();
			
			_strMode = obVals.mode;
			_strUndoMode = obVals.undoMode;
			_strActivateTab = obVals.activateTab;
			_strUndoActivateTab = obVals.undoActivateTab;
			
			_strActivateSubTab = obVals.activateSubTab;
			_strUndoActivateSubTab = obVals.undoActivateSubTab;
		}
		
		override public function Deserialize(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@mode, "SetUIModeObjectOperation mode argument missing");
			_strMode = String(xmlOp.@mode);
			_strUndoMode = String(xmlOp.@undoMode);
			_strActivateTab = String(xmlOp.@activateTab);
			_strUndoActivateTab = String(xmlOp.@undoActivateTab);
			
			_strActivateSubTab = xmlOp.hasOwnProperty('@activateSubTab') ? String(xmlOp.@activateSubTab) : null;
			_strUndoActivateSubTab = xmlOp.hasOwnProperty('@undoActivateSubTab') ? String(xmlOp.@undoActivateSubTab) : null;
			return true;
		}
		
		override public function Serialize(): XML {
			var xml:XML = <SetUIMode mode={_strMode} activateTab={_strActivateTab} undoMode={_strUndoMode} undoActivateTab={_strUndoActivateTab}/>;
			if (_strActivateSubTab != null)
				xml.@activateSubTab = _strActivateSubTab;
			if (_strUndoActivateSubTab != null)
				xml.@undoActivateSubTab = _strUndoActivateSubTab;
			return xml;
		}
		
		override public function Do(imgd:ImageDocument, fDoObjects:Boolean=true, fUseCache:Boolean=false): Boolean {
			if (fDoObjects) {
				// This keeps us from messing with the FlashRenderer or ClientTestRunner's UI
				if (Application.application.uimode) {
					_strUndoMode = Application.application.uimode;
					_strUndoActivateTab = Application.application.activeTabId;
					Application.application.uimode = _strMode;
					
					if (_strActivateSubTab != null) {
						_strUndoActivateSubTab = Application.application.activeSubTabId;
						Application.application.NavigateTo(_strActivateTab, _strActivateSubTab);
					} else {
						if (_strActivateTab)
							Application.application.activeTabId = _strActivateTab;
					}
				}
			}
				
			// HACK: Lay the foundation for before/after viewing
			if (imgd.background != null)
				imgd.SetOriginalToBackgroundClone();
			
			return super.Do(imgd, fDoObjects, fUseCache);
		}
		
		// Restore the saved properties
		override public function Undo(imgd:ImageDocument): Boolean {
			// This keeps us from messing with the FlashRenderer or ClientTestRunner's UI
			if (Application.application.uimode) {
				Application.application.uimode = _strUndoMode;
				
				if (_strUndoActivateTab)
					Application.application.activeTabId = _strUndoActivateTab;
			}
			return true;
		}
	}
}
