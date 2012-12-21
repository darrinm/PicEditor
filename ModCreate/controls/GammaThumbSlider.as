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
	
	public class GammaThumbSlider extends TrippleThumbSlider
	{
		private var _nMiddleThumbPos:Number = 0.5;

		[Bindable (event="change")]
		public function set midVal(n:Number): void {
			_nMiddleThumbPos = n;
			middleThumb.x = leftThumb.x + _nMiddleThumbPos * (rightThumb.x - leftThumb.x);
			invalidateThumbPosition();
		}
		
		public override function Reset(): void {
			super.Reset();
			midVal = 0.5;
		}

		public function get midVal(): Number {
			return _nMiddleThumbPos;
		}
		
		protected override function OnThumbMove(evt:Event = null): void {
			super.OnThumbMove(evt);
			if (evt.target != middleThumb) {
				// When we move an outer thumb, adjust the position of the inner
				// thumb while holding the middle positoin constant
				middleThumb.x = leftThumb.x + _nMiddleThumbPos * (rightThumb.x - leftThumb.x);
			} else {
				// When we move the inner thumb, update our thumb position
				_nMiddleThumbPos = (middleThumb.x - leftThumb.x) / (rightThumb.x - leftThumb.x);
			}
		}
	}
}