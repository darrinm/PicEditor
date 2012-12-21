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
	import flash.display.DisplayObjectContainer;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.documentObjects.IDocumentObject;
	import imagine.serialization.SerializationUtil;
	
	[RemoteClass]
	public class DestroyObjectOperation extends ObjectOperation {
		private var _id:String;
		
		// Preserved by Do for Undo
		private var _strType:String;
		private var _dctProperties:Object;
		private var _index:Number;
		private var _xmlUndoObject:XML;
		
		public function DestroyObjectOperation(id:String=null) {
			// ObjectOperation constructors are called with no arguments during Deserialization
			if (!id)
				return;
			_id = id;
		}

		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first

			var obValues:Object = {};
			obValues.id = _id;
			obValues.type = _strType;
			obValues.properties = SerializationUtil.CleanSrlzWriteValue(_dctProperties);
			obValues.undoIndex = _index;
			obValues.xmlUndoObject = _xmlUndoObject;
			output.writeObject(obValues);
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			
			var obValues:Object = input.readObject();
			_id = obValues.id;
			_strType = obValues.type;
			_dctProperties = obValues.properties;
			_index = obValues.undoIndex;
			_xmlUndoObject = obValues.xmlUndoObject;
		}
		
		override public function Deserialize(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@id, "DestroyObjectOperation id argument missing");
			_id = String(xmlOp.@id);
			
			// Deserialize the optional undo state
			if (xmlOp.hasOwnProperty("@undoIndex"))
				_index = Number(xmlOp.@undoIndex);
			if (xmlOp.hasOwnProperty("@undoType")) {
				_strType = String(xmlOp.@undoType);
				if (xmlOp.UndoProperties.length() > 0)
					_dctProperties = Util.ObFromXmlProperties(xmlOp.UndoProperties[0]);
			} else if (xmlOp.UndoObject.length() > 0) {
				_xmlUndoObject = xmlOp.UndoObject[0];
			}
			return true;
		}
		
		override public function Serialize(): XML {
			var xml:XML = <Destroy id={_id}/>;
			
			// Serialize the undo state (if there is any)
			if (_xmlUndoObject != null) {
				xml.@undoIndex = _index;
				xml.appendChild(_xmlUndoObject);
			}
			return xml;
		}
		
		override public function Do(imgd:ImageDocument, fDoObjects:Boolean=true, fUseCache:Boolean=false): Boolean {
			if (fDoObjects) {
				var dob:DisplayObject = imgd.getChildByName(_id);
				
				// Stash away everything we need to recreate the object exactly as it was
				_index = dob.parent.getChildIndex(dob);
	//			_strType = ImageDocument.GetDocumentObjectType(IDocumentObject(dob));
				var xmlDestroyedObject:XML = ImageDocument.DocumentObjectToXML(IDocumentObject(dob));
				if (dob.parent.name != "$root")
					xmlDestroyedObject.@parent = dob.parent.name;
				_xmlUndoObject = <UndoObject/>;
				_xmlUndoObject.appendChild(xmlDestroyedObject);
	
				// Actually 'Do' the operation
				dob.parent.removeChild(dob);
				if (dob is IDocumentObject)
					IDocumentObject(dob).Dispose();
			}
			return super.Do(imgd, fDoObjects, fUseCache);
		}
		
		// Recreate the object (and all its child objects) at its previous depth (index)
		override public function Undo(imgd:ImageDocument): Boolean {
			if (_strType) { // For backwards compatibility with stored documents
				var dob:DisplayObject = imgd.CreateDocumentObject(_strType, _dctProperties) as DisplayObject;
				if (_dctProperties.parent) {
					var dobcParent:DisplayObjectContainer = imgd.getChildByName(_dctProperties.parent) as DisplayObjectContainer;
					dobcParent.addChildAt(dob, _index);
				} else {
					imgd.addChildAt(dob, _index);
				}
			} else if (_xmlUndoObject != null) {
				imgd.DeserializeDocumentObjects(imgd.documentObjects, _xmlUndoObject, _index);
				imgd.documentObjects.Validate();
			}
			return true;
		}
	}
}
