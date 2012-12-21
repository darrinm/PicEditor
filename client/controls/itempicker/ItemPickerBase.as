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
package controls.itempicker {

	import bridges.email.EmailPickedItem;
	
	import controls.TextInputPlus;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.collections.IList;
	import mx.collections.ListCollectionView;
	import mx.collections.XMLListCollection;
	import mx.containers.Canvas;
	import mx.containers.VBox;
	import mx.controls.List;
	import mx.core.ClassFactory;
	import mx.core.Container;
	import mx.core.UIComponent;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;
	import mx.events.MoveEvent;
	import mx.managers.PopUpManager;


    [Event(name="change", type="flash.events.Event")]
	[Event(name="pickedItemsChange", type="flash.events.Event")]

	public class ItemPickerBase extends VBox {		
		[Bindable] public var pickedItemRenderer:Class;
		[Bindable] public var listItemRenderer:Class;
		[Bindable] public var prompt:String;
		[Bindable] public var oneItem:Boolean = false;
		
		[Bindable] public var _tiFilter:TextInputPlus;
		[Bindable] public var _ctrPickedItems:Container;
		[Bindable] public var _cvsTextBox:Canvas;
					
		private var _lstDropdown:ItemSearchList = null;
		private var _fDropdownShowing:Boolean = false;
		private var _aPickedItems:Array = [];
	    private var _collListItems:ICollectionView;
		
		public function ItemPickerBase() {
			this.addEventListener( FlexEvent.INITIALIZE, OnInit );
			this.addEventListener( Event.CLOSE, OnHide );
		}
					
		public function OnInit(evt:Event):void {
			if (_tiFilter) {
				_tiFilter.addEventListener( KeyboardEvent.KEY_DOWN, OnFilterKeyDown, true );
				_tiFilter.addEventListener( FocusEvent.FOCUS_OUT, OnFilterFocusOut );
				_tiFilter.addEventListener( FocusEvent.FOCUS_IN, OnFilterFocusIn );
				_tiFilter.addEventListener( MouseEvent.CLICK, OnFilterClick );
				_tiFilter.addEventListener( Event.CHANGE, OnFilterChange );
				_tiFilter.addEventListener( Event.RESIZE, OnFilterResize );
				_tiFilter.addEventListener( MoveEvent.MOVE, OnFilterMove );
				_ctrPickedItems.addEventListener( Event.RESIZE, OnPickedItemsResize );
			}
		}	
		
		public function OnHide(evt:Event):void {
			this.HideDropdown();
		}
		
	    //----------------------------------
	    //  pickedItems
	    //----------------------------------
		[Bindable("pickedItemsChange")]
		public function set pickedItems(aItems:Array): void {
			if (oneItem && aItems.length > 1) {
				aItems.splice(1);
			}
			_aPickedItems = aItems;
			dispatchEvent(new Event("change"));
		}
		public function get pickedItems(): Array {
			return _aPickedItems;
		}

	    //----------------------------------
	    //  dataProvider
	    //----------------------------------
	    [Bindable("collectionChange")]
	    [Inspectable(category="Data", defaultValue="undefined")]
	
	    /**
	     *  Set of data to be viewed.
	     *  This property lets you use most types of objects as data providers.
	     *  If you set the <code>dataProvider</code> property to an Array,
	     *  it will be converted to an ArrayCollection. If you set the property to
	     *  an XML object, it will be converted into an XMLListCollection with
	     *  only one item. If you set the property to an XMLList, it will be
	     *  converted to an XMLListCollection. 
	     *  If you set the property to an object that implements the
	     *  IList or ICollectionView interface, the object will be used directly.
	     *
	     *  <p>As a consequence of the conversions, when you get the
	     *  <code>dataProvider</code> property, it will always be
	     *  an ICollectionView, and therefore not necessarily be the type of object
	     *  you used to  you set the property.
	     *  This behavior is important to understand if you want to modify the data
	     *  in the data provider: changes to the original data may not be detected,
	     *  but changes to the ICollectionView object that you get back from the
	     *  <code>dataProvider</code> property will be detected.</p>
	     *
	     *  @default null
	     *  @see mx.collections.ICollectionView
	     */
	    public function get dataProvider():Object
	    {
	        return _collListItems;
	    }
	   
	    /**
	     *  @private
	     */
	    public function set dataProvider(value:Object):void
	    {
	        if (_collListItems)
	        {
	            _collListItems.removeEventListener(CollectionEvent.COLLECTION_CHANGE, CollectionChangeHandler);
	        }
	
	        if (value is Array)
	        {
	            _collListItems = new ArrayCollection(value as Array);
	        }
	        else if (value is ICollectionView)
	        {
	            _collListItems = ICollectionView(value);
	        }
	        else if (value is IList)
	        {
	            _collListItems = new ListCollectionView(IList(value));
	        }
	        else if (value is XMLList)
	        {
	            _collListItems = new XMLListCollection(value as XMLList);
	        }
	        else if (value is XML)
	        {
	            var xl:XMLList = new XMLList();
	            xl += value;
	            _collListItems = new XMLListCollection(xl);
	        }
	        else
	        {
	            // convert it to an array containing this one item
	            var tmp:Array = [];
	            if (value != null)
	                tmp.push(value);
	            _collListItems = new ArrayCollection(tmp);
	        }

	        _collListItems.addEventListener(CollectionEvent.COLLECTION_CHANGE, CollectionChangeHandler, false, 0, true);
	
			dropdown.dataProvider = _collListItems;
			_lstDropdown.SetPickedItems( pickedItems );
			
	        var event:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
	        event.kind = CollectionEventKind.RESET;
	        CollectionChangeHandler(event);
	        dispatchEvent(event);
	    }
	   
	    protected function CollectionChangeHandler(evt:CollectionEvent):void {
			dropdown.dataProvider = _collListItems;
	    	if (evt.kind != CollectionEventKind.REPLACE && evt.kind != CollectionEventKind.ADD &&
	    			evt.kind != CollectionEventKind.REMOVE && evt.kind != CollectionEventKind.UPDATE &&
	    			evt.kind != CollectionEventKind.MOVE) {
	    		//ScrollNow(0); // Reset scroll position
	    	}	
     	    
	    	if (evt.kind != CollectionEventKind.UPDATE) {
	    		//UpdateScrollbars();
	    	}
	    }		
		
		private function get dropdown(): List {
			if (_lstDropdown == null) {
				_lstDropdown = new ItemSearchList();
				_lstDropdown.itemPicker = this;
				_lstDropdown.dataProvider = _collListItems;
				_lstDropdown.width = width;					
				_lstDropdown.rowHeight = 26;
				_lstDropdown.setStyle("borderSides","left,right,bottom");
				_lstDropdown.addEventListener(ListEvent.ITEM_CLICK, OnDropDownClick);
				_lstDropdown.addEventListener(ListEvent.CHANGE, OnDropDownSelect);
				_lstDropdown.itemRenderer = new ClassFactory(listItemRenderer);
			}
			return _lstDropdown;
		}
		
		private function OnDropDownClick(evt:ListEvent): void {
			SelectItem();
		}		
			
		private function OnDropDownSelect(evt:ListEvent): void {
			// nothing
		}
		
		private var _fPicking:Boolean = false;
		public function PickItem( obItem:Object ):void {
			if (_fPicking) return;	// prevent reentrancy
			
			_fPicking = true;
			if (oneItem) {
				UnpickAllItems();
				_cvsTextBox.visible = false;
				_cvsTextBox.includeInLayout = false;
			}
			
			// don't add the same item twice
			for each (var item:EmailPickedItem in _ctrPickedItems.getChildren()) {
				if (CompareItems(item.data, obItem)) {
					if ("Highlight" in item)	
						item['Highlight']();
					_fPicking = false;
					return;
				}
			}
			
			// store the item in our picked list
			_aPickedItems.push( obItem );
	        dispatchEvent(new Event("pickedItemsChange"));			
							
			// add a rendering of the item to the container
			var itm:Container = new pickedItemRenderer();
			itm.data = obItem;
			_ctrPickedItems.addChild(itm);
			if ("Highlight" in itm)	
				itm['Highlight']();
			
			// update the dropdown list		
			_lstDropdown.SetPickedItems(pickedItems);	
			_fPicking = false;
		}
		
		public function UnpickItem( obItem:Object ):void {
			// remove from the picked list
			_aPickedItems.splice(_aPickedItems.indexOf(obItem), 1);
	        dispatchEvent(new Event("pickedItemsChange"));
			
			// remove the child that renders this item
			for( var i:Number = 0; i < _ctrPickedItems.getChildren().length; i++ ) {
				var pickedKid:DisplayObject = _ctrPickedItems.getChildAt(i);
				if (pickedKid && "data" in pickedKid && pickedKid['data'] == obItem) {
					_ctrPickedItems.removeChildAt(i);
					i--;	// we could break here, but what if the same item is twice?
				}
			}
			
			// update the dropdown list
			_lstDropdown.SetPickedItems(pickedItems);	
			MoveDropdown();
			_tiFilter.setFocus();	
			
			if (oneItem) {
				_cvsTextBox.visible = true;
				_cvsTextBox.includeInLayout = true;
			}
		}

		public function UnpickAllItems():void {
			_aPickedItems = [];
	        dispatchEvent(new Event("pickedItemsChange"));

			if (oneItem) {
				_cvsTextBox.visible = true;
				_cvsTextBox.includeInLayout = true;
			}
			
			_ctrPickedItems.removeAllChildren();
			if (_lstDropdown)
				_lstDropdown.SetPickedItems(pickedItems);	
			_tiFilter.setFocus();
		}
		
		private function ShowDropdown(): void {
			if (_fDropdownShowing) return;
			if (dropdown.dataProvider.length == 0) return;
			
			_fDropdownShowing = true;
			if (stage) stage.addEventListener(MouseEvent.CLICK, OnMouseDownWithListUp,false, -100);
			PopUpManager.addPopUp(dropdown, this, false);
			
			// Position and size the list.
			MoveDropdown();
		}
		
		private function MoveDropdown(): void {
			if (!_fDropdownShowing) return;
			
			var nTargetRowCount:Number = 10; // default is 5
			
			// Go smaller if we have fewer items
			nTargetRowCount = Math.min(nTargetRowCount, dropdown.dataProvider.length);
			
			// Also limit it by the number of rows which fit above or below this drop down
			var nRowSize:Number = _lstDropdown.rowHeight;
								
			var ptThis:Point = new Point(0, 0);
			ptThis = localToGlobal(ptThis);
			
			var nSpaceAbove:Number = ptThis.y;
			var nSpaceBelow:Number = screen.height - ptThis.y - height;
			
			var nSpace:Number = Math.max(nSpaceAbove, nSpaceBelow); // max top or bottom space
			nTargetRowCount = Math.min(nTargetRowCount, Math.floor(nSpace / nRowSize));
			
			// Always show at least two rows
			nTargetRowCount = Math.max(2, nTargetRowCount);
			
			dropdown.rowCount = nTargetRowCount;
			
			// Show below unless there is not enough room and there is enough room above.
			if ((nSpaceBelow < nSpaceAbove) && ((nTargetRowCount * nRowSize) > nSpaceBelow)) {
				// Use above
				dropdown.y = ptThis.y - (nTargetRowCount * nRowSize);
			} else {
				// Position below
				dropdown.y = ptThis.y + height;
			}
			dropdown.x = ptThis.x;				
		}
		
		private function HideDropdown(): void {
			if (!_fDropdownShowing) return;
			_fDropdownShowing = false;
			if (stage) stage.removeEventListener(MouseEvent.CLICK, OnMouseDownWithListUp);
			PopUpManager.removePopUp(dropdown);
		}

		private function UpdateFilter(): void {
			if (_lstDropdown && _tiFilter && _tiFilter.text)
				_lstDropdown.filterText = _tiFilter.text.toLowerCase();
		}
			 
		private function OnMouseDownWithListUp(evt:MouseEvent): void {
			// See who got the mouse event.
			var dobTarg:DisplayObject = evt.target as DisplayObject;
			while (dobTarg) {
				if (dobTarg == this) return;
				dobTarg = dobTarg.parent as DisplayObject;
			}
			
			HideDropdown();
		}
		
		private function SelectItem():void {
			if (_lstDropdown && _lstDropdown.selectedItem) {
				PickItem( _lstDropdown.selectedItem );
				_lstDropdown.selectedItem = null;
			} else {
				if (_tiFilter.text.length) {
					var items:Array = CreateItems( _tiFilter.text );
					if (!items || items.length == 0)
						return;
					for each (var oItem:Object in items) {
						PickItem( oItem );
					}
				}					
			}
			UpdateFilter();
			HideDropdown();
			PicnikBase.app.callLater( function():void { _tiFilter.text = ""; } );
			
		}
		
		private const knPassThroughKeys:Array = [Keyboard.UP, Keyboard.DOWN, Keyboard.ENTER, Keyboard.HOME, Keyboard.END, Keyboard.PAGE_UP, Keyboard.PAGE_DOWN];		
		private function OnFilterKeyDown(evt:KeyboardEvent): void {
			if (knPassThroughKeys.indexOf(evt.keyCode) > -1 && _lstDropdown.dataProvider.length > 0) {
				_lstDropdown.dispatchEvent(evt);
			}
			// on enter, select the item
			if (evt.keyCode == Keyboard.ENTER) {
				SelectItem();
				return;
			}
			if (evt.keyCode == Keyboard.BACKSPACE && _tiFilter.text.length == 0) {
				var aKids:Array = _ctrPickedItems.getChildren();
				if (aKids.length > 0) {						
					var uicChild:UIComponent = aKids[aKids.length-1] as UIComponent;
					uicChild.setFocus();
					return;
				}
			}

 			if (evt.keyCode != Keyboard.ESCAPE)
				ShowDropdown();
		}

		private function OnFilterClick(evt:Event): void {
			ShowDropdown();
		}
		
		private function OnFilterFocusIn(evt:Event): void {
		}
		
		private function OnFilterFocusOut(evt:Event): void {
			SelectItem();
			HideDropdown();
		}
		
		private function OnFilterChange(evt:Event): void {
			UpdateFilter();
		}
		
		private function OnFilterResize(evt:Event): void {
			MoveDropdown();
		}
		
		private function OnFilterMove(evt:Event): void {
			MoveDropdown();
		}
		
		private function OnPickedItemsResize(evt:Event): void {
			MoveDropdown();
		}
		
		public function CompareItems( ob1:Object, ob2:Object ):Boolean {
			return (ob1.label == ob2.label ? true: false);
		}
		
		public function CreateItems( strText:String ):Array {
			// return a new object if it's okay
			return [{label:strText}];
		}
		
		public function GetItemFilterText( ob:Object ):String {
			return ob.label;
		}		
		
	}
}