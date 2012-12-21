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
package icons
{
	import flash.display.GradientType;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	
	import mx.core.UIComponent;
	import mx.states.State;
	
	import overlays.helpers.RGBColor;

	public class SolidColorIcon extends UIComponent
	{
		private static const kastrStates:Array = ["selectedDisabled", "disabled", "selectedUp", "up", "selectedOver", "over", "selectedDown", "down"];
		protected static const knCornerRadius:Number = 3;

		private var _clr:Number = 0xff0000;
		
		override public function SolidColorIcon()
		{
			super();
			var ast:Array = [];
			for each (var strState:String in kastrStates) {
				var st:State = new State();
				st.name = strState;
				ast.push(st);
			}
			states = ast;
			
			// outer whine shine
			var flt1:DropShadowFilter = new DropShadowFilter(1, 90, 0xffffff, 0.7, 1, 1, 1, 3);
			
			// top shadow
			var flt2:DropShadowFilter = new DropShadowFilter(1, 90, 0, 0.25, 2, 2, 1, 3, true);
			
			filters = [flt1, flt2];
		}
		
		override protected function measure():void {
			super.measure();
			if (parent != null && 'data' in parent) {
				var obData:Object = parent['data'];
				if ('iconColor' in obData)
					_clr = obData.iconColor;
				measuredWidth = obData.iconWidth;
				measuredHeight = obData.iconHeight;
			}
		}
		
		protected function GetGradientColors(): Array {
			var nHighlightAlpha:Number = 0.3;
			var clrBottom:Number = RGBColor.RGBtoUint(
					nHighlightAlpha * 255 + (1-nHighlightAlpha) * RGBColor.RedFromUint(_clr),
					nHighlightAlpha * 255 + (1-nHighlightAlpha) * RGBColor.GreenFromUint(_clr),
					nHighlightAlpha * 255 + (1-nHighlightAlpha) * RGBColor.BlueFromUint(_clr));
			
			return [_clr, clrBottom];
		}
		
		private function GetGradientAlphas(aclr:Array): Array {
			var anAlphas:Array = [];
			for (var i:Number = 0; i < aclr.length; i++)
				anAlphas.push(1);
			return anAlphas;
		}
		
		private function GetGradientRatios(aclr:Array): Array {
			var anRatios:Array = [];
			for (var i:Number = 0; i < aclr.length; i++)
				anRatios.push(i * 255 / (aclr.length-1)); // 0 to 255
			return anRatios;
		}
		
		protected function GetGradientDirection(): Number {
			return Math.PI/2;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			graphics.clear();

			var mat:Matrix = new Matrix();
			mat.createGradientBox(unscaledWidth, unscaledHeight, GetGradientDirection(), 0, 0);
			
			var aclr:Array = GetGradientColors();
			graphics.beginGradientFill(GradientType.LINEAR, aclr, GetGradientAlphas(aclr), GetGradientRatios(aclr), mat);
			graphics.drawRoundRect(0, 0, unscaledWidth, unscaledHeight, knCornerRadius * 2, knCornerRadius * 2);
			graphics.endFill();
		}
	}
}