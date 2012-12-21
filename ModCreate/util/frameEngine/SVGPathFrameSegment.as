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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import util.svg.CubicBezierSegment;
	import util.svg.LineSegment;
	import util.svg.MoveSegment;
	import util.svg.PathSegment;
	import util.svg.PathSegmentsCollection;
	import util.svg.QuadraticBezierSegment;
	import util.svg.QuadraticPoints;

	public class SVGPathFrameSegment extends FrameSegmentCollection
	{
		public function SVGPathFrameSegment(svgPath:String, rcArea:Rectangle, fMaintainAspectRatio:Boolean = true, fCounterClockwise:Boolean=false)
		{
			super();
			UpdateFrameSegments(svgPath, rcArea, fMaintainAspectRatio, fCounterClockwise);
			CalculateLength();
		}
		
		override public function get isCurved():Boolean
		{
			return true;
		}
		
		private function CalculateTransform(psgs:PathSegmentsCollection, rcTargetArea:Rectangle, fMaintainAspectRatio:Boolean): Object {
			var rcNative:Rectangle = psgs.getBounds();
			
			var sx:Number = rcTargetArea.width / rcNative.width;
			var sy:Number = rcTargetArea.height / rcNative.height;
			
			if (fMaintainAspectRatio) {
				sx = Math.min(sx, sy);
				sy = sx;
			}
			
			// Now we have our scale factor
			var rcScaled:Rectangle = rcNative.clone();
			rcScaled.x *= sx;
			rcScaled.width *= sx;
			rcScaled.y *= sy;
			rcScaled.height *= sy;
			
			var dx:Number = (rcTargetArea.x - rcScaled.x) + (rcTargetArea.width - rcScaled.width) / 2;
			var dy:Number = (rcTargetArea.y - rcScaled.y) + (rcTargetArea.height - rcScaled.height) / 2;
			
			return {sx:sx, sy:sy, dx:dx, dy:dy};
		}
		
		private function UpdateFrameSegments(svgPath:String, rcArea:Rectangle, fMaintainAspectRatio:Boolean, fCounterClockwise:Boolean): void {
			var psgs:PathSegmentsCollection = new PathSegmentsCollection(svgPath);
			
			var obTransform:Object = CalculateTransform(psgs, rcArea, fMaintainAspectRatio);
			var dx:Number = obTransform.dx;
			var dy:Number = obTransform.dy;
			var sx:Number = obTransform.sx;
			var sy:Number = obTransform.sy;
			
			_afsgs = [];
			var psgPrev:PathSegment = new PathSegment();
			var ptStart:Point;
			var ptEnd:Point;
			var ptControl:Point;
			for each (var psg:PathSegment in psgs.data) {
				if (psg is MoveSegment) {
					// pass
				} else if (psg is CubicBezierSegment) {
			        var qPts:QuadraticPoints = CubicBezierSegment(psg).getQuadraticPoints(psgPrev);
			        ptStart = new Point(dx + psgPrev.x*sx, dy + psgPrev.y*sy);
			       
			        ptControl = new Point(dx + qPts.control1.x*sx, dy+qPts.control1.y*sy);
			        ptEnd = new Point(dx+qPts.anchor1.x*sx, dy+qPts.anchor1.y*sy);
			        _afsgs.push(new CurveFrameSegment(ptStart, ptControl, ptEnd, fCounterClockwise));
			       
			        ptStart = ptEnd;
			        ptControl = new Point(dx + qPts.control2.x*sx, dy+qPts.control2.y*sy);
			        ptEnd = new Point(dx+qPts.anchor2.x*sx, dy+qPts.anchor2.y*sy);
			        _afsgs.push(new CurveFrameSegment(ptStart, ptControl, ptEnd, fCounterClockwise));

			        ptStart = ptEnd;
			        ptControl = new Point(dx + qPts.control3.x*sx, dy+qPts.control3.y*sy);
			        ptEnd = new Point(dx+qPts.anchor3.x*sx, dy+qPts.anchor3.y*sy);
			        _afsgs.push(new CurveFrameSegment(ptStart, ptControl, ptEnd, fCounterClockwise));

			        ptStart = ptEnd;
			        ptControl = new Point(dx + qPts.control4.x*sx, dy+qPts.control4.y*sy);
			        ptEnd = new Point(dx+qPts.anchor4.x*sx, dy+qPts.anchor4.y*sy);
			        _afsgs.push(new CurveFrameSegment(ptStart, ptControl, ptEnd, fCounterClockwise));
				} else if (psg is LineSegment) {
					ptStart = new Point(dx + psgPrev.x*sx, dy + psgPrev.y*sy);
					ptEnd = new Point(dx + psg.x*sx, dy + psg.y*sy);
					
					if (fCounterClockwise) {
						ptControl = ptStart;
						ptStart = ptEnd;
						ptEnd = ptControl;
					}
					_afsgs.push(new StraightFrameSegment(ptStart, ptEnd));
				} else if (psg is QuadraticBezierSegment) {
					var qpsg:QuadraticBezierSegment = psg as QuadraticBezierSegment;
					ptStart = new Point(dx + psgPrev.x*sx, dy + psgPrev.y*sy);
					ptControl = new Point(dx + qpsg.control1X*sx, dy + qpsg.control1Y*sy);
					ptEnd = new Point(dx + psg.x*sx, dy + psg.y*sy);
			        _afsgs.push(new CurveFrameSegment(ptStart, ptControl, ptEnd, fCounterClockwise));
				}
				psgPrev = psg;
			}
		}
	}
}