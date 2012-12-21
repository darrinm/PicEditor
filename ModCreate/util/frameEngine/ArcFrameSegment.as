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
	
	public class ArcFrameSegment extends FrameSegment implements IFrameSegment
	{
		private var _ptCenter:Point;
		private var _nRadius:Number;
		private var _nStartDeg:Number;
		private var _nArcDegSize:Number;
		
		public function ArcFrameSegment(ptCenter:Point, nRadius:Number, nStartDeg:Number, nArcDegSize:Number)
		{
			super();
			_ptCenter = ptCenter;
			_nRadius = nRadius;
			_nStartDeg = nStartDeg;
			_nArcDegSize = nArcDegSize;
			
			_nLength = 2 * Math.PI * _nRadius * Math.abs(nArcDegSize) / 360;
		}
		
		public function get isCurved():Boolean
		{
			return true;
		}
		
		override public function GetLoc(nDistance:Number):FrameSegmentLoc
		{
			var nPct:Number = Math.min(1,Math.max(0, nDistance / length));
			var rad:Number = (_nStartDeg + _nArcDegSize * nPct) * Math.PI / 180;
			
			var ptLoc:Point = new Point(_ptCenter.x + _nRadius * Math.cos(rad), _ptCenter.y + _nRadius * Math.sin(rad));
			var ptVect:Point = _ptCenter.subtract(ptLoc);
			ptVect.normalize(1);
			return new FrameSegmentLoc(ptLoc, ptVect);
		}
	}
}