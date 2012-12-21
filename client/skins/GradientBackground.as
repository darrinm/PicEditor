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
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.IBitmapDrawable;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import mx.core.EdgeMetrics;
	import mx.skins.halo.HaloBorder;
	import mx.utils.GraphicsUtil;
	
	/**
	 * A normal Halo border with a gradient background.
	 * Styles supported include:
	 *  - gradientFillColors
	 *  - gradientRotation (0 = left to right, 90 (Defualt) = top to bottom, etc
	 *  - gradientFixedSize - Size in pixels of the gradient. Padd the rest. Default is stretch to fill
	 *  - gradientFillAlphas - default is 1,1,1...
	 *  - gradientFillRatios - default is 0-255, spread evenly over the fill colors
	 * Example:
	 *	.tileListGreenGradient
	 *	{
	 *        border-style: solid;
	 *        border-thickness: 0;
	 *        border-skin: ClassReference("skins.GradientBackground");
	 *        gradient-fill-colors: #6F8E31, #607B2A, #526925, #45591C;
	 *        gradient-fill-alphas: 1,0.9,0.9,1;
	 *        gradient-fill-ratios: 0,100,150,255;
	 * 		  gradient-fixed-size: 200;
	 *        gradient-rotation: 90;
	 *    }
	 *
	 */
	public class GradientBackground extends HaloBorder
	{
		public function GradientBackground()
		{
		}
		
		private var _anFillColors:Array;
		private var _anFillAlphas:Array;
		private var _anFillRatios:Array;
		private var _fStylesLoaded:Boolean = false;
		private var _degRotation:Number = 90;
		private var _nFixedSize:Number = 0;
		private var _nTopCornerRadius:Number = 0;
		private var _nBottomCornerRadius:Number = 0;
		
		private var _nBottomBulbDiameter:Number = 0;
		private var _nBottomBulbOffset:Number = 0;
		
		private var _fltDropShadow:DropShadowFilter = null;
		
		// ------------------------------------------------------------------------------------- //
		override public function styleChanged(styleProp:String):void
		{
			_fStylesLoaded = false;
			invalidateDisplayList();
		}
		
		private function LoadStyles():void
		{
			var i:Number = 0;
			
			_anFillColors = getStyle("gradientFillColors") as Array;
			if (!_anFillColors) _anFillColors = [0xFFFFFF, 0xFFFFFF];
			
			var obRotation:Object = getStyle("gradientRotation");
			_degRotation = obRotation != null ? obRotation as Number : 90;
			
			_nFixedSize = getStyle("gradientFixedSize") as Number;
			if (!_nFixedSize) _nFixedSize = 0;   
			
			_nTopCornerRadius = getStyle("cornerRadius") as Number;
			if (!_nTopCornerRadius) _nTopCornerRadius = 0;   
			
			_nBottomCornerRadius = getStyle("bottomCornerRadius") as Number;
			if (!_nBottomCornerRadius) _nBottomCornerRadius = _nTopCornerRadius;
			
			_anFillAlphas = getStyle("gradientFillAlphas") as Array;
			if (!_anFillAlphas) {
				var nAlpha:Number = 1;
				var obBackgroundAlpha:Object = getStyle("backgroundAlpha");
				if (obBackgroundAlpha)
					nAlpha = obBackgroundAlpha as Number;
				_anFillAlphas = [];
				for (i = 0; i < _anFillColors.length; i++) {
					_anFillAlphas[i] = nAlpha;
				}           
			}
			
			_anFillRatios = getStyle("gradientFillRatios") as Array;
			if (!_anFillRatios) {
				var nRatio:Number = 0;
				_anFillRatios = [];
				for (i = 0; i < _anFillColors.length; i++) {
					_anFillRatios[i] = i * 255 / (_anFillColors.length-1) ;
				}
			}
			
			// Clean up our arrays
			if (_anFillAlphas.length > _anFillColors.length) {
				trace("WARNING: Gradient fill alphas longer than gradient fill colors");
				_anFillAlphas.length = _anFillColors.length
			} else if (_anFillColors.length > _anFillAlphas.length) {
				trace("WARNING: Gradient fill alphas shorter than gradient fill colors");
				while (_anFillColors.length > _anFillAlphas.length) {
					_anFillAlphas.push(1);
				}
			}
			
			if (_anFillRatios.length > _anFillColors.length) {
				trace("WARNING: Gradient fill ratios longer than gradient fill colors");
				_anFillRatios.length = _anFillColors.length
			} else if (_anFillColors.length > _anFillRatios.length) {
				trace("WARNING: Gradient fill ratios shorter than gradient fill colors");
				while (_anFillColors.length > _anFillRatios.length) {
					_anFillRatios.push(255);
				}
			}
			
			for (i = 0; i < _anFillColors.length; i++) {
				if (_anFillAlphas[i] < 0) {
					trace("WARNING: Illegal fill alpha: " + _anFillAlphas[i] + ". Must be between 0 and 1, inclusive");
					_anFillAlphas[i] = 0;
				} else if (_anFillAlphas[i] > 1) {
					trace("WARNING: Illegal fill alpha: " + _anFillAlphas[i] + ". Must be between 0 and 1, inclusive");
					_anFillAlphas[i] = 1;
				}
				if (_anFillRatios[i] < 0) {
					trace("WARNING: Illegal fill ratio: " + _anFillRatios[i] + ". Must be between 0 and 255, inclusive");
					_anFillRatios[i] = 0;
				} else if (_anFillRatios[i] > 255) {
					trace("WARNING: Illegal fill ratio: " + _anFillRatios[i] + ". Must be between 0 and 255, inclusive");
					_anFillRatios[i] = 255;
				}
				if (i > 0 && _anFillRatios[i] < _anFillRatios[i-1]) {
					trace("WARNING: Illegal fill ratio: " + _anFillRatios[i] + ". Must be arranged in ascending order");
					_anFillRatios[i] = 255;
				}
			}
			
			var obBulbOffset:Object = getStyle("bottomBulbOffset");
			_nBottomBulbOffset = obBulbOffset != null ? obBulbOffset as Number : 0;
			
			var obBulbDiameter:Object = getStyle("bottomBulbDiameter");
			_nBottomBulbDiameter = obBulbDiameter != null ? obBulbDiameter as Number : 0;
			
			_fltDropShadow = GetDropShadowFilterStyle();
			
			_fStylesLoaded = true;   
		}
		
		private function GetStyleNum(strName:String, nDefault:Number): Number {
			if (getStyle(strName) == null)
				return nDefault;
			return getStyle(strName) as Number;
		}
		
		private var _bmdShadow:BitmapData = null;
		
		private function GetDropShadowFilterStyle(): DropShadowFilter {
			if (GetStyleNum('dropShadowStrength',0) <= 0)
				return null;
			
			var fInner:Boolean = false;
			var fKnockout:Boolean = true;
			var fHide:Boolean = false;
			
			return new DropShadowFilter(
				GetStyleNum('dropShadowDistance', 4),
				GetStyleNum('dropShadowAngle', 45),
				GetStyleNum('dropShadowColor',0),
				GetStyleNum('dropShadowAlpha',1),
				GetStyleNum('dropShadowBlurX',4),
				GetStyleNum('dropShadowBlurY',4),
				GetStyleNum('dropShadowStrength',1),
				GetStyleNum('dropShadowQuality',0),
				fInner, fKnockout, fHide);
		}
		
		private function GetShadowBmd(nWidth:Number, nHeight:Number): BitmapData {
			if (_bmdShadow == null || (_bmdShadow.width != nWidth) || (_bmdShadow.height != nHeight)) {
				if (_bmdShadow != null)
					_bmdShadow.dispose();
				_bmdShadow = new BitmapData(nWidth, nHeight, true, 0);
			} else {
				_bmdShadow.fillRect(_bmdShadow.rect, 0);
			}
			return _bmdShadow;
		}
		
		// ------------------------------------------------------------------------------------- //
		
		private function DrawBackground(g:Graphics, unscaledWidth:Number, unscaledHeight:Number, fBlackOnly:Boolean): void {
			var emBorder:EdgeMetrics = borderMetrics;
			var w:Number = unscaledWidth - emBorder.left - emBorder.right;
			var h:Number = unscaledHeight - emBorder.top - emBorder.bottom;
			
			var nGradWidth:Number = _nFixedSize ? _nFixedSize : w;
			var nGradHeight:Number = _nFixedSize ? _nFixedSize : h;
			
			var mat:Matrix = rotatedGradientMatrix(0,0,nGradWidth,nGradHeight,_degRotation);
			
			if (_degRotation == 270 && _nFixedSize > 0) {
				mat.translate(0, h - _nFixedSize);
			}
			
			var nTopCornerRadius:Number = Math.max(_nTopCornerRadius-2, 0);
			var nBottomCornerRadius:Number = Math.max(_nBottomCornerRadius-2, 0);
			
			if (fBlackOnly)
				g.beginFill(0, 1);
			else
				g.beginGradientFill("linear", _anFillColors, _anFillAlphas, _anFillRatios, mat);
			
			GraphicsUtil.drawRoundRectComplex(g, emBorder.left, emBorder.top, w, h-_nBottomBulbOffset, nTopCornerRadius, nTopCornerRadius, nBottomCornerRadius, nBottomCornerRadius);
			g.endFill();
			if (_nBottomBulbDiameter > 0) {
				if (fBlackOnly)
					g.beginFill(0, 1);
				else
					g.beginGradientFill("linear", _anFillColors, _anFillAlphas, _anFillRatios, mat);
				g.drawCircle(emBorder.left + w/2, emBorder.top + h - _nBottomBulbDiameter/2,_nBottomBulbDiameter/2);
				g.endFill();
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var emBorder:EdgeMetrics = borderMetrics;
			if (!_fStylesLoaded) LoadStyles();
			
			graphics.clear();
			
			if (_fltDropShadow && (unscaledWidth > 0) && (unscaledHeight > 0)) {
				var spr:Sprite = new Sprite();
				spr.filters = [_fltDropShadow];
				DrawBackground(spr.graphics, unscaledWidth, unscaledHeight, true);
				var nPadding:Number = Math.max(_fltDropShadow.blurX, _fltDropShadow.blurY) + _fltDropShadow.quality + _fltDropShadow.distance;
				var bmd:BitmapData = GetShadowBmd(unscaledWidth + 2 * nPadding, unscaledHeight + 2 * nPadding);
				var mat:Matrix = new Matrix();
				mat.translate(nPadding, nPadding);
				bmd.draw(spr, mat);
				mat = new Matrix();
				mat.translate(-nPadding, -nPadding);
				graphics.beginBitmapFill(bmd, mat, false, false);
				graphics.drawRect(-nPadding, -nPadding, bmd.width, bmd.height);
				graphics.endFill();
			}
			DrawBackground(graphics, unscaledWidth, unscaledHeight, false);
		}
	}
}

