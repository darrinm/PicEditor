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
package imagine.documentObjects {
	import flash.geom.Point;
	
	/**
	 * This class is essentially the same as RoundedRectangle except that it works
	 * extra hard to not let its proportions be distorted by the scale factor applied
	 * to its parent. This is used to give Targets in PhotoGrids nice rounded corners.
	 */
	[RemoteClass]
	public class RoundedRectangleMask extends RoundedRectangle {
		public override function get typeName(): String {
			return "Rounded Rectangle Mask";
		}
		
		// Roundedness of the object
		override protected function getEllipseSize(): Point {
			// We want this to be a circle even when the shape is distorted, so take scale into account
			var scaleX:Number = this.scaleX;
			var scaleY:Number = this.scaleY;
			
			// It is assumed that this mask is a child of the object it masks and
			// therefore transformed by its parent. Invert the scaling applied by
			// the parent to keep the mask's corners round.
			if (parent) {
				scaleX *= parent.scaleX;
				scaleY *= parent.scaleY;
			}
			
			var nScaledDiameter:Number = Math.min(roundedPct * unscaledWidth * scaleX, roundedPct * unscaledHeight * scaleY);
			
			// Remove the scale factor and return the width/height of our ellipse
			return new Point(nScaledDiameter / scaleX, nScaledDiameter / scaleY);
		}
	}
}
