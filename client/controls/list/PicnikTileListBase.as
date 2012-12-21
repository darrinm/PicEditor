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
	/**
	 * The foundation for the smooth scrolling tile list
	 * This class mostly handles scrolling
	 * The ListItemView class handles positioning logic
	 * The PicnikTileList class (sub-class of this one) handles the selection
	 */
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.collections.IList;
	import mx.collections.ListCollectionView;
	import mx.collections.XMLListCollection;
	import mx.controls.scrollClasses.ScrollBar;
	import mx.core.EdgeMetrics;
	import mx.core.IFactory;
	import mx.core.ScrollControlBase;
	import mx.effects.AnimateProperty;
	import mx.effects.easing.Quadratic;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.EffectEvent;
	import mx.events.ResizeEvent;
	import mx.events.ScrollEvent;
	import mx.events.ScrollEventDetail;

	public class PicnikTileListBase extends ScrollControlBase
	{
		public function PicnikTileListBase()
		{
			super();
			addEventListener(ResizeEvent.RESIZE, OnResize);
			_livListContent = new ListItemView();
			
			// Fill the content area with transparent pixels to capture mouse events
            var g:Graphics = _livListContent.graphics;
            g.beginFill(0, 0); // 0 alpha means transparent
            g.drawRect(0, 0, 800000, 800000);
            g.endFill();
		}
		
		private var _nAspectRatio:Number = NaN;
		private var _fWidthJustified:Boolean = true;
		private var _fAlwaysWidthJustified:Boolean = false;
		private var _nTileSizeW:Number = 100;
		
	    private var _nRowHeight:Number = 100;
	    private var _nColumnWidth:Number = 100;

   		private const knHorizontalScrollbarHeight:Number = 16;
   		private const knVerticalScrollbarWidth:Number = 16;
   		private const knAutoSwitchHeightThreshold:Number = 2;
   		
		private var _itmr:IFactory = null;
	    protected var collection:ICollectionView;
	   
	    protected var _livListContent:ListItemView = null;

	    private var _fVertical:Boolean = true;
	   
	    private var _fAutoHorizontal:Boolean = false;
	   
	    private var knMaxVisibleToAnimate:Number = 100;
	   
	    private var _fAnimatingRelayout:Boolean = false;

	    private var _nPrevScroll:Number = 0;
	    private var _nActualVerticalScrollPos:Number = 0;
	    private var _nActualHorizontalScrollPos:Number = 0;
	   
		private var _fSnapScroll:Boolean = false;
		
		private var _nLeftElementPadding:Number = 0;

	    private var _bPageScrollDebounce:Boolean = true;
		
		[Bindable] public var fListHasItems:Boolean = false;
		
		public function set leftElementPadding(n:Number): void {
			if (_nLeftElementPadding != n) {
				_nLeftElementPadding = n;
				updateChildBorders();
			}
		}
		public function get leftElementPadding(): Number {
			return _nLeftElementPadding;
		}
		
		public function set animationDuration(n:Number): void {
			_livListContent.animationDuration = n;
		}
		
		private function updateChildBorders(): void {
			if (!_livListContent) return;
			_livListContent.leftBorder = leftElementPadding;
			_livListContent.topBorder = 0;
			var emBorder:EdgeMetrics = borderMetrics;
			if (emBorder) {
				_livListContent.leftBorder += emBorder.left;
				_livListContent.topBorder += emBorder.top;
			}
		}
		
	    override public function styleChanged(strStyle:String):void {
	        super.styleChanged(strStyle);

	        var fAllStyles:Boolean = (strStyle == null || strStyle == "styleName");
	
	        if (fAllStyles || strStyle == "border-thickness") {
	        	updateChildBorders();
	        }
		}
		
		public function set snapScroll(f:Boolean): void {
			_fSnapScroll = f;
		}
		
		public function get singleRowHeight(): Number {
			return minHeight;
		}
		
		public function get twoRowHeight(): Number {
	    	var nTwoRowHeight:Number = rowHeight * 2;
	    	var emBorder:EdgeMetrics = borderMetrics;
	    	if (emBorder)
	    		nTwoRowHeight += emBorder.top + emBorder.bottom;
			return nTwoRowHeight;
		}
		
		override protected function createChildren():void {
			super.createChildren();
			_livListContent.addEventListener("item_removed", _OnItemRemoved);
			_livListContent.addEventListener("item_inserted", _OnItemInserted);
			_livListContent.mask = maskShape;
			addChild(_livListContent);
			updateChildBorders();
		}
	
	    private function EndRelayout(): void {
	    	_fAnimatingRelayout = false;
	    }
	   
	    public function set autoHorizontal(f:Boolean): void {
	    	_fAutoHorizontal = f;
	    	if (_fAutoHorizontal && !vertical) horizontalScrollPolicy = "on";

	    	UpdateMinHeight();
	    	OnResize();
	    }
	   
	    private function UpdateMinHeight(): void {
	    	minHeight = 0;
	    	var emBorder:EdgeMetrics = borderMetrics;
	    	if (emBorder) {
	    		minHeight += emBorder.top + emBorder.bottom;
	    	}
	    	if (_fAutoHorizontal) {
	    		minHeight += knHorizontalScrollbarHeight + knAutoSwitchHeightThreshold + rowHeight;
	    	}
	    }
	   
	    public function get autoHorizontal():Boolean {
	    	return _fAutoHorizontal;
	    }

		public function set itemRenderer(itmr:IFactory): void {
			_livListContent.itemRenderer = itmr;
		}

		public function get itemRenderer(): IFactory {
			return _livListContent.itemRenderer;
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
	        return collection;
	    }
	   
	    /**
	     *  @private
	     */
	    public function set dataProvider(value:Object):void
	    {
	        if (collection)
	        {
	            collection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, CollectionChangeHandler);
	        }
	
	        if (value is Array)
	        {
	            collection = new ArrayCollection(value as Array);
	        }
	        else if (value is ICollectionView)
	        {
	            collection = ICollectionView(value);
	        }
	        else if (value is IList)
	        {
	            collection = new ListCollectionView(IList(value));
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
	        // trace("ListBase added change listener");
	        collection.addEventListener(CollectionEvent.COLLECTION_CHANGE, CollectionChangeHandler, false, 0, true);
	
			_livListContent.collection = collection;
			
	        var event:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
	        event.kind = CollectionEventKind.RESET;
	        CollectionChangeHandler(event);
	        dispatchEvent(event);
	    }
	   
	    protected function CollectionChangeHandler(evt:CollectionEvent):void {
	    	_livListContent.CollectionChanged(evt);
	    	if (evt.kind != CollectionEventKind.REPLACE && evt.kind != CollectionEventKind.ADD &&
	    			evt.kind != CollectionEventKind.REMOVE && evt.kind != CollectionEventKind.UPDATE &&
	    			evt.kind != CollectionEventKind.MOVE) {
	    		ScrollNow(0); // Reset scroll position
	    	}	
     	    
	    	if (evt.kind != CollectionEventKind.UPDATE) {
	    		UpdateScrollbars();
	    	}
			
			fListHasItems = (collection != null && collection.length > 0);
	    }
	   
	    public function set actualVerticalScrollPos(n:Number): void {
	    	n = Math.max(0, Math.min(maxScrollPosition, Math.round(n)));
	    	if (n == _nActualVerticalScrollPos) return;
	    	_nActualVerticalScrollPos = n;
	    	verticalScrollPosition = n;
	    	
	    	var yy:Number = -_nActualVerticalScrollPos;
	    	_livListContent.yScroll = Math.round(yy);
	    }
	   
	    public function get actualVerticalScrollPos(): Number {
	    	return _nActualVerticalScrollPos;
	    }
	   
	    public function set actualHorizontalScrollPos(n:Number): void {
	    	n = Math.max(0, Math.min(maxScrollPosition, Math.round(n)));
	    	if (n == _nActualHorizontalScrollPos) return;
	    	_nActualHorizontalScrollPos = n;
	    	horizontalScrollPosition = n;
	    	var xx:Number = -_nActualHorizontalScrollPos;
	    	_livListContent.xScroll = Math.round(xx);
	    }
	   
	    public function get actualHorizontalScrollPos(): Number {
	    	return _nActualHorizontalScrollPos;
	    }
	   
	    // public so that our effect can set this
	    [Bindable]
	    public function set actualScrollPosition(n:Number): void {
			if (vertical) {
				actualVerticalScrollPos = n;
			} else {
				actualHorizontalScrollPos = n;
			}
	    }
	   
	    public function get actualScrollPosition(): Number {
	    	return vertical ? actualVerticalScrollPos : actualHorizontalScrollPos;
	    }
	   
	    public function set tileAspectRatio(nAspectRatio:Number): void {
	    	_nAspectRatio = nAspectRatio;
	    	UpdateTileSize();
	    }
	   
	    [Bindable]
	    public function set tileSizeInWidth(nTileSizeW:Number): void {
	    	_nTileSizeW = nTileSizeW;
	    	UpdateTileSize();
	    }
	   
	    public function get tileSizeInWidth(): Number {
	    	return _nTileSizeW;
	    }
	   
	    private function get unpaddedColumnWidth(): Number {
	    	if (isNaN(_nAspectRatio) || !vertical ||!_fWidthJustified) return columnWidth;
	    	// We have justified width, so our actual width may be smaller.
	    	return Math.floor(_nTileSizeW);
	    }
	   
	    private function UpdateTileSize(): void {
	    	if (!_fWidthJustified) return;
	    	var nWidth:Number = Math.floor(_nTileSizeW);
	    	var nHeight:Number;
	    	if (!isNaN(_nAspectRatio))
	    		nHeight = Math.floor(_nTileSizeW / _nAspectRatio);
	    	else
	    		nHeight = NaN;
	    		
	    	if (vertical && _fWidthJustified) {
	    		// Stretch the width to fill extra space
				var cx:Number = minContentWidth;
				var cColumns:Number = int(cx / nWidth);
				// Don't stretch unless we have enough items to fill a line
				if (_fAlwaysWidthJustified || (collection && collection.length > cColumns)) {
					var cxRemaining:Number = cx - (cColumns * nWidth);
					nWidth += int(cxRemaining / cColumns);
				}
	    	}
	    	if (!isNaN(nHeight)) rowHeight = nHeight;
	    	columnWidth = nWidth;
	    }
	   
	    [Bindable]
	    public function set rowHeight(n:Number): void {
	    	if (_nRowHeight == n) return;
	    	// trace("rowHeight changed from " + _nRowHeight + " to " + n);

	    	var obPrevScrollState:Object = GetScrollState();
	    	_nRowHeight = n;
	    	UpdateMinHeight();
	    	_livListContent.rowHeight = _nRowHeight;
	    	UpdateScrollbars(obPrevScrollState);
	    }
	   
	    public function get rowHeight(): Number {
	    	return _nRowHeight;
	    }

	    [Bindable]
	    public function set alwaysWidthJustified(f:Boolean): void {
	    	if (_fAlwaysWidthJustified == f) return;
	    	// trace("rowHeight changed from " + _nRowHeight + " to " + n);
	    	var obPrevScrollState:Object = GetScrollState();
	    	_fAlwaysWidthJustified = f;
	    	UpdateScrollbars(obPrevScrollState);
	    }
	   
	    public function get alwaysWidthJustified(): Boolean {
	    	return _fAlwaysWidthJustified;
	    }

	    [Bindable]
	    public function set columnWidth(n:Number): void {
	    	if (_nColumnWidth == n) return;
	    	// trace("colWidth changed from " + _nColumnWidth + " to " + n);

	    	var obPrevScrollState:Object = null;
   			obPrevScrollState = GetScrollState();
	    	_nColumnWidth = n;
	    	_livListContent.columnWidth = _nColumnWidth;
	    	UpdateScrollbars(obPrevScrollState);
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
	    		haltAnimation();
	    		// Update something?
	    		// UNDONE: Remember and translate your scroll position to keep the same items on the screen

		    	var obPrevScrollState:Object = GetScrollState();

	    		actualScrollPosition = 0;
		    	_fVertical = f;
		    	
		    	if (_fVertical) {
		    		verticalScrollPolicy = "auto";
		    		horizontalScrollPolicy = "off";
		    	} else {
		    		verticalScrollPolicy = "off";
		    		horizontalScrollPolicy = "on";
		    	}
		    	_livListContent.vertical = _fVertical;
		    	
		    	UpdateScrollbars(obPrevScrollState);
		    }
	    }
	   
	    private function get heightWithoutBorders(): Number {
	    	var nHeight:Number = height;
	    	var emBorder:EdgeMetrics = borderMetrics;
	    	if (emBorder)
	    		nHeight -= emBorder.top + emBorder.bottom;
	    	return nHeight;
	    }
	   
	    protected function get contentHeight(): Number {
	    	if (horizontalScrollBar) return heightWithoutBorders - horizontalScrollBar.height;
	    	return heightWithoutBorders;
	    }
	   
	    private function get widthWithoutBorders(): Number {
	    	var nWidth:Number = width;
	    	var emBorder:EdgeMetrics = borderMetrics;
	    	if (emBorder)
	    		nWidth -= emBorder.left + emBorder.right;
	    	return nWidth;
	    }
	   
	    protected function get contentWidth(): Number {
	    	var nWidth:Number = widthWithoutBorders;
	    	if (verticalScrollBar)
	    		nWidth -= verticalScrollBar.width;
	    	return nWidth;
	    }
	   
	    private function get minContentWidth(): Number {
	    	return widthWithoutBorders - (vertical ? knVerticalScrollbarWidth : 0) - (vertical ? leftElementPadding : 0);
	    }
	   
	    private function get minContentHeight(): Number {
	    	return heightWithoutBorders - (vertical ? 0 : knHorizontalScrollbarHeight);
	    }
	   
	    private function get pageScrollSize(): Number {
	    	if (vertical) return verticalPageScrollSize;
	    	return horizontalPageScrollSize;
	    }
	   
	    private function get lineScrollSize(): Number {
	    	if (vertical) return rowHeight;
	    	return columnWidth;
	    }
	   
	    protected function get verticalPageScrollSize(): Number {
	    	return rowHeight * Math.max(1, Math.floor(contentHeight/rowHeight));
	    }
	   
	    protected function get horizontalPageScrollSize(): Number {
	    	return columnWidth * Math.max(1, Math.floor(contentWidth/columnWidth));
	    }
	   
	    protected function get scrollBar(): ScrollBar {
	    	return vertical ? verticalScrollBar : horizontalScrollBar;
	    }
	   
	    private function UpdateScrollbars(obPrevScrollState:Object=null): void {
	    	if (!collection) return;
	    	if (!obPrevScrollState) obPrevScrollState = GetScrollState();
	    	UpdateTileSize();
	    	if (vertical) {
	    		setScrollBarProperties(0,0,rowHeight * _livListContent.totalRows, contentHeight);
	    	} else {
	    		setScrollBarProperties(columnWidth * _livListContent.totalColumns, contentWidth - leftElementPadding, 0,0);
	    	}
	    	if (scrollBar) {
				scrollBar.lineScrollSize = lineScrollSize;
				scrollBar.pageScrollSize = pageScrollSize;
	    	}

	    	_livListContent.width = contentWidth;
	    	_livListContent.height = contentHeight;

	    	AdjustScroll(obPrevScrollState);
	    }
	   
		private function GetScrollState(fAnchorTop:Boolean=false): Object {
			var ptViewTopLeft:Point = new Point(- _livListContent.xScroll, -_livListContent.yScroll);
			
			var ptAnchor:Point;
			
			var nAnchorTileIndex:Number;
			if (fAnchorTop) {
				ptAnchor = ptViewTopLeft.clone();
				ptAnchor.offset(columnWidth/2, rowHeight/2);
			} else {
				ptAnchor = ptViewTopLeft.clone();
				ptAnchor.offset(_livListContent.width/2, _livListContent.height/2);
			}
			nAnchorTileIndex = _livListContent.PointToIndex(ptAnchor);
			
			// Center of the middle index
			var ptAnchorTile:Point = _livListContent.IndexToPoint(nAnchorTileIndex); // upper left
			ptAnchorTile.offset(columnWidth/2, rowHeight/2); // Location of the center of the tile
			
			// Now, calculate the offset of our middle tile from the middle of the view
			var ptOffTopLeft:Point = ptAnchorTile.subtract(ptViewTopLeft); // Positive is right,below middle

			var obState:Object = {};
			obState.fAtTop = actualScrollPosition == 0;
			obState.fAtBottom = actualScrollPosition == maxScrollPosition;
			obState.nAnchorTileIndex = nAnchorTileIndex; // index of middle tile
			obState.ptOffTopLeft = ptOffTopLeft; // center point of middle tile

			return obState;
		}

	    private function AdjustScroll(obPrevScroll:Object): void {
	    	if (obPrevScroll.fAtTop) {
	    		actualScrollPosition = 0;
	    	} else if (obPrevScroll.fAtBottom) {
	    		actualScrollPosition = maxScrollPosition;
	    	} else {
	    		// Not at top or bottom. Scroll so that the same index is
	    		// in about the same place.

	    		var ptAnchorTile:Point = _livListContent.IndexToPoint(obPrevScroll.nAnchorTileIndex);
	    		ptAnchorTile.offset(columnWidth/2, rowHeight/2);
	    		
	    		var ptScrollPos:Point = ptAnchorTile.subtract(obPrevScroll.ptOffTopLeft);

	    		actualScrollPosition = Snap(vertical ? ptScrollPos.y : ptScrollPos.x);
	    	}
	    }
	   
	    private function Snap(nToScroll:Number): Number {
			if (_fSnapScroll && nToScroll < maxScrollPosition) {
				// UNDONE: What is expected behavior when we snap with left element padding?
				// if (!vertical) nToScroll -= leftElementPadding;
				nToScroll = lineSize * (Math.round(nToScroll / lineSize));
				// if (!vertical) nToScroll += leftElementPadding;
			}
			nToScroll = Math.max(0, Math.min(maxScrollPosition, nToScroll));
			return nToScroll;
	    }
	   
	    protected function OnResize(evt:ResizeEvent=null): void {
	    	// First, check for auto adjustments
	    	if (autoHorizontal) {
	    		var fWasVertical:Boolean = vertical;
	    		vertical = height > minHeight;
	    	}
	    	UpdateScrollbars(GetScrollState(true));
	    }

	    private function ScrollNow(pos:Number): void {
	    	haltAnimation();
	    	actualScrollPosition = pos;
	    }

	    protected function get animating(): Boolean {
	    	return _effScroll.isPlaying;
	    }
	   
	    private var _effScroll:AnimateProperty = null;
	   
	    private function get animateScrollEffect(): AnimateProperty {
	    	if (!_effScroll) {
	    		_effScroll = new AnimateProperty(this);
	    		_effScroll.property = "actualScrollPosition";
	    		_effScroll.suspendBackgroundProcessing = true;
	    	}
	    	return _effScroll;
	    }
	   
	    private function haltAnimation(): void {
	    	if (animateScrollEffect.isPlaying) {
	    		animateScrollEffect.toValue = actualScrollPosition;
	    		animateScrollEffect.end();
	    	}
	    }
	   
	    // Set the scroll bar position
	    private function set virtualScrollPosition(nPos:Number): void {
	    	if (vertical)
	    		verticalScrollPosition = nPos;
	    	else
	    		horizontalScrollPosition = nPos;
	    }

	    public function AnimateScroll(nDeltaScroll:Number, nMouseLimit:Number=NaN, fnDone:Function=null): Number {
	    	var nToScroll:Number;
	    	var nCurrentScrollTarget:Number;
	    	
	    	// First, get our target position
	    	if (animateScrollEffect.isPlaying) {
	    		nCurrentScrollTarget = animateScrollEffect.toValue;
	    	} else {
	    		nCurrentScrollTarget = actualScrollPosition;
	    	}
	    	nToScroll = nCurrentScrollTarget + nDeltaScroll;
	    	nToScroll = Math.min(maxScrollPosition, Math.max(0, nToScroll));

			// Next, check against any limit
	    	var fHitLimit:Boolean = false;
    		if (!isNaN(nMouseLimit)) {
    			if (nDeltaScroll > 0) {
    				// Scrolling down
    				fHitLimit = (nToScroll > nMouseLimit);
    			} else {
    				// Scrolling up
    			 	fHitLimit = ((nToScroll + pageScrollSize) < nMouseLimit);
    			}
    		}
    		if (fHitLimit) {
	    		nToScroll = nCurrentScrollTarget;
				virtualScrollPosition = actualScrollPosition; // Make sure
		    } else {
		    	AnimateScrollTo(nToScroll, fnDone);
		    }
		    return nToScroll;
		}
	   
	    protected function get lineSize(): Number {
	    	return vertical ? rowHeight : columnWidth;
	    }
	   
	    protected function get contentLineSize(): Number {
	    	return vertical ? contentHeight : contentWidth;
	    }
	   
	    private function get maxScrollPosition(): Number {
	    	return vertical ? maxVerticalScrollPosition : maxHorizontalScrollPosition;
	    }

	    private function _OnItemRemoved(evt:ListItemEvent): void {
	    	OnItemRemoved(evt._tliTarget as ITileListItem);
	    }

	    private function _OnItemInserted(evt:ListItemEvent): void {
	    	OnItemInserted(evt._tliTarget as ITileListItem, evt._nIndex);
	    }

	    protected function OnItemRemoved(tliRemoved:ITileListItem): void {
	    	// Override in subclasses
	    }

	    protected function OnItemInserted(tliInserted:ITileListItem, nIndex:Number): void {
	    	// Override in subclasses
	    }

		protected function ItemApply(fnApply:Function, nStartIndex:Number=0, cItems:Number=Number.POSITIVE_INFINITY): void {
			_livListContent.ItemApply(fnApply, nStartIndex, cItems);
		}
		
		protected function AnimateScrollTo(nToScroll:Number, fnDone:Function=null): void {
			nToScroll = Snap(nToScroll);
			if (_livListContent.visibleTiles > knMaxVisibleToAnimate) {
				ScrollNow(nToScroll);
			} else {
				var nPrevPos:Number = actualScrollPosition;
		    	if (animateScrollEffect.isPlaying) {
		    		haltAnimation();
		    		animateScrollEffect.easingFunction = Quadratic.easeOut;
		    	} else {
		    		animateScrollEffect.easingFunction = Quadratic.easeInOut;
		    	}
		    	if (nPrevPos != actualScrollPosition) {
		    		actualScrollPosition = nPrevPos;
		    	}
		    	animateScrollEffect.fromValue = actualScrollPosition;
		    	animateScrollEffect.toValue = nToScroll = Math.max(0, Math.min(nToScroll, maxScrollPosition));
		    	// Duration logic
		    	// Default is 400ms
		    	// Requires delta >= rowHeight * 2
		    	// min is 100ms
		    	// so set the duration to max(100, min(400, 300 * abs(delta) / (rowheight * 2)))
		    	
		    	var nMaxDuration:Number = 800; // For knRowsForMaxDuration change
		    	var nMinDuration:Number = 300; // For one row change
		    	
		    	var nMaxDurationDelta:Number;
		    	var nMinDurationDelta:Number;
		    	var nDelta:Number = Math.abs(animateScrollEffect.toValue - animateScrollEffect.fromValue);
		    	if (nDelta > 1500) {
		    		// For deltas greater than 1500, speed up to max speed at 2000 (min duration)
		    		nMinDurationDelta = 2000;
		    		nMaxDurationDelta = 1500;
		    		nMinDuration = 200;
		    	} else if (nDelta < rowHeight) {
		    		nMinDurationDelta = 0;
		    		nMaxDurationDelta = rowHeight;
		    		nMaxDuration = nMinDuration;
		    		nMinDuration = 0;
		    	} else {
		    		// For smaller deltas, max speed is 1 row, min speed is 5 rows.
		    		nMinDurationDelta = rowHeight;
		    		nMaxDurationDelta = rowHeight * 5;
		    	}
		    	var nPctFromMinToMaxDuration:Number = (nDelta - nMinDurationDelta) / (nMaxDurationDelta - nMinDurationDelta);
		    	var nDuration:Number = nMinDuration + nPctFromMinToMaxDuration * (nMaxDuration - nMinDuration);
		    	animateScrollEffect.duration = Math.max(nMinDuration, Math.min(nMaxDuration, nDuration));

				var fnOnSelectedEffectEnd:Function = function(evt:EffectEvent): void {		    	
					evt.target.removeEventListener(EffectEvent.EFFECT_END, fnOnSelectedEffectEnd);
					if (fnDone != null)
						fnDone();
				}
				animateScrollEffect.addEventListener(EffectEvent.EFFECT_END, fnOnSelectedEffectEnd);
		    	animateScrollEffect.play();
		    }
		}

	    private function GetDelta(strDetail:String): Number {
	    	switch(strDetail) {
	    		case ScrollEventDetail.LINE_DOWN:
	    		case ScrollEventDetail.LINE_RIGHT:
	    			return lineScrollSize;
	    		case ScrollEventDetail.LINE_LEFT:
	    		case ScrollEventDetail.LINE_UP:
	    			return -lineScrollSize;
	    		case ScrollEventDetail.PAGE_DOWN:
	    		case ScrollEventDetail.PAGE_RIGHT:
	    			return pageScrollSize;
	    		case ScrollEventDetail.PAGE_LEFT:
	    		case ScrollEventDetail.PAGE_UP:
	    			return -pageScrollSize;
	    		
	    		default:
	    			return 0;
	    	}
	    	return 0;
	    }
	   
	    override protected function mouseWheelHandler(event:MouseEvent):void {
	        if (scrollBar)
	        {
	        	AnimateScroll(-event.delta * lineScrollSize);
	            event.stopPropagation();
	        }
	    }
	   
	    public function AnimateScrollToHead(): void {
	    	AnimateScrollTo(0);
	    }
	   
	    override protected function scrollHandler(event:Event):void
	    {
	    	// super.scrollHandler(event);
	        // TextField.scroll bubbles so you might see it here
	        if (event is ScrollEvent)
	        {
	            var scrollBar:ScrollBar = ScrollBar(event.target);
	            var pos:Number = scrollBar.scrollPosition;
	            var sevt:ScrollEvent = event as ScrollEvent;
            	if ((sevt.detail == ScrollEventDetail.THUMB_POSITION) || (sevt.detail == ScrollEventDetail.THUMB_TRACK)) {
            		ScrollNow(pos);
            		if (sevt.detail == ScrollEventDetail.THUMB_POSITION && _fSnapScroll) {
            			AnimateScrollTo(pos, null);
            		}
            	} else {
            		if (sevt.detail == ScrollEventDetail.PAGE_UP   ||
            			sevt.detail == ScrollEventDetail.PAGE_DOWN ||
            			sevt.detail == ScrollEventDetail.PAGE_LEFT ||
            			sevt.detail == ScrollEventDetail.PAGE_RIGHT)
            		{
            			// both ScrollBar.scrollTrack_mouseDownHandler and ScrollBar.scrollTrack_mouseUpHandler
            			// will generate scroll events when clicking on the track.  This leads to scrolling
            			// two pages on a mouse click rather than one.  AnimateScroll() will accumulate nDelta
            			// if you rapidly click twice -- we could discard that behavior and paging is OK, but
            			// we want to accumulate these changes.  So, we ignore the mouseUpHandler event.
            			_bPageScrollDebounce = !_bPageScrollDebounce;
            			if (_bPageScrollDebounce)
            				return; 		
            		}
		            if (scrollBar) scrollBar.scrollPosition = actualScrollPosition;
            		var nDelta:Number = GetDelta(sevt.detail);
            		if (nDelta == 0) {
	            		nDelta = (pos - actualVerticalScrollPos);
	            	}
	            	var nMouseLimit:Number = NaN;
            		AnimateScroll(nDelta, nMouseLimit);
            	}
	        }
	    }
	}
}
