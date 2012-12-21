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
	
	public class StraightFrameSegment extends FrameSegment implements IFrameSegment
	{
		private var _ptStart:Point;
		private var _ptEnd:Point;
		private var _ptCenterVector:Point;
		
		// Points should be going clockwise in a y increases down coordinate system.
		public function StraightFrameSegment(ptStart:Point, ptEnd:Point)
		{
			super();
			SetEndpoints(ptStart, ptEnd);
		}
		
		private function SetEndpoints(ptStart:Point, ptEnd:Point): void {
			_ptStart = ptStart;
			_ptEnd = ptEnd;
			_ptCenterVector = new Point(ptStart.y - ptEnd.y, ptEnd.x - ptStart.x);
			_ptCenterVector.normalize(1);
			_nLength = (_ptEnd.subtract(_ptStart)).length;
		}
		
		public function get isCurved():Boolean
		{
			return false;
		}
		
		// Add (or subtract if negative) this many pixels to each end
		public function Extend(nPix:Number): void {
			var ptExtend:Point = _ptStart.subtract(_ptEnd);
			ptExtend.normalize(nPix);
			SetEndpoints(_ptStart.add(ptExtend), _ptEnd.subtract(ptExtend));
		}
		
		override public function GetLoc(nDistance:Number):FrameSegmentLoc
		{
			var ptLoc:Point;
			
			if (nDistance <= 0)	
				ptLoc = _ptStart;
			else if (nDistance >= length)
				ptLoc = _ptEnd;
			else {
				var nPctDist:Number = nDistance / length;
				ptLoc = new Point(_ptStart.x + (_ptEnd.x - _ptStart.x) * nPctDist,
						_ptStart.y + (_ptEnd.y - _ptStart.y) * nPctDist);
			}
			return new FrameSegmentLoc(ptLoc, _ptCenterVector);
		}
	}
}