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
package containers.sectionList {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.IEventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.XMLListCollection;
	import mx.containers.Box;
	import mx.core.IDataRenderer;
	import mx.core.IFactory;
	import mx.effects.Resize;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.ResizeEvent;
	
	import util.SectionBadgeInfo;

	// A section renderer renders a header and a list of child items
	public class BoxSectionRenderer extends Box implements ISectionRenderer {
		[Bindable] public var _bxChildItems:Box = null;
		[Bindable] public var _hdr:SectionHeader = null;
		[Bindable] public var initialExpanded:Boolean = false;
		[Bindable] public var childHeight:Number = NaN;
		[Bindable] public var showHeader:Boolean = true;
		
		protected var _clItemRenderer:Class = null;
		protected var _dataProvider:IList = null;
		
		private var _fItemsInvalid:Boolean = true;
		private var _fExpanded:Boolean = true;
		private var _fDispatchGrowEvents:Boolean = false;
		private var _iInitialSelection:int = -1;
		
		// We need to declare the section badges we support or they don't get compiled in
		static public const kclSectionBadge_FontShop:Class = SectionBadge_FontShop;

		public function BoxSectionRenderer(): void {
			direction = "vertical"; // Default to a VBox. Easy to change
			addEventListener(ResizeEvent.RESIZE, OnResize);
		}
		
		//
		// ISectionRenderer implementation
		//
		
		public function set active(fActive:Boolean): void {
			if (!_bxChildItems) return;
			for (var i:Number = 0; i < _bxChildItems.numChildren; i++) {
				var dobItemRenderer:DisplayObject = _bxChildItems.getChildAt(i);
				if ('active' in dobItemRenderer) dobItemRenderer['active'] = fActive;
			}
		}
		
		// Item renderer should be either a display object class or a factor class that creates display ojbects.
		// You can use the factor class with a factor that returns data as a pass through item renderer
		public function set itemRenderer(cl:Class):void {
			_clItemRenderer = cl;
			_fItemsInvalid = true;
			invalidateProperties();
		}

		// heading.data = data
		// childDataProvider = data.children
		[Bindable]
		override public function set data(ob:Object):void {
			super.data = ob;
			dataProvider = ob.children;
			initialExpanded = true;
			if (ob.hasOwnProperty("expanded"))
				if (ob.expanded == "premium")
					initialExpanded = !ob.premium || AccountMgr.GetInstance().isPremium;
				else
					if (ob.expanded is Boolean)
						initialExpanded = ob.expanded;
					else
						initialExpanded = (ob.expanded == "true");
		}
		
		public function set initialSelectedIndex(i:int): void {
			_iInitialSelection = i;
		}
		
		// Passed-in point is in stage coordinates
		public function GetItemRendererFromPoint(pts:Point): DisplayObject {
			if (!expanded)
				return null;
				
			var rcs:Rectangle;
			for (var i:Number = 0; i < _bxChildItems.numChildren; i++) {
				var dobItemRenderer:DisplayObject = _bxChildItems.getChildAt(i);
				rcs = dobItemRenderer.getRect(stage);
				if (rcs.containsPoint(pts)) {
					
					// The BoxSectionRenderer's children may actually just be containers
					// for the ItemRenderers. If so, drill in and find the child ItemRenderer
					// at the point.
					if (dobItemRenderer is DisplayObjectContainer) {
						if (!(dobItemRenderer is IDataRenderer) || IDataRenderer(dobItemRenderer).data == null) {
							var dobc:DisplayObjectContainer = DisplayObjectContainer(dobItemRenderer);
							for (var j:int = 0; j < dobc.numChildren; j++) {
								var rndr:DisplayObject = dobc.getChildAt(j);
								if (!(rndr is IDataRenderer))
									continue;
								rcs = rndr.getRect(stage);
								if (rcs.containsPoint(pts))
									return rndr;
							}
						}
					}
					return dobItemRenderer;
				}
			}
			return null;
		}
		
		public function GetItemRendererFromItem(obItem:Object): DisplayObject {
			for (var i:Number = 0; i < _bxChildItems.numChildren; i++) {
				var obItemRenderer:Object = _bxChildItems.getChildAt(i) as Object;
				if (!("data" in obItemRenderer))
					continue;
				if (obItemRenderer.data == obItem)
					return obItemRenderer as DisplayObject;
			}
			return null;
		}
		
		public function set headingRenderer(cl:Class):void {
			_fItemsInvalid = true;
			invalidateProperties();
		}

		protected function OnResize(evt:ResizeEvent): void {
			if (evt.oldHeight < height && _fDispatchGrowEvents) {
				// If this section contains a selected ItemRenderer we want to make sure
				// the expansion process makes it visible. We can do that by having the
				// selected ItemRenderer dispatch the SECTION_GROWING event.
				var evtd:IEventDispatcher = this;
				for (var i:Number = 0; i < _bxChildItems.numChildren; i++) {
					var obItemRenderer:Object = _bxChildItems.getChildAt(i);
					if ("selected" in obItemRenderer && obItemRenderer.selected) {
						evtd = IEventDispatcher(obItemRenderer);
						break;
					}
				}

				evtd.dispatchEvent(new Event(SectionListBase.SECTION_GROWING, true));
			}
		}
		
		[Bindable]
		public function set expanded(fExpanded:Boolean): void {
			if (_fExpanded != fExpanded) {
				_fExpanded = fExpanded;
				// Don't start dispatching grow events until the first time we expand
				if (_fExpanded)
					_fDispatchGrowEvents = true;
				
				if (_bxChildItems) {
					var effResize:Resize = new Resize(_bxChildItems);
					
					if (isNaN( _bxChildItems.height))
						effResize.heightFrom = 0
					else
						effResize.heightFrom = _bxChildItems.height;
					
					effResize.heightTo = _fExpanded ? _bxChildItems.measuredHeight : 0;
					effResize.duration = 300;
					_bxChildItems.endEffectsStarted();
					effResize.play();
				}
			}
		}
		
		public function get expanded(): Boolean {
			return _fExpanded;
		}
		
		// obValue can be either Array, IList, or ArrayCollection
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
		
		protected function OnDataChange(evt:CollectionEvent): void {
			// Recreate everything
			if (evt.kind != CollectionEventKind.UPDATE) {
				_fItemsInvalid = true;
				invalidateProperties();
			}
		}
		
		private var _cwExpanded:ChangeWatcher = null;
		
		protected function RecreateSectionItems(): void {
			_fItemsInvalid = false;
			
			// First, remove any existing items.
			_bxChildItems.removeAllChildren();
			
			// Next, create children if we can
			if (_clItemRenderer && _dataProvider && data) {
				CreateChildren();
			}
			invalidateSize();
		}
		
		// Override this for children that are not in a linear list (e.g. shapes)
		protected function CreateChildren(): void {
			for (var i:int = 0; i < _dataProvider.length; i++) {
				var data:Object = _dataProvider.getItemAt(i);
				var dobItem:DisplayObject = null;					
				if (data is SectionBadgeInfo) {
					var secB:SectionBadgeInfo = data as SectionBadgeInfo;
					if (secB.category == "FontShop") {
						dobItem = new SectionBadge_FontShop();
						dobItem["data"] = _dataProvider.getItemAt(i);
					}
					if (dobItem)
						_bxChildItems.addChild(dobItem);
				} else {
					var obItem:Object = new _clItemRenderer();
					obItem["data"] = _dataProvider.getItemAt(i);
					if (obItem is IFactory)
						dobItem = (obItem as IFactory).newInstance() as DisplayObject;
					else
						dobItem = obItem as DisplayObject;
					_bxChildItems.addChild(dobItem);
					if (i == _iInitialSelection) {
						if ("selected" in dobItem)
							dobItem["selected"] = true;
					}
				}
			}
			
			// reset our size
			expanded = initialExpanded;
		}
		
		override protected function commitProperties():void {
			super.commitProperties();
			
			if (_fItemsInvalid) {
				RecreateSectionItems();
			}
		}
	}
}
