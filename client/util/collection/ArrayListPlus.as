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
package util.collection
{
	import mx.collections.ArrayList;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;

	public class ArrayListPlus extends ArrayList
	{
	    private var resourceManager:IResourceManager =
                                    ResourceManager.getInstance();
                                   
		public function ArrayListPlus(source:Array=null)
		{
			super(source);
		}
		
		// Based on ArrayList.removeItemAt()
		public function moveItem(iFrom:int, iTo:int): void {
	    	var iOutOfBounds:Number = NaN;
	        if (iFrom < 0 || iFrom >= length)
	        	iOutOfBounds = iFrom;
	        else if (iTo < 0 || iTo >= length)
	        	iOutOfBounds = iTo;
	        if (!isNaN(iOutOfBounds))
	            throw new RangeError(resourceManager.getString(
	                "collections", "outOfBounds", [ iOutOfBounds ]));

			if (iFrom == iTo)
				return; // NOP
			
	        var obMove:Object = source.splice(iFrom, 1)[0];
	        source.splice(iTo, 0, obMove);
	        internalDispatchMoveEvent(iFrom, iTo, obMove);
	    }

		// Based on ArrayList.internalDispatchEvent()
		private function internalDispatchMoveEvent(iFrom:int, iTo:int, obMove:Object):void
		{
    		if (hasEventListener(CollectionEvent.COLLECTION_CHANGE))
    		{
		        var event:CollectionEvent =
					new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
		        event.kind = CollectionEventKind.MOVE;
		        event.items.push(obMove);
		        event.location = iTo;
		        event.oldLocation = iFrom;
		        dispatchEvent(event);
		    }

	    	// now dispatch a complementary PropertyChangeEvent
	    	if (hasEventListener(PropertyChangeEvent.PROPERTY_CHANGE)) 
	    	{
				var iDir:Number = (iFrom > iTo) ? -1 : 1;
				for (var i:Number = iFrom; i != (iTo + iDir); i += iDir) {
		    		var objEvent:PropertyChangeEvent =
						new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE);
		    		objEvent.property = i;
	    			objEvent.newValue = source[i];
		    		dispatchEvent(objEvent);
				}
		    }
		}

	}
}