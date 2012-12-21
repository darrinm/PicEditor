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
	import imagine.documentObjects.IDocumentStatus;
	
	import flash.events.IEventDispatcher;
	
	[Event(name="progress", type="flash.events.ProgressEvent")]
	[Event(name="statusupdate", type="flash.events.Event")]
	
	/** IPendingFile
	 * This class is used for waiting on thumbnails in the basket/in bridges
	 * It is created from an image properties.
	 * For most items, the thumbnail is available immediately
	 * For Uploads, the thumbnail is only available once the upload has completed.
	 */
	public interface IPendingFile extends IEventDispatcher, IDocumentStatus
	{
		/**
		 * Status: progress
		 * Loading: 0 <= progress < 1
		 * Loaded: progress = 1
		 * Error: progress = 0
		 */
		// From IDocumentStatus:
		// function get status(): Number; // returns DocumentStatus constant
		function get progress(): Number;

		// Either the target thumbnail was loaded or is no longer needed
		function Unwatch(): void;
	}
}