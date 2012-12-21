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
package controls {
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	
	import mx.containers.Canvas;
	import mx.effects.AnimateProperty;
	import mx.effects.Effect;
	import mx.effects.SetPropertyAction;
	import mx.effects.easing.Cubic;
	
	import overlays.helpers.RGBColor;

	[Event(name="select", type="flash.events.Event")]

	public class PosterButtonImage extends Canvas {
		[Bindable] public var effectData:Object = null;
		
		private var _fSelected:Boolean = false;
		private var _fMouseOver:Boolean = false;
		
		private var fnEase:Function = Cubic.easeIn;
		private var knAnimateDuration:Number = 100;
		
		private var _fltCurrent:GlowFilter = null;
		private var _fltFrom:GlowFilter = null;
		private var _fltTo:GlowFilter = null;
		
		public function PosterButtonImage()
		{
			super();
			_fltCurrent = defaultGlow;
			filters = [_fltCurrent];
			
			this.addEventListener(MouseEvent.ROLL_OVER, function(evt:MouseEvent): void {
				mouseover = true;
			});
			this.addEventListener(MouseEvent.ROLL_OUT, function(evt:MouseEvent): void {
				mouseover = false;
			});
			
			this.addEventListener(MouseEvent.CLICK, function(evt:MouseEvent): void {
				dispatchEvent(new Event("select"));
			});
		}
		
		private var _img:ImagePlus;
		
		public function set source(value:Object): void {
			if (_img)
				removeChild(_img);
			_img = new ImagePlus();
			addChild(_img);
			_img.percentWidth = 100;
			_img.percentHeight = 100;
			_img.source = value;
		}
		
		protected function get defaultGlow(): GlowFilter {
			return new GlowFilter(0, .3, 2, 2, 2, 3);
		}
		
		protected function get mouseOverGlow(): GlowFilter {
			return new GlowFilter(0x618430, .7, 5, 5, 2, 3);
		}
		
		protected function get selectedGlow(): GlowFilter {
			return new GlowFilter(0x618430, .8, 8, 8, 2, 3);
		}
		
		public function set selected(f:Boolean): void {
			if (_fSelected == f)
				return;
			_fSelected = f;
			InvalidateState();
		}
		
		public function get selected(): Boolean {
			return _fSelected;
		}
		
		public function set mouseover(f:Boolean): void {
			if (_fMouseOver == f)
				return;
			_fMouseOver = f;
			InvalidateState();
		}
		
		private var _fStateValid:Boolean = true;
		private function InvalidateState(): void {
			_fStateValid = false;
			invalidateProperties();
		}
		
		protected override function commitProperties():void {
			super.commitProperties();
			if (!_fStateValid) {
				_fStateValid = true;
				UpdateState();
			}
		}
		
		private function UpdateState(): void {
			_fltFrom = _fltCurrent.clone() as GlowFilter;
			_fltTo = _fSelected ? selectedGlow : (_fMouseOver ? mouseOverGlow : defaultGlow);
			endEffectsStarted();
			_nAnimationState = 0;
			var efTween:AnimateProperty = new AnimateProperty(this);
			efTween.property = "AnimationState";
			efTween.fromValue = 0;
			efTween.toValue = 1;
			efTween.duration = knAnimateDuration;
			efTween.play();
		}
		
		private var _nAnimationState:Number = 0;
		
		public function get AnimationState(): Number {
			return _nAnimationState;
		}
		
		private function NumTween(ob1:Object, ob2:Object, n:Number): Number {
			return Number(ob1) + (Number(ob2) - Number(ob1)) * n;
		}
		
		public function set AnimationState(n:Number): void {
			_nAnimationState = n;
			n = Math.min(1, Math.max(0, n)); // Clamp between 0 and 1
			for each (var strParam:String in ['alpha', 'color', 'blurX', 'blurY', 'strength', 'quality', 'knockout', 'inner']) {
				var obFromValue:Object = _fltFrom[strParam];
				var obToValue:Object = _fltTo[strParam];
				var obValue:Object;
				if (obFromValue is Boolean) {
					obValue = (n < 0.5) ? obFromValue : obToValue;
				} else if (strParam == 'color') {
					// Color tween
					var nR:Number = NumTween(RGBColor.RedFromUint(Number(obFromValue)), RGBColor.RedFromUint(Number(obToValue)), n);
					var nG:Number = NumTween(RGBColor.GreenFromUint(Number(obFromValue)), RGBColor.GreenFromUint(Number(obToValue)), n);
					var nB:Number = NumTween(RGBColor.BlueFromUint(Number(obFromValue)), RGBColor.BlueFromUint(Number(obToValue)), n);
					obValue = RGBColor.RGBtoUint(nR, nG, nB);
				} else {
					// Number
					obValue = NumTween(obFromValue, obToValue, n);
				}
				_fltCurrent[strParam] = obValue;
			}
			filters = [_fltCurrent];
		}
	}
}
