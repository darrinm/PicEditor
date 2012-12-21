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
package util.frameEngine
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import util.svg.PathSegmentsCollection;
	
	public class SVGPathFillFrameSegment extends FrameSegmentCollection
	{
		public function SVGPathFillFrameSegment(svgPath:String, rcOuter:Rectangle, rcShape:Rectangle, fMaintainAspectRatio:Boolean, fOuterFill:Boolean, nLineSpacing:Number)
		{
			super();
			UpdateFrameSegments(svgPath, rcOuter, rcShape, fMaintainAspectRatio, fOuterFill, nLineSpacing);
			CalculateLength();
		}
		private function PointInFill(ix:Number, iy:Number, bmd:BitmapData, fOuterFill:Boolean): Number {
			// If the point is white, it is outside the shape
			
			var nOutside:Number = (bmd.getPixel(ix, iy) & 0xff) / 255;
			
			if (fOuterFill)
				return nOutside;
			else
				return 1 - nOutside;
		}
		
		private function UpdateFrameSegments(svgPath:String, rcOuter:Rectangle, rcShape:Rectangle, fMaintainAspectRatio:Boolean, fOuterFill:Boolean, nLineSpacing:Number): void {
			_afsgs = [];
			var nScale:Number = 1/nLineSpacing;
			var bmd:BitmapData = new BitmapData(Math.ceil(nScale * rcOuter.width)+1, Math.ceil(nScale * rcOuter.height)+1, false, 0xffffff);
			var psgs:PathSegmentsCollection = new PathSegmentsCollection(svgPath);
			var spr:Sprite = new Sprite();
			spr.graphics.beginFill(0, 1);
			psgs.generateGraphicsPathInBox(spr.graphics, rcShape, 1);
			spr.graphics.endFill();
			
			var mat:Matrix = new Matrix();
			mat.translate(-rcOuter.x, -rcOuter.y);
			mat.scale(nScale, nScale);
			bmd.draw(spr, mat, null, null, null, true);
			
			// UNDONE: Do some scaling now?
			var ix:Number = 0;
			var iy:Number = 0;
			var xEnd:Number;
			var ptStart:Point;
			var ptEnd:Point;
			for (iy = 0; iy < bmd.height; iy++) {
				// Calculate horizontal lines
				var xStart:Number = NaN;
				if (PointInFill(0, iy, bmd, fOuterFill) > 0.5)
					xStart = -0.5;	
				for (ix = 1; ix < bmd.width; ix++) {
					var nFill:Number = PointInFill(ix, iy, bmd, fOuterFill);
					if (nFill > 0.5 && isNaN(xStart)) {
						// Start filling a new line
						xStart = ix + 1 - nFill;
					} else if (nFill < 0.5 && !isNaN(xStart)) {
						// End a fill
						xEnd = ix;
						ptStart = new Point(rcOuter.x + xStart * nLineSpacing, rcOuter.y + iy * nLineSpacing);
						ptEnd = new Point(rcOuter.x + xEnd * nLineSpacing, rcOuter.y + iy * nLineSpacing);
						_afsgs.push(new StraightFrameSegment(ptStart, ptEnd));
						xStart = NaN;
					}
				}
				// Terminate any lines in progress
				if (!isNaN(xStart)) {
					xEnd = bmd.width;
					ptStart = new Point(rcOuter.x + xStart * nLineSpacing, rcOuter.y + iy * nLineSpacing);
					ptEnd = new Point(rcOuter.x + xEnd * nLineSpacing, rcOuter.y + iy * nLineSpacing);
					_afsgs.push(new StraightFrameSegment(ptStart, ptEnd));
					xStart = NaN;
				}
			}
			bmd.dispose();
		}
	}
}