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
package util
{
	/** VariableTimer
	 * This class lets you specify an array of delays for a timer
	 * The delays are specified in seconds
	 * The last delay is repeated until the timer is stopped.
	 */
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class VariableTimer extends Timer
	{
		private var _anDelaySeconds:Array = [];
		
		public function VariableTimer(anDelaySeconds:Array, repeatCount:int=0)
		{
			super(1000, repeatCount);
			delaySeconds = anDelaySeconds;
			addEventListener(TimerEvent.TIMER, OnTimer);
		}
		
		public override function set delay(value:Number):void {
			throw new Error("Set delaySeconds on VariableTimer instead of delay");
		}
		
		public function set delaySeconds(anDelaySeconds:Array): void {
			_anDelaySeconds = anDelaySeconds;
			super.delay = anDelaySeconds.shift() * 1000;
		}
		
		private function OnTimer(evt:Event): void {
			if (_anDelaySeconds.length > 0)
				super.delay = _anDelaySeconds.shift() * 1000;
		}
	}
}