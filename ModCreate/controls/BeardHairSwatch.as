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
	import de.polygonal.math.PM_PRNG;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import imagine.imageOperations.paintMask.BeardHairBrush;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.controls.Image;
	import mx.core.UIComponent;
	
	import overlays.helpers.RGBColor;
	
	public class BeardHairSwatch extends UIComponent
	{
		[Bindable] public var thickness:Number = 3;
		[Bindable] public var positionJitter:Number = 3;
		[Bindable] public var curve:Number = 5;
		[Bindable] public var colors:Array = null;
		
		private static const kastrWatchParams:Array = ['thickness', 'positionJitter', 'colors', 'curve', 'width', 'height'];
		
		private var _acw:Array = [];
		private var _fSwatchValid:Boolean = true;
		
		public function BeardHairSwatch()
		{
			super();
			for each (var strParam:String in kastrWatchParams)
			_acw.push(ChangeWatcher.watch(this, strParam, InvalidateSwatch));
			
			blur = 1.5;
		}
		
		public override function setActualSize(w:Number, h:Number):void {
			super.setActualSize(w, h);
			InvalidateSwatch();
		} 
		
		private function InvalidateSwatch(evt:Event=null): void {
			_fSwatchValid = false;
			invalidateDisplayList();
		}
		
		private function RandCurve(rnd:PM_PRNG): Number {
			return rnd.nextDoubleRange(-curve, curve);
		}
		
		private function RandPosition(rnd:PM_PRNG): Number {
			return rnd.nextDoubleRange(-positionJitter, positionJitter);
		}
		
		public function set blur(nBlur:Number): void {
			filters = [new BlurFilter(nBlur, nBlur, .5)];
		}
		
		private function DrawSwatch(): void {
			if (colors == null || width < 1 || colors.length < 1)
				return;
			
			// Draw a bunch of diagonal lines using the hair colors.
			// Place them semi-randomly.
			// Go outside the lines semi-randomly.
			
			var rnd:PM_PRNG = new PM_PRNG();
			rnd.seed = 1;
			
			graphics.clear();
			var fStraightPass:Boolean = thickness > 1;
			var nCurvyPasses:Number = thickness - 1;
			var ix:Number;
			var clr:Number;
			if (fStraightPass) {
				for (ix = 2; ix < width-2; ix++) {
					clr = colors[rnd.nextIntRange(0, colors.length-1)];
					graphics.lineStyle(1, clr, 1, false);
					graphics.moveTo(ix, 0);
					graphics.lineTo(ix, height-2);
				}
			}
			for (var iPass:Number = 0; iPass < nCurvyPasses; iPass++) {
				var aobHair:Array = [];
				var obHair:Object;
				for (ix = 0; ix < width; ix++) {
					clr = colors[rnd.nextIntRange(0, colors.length-1)];
					obHair = {clr:clr, lum:RGBColor.LuminosityFromUint(clr)};
					obHair.x1 = ix;
					obHair.x2 = ix + RandCurve(rnd);
					obHair.x3 = ix + RandCurve(rnd);
					obHair.y1 = 0;
					obHair.y2 = height/2 + RandCurve(rnd);
					obHair.y3 = height + RandPosition(rnd);
					aobHair.push(obHair);
				}
				aobHair.sortOn('lum', Array.NUMERIC);
				for each (obHair in aobHair) {
					graphics.lineStyle(1, obHair.clr, 1, false);
					graphics.moveTo(obHair.x1, obHair.y1);
					graphics.curveTo(obHair.x2, obHair.y2, obHair.x3, obHair.y3);
				}
			}
		}
		
		protected override function updateDisplayList(nWidth:Number, nHeight:Number):void {
			super.updateDisplayList(nWidth, nHeight);
			if (!_fSwatchValid) {
				DrawSwatch();
				_fSwatchValid = true;
			}
		}
	}
}