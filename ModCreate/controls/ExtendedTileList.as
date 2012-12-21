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
	import controls.list.PicnikTileList;
	
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import mx.events.ListEvent;
	
	// This a bridge specific tile list which uses the BridgeItem tile renderer and knows
	// how to generate bridge events. To use this, do the following:
	// 1. Include it in your bridge MXML
	// 2. Set the item renderer to "bridges.BridgeItem"
	// 3. Specify the dataProvider (use an array of ImageThumbs). use SmartUpdateDataProvider to set the data provider nicely.
	// 4. Listen for and react to BridgeItemEvents
	public class ExtendedTileList extends PicnikTileList {
		// [Bindable] public var singleClickEdit:Boolean = false;
		
		private var _nSmallestMouseWheel:Number = NaN;
		
		// TileLists already scroll in rediculous big chunks then mousewheel
		// events introduce a multiplier. Back it off to something reasonable		
		override protected function mouseWheelHandler(event:MouseEvent):void {
			var nAbsDelta:Number = Math.abs(event.delta);
			if (isNaN(_nSmallestMouseWheel)) {
				_nSmallestMouseWheel = nAbsDelta;
			} else if (nAbsDelta < _nSmallestMouseWheel) {
				_nSmallestMouseWheel = nAbsDelta;
			}
			if (Math.abs(event.delta) <= nAbsDelta && event.delta != 0) {
				event.delta = event.delta / nAbsDelta;
			} else {
				event.delta = int(event.delta / nAbsDelta);
			}
			super.mouseWheelHandler(event);
		}
	}
}
