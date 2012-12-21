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
	import com.primitives.DrawUtils;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;
	
	import overlays.helpers.RGBColor;

	[Event(name="change", type="flash.events.Event")]

	public class LipstickColorPalette extends UIComponent
	{
		[Embed("/assets/bitmaps/lipstick_color_shine.png")]
		private static var _clsShine:Class;
		private var _nSelectedColorIndex:Number = 8;
		
		private var _sprThumb:Sprite = null;
		private static const knThumbDiameter:Number = 6.5;
		private static const knThumbHoleDiameter:Number = 4.5;
		
		public function LipstickColorPalette()
		{
			super();
			colors = [
					// top row
					0xee626a,
					0xd47971,
					0x9b5d5c,
					0xee7f71,
					0xfa5f6c,
					0xfe648b,
					//bottom row
					0xb2585e,
					0xf05a58,
					0xf37995,
					0xff484d,
					0xed2850
				];
			filters = [new DropShadowFilter(1, -90, 0, 0.2, 3, 3, 1, 3, true)];
		}
		
		[Bindable] public var color:Number = 0xEF676F;
		
		private var _anColors:Array = [];
		
		private var _fSelected:Boolean = false;
		
		public function set selected(fSelected:Boolean): void {
			_fSelected = fSelected;
			Reset();
		}
		
		public function Reset(): void {
			selectedColorIndex = 8;
		}
		
		public function set colors(anColors:Array): void {
			_anColors = anColors;
			invalidateDisplayList();
		}
		
		public function set selectedColorIndex(n:Number): void {
			color = _anColors[n];
			
			var nPrevSelected:Number = _nSelectedColorIndex;
			_nSelectedColorIndex = n;
			if (numChildren > 0) {
				UpdateThumb();
				if (nPrevSelected >= 0)
					UpdateChildColor(nPrevSelected)
				dispatchEvent(new Event(Event.CHANGE));
			}
		}
		
		private function UpdateThumb(): void {
			if (numChildren == 0) return;
			if (_sprThumb == null) {
				_sprThumb = new Sprite();
				_sprThumb.filters = [new DropShadowFilter(1, 90, 0.0, 0.3)];
				_sprThumb.mouseEnabled = false;
				_sprThumb.mouseChildren = false;
				addChild(_sprThumb);
			} else if (getChildIndex(_sprThumb) != (numChildren-1)) {
				setChildIndex(_sprThumb, numChildren-1);
			}
			// Draw and position the thumb
			var pt:Point = GetSwatchCenter(_nSelectedColorIndex);
			_sprThumb.graphics.clear();
			_sprThumb.graphics.beginFill(0xffffff);
			_sprThumb.graphics.drawCircle(0,0,knThumbDiameter);
			_sprThumb.graphics.beginFill(_anColors[_nSelectedColorIndex]);
			_sprThumb.graphics.drawCircle(0,0,knThumbHoleDiameter);
			
			if (_sprThumb.x != pt.x) {
				_sprThumb.x = pt.x;
				_sprThumb.y = pt.y;
			}
		}
		
		protected override function measure():void {
			measuredWidth = 191;
			measuredHeight = 67;
		}
		
		private static const knSwatchDiameter:Number = 41;
		private static const knColorDiameter:Number = 25;
		private static const knSwatchRowDistance:Number = 26;
		private static const knSwatchColDistance:Number = 30;
		private static const kcSwatchesInLargeRow:Number = 6;
		
		private static const knHorizInset:Number = 17;
		private static const knVertInset:Number = 8;
		
		private static const kcSwatchesInChunk:Number = kcSwatchesInLargeRow * 2 - 1;
		
		private function GetSwatchCenter(i:Number): Point {
			var iChunk:Number = Math.floor(i / kcSwatchesInChunk);
			i -= iChunk * kcSwatchesInChunk; // i becomes chunk index
			
			var yPos:Number = knSwatchDiameter / 2; // First row
			var xPos:Number = knSwatchDiameter / 2; // First col
			
			var iRow:Number = 2 * iChunk;
			var nCol:Number = i;
			
			if (i >= kcSwatchesInLargeRow) {
				// Smaller offset row
				nCol = nCol - kcSwatchesInLargeRow + 0.5;
				iRow += 1; // Second line
			}
			
			yPos += iRow * knSwatchRowDistance;
			xPos += nCol * knSwatchColDistance;
			return new Point(xPos, yPos);
		}
		
		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			graphics.clear();
			var mat:Matrix = new Matrix();
			mat.createGradientBox(unscaledWidth, unscaledHeight, Math.PI/2);
			
			var i:Number;
			var pt:Point;

			// Background
			for (i = 0; i < _anColors.length; i++) {
				pt = GetSwatchCenter(i);
				graphics.beginGradientFill(GradientType.LINEAR,
						[0xffffff, 0xe5e5e5, 0xd9d9d9],
						[1,1,1],
						[0.2*255, 0.75*255,1*255], mat);
				graphics.drawCircle(pt.x, pt.y, knSwatchDiameter/2-0.5);
				graphics.endFill();
			}
			
			// Stroke
			graphics.lineStyle(1);

			graphics.lineGradientStyle(GradientType.LINEAR, [0xf0f0f0, 0xd2d2d2], [1,1],[0,255], mat);
			var nHorizColOff:Number = knSwatchColDistance/2;
			var nRadius:Number = knSwatchDiameter / 2 -0.5;
			
			var nColTheta:Number = Math.asin(nHorizColOff/nRadius);
			var nVertColOff:Number = Math.sqrt(nRadius*nRadius - nHorizColOff*nHorizColOff);
			
			
			var pt0:Point = GetSwatchCenter(0);
			var pt1:Point = GetSwatchCenter(kcSwatchesInLargeRow);
			var nRowDist:Number = pt0.subtract(pt1).length;
			var nRowTheta:Number = Math.asin(nRowDist/(2*nRadius));
			var nRowLinearTheta:Number = Math.asin(Math.abs(pt0.x - pt1.x) / nRowDist);
			
			for (i = 0; i < _anColors.length; i++) {
				pt = GetSwatchCenter(i);
				if (i == 0) {
					// First point is on a corner
					DrawStroke(i, Math.PI + nRowLinearTheta + nRowTheta, Math.PI/2 - nColTheta); // 0 is right
				} else if (i == (kcSwatchesInLargeRow -1)) {
					// Top right
					DrawStroke(i, Math.PI/2 + nColTheta, - nRowLinearTheta - nRowTheta); // 0 is right
				} else if (i < kcSwatchesInLargeRow) {
					// Top row, middle
					DrawStroke(i, Math.PI/2 + nColTheta, Math.PI/2 - nColTheta); // 0 is right
				} else if (i == kcSwatchesInLargeRow) {
					// Bottom left
					DrawStroke(i, Math.PI + nRowLinearTheta - nRowTheta, 2 * Math.PI -Math.PI/2 + nColTheta);
				} else if (i == (kcSwatchesInChunk -1)) {
					// Bottom right
					DrawStroke(i, 2*Math.PI -nRowLinearTheta + nRowTheta, 2 * Math.PI -Math.PI/2 - nColTheta);
				} else {
					// bottom row
					DrawStroke(i, 2 * Math.PI -Math.PI/2 - nColTheta, 2 * Math.PI -Math.PI/2 + nColTheta);
				}
			}
			
			// Paint pots
			for (i = 0; i < _anColors.length; i++)
				UpdateChildColor(i);
				
			UpdateThumb();
		}
		
		private function OnColorClick(evt:Event): void {
			selectedColorIndex = getChildIndex(evt.target as DisplayObject);
		}
		
		private function CreateChild(i:Number): void {
			var ptCenter:Point = GetSwatchCenter(i);
			var spr:Sprite = new Sprite();
			spr.mouseEnabled = true;
			spr.mouseChildren = false;
			spr.addEventListener(MouseEvent.CLICK, OnColorClick, false, 0, true);
			spr.x = ptCenter.x;
			spr.y = ptCenter.y;
			
			var dobShine:DisplayObject = new _clsShine();
			dobShine.x = dobShine.width / -2;
			dobShine.alpha = 0.5;
			spr.addChild(dobShine);
			
			// outer whine shine
			var flt1:DropShadowFilter = new DropShadowFilter(1, 90, 0xffffff, 1, 1, 1, 1, 3);
			
			// top shadow
			var flt2:DropShadowFilter = new DropShadowFilter(1, 90, 0, 0.25, 2, 2, 1, 3, true);
			
			spr.filters = [flt1, flt2];
			addChild(spr);
		}
		
		private function UpdateChildColor(i:Number): void {
			while (numChildren <= i)
				CreateChild(i);
				
			var clr:Number = _anColors[i];
			var gr:Graphics = (getChildAt(i) as Sprite).graphics;
			gr.clear();
			var mat:Matrix = new Matrix();
			var rcArea:Rectangle = new Rectangle(-knColorDiameter/2, -knColorDiameter/2, knColorDiameter, knColorDiameter);
			mat.createGradientBox(rcArea.width, rcArea.height, Math.PI/2, rcArea.x, rcArea.y);
			
			var nHighlightAlpha:Number = 0.3;
			var clrBottom:Number = RGBColor.RGBtoUint(
					nHighlightAlpha * 255 + (1-nHighlightAlpha) * RGBColor.RedFromUint(clr),
					nHighlightAlpha * 255 + (1-nHighlightAlpha) * RGBColor.GreenFromUint(clr),
					nHighlightAlpha * 255 + (1-nHighlightAlpha) * RGBColor.BlueFromUint(clr));
			
			gr.beginGradientFill(GradientType.LINEAR, [clr, clrBottom], [1,1],[0,255], mat);
			
			gr.drawCircle(rcArea.x + rcArea.width/2, rcArea.y + rcArea.height/2, knColorDiameter/2);
			gr.endFill();
		}
		
		private function DrawStroke(i:Number, nStartRads:Number, nEndRads:Number): void {
			var nRadius:Number = knSwatchDiameter / 2 - 0.5;
			var pt:Point = GetSwatchCenter(i);
			var xOff:Number = nRadius * Math.sin(Math.PI/2+nStartRads);
			var yOff:Number = nRadius * Math.cos(Math.PI/2+nStartRads);
			DrawUtils.arcTo(graphics, pt.x + xOff, pt.y + yOff, nStartRads * 180 / Math.PI, (nEndRads-nStartRads) * 180 / Math.PI, nRadius, nRadius);
		}
	}
}