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
	import controls.list.ITileListItem;
	
	import mx.containers.Box;
	import mx.controls.Image;
	
	public class TextureTileListItemBase extends Box implements ITileListItem
	{
		[Bindable] public var _imgThumbnail:Image;

		private var _fHighlighted:Boolean = false;
		private var _fSelected:Boolean = false;

		public function TextureTileListItemBase()
		{
			super();
		}

		public function isLoaded(): Boolean {
			if (!_imgThumbnail) return false;
			var nWidth:Number = _imgThumbnail.contentWidth;
			return (!isNaN(nWidth)) && nWidth > 0;
		}

		public function get highlighted(): Boolean {
			return _fHighlighted;
		}
		
		public function get selected(): Boolean {
			return _fSelected;
		}
		
		public function set highlighted(f:Boolean): void {
			_fHighlighted = f;
			UpdateState();
		}
		
		public function set selected(f:Boolean): void {
			_fSelected = f;
			UpdateState();
		}
		
		public function setState(fHighlighted:Boolean, fSelected:Boolean, fEnabled:Boolean): void {
			_fHighlighted = fHighlighted;
			_fSelected = fSelected;
			super.enabled = fEnabled;
			UpdateState();
		}
		
		// Possible states: "NotSelected, Selected, Highlight
		private function UpdateState(): void {
			var strState:String = "NotSelected";
			if (_fSelected) strState = "Selected";
			else if (_fHighlighted) strState = "Highlight";
			
			// Disable the item if there is enabled limit and the item exceeds it.
			// if (!enabled)
			//	strState = "Disabled" + strState;
			
			if (currentState != strState) currentState = strState;
		}
	}
}