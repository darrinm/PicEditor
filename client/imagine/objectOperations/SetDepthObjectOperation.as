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
package imagine.objectOperations {
	import flash.display.DisplayObject;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	
	[RemoteClass]
	public class SetDepthObjectOperation extends ObjectOperation {
		private var _id:String;
		private var _nDepthChange:Number;
		private var _nUndoDepth:Number = -1;
		
		// Positive means bring forward, negative send back.
		public function SetDepthObjectOperation(id:String=null, nDepthChange:Number=0) {
			// ObjectOperation constructors are called with no arguments during Deserialization
			if (!id)
				return;
			_id = id;
			_nDepthChange = nDepthChange;
			_nUndoDepth = -1; // No value
		}

		override public function Deserialize(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@id, "SetDepthObjectOperation id argument missing");
			_id = String(xmlOp.@id);
			Debug.Assert(xmlOp.@depthChange, "SetDepthObjectOperation depthChange argument missing");
			_nDepthChange = Number(xmlOp.@depthChange);
			_nUndoDepth = Number(xmlOp.@undoDepth);
			return true;
		}
		
		override public function Serialize(): XML {
			return <SetDepth id={_id} depthChange={_nDepthChange} undoDepth={_nUndoDepth}/>;
		}
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			
			var obVals:Object = {};
			obVals.id = _id;
			obVals.depthChange = _nDepthChange;
			obVals.undoDepth = _nUndoDepth;
			
			output.writeObject(obVals);
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			var obVals:Object = input.readObject();
			_id = obVals.id;
			_nDepthChange = obVals.depthChange;
			_nUndoDepth = obVals.undoDepth;
		}
		
		override public function Do(imgd:ImageDocument, fDoObjects:Boolean=true, fUseCache:Boolean=false): Boolean {
			if (fDoObjects) {
				var dob:DisplayObject = imgd.getChildByName(_id);
				_nUndoDepth = imgd.getChildIndex(dob);
				var nTargetIndex:Number = _nUndoDepth + _nDepthChange;
				if (nTargetIndex < 0) nTargetIndex = 0;
				else if (nTargetIndex >= imgd.numChildren) nTargetIndex = imgd.numChildren - 1;
				imgd.setChildIndex(dob, nTargetIndex);
			}
			return super.Do(imgd, fDoObjects, fUseCache);
		}
		
		// Restore the saved properties
		override public function Undo(imgd:ImageDocument): Boolean {
			if (_nUndoDepth > -1) {
				var dob:DisplayObject = imgd.getChildByName(_id);
				var nTargetIndex:Number = _nUndoDepth;
				if (nTargetIndex < 0) nTargetIndex = 0;
				else if (nTargetIndex >= imgd.numChildren) nTargetIndex = imgd.numChildren - 1;
				imgd.setChildIndex(dob, nTargetIndex);
			}
			return true;
		}
	}
}