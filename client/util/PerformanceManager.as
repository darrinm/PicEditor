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
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;

	[Event(name="change", type="flash.events.Event")]
	
	public class PerformanceManager extends EventDispatcher
	{
		private var _fIsSlow:Boolean = false;
		
		private static var _pm:PerformanceManager = new PerformanceManager();
		
		private static const kaobLimits:Array = [
			{nTimeLimit:3000, nCount:1, nTimeBetweenOps:Number.MAX_VALUE},
			{nTimeLimit:2000, nCount:3, nTimeBetweenOps:Number.MAX_VALUE},
			{nTimeLimit:1500, nCount:3, nTimeBetweenOps:600},
			{nTimeLimit:750, nCount:5, nTimeBetweenOps:10000}
		];

		private static var _nTimesToKeep:Number = NaN;

		private var _aobLog:Array = [];

		[Bindable]
		public function set isSlow(f:Boolean): void {
			if (_fIsSlow == f) return;
			_fIsSlow = f;
			dispatchEvent(new Event("change"));
		}
		public function get isSlow(): Boolean {
			return _fIsSlow;
		}
		
		public static function Inst(): PerformanceManager {
			return _pm;
		}
		
		private static function get timesToKeep():Number {
			if (isNaN(_nTimesToKeep)) {
				_nTimesToKeep = 0;
				for each (var obLimits:Object in kaobLimits)
					_nTimesToKeep = Math.max(_nTimesToKeep, obLimits.nCount * 2);
			}
			return _nTimesToKeep;
		}
		
		public static function OnImageOperationDo(nTime:Number): void {
			Inst()._OnImageOperationDo(nTime);
		}
		
		public static function Reset(): void {
			Inst()._Reset();
		}
		
		private function _Reset(): void {
			_aobLog = [];
			isSlow = false;
		}
		
		private function UpdateIsSlow(): void {
			if (_aobLog.length == 0) return;
			for each (var obLimits:Object in kaobLimits) {
				var iStartFrame:Number = _aobLog.length-1;
				var nTimeBetweenOps:Number = 0;
				while (iStartFrame > 0) {
					nTimeBetweenOps -= _aobLog[iStartFrame].nStartTime - _aobLog[iStartFrame-1].nStartTime - _aobLog[iStartFrame-1].nDuration;
					if (nTimeBetweenOps > obLimits.nTimeBetweenOps)
						break;
					iStartFrame--;
				}
				
				// We have one or more frames to consider
				var nCountSeen:Number = 0;
				while (iStartFrame < _aobLog.length) {
					if (_aobLog[iStartFrame].nDuration >= obLimits.nTimeLimit)
						nCountSeen++;
					iStartFrame++;
				}
				if (nCountSeen >= obLimits.nCount) {
					trace("Hit slow warning limit: " + obLimits.nTimeLimit);
					isSlow = true;
					return;
				}
			}
		}
		
		private function _OnImageOperationDo(nTime:Number): void {
			if (isSlow) return;
			_aobLog.push({nDuration:nTime, nStartTime:new Date().time - nTime});
			if (_aobLog.length > timesToKeep) _aobLog.shift();
			UpdateIsSlow();
		}
		
		public function PerformanceManager(target:IEventDispatcher=null)
		{
			super(target);
		}
		
	}
}