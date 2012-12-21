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
package overlays.helpers
{
	import flash.geom.Point;
	import flash.display.Graphics;
	
	/**
	* @brief The LevelLine class is manages the straighten/level line for the Rotate class.
	*
	* This class is responsible for keeping track of the start and end points
	* as well as calculating the final "straight" angle.
	*
	* @see RotateOverlayBase
	*/
	public class LevelLine
	{
		// Constants
		private const kcoLevelLine:uint =  0xffffff; // CONFIG
		private const knLevelLineThickness:Number = 1; // CONFIG
		private const knLevelLineAlpha:Number = 0.80; // CONFIG

		private const kcoLevelLineBack:uint =  0x000000; // CONFIG
		private const knLevelLineBackAlpha:Number = 0.20; // CONFIG
		private const knLevelLineBackThickness:Number = 2; // CONFIG


		private var _ptStart:Point;
		private var _ptEnd:Point;
		
		// Constructor takes in the x and y coordinates of the start point
		public function LevelLine(x:Number, y:Number) {
			_ptStart = new Point(x,y);
			_ptEnd = new Point(x,y);
		}
		
		// Set a new start point
		public function SetStart(x:Number, y:Number): void {
			_ptStart.x = x;
			_ptStart.y = y;
		}

		// Set the end point
		public function SetEnd(x:Number, y:Number): void {
			_ptEnd.x = x;
			_ptEnd.y = y;
		}
		
		// The distance between the start and end points
		// Useful for setting a minimum drag threshold
		public function get Length(): Number {
			return Point.distance(_ptStart, _ptEnd);
		}
		
		// Draw the level line in a Graphics.
		public function Draw(gr:Graphics): void {
			with (gr)
			{
				clear();

				// Draw background line
				lineStyle(knLevelLineBackThickness, kcoLevelLineBack, knLevelLineBackAlpha);
				moveTo(_ptStart.x, _ptStart.y);
				lineTo(_ptEnd.x, _ptEnd.y);

				// Draw foreground line				
				lineStyle(knLevelLineThickness, kcoLevelLine, knLevelLineAlpha);
				moveTo(_ptStart.x, _ptStart.y);
				lineTo(_ptEnd.x, _ptEnd.y);
			}
		}

		// Given the current ofset radians, return the new offset radians.		
		public function GetStraightRad(radCurrentRotation:Number): Number {
			var ptDragLine:Point = _ptStart.subtract(_ptEnd);
			var radDragAngle:Number = Math.atan2(ptDragLine.y, ptDragLine.x);
			radDragAngle -= radCurrentRotation;
			radDragAngle = Util.NormalizeRad(radDragAngle);
			return Util.RadsFromNearest90(radDragAngle);
		}
	}
}