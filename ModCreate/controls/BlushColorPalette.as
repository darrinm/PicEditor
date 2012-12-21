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
	
	import util.BlendModeMath;

	[Event(name="change", type="flash.events.Event")]

	public class BlushColorPalette extends UIComponent
	{
		private var _nSelectedColorIndex:Number = 0;
		
		private var _sprThumb:Sprite = null;
		private static const knThumbDiameter:Number = 6.5;
		private static const knThumbHoleDiameter:Number = 4.5;

		private var _nNumSwatches:Number = 5;

		private static const knTotalWidth:Number = 190;
		private static const knTotalHeight:Number = 67;

		private static const knOutsidePadding:Number = 5;
		private static const knHorizontalGap:Number = 4;
		
		private static const knOuterCornerRadius:Number = 9;
		private static const knSwatchCornerRadius:Number = 8.5;
		
		private var _fWet:Boolean = false;
		
		private var _sprBackground:Sprite;
		private var _sprMask:Sprite;

		private var _fSelected:Boolean = false;

		private var _asprColors:Array = [];
		
		[Bindable] public var color:Number = 0xfbbeaa;
		private var _anColors:Array = [];
		
		private var _anSwatchWidths:Array = null;

		public function BlushColorPalette()
		{
			super();
			colors = [0xfbbeaa, 0xffc0d0, 0xe7a0ae, 0xd05167, 0x88424b];
			filters = [new DropShadowFilter(1, -90, 0, 0.2, 3, 3, 1, 3, true)];
			CreateBackground();
		}
		
		private function CreateBackground(): void {
			_sprBackground = new Sprite();
			_sprMask = new Sprite();
			
			
			_sprBackground.mask = _sprMask;
			_sprBackground.addChild(_sprMask);
			addChild(_sprBackground);
			
			DrawBackground(knTotalWidth, knTotalHeight);
		}
		
		private function DrawBackground(nWidth:Number, nHeight:Number): void {
			// Draw the background
			var gr:Graphics = _sprBackground.graphics;
			gr.clear();
			var mat:Matrix = new Matrix();
			mat.createGradientBox(nWidth, nHeight, Math.PI/2);
			
			// Background, stroke
			gr.lineStyle(1);
			gr.lineGradientStyle(GradientType.LINEAR, [0xf0f0f0, 0xc8c8c8], [1,1],[0,255], mat);
			gr.beginGradientFill(GradientType.LINEAR,
					[0xffffff, 0xe5e5e5, 0xd9d9d9],
					[1,1,1],
					[0.2*255, 0.75*255,1*255], mat);
			gr.drawRoundRect(0, 0, nWidth, nHeight-0.5, knOuterCornerRadius*2, knOuterCornerRadius*2);
			gr.endFill();
			
			// Update the mask
			gr = _sprMask.graphics;
			gr.clear();
			gr.beginFill(0, 1);
			gr.drawRect(0, 0, nWidth, nHeight);
			gr.endFill();
		}
		
		public function set numSwatches(n:Number): void {
			if (_nNumSwatches == n)
				return;
			
			for each(var spr:Sprite in _asprColors) {
				removeChild(spr);
				spr.removeEventListener(MouseEvent.CLICK, OnColorClick, false);
			}
			
			_asprColors = [];
			_anSwatchWidths = null;
			_nNumSwatches = n;
			if (selectedColorIndex >= _nNumSwatches) {
				selectedColorIndex = _nNumSwatches - 1;
			}
			invalidateDisplayList();
		}
		
		public function set colors(anColors:Array): void {
			_anColors = anColors;
			numSwatches = anColors.length;
			invalidateDisplayList();
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function set wet(f:Boolean): void {
			if (_fWet == f) return;
			_fWet = f;
			invalidateDisplayList();
		}
		
		[Bindable (event="change")]
		public function set selectedColorIndex(n:Number): void {
			color = _anColors[n];
			
			var nPrevSelected:Number = _nSelectedColorIndex;
			_nSelectedColorIndex = n;
			if (numChildren > 0) {
				UpdateThumb();
				if (nPrevSelected >= 0 && nPrevSelected < _anColors.length)
					UpdateChildColor(nPrevSelected)
				dispatchEvent(new Event(Event.CHANGE));
			}
		}
		
		public function get selectedColorIndex(): Number {
			return _nSelectedColorIndex;
		}
		
		public function set selected(fSelected:Boolean): void {
			_fSelected = fSelected;
			Reset();
		}
		
		public function Reset(): void {
			selectedColorIndex = 0;
		}
		
		private function UpdateThumb(): void {
			if (numChildren == 0) return;
			if (_sprThumb == null) {
				_sprThumb = new Sprite();
				_sprThumb.filters = [new DropShadowFilter(1, 90, 0.0, 0.35, 5, 5)];
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
			measuredWidth = knTotalWidth;
			measuredHeight = knTotalHeight;
		}
		
		private function get swatchWidths(): Array {
			if (_anSwatchWidths == null) {
				var nSwatchSpace:Number = knTotalWidth - (_nNumSwatches-1) * knHorizontalGap - knOutsidePadding * 2;
				var nAverageWidth:Number = nSwatchSpace / _nNumSwatches;
				// Average width might not be whole
				
				_anSwatchWidths = [];
				var nRemainder:Number = 0;
				for (var i:Number = 0; i < _nNumSwatches; i++) {
					var nWidth:Number = nAverageWidth + nRemainder;
					var nRoundWidth:Number = Math.round(nWidth);
					nRemainder = nWidth - nRoundWidth;
					_anSwatchWidths.push(nRoundWidth);
				}
			}
			return _anSwatchWidths;
		}
		
		private function GetSwatchCenter(i:Number): Point {
			var xPos:Number = knOutsidePadding;
			for (var iCol:Number = 0; iCol < i; iCol++)
				xPos += swatchWidths[iCol] + knHorizontalGap;
			xPos += swatchWidths[i] / 2;
			return new Point(xPos, knTotalHeight / 2);
		}
		
		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			// Paint pots
			var i:Number;
			for (i = 0; i < _anColors.length; i++)
				UpdateChildColor(i);
				
			UpdateThumb();
		}
		
		private function getColorIndex(dob:DisplayObject): Number {
			for (var i:Number = 0; i < numColorSprites; i++)
				if (getColorSprite(i) == dob)
					return i;
			
			return -1;
		}
		
		private function OnColorClick(evt:Event): void {
			selectedColorIndex = getColorIndex(evt.target as DisplayObject);
		}
		
		private function CreateChild(i:Number): void {
			var ptCenter:Point = GetSwatchCenter(i);
			var spr:Sprite = new Sprite();
			spr.addEventListener(MouseEvent.CLICK, OnColorClick, false, 0, true);
			spr.x = ptCenter.x;
			spr.y = ptCenter.y;
			
			// outer whine shine
			var flt1:DropShadowFilter = new DropShadowFilter(1, 90, 0xffffff, 1, 1, 1, 1, 3);
			
			// top shadow
			var flt2:DropShadowFilter = new DropShadowFilter(1, 90, 0, 0.37, 2, 2, 1, 3, true);
			
			spr.filters = [flt1, flt2];
			spr.filters = [flt2, flt1];
			addChild(spr);
			_asprColors.push(spr);
		}
		
		private function get numColorSprites(): Number {
			return _asprColors.length;
		}
		
		private function getColorSprite(i:Number): Sprite {
			return _asprColors[i] as Sprite;
		}
		
		private function UpdateChildColor(i:Number): void {
			while (numColorSprites <= i)
				CreateChild(i);
				
			var clr:Number = _anColors[i];
			var gr:Graphics = getColorSprite(i).graphics;
			gr.clear();
			var mat:Matrix = new Matrix();
			var nWidth:Number = swatchWidths[i];
			var nHeight:Number = knTotalHeight - 2*knOutsidePadding;
			
			var rcArea:Rectangle = new Rectangle(-nWidth/2, -nHeight/2, nWidth, nHeight);
			mat.createGradientBox(rcArea.width, rcArea.height, Math.PI/2, rcArea.x, rcArea.y);
			
			var nHighlightAlpha:Number = 0.42;
			
			var clrBottom:Number = RGBColor.RGBtoUint(
					nHighlightAlpha * BlendModeMath.Screen(255, RGBColor.RedFromUint(clr)) + (1-nHighlightAlpha) * RGBColor.RedFromUint(clr),
					nHighlightAlpha * BlendModeMath.Screen(255, RGBColor.GreenFromUint(clr)) + (1-nHighlightAlpha) * RGBColor.GreenFromUint(clr),
					nHighlightAlpha * BlendModeMath.Screen(255, RGBColor.BlueFromUint(clr)) + (1-nHighlightAlpha) * RGBColor.BlueFromUint(clr));
			
			gr.beginGradientFill(GradientType.LINEAR, [clr, clrBottom], [1,1],[0,255], mat);
			gr.drawRoundRect(rcArea.x, rcArea.y, rcArea.width, rcArea.height, knSwatchCornerRadius*2, knSwatchCornerRadius*2);
			gr.endFill();
			
			if (_fWet) {
				rcArea.left += 3;
				rcArea.right -= 3;
				rcArea.y += 3;
				rcArea.height = 27;
				mat.createGradientBox(rcArea.width, rcArea.height, Math.PI/2, rcArea.x, rcArea.y);
				gr.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xffffff], [0.32, 0], [0, 255], mat);
				gr.drawRoundRectComplex(rcArea.x, rcArea.y, rcArea.width, rcArea.height, knSwatchCornerRadius - 2.5, knSwatchCornerRadius - 2.5, 0, 0);
				gr.endFill();
			}
		}
	}
}