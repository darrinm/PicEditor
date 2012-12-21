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
package util.assets
{
	import mx.core.Application;
	
	import util.RemoteAssetSource;
	import util.assets.imported.ImportTracker;
	
	public class BulkRemoteFilePeers
	{
		// Resuts from the create call
		private var _err:Number = NaN; // Default is NaN. When this is not NaN, we have results.
		private var _strError:String;
		private var _aobCreated:Array = null;
		private var _afnOnCreated:Array = [];
		
		private var _astrUrls:Array = [];
		
		public function BulkRemoteFilePeers(arasrc:Array, fTemporary:Boolean=true) // array of RemoteAssetSource
		{
			Debug.Assert(arasrc.length > 0);
			
			// Perform create many call
			var obFileProps:Object = {};
			// TODO: One type per source
			var strType:String = (arasrc[0] as RemoteAssetSource).type;
			if (strType)
				obFileProps['strType'] = strType;
			obFileProps['fTemporary'] = fTemporary ? 1 : 0;
			
			PicnikService.CreateManyFiles(arasrc.length, obFileProps, OnCreateMany);
			
			for (var i:Number = 0; i < arasrc.length; i++) {
				var rasrc:RemoteAssetSource = arasrc[i];
				rasrc.creator = new BulkRemoteCreator(this, i);
				_astrUrls[i] = rasrc.url;
			}
		}
	
		// CreateMany makes this callback:
		//public function fnDone(err:Number, strError:String, aobCreated:Array=null): void
 		//	aobCreated is an array of nFiles objects with .fid and .importurl
 		
 		private function OnCreateMany(err:Number, strError:String, aobCreated:Array=null): void {
 			_err = err;
 			_strError = strError;
 			_aobCreated = aobCreated;
 			
 			// Make sure we do not set _err to NaN so we know we are finished.
 			if (isNaN(_err))
 				_err = PicnikService.errFail;
 			
 			if (_err == PicnikService.errNone && aobCreated) {
 				for (var i:Number = 0; i < aobCreated.length; i++) {
 					ImportTracker.Instance().ImportCreated(aobCreated[i].fid, _astrUrls[i], aobCreated[i].importurl);
 				}
 			}
 			
 			DoCallbacks();
		}
		
		private function DoCallbacks(): void {
			if (isNaN(_err)) return; // Not done yet
			
			while (_afnOnCreated.length > 0) {
				var fnOnCreated:Function = _afnOnCreated.pop();
				fnOnCreated();
			}
		}
		
		private function WaitForCreated(fnOnCreated:Function): void {
			_afnOnCreated.push(fnOnCreated);
			Application.application.callLater(DoCallbacks);
		}
		
		//   fnCreated(err:Number, strError:String, fidAsset:String=null, strImportUrl:String=null): void
		public function Create(fnCreated:Function, nIndex:Number): void {
			var fnOnCreated:Function = function(): void {
				var fid:String = null;
				var strImportUrl:String = null;
				
				if (_aobCreated && _aobCreated.length > nIndex) {
					fid = _aobCreated[nIndex].fid;
					strImportUrl = _aobCreated[nIndex].importurl;
				}
				
				if (fnCreated != null)
					fnCreated(_err, _strError, fid, strImportUrl);
			}
			
			WaitForCreated(fnOnCreated);
		}
		
		public function GetCreator(nIndex:Number): ICreator {
			return new BulkRemoteCreator(this, nIndex);
		}
	}
}