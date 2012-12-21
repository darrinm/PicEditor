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
package controls {
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.Canvas;
	import mx.core.Application;
	import mx.events.FlexEvent;
	
	public class MouseFollowingPremiumNagBase extends Canvas {
		public static function Show(): MouseFollowingPremiumNag {
			var mfn:MouseFollowingPremiumNag = new MouseFollowingPremiumNag();
			Application.application.systemManager.popUpChildren.addChild(mfn);
			return mfn;
		}
		
		public function Hide(): void {
			Application.application.systemManager.popUpChildren.removeChild(this);
		}
		
		public function MouseFollowingPremiumNagBase() {
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}
		
		private function OnCreationComplete(evt:FlexEvent): void {
			addEventListener(Event.REMOVED, OnRemoved);
			Application.application.stage.addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
			OnMouseMove();
		}
		
		private function OnMouseMove(evt:MouseEvent=null): void {
			var stage:Stage = Application.application.stage;
			x = stage.mouseX + 20;
			if (x + width > stage.stageWidth)
				x = stage.mouseX + 20 - width;
			y = stage.mouseY + 18;
		}
		
		private function OnRemoved(evt:Event): void {
			Application.application.stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
		}
	}
}
