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
package util.assets.imported
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import mx.core.Application;
	
	import util.AssetMgr;
	import util.assets.AlreadyCreated;
	import util.assets.ICreator;
	
	public class Reimporter extends ImporterBase
	{
		private var _ctr:ICreator;
		
		// The fid was created. The import is in progress.
		// Get in the queue to block on the import (or possibly start it)
		// Return delayed calls to GetFileProperties. ImporterBase handles
		// delayed callbacks - as long as we set up obCreated and obComplete params correctly
		public function Reimporter(fid:String)
		{
			super();
			_fid = fid;
			
			var iaThis:Reimporter = this;

 			var fnOnLater:Function = function(): void {
 				_obCreatedParams = {err:PicnikService.errNone, strError:"", fid:fid, strImportUrl:importUrl};
 				
 				// Created. Now do callbacks and add it to the start queue
				DoCallbacks();
				StartIfSpace(iaThis); // Start the import
 			}
 			
 			Application.application.callLater(fnOnLater);
		}
		
 		private function get importUrl(): String {
			return ImportTracker.Instance().GetImportUrl(fid);
		}
		
 		private function get sourceUrl(): String {
			return ImportTracker.Instance().GetUrl(fid);
		}
		
		// var fnOnProgress:Function = function(cbUploaded:Number, cbTotal:Number): void {
		// var fnOnComplete:Function = function(err:Number, strError:String, fidAsset:String=null): void {
 		override protected function DoImport(fnOnProgress:Function, fnOnComplete:Function):void {
 			var nStatus:Number = ImportTracker.Instance().GetImportStatus(fid);
 			if (nStatus == ImportTracker.knImporting) {
 				// Wait for the import
 				try {
	 				var strStatusUrl:String = PicnikService.GetFileURL(fid, {format:'status'});
	 				trace("status url = " + strStatusUrl);
 				
 					var fnError:Function = function(evt:Event): void {
 						trace("Error loading status: " + evt);
 						fnOnComplete(PicnikService.errFail, evt.toString());
 					}
 					
 					var fnComplete:Function = function(evt:Event): void {
 						trace("Got file status for fid " + fid + ": " + urll.data);
 						fnOnComplete(PicnikService.errNone, "", fid);
 					}
 					var urlr:URLRequest = new URLRequest(strStatusUrl);
 					var urll:URLLoader = new URLLoader(urlr);
 					urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnError);
 					urll.addEventListener(IOErrorEvent.IO_ERROR, fnError);
 					urll.addEventListener(Event.COMPLETE, fnComplete);
 				} catch (e:Error) {
 					fnOnComplete(PicnikService.errFail, e.toString());
 				}
 			} else if (nStatus == ImportTracker.knCreated) {
 				// Start the import
 				var ctr:AlreadyCreated = new AlreadyCreated(PicnikService.errNone, "", fid, importUrl);
 				AssetMgr.ImportAsset(sourceUrl, null, true, null, fnOnProgress, fnOnComplete, ctr);
 			} else {
 				Debug.Assert(false, "Invalid state for reimporter");
 			}
 		}
	}
}