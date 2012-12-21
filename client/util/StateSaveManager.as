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
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class StateSaveManager
	{
		private var _fEnabled:Boolean = false;
		private var _fPrevManualSerializationMode:Boolean;
		private var _fStateChanged:Boolean = false;
		private var _tmrSave:Timer = null;
		
		private static var _ssmInstance:StateSaveManager = new StateSaveManager();
		
		// When something changes, wait a bit in case other things change.
		// Wait this long after the last change before saving state 
		private static const kmsSaveDelay:Number = 3000;
		
		public static function Enable(): void {
			_ssmInstance._Enable();
		}
		
		public static function Disable(): void {
			_ssmInstance._Disable();
		}
		
		public static function SomethingChanged(): void {
			_ssmInstance._SomethingChanged();
		}
		
		public function StateSaveManager()
		{
			_tmrSave = new Timer(kmsSaveDelay,1);
			_tmrSave.addEventListener(TimerEvent.TIMER, SaveStateIfChanged);
		}
		
		private function _Enable(): void {
			if (_fEnabled)
				return;
			_fPrevManualSerializationMode = PicnikBase.app.inManualSerializationMode;
			PicnikBase.app.inManualSerializationMode = true;
			
			_fEnabled = true;
		}
		
		private function SaveStateIfChanged(evt:Event=null): void {
			if (_fStateChanged) {
				_fStateChanged = false;
				// trace("save state");
				PicnikBase.app.SaveApplicationState(true);
			}
		}
		
		private function _Disable(): void {
			if (!_fEnabled)
				return;
			SaveStateIfChanged();
			PicnikBase.app.inManualSerializationMode = _fPrevManualSerializationMode;
			_fEnabled = false;
		}
		
		private function _SomethingChanged(): void {
			// trace("something changed");
			if (!_fEnabled)
				return;
			_fStateChanged = true;
			_tmrSave.stop(); // Stop
			_tmrSave.start(); // Start over
		}
		
	}
}