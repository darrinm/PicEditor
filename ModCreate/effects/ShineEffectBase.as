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
package effects {
	import containers.DrawOverlayEffectCanvas;
	import flash.geom.Point;
	import controls.HSliderPlus;
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import mx.controls.Image;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.display.MovieClip;

	// TODO: this code is pretty much identical to BlemishEffectBase. Consolidate.
	
	public class ShineEffectBase extends DrawPointsOverlayEffectCanvas {
		[Bindable] public var _sldrBrushSize:HSliderPlus;
		[Bindable] public var _nFeedbackSecs:Number;
		[Bindable] public var _cxyMinFeedbackDim:Number;
		
		[Embed(source="/assets/swfs/redeye_success.swf")]
		[Bindable] public var _clsSuccessSwf:Class;

		private var _tmrFeedback:Timer = null;
		private var _effect:DisplayObject = null;
		private var _fDirty:Boolean = false;

		protected function HideFeedback(evt:Event = null): void {
			if (_tmrFeedback != null) {
				_tmrFeedback.stop();
				_tmrFeedback.removeEventListener(TimerEvent.TIMER, HideFeedback);
			}
			_tmrFeedback = null;
			if (_effect != null) {
				if (_mcOverlay.contains(_effect)) {
					_mcOverlay.removeChild(_effect);
				}
				_effect = null;
			}
		}
		
		protected function ShowFeedback(clsSwf:Class, rcEffect:Rectangle): void {
			if (_tmrFeedback != null) {
				// We are currently showing an animation. Remove the old one.
				HideFeedback();
			}

			var pt:Point = rcEffect.topLeft;
			_effect = new clsSwf();
			_effect.x = pt.x;
			_effect.y = pt.y;
			_effect.scaleX *= (rcEffect.width / _effect.width);
			_effect.scaleY *= (rcEffect.height / _effect.height);
			_effect.visible = true;

			_mcOverlay.addChild(_effect);
			
			_tmrFeedback = new Timer(0, 1);
			_tmrFeedback.delay = _nFeedbackSecs * 1000;
			_tmrFeedback.addEventListener(TimerEvent.TIMER, HideFeedback);
			_tmrFeedback.start();
		}

		protected function AnimateResult(rcdEffect:Rectangle): void {
			var clsSwf:Class = _clsSuccessSwf;
			var rclEffect:Rectangle = _imgv.RclFromRcd(rcdEffect);
			var cxyEffectDim:Number = Math.max(_cxyMinFeedbackDim, rclEffect.width, rclEffect.height);
			rclEffect.inflate((cxyEffectDim - rclEffect.width) / 2, (cxyEffectDim - rclEffect.height) / 2);
			ShowFeedback(clsSwf, rclEffect);
		}
		
		public override function OnOverlayPress(evt:MouseEvent): Boolean {
			super.OnOverlayPress(evt);
			var iptLast:Number = _aapt.length - 1;
			var apt:Array = _aapt[iptLast];
			var nWidth:Number = Math.round(_sldrBrushSize.value);
			_aapt[iptLast].width = nWidth;
			operation['lines'] = _aapt;
			_fDirty = true;
			OnOpChange();
			AnimateResult(new Rectangle(apt[0].x-nWidth/2, apt[0].y-nWidth/2, nWidth, nWidth));
			return true;
		}
		
		override protected function UpdateBitmapData():void {
			if (_fDirty) {
				_fDirty = false;
				super.UpdateBitmapData();
			}
		}
		
		public override function OnOverlayMouseDrag(): Boolean {
			return true;
		}
	}
}
