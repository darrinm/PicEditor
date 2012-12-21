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
package events
{
	import flash.events.Event;

	public class SlideShowEvent extends Event {
		public static const SHOW_CONTROLS:String = "showControls";
		public static const HIDE_CONTROLS:String = "hideControls";
		public static const PLAY_STATE:String = "playState";
		public static const PROPERTY_CHANGE:String = "propertyChange";
		public static const IMAGE_PROPERTY_CHANGE:String = "imagePropertyChange";
		public static const CURRENT_IMAGE:String = "currentImage";
		public static const INSERT_IMAGE:String = "insertImage";
		public static const DELETE_IMAGE:String = "deleteImage";
		public static const MOVE_IMAGE:String = "moveImage";
		public static const DELETE_ALL_IMAGES:String = "deleteAllImages";
		public static const REFRESH:String = "refresh";
		public static const LOAD_PROGRESS:String = "premiumState";
		
		public var arg1:*;
		public var arg2:*;
		public var arg3:*;
		public var id:String;
		public var pos:int;
		public var info:Object;
		public var key:String;
		public var value:String;
		public var bytesLoaded:int;
		public var bytesTotal:int;
		
		public function SlideShowEvent(type:String, arg1:*=null, arg2:*=null, arg3:*=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			// generic handling
			this.arg1 = arg1;
			this.arg2 = arg2;
			this.arg3 = arg3;
			
			// CURRENT_IMAGE event
			// INSERT_IMAGE event
			if (type == SlideShowEvent.CURRENT_IMAGE ||
				type == SlideShowEvent.INSERT_IMAGE) {
				this.id = arg1 as String;
				this.pos = arg2 as int;
				this.info = arg3 as Object;
			}
			
			// DELETE_IMAGE
			// MOVE_IMAGE
			if (type == SlideShowEvent.DELETE_IMAGE ||
				type == SlideShowEvent.MOVE_IMAGE) {
				this.id = arg1 as String;
				this.pos = arg2 as int;
			}
			
			// DELETE_ALL_IMAGES
			// MOVE_IMAGE
			if (type == SlideShowEvent.DELETE_ALL_IMAGES) {
				// no args
			}
			
			// PROPERTY_CHANGE event
			if (type == SlideShowEvent.PROPERTY_CHANGE) {
				this.key = arg1 as String;
				this.value = arg2 as String;
			}
			
			// IMAGE_PROPERTY_CHANGE event
			if (type == SlideShowEvent.IMAGE_PROPERTY_CHANGE) {
				this.id = arg1 as String;
				this.key = arg2 as String;
				this.value = arg3 as String;
			}
			
			// LOAD_PROGRESS
			if (type == SlideShowEvent.LOAD_PROGRESS) {
				this.id = arg1 as String;
				this.bytesLoaded = arg2 as int;
				this.bytesTotal = arg3 as int;
			}			
			
			super(type, bubbles, cancelable);
		}
		
		// Override the inherited clone() method
		override public function clone(): Event {
			return new SlideShowEvent(type, arg1, arg2, arg3);
		}

	}
}