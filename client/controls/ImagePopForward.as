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
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	
	public class ImagePopForward extends ImagePlus {
		
		[Bindable] public var autoPopForward:Boolean = true;
		
		public function ImagePopForward() {
			super();
			addEventListener(MouseEvent.ROLL_OVER, OnRollOver);
		}

		private function OnRollOver(evt:MouseEvent): void {
			// pop forward!
			if (autoPopForward) {
				PopForward();
			}
		}
		
		public function PopForward(): void {
			// pop forward!
			if (parent) {
				var dobParent:DisplayObjectContainer = parent;
				dobParent.removeChild(this);
				dobParent.addChild(this);
			}
		}
	}
}
