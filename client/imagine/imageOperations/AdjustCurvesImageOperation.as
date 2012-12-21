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
package imagine.imageOperations
{
	import flash.geom.Point;
	
	import util.SplineInterpolator;

	// This is a palette image operation to adjust curves

	[RemoteClass]
	public class AdjustCurvesImageOperation extends PaletteMapImageOperation {
		private var _aobMasterCurve:Array = null;
		private var _aobRedCurve:Array = null;
		private var _aobGreenCurve:Array = null;
		private var _aobBlueCurve:Array = null;
		private var _nMasterFactor:Number = 1; // Apply master curve this many times. Useful for Exposure which is additive
		private var _asiPreMasterSplines:Array = null;
		
		private const knRedShift:Number = 16;
		private const knGreenShift:Number = 8;
		private const knBlueShift:Number = 0;

		// For helper function Exposure Curve
		private static const kaanDarkenCurve:Array = [[13, 0],[116, 74],[208, 156],[255, 221]];
		private static const kaanLightenCurve:Array = [[0, 17],[47, 81],[129, 186],[221, 255]];
		
		public function AdjustCurvesImageOperation()
		{
			CalcArrays();
		}
		
		private static function GetExposureAdjustmentCurve(nExposure:Number): Array {
			// Exposure -1 returns the darken curve, exposure +1 returns the lighten curve
			// Everthing inbetween returns a curve inbetween
			
			var aanBase:Array;
			
			if (nExposure == 0)
				aanBase = [[0,0],[255,255]];
			else if (nExposure < 0)
				aanBase = kaanDarkenCurve;
			else
				aanBase = kaanLightenCurve;
				
			var aobPoints:Array = [];
			for each (var anPt:Array in aanBase)
				aobPoints.push(new Point(anPt[0], anPt[1]));
				
			return aobPoints;
		}
		
		// Return a number nFactor % of the way from n1 to n2
		// nFactor goes from 0 to 1
		private static function SimpleInterpolate(n1:Number, n2:Number, nFactor:Number): Number {
			return n1 + (n2 - n1) * nFactor;
		}

		// n == 1: +1 stop exposure adjustment
		// n == -1: -1 stop exposure adjustment
		public function set ExposureAdjustmentStops(n:Number): void {
			_nMasterFactor = Math.abs(n);
			MasterCurve = GetExposureAdjustmentCurve(n);
		}
		
		public function set MasterCurve(aob:Array): void {
			// First, clean up our gradient array
			_aobMasterCurve = CleanArray(aob);
			CalcArrays();
		}
		
		public function set PreMasterCurve(aob:Array): void {
			if (aob == null || aob.length == 0) {
				_asiPreMasterSplines = null;
			} else {
				if (aob[0] is SplineInterpolator) {
					_asiPreMasterSplines = aob;
				} else {
					_asiPreMasterSplines = [CreateSplineInterpolator(CleanArray(aob))];
				}
				
			}
			CalcArrays();
		}
		
		// Takes in an array of curves (master, red, green, blue).
		// Each curve is an array of numbers (x0,y0,x1,y1,x2,y2,etc...)
		// This is the same format used in CurveEffect
		// Default curve is 0,0,255,255
		public function set CurveData(aanCurves:Array): void {
			while (aanCurves.length < 4)
				aanCurves.push([0,0,255,255]); // Fill out the array with default curves
			
			_aobMasterCurve = CleanArray(aanCurves[0]);
			_aobRedCurve = CleanArray(aanCurves[1]);
			_aobGreenCurve = CleanArray(aanCurves[2]);
			_aobBlueCurve = CleanArray(aanCurves[3]);
			CalcArrays();
		}
		public function set RedCurve(aob:Array): void {
			// First, clean up our gradient array
			_aobRedCurve = CleanArray(aob);
			CalcArrays();
		}
		
		public function set GreenCurve(aob:Array): void {
			// First, clean up our gradient array
			_aobGreenCurve = CleanArray(aob);
			CalcArrays();
		}
		
		public function set BlueCurve(aob:Array): void {
			// First, clean up our gradient array
			_aobBlueCurve = CleanArray(aob);
			CalcArrays();
		}
		
		public function CleanArray(aob:Array): Array {
			if (aob == null) {
				return null;
			}
			
			if (aob.length < 2) {
				trace("curves adjustment array too small. Must be at least two elements.");
				return null;
			}
			
			if ((aob[0] is Number) && (aob.length % 2) == 0) {
				// Convert number pairs to obejcts
				var aob2:Array = [];
				for (var i:Number = 0; (i+1) < aob.length; i += 2) {
					aob2.push(new Point(aob[i], aob[i+1]));
				}
				aob = aob2;
			} else {
				for each (var ob:Object in aob) {
					if (!("x" in ob)) {
						trace("curves adjustment array object missing x");
						return null;
					}
					if (!("y" in ob)) {
						trace("curves adjustment array object missing y");
						return null;
					}
				}
			}
			return aob;
		}
		
		// Returns null if the incoming array is not valid
		protected function CreateSplineInterpolator(aobPoints:Array): SplineInterpolator {
			if (aobPoints == null) return null;
			if (aobPoints.length == 1) return null;
			var si:SplineInterpolator = new SplineInterpolator();
			for each (var ob:Object in aobPoints) {
				si.add(ob.x, ob.y);
			}
			return si;
		}
		
		// Takes in two spline interpolators
		// Either or both may be null - return normal curve
		// Otherwise, apply both curves
		protected function CalcArray(anOut:Array, nShift:uint, si1:SplineInterpolator, si2:SplineInterpolator, nFactor:Number, asiPreMasterSplines:Array=null): void {
			for (var i:Number = 0; i < 256; i++) {
				var y:Number = i;
				
				if (asiPreMasterSplines != null) {
					for each (var siPre:SplineInterpolator in asiPreMasterSplines)
						y = siPre.Interpolate(y);
				}
				
				if (si1) {
					y = si1.Interpolate(y);
					if (nFactor != 1) {
						var nPrev:Number = i;
						var nFactorTemp:Number = nFactor;
						while (nFactorTemp > 1) {
							nFactorTemp -= 1;
							nPrev = y;
							y = si1.Interpolate(y);
						}
						y = SimpleInterpolate(nPrev, y, nFactorTemp);
					}
				}
				if (si2) y = si2.Interpolate(y);
				if (y < 0) y = 0;
				else if (y > 255) y = 255;
				else y = Math.round(y);
				anOut[i] = y << nShift;
				
			}
		}

		// returns an object with palette arrays (array of number) for .red, .green, and .blue		
		protected function CalcArrays(): void {
			_acoRed = new Array(256);
			_acoGreen = new Array(256);
			_acoBlue = new Array(256);
			var i:Number;
			var siMaster:SplineInterpolator = CreateSplineInterpolator(_aobMasterCurve);
			var siRed:SplineInterpolator = CreateSplineInterpolator(_aobRedCurve);
			var siGreen:SplineInterpolator = CreateSplineInterpolator(_aobGreenCurve);
			var siBlue:SplineInterpolator = CreateSplineInterpolator(_aobBlueCurve);
			CalcArray(_acoRed, knRedShift, siMaster, siRed, _nMasterFactor, _asiPreMasterSplines);
			CalcArray(_acoGreen, knGreenShift, siMaster, siGreen, _nMasterFactor, _asiPreMasterSplines);
			CalcArray(_acoBlue, knBlueShift, siMaster, siBlue, _nMasterFactor, _asiPreMasterSplines);
		}
	}
}