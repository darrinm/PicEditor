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
	public class SetPropertiesObjectOperation extends ObjectOperation {
		private var _id:String;
		private var _dctProperties:Object;
		private var _fCoalescable:Boolean = true;
				
		// Preserved by Do for Undo
		private var _dctUndoProperties:Object;
		
		public function SetPropertiesObjectOperation(id:String=null, dctProperties:Object=null) {
			// ObjectOperation constructors are called with no arguments during Deserialization
			if (!id)
				return;
			_id = id;
			_dctProperties = dctProperties;
		}
		
		public function set props(dctProperties:Object): void {
			_dctProperties = dctProperties;
		}
		
		public function get props(): Object {
			return _dctProperties;
		}
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			
			var obVals:Object = {};
			obVals.id = _id;
			obVals.properties = SerializationUtil.CleanSrlzWriteValue(_dctProperties);
			obVals.undoProperties = SerializationUtil.CleanSrlzWriteValue(_dctUndoProperties);
			output.writeObject(obVals);
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			
			var obVals:Object = input.readObject();
			
			_id = obVals.id;
			_dctProperties = obVals.properties;
			_dctUndoProperties = obVals.undoProperties;
		}
		
		override public function Deserialize(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@id, "SetPropertiesObjectOperation id argument missing");
			_id = String(xmlOp.@id);
			Debug.Assert(xmlOp.Properties.length() > 0, "SetPropertiesObjectOperation Properties argument missing");
			_dctProperties = Util.ObFromXmlProperties(xmlOp.Properties[0]);

			// Deserialize the optional undo state
			if (xmlOp.UndoProperties.length() > 0)
				_dctUndoProperties = Util.ObFromXmlProperties(xmlOp.UndoProperties[0]);
			return true;
		}
		
		override public function Serialize(): XML {
			var xml:XML = <SetProperties id={_id}/>;
			xml.appendChild(Util.XmlPropertiesFromOb(_dctProperties, "Properties"));
			
			// Serialize the undo state (if there is any)
			if (_dctUndoProperties)
				xml.appendChild(Util.XmlPropertiesFromOb(_dctUndoProperties, "UndoProperties"));
			return xml;
		}
		
		override public function Do(imgd:ImageDocument, fDoObjects:Boolean=true, fUseCache:Boolean=false): Boolean {
			if (fDoObjects) {
				var dob:DisplayObject = imgd.getChildByName(_id);
				
				// Save undo state
				_dctUndoProperties = {}
				for (var strProp:String in _dctProperties) {
					if (strProp == "parent") {
						_dctUndoProperties["parent"] = dob.parent.name;
					} else if (strProp == "zIndex") {
						_dctUndoProperties["zIndex"] = dob.parent.getChildIndex(dob);
					} else {
						_dctUndoProperties[strProp] = dob[strProp];
					}
				}
					
				// Actually 'Do' the operation
				// First, special case parent and zIndex because we must set the parent first
				if ("parent" in _dctProperties || "zIndex" in _dctProperties) {
					// Do the parent first
					var dobcParent:DisplayObjectContainer = null;
					if ("parent" in _dctProperties) {
						// Find the parent container and reparent this object to it
						dobcParent = DisplayObjectContainer(imgd.getChildByName(_dctProperties["parent"]));
						dobcParent.addChild(dob);
						if (dobcParent is IDocumentObject)
							IDocumentObject(dobcParent).Invalidate();
					}
					// Next, apply the zIndex
					if ("zIndex" in _dctProperties) {
						if (dobcParent == null) dobcParent = dob.parent;
						dobcParent.setChildIndex(dob, Number(_dctProperties["zIndex"]));
					}
					if (dobcParent is IDocumentObject)
						IDocumentObject(dobcParent).Invalidate();
				}
				
				for (strProp in _dctProperties) {
					if (strProp != "parent" && strProp != "zIndex") {
						dob[strProp] = _dctProperties[strProp];
					}
				}
			}
			return super.Do(imgd, fDoObjects, fUseCache);
		}
		
		// Restore the saved properties
		override public function Undo(imgd:ImageDocument): Boolean {
			var dob:DisplayObject = imgd.getChildByName(_id);
			
			// Special case parent and zIndex because they must be done in order (parent first)
			if ("parent" in _dctUndoProperties || "zIndex" in _dctUndoProperties) {
				var dobcParent:DisplayObjectContainer = null;
				if ("parent" in _dctUndoProperties) {
					// Find the parent container and reparent this object to it
					dobcParent = DisplayObjectContainer(imgd.getChildByName(_dctUndoProperties["parent"]));
					dobcParent.addChild(dob);
				}
				if ("zIndex" in _dctUndoProperties) {
					if (dobcParent == null) dobcParent = dob.parent;
					dobcParent.setChildIndex(dob, Number(_dctUndoProperties["zIndex"]));
				}	
					
				// Target containers need to invalidate when their children change
				// so they can lay them out.
				// CONSIDER: Target should listen for add/removechild events
				if (dobcParent is IDocumentObject)
					IDocumentObject(dobcParent).Invalidate();
				
			}
			
			for (var strProp:String in _dctUndoProperties) {
				if (strProp != "parent" && strProp != "zIndex")
					dob[strProp] = _dctUndoProperties[strProp];
			}
			return true;
		}

		// Assume assetRefs is either an array or a comma separated string.		
		private function ToAssetArray(obAssetList:Object): Array {
			if (obAssetList is Array) return obAssetList as Array;
			var strList:String = obAssetList.toString();
			if (strList.length == 0) return [];
			return strList.split(',');
		}
		
		override public function get assetRefs():Array {
			var aRefs:Array = [];
			if ('assetRef' in _dctProperties)
				aRefs.push(_dctProperties['assetRef']);
			if ('assetRef' in _dctUndoProperties)
				aRefs.push(_dctUndoProperties['assetRef']);
			
			if ('assetRefs' in _dctProperties)
				aRefs = aRefs.concat(ToAssetArray(_dctProperties['assetRefs']));
			if ('assetRefs' in _dctUndoProperties)
				aRefs = aRefs.concat(ToAssetArray(_dctUndoProperties['assetRefs']));
				
			return aRefs;
		}
		
		// Does this operation target the same object and properties as those
		// passed in?
		public function IsCoalesceMatch(id:String, dctProperties:Object): Boolean {
			if (_id != id)
				return false;
			
			// Test to see if this operation contains all the properties the
			// caller cares about.
			var cCallerProps:Number = 0;
			for (var strProp:String in dctProperties) {
				if (_dctProperties[strProp] == undefined)
					return false;
				cCallerProps++;
			}
			
			// Test to see if this operation contains any bonus properties
			var cDoProps:Number = 0;
			for (strProp in _dctProperties)
				cDoProps++;
			if (cCallerProps != cDoProps)
				return false;
			
			// Looks like a match				
			return true;
		}
		
		//
		// Some helpers for applying property changes to all DocumentObjects in a ImageDocument
		//

		// Returns an updated dctPropertySets dictionary of dictionaries keyed by DocumentObject name.
		// Each property dictionary will have x, y, scaleX, scaleY properties scaled by nScaleFactor
		public static function ScaleDocumentObjects(dctPropertySets:Object, imgd:ImageDocument, nScaleX:Number, nScaleY:Number=NaN): void {
			if (isNaN(nScaleY))
				nScaleY = nScaleX;
				
			for (var i:Number = 0; i < imgd.numChildren; i++) {
				var dob:DisplayObject = imgd.getChildAt(i);
				var dctProperties:Object = dctPropertySets[dob.name];
				if (dctProperties == null)
					dctProperties = {};
				if (!("x" in dctProperties))
					dctProperties.x = dob.x;
				if (!("y" in dctProperties))
					dctProperties.y = dob.y;
				if (!("scaleX" in dctProperties))
					dctProperties.scaleX = dob.scaleX;
				if (!("scaleY" in dctProperties))
					dctProperties.scaleY = dob.scaleY;
				dctProperties.x *= nScaleX;
				dctProperties.y *= nScaleY;
				dctProperties.scaleX *= nScaleX;
				dctProperties.scaleY *= nScaleY;
				dctPropertySets[dob.name] = dctProperties;
			}
		}
		
		// Returns an updated dctPropertySets dictionary of dictionaries keyed by DocumentObject name.
		// Each property dictionary will have x, y properties offset by dx, dy
		public static function OffsetDocumentObjects(dctPropertySets:Object, imgd:ImageDocument, dx:Number, dy:Number): void {
			for (var i:Number = 0; i < imgd.numChildren; i++) {
				var dob:DisplayObject = imgd.getChildAt(i);
				var dctProperties:Object = dctPropertySets[dob.name];
				if (dctProperties == null)
					dctProperties = {};
				if (!("x" in dctProperties))
					dctProperties.x = dob.x;
				if (!("y" in dctProperties))
					dctProperties.y = dob.y;
				dctProperties.x += dx;
				dctProperties.y += dy;
				dctPropertySets[dob.name] = dctProperties;
			}
		}

		// For each set of properties instantiate a SetPropertiesObjectOperation and Do it.
		// Loop over the PropertySets like this so they'll always be performed in the same order
		public static function SetProperties(dctPropertySets:Object, imgd:ImageDocument): void {
			for (var i:Number = 0; i < imgd.numChildren; i++) {
				var dob:DisplayObject = imgd.getChildAt(i);
				var dctProperties:Object = dctPropertySets[dob.name];
				var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(dob.name, dctProperties);
				spop.Do(imgd);
			}
		}
	}
}
