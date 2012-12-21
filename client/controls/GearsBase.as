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
	
	import mx.containers.Box;
	import mx.controls.Image;
	import mx.events.FlexEvent;

	public class GearsBase extends Box
	{
		[Bindable] public var _imgGears:Image;
		
		private var _obSource:Object = null;
		
		public override function set visible(value:Boolean):void {
			super.visible = value;
			updateGears();
		}
		
		override protected function initializationComplete(): void {
			super.initializationComplete();
			addEventListener(FlexEvent.SHOW, OnVisibleChange);
			addEventListener(FlexEvent.HIDE, OnVisibleChange);
			updateGears();
		}
		
		protected function OnVisibleChange(evt:FlexEvent): void {
			updateGears();
		}
		
		override protected function createChildren():void {
			super.createChildren();
			if (_obSource) _imgGears.source = _obSource;
		}
		
		[Inspectable(category="General", defaultValue="", format="File")]
		[Bindable]
		public function set source(ob:Object): void {
			if (_imgGears) _imgGears.source = ob;
			else _obSource = ob;
		}

		public function get source(): Object {
			if (_imgGears) return _imgGears.source;
			else return _obSource;
		}
		
		// Add or remove the child gears based on the visible state
		protected function updateGears(): void {
			if (visible) {
				if (numChildren == 0) addChild(_imgGears);
			} else { // Not visible
				if (numChildren > 0) removeAllChildren();
			}
		}
	}
}