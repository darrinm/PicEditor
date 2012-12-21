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
	import com.adobe.errors.IllegalStateError;
	import com.adobe.serialization.json.JSON;
	
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.utils.Timer;

	public class PerfLogger
	{
		private static const kstrJsPerfDataAddFunction:String =
			"function (strPerfTiming) { strPerfData = strPerfTiming; }";

		// Send data after 5 sec of inactivity.
		private static const knSendDelayMs:Number = 5000;

		// Map of perf metric name to timing metric. Each metric is an Object
		// with keys nStartTime, nEndTime, and nElapsedTime.
		private var _oPerfTimings:Object = new Object();
		private var _fLogToJSON:Boolean = false;
		private var _tmrSendPerfData:Timer = new Timer(knSendDelayMs, 1);
		private var _fLogDataSend:Boolean = false;

		private static const instance: PerfLogger = new PerfLogger(SingletonLock);

		
		public function PerfLogger(lock:Class) {
			if (lock != SingletonLock) {
				throw new Error("Invalid Singleton access. Use PerfLogger.instance.");
			}
			_tmrSendPerfData.addEventListener(TimerEvent.TIMER,
				WritePerfData);
			_tmrSendPerfData.start();
		}

		public static function AttemptLogPerfTimeStart(name:String, start_time:Number=0): void {
			try {
				if (start_time == 0)
					start_time = new Date().getTime();
				instance.LogPerfTimeStart(name, start_time);
			} catch (err:Error) {}
		}

		public static function AttemptLogPerfTimeEnd(name:String, end_time:Number=0): void {
			try {
				if (end_time == 0)
					end_time = new Date().getTime();
				instance.LogPerfTimeEnd(name, end_time);
			} catch (err:Error) {}
		}

		public static function LogToJson(fLogToJson:Boolean): void {
			try {
				instance.logToJSON = fLogToJson;
			} catch (err:Error) {}
		}

		private function LogPerfTimeStart(name:String, start_time:Number): void {
			_oPerfTimings[name] = {"nStartTime": start_time};
			_tmrSendPerfData.reset();
			_tmrSendPerfData.start();
		}

		private function LogPerfTimeEnd(name:String, end_time:Number): void {
			try {
				_oPerfTimings[name].nEndTime = end_time;
				_oPerfTimings[name].nElapsedTime = end_time -
					_oPerfTimings[name].nStartTime;
			} catch (e:TypeError) {
				throw new IllegalStateError("LogPerfTimeEnd called on metric " +
					name + " before LogPerfTimeStart")
			}
			_tmrSendPerfData.reset();
			_tmrSendPerfData.start();
		}

		public function get logToJSON(): Boolean {
		  return _fLogToJSON;
		}

		public function set logToJSON(fLogToJSON:Boolean): void {
			_fLogToJSON = fLogToJSON;
		}

		private function PerfTimingsIsValid(): Boolean {
			var isEmpty:Boolean = true;
			for (var name:String in _oPerfTimings) {
				isEmpty = false;
				if (!_oPerfTimings[name].hasOwnProperty("nElapsedTime")) {
					return false;
				}
			}
			return !isEmpty;
		}

		private function WritePerfData(evt: TimerEvent): void {
			if (!PerfTimingsIsValid()) {
				return;
			} else if (_fLogDataSend) {
				return;
			}

			if (ExternalInterface.available && _fLogToJSON) {
				ExternalInterface.call(kstrJsPerfDataAddFunction, JSON.encode(_oPerfTimings));
			} else {
				PicnikService.Log(JSON.encode(_oPerfTimings),
					PicnikService.knLogSeverityUserSegment);
			}
			_fLogDataSend = true;
		}
	}
}

/**
 * This is a private class declared outside of the package
 * that is only accessible to classes inside of the PerfLogger.as
 * file.  Because of that, no outside code is able to get a
 * reference to this class to pass to the constructor, which
 * enables us to prevent outside instantiation.
 *
 * http://www.darronschall.com/weblog/2007/11/actionscript-3-singleton-redux.cfm
 */
class SingletonLock
{
} // end class

