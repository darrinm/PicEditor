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
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.core.UIComponentGlobals;
	import mx.core.mx_internal;
	import mx.effects.Tween;
	import mx.events.FlexEvent;
	import mx.events.FlexMouseEvent;
	import mx.events.ListEvent;
	import mx.managers.PopUpManager;
	
	use namespace mx_internal;

	[Event(name="loaded", type="flash.events.Event")]
	[Event(name="change", type="flash.events.Event")]

	public class FontComboBoxBase extends Canvas {
		[Bindable] public var _fntl:FontList;
		
		[Bindable] public var loaded:Boolean = false;
		[Bindable] public var _btnDropdown:Button;
		[Bindable] public var _imgSelected:Image;
		[Bindable] public var premiumColor:uint = 0x005580;
		[Bindable] public var _fltDropdown:DropShadowFilter;
		
		private var _fEnabled:Boolean = false;
		private var _fDropDown:Boolean = false;
		private var _cyDropDown:Number = 0;
		private var _iSelected:Number = -1; // holds the selected index until _fntl is initialized
		private var _fShowingDropdown:Boolean = false;
		
		public function FontComboBoxBase(): void {
			super.enabled = false;
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
		}
		
		private function OnInitialize(evt:Event): void {
			_fntl.addEventListener("loaded", OnFontListLoaded);
			_fntl.addEventListener(Event.CHANGE, OnChange);
            _btnDropdown.addEventListener(FlexEvent.BUTTON_DOWN, OnDropdownButtonDown);
           
            _fntl.addEventListener(FlexMouseEvent.MOUSE_DOWN_OUTSIDE, OnDropdownMouseDownOutsideHandler);
            _fntl.addEventListener(FlexMouseEvent.MOUSE_WHEEL_OUTSIDE, OnDropdownMouseDownOutsideHandler);
		}
		
		public function set active(fActive:Boolean): void {
			_fntl.active = fActive;
		}
		
		private function OnFontListLoaded(evt:Event): void {
			super.enabled = _fEnabled;
			loaded = true;
			dispatchEvent(new Event("loaded"));
			
			_fntl.selectedIndex = _iSelected;
		}
		
		private function OnChange(evt:Event=null): void {
			if (!loaded)
				return;
			var obItem:Object = _fntl.selectedItem;
			if (obItem == null)
				return;

			// When the selection changes, update the imgSelected's color to reflect the
			// font's premiumness.
			if ("premium" in obItem) {
				var cot:ColorTransform = new ColorTransform();
				cot.color = obItem.premium ? premiumColor : 0;
				_imgSelected.transform.colorTransform = cot;
			}
			
			// Let Combo listeners know the selection has changed
			dispatchEvent(new Event(Event.CHANGE));
			
			// If the dropdown list is open, close it
			if (_fntl.isPopUp)
				CloseDropdown();
		}
		
		private function OnDropdownButtonDown(evt:FlexEvent): void {
			// The down arrow should always toggle the visibility of the dropdown.
			if (_fShowingDropdown) {
	            CloseDropdown(evt);
			} else {
				ShowDropdown(true, evt);
			}
		}

		private var _selectedIndexOnDropdown:int = -1;
		private var inTween:Boolean = false;
	   
	    /**
	     *  @private
	     *  The tween used for showing and hiding the drop-down list.
	     */
	    private var tween:Tween = null;
	   
	    /**
	     *  @private
	     *  A flag to track whether the dropDown tweened up or down.
	     */
	    private var tweenUp:Boolean = false;

	    /**
	     *  @private
	     *  Event that is causing the dropDown to open or close.
	     */
	    private var triggerEvent:Event;

	    private function ShowDropdown(fShow:Boolean, trigger:Event = null): void {
	        // Show or hide the dropdown
	        var initY:Number;
	        var endY:Number;
	        var duration:Number;
	        var easingFunction:Function;
	
	        var point:Point = new Point(0, unscaledHeight);
	        point = _btnDropdown.localToGlobal(point);
	       
	        //opening the dropdown
	        if (fShow) {
	            // Store the selectedIndex temporarily so we can tell
	            // if the value changed when the dropdown is closed
	            _selectedIndexOnDropdown = selectedIndex;
	            _fntl.width = _btnDropdown.width;
	
				if (_fntl.parent) {
					if (_fntl.isPopUp)
						PopUpManager.removePopUp(_fntl);
					_fntl.parent.removeChild(_fntl);
				}
				_fntl.visible = true;
                PopUpManager.addPopUp(_fntl, this);
	            point = _fntl.parent.globalToLocal(point);
	            _fntl.height = screen.height - point.y - 3; // -3 so the shadow can be seen
                initY = _fntl.height;
	       
				_fntl.ScrollSelectedItemIntoView();
	
	            if (_fntl.x != point.x || _fntl.y != point.y)
	                _fntl.move(point.x, point.y);
	
	            _fntl.scrollRect = new Rectangle(0, initY, _fntl.width, _fntl.height);
	
	            // Set up the tween and relevant variables.
	            _fShowingDropdown = true;
	            duration = getStyle("openDuration");
	            endY = 0;
	            easingFunction = getStyle("openEasingFunction") as Function;
	        }
	       
	        // closing the dropdown
	        else if (_fntl) {
	            point = _fntl.parent.globalToLocal(point);
	            // Set up the tween and relevant variables.
	            endY = (point.y + _fntl.height > screen.height || tweenUp
	                               ? -_fntl.height
	                               : _fntl.height);
	            _fShowingDropdown = false;
	            initY = 0;
	            duration = getStyle("closeDuration");
	            easingFunction = getStyle("closeEasingFunction") as Function;
	        }
	       
	        inTween = true;
	       
	        // WTF? without this the background of the tweening SectionList doesn't get drawn!
	        UIComponentGlobals.layoutManager.validateNow();
	       
	        // Block all layout, responses from web service, and other background
	        // processing until the tween finishes executing.
	        UIComponent.suspendBackgroundProcessing();
	       
	        // Disable the dropdown during the tween.
	        if (_fntl)
	            _fntl.enabled = false;
	       
	        duration = Math.max(1, duration);
	        tween = new Tween(this, initY, endY, duration);
	       
	        if (easingFunction != null && tween)
	            tween.easingFunction = easingFunction;
	           
	        triggerEvent = trigger;
	    }
	   
	    public function CloseDropdown(trigger:Event = null): void {
	        if (_fShowingDropdown) {
	            ShowDropdown(false, trigger);
	
	            dispatchChangeEvent(new Event("dummy"), _selectedIndexOnDropdown, selectedIndex);
	        }
	    }

	    private function dispatchChangeEvent(oldEvent:Event, prevValue:int, newValue:int): void {
	        if (prevValue != newValue) {
	            var newEvent:Event = oldEvent is ListEvent ? oldEvent : new ListEvent("change");
	            dispatchEvent(newEvent);
	        }
	    }

	    private function OnDropdownMouseDownOutsideHandler(event:FlexMouseEvent): void {
	        if (event.target != _fntl)
	            // the dropdown's items can dispatch a mouseDownOutside
	            // event which then bubbles up to us
	            return;
	
	        if (!hitTestPoint(event.stageX, event.stageY, true)) {
	            CloseDropdown(event);
	        }
	    }
		
	    //--------------------------------------------------------------------------
	    //
	    // Tween handlers
	    //
	    //--------------------------------------------------------------------------

		// Has to be public so Tween.as can find it	
	    public function onTweenUpdate(value:Number): void {
	        if (_fntl) {
	            _fntl.scrollRect = new Rectangle(0, value,
	                _fntl.width, _fntl.height);
	        }
	    }
	
		// Has to be public so Tween.as can find it	
	    public function onTweenEnd(value:Number): void {
            // Clear the scrollRect here. This way if drop shadows are
            // assigned to the dropdown they show up correctly
            _fntl.scrollRect = null;

            inTween = false;
            _fntl.enabled = true;
            _fntl.visible = _fShowingDropdown;
           
            if (!_fShowingDropdown) {
            	if (_fntl.isPopUp)
            		PopUpManager.removePopUp(_fntl);
            }
           
	        UIComponent.resumeBackgroundProcessing();
	    }
	
		[Bindable]
		public function set dropdown(fDropDown:Boolean): void {
			_fDropDown = fDropDown;
			if (_fDropDown) {
				_fntl.filters = [ _fltDropdown ];
			} else {
				_fntl.filters = null;
				if (_fntl.parent != this) {
					if (_fShowingDropdown) {
						_fShowingDropdown = false;
						PopUpManager.removePopUp(_fntl);
					}
					addChild(_fntl);
		            _fntl.x = 0;
		            _fntl.y = 0;
		            _fntl.percentWidth = 100;
		            _fntl.percentHeight = 100;
				}
				validateNow();
	            _fntl.ScrollSelectedItemIntoView(true);
			}
		}
		
		public function get dropdown(): Boolean {
			return _fDropDown;
		}
		
		[Bindable]
		public function set dropdownHeight(cy:Number): void {
			_cyDropDown = cy;
			// UNDONE: resize dropdown list
		}
		
		public function get dropdownHeight(): Number {
			return _cyDropDown;
		}
		
		// UNDONE: supposed to be enabling/disabling the dropdown button & FontList? [list takes care of itself]
		public override function set enabled(fEnabled:Boolean): void {
			_fEnabled = fEnabled;
			if (loaded)
				super.enabled = fEnabled;
		}
		
	    public override function get enabled():Boolean {
			return _fEnabled;
		}
		
		//
		// Selection support
		//

		[Bindable]
		public function set selectedItem(data:Object):void {
			_fntl.selectedItem = data;
		}
		
		public function get selectedItem(): Object {
			if (_fntl == null)
				return null;
			return _fntl.selectedItem;
		}
		
		[Bindable]
		public function set selectedIndex(i:int): void {
			if (_fntl == null) {
				_iSelected = i;
				return;
			}
			_fntl.selectedIndex = i;
			
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function get selectedIndex(): int {
			if (_fntl == null)
				return -1;
			return _fntl.selectedIndex;
		}
	}
}
