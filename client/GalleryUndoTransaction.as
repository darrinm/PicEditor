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
	import mx.collections.ArrayCollection;
	
	import util.GalleryItem;
	
	public class GalleryUndoTransaction extends UndoTransaction { // gut

		public static const INSERT_IMAGE:String			= 'InsertImage';
		public static const DELETE_IMAGE:String			= 'DeleteImage';
		public static const INSERT_IMAGES:String		= 'InsertImages';
		public static const DELETE_IMAGES:String		= 'DeleteImages';
		public static const DELETE_ALL_IMAGES:String	= 'DeleteAllImages';
		public static const SET_IMAGES:String			= 'SetImages';
		public static const SET_PROPERTY:String			= 'SetProperty';
		public static const SET_PROPERTIES:String		= 'SetProperties';
		public static const SET_IMAGE_PROPERTY:String	= 'SetImageProperty';
		public static const SET_IMAGE_PROPERTIES:String	= 'SetImageProperties';
		public static const MOVE_IMAGE:String			= 'MoveImage';
				
		public var item:GalleryItem;
		public var id:String;
		public var pos:int;
		public var oldPos:int;
		public var key:String;
		public var val:Object;
		public var oldVal:Object;
		public var items:ArrayCollection;
		
		public function GalleryUndoTransaction(strName:String=null, fDirty:Boolean=true,
			item:GalleryItem=null, id:String=null, pos:int=-1, oldPos:int=-1, key:String=null, val:Object=null,
			oldVal:Object=null, items:ArrayCollection=null, fLog:Boolean=true)
		{
			super(strName, fLog, fDirty);
			
			// BUGBUG: Should we be cloning the "item" field here? 
			// Otherwise, we could end up archiving a modified version if someone changes the
			// item after this GUT is created.  I think?
			this.item = item;
			this.id = id;
			this.pos = pos;
			this.oldPos = oldPos;
			this.key = key;
			this.val = val;
			this.oldVal = oldVal;
			this.items = items;
		}

		public function get isStyleOp() : Boolean {
			return (strName == SET_PROPERTY || strName == SET_PROPERTIES);
		}
		
		public override function Matches( utOther:UndoTransaction ):Boolean {
			var gutOther:GalleryUndoTransaction = utOther as GalleryUndoTransaction;
			
			if (!gutOther) return super.Matches(utOther);
			
			if (super.Matches(utOther) &&
					 item == gutOther.item &&
					 id == gutOther.id &&
					 pos == gutOther.pos &&
					 oldPos == gutOther.oldPos &&
					 key == gutOther.key &&
					 val == gutOther.val &&
					 oldVal == gutOther.oldVal &&
					 items == gutOther.items) {
				 return true;
			}
			return false;			
		}

		public function Invert():GalleryUndoTransaction {
			switch (strName) {
				case INSERT_IMAGE:
					return new GalleryUndoTransaction( DELETE_IMAGE, false, item, id, oldPos, pos);
				case DELETE_IMAGE:
					return new GalleryUndoTransaction( INSERT_IMAGE, false, item, id, oldPos );
				case INSERT_IMAGES:
					return new GalleryUndoTransaction( DELETE_IMAGES, false, null, null, -1, -1, null, null, null, items );
				case DELETE_IMAGES:
					return new GalleryUndoTransaction( INSERT_IMAGES, false, null, null, -1, -1, null, null, null, items );
				case DELETE_ALL_IMAGES:
					return new GalleryUndoTransaction( SET_IMAGES, false, null, null, -1, -1, null, null, null, items );
				case SET_IMAGES:
					return new GalleryUndoTransaction( DELETE_ALL_IMAGES, false, null, null, -1, -1, null, null, null, items );
				case SET_PROPERTY:
					return new GalleryUndoTransaction( SET_PROPERTY, false, null, id, -1, -1, key, oldVal, val );
				case SET_PROPERTIES:
					return new GalleryUndoTransaction( SET_PROPERTIES, false, null, null, -1, -1, null, oldVal, val );
				case SET_IMAGE_PROPERTY:
					return new GalleryUndoTransaction( SET_IMAGE_PROPERTY, false, null, id, -1, -1, key, oldVal, val );
				case GalleryUndoTransaction.MOVE_IMAGE:
					return new GalleryUndoTransaction( MOVE_IMAGE, false, item, id, oldPos, pos );
			}
			trace("unknown transaction type in GalleryUndoTransaction.Invert");
			return null;								
		}
		
		public function toXml(): XML {
			var xmlGut:XML = <gut name={strName}/>
			
			// gut attributes -- only set them if they're not defaults
			if (id != null && id != "null") {
				xmlGut.@id = id;
			}
			
			if (pos >= 0) {
				xmlGut.@pos = pos;
			}
			
			if (oldPos >= 0) {
				xmlGut.@oldPos = oldPos;
			}	
					
			if (key != null && key != "null") {
				xmlGut.@key = key;
			}
			
			if (!fDirty) {
				xmlGut.@dirty = fDirty;
			}
			
			// val/oldVal
			if (val is String) {
				xmlGut.appendChild( <val>{val}</val> );
			} else if (val != null) {
				xmlGut.appendChild( Util.XmlPropertiesFromOb(val, "val") );
			}
			if (oldVal is String) {
				xmlGut.appendChild( <oldVal>{oldVal}</oldVal> );
			} else if (oldVal != null) {
				xmlGut.appendChild( Util.XmlPropertiesFromOb(oldVal, "oldVal") );
			}			

			// items
			if (items) {
				var xmlItems:XML = <items count={items.length}/>;
				for each (var itm:GalleryItem in items) {
					xmlItems.appendChild( itm.toXml() );
				}
				xmlGut.appendChild( xmlItems );
			}
			
			// item
			if (item) {
				xmlGut.appendChild( item.toXml() );
			}
					
			return xmlGut;			
		}
		
		public function toAMF(): Object {
			var obGut:Object = {name:strName};
			
			// gut attributes -- only set them if they're not defaults
			if (id != null && id != "null") {
				obGut.id = id;
			}
			
			if (pos >= 0) {
				obGut.pos = pos;
			}
			
			if (oldPos >= 0) {
				obGut.oldPos = oldPos;
			}	
					
			if (key != null && key != "null") {
				obGut.key = key;
			}
			
			if (!fDirty) {
				obGut.dirty = fDirty;
			}
			
			// val/oldVal
			obGut.val = val;
			obGut.oldVal = oldVal;

			// items
			if (items) {
				obGut.aobItems = [];
				for each (var itm:GalleryItem in items) {
					obGut.aobItems.push( itm.toAMF() );
				}
			}
			
			// item
			if (item) {
				obGut.item = item.toAMF();
			}
					
			return obGut;			
		}
		
		public static function fromXml( doc:GalleryDocument, xml:XML ): GalleryUndoTransaction {
			var gut:GalleryUndoTransaction = new GalleryUndoTransaction(xml.@name);
			
			if (xml.hasOwnProperty("@dirty")) {
				gut.fDirty = xml.@dirty;
			}
			if (xml.hasOwnProperty("@key")) {
				gut.key = xml.@key;
			}
			if (xml.hasOwnProperty("@id")) {
				gut.id = xml.@id;
			}
			if (xml.hasOwnProperty("@pos")) {
				gut.pos = xml.@pos;
			}
			if (xml.hasOwnProperty("@oldPos")) {
				gut.oldPos = xml.@oldPos;
			}

			if (xml.hasOwnProperty("item")) {
				var xmllItem:XMLList = xml.item;
				var xmlItem:XML = xmllItem[0];
				var item:GalleryItem = doc.GetItemById(xmlItem.@id);
				gut.item = item;
			}
			
			if (xml.hasOwnProperty("items")) {
				gut.items = new ArrayCollection();
				for each (var xmlItems:XML in xml.items.item) {
					var item2:GalleryItem = doc.GetItemById(xmlItems.@id);
					gut.items.addItem(item2);
				}
			}
			
			if (xml.hasOwnProperty("val")) {
				var xmllVal:XMLList = xml..val;	// hmm...why does this have 2 dots, but oldVal, below, only uses 1?
				var xmlVal:XML = xmllVal[0];
				if (xmlVal.hasOwnProperty("Object"))
					gut.val = Util.ObFromXmlProperties(xmlVal.Object);
				else if (xmlVal.hasOwnProperty("val"))
					gut.val = Util.ObFromXmlProperties(xmlVal.val);
				else if (xmlVal.hasOwnProperty("Property"))
					gut.val = Util.ObFromXmlProperties(xmlVal);
				else
					gut.val = xmlVal.toString();
			}		

			if (xml.hasOwnProperty("oldVal")) {
				var xmllOldVal:XMLList = xml.oldVal;				
				var xmlOldVal:XML = xmllOldVal[0];
				if (xmlOldVal.hasOwnProperty("Object"))
					gut.oldVal = Util.ObFromXmlProperties(xmlOldVal.Object);
				else if (xmlOldVal.hasOwnProperty("oldVal"))
					gut.oldVal = Util.ObFromXmlProperties(xmlOldVal.oldVal);
				else if (xmlOldVal.hasOwnProperty("Property"))
					gut.oldVal = Util.ObFromXmlProperties(xmlOldVal);
				else
					gut.oldVal = xmlOldVal.toString();				
			}
			return gut;
		}	

		public static function fromAMF( doc:GalleryDocument, ob:Object ): GalleryUndoTransaction {
			var gut:GalleryUndoTransaction = new GalleryUndoTransaction(ob.name);
			
			if (ob.hasOwnProperty("dirty")) {
				gut.fDirty = ob.dirty;
			}
			if (ob.hasOwnProperty("key")) {
				gut.key = ob.key;
			}
			if (ob.hasOwnProperty("id")) {
				gut.id = ob.id;
			}
			if (ob.hasOwnProperty("pos")) {
				gut.pos = ob.pos;
			}
			if (ob.hasOwnProperty("oldPos")) {
				gut.oldPos = ob.oldPos;
			}

			var obItem:Object;
			if (ob.hasOwnProperty("item")) {
				obItem = ob.item;
				var item:GalleryItem = doc.GetItemById(obItem.id);
				gut.item = item;
			}
			
			if (ob.hasOwnProperty("aobItems")) {
				gut.items = new ArrayCollection();
				for each (obItem in ob.aobItems)
					gut.items.addItem(doc.GetItemById(obItem.id));
			}
			
			if (ob.hasOwnProperty("val")) {
				gut.val = ob.val;
			}		

			if (ob.hasOwnProperty("oldVal")) {
				gut.oldVal = ob.oldVal;				
			}
			return gut;
		}	
	}
}
