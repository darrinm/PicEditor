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
package controls
{
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.controls.VRule;
	
	public class FadingVRule extends VRule
	{
		private var _acw:Array = [];
		
		public function FadingVRule()
		{
			super();
			_acw.push(ChangeWatcher.watch(this, "topFadeSize", OnFadeChange));
			_acw.push(ChangeWatcher.watch(this, "percentTopFadeSize", OnFadeChange));
			_acw.push(ChangeWatcher.watch(this, "bottomFadeSize", OnFadeChange));
			_acw.push(ChangeWatcher.watch(this, "percentBottomFadeSize", OnFadeChange));
			_acw.push(ChangeWatcher.watch(this, "topAlpha", OnFadeChange));
			_acw.push(ChangeWatcher.watch(this, "midAlpha", OnFadeChange));
			_acw.push(ChangeWatcher.watch(this, "bottomAlpha", OnFadeChange));
		}
		
		private function OnFadeChange(evt:Event): void {
			invalidateDisplayList();
		}
		
		[PercentProxy("percentTopFadeSize")]
		[Bindable]
		public var topFadeSize:Number = NaN;
		
		[Bindable]
		public var percentTopFadeSize:Number = NaN;
		
		[PercentProxy("percentBottomFadeSize")]
		[Bindable]
		public var bottomFadeSize:Number = NaN;
		
		[Bindable]
		public var percentBottomFadeSize:Number = NaN;
		
		[Bindable]
		public var topAlpha:Number = 0;
		
		[Bindable]
		public var midAlpha:Number = 1;
		
		[Bindable]
		public var bottomAlpha:Number = 0;
		
		private function GetFadePixelSize(strSide:String, nFullSize:Number): Number {
			var nFixed:Number = this[strSide.substr(0,1).toLowerCase() + strSide.substr(1) + 'FadeSize'];
			var nPercent:Number = this['percent' + strSide.substr(0,1).toUpperCase() + strSide.substr(1) + 'FadeSize'];
			if (isNaN(nFixed) && isNaN(nPercent))
				nPercent = 0;
			
			if (isNaN(nFixed))
				nFixed = nPercent * nFullSize / 100;
			return nFixed;
		}
		
		/**
		 *  @private
		 *  This code is copied from VRule.as with added fade support
		 *  The appearance of our vertical rule is inspired by
		 *  the leading browser's rendering of HTML's <VR>.
		 *
		 *  The only reliable way to draw the 1-pixel lines that are
		 *  the borders of the vertical rule is by filling rectangles!
		 *  Otherwise, very short lines become antialised, probably because
		 *  the Player is trying to render an endcap.
		 */
		override protected function updateDisplayList(unscaledWidth:Number,
													  unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var nTopFadeSize:Number = GetFadePixelSize("top", unscaledHeight);
			var nBottomFadeSize:Number = GetFadePixelSize("bottom", unscaledHeight);
			
			var nMidSize:Number = unscaledHeight - nTopFadeSize - nBottomFadeSize;
			if (nMidSize < 0) {
				nTopFadeSize += nMidSize/2;
				nBottomFadeSize += nMidSize/2;
				nMidSize = 0;
			}
			
			var g:Graphics = graphics;
			g.clear();
			
			// Look up the style properties
			var strokeColor:Number = getStyle("strokeColor");
			var shadowColor:Number = getStyle("shadowColor");
			var strokeWidth:Number = getStyle("strokeWidth");
			
			// The thickness of the stroke shouldn't be greater than
			// the unscaledWidth of the bounding rectangle.
			if (strokeWidth > unscaledWidth)
				strokeWidth = unscaledWidth;
			
			// The vertical rule extends from the top edge
			// to the bottom edge of the bounding rectangle and
			// is horizontally centered within the bounding rectangle.
			var left:Number = (unscaledWidth - strokeWidth) / 2;
			var top:Number = 0;
			var right:Number = left + strokeWidth;
			var bottom:Number = unscaledHeight;
			
			var anAlphas:Array = [topAlpha, midAlpha, midAlpha, bottomAlpha];
			var anRatios:Array = [0, nTopFadeSize * 255 / unscaledHeight, 255 - nBottomFadeSize * 255 / unscaledHeight, 255];
			var anStrokeColors:Array = [strokeColor, strokeColor, strokeColor, strokeColor];
			var anShadowColors:Array = [shadowColor, shadowColor, shadowColor, shadowColor];
			var mat:Matrix = new Matrix();
			
			if (strokeWidth == 1)
			{
				// *
				// *
				// *
				// *
				// *
				// *
				// *
				mat.createGradientBox(strokeWidth, unscaledHeight, Math.PI/2, left, top);
				g.beginGradientFill(GradientType.LINEAR, anStrokeColors, anAlphas, anRatios, mat);
				g.drawRect(left, top, right-left, unscaledHeight);
				g.endFill();
			}
			else if (strokeWidth == 2)
			{
				// *o
				// *o
				// *o
				// *o
				// *o
				// *o
				// *o
				
				mat.createGradientBox(1, unscaledHeight, Math.PI/2, left, top);
				g.beginGradientFill(GradientType.LINEAR, anStrokeColors, anAlphas, anRatios, mat);
				g.drawRect(left, top, 1, unscaledHeight);
				g.endFill();
				
				mat.createGradientBox(1, unscaledHeight, Math.PI/2, right-1, top);
				g.beginGradientFill(GradientType.LINEAR, anShadowColors, anAlphas, anRatios, mat);
				g.drawRect(right - 1, top, 1, unscaledHeight);
				g.endFill();
			}
			else if (strokeWidth > 2)
			{
				// Will we ever use this?
				throw new Error("Not yet implemented");
				// **o
				// * o
				// * o
				// * o
				// * o
				// * o
				// ooo
				/*
				g.beginFill(strokeColor);
				g.drawRect(left, top, right - left - 1, 1);
				g.endFill();
				
				g.beginFill(shadowColor);
				g.drawRect(right - 1, top, 1, unscaledHeight - 1);
				g.drawRect(left, bottom - 1, right - left, 1);
				g.endFill();
				
				g.beginFill(strokeColor);
				g.drawRect(left, top + 1, 1, unscaledHeight - 2);
				g.endFill();
				*/
			}
		}
}
}