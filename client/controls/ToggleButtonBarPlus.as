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
	/** ToggleButtonBarPlus
	 * This class fixes a bug in ButtonBar which draws focus rects for buttons on a
	 * button bar when the focus is not enabled. This causes strange seemingly
	 * random focus rects to appear on the screen
	 */
	import mx.controls.ToggleButtonBar;
	import mx.core.mx_internal;

	use namespace mx_internal;
	
	public class ToggleButtonBarPlus extends ToggleButtonBar
	{
		public function ToggleButtonBarPlus()
		{
			super();
		}

		override mx_internal function drawButtonFocus(index:int, focused:Boolean):void
		{
			super.drawButtonFocus(index, focused && focusEnabled);
		}
	}
}