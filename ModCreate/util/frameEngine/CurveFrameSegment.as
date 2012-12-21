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
	
	public class CurveFrameSegment extends FrameSegment implements IFrameSegment
	{
		private var _ptStart:Point;
		private var _ptControl:Point;
		private var _ptEnd:Point;
		private var _fCounterClockwise:Boolean = false;
		private var _anLengths:Array;

		public function CurveFrameSegment(ptStart:Point, ptControl:Point, ptEnd:Point, fCounterClockwise:Boolean=false)
		{
			super();
			_ptStart = ptStart;
			_ptControl = ptControl;
			_ptEnd = ptEnd;
			_fCounterClockwise = fCounterClockwise;
			CalculateLength();
		}
		
		private static const knNumSegments:Number = 20;

		// closed-form solution to elliptic integral for arc length
		// see http://algorithmist.wordpress.com/2009/01/05/quadratic-bezier-arc-length/
		private function CalculateLength():void
		{
			// knNumSegments - 1 lengths
			_anLengths = [];
			_nLength = 0;
			var ptPrev:Point = null;
			for (var i:Number = 0; i < knNumSegments; i++) {
				var nPct:Number = i / (knNumSegments-1);// 0 to 1
				var sgloc:FrameSegmentLoc = GetLocFromLinearDistance(nPct);
				var ptThis:Point = sgloc.loc;
				if (ptPrev) {
					var nLength:Number = Point.distance(ptThis, ptPrev);
					_nLength += nLength;
					_anLengths.push(nLength);
				}
				ptPrev = ptThis;
			}
		}
		
		private function GetLinearPercentComplete(nDistance:Number): Number {
			// nDistance is between 0 and nLength
			// Convert it into a linear percent using our _anLengths array as a guide
			var i:Number = 0;
			while (nDistance > _anLengths[i]) {
				nDistance -= _anLengths[i];
				i++;
			}
			// Now we have our i and our distance as our remainder
			i += nDistance / _anLengths[i];
			
			// Now i is our "index" where i is between 0 and knNumSegments
			return i / _anLengths.length;
		}

		public function get isCurved():Boolean
		{
			return true;
		}
		
		private function PointBetween(ptA:Point, ptB:Point, nPct:Number): Point {
			return new Point(ptA.x + nPct * (ptB.x - ptA.x), ptA.y + nPct * (ptB.y - ptA.y));
		}
		
		// nPct is percent from ptA to ptB, ptB to ptC, and ptAB to ptBC
		private function GetLocFromLinearDistance(nPct:Number):FrameSegmentLoc {
			// Assume nDistance is between 0 and _nLength
			
			// nPct is percent of the distance complete.
			// We have new points:
			// ptAB, ptBC, lineAB_BC, and ptL_AB_BC (nPct along the line from ptAB to ptBC)
			// Note that our tangent is perpendicular to this line
			
			var ptA:Point = _ptStart;
			var ptB:Point = _ptControl;
			var ptC:Point = _ptEnd;
			
			var ptAB:Point = PointBetween(ptA, ptB, nPct);
			var ptBC:Point = PointBetween(ptB, ptC, nPct);
			
			var ptAB_BC:Point =  PointBetween(ptAB, ptBC, nPct);
			
			var ptLoc:Point = ptAB_BC;

			var ptVect:Point = new Point(ptAB.y - ptBC.y, ptBC.x - ptAB.x);
			if (!_fCounterClockwise) { // Point the other way
				ptVect.y = -ptVect.y;
				ptVect.x = -ptVect.x;
			}
			ptVect.normalize(1);
			return new FrameSegmentLoc(ptLoc, ptVect);
		}
		
		override public function GetLoc(nDistance:Number):FrameSegmentLoc
		{
			nDistance = Math.min(_nLength,Math.max(0, nDistance)); // Chomp
			var nPct:Number = GetLinearPercentComplete(nDistance);
			return GetLocFromLinearDistance(nPct);
		}
	}
}