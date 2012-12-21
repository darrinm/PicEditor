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
package controls.list
{
	import com.adobe.utils.StringUtil;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import mx.collections.CursorBookmark;
	import mx.collections.IViewCursor;
	import mx.controls.scrollClasses.ScrollBar;
	import mx.core.DragSource;
	import mx.core.EdgeMetrics;
	import mx.core.EventPriority;
	import mx.core.IFactory;
	import mx.core.IFlexDisplayObject;
	import mx.core.IUIComponent;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.DragEvent;
	import mx.events.ListEvent;
	import mx.managers.DragManager;
	import mx.managers.IFocusManagerComponent;

	[Event(name="itemClick", type="mx.events.ListEvent")]
	[Event(name="itemDoubleClick", type="mx.events.ListEvent")]
	[Event(name="selectionChange", type="mx.events.ListEvent")]
	
	/**
	 * A PicnikTileListBase with user input including:
	 *  - An enabled limit
	 *  - a selected item (no multi-select, yet)
	 *  - a highlighted item
	 *  - keyboard interaction
	 *  - Mouse interaction:
	 *    - Drag and drop support
	 *    - double click
	 */
	public class PicnikTileList extends PicnikTileListBase implements IFocusManagerComponent
	{
		private var _cEnabledLimit:Number = Number.POSITIVE_INFINITY;
		
		private var _tliHighlighted:ITileListItem = null;
		private var _tliSelectedInternal:ITileListItem = null;
		private var _nSelected:Number = -1;

		private var _obHiddenFocus:Object = null;

		private var _ptMouseDown:Point = null;
		protected var _nDragThreshold:Number = 4;
		
		private var _strSearchPrefix:String = "";
		
	    public var _nDragAlpha:Number = 0.75;
	   
		// Resets search prefix after one second of inactivity
		private static const knResetSearchAfterMilis:Number = 1000;
		
		private var _tmrResetSearchPrefix:Timer = null;

		private var _ifactDragProxyRenderer:IFactory = null;
		
		public function PicnikTileList()
		{
			super();
			 // No default drag image factory _ifactDragProxyRenderer = new ClassFactory(PicnikListItemDragProxy);
	        addEventListener(MouseEvent.MOUSE_OVER, OnMouseOver);
	        addEventListener(MouseEvent.MOUSE_OUT, OnMouseOut);
	        addEventListener(MouseEvent.ROLL_OUT, OnRollOut);
	        addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
	        addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
	        addEventListener(MouseEvent.DOUBLE_CLICK, OnMouseDoubleClick);
	        addEventListener(MouseEvent.CLICK, OnMouseClick);
		}

		//----------------------------------
		//  dragProxyRenderer
		//----------------------------------
		
		public function get dragProxyRenderer():IFactory
		{
			return _ifactDragProxyRenderer;
		}
		
		/**
		 *  @private
		 */
		public function set dragProxyRenderer(ifact:IFactory):void
		{
			_ifactDragProxyRenderer = ifact;
		}
		
		// Data corresponding to selected item
		public function get selectedItem(): Object {
			return indexToItemData(_nSelected);
		}
		
		public function set selectedItem(o:Object):void {
			var tli:ITileListItem = o as ITileListItem;
			if (tli != null)
				MoveHighlight(tli);
		}

		// Returns -1 if nothing is selected.
		public function get selectedIndex(): Number {
			if (!collection) return -1;
			return Math.min(collection.length-1,_nSelected);
		}
		
		public function set selectedIndex(n:Number): void {
			if (selectedIndex == n)
				return;
			var obNewSelectionLoc:Object = IndexToItemLoc(n);
			MoveSelection(ItemLocToItem(obNewSelectionLoc), ItemLocToIndex(obNewSelectionLoc));
			AnimateScrollToLoc(obNewSelectionLoc);
		}
		
		// UNDONE: created as a wrapper for MoveSelection, but the title seems backwards from
		// what it should be -- shouldn't it be selectedItem?  However, that already exists
		// a few lines above and is a wrapper for MoveHighlight.
		public function set highlightedItem(o:Object): void {
			var tli:ITileListItem = o as ITileListItem;
			if (tli != null)
				MoveSelection(tli);
		}
		
		public function indexToItemData(nIndex:Number): Object {
			if (nIndex < 0 || !collection || nIndex > collection.length) return null;
			var csr:IViewCursor = collection.createCursor();
			csr.seek(CursorBookmark.FIRST, nIndex);
			return csr.current;
		}
		
		public function indexToItemRenderer(nIndex:Number): ITileListItem {
			if (nIndex < 0 || !collection || nIndex > collection.length) return null;
			return IndexToItem(nIndex);
		}
		
		/**
		 *  Handles <code>MouseEvent.MOUSE_DOUBLE_CLICK</code> events from any
		 *  mouse targets contained in the list including the renderers.
		 *  This method determines which renderer was clicked
		 *  and dispatches a <code>ListEvent.ITEM_DOUBLE_CLICK</code> event.
		 *
		 *  @param evt The MouseEvent object.
		 */
		// Copied from ListBase
		protected function OnMouseDoubleClick(evt:MouseEvent):void
		{
			var tli:ITileListItem = MouseEventToItem(evt);
			if (!tli)
				return;
			
			var listEvent:ListEvent = new ListEvent(ListEvent.ITEM_DOUBLE_CLICK);
			listEvent.columnIndex = evt.stageX;
			listEvent.rowIndex = evt.stageY;
			listEvent.itemRenderer = tli;
			dispatchEvent(listEvent);
		}

		// Copied from ListBase
		protected function OnMouseClick(evt:MouseEvent):void
		{
			var tli:ITileListItem = MouseEventToItem(evt);
			if (!tli)
				return;
			
			var listEvent:ListEvent = new ListEvent(ListEvent.ITEM_CLICK);
			listEvent.columnIndex = evt.stageX;
			listEvent.rowIndex = evt.stageY;
			listEvent.itemRenderer = tli;
			dispatchEvent(listEvent);
		}


		private function OnMouseUp(evt:MouseEvent): void {
        	if (_ptMouseDown && stage) {
        		_ptMouseDown = null;
        		if (stage)
        			stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnStageMouseMove);
        	}
			removeEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			if (stage)
				stage.removeEventListener(MouseEvent.MOUSE_UP, OnMouseUp);

		}
		
		// Drag support copied form TileListBase/ListBase
		
	    //----------------------------------
	    //  dragEnabled
	    //----------------------------------
	
	    /**
	     *  @private
	     *  Storage for the dragEnabled property.
	     */
	    private var _dragEnabled:Boolean = false;
	
	    /**
	     *  A flag that indicates whether you can drag items out of
	     *  this control and drop them on other controls.
	     *  If <code>true</code>, dragging is enabled for the control.
	     *  If the <code>dropEnabled</code> property is also <code>true</code>,
	     *  you can drag items and drop them within this control
	     *  to reorder the items.
	     *
	     *  @default false
	     */
	    public function get dragEnabled():Boolean
	    {
	        return _dragEnabled;
	    }
	
	    /**
	     *  @private
	     */
	    public function set dragEnabled(value:Boolean):void
	    {
	        if (_dragEnabled && !value)
	        {
	            removeEventListener(DragEvent.DRAG_START, OnDragStart, false);
	            removeEventListener(DragEvent.DRAG_COMPLETE,
	                                OnDragComplete, false);
	        }
	
	        _dragEnabled = value;
	
	        if (value)
	        {
	            addEventListener(DragEvent.DRAG_START, OnDragStart, false,
	                             EventPriority.DEFAULT_HANDLER);
	            addEventListener(DragEvent.DRAG_COMPLETE, OnDragComplete,
	                             false, EventPriority.DEFAULT_HANDLER);
	        }
	    }
	   
	    private function OnDragStart(evt:DragEvent): void {
	        if (evt.isDefaultPrevented())
	            return;
	
			if (evt.target is ScrollBar) return;

			// If the item is disbled (e.g. it is a History entry inaccessable to a non-subscriber)
			// we don't want to let it be drag/dropped.			
			if (_tliSelected && !_tliSelected.enabled)
				return;
			
	        var dragSource:DragSource = new DragSource();
	
	        addDragData(dragSource);
	        var dob:IFlexDisplayObject = dragImage;
	        dragSource.addData(dob, "dragImage");
	
			var fDragMoveEnabled:Boolean = false; // UNDONE: Support dragging within a list

			var ptOffset:Point = dragImageOffset(selectedIndex);

	        DragManager.doDrag(this, dragSource, evt, dob, -ptOffset.x, -ptOffset.y, _nDragAlpha, fDragMoveEnabled);
	    }

	    /**
	     *  Adds the selected items to the DragSource object as part of a
	     *  drag-and-drop operation.
	     *  Override this method to add other data to the drag source.
	     *
	     * @param ds The DragSource object to which to add the data.
	     */
	    private function addDragData(ds:Object):void // actually a DragSource
	    {
	        ds.addHandler(copySelectedItems, "items");
	    }
	    
	    private function OnDragComplete(evt:DragEvent): void {
	    }
	
	    //----------------------------------
	    //  dragImage
	    //----------------------------------
	
	    /**
	     *  Gets an instance of a class that displays the visuals
	     *  during a drag and drop operation.
	     *
	     *  @default PicnikListItemDragProxy
	     */
	    private function get dragImage():IFlexDisplayObject
	    {
	    	var iuic:IFlexDisplayObject = null;
	    	if (_tliSelected && _tliSelected is IDragImageFactory) {
	    		iuic = IDragImageFactory(_tliSelected).CreateDragImage(this);
	    	}
	    	if (!iuic && dragProxyRenderer) {
		        iuic = dragProxyRenderer.newInstance() as IFlexDisplayObject;
		        if ("owner" in iuic) iuic["owner"] = this;
		    }
	        return iuic;
	    }
	
	    //----------------------------------
	    //  dragImageOffsets
	    //----------------------------------
	
	    /**
	     *  Gets the offset of the drag image for drag and drop.
	     */
	    public function dragImageOffset(nIndex:Number):Point
	    {
	    	if (nIndex >= 0) {
	    		var pt:Point = IndexToPoint(nIndex);
	    		pt.x -= actualHorizontalScrollPos;
	    		pt.x += leftElementPadding;
	    		pt.y -= actualVerticalScrollPos;
				var emBorder:EdgeMetrics = borderMetrics;
				if (emBorder) {
					pt.x += emBorder.left;
					pt.y += emBorder.top;
				}
	    	} else {
	    		pt = new Point(0,0);
	    	}
	    	return pt;
	    }
	   
	    public function indexToData(nIndex:Number): Object {
	    	if (nIndex < 0) return null;
	    	var iter:IViewCursor = collection.createCursor();
	    	iter.seek(CursorBookmark.FIRST, nIndex);
	    	if (iter.afterLast) return null;
	    	return iter.current;
	    }
	   

	    /**
	     *  Makes a copy of the selected items in the order they were
	     *  selected.
	     *
	     *  @param useDataField <code>true</code> if the array should
	     *  be filled with the actual items or <code>false</code>
	     *  if the array should be filled with the indexes of the items
	     *
	     *  @return array of selected items
	     */
	    public function copySelectedItems(fUseDataField:Boolean = true):Array
	    {
	        var aOb:Array = [];
	        if (_nSelected > -1) {
	            if (fUseDataField) {
		    		var iterSelected:IViewCursor = collection.createCursor();
		    		iterSelected.seek(CursorBookmark.FIRST, _nSelected);
		    		if (!iterSelected.afterLast) {
		                aOb.push(iterSelected.current);
		      		}
	            } else {
	                aOb.push(_nSelected);
	            }
	        }
	        return aOb;
	    }
	   
	    // Change the selection to reflect a change in the collection
		private function UpdateSelection(nStartLoc:Number, cItems:Number, fReplace:Boolean = false): void {
			if (_nSelected < nStartLoc) return;
			if (fReplace) {
				if (_nSelected < (cItems + nStartLoc)) {
					MoveSelection(null); // Selected item was replaced
				}
			} else {
				// Insert/remove
				var nNewIndex:Number = _nSelected + cItems;
				if (nNewIndex < nStartLoc) {
					MoveSelection(null); // Selected item was removed
				} else {
					// Selected item index changed, but the item did not
					MoveSelection(IndexToItem(nNewIndex), nNewIndex);
				}
			}
		}

		// Update the selection and enabled when the collection changes
	    override protected function CollectionChangeHandler(evt:CollectionEvent):void {
	    	super.CollectionChangeHandler(evt);
	    	if (evt.kind == CollectionEventKind.UPDATE) {
	    		return;
	    	}
			MoveHighlight(null);
			if (evt.kind == CollectionEventKind.ADD) {
	    		UpdateSelection(evt.location, evt.items.length);
	    	} else if (evt.kind == CollectionEventKind.REMOVE) {
	    		UpdateSelection(evt.location, -evt.items.length);
	    	} else if (evt.kind == CollectionEventKind.REPLACE) {
	    		UpdateSelection(evt.location, evt.items.length, true);
	    	} else {
				MoveSelection(null);
			}
			UpdateEnabled(evt.location, collection.length - evt.location);
		}
		
		// set to NaN or Number.POSITIVE_INFINITY for infinite (default)
		public function set enabledLimit(n:Number): void {
			if (n < 0) n = Number.POSITIVE_INFINITY;
			if (_cEnabledLimit != n) {
				var nPrev:Number = _cEnabledLimit;
				var nCollectionLength:Number = collection ? collection.length : Number.POSITIVE_INFINITY; 
				if (isNaN(nPrev)) nPrev = Number.POSITIVE_INFINITY;
				_cEnabledLimit = n;
				nPrev = Math.max(nPrev, nCollectionLength);
				var nNew:Number = Math.max(n, nCollectionLength);
				if (nPrev > nNew) UpdateEnabled(nNew, nPrev - nNew);
				else UpdateEnabled(nPrev, nNew - nPrev);
			}
		}
		
		// Update the enabled state of a set of items
		private function UpdateEnabled(nStartIndex:Number, cItems:Number): void {
			// We need a way to walk the items and apply a function
			var fnUpdateEnabled:Function = function(tli:ITileListItem, nIndex:Number): void {
				tli.enabled = nIndex < _cEnabledLimit;
			}
			ItemApply(fnUpdateEnabled, nStartIndex, cItems);
		}
		
		// Make sure we update the selection when an item is removed from the visible area
	    override protected function OnItemRemoved(tli:ITileListItem): void {
	    	if (tli && tli == _tliSelected) {
	    		_tliSelected = null;
	    	}
	    	if (tli && tli == _tliHighlighted) {
	    		MoveHighlight(null);
	    	}
	    }

		private function set _tliSelected(tliSelected:ITileListItem): void {
			if (_tliSelectedInternal != tliSelected) {
				_tliSelectedInternal = tliSelected;
				dispatchEvent(new ListEvent("selectionChange", false, false, -1, -1, null, _tliSelectedInternal));
			}
		}
		
		private function get _tliSelected(): ITileListItem {
			return _tliSelectedInternal;
		}
	   
	    // Make sure we update the selection and enabled states when an item is added to the visible area
	    override protected function OnItemInserted(tli:ITileListItem, nIndex:Number): void {
	    	// Now we have the item and its index. Update its state.
	    	var fEnabled:Boolean = isNaN(_cEnabledLimit) || (_cEnabledLimit > nIndex);
	    	var fSelected:Boolean = nIndex == _nSelected;
	    	tli.setState(tli == _tliHighlighted, fSelected, fEnabled);
	    	if (fSelected) _tliSelected = tli;
	    }
	   
		private function MoveHighlight(tli:ITileListItem): void {
		    if (tli != _tliHighlighted)
		    {
		    	if (_tliHighlighted) _tliHighlighted.highlighted = false;
		    	_tliHighlighted = tli;
		    	if (_tliHighlighted) _tliHighlighted.highlighted = true;
		    }
		}

		// Select/deselect an item
		protected function ApplySelection(tli:ITileListItem, fSelected:Boolean): void {
			if (!tli) return;
			if (tli is IFocusManagerComponent) {
				(tli as IFocusManagerComponent).drawFocus(fSelected);
			} else {
				tli.selected = fSelected;
			}
		}

		// Select a different item
		private function MoveSelection(tli:ITileListItem, nIndex:Number=-1): void {
		    if (tli != _tliSelected || nIndex != _nSelected)
		    {
		    	// if (_tliSelected) _tliSelected.selected = false;
		    	ApplySelection(_tliSelected, false);
		    	
		    	_nSelected = tli ? ItemToIndex(tli) : nIndex;
		    	_tliSelected = tli;
		    	//if (_tliSelected) _tliSelected.selected = true;
		    	ApplySelection(_tliSelected, true);
			}
		}
		
		// Move the selection by a row/tile count
		// Includes smarts for wrapping rows and tiles
		// Used for handling keyboard events
		protected function MoveSelectionBy(obMove:Object): void {
			// First, move tiles, then lines, finally get an index
			if (_nSelected == -1) return; // Nothing to start with
			var obItemLocSelected:Object = IndexToItemLoc(_nSelected);
			var nXOff:Number = ('x' in obMove) ? Math.round(obMove.x / columnWidth) : 0;
			var nYOff:Number = ('y' in obMove) ? Math.round(obMove.y / rowHeight) : 0;
			
			var nTileOffset:Number = vertical ? nXOff : nYOff;
			var nLineOffset:Number =  vertical ? nYOff : nXOff;
			
			var nTile:Number = obItemLocSelected.nTile + nTileOffset;
			var nLine:Number = obItemLocSelected.nLine + Math.floor(nTile / tilesPerLine);
			
			var obNewSelectionLoc:Object = null;
			if (nTile == Number.POSITIVE_INFINITY || nLine == Number.POSITIVE_INFINITY) {
				// Go to the end
				obNewSelectionLoc = IndexToItemLoc(collection.length-1);
			} else if (nTile == Number.NEGATIVE_INFINITY || nLine == Number.NEGATIVE_INFINITY) {
				// Go to the head
				obNewSelectionLoc = IndexToItemLoc(0);
			} else {
				nTile = nTile % tilesPerLine;
				if (nTile < 0) nTile += tilesPerLine;
				nLine += nLineOffset;
				
				// Now make sure nLine isn't beyond the end.
				obNewSelectionLoc = {nTile:nTile, nLine:nLine};
				var nNewIndex:Number = ItemLocToIndex(obNewSelectionLoc);
				if ((nNewIndex < 0) || (nNewIndex >= collection.length)) {
					if (nNewIndex < 0) {
						if (nTileOffset != 0) {
							nNewIndex = 0; // If we are scrolling tiles, stop at index zero
						} else {
							// If we are scrolling lines, stop at line zero in the current tile.
							nNewIndex = nNewIndex % tilesPerLine;
							if (nNewIndex < 0) nNewIndex += tilesPerLine;
						}
					} else { // beyond the end
						if (nTileOffset != 0) {
							nNewIndex = collection.length-1; // Stop at the end if we are scrolling tilesw
						} else {
							// Stop at the last line in the current tile
							nNewIndex -= Math.ceil((1 + nNewIndex - collection.length) / tilesPerLine) * tilesPerLine;
						}
					}
					obNewSelectionLoc = IndexToItemLoc(nNewIndex);
				}
			}

			MoveSelection(ItemLocToItem(obNewSelectionLoc), ItemLocToIndex(obNewSelectionLoc));
			AnimateScrollToLoc(obNewSelectionLoc);
		}
		
		// Animate scroll to show a location (e.g. the selected item)
		private function AnimateScrollToLoc(obLoc:Object): void {
			if (!obLoc) return;
			
			var pt:Point = ItemLocToPoint(obLoc);
			var nItemLineTopXY:Number = vertical ? pt.y : pt.x;
			
			if (nItemLineTopXY < actualScrollPosition) {
				AnimateScrollTo(nItemLineTopXY);
			} else {
				// Put the bottom of the item at the bottom of the screen
				// scroll = yTop + rowHeight - screenHeight
				var nScroll:Number = nItemLineTopXY + lineSize - contentLineSize;

				// Don't scroll if we end up scrolling up
				if (nScroll > actualScrollPosition) {
					AnimateScrollTo(nScroll);
				}
			}
		}
		
		private function OnStageMouseMove(evt:MouseEvent): void {
			// See if we are dragging
			if (evt.buttonDown && _ptMouseDown && !DragManager.isDragging) {
		        var pt:Point = new Point(evt.localX, evt.localY);
		        pt = DisplayObject(evt.target).localToGlobal(pt);
		        pt = globalToLocal(pt);
	            if (Math.abs(_ptMouseDown.x - pt.x) > _nDragThreshold ||
	             		Math.abs(_ptMouseDown.y - pt.y) > _nDragThreshold) {
	                var dragEvent:DragEvent = new DragEvent(DragEvent.DRAG_START);
	                dragEvent.dragInitiator = this;
	                dragEvent.localX = _ptMouseDown.x;
	                dragEvent.localY = _ptMouseDown.y;
	                dragEvent.buttonDown = true;
	                dispatchEvent(dragEvent);
	                _ptMouseDown = null;
	                stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnStageMouseMove);
				}
			}
		}
		
		private function OnMouseMove(evt:MouseEvent):void
		{
		    MoveHighlight(MouseEventToItem(evt));
		}
		
		private function IsMyScrollBar(dobTarg:DisplayObject): Boolean {
			var fIsScrollBar:Boolean = false;
			
			while (dobTarg && dobTarg != this && !fIsScrollBar) {
				fIsScrollBar = dobTarg == scrollBar;
				dobTarg = dobTarg.parent;
			}
			return fIsScrollBar;
		}
		
		private function OnMouseDown(evt:MouseEvent):void
		{
			addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			
	        if (IsMyScrollBar(evt.target as DisplayObject)) {
	        	if (_ptMouseDown && stage) {
	        		_ptMouseDown = null;
	        		stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnStageMouseMove);
	        	}
	        } else {
				var tli:ITileListItem = MouseEventToItem(evt);
				if (tli) {
					MoveSelection(tli);
			        var pt:Point = new Point(evt.localX, evt.localY);
			        pt = DisplayObject(evt.target).localToGlobal(pt);
		        	_ptMouseDown = globalToLocal(pt);
	        		stage.addEventListener(MouseEvent.MOUSE_MOVE, OnStageMouseMove);
				}
	        }
		}
		
		private function OnMouseOut(evt:MouseEvent):void
		{
		    MoveHighlight(MouseEventToItem(evt));
		}
		
		private function OnRollOut(evt:MouseEvent):void
		{
		    MoveHighlight(null);
		}
		
		private function OnMouseOver(evt:MouseEvent): void {
			OnMouseMove(evt);
		}
		
		// Find the item associated with a mouse event
		private function MouseEventToItem(evt:MouseEvent): ITileListItem {
			// Based on mouse event handler in TileListBase
			var tli:ITileListItem = null;
			
		    var dobTarget:DisplayObject = DisplayObject(evt.target);

			// If the target is this or the list content, use the position to find the item
		    if (dobTarget == _livListContent || dobTarget == this)
		    {
		        var pt:Point = new Point(evt.stageX, evt.stageY);
		        pt = _livListContent.globalToLocal(pt);
		       
		        tli = PointToItem(pt);
		    }
		
			// If the target is a child of this or the list content, walk up the tree
			// until we find a tile list item
		    while (dobTarget && dobTarget != this)
		    {
		        if (dobTarget is ITileListItem && dobTarget.parent == _livListContent)
		        {
		            if (dobTarget.visible)
		                return ITileListItem(dobTarget);
		            break;
		        }
		
				if (dobTarget is IUIComponent)
					dobTarget = IUIComponent(dobTarget).owner;
				else
					dobTarget = dobTarget.parent;
		    }
		
			return tli;
		}
		
		// Convert a key to a move object (delta x and delta y)
		private function KeyToMove(nKeyCode:uint): Object {
			switch(nKeyCode) {
				case Keyboard.DOWN:
					return {y:rowHeight};
				case Keyboard.UP:
					return {y:-rowHeight};
				case Keyboard.RIGHT:
					return {x:+columnWidth};
				case Keyboard.LEFT:
					return {x:-columnWidth};
				case Keyboard.END:
					return {y:Number.POSITIVE_INFINITY, x:Number.POSITIVE_INFINITY};
				case Keyboard.HOME:
					return {y:Number.NEGATIVE_INFINITY, x:Number.NEGATIVE_INFINITY};
				case Keyboard.PAGE_DOWN:
					// Change this if we do not want pagedown scrolling horizontal lists
					return vertical ? {y:verticalPageScrollSize} : {x:horizontalPageScrollSize};
				case Keyboard.PAGE_UP:
					// Change this if we do not want pageup scrolling horizontal lists
					return vertical ? {y:-verticalPageScrollSize} : {x:-horizontalPageScrollSize};
				case Keyboard.SPACE:
					return {y:0};
				default:
					break;
			}
			return null;
		}

		// Find an item whose title starts with this string starting with the current selected item (or the head)
		// Ignores white space and case
		private function FindString(str:String): Boolean {
			// Start with the selected item (or the head) and move to the first item with a title
			// prefix which matches that which we are looking for
			
			if (!collection) return false;
			
			var nIndex:Number = Math.min(Math.max(0, _nSelected), collection.length-1);
			var iterSearch:IViewCursor = collection.createCursor();
			iterSearch.seek(CursorBookmark.FIRST, nIndex);
			while (true) {
				if (iterSearch.afterLast) return false;
				var obData:Object = iterSearch.current;
				if (obData) {
					if ('title' in obData && obData['title'] != null) {
						var strTitle:String = obData['title'];
						strTitle = strTitle.replace(/[ \r\n\t]*/g,''); // Remove white space
						strTitle = strTitle.toUpperCase();
						if (StringUtil.beginsWith(strTitle, str)) {
							// Found it.
							break;
						}
					}
				}
				nIndex += 1;
				iterSearch.moveNext();
			}
			// If we got here, we found it at position nIndex
			MoveSelection(IndexToItem(nIndex), nIndex);
			AnimateScrollToLoc(IndexToItemLoc(nIndex));
			return true;
		}
		
		// Initiate a find based on a user key press
	    private function FindKey(nKeyCode:int):Boolean
	    {
    		
	    	// Copied from ListBase. Not sure why they create the temp code.
	        var nTmpCode:int = nKeyCode;
	        if (nTmpCode < 33) return false;
	        if (nTmpCode > 126) return false;

	    	if (_tmrResetSearchPrefix == null) {
	    		_tmrResetSearchPrefix = new Timer(knResetSearchAfterMilis,1);
	    		_tmrResetSearchPrefix.addEventListener(TimerEvent.TIMER, function (evt:Event):void {_strSearchPrefix="";});
	    	} else {
	    		_tmrResetSearchPrefix.stop();
	    		_tmrResetSearchPrefix.reset();
	    	}
    		_tmrResetSearchPrefix.start(); // Clear our search prefix after one minute
    		
    		_strSearchPrefix += String.fromCharCode(nTmpCode);
            return FindString(_strSearchPrefix);
	    }
	   
	    // Hanlde user key presses
	    // Four options:
	    // 1. Move the selection
	    // 2. Move the view without changing the selection (ctrl + direction)
	    // 3. Search by title (non-direction key)	   
	    // 4. Open the selected item (enter key)
		override protected function keyDownHandler(evt:KeyboardEvent):void {
			if (!collection) return;
			
			var obMove:Object = KeyToMove(evt.keyCode);
			
			if (obMove) {
				// Do something with the move
				if (evt.ctrlKey) {
					// Move the window, not the selection
					var nScrollDelta:Number = 0;
					if (vertical && ('y' in obMove))
						nScrollDelta = obMove.y;
					else if ('x' in obMove)
						nScrollDelta = obMove.xy;
					if (nScrollDelta != 0)
						AnimateScroll(nScrollDelta);
				} else {
					// Move the selection and scroll to show it.
					MoveSelectionBy(obMove);
				}
				if (evt.keyCode != Keyboard.SPACE)
					_strSearchPrefix="";
				evt.stopPropagation();
			} else {
				if (!evt.ctrlKey) {
					// Try a find based on what the user is typing
					if (FindKey(evt.keyCode)) {
						evt.stopPropagation();
					}
				}
			}
		}
		
		// Helper functions
		private function get tilesPerLine(): Number {
			return _livListContent.tilesPerLine;
		}
		
		public function IndexToItemLoc(nIndex:Number): Object {
			return _livListContent.IndexToItemLoc(nIndex);
		}

	    private function IndexToPoint(nIndex:Number): Point {
			return _livListContent.IndexToPoint(nIndex);
	    }
	   
	    private function ItemLocToIndex(obLoc:Object): Number {
	    	return _livListContent.ItemLocToIndex(obLoc);
	    }
	   
	    private function ItemLocToItem(obItemLoc:Object): ITileListItem {
	    	return _livListContent.ItemLocToItem(obItemLoc);
	    }
	   
	    private function ItemLocToPoint(obLocation:Object): Point {
	    	return _livListContent.ItemLocToPoint(obLocation);
	    }
	   
	    private function PointToItem(pt:Point): ITileListItem {
	    	return _livListContent.PointToItem(pt);
	    }
	   
	    private function IndexToItem(nIndex:Number): ITileListItem {
	    	return _livListContent.IndexToItem(nIndex);
	    }
	   
	    private function ItemToIndex(tli:ITileListItem): Number {
	    	return _livListContent.ItemToIndex(tli);
	    }
	   
	}
}
