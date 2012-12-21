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
package controls
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.collections.CursorBookmark;
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.collections.XMLListCollection;
	import mx.containers.VBox;
	import mx.core.IFactory;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;

	public class VBoxRepeater extends VBox
	{
	    private var collection:ICollectionView;
	    private var _fItemsInvalid:Boolean = true;
	    private var _itemRenderer:IFactory = null;
	   
	    private var _strChildStyleName:String;
	   
		public function VBoxRepeater()
		{
			super();
			setStyle("verticalGap", 0);
		}

	    //----------------------------------
	    //  itemRenderer
	    //----------------------------------
	
	    /**
	     *  @private
	     *  Storage for the itemRenderer property.
	     */
	
	    [Inspectable(category="Data")]
	
	    /**
	     *  The custom item renderer for the control.
	     *  You can specify a drop-in, inline, or custom item renderer.
	     *
	     *  <p>The default item renderer depends on the component class.
	     *  The TileList and HorizontalList class use
	     *  TileListItemRenderer, The List class uses ListItemRenderer.
	     *  The DataGrid class uses DataGridItemRenderer from DataGridColumn.</p>
	     */
	    public function get itemRenderer():IFactory
	    {
	        return _itemRenderer;
	    }
	   
	    /**
	     *  @private
	     */
	    public function set itemRenderer(value:IFactory):void
	    {
	    	if (_itemRenderer == value) return;
	        _itemRenderer = value;
	
			invalidateItems();
	        dispatchEvent(new Event("itemRendererChanged"));
	    }
	   
	    private function invalidateItems(): void {
	    	_fItemsInvalid = true;
	    	invalidateProperties();
	    }
	   
	    override protected function commitProperties():void {
	    	if (_fItemsInvalid) {
	    		validateItems();
	    	}
	    	super.commitProperties();
	    }
	   
	    private function validateItems(): void {
	    	// First, remove all children.
	    	removeAllChildren();
	    	
	    	if (_itemRenderer == null) return; // No item renderer
	    	if (collection == null) return; // Nothing to render
	    	var iter:IViewCursor = collection.createCursor();
	    	iter.seek(CursorBookmark.FIRST, 0);
	    	while (!iter.afterLast) {
	    		addItem(iter.current);
	    		iter.moveNext();
	    	}
	    	_fItemsInvalid = false;
	    }
	   
	    private function addItem(obData:Object): void {
	    	var dob:DisplayObject = _itemRenderer.newInstance() as DisplayObject;
	    	dob["data"] = obData;
			if ("styleName" in dob) {
				if (_strChildStyleName != null)
					dob["styleName"] = _strChildStyleName;
				else
					dob["styleName"] = this;
			}
			addChild(dob);
	    }
	   
	    public function set childStyleName(str:String): void {
	    	_strChildStyleName = str;
	    	for each (var dob:DisplayObject in getChildren()) {
				if ("styleName" in dob) {
					if (_strChildStyleName != null)
						dob["styleName"] = _strChildStyleName;
					else
						dob["styleName"] = this;
				}
	    	}
	    }
	
	    private function collectionChangeHandler(evt:Event): void {
	    	invalidateItems();
	    }
	   
	    [Bindable]
	    public function set dataProvider(value:Object):void
	    {
	        if (collection)
	        {
	            collection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
	        }
	
	        if (value is Array)
	        {
	            collection = new ArrayCollection(value as Array);
	        }
	        else if (value is ICollectionView)
	        {
	            collection = ICollectionView(value);
	        }
	        else if (value is XMLList)
	        {
	            collection = new XMLListCollection(value as XMLList);
	        }
	        else if (value is XML)
	        {
	            var xl:XMLList = new XMLList();
	            xl += value;
	            collection = new XMLListCollection(xl);
	        }
	        else
	        {
	            // convert it to an array containing this one item
	            var tmp:Array = [];
	            if (value != null)
	                tmp.push(value);
	            collection = new ArrayCollection(tmp);
	        }

	        collection.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler, false, 0, true);
	
	        var event:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
	        event.kind = CollectionEventKind.RESET;
	        collectionChangeHandler(event);
	        dispatchEvent(event);
	
	        invalidateItems();
	    }
	    public function get dataProvider():Object
	    {
	        return collection;
	    }

	}
}