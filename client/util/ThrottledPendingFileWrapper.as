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
	import imagine.documentObjects.DocumentStatus;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;

	/** PendingFileWrapper
	 * This class is a wrapper for IPendingFile for cases where the file is not pending
	 * IPendingFile exists to handle the case where a thumbnail in a bridge might not
	 * yet be available.
	 *
	 * This class is used for cases where the thumbnail is already available.
	 */
	public class ThrottledPendingFileWrapper extends EventDispatcher implements IPendingFile
	{
		private static const knMaxAsync:Number = 2;
		private static var _apfPendingQueue:Array = [];
		private static var _nLoading:Number = 0;
		
		private var _nProgress:Number = 0;
		private var _nStatus:Number = DocumentStatus.Loading;
		
		public function ThrottledPendingFileWrapper ()
		{
			super();
			// Add to pending queue.
			// Set progress = 0, status = loading until we have space to load
			// Then, set status to loaded but keep progress at 0 (no progress bar)
			Enqueue();
		}
		
		private function Enqueue(): void {
			_apfPendingQueue.push(this);
			UpdateStatus();
		}
		
		private static function UpdateStatus(): void {
			for each (var tpfw:ThrottledPendingFileWrapper in _apfPendingQueue) {
				if (_nLoading >= knMaxAsync) break;
				if (tpfw.status != DocumentStatus.Loaded) {
					tpfw.status = DocumentStatus.Loaded;
					_nLoading += 1;
				}
			}
		}

		private function Dequeue(): void {
			var i:Number = _apfPendingQueue.indexOf(this);
			if (i == -1) throw new Error("Dequeue called on throttled pending file wrapper not in queue: "+ this);
			_apfPendingQueue.splice(i, 1);
			if (status == DocumentStatus.Loaded) {
				_nLoading -= 1;
				UpdateStatus();
			}
		}

		[Bindable ("statusupdate")]
		public function set status(n:Number): void {
			if (_nStatus == n) return;
			_nStatus = n;
			dispatchEvent(new Event("statusupdate"));
		}
		
		public function get status(): Number {
			return _nStatus;
		}

		[Bindable("progress")]
		public function set progress(n:Number): void {
			if (_nProgress == n) return;
			_nProgress = n;
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, uint(n * 100),100));
		}
		public function get progress():Number
		{
			return _nProgress;
		}
		
		// Either the target thumbnail was loaded or is no longer needed
		public function Unwatch(): void {
			Dequeue();
		}
	}
}