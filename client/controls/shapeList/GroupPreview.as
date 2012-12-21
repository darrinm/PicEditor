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
package controls.shapeList
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.containers.Canvas;
	import mx.effects.Fade;
	import mx.effects.easing.Sine;
	import mx.events.EffectEvent;

	public class GroupPreview extends Canvas
	{
		private var _nState:Number = 0;
		
		// States
		private static const knInitial:Number = 0;
		private static const knDelay:Number = 1;
		private static const knTransition:Number = 2;
		private static const knAnimate:Number = 3;
		
		private var _fStarted:Boolean = false;
		private var _fTransitionOnLoad:Boolean = false;
		
		private var _ris:RotatingImageStack = null;
		
		private var _obPreviewUrls:Object = [];
		private var _imgs:ImageSlice = null;
		private var _tmrDelay:Timer = new Timer(fadeDuration);

		private var _effFadeAnimation:Fade;
		private var _effFadeThumb:Fade;
		
		public var extraUrls:String = null;
		
		public var delay:Number = 300;
		public var fadeDuration:Number = 300;
		public var easingFunction:Function = Sine.easeInOut;
		
		private var _tmrExtra:Timer = new Timer(30000);
		private var _risExtra:RotatingImageStack = null;
		
		public function GroupPreview()
		{
			super();
			_imgs = new ImageSlice();
			addChild(_imgs);
			_imgs.percentWidth = 100;
			_imgs.percentHeight = 100;
			_imgs.cornerRadius = 5;
			_tmrDelay.addEventListener(TimerEvent.TIMER, OnDelayTimer);
			_tmrExtra.addEventListener(TimerEvent.TIMER, OnExtraTimer);

			_effFadeAnimation = new Fade();
			_effFadeAnimation.addEventListener(EffectEvent.EFFECT_END, OnFadeEnd);
			_effFadeThumb = new Fade(_imgs);
		}
		
		public function set source(ob:Object): void {
			_imgs.source = ob;
		}
		
		private function OnFadeEnd(evt:EffectEvent): void {
			if (_fStarted) {
				// Next state is play the animation
				state = knAnimate;
				_ris.play();
			} else {
				// Ending. Next state is init
				state = knInitial;
			}
		}
		
		private function set state(n:Number): void {
			_nState = n;
		}
		
		private function LoadPreviewImages(): void {
			_ris = new RotatingImageStack();
			_ris.urls = _obPreviewUrls;
			_ris.alpha = 0;
			PositionRIS(_ris);
			addChild(_ris);
			_effFadeAnimation.target = _ris;
			_ris.addEventListener(Event.COMPLETE, OnPreviewsLoaded);
		}
		
		private function OnPreviewsLoaded(evt:Event): void {
			if (_fStarted && _fTransitionOnLoad) {
				FadePreviews(1);
			}
		}
		
		private function FadePreviews(nPreviewAlphaTo:Number): void {
			_ris.pause();
			// var nPreviewAlphaFrom:Number = _ris.alpha;
			var nPreviewAlphaFrom:Number = 1 - nPreviewAlphaTo;
			if (_effFadeAnimation.isPlaying) {
				_effFadeAnimation.reverse();
				_effFadeThumb.reverse();
			} else {
				_effFadeAnimation.alphaFrom = nPreviewAlphaFrom;
				_effFadeAnimation.alphaTo = nPreviewAlphaTo;
				_effFadeAnimation.duration = fadeDuration;
				_effFadeAnimation.easingFunction = easingFunction;
				
				_effFadeThumb.alphaFrom = 1 - nPreviewAlphaFrom;
				_effFadeThumb.alphaTo = 1 - nPreviewAlphaTo;
				_effFadeThumb.duration = fadeDuration;
				_effFadeThumb.easingFunction = easingFunction;
				
				_effFadeThumb.play();
				_effFadeAnimation.play();
			}
			state = knTransition;
		}
		
		public function set previewUrls(ob:Object): void {
			_obPreviewUrls = ob;
			if (_ris) _ris.urls = ob;
		}
		
		private function TransitionToPreviews(): void {
			_ris.resetPosition();
			FadePreviews(1);
		}
		
		private function OnDelayTimer(evt:TimerEvent): void {
			if (!_fStarted) return; // Make sure we are still going
			if (_ris.loaded) {
				TransitionToPreviews();
			} else {
				_fTransitionOnLoad = true;
			}
			_tmrDelay.stop();
		}

		private function PositionRIS(ris:RotatingImageStack): void {
			if (ris.width == 0) {
				ris.width = width;
				ris.height = height;
			}
			if (ris.width == 0) return;
			ris.x = Math.round((width - ris.width)/2);
			ris.y = Math.round((height - ris.height)/2);
		}
		
		private function OnExtraTimer(evt:Event): void {
			_tmrExtra.stop();
			if (!_fStarted || extraUrls == null) return;
			if (_risExtra == null) {
				_risExtra = new RotatingImageStack();
				_risExtra.transitionDelay = 130;
				_risExtra.transitionDuration = 70;
				_risExtra.urls = extraUrls;
				PositionRIS(_risExtra);
				addChild(_risExtra);
			}

			var fnPlay:Function = function(evt:Event=null): void {
				if (!_fStarted) return;
				if (_ris) _ris.alpha = 0;
				_risExtra.alpha = 1;
				_risExtra.play();
			}
			
			if (_risExtra.initialized) {
				fnPlay();
			} else {
				_risExtra.addEventListener(Event.COMPLETE, fnPlay);
			}
		}
		
		public function start(): void {
			if (_fStarted) return;
			_fStarted = true;
			
			_tmrExtra.start();
			
			// Check our current state
			if (_nState == knInitial) {
				state = knDelay;
				// Start the delay timer and load the preview bits
				_fTransitionOnLoad = false;
				if (_ris == null) LoadPreviewImages();
				_tmrDelay.reset();
				_tmrDelay.delay = delay;
				_tmrDelay.repeatCount = 2;
				_tmrDelay.start();
			} else if (_nState == knTransition) {
				// Reverse the transition
				FadePreviews(1);
			} else {
				throw new Error("Unexpected state. Was in state " + _nState + " while stopped");
			}
		}
		
		public function stop(): void {
			if (!_fStarted) return;
			if (_risExtra) _risExtra.alpha = 0; // Make sure these aren't showing
			if (_risExtra) _risExtra.pause();
			_fStarted = false;
			_tmrExtra.stop();
			// Stop the animation, fade back to the thumb, then reset the animation
			if (_nState == knDelay) {
				_tmrDelay.stop();
				_fTransitionOnLoad = false;
				state = knInitial;
			} else if (_nState == knTransition || _nState == knAnimate) {
				FadePreviews(0);
			} else {
				throw new Error("Unexpected state. Was in state " + _nState + " while started");
			}
		}
	}
}