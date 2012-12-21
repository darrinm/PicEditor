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
package skins
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.GradientType;
	import flash.events.IEventDispatcher;
	import flash.geom.Matrix;
	
	import mx.controls.sliderClasses.Slider;
	import mx.events.PropertyChangeEvent;
	
	import overlays.helpers.RGBColor;

	public class RoundedValueSliderTrack extends ValueSliderTrack
	{
		override public function RoundedValueSliderTrack()
		{
			super();
		}
		
		override protected function get cornerRadius(): int {
			return 5;
		}
	}
}