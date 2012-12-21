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
// This special event is used by the ImageView to provide drag/drop notifications to
// ViewObjects that won't be confused with the DragEvents the DragManager will also
// be providing.

package events {
	import flash.display.DisplayObject;
	
	import mx.core.DragSource;
	import mx.core.IUIComponent;
	import mx.events.DragEvent;
	
	public class ViewDragEvent extends DragEvent {
		public static const VIEW_DRAG_ENTER:String = "viewDragEnter";
		public static const VIEW_DRAG_EXIT:String = "viewDragExit";
		public static const VIEW_DRAG_OVER:String = "viewDragOver";
		public static const VIEW_DRAG_DROP:String = "viewDragDrop";
		
		private var _dobTarget:DisplayObject = null;
		private var _fPreventDefault:Boolean = false;
		
		public function ViewDragEvent(type:String, bubbles:Boolean = false,
				  cancelable:Boolean = true,
				  dragInitiator:IUIComponent = null,
				  dragSource:DragSource = null,
				  action:String = null,
				  ctrlKey:Boolean = false,
				  altKey:Boolean = false,
				  shiftKey:Boolean = false)
		{
			super(type, bubbles, cancelable, dragInitiator, dragSource, action, ctrlKey, altKey, shiftKey);
		}
		
		public function AcceptDragDrop(dob:DisplayObject): void {
			_dobTarget = dob;
		}
		
		public function get targetDisplayObject(): DisplayObject {
			return _dobTarget;
		}
		
		override public function preventDefault(): void {
			_fPreventDefault = true;
		}
		
		override public function isDefaultPrevented(): Boolean {
			return _fPreventDefault;
		}
	}
}
