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
package documentObjects
{
	import flash.display.Graphics;
	import flash.geom.Point;
	import mx.binding.utils.ChangeWatcher;
	import flash.events.Event;
	import mx.events.PropertyChangeEvent;
	import flash.geom.Rectangle;
	import flash.display.Sprite;
	
	public class RoundedSquare extends PShape
	{
		private var _nRoundedPct:Number = 0.4;
		
		public override function get typeName(): String {
			return "Rounded Square";
		}
		
		public function RoundedSquare(nRoundedPct:Number = 0.4) {
			roundedPct = nRoundedPct;
		}
		
		public function get roundedPct(): Number {
			return _nRoundedPct;
		}
		public function set roundedPct(nPct:Number): void {
			if (nPct > 1) nPct = 1;
			else if (nPct < 0) nPct = 0;
			_nRoundedPct = nPct;
			Invalidate();
		}

		override public function get serializableProperties(): Array {
			return super.serializableProperties.concat(["roundedPct"]);
		}
		
		// Roundedness of the object
		protected function getEllipseSize(): Point {
			// We want this to be a circle even when the shape is distorted, so take scale into account
			var nScaledDiameter:Number = Math.min(roundedPct * unscaledWidth * scaleX, roundedPct * unscaledHeight * scaleY);
			
			// Remove the scale factor and return the width/height of our ellipse
			return new Point(nScaledDiameter / scaleX, nScaledDiameter / scaleY);
		}
		
		protected override function drawShape(gr:Graphics, clr:uint): void {
			gr.clear();
			gr.beginFill(clr);
			var cxySize:Number = (unscaledWidth + unscaledHeight) / 4;
			var xCenter:Number = unscaledWidth / 2;
			var yCenter:Number = unscaledHeight / 2;
			var nOuterRadiusPct:Number = 1;
			
			var ptEllipseSize:Point = getEllipseSize();
			
			gr.drawRoundRect(0, 0, unscaledWidth, unscaledHeight, ptEllipseSize.x, ptEllipseSize.y);
			
			gr.endFill();
		}
	}
}