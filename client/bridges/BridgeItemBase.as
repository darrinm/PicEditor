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
package bridges
{
	import controls.list.ITileListItem;
	
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import mx.containers.Box;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.controls.TextInput;
	import mx.events.FlexEvent;
	import mx.events.ToolTipEvent;

	// The BridgeItemBase class is an item renderer for in bridge tile lists.
	// It renders the image thumbnail and tools to interact with the image
	// It generates events related to user actions, such as edit, delete, rename, email, etc.
	// This class looks for a parent class of type "bridge" in order to determine
	// which operations are supported for this specific bridge (e.g. web in bridge does not support delete)
	// This is done by calling the Bridge.GetMenuItems() function.
	public class BridgeItemBase extends Box implements ITileListItem
	{
		[Bindable] public var _btnMenu:Button;
		[Bindable] public var _tiName:TextInput;
		[Bindable] public var _vboxThumbnail:VBox;
		[Bindable] public var _imgThumbnail:Image;
		
		private var _astrMenuItems:Array = null;
		
		private var _fHighlighted:Boolean = false;
		private var _fSelected:Boolean = false;
		
		public function BridgeItemBase() {
			super();
			cacheAsBitmap = true;
		}
		
		public function isLoaded(): Boolean {
			if (!_imgThumbnail) return true;
			var nWidth:Number = _imgThumbnail.contentWidth;
			return (!isNaN(nWidth)) && nWidth > 0;
		}
		
		public function get highlighted(): Boolean {
			return _fHighlighted;
		}
		
		public function get selected(): Boolean {
			return _fSelected;
		}
		
		public function set highlighted(f:Boolean): void {
			_fHighlighted = f;
			UpdateState();
		}
		
		public function set selected(f:Boolean): void {
			_fSelected = f;
			UpdateState();
		}
		
		public override function set enabled(f:Boolean):void {
			super.enabled = f;
			UpdateState();
		}
		
		public override function get enabled(): Boolean {
			return super.enabled;
		}
		
		public function setState(fHighlighted:Boolean, fSelected:Boolean, fEnabled:Boolean): void {
			_fHighlighted = fHighlighted;
			_fSelected = fSelected;
			super.enabled = fEnabled;
			UpdateState();
		}
		
		private function UpdateState(): void {
			var strState:String = "NotSelected";
			if (_fSelected) strState = "Selected";
			else if (_fHighlighted) strState = "Highlight";
			if (ReadOnly()) strState += "ReadOnly";
			
			// Disable the item if there is enabled limit and the item exceeds it.
			if (!enabled)
				strState = "Disabled" + strState;

			if (currentState != strState) currentState = strState;
		}
		
		public function OnInitialize(): void {
			if (_btnMenu) {
				_btnMenu.addEventListener(MouseEvent.CLICK, OnMenuButtonClick);
				_btnMenu.addEventListener(MouseEvent.DOUBLE_CLICK, OnMenuButtonClick);
			}
			addEventListener(BridgeItemEvent.ITEM_ACTION, OnBridgeItemEvent);
			if (_imgThumbnail) _imgThumbnail.addEventListener(Event.COMPLETE, OnThumbnailLoadComplete);
//			_vboxThumbnail.addEventListener(ToolTipEvent.TOOL_TIP_CREATE, OnToolTipEvent);
			if (!ReadOnly()) {
				_tiName.addEventListener(KeyboardEvent.KEY_DOWN, OnNameKeyDown);
				_tiName.addEventListener(FlexEvent.VALUE_COMMIT, OnNameValueCommit);
				_tiName.addEventListener(FlexEvent.ENTER, OnNameEnter);
				_tiName.addEventListener(MouseEvent.DOUBLE_CLICK, HideEvent);
				_tiName.addEventListener(FocusEvent.FOCUS_IN, OnFocusIn);
			}
		}
		
		private function OnThumbnailLoadComplete(evt:Event): void {
			// We may be able to turn smoothing on for the thumbnail. Smoothing only
			// works if the file is loaded from our own domain or from one with a
			// crossdomain.xml <allow-access-from domain="*"> file.
			try {
				evt.target.content.smoothing = true;
//				evt.target.content.pixelSnapping = PixelSnapping.ALWAYS;
			} catch (err:Error) {
			}
			evt.target.removeEventListener(Event.COMPLETE, OnThumbnailLoadComplete);
		}
		
		private function OnToolTipEvent(evt:ToolTipEvent): void {
			// Give anyone who is interested the opportunity to create the tooltip
			var br:Bridge = GetBridgeParent();
			if (br != null)
				br.dispatchEvent(new BridgeItemEvent(BridgeItemEvent.TOOL_TIP_CREATE, this, null, evt));
		}

		private function OnNameEnter(evt:Event): void {
			setFocus(); // Remove the focus from the text field when you hit enter.
		}

		private function OnNameValueCommit(evt:Event): void {
			// Make sure the beginning of the string is what is displayed.
			_tiName.horizontalScrollPosition = 0;
			
			if (data && !ReadOnly() && _tiName.text.toString() != data.title) {
				// Make sure this event bubbles up to the tile list by setting the last
				// constructor param to true (bubbles).
				var evtOut:BridgeItemEvent = new BridgeItemEvent(BridgeItemEvent.ITEM_ACTION, this, Bridge.COMMIT_RENAME_ITEM, null, true);
				evtOut.data = _tiName.text;
				dispatchEvent(evtOut);
			}
		}
		
		public function ReadOnly(): Boolean {
			if (_tiName == null) return true;
			var brgParent:Bridge = GetBridgeParent();
			if (brgParent == null)
				return true;
			return !brgParent.NameIsEditable();
		}
		
		public function OnBridgeItemEvent(evt:BridgeItemEvent): void {
			if (!ReadOnly() && evt.action == Bridge.RENAME_ITEM) {
				_tiName.setFocus();
			}
		}
		
		private function OnFocusIn(evt:FocusEvent): void {
			PicnikBase.app.ExitFullscreenMode();
		}

		// Look	for an ancestor of type Bridge. Returns null if none found.
		public function GetBridgeParent(): Bridge {
			var doc:DisplayObjectContainer = this.parent;
			while (doc != null) {
				if (doc is Bridge) {
					return Bridge(doc);
				}
				doc = doc.parent;
			}
			return null;
		}
		
		// Get the menu items from the bridge ancestor
		private function LoadMenuItems(): void {
			// HACK: don't cache menu items so they can change dynamically. The WebInBridge takes
			// advantage of this to show the "Open Flickr page" item (or not) depending on whether
			// the thumbnail was produced by the Flickr interestingness easter egg. If this has
			// a perceptable impact on performance find a better solution.
//			if (_astrMenuItems == null) {
				var br:Bridge = GetBridgeParent();
				if (br != null) _astrMenuItems = br.GetMenuItems();
//			}
		}
		
		// Popup the menu when the menu button is clicked.
		private function OnMenuButtonClick(evt:MouseEvent): void {
			LoadMenuItems();
			new BridgeMenuItem().Show(this, _btnMenu, _astrMenuItems);
			evt.stopPropagation();
		}
		
		private function OnNameKeyDown(evt:KeyboardEvent): void {
			if (!ReadOnly() && evt.keyCode == Keyboard.ESCAPE) {
				_tiName.text = data.title;
				setFocus();
			}
			evt.stopPropagation();
		}
		
		private function HideEvent(evt:Event): void {
			evt.stopPropagation();
		}
	}
}