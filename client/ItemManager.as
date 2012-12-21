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
	// ItemManager.as gives us a place to manage multiple photos
	import mx.events.PropertyChangeEvent;
	
	public class ItemManager {		
		
		private var _adctItems:Array = [];
		private var _adctSets:Array = [];
		private var _strDefaultService:String = "";
							
		[Bindable]
		public function set defaultService(strService:String): void {
			_strDefaultService = strService;
		}
		
		public function get defaultService():String {
			return _strDefaultService; 	
		}

		[Bindable]
		public function set items(adctItems:Array): void {
			// change notifications are manually propagated. See AddItem()
			Debug.Assert( !"ItemManager.items is read-only" );
		}
		
		public function get items():Array {
			return _adctItems; 	
		}
		
		[Bindable]
		public function set sets(adctSets:Array): void {
			// change notifications are manually propagated. See AddSet()
			Debug.Assert( !"ItemManager.sets is read-only" );
		}
		
		public function get sets():Array {
			return _adctSets; 	
		}
		
		public function AddItem( dctItem:ItemInfo ): void {
			// for now, we only support a homogenous multibasket.
			// later, we'll let it contain a mix of items.
			if (dctItem.serviceid.toLowerCase() != defaultService.toLowerCase())
				return;
				
			var adctOldItems:Array = _adctItems;
			// search for an item with this id already in the batch
			for (var i:Number = 0; i < _adctItems.length; i++) {
				if (dctItem.id == _adctItems[i].id && dctItem.serviceid.toLowerCase() == _adctItems[i].serviceid.toLowerCase()) {
					_adctItems[i] = dctItem;
					dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "items", adctOldItems, _adctItems));	
					return;
				}
			}
			// new item; stick it on the front.
			_adctItems.unshift(dctItem);
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "items", adctOldItems, _adctItems));	
		}

				
		public function AddItems( adctItems:Array ): void {
			for (var i:Number = 0; i < adctItems.length; i++) {
				if (adctItems[i].invalid_image) {
					RemoveItem( adctItems[i] );
				} else {
					AddItem( adctItems[i] );
				}
			}
		}
		
		public function RemoveItem( dctItem:ItemInfo ): Object {
			var adctOldItems:Array = _adctItems;
			
			// search for an item with this id
			for (var i:Number = 0; i < _adctItems.length; i++) {
				if (dctItem.id == _adctItems[i].id) {
					dctItem = _adctItems[i];
					_adctItems.splice( i, 1 );
					dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "items", adctOldItems, _adctItems));	
					return dctItem;
				}
			}
			return null;
		}
		
		public function RemoveItems(): void {
			var adctOldItems:Array = _adctItems;
			_adctItems = [];
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "items", adctOldItems, _adctItems));	
		}
		
		public function AddSet( dctSet:Object ): void {
			var adctOldSets:Array = _adctSets;
			// search for an item with this id already in the batch
			for (var i:Number = 0; i < _adctSets.length; i++) {
				if (dctSet.id == _adctSets[i].id && dctSet.serviceid == _adctSets[i].serviceid) {
					_adctSets[i] = dctSet;
					dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "sets", adctOldSets, _adctSets));	
					return;
				}
			}
			// new set; stick it on the front.
			_adctSets.unshift(dctSet);
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "sets", adctOldSets, _adctSets));	
		}
		
		public function FlattenSet( dctSet:Object, adctItems:Array ): void {
			AddItems( adctItems );
			RemoveSet( dctSet );
		}		
				
		public function RemoveSet( dctSet:Object ): Object {
			var adctOldSets:Array = _adctSets;
			
			// search for a set with this id
			for (var i:Number = 0; i < _adctSets.length; i++) {
				if (dctSet.id == _adctSets[i].id && dctSet.serviceid == _adctSets[i].serviceid) {
					dctSet = _adctSets[i];
					_adctSets.splice( i, 1 );
					dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "sets", adctOldSets, _adctSets));	
					return dctSet;
				}
			}
			return null;
		}		
		
		public function RemoveSets( dctSet:Object ): void {
			var adctOldSets:Array = _adctItems;
			_adctSets = [];
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "sets", adctOldSets, _adctSets));	
		}
				
		// Serialized batch information looks something like this:
		//		<items>
		//			<item id="..." ss="flickr">
		//				<sourceurl>http://....</sourceurl>
		//				<thumbnailurl>http://....</thumbnailurl>
		//				<title>...</title>
		//				<description>...</description>
		//				<tags>...</tags>
		//			</item>
		//			...more items...
		//			<set id="..." ss="flickr"/>
		//			...more sets...
		//		</items>
						
		
		public function Serialize(): String {
			var strItems:String = "<items>";
			
			// note that we save the items in backwards order because
			// they're deserialized back-to-front.
			for (var i:Number = _adctItems.length-1; i >= 0; i--) {
				var dctItem:Object = _adctItems[i];
				strItems += "<item id='" + dctItem.id + "' ss='" + dctItem.serviceid + "'>";
				for each (var strAttr:String in ['title','description','sourceurl','thumbnailurl']) {
					if (strAttr in dctItem) {
						strItems += "<" + strAttr + ">" + dctItem[strAttr] + "</" + strAttr + ">";
					}
				}
				strItems += "</item>";
			}
			strItems += "</items>";
			return strItems;
		}
		
		public function Deserialize( strItems:String ):void {
			try {
				var adctItemInfos:Array = [];
				var xmlItems:XML = null;	
				try {
					xmlItems = new XML(strItems);
				} catch (err:Error) {
					PicnikService.LogException("Invalid items XML", err, null, strItems);
					return;
				}

				if (xmlItems) {
					// Store every set we've been given
					for each (var xmlSet:XML in xmlItems['set']) {
						var strId:String = String(xmlSet.@id);
						var strServiceId:String = xmlSet.hasOwnProperty("ss") ? String(xmlSet.@ss) : defaultService;
						AddSet( { id: strId, serviceid: strServiceId } );
					}
								
					// Also throw in any individual item info we've been given
					for each (var xmlItem:XML in xmlItems.item) {
						var itemInfo:ItemInfo = new ItemInfo( {
								id: String(xmlItem.@id),
								setid: String(xmlItem.@setid),
								serviceid: xmlItem.hasOwnProperty("ss") ? String(xmlItem.@ss) : defaultService,
								partial: true, /* since we don't trust the API user's info */
								sourceurl: String(xmlItem.sourceurl),
								thumbnailurl: String(xmlItem.thumbnailurl),
								webpageurl: String(xmlItem.webpageurl),
								last_update: String(xmlItem.last_update),
								title: String(xmlItem.title),
								description: String(xmlItem.description),
								tags: String(xmlItem.tags),
								etag: String(xmlItem.etag),
								ownerid: String(xmlItem.ownerid),
								flickr_ispublic: String(xmlItem.flickr_ispublic),
								flickr_isfriend: String(xmlItem.flickr_isfriend),
								flickr_isfamily: String(xmlItem.flickr_isfamily),
								flickr_rotation: String(xmlItem.flickr_rotation),
								width: String(xmlItem.width),
								height: String(xmlItem.height),
								fCanLoadDirect: String(xmlItem.fCanLoadDirect),
								strFormat: String(xmlItem.strFormat) } );
						adctItemInfos.unshift( itemInfo ); 								
					}
					AddItems(adctItemInfos);
				}
			} catch (err:Error) {
				PicnikService.LogException("Error processing items XML ", err, null, strItems);
				return;
			}
		}		
	}
}
