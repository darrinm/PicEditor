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
	import mx.containers.Canvas;

	// Use this canvas to remove child components when they are hidden.
	// This is useful for stopping animating swfs, like the gears progress indicators
	public class InactiveRemoveCanvas extends Canvas
	{
		private var _fActive:Boolean = false;
		private var _aobChildren:Array = new Array();
		
		[Bindable]
		public function set active( f:Boolean ): void {
			_fActive = f;
			UpdateContent();
		}
		
		public function get active():Boolean {
			return _fActive;
		}
		
		protected function PopChildren(): void {
			for (var i:Number = 0; i < numChildren; i++) {
				_aobChildren.push(getChildAt(i));
			}
			removeAllChildren();
		}
		
		protected function PushChildren(): void {
			for (var i:Number = 0; i < _aobChildren.length; i++) {
				addChild(_aobChildren[i]);
			}
			_aobChildren.length = 0;
		}
		
		// Add or remove the child gears based on the visible state
		protected function UpdateContent(): void {
			if (active) {
				if (numChildren == 0) PushChildren();
			} else { // Not visible
				if (numChildren > 0) PopChildren();
			}
		}
	}
}