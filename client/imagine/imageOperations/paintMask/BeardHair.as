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
package imagine.imageOperations.paintMask
{
	import de.polygonal.math.PM_PRNG;
	
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class BeardHair
	{
		private const thickness:Number = 1;

		public var rnd:PM_PRNG;
		
		public var length:Number = 100;
		public var color:Number = 0;
		public var hairAlpha:Number = 1;

		// Curviness
		public var initialCurveJiggle:Number = 10;
		public var curveJiggle:Number = 10;
		public var curveAccel:Number = 1.5;
		public var lengthJiggle:Number = 1.2;
		public var lengthAccel:Number = 1.1;

		public function BeardHair(nLength:Number=100)
		{
			length = nLength;
		}
		
		private function RandBetween(nStart:Number, nEnd:Number): Number {
			return rnd.nextDoubleRange(nStart, nEnd);
		}
		
		
		private function GetHairPoints(): Object {
			var apts:Array = [];

			apts.push(new Point(0, 0));
			
			var nDirection:Number = 90; // down
			var nCurve:Number = 0;
			var nCurveJiggle:Number = curveJiggle;
			var nDirectionJiggle:Number = 0.8;
			var nLength:Number = 10;
			var nLengthJiggle:Number = lengthJiggle;
			
			// Number of curves can be between 0 and 4
			var nCurves:Number = Math.round(rnd.nextIntRange(0, 4));
			
			// Number of points must be odd and at least 3
			var nPoints:Number = 3 + nCurves * 2;

			var fFixedDirection:Boolean = true;
			
			nCurve += RandBetween(-initialCurveJiggle, initialCurveJiggle);
			
			// Put a few points on the beginning with alpha fading in
			var nFadeInLength:Number = nLength * 0.3;
			var nFadeInSteps:Number = 1;
			var nFadeInPoints:Number = nFadeInSteps * 2;
			var nFadeInAlphaStart:Number = 0.3;
			
			nPoints += nFadeInPoints;			
			
			var anAlphas:Array = [];

			while (apts.length < nPoints) {
				var nAlpha:Number = 1;
				if (apts.length < nFadeInPoints) {
					nLen = nLength * nFadeInLength / nFadeInPoints;
					nAlpha = nFadeInAlphaStart + (1 - nFadeInAlphaStart) * apts.length / nFadeInPoints;
				} else {
					if (!fFixedDirection) {
						nCurve += RandBetween(-nCurveJiggle, nCurveJiggle);
						nDirection += nCurve;
						
						// Normalize our direction to be between -90 and 270.
						while (nDirection > 270)
							nDirection -= 360;
						while (nDirection < -90)
							nDirection += 360;
						// Now add gravity
						// if nDirection < 90, add a bit
						// if nDirection > 90, subtract a bit
						// The closer we are to the start of the hair, the stronger gravity is.
						var nGravity:Number = nDirection - 90;
						nGravity *= rnd.nextDoubleRange(0, 1);
						nGravity *= (apts.length - nPoints) / nPoints;
						nDirection += nGravity;
						nCurveJiggle *= curveAccel;
					}
					
					// Default length is nLength == 10
					// Jiggle a bit. Say maybe +-20% => 0.8 to 1.2 multiplier Increase jiggle slightly over time.
					var nLen:Number = nLength * RandBetween(1/nLengthJiggle, nLengthJiggle);
					nLengthJiggle *= lengthAccel;
				}
					
				var ptPrev:Point = apts[apts.length-1];
				
				var ptNew:Point = new Point(ptPrev.x + nLen * Math.cos(nDirection * Math.PI / 180),
					ptPrev.y + nLen * Math.sin(nDirection * Math.PI / 180));

				apts.push(ptNew);
				anAlphas.push(nAlpha);

				fFixedDirection = !fFixedDirection;
			}
			return {apts:apts, anAlphas:anAlphas};
		}
		
		private function TransformPoint(pt:Point, xOff:Number, yOff:Number, nScale:Number): Point { // Apply offset first
			return new Point((pt.x + xOff) * nScale, (pt.y + yOff) * nScale);
		}

		private static function GetBounds(apts:Array, mat:Matrix): Rectangle {
			var pt1:Point = mat.transformPoint(apts[0]);
			
			var xMin:Number = pt1.x;
			var xMax:Number = pt1.x;
			var yMin:Number = pt1.y;
			var yMax:Number = pt1.y;
			for each (var pt2:Point in apts) {
				pt2 = mat.transformPoint(pt2);
				xMin = Math.min(xMin, pt2.x);
				xMax = Math.max(xMax, pt2.x);
				yMin = Math.min(yMin, pt2.y);
				yMax = Math.max(yMax, pt2.y);
			}
			return new Rectangle(xMin, yMin, xMax - xMin, yMax - yMin);
		}

		private function ConstrainPoints(nLength:Number, apts:Array, mat:Matrix): void {
			var rcBounds:Rectangle = GetBounds(apts, mat);
			var ptCenter:Point = new Point(rcBounds.x + rcBounds.width / 2, rcBounds.y + rcBounds.height / 2);
			
			mat.translate(-ptCenter.x, -ptCenter.y);

			var nScale:Number = nLength / Math.max(rcBounds.width, rcBounds.height);
			mat.scale(nScale, nScale);
		}
		
		private static const knScaleVariance:Number = 0.4;
		
		private function ApplyMatrix(apts:Array, mat:Matrix): void {
			for (var i:Number = 0; i < apts.length; i++) {
				apts[i] = mat.transformPoint(apts[i]);
			}
		}
		
		public function Draw(spr:Sprite, rcArea:Rectangle): void {
			var obPoints:Object = GetHairPoints();
			var apts:Array = obPoints.apts;
			var anAlphas:Array = obPoints.anAlphas;
			
			var nLength:Number = length * (1 + rnd.nextDoubleRange(0, knScaleVariance) - knScaleVariance);
			var mat:Matrix = new Matrix();
			ConstrainPoints(nLength, apts, mat);
			
			var nRotation:Number = rnd.nextDoubleRange(-10 * Math.PI / 180, 10 * Math.PI/180);
			
			// Now rotate
			mat.rotate(nRotation);
			var rcBounds:Rectangle = GetBounds(apts, mat); // Bounds of our hair. Should be of max len nLength, centered at 0,0
			
			// Now place within rcArea
			
			// Make sure it isn't too large after our rotation
			var nScale:Number = 0.8 * Math.min(rcArea.width / rcBounds.width, rcArea.height / rcBounds.height);
			if (nScale < 1) {
				mat.scale(nScale, nScale);
				rcBounds = GetBounds(apts, mat); // Bounds of our hair. Should be of max len nLength, centered at 0,0
			}
			
			// Now place it randomly within rcArea
			var xOffset:Number = rnd.nextDoubleRange(-1, 1) * rnd.nextDoubleRange(0, 1); // Result is between -1 and 1, clustered close to zero
			xOffset = (xOffset + 1) / 2; // 0 to 1
			xOffset *= rcArea.width - rcBounds.width; // 0 to max offset
			xOffset += rcArea.x - rcBounds.x; // min offset to max offset

			var yOffset:Number = rnd.nextDoubleRange(-1, 1) * rnd.nextDoubleRange(0, 1); // Result is between -1 and 1, clustered close to zero
			yOffset = (yOffset + 1) / 2; // 0 to 1
			yOffset *= rcArea.height - rcBounds.height; // 0 to max offset
			yOffset += rcArea.y - rcBounds.y; // min offset to max offset

			mat.translate(xOffset, yOffset);
			
			// Apply our transformation
			ApplyMatrix(apts, mat);
			
			var graphics:Graphics = spr.graphics;

			var nAlpha:Number = 1;
			nAlpha = anAlphas[0];
			graphics.lineStyle(0.1, color, nAlpha * hairAlpha);
			graphics.moveTo(apts[0].x, apts[0].y);
			
			var nNewAlpha:Number;
			for (var i:Number = 1; i < (apts.length-1); i += 2) {
				graphics.curveTo(apts[i].x, apts[i].y, apts[i+1].x, apts[i+1].y);
				nNewAlpha = anAlphas[i+1];
				if (nNewAlpha != nAlpha) {
					nAlpha = nNewAlpha;
					graphics.lineStyle(0.1, color, nAlpha * hairAlpha);
				}
			}
		}
	}
}