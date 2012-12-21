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
/**
 * The SpiderWebMSR controller is only active while the SpiderWebEffect is in use.
 * Afterwards the standard MSR controller is used so the web behaves as any other
 * sticker.
 */

package controllers {
	import flash.display.DisplayObject;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;

	public class SpiderWebMSR extends MoveSizeRotate {
		public function SpiderWebMSR(imgv:ImageView, dob:DisplayObject, fCrop:Boolean=true) {
			super(imgv, dob, fCrop);
			_fRecordUndoHistory = false;
		}
		
		// Don't the the user delete the spider web during the creation process.
		override protected function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.DELETE || evt.keyCode == Keyboard.BACKSPACE)
				return;
			super.OnKeyDown(evt);
		}
	}
}
