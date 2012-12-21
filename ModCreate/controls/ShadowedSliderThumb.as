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
	import flash.filters.DropShadowFilter;
	
	import mx.controls.sliderClasses.Slider;
	import mx.core.mx_internal;

	use namespace mx_internal;

	public class ShadowedSliderThumb extends SliderThumbPlus
	{
		private var _xInternal:Number = NaN;
		
		public function ShadowedSliderThumb()
		{
			super();
			filters = [new DropShadowFilter(0, 90, 0, 0.35, 3, 3, 1, 3)];
		}

		public override function get xPosition():Number
		{
			if (!isNaN(_xInternal)) return _xInternal;
			return $x + width / 2;
		}
		
		/**
		 *  @private
		 */
		public override function set xPosition(value:Number):void
		{
			$x = Math.round(value - width / 2);
			_xInternal = value;
			
			Slider(owner).drawTrackHighlight();
		}
	}
}