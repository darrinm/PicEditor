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
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.core.UIComponent;
	
	import util.svg.PathSegmentsCollection;

	public class SVGShape extends UIComponent
	{
		private var _acw:Array = [];
		
		private var _fPathValid:Boolean = false;
		private var _psg:PathSegmentsCollection;
		private var _strPath:String = null;
		
		// Changing these require a redraw and a measure
		[Bindable] public var shapeMaxWidth:Number = 100;
		[Bindable] public var shapeMaxHeight:Number = 100;
		
		// Changing these require a redraw
		[Bindable] public var strokeColor:Number = 0;
		[Bindable] public var strokeAlpha:Number = 1;
		[Bindable] public var strokeThickness:Number = 0;
		
		[Bindable] public var fillColors:Array = [0];
		[Bindable] public var fillAlphas:Array = [1];
		[Bindable] public var fillRatios:Array = [0];
		[Bindable] public var gradientRotationDegs:Number = 90;
		
		private static const kastrSizeModifierFields:Array =
			['svgPath', 'shapeMaxWidth', 'shapeMaxHeight'];
		
		private static const kastrPathModifierFields:Array =
			['svgPath', 'shapeMaxWidth', 'shapeMaxHeight', 'strokeColor',
			 'strokeAlpha', 'strokeThickness', 'fillColors', 'fillAlphas',
			 'fillRatios', 'gradientRotationDegs'];
		
		public function SVGShape()
		{
			super();
			_psg = new PathSegmentsCollection(null);
			
			var strField:String;
			for each (strField in kastrPathModifierFields)
				_acw.push(ChangeWatcher.watch(this, strField, invalidatePath));
			for each (strField in kastrSizeModifierFields)
				_acw.push(ChangeWatcher.watch(this, strField, _invalidateSize));
		}
		
		private function get hasFill(): Boolean {
			for each (var nFillAlpha:Number in fillAlphas)
				if (nFillAlpha > 0)
					return true;
			return false;
		}
		
		private function get hasStroke(): Boolean {
			return (strokeThickness > 0) && (strokeAlpha > 0);
		}
		
		public function set fillColor(n:Number): void {
			fillColors = [n];
			fillRatios = [0];
		}
		
		public function set fillAlpha(n:Number): void {
			fillAlphas = [n];
		}
		
		private function CleanData(): void {
			if (fillRatios.length > fillColors.length)
				throw new Error("More fill ratios than fill colors");
			if (fillRatios.length < fillColors.length)
				throw new Error("Fewer fill ratios than fill colors");
				
			if (fillAlphas.length > fillColors.length)
				throw new Error("More fill alphas than fill colors");
			if (fillAlphas.length < fillColors.length)
				throw new Error("Fewer fill alphas than fill colors");
		}
		
		private function SetUpFillAndStroke(rcBounds:Rectangle): void {
			CleanData();
			graphics.clear();
			if (hasFill) {
				if (fillColors.length > 1) {
					// Gradient fill
					var mat:Matrix = new Matrix();
					mat.createGradientBox(rcBounds.width, rcBounds.height, gradientRotationDegs * Math.PI / 180, rcBounds.x, rcBounds.y);
					graphics.beginGradientFill(GradientType.LINEAR, fillColors, fillAlphas, fillRatios, mat);
				} else {
					graphics.beginFill(fillColors[0], fillAlphas[0]);
				}
			}
			if (hasStroke) {
				graphics.lineStyle(strokeThickness, strokeColor, strokeAlpha);
			}
		}
		
		private function EndFillAndStroke(): void {
			if (hasFill)
				graphics.endFill();
		}
		
		private function _invalidateSize(evt:Event=null): void {
			invalidateSize();
		}
		
		[Bindable]
		public function set svgPath(str:String): void {
			if (_strPath == str)
				return;
			_strPath = str;
			_psg = new PathSegmentsCollection(_strPath);
			invalidatePath();
			invalidateSize();
		}
		
		public function get svgPath(): String {
			return _strPath;
		}
		
		protected function GetScaleFactor(rcNative:Rectangle): Number {
			if ((rcNative.width <= 0) || (rcNative.height <= 0))
				return 1;
			return Math.min(shapeMaxWidth / rcNative.width, shapeMaxHeight / rcNative.height);
		}
		
		protected function GetScaledBounds(): Rectangle {
			var rcBounds:Rectangle = _psg.getBounds();
			if (rcBounds.width == 0 || rcBounds.height == 0)
				return new Rectangle(0, 0, 1, 1);
			
			var nScale:Number = GetScaleFactor(rcBounds);
			return new Rectangle(0, 0, rcBounds.width * nScale, rcBounds.height * nScale);
		}
		
		protected override function measure():void {
			var rcBounds:Rectangle = GetScaledBounds();
			measuredWidth = rcBounds.width;
			measuredHeight = rcBounds.height;
		}
		
		private function invalidatePath(evt:Event=null): void {
			_fPathValid = false;
			invalidateDisplayList();
		}
		
		private function RedrawPath(): void {
			graphics.clear();
			if (_psg.data.length > 0) {
				var rcBounds:Rectangle = GetScaledBounds();
				SetUpFillAndStroke(rcBounds);
				_psg.generateGraphicsPathInBox(graphics, rcBounds);
				EndFillAndStroke();
			}
		}
		
		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (!_fPathValid)
				RedrawPath();
		}
		
	}
}