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
package imagine.documentObjects
{
	import flash.display.Graphics;
	import com.primitives.DrawUtils;
	
	[RemoteClass]
	public class Star extends PointyShape
	{
		private const knFivePointInnerRadius:Number = 0.381966011; // roughly level lines
		
		public override function get typeName(): String {
			return "Star";
		}
		
		public function Star(nPoints:Number = 5, nInnerRadiusPct:Number = knFivePointInnerRadius, nOffsetAngle:Number=0) {
			super(nPoints, nInnerRadiusPct, nOffsetAngle);
		}

		override protected function drawPointyShape(gr:Graphics, xCenter:Number, yCenter:Number, cxyInnerRadius:Number, cxyOuterRadius:Number): void {
			DrawUtils.star(gr, xCenter, yCenter, points, cxyInnerRadius, cxyOuterRadius, 90 + offsetAngle);
		}
	}
}