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
package icons
{
	import flash.geom.Matrix;
	
	import overlays.helpers.RGBColor;

	public class HueGradientIcon extends SolidColorIcon
	{
		private static const knStartHue:Number = 180;
		private static const knHueGradientPoints:Number = 20;
		
		override public function HueGradientIcon()
		{
			super();
		}
		
		override protected function GetGradientColors(): Array {
			var nSat:Number = 100;
			var nVal:Number = 100;
			var nHue:Number;
			
			var aclr:Array = [];
			
			for (var i:Number = 0; i < knHueGradientPoints; i++) {
				nHue = knStartHue + 360 * i / (knHueGradientPoints-1);
				aclr.push(RGBColor.HSVtoUint(nHue, nSat, nVal));
			}
			return aclr;
		}
		
		override protected function GetGradientDirection(): Number {
			return 0; // Left to right
		}
	}
}