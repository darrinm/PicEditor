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
package util {
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class RectUtil {
		public static const CENTER:Number = -1;
		public static const ABOVE:Number = 0;
		public static const BELOW:Number = 1;
		public static const LEFT:Number = 2;
		public static const RIGHT:Number = 3;
		
		// Given an array of constraint objects, and the size of a new rectangle,
		// returns x,y coordinates of a target position which best matches the constraints.
		public static function PlaceRect(aobConstraints:Array, ptSize:Point): Point {
			if (aobConstraints == null || aobConstraints.length == 0) return new Point(0,0);
			
			var rcStart:Rectangle;
			var i:Number = 0;
			if ('rcInside' in aobConstraints[0]) {
				rcStart = aobConstraints[0].rcInside;
				i++;
			} else {
				rcStart = new Rectangle(0, 0, Number.MAX_VALUE, Number.MAX_VALUE);
			}
			
			// Truncate to fit - this forces overflow down and right, which is fine.
			ptSize.x = Math.min(ptSize.x, rcStart.width);
			ptSize.y = Math.min(ptSize.y, rcStart.height);
			
			var ob:Object = ApplyRules(rcStart, aobConstraints, ptSize, i);
			if (ob == null) {
				return new Point(0,0);
			} else {
				return ob.pt;
			}
		}

		public static function ApplyPadding(rc:Rectangle, obPadding:Object, fOutside:Boolean=true): Rectangle {
			var rcPadded:Rectangle = rc.clone();
			if (obPadding != null) {
				if (RectUtil.ABOVE in obPadding) {
					rcPadded.y -= obPadding[RectUtil.ABOVE];
					rcPadded.height += obPadding[RectUtil.ABOVE];
				}
				if (RectUtil.BELOW in obPadding) {
					rcPadded.height += obPadding[RectUtil.BELOW];
				}
				if (RectUtil.LEFT in obPadding) {
					rcPadded.x -= obPadding[RectUtil.LEFT];
					rcPadded.width += obPadding[RectUtil.LEFT];
				}
				if (RectUtil.RIGHT in obPadding) {
					rcPadded.width += obPadding[RectUtil.RIGHT];
				}
			}
			return rcPadded;
		}
		
		protected static function ApplyRules(rcIn:Rectangle, aobConstraints:Array, ptSize:Point, i:Number): Object {
			var obRet:Object = null;
			var obConst:Object = aobConstraints[i];
			var rc:Rectangle;
			
			// UNDONE: This code could repeats itself and could use some refactoring
			if ('rcInside' in obConst) {
				rc = obConst['rcInside'];
				rc = rcIn.intersection(rc); // Space we have left
				if ((rc.width+0.5) < ptSize.x || (rc.height+0.5) < ptSize.y) return null; // doesn't fit
				// It fits. Recurse down, if there are more constraints. Otherwise, center the rect
				if (aobConstraints.length > (i+1)) {
					obRet = ApplyRules(rc, aobConstraints, ptSize, i+1);
				}
				if (!obRet) {
					obRet = {};
					obRet.pt = new Point(rc.x + (rc.width - ptSize.x)/2, rc.y + (rc.height - ptSize.y)/2); 
					obRet.depth = i;
				}
				return obRet;
			} else if ('rcOutside' in obConst || 'rcPointAt' in obConst) {
				var rcOutside:Rectangle = obConst.rcOutside ? obConst.rcOutside : obConst.rcPointAt;
				var aobRet:Array = [];
				var nDir:Number;
				var rc2:Rectangle;
				
				var fnCommon:Function = function (): void {
 					obRet = null;
					if (aobConstraints.length > (i+1)) {
						obRet = ApplyRules(rc2, aobConstraints, ptSize, i+1);
					}
					if (obRet == null) {
						obRet = {};
						if (obConst.rcPointAt) {
							// Calc a rect of ptSize centered over obConst.rcPointAt
							var rcPointAt:Rectangle = obConst.rcPointAt as Rectangle;
							var rcT:Rectangle = new Rectangle(rcPointAt.left - (ptSize.x - rcPointAt.width) / 2,
									rcPointAt.top - (ptSize.y - rcPointAt.height) / 2, ptSize.x, ptSize.y);
							switch (nDir) {
							case ABOVE:
								rcT.x = Math.min(Math.max(rcT.x, rc2.x), rc2.right - rcT.width);
								rcT.y = rc2.bottom - rcT.height; //Math.min(rc2.bottom, rcT.bottom) - rcT.height;
								break;
								
							case BELOW:
								rcT.x = Math.min(Math.max(rcT.x, rc2.x), rc2.right - rcT.width);
								rcT.y = rc2.top;
								break;
								
							case LEFT:
								rcT.x = rc2.right - rcT.width;
								rcT.y = Math.min(Math.max(rcT.y, rc2.y), rc2.bottom - rcT.height);
								break;
								
							case RIGHT:
								rcT.x = rc2.left;
								rcT.y = Math.min(Math.max(rcT.y, rc2.y), rc2.bottom - rcT.height);
								break;
							}
							obRet.pt = new Point(rcT.x, rcT.y);
						} else {
							obRet.pt = new Point(rc2.left + (rc2.width - ptSize.x)/2, rc2.top + (rc2.height - ptSize.y)/2);
						}
						obRet.depth = i; 
					}
					if ('prefer' in obConst && obConst['prefer'] == nDir) {
						obRet.depth += 0.5;
					}
					aobRet.push({pt:obRet.pt, depth:obRet.depth});
				}

				// fits above
				if ((rcOutside.top - rcIn.top) >= (ptSize.y-0.5)) {
					nDir = ABOVE;
					rc2 = rcIn.clone();
					rc2.bottom = Math.min(rc2.bottom, rcOutside.top);
					fnCommon();
				}
							
				// fits below
				if ((rcIn.bottom - rcOutside.bottom) >= (ptSize.y-0.5)) {
					nDir = BELOW;
					rc2 = rcIn.clone();
					rc2.top = Math.max(rc2.top, rcOutside.bottom);
					fnCommon();
				}

				// fits left
				if ((rcOutside.left - rcIn.left) >= (ptSize.x-0.5)) {
					nDir = LEFT;
					rc2 = rcIn.clone();
					rc2.right = Math.min(rc2.right, rcOutside.left);
					fnCommon();
				}
							
				// fits right
				if ((rcIn.right - rcOutside.right) >= (ptSize.x-0.5)) {
					nDir = RIGHT;
					rc2 = rcIn.clone();
					rc2.left = Math.max(rc2.left, rcOutside.right);
					fnCommon();
				}
							
				aobRet.sortOn('depth', Array.NUMERIC | Array.DESCENDING);
				if (aobRet.length == 0) return null; // Constraint does not apply
				return aobRet[0];
			} else {
				return null; // No constraints?!?
			}
		}
		
		// Return a rect that is padded out to the nearest whole number on all sides.
		// The new rect is guaranteed to completely enclose the original.
		public static function Integerize(rc:Rectangle): Rectangle {
			return new Rectangle(int(rc.x), int(rc.y), Math.ceil(rc.right) - int(rc.left), Math.ceil(rc.bottom) - int(rc.top));
		}
	}
}