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
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.registerClassAlias;
	
	import util.SplineInterpolator;
	import util.VBitmapData;
	
	[RemoteClass]
	public class CircularBrush extends Brush {
		{ // static block
			// This alias is for backward compatibility with the pre-Imagine class packaging.
			// Yes, that '>' is unexpected but that's what RemoteClass prefixes them all with
			// so that's what we need to be backward-compatible with.
			// The [RemoteClass] above also registers ">imagine.imageOperations.paintMask.CircularBrush"
			registerClassAlias(">imageOperations.paintMask.CircularBrush", CircularBrush);
		}
		
		private var _cbr:CachedBrush = null;
		private var _nColor:Number = NaN;
		
		public function CircularBrush(nDiameter:Number=100, nHardness:Number=0.5) {
			super();
			diameter = nDiameter;
			hardness = nHardness;
		}
		
		override public function get width(): Number {
			return diameter;
		}

		override public function get height(): Number {
			return diameter;
		}

		override public function dispose(): void {
			if (_cbr != null)
				_cbr.ReleaseBitmap(this);
			_cbr = null;
		}
		
		private function get brushBmd(): BitmapData {
			if (_cbr == null) {
				_cbr = CachedBrush.GetBrush("CircularBrush", CreateCircularBrushBitmap, [diameter, hardness, inverted, _nColor]);
				_cbr.AcquireBitmap(this);
			}
			return _cbr.bitmapData;
		}
		
		// If we were to draw into a point, pt, return the dirty rect
		override public function GetDrawRect(ptCenter:Point, nColor:Number=NaN, nRot:Number=NaN): Rectangle {
			_nColor = nColor;
			var rcBrush:Rectangle = new Rectangle(
					Math.round(ptCenter.x-brushBmd.width/2),
					Math.round(ptCenter.y-brushBmd.height/2),
					brushBmd.width,
					brushBmd.height);
			return rcBrush;
		}
		
		override public function DrawInto(bmdTarget:BitmapData, bmdOrig:BitmapData, ptCenter:Point, nAlpha:Number, nColor:Number=NaN, nScaleX:Number=NaN, nScaleY:Number=NaN, nRot:Number=NaN): Rectangle {
			// UNDONE: Support scale, rotation
			
			var mat:Matrix = new Matrix();
			var rcBrush:Rectangle = GetDrawRect(ptCenter, nColor);
			mat.translate(rcBrush.x, rcBrush.y);
			
			var ctr:ColorTransform = null;
			if (nAlpha < 1) {
				if (nAlpha <= 0)
					return new Rectangle();
				else
					ctr = new ColorTransform(1,1,1,nAlpha);
			}
			if (inverted)
				bmdTarget.draw(brushBmd, mat, ctr, BlendMode.MULTIPLY);
			else
				bmdTarget.draw(brushBmd, mat, ctr);
			return rcBrush; // This will be impacted by scale/rotation
		}
		
		private static function MapArray(an:Array, nPct:Number): Number {
			// First array element corresponds to nPct <= 0
			// Last array element corresponds to nPct >= 1
			var nPos:Number = nPct * (an.length-1); // Position in the array
			if (nPos <= 0) return an[0];
			if (nPos >= (an.length-1)) return an[an.length-1];
			// OK, interpolate
			var iPrevPos:Number = Math.floor(nPos);
			var nPctToNext:Number = nPos - iPrevPos;
			var iNextPos:Number = iPrevPos + 1;
			return an[iPrevPos] * (1 - nPctToNext) + an[iNextPos] * nPctToNext;
		}
		
		private static const kaobBrushCurve:Array = [{x:0, y:0}, {x:14, y:4}, {x:35, y:25}, {x:108, y:170}, {x:179, y:242}, {x:255, y:255}];
		
		private static const kanBrushCenterSizes:Array = [5,42,64,89,96]; // Center size out of 100 for brush hardnesses 0,25,60,75,100
		private static function GetBrushCenterSize(nHardness:Number): Number { // For a 100 radius brush
			// kanBrushCenterSizes goes from 0 to 100, map _nBrushHardness to this array
			return MapArray(kanBrushCenterSizes, nHardness);
		}
		
		private static const kanBrushCurveSizes:Array = [166,109,69,40,8]; // Center size out of 100 for brush hardnesses 0,25,60,75,100
		private static function GetBrushCurveSize(nHardness:Number): Number { // For a 100 radius brush
			return MapArray(kanBrushCurveSizes, nHardness);
		}
		
		public static function CreateCircularBrushBitmap(nDiameter:Number, nHardness:Number, fInverted:Boolean, nColor:Number=NaN): BitmapData {
			var nTotalDiameter:Number;
			var spr:Sprite = new Sprite();
			if (nHardness >= 1) {
				nTotalDiameter = nDiameter;
				if (isNaN(nColor))
					spr.graphics.beginFill(fInverted ? 0 : 0, 1);
				else
					spr.graphics.beginFill(nColor, 1);
			} else {
				var nCurveStart:Number = GetBrushCenterSize(nHardness) * nDiameter / 200;
				var nCurveSize:Number = GetBrushCurveSize(nHardness) * nDiameter / 200;
				var nTotalRadius:Number = nCurveStart + nCurveSize;
				nTotalDiameter = nTotalRadius * 2;
				
				var si:SplineInterpolator = new SplineInterpolator();
				
				var nCurveStartPct:Number = nCurveStart / nTotalRadius;
				var nCurveSizePct:Number = nCurveSize / nTotalRadius;
				var i:Number;
				
				// kaobBrushCurve goes from 0,0 (center) to 255,255 (outer) but curves a bit
				// Map our spline to go from 0 to 100
				
				for each (var obPt:Object in kaobBrushCurve) {
					// obPt.x goes from 0 to 255
					// Map that from nCurveStartPct to 1.
					si.add(nCurveStartPct + obPt.x * nCurveSizePct / 255, obPt.y);
				}
				
				var mat:Matrix = new Matrix();
				mat.createGradientBox(nTotalDiameter, nTotalDiameter, 0, 0, 0);			
	
				var anFillColors:Array = []; // [0xffffff, 0x000000]
				var anFillAlpha:Array = []; // = [1,1];
				var anFillRatios:Array = []; // = [0,255];
				
				// 50 to 100 is very straight.
				// Come up with a way to distribute our 16 sample points - along the curve
				var anSamplePoints:Array = [0, 5, 10, 25, 40, 50, 60, 100, 120, 135, 150, 175, 220, 255];
				
				// Map anSamplePoints to to nCurveStartPct to 1, then add 0 to the front
				for (i = 0; i < anSamplePoints.length; i++) {
					anSamplePoints[i] = nCurveStartPct + anSamplePoints[i] * nCurveSizePct / 255;
				}
				anSamplePoints.unshift(0);
				
				// Really low alphas get premultiped and end up with crap values.
				// We can partially alleviate this by setting a minimum alpha. 
				var nAlphaMin:Number = 4;
				
				for each (i in anSamplePoints) {
					var nPctPos:Number = i;
					var iPos255:Number = nPctPos * 255;
					var nFillAlpha:Number = Math.min(255,Math.max(0,Math.round(si.Interpolate(nPctPos))));
					
					
					// Goes from 0 to 255 (center to outside)
					// We want to go from 1 to 0
					if (!fInverted)
						nFillAlpha = 255 - nFillAlpha;
					
					var nFillColor:Number = nColor;
					if (isNaN(nFillColor)) nFillColor = nFillAlpha; // Blue mirrors alpha - to support erase
					
					if (nFillAlpha < nAlphaMin) {
						if (nFillAlpha < (nAlphaMin/2)) nFillAlpha = 0
						else nFillAlpha = nAlphaMin;
					}
					
					nFillAlpha = nFillAlpha / 255; // Scale from 0 to 1
					
					if (fInverted) nFillAlpha = 1;
					
					anFillColors.push(nFillColor);
					anFillAlpha.push(nFillAlpha);
					anFillRatios.push(iPos255);
				}
	
				spr.graphics.beginGradientFill(GradientType.RADIAL, anFillColors, anFillAlpha, anFillRatios, mat);
			}
			spr.graphics.drawCircle(nTotalDiameter/2,nTotalDiameter/2,nTotalDiameter/2);
			spr.graphics.endFill();
			
			// Now create our gradient
			var bmdBrush:BitmapData = VBitmapData.Construct(nTotalDiameter+1, nTotalDiameter+1, true, 0x00ffffff, "circular brush");
			bmdBrush.draw(spr, null, null, null, null, true);
			
			return bmdBrush;
		}
		

	}
}