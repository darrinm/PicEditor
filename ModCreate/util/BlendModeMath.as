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
	public class BlendModeMath
	{
		public static function GetPaletteMap(fn:Function, nB:Number, nColorShift:Number): Array {
			var an:Array = [];
			for (var i:Number = 0; i <= 255; i++) {
				an.push(Math.min(Math.max(Math.round(fn(nB, i)), 0), 255) << nColorShift);
			}
			return an;
		}
		
		public static function GetColorMaps(fnBlend:Function, clr:Number): Array {
			var aanMaps:Array = [];
			if (fnBlend == null || isNaN(clr)) {
				aanMaps = [null, null, null];
			} else {
				aanMaps.push(BlendModeMath.GetPaletteMapForColor(fnBlend, clr, 16));
				aanMaps.push(BlendModeMath.GetPaletteMapForColor(fnBlend, clr, 8));
				aanMaps.push(BlendModeMath.GetPaletteMapForColor(fnBlend, clr, 0));
			}
			return aanMaps;
		}
		
		public static function GetPaletteMapForColor(fn:Function, clr:Number, nColorShift:Number): Array {
			var nB:Number = (clr >> nColorShift) & 0xff;
			return GetPaletteMap(fn, nB, nColorShift);
		}
		
		public static const kaobFuncs:Array = [
				{label:"Normal", fn:Normal},
				{label:"Lighten", fn:Lighten},
				{label:"Darken", fn:Darken},
				{label:"Multiply", fn:Multiply},
				{label:"Average", fn:Average},
				{label:"Add", fn:Add},
				{label:"Subtract", fn:Subtract},
				{label:"Difference", fn:Difference},
				{label:"Negation", fn:Negation},
				{label:"Screen", fn:Screen},
				{label:"Exclusion", fn:Exclusion},
				{label:"Overlay", fn:Overlay},
				{label:"SoftLight", fn:SoftLight},
				{label:"HardLight", fn:HardLight},
				{label:"ColorDodge", fn:ColorDodge},
				{label:"ColorBurn", fn:ColorBurn},
				{label:"LinearDodge", fn:LinearDodge},
				{label:"LinearBurn", fn:LinearBurn},
				{label:"LinearLight", fn:LinearLight},
				{label:"VividLight", fn:VividLight},
				{label:"PinLight", fn:PinLight},
				{label:"HardMix", fn:HardMix},
				{label:"Reflect", fn:Reflect},
				{label:"Glow", fn:Glow},
				{label:"Phoenix", fn:Phoenix}];

		public static function Normal(B:Number, L:Number): Number {
			return B;
		}
		public static function Lighten(B:Number, L:Number): Number {
			return     (((L > B) ? L:B));
		}
		public static function Darken(B:Number, L:Number): Number {
			return (((L > B) ? B:L));
		}
		public static function Multiply(B:Number, L:Number): Number {
			return    (((B * L) / 255));
		}
		public static function Average(B:Number, L:Number): Number {
			return     (((B + L) / 2));
		}
		public static function Add(B:Number, L:Number): Number {
			return    ((Math.min(255, (B + L))));
		}
		public static function Subtract(B:Number, L:Number): Number {
			return    (((B + L < 255) ? 0:(B + L - 255)));
		}
		public static function Difference(B:Number, L:Number): Number {
			return  ((Math.abs(B - L)));
		}
		public static function Negation(B:Number, L:Number): Number {
			return    ((255 - Math.abs(255 - B - L)));
		}
		public static function Screen(B:Number, L:Number): Number {
			return ((255 - (((255 - B) * (255 - L)) >> 8)));
		}
		public static function Exclusion(B:Number, L:Number): Number {
			return   ((B + L - 2 * B * L / 255));
		}
		public static function Overlay(B:Number, L:Number): Number {
			return     (((L < 128) ? (2 * B * L / 255):(255 - 2 * (255 - B) * (255 - L) / 255)));
		}
		public static function SoftLight(B:Number, L:Number): Number {
			return   (((L < 128)?(2*((B>>1)+64))*(L/255):(255-(2*(255-((B>>1)+64))*(255-L)/255))));
		}
		public static function HardLight(B:Number, L:Number): Number {
			return   (Overlay(L,B));
		}
		public static function ColorDodge(B:Number, L:Number): Number {
			return  (((L == 255) ? L:Math.min(255, ((B << 8 ) / (255 - L)))));
		}
		public static function ColorBurn(B:Number, L:Number): Number {
			return   (((L == 0) ? L:Math.max(0, (255 - ((255 - B) << 8 ) / L))));
		}
		public static function LinearDodge(B:Number, L:Number): Number {
			return (Add(B,L));
		}
		public static function LinearBurn(B:Number, L:Number): Number {
			return  (Subtract(B,L));
		}
		public static function LinearLight(B:Number, L:Number): Number {
			return ((L < 128)?LinearBurn(B,(2 * L)):LinearDodge(B,(2 * (L - 128))));
		}
		public static function VividLight(B:Number, L:Number): Number {
			return  ((L < 128)?ColorBurn(B,(2 * L)):ColorDodge(B,(2 * (L - 128))));
		}
		public static function PinLight(B:Number, L:Number): Number {
			return    ((L < 128)?Darken(B,(2 * L)):Lighten(B,(2 * (L - 128))));
		}
		public static function HardMix(B:Number, L:Number): Number {
			return     (((VividLight(B,L) < 128) ? 0:255));
		}
		public static function Reflect(B:Number, L:Number): Number {
			return     (((L == 255) ? L:Math.min(255, (B * B / (255 - L)))));
		}
		public static function Glow(B:Number, L:Number): Number {
			return   (Reflect(L,B));
		}
		public static function Phoenix(B:Number, L:Number): Number {
			return     ((Math.min(B,L) - Math.max(B,L) + 255));
		}

		public function BlendModeMath()
		{
		}

	}
}