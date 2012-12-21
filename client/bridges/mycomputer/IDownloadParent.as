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
package bridges.mycomputer
{
	import flash.events.ProgressEvent;
	
	import mx.core.UIComponent;
	
	/** IDownloadParent
	 * This is something which can call FileDownloader.Download() and respond to download callbacks
	 */
	public interface IDownloadParent
	{
		// fnOnDownloadCancel = function(): void
		function get component(): UIComponent;
		function DownloadStarted(fnOnDownloadCancel:Function): void;
		function DownloadProgress(evt:ProgressEvent): void;
		function DownloadFinished(fSuccess:Boolean, strFileName:String=null): void;
		function SetFileNameBase(strName:String): void;
		
	}
}