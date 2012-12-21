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
package containers
{
	import flash.events.MouseEvent;
	import events.PassThroughMouseEvent;
	import mx.controls.Button;
	
	public class HBoxButton extends ResizingHBox
	{
		private var _btn:Button = null;

		public function HBoxButton(): void {
			addEventListener(MouseEvent.MOUSE_DOWN, MouseAction);
			addEventListener(MouseEvent.MOUSE_UP, MouseAction);
			addEventListener(MouseEvent.MOUSE_OVER, MouseAction);
			addEventListener(MouseEvent.MOUSE_OUT, MouseAction);
			addEventListener(MouseEvent.ROLL_OVER, MouseAction);
			addEventListener(MouseEvent.ROLL_OUT, MouseAction);
			addEventListener(MouseEvent.CLICK, MouseAction);
		}
		
		[Bindable]
		public function set button(btn:Button): void {
			_btn = btn;
			button.mouseChildren = false;
			button.mouseEnabled = false;
		}
		
		public function get button(): Button {
			return _btn;
		}
		
		protected function MouseAction(evt:MouseEvent): void {
			if (button == null) return;
			if (evt is PassThroughMouseEvent) return;
			button.dispatchEvent(new PassThroughMouseEvent(evt));
		}
	}
}