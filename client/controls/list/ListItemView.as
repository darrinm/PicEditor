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
	import controls.list.util.PendingList;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.collections.CursorBookmark;
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.core.IFactory;
	import mx.core.UIComponent;
	import mx.effects.Effect;
	import mx.effects.Move;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	/*** ListItemView
	 * This a visible collection of list items
	 * It manages changes to the layout
	 * It keeps list items in "lines" (perpendicular to scroll direction)
	 * This gives us a 2d way to access visible items,
	 * reducing random access time for large lists.
	 */

	public class ListItemView extends UIComponent
	{
		public function ListItemView()
		{
			super();
			addEventListener(Event.DEACTIVATE, OnDeactivate);
		}
		
		private var _nTopBorder:Number = 0;
		private var _nLeftBorder:Number = 0;
		
	    private var _nRowHeight:Number = 100;
	    private var _nColumnWidth:Number = 100;
	   
	    private var _dtLastActivity:Date = new Date();
	    private static const knMinInactiveTimeForBackgroundTasks:Number = 500;
	    private static const knMinInactiveTimeToReleasePending:Number = 1000 * 60;

		// item renderer
		private var _itmr:IFactory = null;
		
		// The data provider
	    private var _collection:ICollectionView;
	   
	    // True for a vertical scroll bar, false for horizontal
	    private var _fVertical:Boolean = true;
	   
	    // The list of visible lines (perpendicular to scroll direction)
	    private var _aobVisibleLines:Array = [];
	   
	    // A list of free items for reuse
	    private var _aobFreeItems:Array = [];
	   
	    // Display states
	    private static const VALID:Number = 0; // Everything is OK
	    private static const SCROLL_INVALID:Number = 1;  // Need to adjust scroll position
	    private static const ALL_INVALID:Number = 3;  // Need to relayout everything
	   
	    private var _nLayoutValidity:Number = ALL_INVALID;
	   
	    private var _fReadyToCreateChildren:Boolean = false;
	   
	    private var _tmrCreateResources:Timer = null;
	   
	    private var _plPending:PendingList = new PendingList();
	    private static const knMaxPending:Number = 100;

		private var _fSlowLoad:Boolean = false;
		
		private var _fAnimateRelayout:Boolean = false;
	    private var _dctActiveEffects:Dictionary = new Dictionary();
	   
	    public var animationDuration:Number = 400;
		
		public function set topBorder(n:Number): void {
			var yScrollPrev:Number = yScroll;
			_nTopBorder = n;
			yScroll = yScrollPrev;
		}
		public function get topBorder(): Number {
			return _nTopBorder;
		}

		public function set slowLoad(f:Boolean): void {
			_fSlowLoad = f;
			createTimer();
		}
		public function get slowLoad(): Boolean {
			return _fSlowLoad;
		}
		
		public function set leftBorder(n:Number): void {
			var xScrollPrev:Number = xScroll;
			_nLeftBorder = n;
			xScroll = xScrollPrev;
		}
		public function get leftBorder(): Number {
			return _nLeftBorder;
		}
	   
	    public function get hasMouse():Boolean {
	    	return (mouseX >= 0 && mouseY >= 0 && mouseX <= width && mouseY <= height);
	    }
	   
	    private function RemoveExtraPending(): void {
	    	while (_plPending.length > knMaxPending) {
	    		_plPending.RemoveLast(_aobFreeItems);
	    	}
	    }
	   
	    override protected function createChildren():void {
	    	super.createChildren();
	    	_fReadyToCreateChildren = true;
	    	invalidateDisplayList();
	    	if (!_tmrCreateResources)
	    		createTimer();
	    }

		private function createTimer(): void {
			if (_tmrCreateResources) {
				_tmrCreateResources.stop();
				_tmrCreateResources.removeEventListener(TimerEvent.TIMER, OnCreateResourcesTimer);
			}

    		_tmrCreateResources = new Timer(_fSlowLoad ? 200 : 100);
    		_tmrCreateResources.addEventListener(TimerEvent.TIMER, OnCreateResourcesTimer);
    		_tmrCreateResources.start();
		}

	   
	    private var _fListeningForMouse:Boolean = false;
	    private var _fMouseDown:Boolean = false;
	  
		private function OnStageMouseDown(evt:MouseEvent): void {
			_fMouseDown = true;
		}
	   
		private function OnStageMouseUp(evt:MouseEvent): void {
			_fMouseDown = false;
		}
	   
	    private function OnCreateResourcesTimer(evt:TimerEvent): void {
	    	if (!stage) return;
    		if (!_fListeningForMouse) {
    			_fListeningForMouse = true;
    			stage.addEventListener(MouseEvent.MOUSE_DOWN, OnStageMouseDown, true);
    			stage.addEventListener(MouseEvent.MOUSE_UP, OnStageMouseUp, true);
    			return;
    		}
	    	if (_fMouseDown) return;

	    	if (_nLayoutValidity != VALID) return;
	    	if (!_itmr) return;
	    	var nTimeSinceLastActivity:Number = new Date().time - _dtLastActivity.time;
	    	if (stage && nTimeSinceLastActivity > knMinInactiveTimeForBackgroundTasks && hasMouse) {
	    		var nExtraNeeded:Number = knMaxPending + (vertical ? fixedColumns * (visibleRows+1): fixedRows * (visibleColumns+1));
	    		nExtraNeeded -= numChildren;
	    		if (nExtraNeeded > 0) {
	    			nExtraNeeded = Math.min(nExtraNeeded, _fSlowLoad ? 1 : 2); // Only create 1 or 2 at a time, this is very slow
	    			for (var i:Number = 0; i < nExtraNeeded; i++) {
	    				var dob:DisplayObject = _itmr.newInstance();
	    				dob.visible = false;
	    				super.addChild(dob);
	    				_aobFreeItems.push(dob);
	    			}
	    		}
	    	}
	    	if (nTimeSinceLastActivity > knMinInactiveTimeToReleasePending && _plPending.length > 0) {
	    		// Free pending items to release image memory
	    		_plPending.RemoveAll(_aobFreeItems);
	    	}
	    }

		override public function addChild(child:DisplayObject):DisplayObject {
			throw new Error("Do not call addChild directly");
		}

		override public function removeChild(child:DisplayObject):DisplayObject {
			throw new Error("Do not call removeChild directly");
		}
		
		override public function removeChildAt(index:int):DisplayObject {
			throw new Error("Do not call removeChildAt directly");
		}
		
		// Returns true if we have items in our lines.
		// May be false if we are waiting to update a layout.
		public function get hasItems(): Boolean {
	    	return _aobVisibleLines.length > 0 && _aobVisibleLines[0].aobTiles.length > 0;
		}
		
 		// x position is synonymous with horizontal scroll (negative position => scroll down)
		public override function set x(value:Number): void {
			if (super.x == value) return;
			super.x = value;
			InvalidateLayout(true);
		}
		public override function get x(): Number {
			return super.x;
		}

		public function get xScroll():Number {
			return Math.min(0,x - leftBorder);
		}
		
		public function set xScroll(n:Number): void {
			x = n + leftBorder;
		}
		
		public function get yScroll():Number {
			return Math.min(0,y - topBorder);
		}
		
		public function set yScroll(n:Number): void {
			y = n + topBorder;
		}
		
		// y position is synonymous with vertical scroll (negative value => scroll down)
		public override function set y(value:Number): void {
			if (super.y == value) return;
			InvalidateLayout(true);
			super.y = value;
		}
		public override function get y(): Number {
			return super.y;
		}
		
		public override function set width(value:Number): void {
			if (super.width != value) {
				super.width = value;
				InvalidateLayout();
			}
		}
		public override function get width(): Number {
			return super.width;
		}
		
		public override function set height(value:Number): void {
			if (super.height != value) {
				super.height = value;
				InvalidateLayout();
			}
		}
		public override function get height(): Number {
			return super.height;
		}
		
		public function set itemRenderer(itmr:IFactory): void {
			_itmr = itmr;
			ClearAll();
			InvalidateLayout();
			
		}

		public function get itemRenderer(): IFactory {
			return _itmr;
		}
		
	    // Remove all item renders and set them to null, remove them from our free list.
	    // Call this when all of our items are invalid (e.g. the item renderer changed)
	    // The free list will be cleared.
	    private function ClearAll(): void {
	    	RemoveAllItems();
	    	_plPending.RemoveAll(_aobFreeItems);
	    	while (_aobFreeItems.length > 0) _aobFreeItems.pop();
	    }
	
	    // Move all items to our free list.
	    // Call this when we need to relayout everything and we can't reuse indexes
	    private function RemoveAllItems(): void {
    		while (_aobVisibleLines.length > 0) {
    			var obLine:Object = _aobVisibleLines.pop();
    			for each (var dob:DisplayObject in obLine.aobTiles) {
    				RemoveItem(dob);
    			}
    		}
	    }
	   
	    public function set collection(value:ICollectionView):void
	    {
	    	_collection = value;
	    	RemoveAllItems();
	    	InvalidateLayout();
	    }
	   
	    // This gets called by the container whenever the collection changes
	    // Update the layout accordingly.
	    public function CollectionChanged(evt:CollectionEvent): void {
	    	// How do we handle this?
	    	if (evt.kind == CollectionEventKind.ADD) {
	    		UpdateCollection(evt.location, evt.items.length);
	    	} else if (evt.kind == CollectionEventKind.REMOVE) {
	    		UpdateCollection(evt.location, -evt.items.length);
	    	} else if (evt.kind == CollectionEventKind.REPLACE) {
	    		UpdateCollection(evt.location, evt.items.length, true);
	    	} else if (evt.kind == CollectionEventKind.MOVE) {
	    		var iFirst:Number = Math.min(evt.location, evt.oldLocation);
	    		var cItems:Number = Math.abs(evt.location - evt.oldLocation);
	    		UpdateCollection(iFirst, cItems, false, evt.oldLocation, evt.location);
	    	} else if (evt.kind == CollectionEventKind.UPDATE) {
	    		// Ignore updates
	    		return;
	    	} else {
	    		RemoveAllItems(); // Don't mess around with trying to keep a pending list.
	    		InvalidateLayout();
	    	}
	    }
	   
	    // Something changed. Try to be smart about moving things to pending and then
	    // updating the pending list.
	    // For example, if we are adding an item to the list, we move everything to our
	    // pending list, then update the indexes on the pending list to accomodate the
	    // new item. When we relayout, most of our items will come off the pending list.
	    // Supports insert, delete, and replace.
	    private function UpdateCollection(nInsertAt:Number, cItems:Number, fReplace:Boolean=false, iMoveFrom:Number=-1, iMoveTo:Number=-1): void {
	    	var nLastIndex:Number = -1;
	    	if (_aobVisibleLines && _aobVisibleLines.length > 0) {
	    		var obLastLine:Object = _aobVisibleLines[_aobVisibleLines.length-1];
	    		nLastIndex = obLastLine.nIndex + obLastLine.aobTiles.length - 1;
	    		var nFirstIndex:Number = firstLine.nIndex;
	    		nLastIndex = Math.max(nLastIndex, nFirstIndex + (vertical ? fixedColumns * (visibleRows+1): fixedRows * (visibleColumns+1)));
	    		if (nLastIndex < nInsertAt) return;
	    	}
	    	cItems = Math.round(cItems); // Make sure we aren't adding fractional amounts
	    	if (cItems != 0) {
	    		MoveAllItemsToPending();
	    		if (iMoveFrom >= 0 && iMoveTo >= 0)
		    		_plPending.UpdateIndicesForMove(iMoveFrom, iMoveTo);
	    		else
		    		_plPending.UpdateIndices(nInsertAt, cItems, _aobFreeItems, fReplace);
	    		InvalidateLayout(false, cItems < 5);
	    	}
	    }
	   
	    private function get isReady(): Boolean {
	    	return _collection && _itmr && _fReadyToCreateChildren;
	    }
	   
	    private function get firstLine(): Object {
	    	return _aobVisibleLines[0];
	    }
	   
	    private function get numLines(): Number {
	    	return _aobVisibleLines.length;
	    }
	   
	    // Call this when we change the start or size in the line dimension
	    // Assumes that nothing else has changed.
	    private function DoScroll(): void {
	    	if (!isReady) return;
	    	// trace("DoScroll: " + _nPrevScroll + ", " + scrollPosition);
	    	
	    	// Do some math to calculate the line area which is no longer visible
	    	// as well as the line area which is now visible

			// First, get our previous start and height and our new start and height	    	
	    	var nPrevStart:Number;
	    	var nPrevSize:Number;
	    	if (hasItems) {
	    		nPrevStart = vertical ? firstLine.y : firstLine.x;
	    		nPrevSize = numLines * lineSize;
	    	} else {
	    		nPrevStart = 0;
	    		nPrevSize = 0;
	    	}
	    	var nPrevEnd:Number = nPrevStart + nPrevSize - 1;
	    	
	    	var nNewStart:Number = vertical ? -yScroll : -xScroll;
	    	var nNewSize:Number = vertical ? height : width;
	    	var nNewEnd:Number = nNewStart + nNewSize - 1;

	    	if (nNewStart > nPrevStart) {
	    		// Remove lines at the beginning
	    		FreeLinesAbove(nNewStart);
	    	}
	    	if (nNewEnd < nPrevEnd) {
	    		// Remove lines at the end
	    		FreeLinesBelow(nNewEnd);
	    	}
	    	
	    	if (!hasItems) {
	    		CreateAllLines();
	    	} else {
		    	if (nNewStart < nPrevStart) {
		    		InsertLinesOverlapping(nNewStart, Math.min(nPrevStart-1, nNewEnd), true);
		    	}
		    	if (nNewEnd > nPrevEnd) {
		    		InsertLinesOverlapping(Math.max(nPrevEnd+1, nNewStart), nNewEnd, false);
		    	}
	    	}
	    	_nLayoutValidity = _nLayoutValidity & ~SCROLL_INVALID;
	    }

	    protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
	    	ValidateLayout();
	    	super.updateDisplayList(unscaledWidth, unscaledHeight);
	    }
	   
	    [Bindable]
	    public function set rowHeight(n:Number): void {
	    	if (_nRowHeight == n) return;
	    	_nRowHeight = n;
	    	InvalidateLayout();
	    }
	   
	    public function get rowHeight(): Number {
	    	return _nRowHeight;
	    }
	   
	    [Bindable]
	    public function set columnWidth(n:Number): void {
	    	if (_nColumnWidth == n) return;
	    	_nColumnWidth = n;
	    	InvalidateLayout();
	    }
	   
	    public function get columnWidth(): Number {
	    	return _nColumnWidth;
	    }

    	[Bindable]
	    public function get vertical(): Boolean {
	    	return _fVertical;
	    }
	   
	    public function set vertical(f:Boolean): void {
	    	if (_fVertical != f) {
		    	_fVertical = f;
		    	InvalidateLayout();
		    }
	    }
	   
	    private function InvalidateLayout(fScrollOnly:Boolean=false, fAnimateRelayout:Boolean=false): void {
	    	_fAnimateRelayout = fAnimateRelayout;
	    	_nLayoutValidity = _nLayoutValidity | (fScrollOnly ? SCROLL_INVALID : ALL_INVALID);
	    	invalidateDisplayList();
	    }
	   
	    private function ValidateLayout(): Boolean {
	    	if (!isReady) return false;
	    	if (_nLayoutValidity != VALID) {
	    		_dtLastActivity = new Date();
	    		if (_nLayoutValidity == SCROLL_INVALID) {
	    			DoScroll();
	    		} else {
		    		DoLayout();
		    	}
	    	}
	    	return true;
	    }
	   
	    private function DoLayout(): void {
	    	if (!isReady) return;
	    	_nLayoutValidity = VALID;
	    	MoveAllItemsToPending();
	    	CreateAllLines();
	    	_plPending.HideAll();
	    	RemoveExtraPending();
	    }
	   
	    // Remove an item from the display and put it on our free list
	    private function RemoveItem(dob:DisplayObject): void {
			// trace("Removing object " + dob['data'].id + "[" + dob['data'].title + "] at position: " + dob.x + ", " + dob.y);	    	
			dob.visible = false;
	    	dob['data'] = null;
	    	_aobFreeItems.push(dob);
	    	dispatchEvent(new ListItemEvent("item_removed", ITileListItem(dob) ));
	    }
	   
	    // Take all items out of our lines and move them to pending.
	    // Call this when doing a relayout, e.g. when the items change size or the screen is resized
	    private function MoveAllItemsToPending(): void {
	    	for each (var obLine:Object in _aobVisibleLines) {
	    		var nIndex:Number = obLine.nIndex;
	    		for each (var obTile:Object in obLine.aobTiles) {
	    			_plPending.Enqueue(obTile as ITileListItem, nIndex.toString(), _aobFreeItems);
	    			nIndex++;
	    		}
	    	}
	    	_aobVisibleLines.length = 0;
	    }
	   
	    // Remove all lines above/left of a point
   		private function FreeLinesAbove(nTopPixel:Number): void {
   			if (_aobVisibleLines.length > 0) {
   				// Find the line
   				// Start with the first line
   				var nRemoveAbove:Number = AbsoluteToRelativeLineNumber(Math.floor(nTopPixel/lineSize));
   				FreeLines(0, nRemoveAbove - 1);
   			}
   		}

		// Remove all lines below/right of a point
   		private function FreeLinesBelow(nBottomPixel:Number): void {
   			if (_aobVisibleLines.length > 0) {
   				// Find the line
   				// Start with the first line
   				var nRemoveBelow:Number = AbsoluteToRelativeLineNumber(Math.floor(nBottomPixel/lineSize));
   				FreeLines(nRemoveBelow + 1, _aobVisibleLines.length);
   			}
   		}
   		
   		// Given an absolute line number (from the top of the list) calculate
   		// the line number relative to the first visible line (line 0)
   		private function AbsoluteToRelativeLineNumber(nAbsoluteLineNumber:Number): Number {
   			var obFirstLoc:Object = PointToItemLoc(new Point(0,0));
   			return obFirstLoc.nLine + nAbsoluteLineNumber;
   		}

		// Remove one or more lines and move them to hte free list
	    private function FreeLines(nFirstRemove:Number, nLastRemove:Number): void {
	    	if (nFirstRemove > nLastRemove) return;
	    	if (nFirstRemove >= _aobVisibleLines.length) return;
	    	if (nLastRemove < 0) return;
	    	nFirstRemove = Math.max(0, nFirstRemove);
	    	nLastRemove = Math.min(_aobVisibleLines.length - 1, nLastRemove);
	    	// Now we know that first and last remove are within bounds
	    	for (var i:Number = nFirstRemove; i <= nLastRemove; i++) {
	    		var obLine:Object = _aobVisibleLines[i];
	    		var nIndex:Number = obLine.nIndex;
	    		for each (var tli:ITileListItem in obLine.aobTiles) {
	    			if (tli.isLoaded()) {
		    			_plPending.Enqueue(tli, nIndex.toString(), _aobFreeItems);
		    		} else {
		    			RemoveItem(DisplayObject(tli));
		    		}
	    			nIndex++;
		    	}
		    }
		    _aobVisibleLines.splice(nFirstRemove, nLastRemove - nFirstRemove + 1);
		    RemoveExtraPending();
			_plPending.HideAll();
	    }
	   
	    // Add an item.
	    // Will try to, in order:
	    //  1. Reuse a pending item
	    //  2. Reuse a free item
	    //  3. Create a new item
	    private function InsertNewItem(xx:Number, yy:Number, data:Object, nIndex:Number): DisplayObject {
	    	var dob:DisplayObject;
	    	var fCreate:Boolean = false;
	    	var fAnimate:Boolean = _fAnimateRelayout;
	    	
    		// in our shuffle list
    		dob = _plPending.Fetch(nIndex.toString()) as DisplayObject;
	    	if (!dob) {
		    	if (_aobFreeItems.length > 0) {
		    		var ob:Object = _aobFreeItems.pop();
		    		dob = DisplayObject(ob);
		    		// dob = _aobFreeItems.pop(); // On unused queue
		    	} else {
		    		// Before we try to create an item, grab one from the pending queue, since this is much faster.
		    		if (_plPending.length > 0) {
		    			dob = _plPending.Dequeue() as DisplayObject;
		    		} else {
			    		// Create it
				    	dob = _itmr.newInstance();
			    		fCreate = true;
			    	}
			    }
		    	dob['data'] = data;
		    	fAnimate = false; // This is a new item. Don't bother animating
			}
	    	// trace("Placing object " + data.id + "[" + data.title + "] at position: " + xx + ", " + yy + ", create = " + fCreate);
	    	if (fAnimate) {
	    		var mv:Move = new Move(dob);
	    		mv.xFrom = dob.x;
	    		mv.yFrom = dob.y;
	    		if (dob in _dctActiveEffects) {
					Effect(_dctActiveEffects[dob]).end();
					delete _dctActiveEffects[dob];
	    		}
	    		mv.xTo = xx;
	    		mv.yTo = yy;
	    		_dctActiveEffects[dob] = mv;
	    		mv.duration = animationDuration;
	    		mv.play();
	    	} else {
	    		if (dob in _dctActiveEffects) {
					Effect(_dctActiveEffects[dob]).end();
					delete _dctActiveEffects[dob];
	    		}
		    	dob.x = xx;
		    	dob.y = yy;
		    }
	    	dob.height = rowHeight;
	    	dob.width = columnWidth;
	    	if (fCreate) super.addChild(dob);
	    	else dob.visible = true; // Was merely hiding
	    	dispatchEvent(new ListItemEvent("item_inserted", ITileListItem(dob), nIndex));
	    	return dob;
	    }

		// Insert lines overlapping two positions
   		private function InsertLinesOverlapping(nStart:Number, nEnd:Number, fBefore:Boolean): void {
   			// nStart and nEnd are line pixel positions which are empty but should contain lines
   			var rcArea:Rectangle;
   			if (vertical) {
   				rcArea = new Rectangle(0, nStart, width, nEnd - nStart);
   			} else {
   				rcArea = new Rectangle(nStart, 0, nEnd - nStart, height);
   			}
   			if (rcArea.height > 0 && rcArea.width > 0) {
	   			CreateLines(rcArea, fBefore);
	   		}
   		}
	   
	    /*** CreateLines
	    * Create new lines for an area
	    * Types of layout changes
	    * 1. Initial creation (data provider changed, item renderer changed)
	    * 2. Scrolling (animated) - move stuff
	    * 3. Scaling (similar to starting from scratch)
	    */
	    private function CreateLines(rcArea:Rectangle, fBefore:Boolean=true): void {
	    	if (!isReady) return;
	    	var xx:Number = 0;
	    	var yy:Number = 0;
	    	
	    	var iterator:IViewCursor = _collection.createCursor();
	    	
    		var aobNewLines:Array = [];
    		var obLine:Object;

    		var nIndex:Number = PointXYToIndex(rcArea.x, rcArea.y);
    		if (nIndex < 0) {
    			throw new Error("Negative index: " + nIndex + ", " + rcArea);
    		}
    		iterator.seek(CursorBookmark.FIRST, nIndex);
    		if (iterator.afterLast) return; // Is there any cleanup we should do?
    		var fMoreItems:Boolean = true;
	    	
	    	if (vertical) {
    			yy = IndexToPoint(nIndex).y; // at or above rcArea.y
    			while (fMoreItems && yy < rcArea.bottom) {
    				xx = 0;

    				// Start looping. We have at least one item in this row (iterator is valid)
    				obLine = {nIndex:nIndex, aobTiles:[], x:xx, y:yy}
    				aobNewLines.push(obLine);
    				
    				// Do something
		    		while (fMoreItems && ((xx + columnWidth) <= width || xx == 0)) {
		    			// For each column/tile
		    			obLine.aobTiles.push(InsertNewItem(xx, yy, iterator.current, nIndex));
		    			fMoreItems = iterator.moveNext();
		    			nIndex++;
		    			xx += columnWidth;
		    		} 
    				yy += rowHeight;
    			}
	    	} else {
    			xx = IndexToPoint(nIndex).x; // at or above rcArea.y
    			while (fMoreItems && xx < rcArea.right) {
    				yy = 0;

    				// Start looping. We have at least one item in this row (iterator is valid)
    				obLine = {nIndex:nIndex, aobTiles:[], x:xx, y:yy}
    				aobNewLines.push(obLine);
    				
    				// Do something
		    		while (fMoreItems && ((yy + rowHeight) <= height || yy == 0)) {
		    			// For each row/tile
		    			obLine.aobTiles.push(InsertNewItem(xx, yy, iterator.current, nIndex));
		    			fMoreItems = iterator.moveNext();
		    			nIndex++;
		    			yy += rowHeight;
		    		} 
    				xx += columnWidth;
    			}
	    	}
			if (fBefore) {
				_aobVisibleLines = aobNewLines.concat(_aobVisibleLines);
			} else {
				_aobVisibleLines = _aobVisibleLines.concat(aobNewLines);
			}
	    }

	    /*** CreateAllLines
	    * Recreate all the lines.
	    * Types of layout changes
	    * 1. Initial creation (data provider changed, item renderer changed)
	    * 2. Scrolling (animated) - move stuff
	    * 3. Scaling (similar to starting from scratch)
	    */
	    private function CreateAllLines(): void {
	    	if (_aobVisibleLines.length > 0) throw new Error("Can not create layout when one already exists");
	    	if (!isReady) return;
	    	
	    	var rcArea:Rectangle = new Rectangle(-xScroll, -yScroll, width, height);
	    	CreateLines(rcArea, true);
	    }
	   
	    private function OnDeactivate(evt:Event): void {
	    	_plPending.RemoveAll(_aobFreeItems);
	    }
	   
	    /********** BEGIN Row, column, tile, line, point, item, index math **********/
	    public function get tilesPerLine():Number {
	    	return vertical ? fixedColumns : fixedRows;
	    }

	    public function get totalRows(): Number {
	    	if (vertical) return Math.ceil(_collection.length / visibleColumns);
	    	else return fixedRows;
	    }
	   
	    public function get visibleTiles(): Number {
	    	return (visibleColumns * visibleRows);
	    }
	   
	    public function get totalColumns(): Number {
	    	if (vertical) return fixedColumns;
	    	else return Math.ceil(_collection.length / visibleRows);
	    }
	   
	    // Number of columns showing when we are in vertical mode
	    // in horizontal, results are undefined
	    private function get fixedColumns(): Number {
	    	if (!vertical) throw new Error("fixed columns only makes sense for vertical mode");
	    	return Math.max(1,Math.floor(width / columnWidth));
	    }
	   
	    // Number of rows showing when we are in horizontal mode
	    // in vertical, results are undefined
	    private function get fixedRows(): Number {
	    	if (vertical) throw new Error("fixed rows only makes sense for horizontal mode");
	    	return Math.max(1,Math.floor(height / rowHeight));
	    }

	    private function get lineSize(): Number {
	    	return vertical ? rowHeight : columnWidth;
	    }

	    private function get tileSize(): Number {
	    	return vertical ? columnWidth : rowHeight;
	    }
	   
	    // Returns an object with:
	    // ob.i = the index
	    // ob.iNearestLineNeighbor = the index of a neighbor in the nearest line
	    // ob.cxyNearestLineNeighborDist = the pixel distance to the nearest neighbor line
	    public function PointToIndexAndNeighborLine(pt:Point): Object {
	    	var nLineOffset:Number = vertical ? pt.y : pt.x;
	    	var nTileOffset:Number = vertical ? pt.x : pt.y;
	    	var nLine:Number = nLineOffset / lineSize;
	    	var iLine:Number = Math.floor(nLine);
	    	var i:Number = iLine * tilesPerLine + Math.floor(nTileOffset / tileSize);
	    	
	    	var iNearestLineNeighbor:Number = Math.round(nLine);
	    	if (iNearestLineNeighbor == iLine)
	    		 iNearestLineNeighbor -= 1;
	    		
	    	var cxyNearestLineNeighborDist:Number = Math.abs(nLine - Math.round(nLine)) * lineSize;
	    	
	    	return {i:i, iNearestLineNeighbor:iNearestLineNeighbor, cxyNearestLineNeighborDist:cxyNearestLineNeighborDist};
	    }

	    public function PointToIndex(pt:Point):Number {
	    	return PointXYToIndex(pt.x, pt.y);
	    }
	   
	    private function PointXYToIndex(xx:Number, yy:Number):Number {
	    	var nLineOffset:Number = vertical ? yy : xx;
	    	var nTileOffset:Number = vertical ? xx : yy;
    		return Math.floor(nLineOffset / lineSize) * tilesPerLine + Math.floor(nTileOffset / tileSize); 
	    }
	   
	    public function IndexToPoint(nIndex:Number): Point {
	    	var nRow:Number;
	    	var nCol:Number;
	    	if (vertical) {
	    		nRow = Math.floor(nIndex / fixedColumns);
	    		nCol = nIndex - nRow * fixedColumns;
	    	} else {
	    		nCol = Math.floor(nIndex / fixedRows);
	    		nRow = nIndex - nCol * fixedRows;
	    	}
	    	
	    	return new Point(nCol * columnWidth, nRow * rowHeight);
	    }
	   
	    private function get visibleRows(): Number {
	    	if (vertical)
	    		return Math.ceil((height + (y % rowHeight)) / rowHeight);
	    	else
	    		return fixedRows;
	    }
	   
	    private function get visibleColumns(): Number {
	    	if (vertical)
		    	return fixedColumns;
	    	else
		    	return Math.ceil((width + (x % columnWidth)) / columnWidth);
	    }
	   
		public function ItemLocToIndex(obLoc:Object): Number {
			return PointToIndex(ItemLocToPoint(obLoc));
		}
		
		public function IndexToItemLoc(nIndex:Number): Object {
			return PointToItemLoc(IndexToPoint(nIndex));
		}
		
		private function ItemLocHead(): Object {
			return {nTile:0, nLine:0};
		}
		private function ItemLocTail(): Object {
			if (hasItems) {
				var aobLastTiles:Array = _aobVisibleLines[_aobVisibleLines.length-1].aobTiles;
				return {nLine:_aobVisibleLines.length-1, nTile:aobLastTiles.length-1};
			}
			return {nTile:0, nLine:0};
		}
		
		// Returns null if none found
		public function IndexToItem(nIndex:Number): ITileListItem {
			return ItemLocToItem(IndexToItemLoc(nIndex));
		}
		
		private function ItemHeadToPoint(): Point {
			if (hasItems) {
				var tilFirst:ITileListItem = _aobVisibleLines[0].aobTiles[0];
				return new Point(tilFirst.x, tilFirst.y);
			}
			// No items, try to figure out where the head should be.
			return IndexToPoint(PointToIndex(new Point(x,y)));
		}
		
		public function PointToItem(pt:Point): ITileListItem {
			return ItemLocToItem(PointToItemLoc(pt));
		}
		
		public function ItemLocToPoint(obLocation:Object): Point {
			var ptItemHead:Point = ItemHeadToPoint();
			var nRowOffset:Number = vertical ? obLocation.nLine : obLocation.nTile;
			var nColOffset:Number = vertical ? obLocation.nTile : obLocation.nLine;
			
			return new Point(ptItemHead.x + columnWidth * nColOffset, ptItemHead.y + rowHeight * nRowOffset);
		}
		
		public function ItemToIndex(tli:ITileListItem): Number {
			return PointToIndex(new Point(tli.x, tli.y));
		}
		
		private function PointToItemLoc(pt:Point): Object {
			var ptItemHead:Point = ItemHeadToPoint();
			
		    var obLocation:Object = null;
		    var nRowOff:Number = Math.floor((pt.y - ptItemHead.y)/rowHeight);
		    var nColOff:Number = Math.floor((pt.x - ptItemHead.x)/columnWidth);
		    if (vertical)
		    	obLocation = {nLine:nRowOff, nTile:nColOff};
		    else
		    	obLocation = {nLine:nColOff, nTile:nRowOff};
		    	
		    return obLocation;
		}
		
		public function ItemLocToItem(obItemLoc:Object): ITileListItem {
			if (obItemLoc == null) return null;
			if (obItemLoc.nLine < 0) return null;
			if (obItemLoc.nTile < 0) return null;
			if (!ValidateLayout()) return null;
			if (obItemLoc.nLine >= _aobVisibleLines.length) return null;
			var aobTiles:Array = _aobVisibleLines[obItemLoc.nLine].aobTiles;
			if (obItemLoc.nTile >= aobTiles.length) return null;
			return aobTiles[obItemLoc.nTile] as ITileListItem;
		}
		
		public function ItemApply(fnApply:Function, nStartIndex:Number=0, cItems:Number=Number.POSITIVE_INFINITY): void {
			var nIndex:Number = Math.max(nStartIndex, ItemLocToIndex(ItemLocHead()));
			var nEndIndex:Number = Math.min(nStartIndex + cItems - 1, ItemLocToIndex(ItemLocTail()));
			while (nIndex <= nEndIndex) {
				var tli:ITileListItem = IndexToItem(nIndex);
				if (tli) fnApply(tli, nIndex);
				nIndex++;
			}
		}
	    /********** END Row, column, tile, line, point, item, index math **********/
	}
}