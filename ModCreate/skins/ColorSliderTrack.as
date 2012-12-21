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
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.GradientType;
	import flash.display.SpreadMethod;
	import flash.events.IEventDispatcher;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import mx.controls.sliderClasses.Slider;
	import mx.core.UIComponent;
	import mx.events.PropertyChangeEvent;

	public class ColorSliderTrack extends UIComponent
	{
		protected var _clr:Number = 0xff0000;
		private var _nWidth:Number = 190;
		private var _nHeight:Number = 12;
		private var _evtdTrackInfoParent:IEventDispatcher = null;
		
		private static const knLeftThumbPadding:Number = 6;
		private static const knRightThumbPadding:Number = 7;
		
		override public function ColorSliderTrack()
		{
			super();
			
			// outer whine shine
			var flt1:DropShadowFilter = new DropShadowFilter(1, 90, 0xffffff, 1, 1, 1, 1, 3);
			
			// top shadow
			var flt2:DropShadowFilter = new DropShadowFilter(1, 90, 0, 0.4, 1.8, 1.8, 1, 3, true);
			
			filters = [flt2, flt1];
			width = _nWidth;
			height = _nHeight;
		}
		
		private function set color(n:Number): void {
			if (_clr == n) return;
			_clr = n;
			invalidateDisplayList();
		}
		
		public override function parentChanged(p:DisplayObjectContainer):void {
			trace("parent changed: " + p);
			if (p != null) {
				var dob:DisplayObject = p
				while (dob != null && !('trackInfo' in dob))
					dob = dob.parent;
					
				if (dob == null) {
					trace("no track info found");
					return;
				}
				trackInfoParent = dob as IEventDispatcher;
			}
		}
		
		private function set trackInfoParent(evtd:IEventDispatcher): void {
			if (_evtdTrackInfoParent == evtd) return;
			if (_evtdTrackInfoParent != null)
				_evtdTrackInfoParent.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnInfoChange);
			_evtdTrackInfoParent = evtd;
			if (_evtdTrackInfoParent != null)
				_evtdTrackInfoParent.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnInfoChange);
			OnInfoChange();
		}
		
		private function OnInfoChange(evt:PropertyChangeEvent=null): void {
			if (evt && evt.property != 'trackInfo') return;
			if (_evtdTrackInfoParent) {
				var obInfo:Object = _evtdTrackInfoParent['trackInfo'];
				color = Number(obInfo);
			}
		}
		
		override protected function measure():void {
			super.measure();
			measuredWidth = _nWidth;
			measuredHeight = _nHeight;
		}
		
		protected function get minimum(): Number {
			var sldr:Slider = _evtdTrackInfoParent as Slider;
			if (sldr)
				return sldr.minimum;
			return 0;
		}
		
		protected function get maximum(): Number {
			var sldr:Slider = _evtdTrackInfoParent as Slider;
			if (sldr)
				return sldr.maximum;
			return 100;
		}
		
		protected function get cornerRadius(): int {
			return 0; 	// Override in sub-classes
		}
		
		protected function GetGradientColors(): Array {
			return [0]; // Override in sub-classes
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
		
		public override function set width(value:Number):void {
			super.width = value;
		}
		
		protected function GetGradientDirection(): Number {
			return 0;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			graphics.clear();
			
			var mat:Matrix = new Matrix();
			mat.createGradientBox(unscaledWidth, unscaledHeight, GetGradientDirection(), 0, 0);
			var aclr:Array = GetGradientColors();
			var rcBox:Rectangle = new Rectangle(-knLeftThumbPadding, 0, unscaledWidth + knRightThumbPadding + knLeftThumbPadding, unscaledHeight);
			graphics.beginGradientFill(GradientType.LINEAR, aclr, GetGradientAlphas(aclr), GetGradientRatios(aclr), mat, SpreadMethod.PAD);
			if (cornerRadius > 0) {
			 	graphics.drawRoundRect(rcBox.x, rcBox.y, rcBox.width, rcBox.height, cornerRadius * 2, cornerRadius * 2);
			} else {
				graphics.drawRect(rcBox.x, rcBox.y, rcBox.width, rcBox.height);	
			}
			graphics.endFill();
		}
	}
}