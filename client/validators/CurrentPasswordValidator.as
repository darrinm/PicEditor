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
package validators
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
	
	import util.CurrentPasswordDictionary;
	import util.PicnikDict;

	public class CurrentPasswordValidator extends DictValidator
	{
  		override protected function get resourceList(): Array {
  			return super.resourceList.concat(["passwordCorrectError", "passwordIncorrectError"]);
  		}

	    [CollapseWhiteSpace]
		[Inspectable(category="Errors", defaultValue="This is your current password.")]
		public var passwordCorrectError:String;

	    [CollapseWhiteSpace]
		[Inspectable(category="Errors", defaultValue="Incorrect.")]
		public var passwordIncorrectError:String;

		private var _cpdt:CurrentPasswordDictionary = new CurrentPasswordDictionary();

		private var _fEnabled:Boolean = false;
		private var _tmr:Timer;

		public override function get dict(): PicnikDict {
			return _cpdt;
		}
		
		public function resetDictionary(): void {
			StopListeningForDictChange(_cpdt);
			_cpdt = new CurrentPasswordDictionary();
			ListenForDictChange(_cpdt);
			passedDeepValidation = false;
		}
		
		public override function get missingFromDictError(): String {
			return passwordIncorrectError;
		}

		public override function get presentInDictError(): String {
			return passwordCorrectError;
		}
		
		private function DoDeepTrigger(evt:Event=null): void {
			if (_fEnabled) {
				StopTimer();
				OnDeepTrigger(null);
			}
		}
		
		private function StartTimer(): void {
			if (_tmr == null) {
				_tmr = new Timer(1500, 1);
				_tmr.addEventListener(TimerEvent.TIMER, DoDeepTrigger);
			} else {
				_tmr.reset();
			}
			_tmr.start();
		}

		private function StopTimer(): void {
			if (_tmr != null)
				_tmr.stop();
		}
		
		private function OnTriggerKeyDown(evt:KeyboardEvent): void {
			if (KeyboardEvent(evt).keyCode == Keyboard.ENTER)
				DoDeepTrigger(null);
		}
		
		private function OnTriggerChange(evt:Event): void {
			StartTimer();
		}
		
		protected override function addDeepTrigger():void {
			super.addDeepTrigger();
			_fEnabled = true;
			if (actualTrigger) {
				actualTrigger.addEventListener(Event.CHANGE, OnTriggerChange);
				actualTrigger.addEventListener(KeyboardEvent.KEY_DOWN, OnTriggerKeyDown);
			}
		}
		
		protected override function removeDeepTrigger():void {
			super.removeDeepTrigger();
			_fEnabled = false;
			StopTimer();
			if (actualTrigger) {
				actualTrigger.removeEventListener(Event.CHANGE, OnTriggerChange);
				actualTrigger.removeEventListener(KeyboardEvent.KEY_DOWN, OnTriggerKeyDown);
			}
		}
	}
}