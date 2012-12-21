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
package picnik.util {
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.effects.easing.Linear;
	import mx.styles.IStyleClient;
	
	public class Animator extends Timer {
		private const kcmsRate:Number = 10; // 100 FPS
		private var _obTarget:Object;
		private var _strProp:String;
		private var _nStart:Number;
		private var _nEnd:Number;
		private var _fnEasing:Function;
		private var _fSuspendBackgroundProcessing:Boolean;
		private var _fFrameBased:Boolean;
		private var _cmsStart:uint;
		private var _cmsDuration:Number;
		private var _fnOnComplete:Function;
		
		// Animate any numeric property of an object from a start value to an end value
		// over a duration via an easing function.
		// If nStart is NaN the current value of the object's property is used.
		
		public function Animator(obTarget:Object, strProp:String, nStart:Number, nEnd:Number,
				cmsDuration:Number, fnEasing:Function=null, fSuspendBackgroundProcessing:Boolean=false,
				fFrameBased:Boolean=false, fnOnComplete:Function=null) {
			super(kcmsRate, cmsDuration / kcmsRate);
		
			_fnOnComplete = fnOnComplete;	
			if (fnEasing == null)
				fnEasing = Linear.easeNone;
			_obTarget = obTarget;
			_strProp = strProp;
			if (isNaN(nStart))
				_nStart = _strProp in _obTarget ? _obTarget[_strProp] : IStyleClient(_obTarget).getStyle(_strProp);
			else
				_nStart = nStart;
			_nEnd = nEnd;
			_fnEasing = fnEasing;
			_fSuspendBackgroundProcessing = fSuspendBackgroundProcessing;
			_fFrameBased = fFrameBased;
			_cmsDuration = cmsDuration;

			if (_fSuspendBackgroundProcessing)
				UIComponent.suspendBackgroundProcessing();

			if (fFrameBased) {
				_cmsStart = getTimer();
				DisplayObject(Application.application).addEventListener(Event.ENTER_FRAME, OnEnterFrame);				
			} else {
				addEventListener(TimerEvent.TIMER, OnTimer);
				addEventListener(TimerEvent.TIMER_COMPLETE, OnTimerComplete);
				start();
			}
		}
		
		public function Dispose():void {
			// Do nothing if already stopped
			if (_obTarget == null)
				return;

			if (_fFrameBased) {
				DisplayObject(Application.application).removeEventListener(Event.ENTER_FRAME, OnEnterFrame);				
			} else {
				removeEventListener(TimerEvent.TIMER, OnTimer);
				removeEventListener(TimerEvent.TIMER_COMPLETE, OnTimerComplete);
			}
			
			if (_fSuspendBackgroundProcessing)
				UIComponent.resumeBackgroundProcessing();
			_obTarget = null;
			_fnEasing = null;
			
			if (_fnOnComplete != null)
				_fnOnComplete();
		}
			
		private function OnTimer(evt:TimerEvent): void {
			evt.updateAfterEvent();
			
			var n:Number = _fnEasing(currentCount * kcmsRate, _nStart, _nEnd - _nStart, repeatCount * kcmsRate);
			if (_strProp in _obTarget)
				_obTarget[_strProp] = n;
			else
				_obTarget.setStyle(_strProp, n);
		}
				
		private function OnTimerComplete(evt:TimerEvent): void {
			Dispose();
		}
		
		private function OnEnterFrame(evt:Event): void {
			var cmsNow:uint = getTimer();
			
			var n:Number;
			var dms:uint = cmsNow - _cmsStart;
			if (dms >= _cmsDuration)
				n = _nEnd;
			else
				n = _fnEasing(dms, _nStart, _nEnd - _nStart, _cmsDuration);
				
			if (_strProp in _obTarget)
				_obTarget[_strProp] = n;
			else
				_obTarget.setStyle(_strProp, n);
				
			if (dms >= _cmsDuration)
				Dispose();
		}
	}
}
