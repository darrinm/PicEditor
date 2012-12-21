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
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.registerClassAlias;
	
	import mx.utils.NameUtil;
	
	import overlays.helpers.RGBColor;
	
	import util.BitmapCache;
	
	[RemoteClass]
	public class BeardHairBrush extends Brush {
		{ // static block
			// This alias is for backward compatibility with the pre-Imagine class packaging.
			// Yes, that '>' is unexpected but that's what RemoteClass prefixes them all with
			// so that's what we need to be backward-compatible with.
			// The [RemoteClass] above also registers ">imagine.imageOperations.paintMask.BeardHairBrush"
			registerClassAlias(">imageOperations.paintMask.BeardHairBrush", BeardHairBrush);
		}
		
		public function BeardHairBrush() {
			super();
		}
		
		// Settings which impact the cached brushes
		// Inherited: public var diameter:Number;
		public var hairColors:Array = [0, 0xffffff];
		public var initialCurveJiggle:Number = 10;
		public var curveJiggle:Number = 10;
		public var curveAccel:Number = 1.5;
		
		public var density:Number = 0.4; // Number of hairs per stroke for diameter = 10. Actual number changes based on area change.
		public var lengthJiggle:Number = 1.2;
		public var lengthAccel:Number = 1.1;
		public var hairSeed:Number = 1;
		
		// These params effect our hair cache
		private static const knHairSampleCacheParams:Array = ['intDiameter', 'density', 'hairColors', 'hairSeed', 'initialCurveJiggle', 'curveJiggle', 'curveAccel', 'lengthJiggle', 'lengthAccel'];
		
		// Other settings.
		public var initialDirectionJiggle:Number = 10;
		public var style:Number = 0; // Support future style options, e.g. stubble, refinements needed for Santa Beard, etc.
		
		// These are statics to avoid instantiation costs
		private static var _hr:BeardHair = null;
		private static var _spr:Sprite = null;
		
		// Layering constants
		private const knLightSamples:Number = 20;
		private const knDarkSamples:Number = 40;
		private const knSamplePerStroke:Number = 3; // 1 light, the rest dark
		
		// Helper function to collapse curve settings into a single value
		private static const kobCurveParams:Object = {
			initialCurveJiggle: 50,
			curveJiggle: 5.6,
			curveAccel: 2.2
		};
		
		public override function get width():Number {
			return diameter;
		}
		
		public override function get height():Number {
			return diameter;
		}
		
		// nCurvature ranges from 0 to 100
		public function set curvature(nCurvature:Number): void {
			for (var strParam:String in kobCurveParams)
				this[strParam] = nCurvature * kobCurveParams[strParam] / 100;
		}
		
		private function GetHairSampleKey(): String {
			var strCacheKey:String = "";
			for each (var strParam:String in knHairSampleCacheParams) {
				strCacheKey += strParam + ":" + this[strParam];
			}
			return strCacheKey;
		}
		
		private function get intDiameter() :Number {
			// Max brush size needs to fit such that
			// 8 * maxBrushDiameter == 2800
			// or: 8 * (intDiamter * sqrt(2) + 1) == 2800, or intDiameter = ((2800/8) - 1) / sqrt(2) == 246
			return Math.min(Math.round(diameter), 246);
		}
		
		private function GetSampleRectAbsolute(nID:Number, nSampleBmdWidth:Number): Rectangle {
			var cColumnsPerRow:Number = Math.floor(nSampleBmdWidth / maxDiameter);
			var iRow:Number = Math.floor(nID / cColumnsPerRow);
			var iCol:Number = nID - iRow * cColumnsPerRow;
			return new Rectangle(iCol * maxDiameter , iRow * maxDiameter, intDiameter, intDiameter);
		}
		
		private function GetSampleRect(nID:Number, fLight:Boolean, nSampleBmdWidth:Number): Rectangle {
			var nAbsoluteID:Number = nID + (fLight ? 0 : knLightSamples);
			return GetSampleRectAbsolute(nAbsoluteID, nSampleBmdWidth);
		}
		
		private const kanBlurVals:Array = [1, 1.5];
		private const kanBlurDiameters:Array = [25, 50];
		
		private function GetBlur(): Number {
			return Math.max(kanBlurVals[0], Math.min(kanBlurVals[1], kanBlurVals[0] + (kanBlurVals[1] - kanBlurVals[0]) * (intDiameter - kanBlurDiameters[0]) / (kanBlurDiameters[1] - kanBlurDiameters[0])));
		}
		
		private function GenerateHairSamples(): BitmapData {
			var rnd:PM_PRNG = new PM_PRNG();
			rnd.seed = hairSeed;
			
			// Set up our sprite			
			if (_spr == null) {
				_spr = new Sprite();
			} else {
				_spr.graphics.clear();
			}
			var nBlur:Number
			_spr.filters = [new BlurFilter(GetBlur(), GetBlur(), 1)];
			
			// Set up our hair
			if (_hr == null)
				_hr = new BeardHair();
			
			// UNDONE: Be smart about keeping hair mostly pointing the same way
			_hr.rnd = rnd;
			
			_hr.length = intDiameter; // UNDONE: Do something else for stubble.
			// UNDONE: Support different modes?
			_hr.initialCurveJiggle = initialCurveJiggle;
			_hr.curveJiggle = curveJiggle;
			_hr.curveAccel = curveAccel;
			_hr.lengthJiggle = lengthJiggle;
			_hr.lengthAccel = lengthAccel;
			
			// Create the target bitmap
			var bmdHairSamples:BitmapData = new BitmapData(8 * maxDiameter, 8 * maxDiameter, true, 0);
			
			var nSampleArea:Number = intDiameter * intDiameter;
			var nHairsPerStroke:Number = density * nSampleArea / 100;
			var cHairsPerSample:Number = Math.max(1, Math.round(nHairsPerStroke / knSamplePerStroke));
			var aclr:Array = hairColors;
			var nLightColorStart:Number = hairColors.length - hairColors.length / knSamplePerStroke;
			
			for (var iSample:Number = 0; iSample < (knLightSamples + knDarkSamples); iSample++) {
				var rcSample:Rectangle = GetSampleRectAbsolute(iSample, bmdHairSamples.width);
				var fLight:Boolean = iSample < knLightSamples;
				
				var i:Number;
				
				for (i = 0; i < cHairsPerSample; i++) {
					// Get the color
					var nStartColor:Number = fLight ? nLightColorStart : 0;
					var nEndColor:Number = fLight ? (aclr.length-1) : (nLightColorStart - 1);
					var cColors:Number = 1 + nEndColor - nStartColor;
					var nColorsPerHair:Number = cColors / cHairsPerSample;
					var iColor:Number = Math.floor(nStartColor + i * nColorsPerHair + rnd.nextDoubleRange(0, nColorsPerHair - 0.0000001));
					
					_hr.color = aclr[iColor];
					
					// Range from 0.25 to 0.5
					if (cHairsPerSample == 1)
						_hr.hairAlpha = fLight ? 0.55 : 0.3;
					else
						_hr.hairAlpha = 0.15 + 0.4 * i / (cHairsPerSample-1);
					
					_hr.Draw(_spr, rcSample);
				}
				
			}
			bmdHairSamples.draw(_spr, null, null, null, null, true);
			return bmdHairSamples;
		}
		
		public function UpdateHairSamples(): void {
			// Trigger generation of hair samples if needed
			GetHairSamples();
		}
		
		private function GetHairSamples(): BitmapData {
			var bmdHairSamples:BitmapData = BitmapCache.Lookup("HairBrush", "HairSample", GetHairSampleKey(), null);
			if (bmdHairSamples == null) {
				bmdHairSamples = GenerateHairSamples();
				BitmapCache.Set("HairBrush", "HairSample", GetHairSampleKey(), null, bmdHairSamples);
			}
			return bmdHairSamples;
		}
		
		private static const knHairLengthPercent:Number = 0.8;
		
		private function get maxDiameter(): Number {
			// Should be the same as GetRotatedDiameter(Math.PI/4)
			return Math.ceil(intDiameter * Math.SQRT2);
		}
		
		private function GetRotatedDiameter(nRot:Number): Number {
			if (isNaN(nRot) || nRot == 0)
				return intDiameter;
			
			var pt:Point = new Point(intDiameter, intDiameter);
			var mat:Matrix = new Matrix();
			mat.rotate(nRot);
			pt = mat.transformPoint(pt);
			return Math.ceil(Math.max(Math.abs(pt.x), Math.abs(pt.y), intDiameter)); // Extra padding to make sure we don't miss any pixels
		}
		
		override public function DrawInto(bmdTarget:BitmapData, bmdOrig:BitmapData, ptCenter:Point, nAlpha:Number, nColor:Number=NaN, nScaleX:Number=NaN, nScaleY:Number=NaN, nRot:Number=NaN): Rectangle {
			var rcEffected:Rectangle = null;
			var bmdHairSamples:BitmapData = GetHairSamples();
			
			var rnd:PM_PRNG = new PM_PRNG();
			rnd.seed = Math.round(ptCenter.x * 1000);
			rnd.seed = rnd.nextInt() + ptCenter.y * 1000;
			if (!isNaN(nRot))
				rnd.seed = rnd.nextInt() + nRot * 1000;
			
			var degRotation:Number = nRot;
			// Use the rotation as a minor guide. Mostly, hang down with slight left-right variance.
			// 90 is down, our center
			
			// First, center on 90, range 270 to -90
			while (degRotation > 270)
				degRotation -= 360;
			while (degRotation < -90)
				degRotation += 360;
			
			// Next, flip up angles to be down angles.
			if (degRotation < 0) // -90 (up) to 0 (right) become 90 (down) to 0 (right)
				degRotation = -degRotation;
			if (degRotation > 180) // 180 (left) to 270 (up) become 180 (left) to 90 (down)
				degRotation = 360 - degRotation;
			
			// Now, reduce the swing
			degRotation = 90 + (degRotation -90) * 0.4;
			
			// Draw our samples.
			for (var i:Number = 0; i < knSamplePerStroke; i++) {
				var fLight:Boolean = i == (knSamplePerStroke-1);
				
				var iSample:Number = rnd.nextIntRange(0, (fLight ? knLightSamples : knDarkSamples)-1);
				var rcSample:Rectangle = GetSampleRect(iSample, fLight, bmdHairSamples.width);
				
				// The hair starts out going down. We can rotate if we want (around the origin) and then shift our hair circle if we have room
				
				var radRotation:Number = (degRotation + rnd.nextDoubleRange(-initialDirectionJiggle, initialDirectionJiggle)); // Don't exactly follow the mouse
				// 90 degrees == 0 radians
				radRotation -= 90;
				radRotation = radRotation * Math.PI / 180;
				
				var nRotatedDiameter:Number = GetRotatedDiameter(radRotation);
				
				var rcBounds:Rectangle = new Rectangle(
					ptCenter.x - nRotatedDiameter/2 + rnd.nextDoubleRange(-2, 2),
					ptCenter.y - nRotatedDiameter/2 + rnd.nextDoubleRange(-2, 2),
					nRotatedDiameter, nRotatedDiameter);
				
				var mat:Matrix = new Matrix();
				// Move the center to 0,0
				mat.translate(-(rcSample.x + rcSample.width/2), -(rcSample.y + rcSample.height/2));
				// Now rotate
				mat.rotate(radRotation);
				
				// Now move to rcBounds center
				mat.translate(rcBounds.x + rcBounds.width/2, rcBounds.y + rcBounds.height/2);
				
				bmdTarget.draw(bmdHairSamples, mat, null, null, rcBounds, true);
				if (rcEffected == null)
					rcEffected = rcBounds;
				else
					rcEffected = rcEffected.union(rcBounds);
			}
			if (rcEffected != null) {
				rcEffected.left = Math.floor(rcEffected.left);
				rcEffected.top = Math.floor(rcEffected.top);
				rcEffected.bottom = Math.ceil(rcEffected.bottom);
				rcEffected.right = Math.ceil(rcEffected.right);
			}
			// rcEffected.inflate(1,1);
			return rcEffected;
		}
	}
}