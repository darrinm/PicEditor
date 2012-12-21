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
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	import mx.collections.CursorBookmark;
	import mx.controls.ComboBox;
	import mx.core.mx_internal;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;

	use namespace mx_internal;

	//--------------------------------------
	//  Events
	//--------------------------------------
	
	/**
	 *  Dispatched when the ComboBox live contents changes as a result of user
	 *  interaction, when the <code>liveSelectedIndex</code> or
	 *  <code>liveSelectedItem</code>
	 *
	 *  @eventType mx.events.Event
	 */
	[Event(name="liveChange", type="flash.events.Event")]

	
	public class ComboBoxPlus extends ComboBox
	{
		private var _nLiveSelectedIndex:Number;
		private var _nRowCount:Number = 5;

		public function ComboBoxPlus()
		{
			addEventListener(ListEvent.ITEM_ROLL_OVER, OnItemRollOutOver, false, -1);
			addEventListener(ListEvent.ITEM_ROLL_OUT, OnItemRollOutOver, false, -1);
			addEventListener(ListEvent.CHANGE, OnSelectedIndexChange);
			OnSelectedIndexChange();
		}
		
    	[Bindable("liveChange")]
		public function set liveSelectedIndex(n:Number): void {
			if (!isShowingDropdown) {
				selectedIndex = n;
				SetLiveSelectedIndex(n);
			} else {
				// Ignore it while we are dropped down
			}
		}

		public function get liveSelectedIndex(): Number {
			return _nLiveSelectedIndex;
		}
		
		// Copied from ComboBase.value
    	[Bindable("liveChange")]
	    public function get liveValue():Object
	    {
	        if (editable)
	            return text;
	
	        var item:Object = liveSelectedItem;
	
	        if (item == null || typeof(item) != "object")
	            return item;
	
	        // Note: the explicit comparison with null is important, because otherwise when
	        // the data is zero, the label will be returned.  See bug 183294 for an example.
	        return item.data != null ? item.data : item.label;
	    }
		
		private function SetLiveSelectedIndex(n:Number): void {
			if (_nLiveSelectedIndex != n) {
				_nLiveSelectedIndex = n;
				dispatchEvent(new Event("liveChange"));
			}			
		}
		
    	[Bindable("liveChange")]
		public function set liveSelectedItem(ob:Object): void {
			if (!isShowingDropdown) {
				// Not showing the drop down.
				selectedItem = ob;
			} else {
				// Showing the drop down.
				// ignore
			}
		}
		
		public function get liveSelectedItem(): Object {
			var obSelectedItem:Object = null;
			if (!isShowingDropdown) {
				obSelectedItem = selectedItem;
			} else {
				if (liveSelectedIndex >= 0) {
					var bookmark:CursorBookmark = iterator.bookmark;
					iterator.seek(CursorBookmark.FIRST, Math.min(liveSelectedIndex, collection.length - 1));
					obSelectedItem = iterator.current;
					iterator.seek(bookmark, 0); // Go back to previous loc
				}
			}
			return obSelectedItem;
		}
		
		private function OnSelectedIndexChange(evt:Event=null): void {
			liveSelectedIndex = selectedIndex;
		}
		
		private var _aevtRollEvents:Array = [];
		
		private function OnItemRollOutOver(evt:ListEvent): void {
			// RollOvers and RollOuts don't come in a reliable order!
			// In this case we don't want to execute the RollOut handler if we're
			// just rolling from item to item.
			// Solultion: defer handling until we know what happened
			_aevtRollEvents.push(evt);
			if (_aevtRollEvents.length == 1)
				callLater(OnLaterItemRollOutOver)
		}
		
		private function OnLaterItemRollOutOver(): void {
			// Look for a roll over event. If there isn't one we'll go with the newest roll out
			for each (var evt:ListEvent in _aevtRollEvents) {
				if (evt.type == ListEvent.ITEM_ROLL_OVER)
					break;
			}
			_aevtRollEvents = [];
			SetLiveSelectedIndex(evt.type == ListEvent.ITEM_ROLL_OUT ? selectedIndex : evt.rowIndex);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			textInput.y = Math.round((height - textInput.measuredHeight)/2);
		}
		private function OnBeforeDropDown(): void {
			UpdateSuperRowCount();
		}
		
		/// BEGIN: Catch places which show the dropdown
		override public function open():void {
			OnBeforeDropDown();
			super.open();
		}

		override protected function downArrowButton_buttonDownHandler(event:FlexEvent):void
		{
		    // The down arrow should always toggle the visibility of the dropdown.
		    if (!isShowingDropdown) OnBeforeDropDown();
		    super.downArrowButton_buttonDownHandler(event);
		}

		override protected function keyDownHandler(event:KeyboardEvent):void
		{
		    // If a the editable field currently has focus, it is handling
		    // all arrow keys. We shouldn't also scroll this selection.
		    if (event.target != textInput && event.ctrlKey && event.keyCode == Keyboard.DOWN) {
			    OnBeforeDropDown();
			}
		   	super.keyDownHandler(event);
		}
		/// END: Catch places which show the dropdown
		private function UpdateSuperRowCount(): void {
			var nTargetRowCount:Number = _nRowCount; // default is 5
			
			// Go smaller if we have fewer items
			nTargetRowCount = Math.min(nTargetRowCount, collection.length);
			
			// Also limit it by the number of rows which fit above or below this drop down
			if (dropdown && dropdown.height && dropdown.rowHeight) {
				var nRowSize:Number = dropdown.rowHeight;
				
				var ptComboBox:Point = new Point(0, 0);
				ptComboBox = localToGlobal(ptComboBox);
				var nSpace:Number = Math.max(ptComboBox.y, screen.height - ptComboBox.y - height); // max top or bottom space
				nTargetRowCount = Math.min(nTargetRowCount, Math.floor(nSpace / nRowSize));
			}
			
			// Always show at least two rows
			nTargetRowCount = Math.max(2, nTargetRowCount);
			
			var fValidate:Boolean = dropdown && dropdown.rowCount != nTargetRowCount;
			super.rowCount = nTargetRowCount;
			if (fValidate)
				dropdown.validateNow();
		}
		
		[Bindable("resize")]
		[Inspectable(category="General", defaultValue="5")]
		override public function set rowCount(value:int):void {
			_nRowCount = value;
			UpdateSuperRowCount();
		}
	}
}