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
	public class Polygon extends PointyShape
	{
		private const knFivePointInnerRadius:Number = 0.381966011; // roughly level lines
		
		public override function get typeName(): String {
			return "Polygon";
		}
		
		public function Polygon(nPoints:Number = 5, nOffsetAngle:Number=0) {
			super(nPoints, 1, nOffsetAngle);
		}
		
		override public function set points(nPoints:Number): void {
			if (nPoints < 3) nPoints = 3;
			super.points = nPoints;
		}


		override protected function drawPointyShape(gr:Graphics, xCenter:Number, yCenter:Number, cxyInnerRadius:Number, cxyOuterRadius:Number): void {
			DrawUtils.polygon(gr, xCenter, yCenter, points, cxyOuterRadius, 90 + offsetAngle);
		}
	}
}