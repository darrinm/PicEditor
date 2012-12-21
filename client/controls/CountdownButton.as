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
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class CountdownButton extends TipButton
	{
		private var _tmr:Timer = new Timer(1000);
		private var _strLabelBase:String;
		private var _nTime:Number;
		
		public function CountdownButton()
		{
			super();
			enabled = false;
			_tmr.addEventListener(TimerEvent.TIMER, Tick);
			_tmr.delay = 1000; // One second tics
			_nTime = 15; // Default to 15 seconds
			_tmr.repeatCount = _nTime + 1;
			_tmr.start();
		}
		
		protected function Tick(evt:TimerEvent): void {
			_nTime -= 1;
			UpdateLabel();
		}
		
		protected function UpdateLabel(): void {
			var str:String = _strLabelBase.replace('%1', _nTime);
			if (_nTime > 0) {
				enabled = false;
			} else {
				enabled = true;
				// Drop the (15s) from our label
				str = _strLabelBase.replace(/ *\(.*\) */,'');
			}
			super.label = str;
		}
		
		
		
		public override function set label(value:String):void {
			_strLabelBase = value;
			UpdateLabel();
		}
		public override function get label():String {
			return super.label;
		}
		
	}
}