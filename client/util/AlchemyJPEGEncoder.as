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
package util {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	
	import mx.core.Application;
	
	// Events:
	// Event.INIT
	// ProgressEvent.PROGRESS
	// Event.COMPLETE
	
	public class AlchemyJPEGEncoder extends EventDispatcher {
		public static const UNINITIALIZED:String = "uninitialized";
		public static const LOADING:String= "loading";
		public static const READY:String = "ready";
		public static const ENCODING:String = "encoding";
		public static const ABORTING:String= "aborting";
		public static const LOAD_FAILED:String = "load_failed";
		//public static const DISABLED:String = "disabled";
		
		[Bindable] public var status:String = UNINITIALIZED;
		[Bindable] public var data:ByteArray;
		
		static private var s_inst:AlchemyJPEGEncoder;
		private var _obPending:Object;
		
		static public function GetInstance(): AlchemyJPEGEncoder {
			if (s_inst == null)
				s_inst = new AlchemyJPEGEncoder();
			return s_inst;
		}
		
		public function AlchemyJPEGEncoder() {
			var fnOnAlchemyLoaded:Function = function (fSuccess:Boolean): void {
				status = fSuccess ? READY : LOAD_FAILED;
				dispatchEvent(new Event(Event.INIT));
				
				if (fSuccess && _obPending) {
					_Encode(_obPending);
					_obPending = null;
				}
			}
			status = LOADING;
			AlchemyLib.inst.Load(fnOnAlchemyLoaded);
		}
		
		// Abort any in-progress and pending encoding
		public function Abort(): void {
			if (status == ENCODING)
				status = ABORTING;
			
			// Alchemy seems to hang on to ByteArrays that it produces. We can at least shrink them.
			if (data) {
				data.length = 0;
				data = null;
			}
		}
		
		// This is an async function which will abort any in-progress encoding
		public function Encode(ba:ByteArray, cx:int, cy:int, nQuality:int,
				aobSegments:Array, nChromaSampling:int, fAsync:Boolean=true): ByteArray {
			if (status != LOADING && status != READY && status != ENCODING && status != ABORTING)
				throw new Error("AlchemyJPEGEncoder can't Encode while status is " + status);
			
			try {
				Abort();
				
				var obParams:Object = {
					ba: ba, cx: cx, cy: cy, nQuality: nQuality,
					aobSegments: aobSegments, nChromaSampling: nChromaSampling,
					fAsync: fAsync
				}
				
				if (status == ABORTING || status == LOADING) {
					_obPending = obParams;
				} else {
					return _Encode(obParams);
				}
			} catch (err:Error) {
				status = READY;
				throw err;
			}
			return null;
		}
		
		private function _Encode(ob:Object): ByteArray {
			status = ENCODING;
			var baJPEG:ByteArray = AlchemyLib.JPEGEncode(ob.ba, ob.cx, ob.cy, ob.nQuality, ob.aobSegments,
					ob.nChromaSampling, ob.fAsync ? OnEncoderCallback : null);
			ob.ba.length = 0; // Try to reduce memory consumption
			if (!ob.fAsync)
				status = READY;
			return baJPEG;
		}
		
		private function OnEncoderCallback(nPercent:int, baData:ByteArray): Boolean {
			if (status == ABORTING) {
				dispatchEvent(new Event(Event.COMPLETE));
				
				// Let JPEGEncode return before kicking off any pending new encode operation.
				if (_obPending) {
					status = ENCODING;
					Application.application.callLater(_Encode, [ _obPending ]);
					_obPending = null;
				} else {
					status = READY;
				}
				
				// Don't continue encoding
				return false;
			}
			
			if (nPercent == -1) {			// Prior encoding Aborted
				data = null;
			} else if (nPercent == 100) {	// Encoding complete
				data = baData;
				status = READY;
				dispatchEvent(new Event(Event.COMPLETE));
			} else {						// Encoding in progress
				dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, nPercent, 100));
			}
				
			// Continue encoding
			return true;
		}
	}
}
