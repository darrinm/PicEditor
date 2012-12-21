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

	/** PendingFileWrapper
	 * This class is a wrapper for IPendingFile for cases where the file is not pending
	 * IPendingFile exists to handle the case where a thumbnail in a bridge might not
	 * yet be available.
	 *
	 * This class is used for cases where the thumbnail is already available.
	 */
	public class PendingFileWrapper implements IPendingFile
	{
		public function PendingFileWrapper()
		{
		}

		public function get status():Number
		{
			return DocumentStatus.Loaded;
		}
		
		public function get progress():Number
		{
			return 1;
		}
		
		// Either the target thumbnail was loaded or is no longer needed
		public function Unwatch(): void {
			// Do nothing
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
		}
		
		public function dispatchEvent(event:Event):Boolean
		{
			return false;
		}
		
		public function hasEventListener(type:String):Boolean
		{
			return false;
		}
		
		public function willTrigger(type:String):Boolean
		{
			return false;
		}
	}
}