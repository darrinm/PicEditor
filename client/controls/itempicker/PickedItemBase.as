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
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	import mx.containers.HBox;
	import mx.effects.Effect;
	import mx.events.FlexEvent;;

	public class PickedItemBase extends HBox implements IPickedItem {
		
		[Bindable] public var _effHighlight:Effect;
		
		public function PickedItemBase() {
			this.addEventListener( FlexEvent.INITIALIZE, OnInit );
			this.addEventListener( KeyboardEvent.KEY_DOWN, OnKeyDown );
		}
		
		protected function OnInit(evt:Event):void {
			this.addEventListener( FocusEvent.FOCUS_IN, OnFocusIn );
			this.addEventListener( FocusEvent.FOCUS_OUT, OnFocusOut );
		}	
			
		protected function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.BACKSPACE ||
				evt.keyCode == Keyboard.DELETE) {
				Remove();
			}
		}
	
		private function GetItemPicker():ItemPicker {
			var dobParent:DisplayObjectContainer = this.parent;
			while (dobParent) {
				if (dobParent is ItemPicker)
					return dobParent as ItemPicker;
				dobParent = dobParent.parent;
			}
			return null;
		}
	
		public function OnPicked(): void {
			
		}
		
		override protected function measure():void {
			super.measure();
		}
		
		public function OnUnpicked(): void {
			
		}
	
		public function Highlight(): void {
			_effHighlight.end();
			_effHighlight.play();
		}
		
		public function GetData():Object {	
			return this.data;
		}
			
		protected function Remove():void {
			var itemPicker:ItemPicker = GetItemPicker();
			if (itemPicker)
				itemPicker.UnpickItem( data );
		}
		
		protected function OnFocusIn(evt:FocusEvent): void {
			this.setStyle("borderColor", "#618430");
			this.setStyle("backgroundColor", "#d6efb2");
		}
	
		protected function OnFocusOut(evt:FocusEvent): void {
			this.setStyle("borderColor", "#bbe57f");
			this.setStyle("backgroundColor", "#ebfad5");
		}
	}
}
