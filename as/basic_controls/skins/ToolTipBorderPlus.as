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
package skins
{
	import mx.skins.halo.ToolTipBorder;
	import flash.display.Graphics;
	import mx.graphics.RectangularDropShadow;
	import flash.filters.DropShadowFilter;

	public class ToolTipBorderPlus extends ToolTipBorder
	{
		private var dropShadow:RectangularDropShadow;

		/**
		 *  @private
		 *  Draw the background and border.
		 */
		override protected function updateDisplayList(w:Number, h:Number):void
		{	
			super.updateDisplayList(w, h);
	
			var borderStyle:String = getStyle("borderStyle");
			var backgroundColor:uint = getStyle("backgroundColor");
			var backgroundAlpha:Number= getStyle("backgroundAlpha");
			var borderColor:uint = getStyle("borderColor");
			var cornerRadius:Number = getStyle("cornerRadius");
			var shadowColor:uint = getStyle("shadowColor");
			var shadowAlpha:Number = 0.1;
	
			var g:Graphics = graphics;
			g.clear();
			
			filters = [];
	
			switch (borderStyle)
			{
				case "toolTip":
				{
					// face
					drawRoundRect(
						3, 1, w - 6, h - 4, cornerRadius,
						backgroundColor, backgroundAlpha)
					
					if (!dropShadow)
						dropShadow = new RectangularDropShadow();
	
					dropShadow.distance = 3;
					dropShadow.angle = 90;
					dropShadow.color = 0;
					dropShadow.alpha = 0.4;
	
					dropShadow.tlRadius = cornerRadius + 2;
					dropShadow.trRadius = cornerRadius + 2;
					dropShadow.blRadius = cornerRadius + 2;
					dropShadow.brRadius = cornerRadius + 2;
	
					dropShadow.drawShadow(graphics, 3, 0, w - 6, h - 4);
	
					break;
				}
	
				case "errorTipRight":
				{
					// border
					drawRoundRect(
						11, 0, w - 11, h - 2, 3,
						borderColor, backgroundAlpha);
	
					// left pointer
					var yMid:Number = Math.floor((h-2)/2);
					g.beginFill(borderColor, backgroundAlpha);
					g.moveTo(11, yMid-6);
					g.lineTo(0, yMid);
					g.lineTo(11, yMid+6);
					g.moveTo(11, yMid-6);
					g.endFill();
					
					filters = [ new DropShadowFilter(2, 90, 0, 0.4) ];
					break;
				}
	
				case "errorTipAbove":
				{
					// border
					drawRoundRect(
						0, 0, w, h - 13, 3,
						borderColor, backgroundAlpha);
	
					// bottom pointer
					g.beginFill(borderColor, backgroundAlpha);
					g.moveTo(9, h - 13);
					g.lineTo(15, h - 2);
					g.lineTo(21, h - 13);
					g.moveTo(9, h - 13);
					g.endFill();
	
					filters = [ new DropShadowFilter(2, 90, 0, 0.4) ];
					break;
				}
	
				case "errorTipBelow":
				{
					// border
					drawRoundRect(
						0, 11, w, h - 13, 3,
						borderColor, backgroundAlpha);
	
					// top pointer
					g.beginFill(borderColor, backgroundAlpha);
					g.moveTo(9, 11);
					g.lineTo(15, 0);
					g.lineTo(21, 11);
					g.moveTo(10, 11);
					g.endFill();
					
					filters = [ new DropShadowFilter(2, 90, 0, 0.4) ];
					break;
				}
			}
		}
	}
}