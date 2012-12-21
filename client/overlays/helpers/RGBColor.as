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
	public class RGBColor
	{
		public static function RGBtoUint(nR:Number, nG:Number, nB:Number): uint {
			return (Math.floor(nR) << 16) | (Math.floor(nG) << 8) | (Math.floor(nB));
		}
		
		public static function RedFromUint(clr:uint): Number {
			return (clr & 0xff0000) >> 16;
		}
		public static function GreenFromUint(clr:uint): Number {
			return (clr & 0x00ff00) >> 8;
		}
		public static function BlueFromUint(clr:uint): Number {
			return (clr & 0x0000ff);
		}
		public static function UintFromOb(ob:Object): uint {
			return RGBtoUint(ob.nR, ob.nG, ob.nB);
		}
		
		public static function Blend(coA:uint, coB:uint, nAmountA:Number): uint {
			var nR:int = (coA & 0xff0000) * nAmountA + (coB & 0xff0000) * (1 - nAmountA);
			var nG:int = (coA & 0x00ff00) * nAmountA + (coB & 0x00ff00) * (1 - nAmountA);
			var nB:int = (coA & 0x0000ff) * nAmountA + (coB & 0x0000ff) * (1 - nAmountA);
			return (nR & 0xff0000) | (nG & 0x00ff00) | (nB & 0x0000ff);
		}
		
		private static const knLumR:Number = 0.3086;
		private static const knLumG:Number = 0.6094;
		private static const knLumB:Number = 0.0820;
		// Returns a luminosity value for a color, 0-255 int
		public static function LuminosityFromUint(clr:uint): Number {
			return LuminosityFromRGB(RedFromUint(clr), GreenFromUint(clr), BlueFromUint(clr));
		}

		// Returns a luminosity value for a color, 0-255 int
		public static function LuminosityFromRGB(nR:Number, nG:Number, nB:Number): Number {
			var nLum:Number = knLumR * nR + knLumG * nG + knLumB * nB;
			nLum = Math.round(nLum);
			nLum = Math.min(255,Math.max(nLum, 0));
			return nLum;
		}

		// Resulting object has nR, nG, and nB members
		public static function AdjustLum(clrIn:Number, nTargetLum:Number): Object {
			var nR:Number = RGBColor.RedFromUint(clrIn);
			var nG:Number = RGBColor.GreenFromUint(clrIn);
			var nB:Number = RGBColor.BlueFromUint(clrIn);
			return AdjustLumRGB(nR, nG, nB, nTargetLum);
		}

		// Resulting object has nR, nG, and nB members
		public static function AdjustLumRGB(nR:Number, nG:Number, nB:Number, nTargetLum:Number): Object {
			var nLumIn:Number = RGBColor.LuminosityFromRGB(nR, nG, nB);
			var nLumShift:Number = nTargetLum - nLumIn;
			
			// Shift everything
			nR += nLumShift;
			nG += nLumShift;
			nB += nLumShift;
			// Now adjust for overflow
			var bFlipped:Boolean = (nLumShift > 0);
			if (bFlipped) {
				// Flip the colors so that we only need to check the < 0 case
				nR = 255 - nR;
				nG = 255 - nG;
				nB = 255 - nB;
			}
			nLumShift = 0; // overflow luminosity
			while (nR < 0 || nG < 0 || nB < 0 || nLumShift != 0) {
				if (nR < 0) {
					nLumShift += nR * knLumR;
					nR = 0;
				}
				if (nG < 0) {
					nLumShift += nG * knLumG;
					nG = 0;
				}
				if (nB < 0) {
					nLumShift += nB * knLumB;
					nB = 0;
				}
				var nShift:Number = 0;
				// Now redistribute the overflow luminosity
				// If all colors are zero, we're done.
				if (nR == 0 && nG == 0 && nB == 0) {
				// Next, check for the case where two colors are already at zero
				} else if (nR == 0 && nG == 0) {
					nB += nLumShift / knLumB;
					if (nB < 0.4) nB == 0;
				} else if (nR == 0 && nB == 0) {
					nG += nLumShift / knLumG;
					if (nG < 0.4) nG == 0;
				} else if (nG == 0 && nB == 0) {
					nR += nLumShift / knLumR;
					if (nR < 0.4) nR == 0;
				// Next check for the case where one color is at zero (share between other two colors)
				} else if (nR == 0) {
					// We need to shift both colors by the same amount with a target of achieving the correct lum shift
					nShift = nLumShift / (knLumG + knLumB);
					nG += nShift;
					nB += nShift;
				} else if (nG == 0) {
					nShift = nLumShift / (knLumR + knLumB);
					nR += nShift;
					nB += nShift;
				} else if (nB == 0) {
					nShift = nLumShift / (knLumR + knLumG);
					nR += nShift;
					nG += nShift;
				} else { // All are zero, we're done
					nR = nG = nB = 0;
				}
				nLumShift = 0;
			}
			nR = int(nR);
			if (nR < 0) nR = 0;
			nG = int(nG);
			if (nG < 0) nG = 0;
			nB = int(nB);
			if (nB < 0) nB = 0;
	
			if (bFlipped) {
				// Flip the colors back
				nR = 255 - nR;
				nG = 255 - nG;
				nB = 255 - nB;
			}
			return {nR:nR, nG:nG, nB:nB};
		}

		// hue goes from 0 to 360
		// sat goes from 0 to 100
		// val goes from 0 to 100
		public static function HSVtoUint(hue:Number, sat:Number, val:Number):uint {
			var red:Number;
			var grn:Number;
			var blu:Number;
			var i:Number;
			var f:Number;
			var p:Number;
			var q:Number;
			var t:Number;
			while (hue < 0) hue += 360;
			while (hue >= 360) hue -= 360;
			if (val > 100) val = 100;
			if (val < 0) val = 0;
			if (sat > 100) sat = 100;
			if (sat < 0) sat = 0;
			if(val==0) {return 0;}
			sat/=100;
			val/=100;
			hue/=60;
			i = Math.floor(hue);
			f = hue-i;
			p = val*(1-sat);
			q = val*(1-(sat*f));
			t = val*(1-(sat*(1-f)));
			if (i==0) {red=val; grn=t; blu=p;}
			else if (i==1) {red=q; grn=val; blu=p;}
			else if (i==2) {red=p; grn=val; blu=t;}
			else if (i==3) {red=p; grn=q; blu=val;}
			else if (i==4) {red=t; grn=p; blu=val;}
			else if (i==5) {red=val; grn=p; blu=q;}
			red = Math.floor(red*255);
			grn = Math.floor(grn*255);
			blu = Math.floor(blu*255);
			return RGBtoUint(red, grn, blu);
		}
		
		public static function Uint2HSV(clr:Number): Object {
			var red:Number = RGBColor.RedFromUint(clr);
			var grn:Number = RGBColor.GreenFromUint(clr);
			var blu:Number = RGBColor.BlueFromUint(clr);
			var x:Number, val:Number, f:Number, i:Number, hue:Number, sat:Number;
			red/=255;
			grn/=255;
			blu/=255;
			x = Math.min(Math.min(red, grn), blu);
			val = Math.max(Math.max(red, grn), blu);
			if (x==val){
			return({h:undefined, s:0, v:val*100});
			}
			f = (red == x) ? grn-blu : ((grn == x) ? blu-red : red-grn);
			i = (red == x) ? 3 : ((grn == x) ? 5 : 1);
			hue = Math.floor((i-f/(val-x))*60)%360;
			sat = Math.floor(((val-x)/val)*100);
			val = Math.floor(val*100);
			return({h:hue, s:sat, v:val});
		}
	}
}