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
package containers.sectionList
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.XMLListCollection;
	import mx.containers.Box;
	import mx.core.IDataRenderer;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	import util.SectionBadgeInfo;

	[Event(name="change", type="flash.events.Event")]

	public class SectionListBase extends Box
	{
		private var _clItemRenderer:Class = null;
		private var _clSectionRenderer:Class = null;
		private var _fItemsInvalid:Boolean = true;
	    private var _dataProvider:IList;
	   
	    private var _fSelectable:Boolean = false;
	    private var _fKeepSelectedItemVisible:Boolean = true;
	    private var _iSelected:int = -1; // -1 == no selection
	   
	    // Sections can dispatch this event when they are growing and wish to have their new contents
	    // remain visible (may need to scroll to do this)
	    public static const SECTION_GROWING:String = "sectionGrowing";
		
		public function SectionListBase() {
			direction = "vertical"; // Default to a VBox. Set as appropriate
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
		}
		
		public function set sectionRenderer(cl:Class): void {
			_clSectionRenderer = cl;
			_fItemsInvalid = true;
			invalidateProperties();
		}

		// Item renderer should be either a display object class or a factor class that creates display ojbects.
		// You can use the factor class with a factor that returns data as a pass through item renderer
		public function set itemRenderer(cl:Class): void {
			_clItemRenderer = cl;
			_fItemsInvalid = true;
			invalidateProperties();
		}
		
		public function get itemRenderer(): Class {
			return _clItemRenderer;
		}
		
		// obValue can be either Array, IList, or ArrayCollection
		[Bindable]
		public function set dataProvider(obValue:Object): void {
			// Modeled after NavBar function set dataProvider()
			if (_dataProvider)
				_dataProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE, OnDataChange);
	       
			if (obValue is IList) {
				_dataProvider = IList(obValue);
			} else if (obValue is Array) {
				_dataProvider = new ArrayCollection(obValue as Array);
			} else if (obValue is XML) {
				var xl:XMLList = new XMLList();
				xl += obValue;
				_dataProvider = new XMLListCollection(xl);
			} else {
				_dataProvider = null;
			}
			if (_dataProvider)
		        _dataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE, OnDataChange, false, 0, true); // Weak ref
			
			_fItemsInvalid = true;
			invalidateProperties();
		}
		
		public function get dataProvider(): Object {
			return _dataProvider;
		}
		
		protected function OnDataChange(evt:CollectionEvent): void {
			// Recreate everything
			if (evt.kind != CollectionEventKind.UPDATE) {
				_fItemsInvalid = true;
				invalidateProperties();
			}
		}
		
		public function set active(fActive:Boolean): void {
			for (var i:Number = 0; i < numChildren; i++) {
				var sect:ISectionRenderer = getChildAt(i) as ISectionRenderer;
				if (sect)
					sect.active = fActive;
			}
		}
		
		protected function CreateListItems(): void {
			_fItemsInvalid = false;
			
			// First, remove any existing items.
			removeAllChildren();
			
			// Next, create children if we can
			if (_clItemRenderer && _clSectionRenderer && _dataProvider) {
				var iChildBase:int = 0;
				for (var i:int = 0; i < _dataProvider.length; i++) {
					var obSection:Object = _dataProvider.getItemAt(i);
					var sect:ISectionRenderer = new _clSectionRenderer() as ISectionRenderer;
					sect.itemRenderer = _clItemRenderer;
					sect.data = obSection;
					if (_fSelectable && _iSelected >= iChildBase && _iSelected < iChildBase + obSection.children.length)
						sect.initialSelectedIndex = _iSelected - iChildBase;
					if (sect is IEventDispatcher) {
						(sect as IEventDispatcher).addEventListener(SECTION_GROWING, OnSectionGrowing, false, 0, true);
					}
					addChild(sect as DisplayObject);
					iChildBase += obSection.children.length;
				}
				invalidateSize();
			}
			
			// Now that items are set, put the selection to use
			if (_fSelectable && _iSelected != -1)
				SelectItem(_iSelected, true);
		}
		
		protected function OnSectionGrowing(evt:Event): void {
			// A child section is growing. Try to keep it in the scroll view.
			ScrollToShow(evt.target as DisplayObject);
		}

		// UNDONE: Add horizontal scroll support if/when we need it
		protected function ScrollToShow(dob:DisplayObject): void {
			// If we convert dob coordinates to these coordinates, we get to points, top and bottom
			// Visible points are 0 to this.height
			// If we add to the verticalScrollPosition, it will move the top and bottom up (negative) towards 0
			// Goal is:
			// 1. If bottom > height and top >= 0, verticalScrollPos += (bottom - height)
			// 2. If top < 0, verticalScrollPos += top
			
			// Get dob local top and bottom points
			var ptTop:Point = new Point(0, 0);
			var ptBottom:Point = new Point(dob.width, dob.height);
			
			// Convert to this local
			ptTop = globalToLocal(dob.localToGlobal(ptTop));
			ptBottom = globalToLocal(dob.localToGlobal(ptBottom));
			
			var nScroll:Number = 0;
			
			// Check for bottom overflow.
			if (ptBottom.y > height && ptTop.y > 0) {
				nScroll = (ptBottom.y - height);
				ptTop.y -= nScroll;
			}
			if (ptTop.y < 0) {
				nScroll += ptTop.y;
			}
			verticalScrollPosition += nScroll;
		}
		
		override protected function commitProperties():void {
			super.commitProperties();
			
			if (_fItemsInvalid) {
				CreateListItems();
			}
		}
		
		//
		// Selection support
		//

		[Bindable]
		public function set selectedItem(data:Object):void {
			selectedIndex = IndexFromItem(data);
		}
		
		public function get selectedItem(): Object {
			return ItemFromIndex(_iSelected);
		}
		
		[Bindable]
		public function set selectedIndex(i:int): void {
			SelectItem(_iSelected, false);
			_iSelected = i;
			SelectItem(_iSelected, true);
			
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function get selectedIndex(): int {
			return _iSelected;
		}
		
		private function SelectItem(iSelected:Number, fSelected:Boolean): void {
			if (dataProvider == null)
				return;
				
			if (iSelected != -1) {
				var obItem:Object = ItemFromIndex(iSelected);
				if (obItem != null) {
					var obRet:Object = GetSectionAndItemRendererFromItem(obItem);
					if (obRet == null)
						return;
						
					if ("selected" in obRet.itemRenderer) {
						obRet.itemRenderer.selected = fSelected;
				
						if (fSelected && _fKeepSelectedItemVisible)
							ScrollSelectedItemIntoView();
					}
				}
			}
		}
		
		// if fTop == true the selected item will be displayed at the top of
		// the visible list (if possible)
		public function ScrollSelectedItemIntoView(fTop:Boolean=false): void {
			if (dataProvider == null || _iSelected == -1)
				return;
				
			var obItem:Object = ItemFromIndex(_iSelected);
			if (obItem == null)
				return;
			var obRet:Object = GetSectionAndItemRendererFromItem(obItem);
			if (obRet == null)
				return;
					
			// Expand the item's section if necessary
			if ("expanded" in obRet.sectionRenderer) {
				if (!obRet.sectionRenderer.expanded) {
					// Section expansion will automatically make the selected
					// item visible
					obRet.sectionRenderer.expanded = true;
				} else {
					// Scroll the minimum necessary to make the item visible
					// UNDONE: sexy animation
					
					// Is the ItemRenderer off-view or clipped?
					var dobItemRenderer:DisplayObject = DisplayObject(obRet.itemRenderer);
					
					// This rectangle is offset by the amount the FontList is scrolled
					// (i.e. the current verticalScrollPosition)
					var rc:Rectangle = dobItemRenderer.getRect(this);
					if (!rc.isEmpty()) {
						// only scroll if rc is not empty.  Sometimes we try
						// to scroll before the rect is properly init'd and we
						// get weird values for top and bottom.
						if (fTop || rc.top < 0) {
							verticalScrollPosition += rc.top;
						} else if (rc.bottom > height) {
							verticalScrollPosition += rc.bottom - height - 1;
						}
					}
				}
			}
		}
		
		public function get selectable(): Boolean {
			return _fSelectable;
		}
		
		public function set selectable(f:Boolean): void {
			_fSelectable = f;
		}
		
		public function get keepSelectedItemVisible(): Boolean {
			return _fKeepSelectedItemVisible;
		}
		
		public function set keepSelectedItemVisible(f:Boolean): void {
			_fKeepSelectedItemVisible = true;
		}

		private function OnMouseDown(evt:MouseEvent): void {
			if (!_fSelectable)
				return;
				
			// BUGBUG: Flash's object hit testing is off by one pixel and returns the
			// DisplayObject one pixel to the left of the mouse coordinate. The localX
			// can therefore be one pixel off the right of the object's bounds. The
			// relevance to the SectionList is that based on event handling object A can
			// be highlighted but when the click is handled here our hit testing resolves
			// it to object B (the object one pixel to the right of object A).
			
			// This "stageX - 1" hack aligns our hit testing with Flash's. A subtle side-
			// effect is that clicks, highlights, etc happen one pixel to the left of the
			// mouse cursor point.
			var rndr:IDataRenderer = GetItemRendererFromPoint(new Point(evt.stageX - 1, evt.stageY)) as IDataRenderer;
			
			if (rndr && rndr.data && !(rndr.data is SectionBadgeInfo)) {
				selectedItem = rndr.data;			
				dispatchEvent(new Event(Event.CHANGE));
			}			
		}
		
		// Iterate through all the sections to find the index requested
		private function ItemFromIndex(i:int): Object {
			if (_dataProvider == null)
				return null;
				
			var iSectionHead:int = 0;
			for (var isec:int = 0; isec < _dataProvider.length; isec++) {
				var sec:Object = _dataProvider.getItemAt(isec);
				
				// In this section?
				if (i >= iSectionHead + sec.children.length) {
					// No, keep looking
					iSectionHead += sec.children.length;
					continue;
				}
				
				// Found it, return
				return sec.children[i - iSectionHead];
			}
			
			return null; // not found
		}
		
		// Iterate through all the sections to find the object requested
		private function IndexFromItem(ob:Object): int {
			if (_dataProvider == null)
				return -1;
				
			var iob:int = 0;
			for (var isec:int = 0; isec < _dataProvider.length; isec++) {
				var sec:Object = _dataProvider.getItemAt(isec);
				for (var i:int = 0; i < sec.children.length; i++) {
					if (sec.children[i] == ob)
						return iob;
					iob++;
				}
			}
			return -1; // not found
		}
		
		// Returns null if the point isn't on an item (e.g. is on a section header)
		private function GetItemRendererFromPoint(pts:Point): DisplayObject {
			for (var i:Number = 0; i < numChildren; i++) {
				var sect:ISectionRenderer = getChildAt(i) as ISectionRenderer;
				if (sect) {
					var dob:DisplayObject = sect.GetItemRendererFromPoint(pts);
					if (dob)
						return dob;
				}
			}
			return null;
		}
		
		public function GetSectionAndItemRendererFromItem(ob:Object): Object {
			for (var i:Number = 0; i < numChildren; i++) {
				var sect:ISectionRenderer = getChildAt(i) as ISectionRenderer;
				if (sect) {
					var dob:DisplayObject = sect.GetItemRendererFromItem(ob);
					if (dob)
						return { sectionRenderer: sect, itemRenderer: dob };
				}
			}
			return null;
		}
	}
}
