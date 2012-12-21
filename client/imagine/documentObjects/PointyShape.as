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
	public class PointyShape extends PShape
	{
		private var _nPoints:Number = 5;
		private var _nInnerRadiusPct:Number = 1;
		private var _nOffsetAngle:Number = 0;
		
		public override function get typeName(): String {
			return "Pointy Shape";
		}
		
		public function PointyShape(nPoints:Number = 5, nInnerRadiusPct:Number = 1, nOffsetAngle:Number = 0) {
			points = nPoints;
			innerRadiusPct = nInnerRadiusPct;
			offsetAngle = nOffsetAngle;
		}
		
		public function get innerRadiusPct(): Number {
			return _nInnerRadiusPct;
		}
		public function set innerRadiusPct(nPct:Number): void {
			if (nPct > 1) nPct = 1;
			else if (nPct < 0.01) nPct = 0.01;
			_nInnerRadiusPct = nPct;
			Invalidate();
		}

		public function set offsetAngle(nOffsetAngle:Number): void {
			if (nOffsetAngle > 360) nOffsetAngle = 360;
			else if (nOffsetAngle < -360) nOffsetAngle = -360;
			_nOffsetAngle = nOffsetAngle;
			Invalidate();
		}
		public function get offsetAngle(): Number {
			return _nOffsetAngle;
		}

		public function get points(): Number {
			return _nPoints;
		}

		public function set points(nPoints:Number): void {
			nPoints = Math.round(nPoints);
			if (nPoints < 2) nPoints = 3;
			else if (nPoints > 100) nPoints = 100;
			_nPoints = nPoints;
			Invalidate();
		}
		
		override public function get serializableProperties(): Array {
			return super.serializableProperties.concat(["innerRadiusPct", "points", "offsetAngle"]);
		}
		
		// Override this
		protected function drawPointyShape(gr:Graphics, xCenter:Number, yCenter:Number, cxyInnerRadius:Number, cxyOuterRadius:Number): void {
			throw new Error("Override drawPointyShape in sub classes: " + this);
		}
		
		protected override function drawShape(gr:Graphics, clr:uint): void {
			gr.clear();
			gr.beginFill(clr);
			var cxySize:Number = (unscaledWidth + unscaledHeight) / 4;
			var xCenter:Number = unscaledWidth / 2;
			var yCenter:Number = unscaledHeight / 2;
			var nOuterRadiusPct:Number = 1;
			
			drawPointyShape(gr, xCenter, yCenter, cxySize * innerRadiusPct, cxySize * nOuterRadiusPct);
			
			gr.endFill();
		}
	}
}