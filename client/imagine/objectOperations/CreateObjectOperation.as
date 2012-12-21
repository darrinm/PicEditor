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
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.documentObjects.IDocumentObject;
	import imagine.serialization.SerializationInfo;
	
	import util.BitmapCache;
	
	[RemoteClass]
	public class CreateObjectOperation extends ObjectOperation {
		private var _strType:String;
		private var _dctProperties:Object;
		
		public function CreateObjectOperation(strType:String=null, dctProperties:Object=null) {
			// ObjectOperation constructors are called with no arguments during Deserialization
			if (!strType)
				return;
			_strType = strType;
			_dctProperties = dctProperties;
		}
		
		public function set type(strType:String): void {
			_strType = strType;
		}
		
		public function get type(): String {
			return _strType;
		}
		
		public function set props(dctProperties:Object): void {
			_dctProperties = dctProperties;
		}
		
		public function get props(): Object {
			return _dctProperties;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['type', {name:'props', cleanWriteValue:true}]);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override public function Deserialize(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@type, "CreateObjectOperation type argument missing");
			_strType = String(xmlOp.@type);
			Debug.Assert(xmlOp.Properties.length() > 0, "CreateObjectOperation Properties argument missing");
			_dctProperties = Util.ObFromXmlProperties(xmlOp.Properties[0]);
			return true;
		}
		
		override public function Serialize(): XML {
			var xml:XML = <Create type={_strType}/>;
			var xmlProperties:XML = Util.XmlPropertiesFromOb(_dctProperties, "Properties");
			xml.appendChild(xmlProperties);
			return xml;
		}
		
		// Create object and add to ImageDocument
		override public function Do(imgd:ImageDocument, fDoObjects:Boolean=true, fUseCache:Boolean=false): Boolean {
			Apply(imgd, imgd.background, fDoObjects, fUseCache);
			return super.Do(imgd, fDoObjects, fUseCache);
		}
		
		// Easy, just remove from the document
		override public function Undo(imgd:ImageDocument): Boolean {
			var dob:DisplayObject = imgd.getChildByName(_dctProperties.name);
			dob.parent.removeChild(dob);
			if (dob is IDocumentObject)
				IDocumentObject(dob).Dispose();
			return true;
		}
		
		override public function Apply(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean=false): BitmapData {
			// We don't want to Do ObjectOperations during document deserialization because the
			// DocumentObject state is already final. Deserialization still needs to get Object-
			// Operations on the undo history (so they can be undone) and it does so by detecting
			// them inside UndoTransactions and putting them directly on the history without Do'ing
			// them.
			if (fDoObjects) {
				// Every object must be created with a globally unique name which is used to
				// find it at Undo time, amongst other things. If it hasn't been assigned one
				// by now, assign one.
				if (!("name" in _dctProperties))
					_dctProperties.name = Util.GetUniqueId();
	
				var dob:DisplayObject = imgd.CreateDocumentObject(_strType, _dctProperties) as DisplayObject;
				
				var nZIndex:Number = ('zIndex' in _dctProperties) ? _dctProperties.zIndex : NaN;
								
				if (_dctProperties.parent) {
					var dobcParent:DisplayObjectContainer = imgd.getChildByName(_dctProperties.parent) as DisplayObjectContainer;
					Debug.Assert(dobcParent != null, "We shouldn't be trying to add a child to non- (or non-existant) DisplayObjectContainer!");
					if (isNaN(nZIndex))
						dobcParent.addChild(dob);
					else
						dobcParent.addChildAt(dob, nZIndex);
				} else {
					if (isNaN(nZIndex))
						imgd.addChild(dob);
					else
						imgd.addChildAt(dob, nZIndex);
				}
				
				if (!BitmapCache.Contains(bmdSrc))
					BitmapCache.Set(this, "ObjectOperation", Serialize().toXMLString(), bmdSrc, bmdSrc);
			}
			return bmdSrc;
		}
		
 		// By convention, DocumentObjects will reference assets they require via an
 		// assetRef (single) or assetRefs (multiple) property.
		override public function get assetRefs(): Array {
			if ("assetRef" in _dctProperties) {
				return [ _dctProperties["assetRef"] ];
			}
			if ("assetRefs" in _dctProperties) {
				return _dctProperties["assetRefs"];
			}
			return null;						
		}
	}
}
