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
package imagine.imageOperations.bokeh.customShapes {
	import flash.display.Graphics;
	import flash.display.Shape;

	public class Heart	{
		private static const WIDTH_TO_HEIGHT_RATIO:Number = 0.85;
		
		public static function draw(target:Shape, radius:Number):void {
			var t:Graphics=target.graphics;
			var ry:Number=radius;
			var ry2:Number=ry/2;
			
			var rx:Number=ry*WIDTH_TO_HEIGHT_RATIO;
			var rx2:Number=rx/2;

			t.moveTo(rx, 0);
			t.lineTo(0, ry);
			t.lineTo(-rx, 0);
			t.curveTo(-rx-rx2, -ry2, -rx, -ry);
			t.curveTo(-rx2, -ry-ry2, 0, -ry*WIDTH_TO_HEIGHT_RATIO);
			t.curveTo(rx2, -ry-ry2, rx, -ry);
			t.curveTo(rx+rx2, -ry2, rx, 0);
		}
	}
}