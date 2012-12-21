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
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class SlideShowAction extends Event {
		public static const ACTION_LAUNCH_PICNIK:String = "LaunchPicnik";
		public static const ACTION_SAVE_CURRENT_IMAGE:String = "SaveCurrentImage";
		public static const ACTION_EDIT_CURRENT_IMAGE:String = "EditCurrentImage";
		public static const ACTION_SHARE_SLIDESHOW:String = "ShareSlideshow";
		public static const ACTION_EDIT_SLIDESHOW:String = "EditSlideshow";
		
		public function SlideShowAction(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}		
	}
}
