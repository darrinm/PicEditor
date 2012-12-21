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
package util
{
	public class RGBColor
	{
		public static function RGBtoUint(nR:Number, nG:Number, nB:Number): uint {
			return (Math.floor(nR) << 16) | (Math.floor(nG) << 8) | (Math.floor(nB));
		}
		
		public static function Normalize(n:Number): Number {
			n = Math.round(n);
			n = Math.min(n, 255);
			n = Math.max(n, 0);
			return n;
		}
		
		public static function RGBAtoUint(nR:Number, nG:Number, nB:Number, nA:Number): uint {
			return (Normalize(nA) << 24) | (Normalize(nR) << 16) |
				(Normalize(nG) << 8) | (Normalize(nB));
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