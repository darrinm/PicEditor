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
	import bridges.Uploader;
	
	import mx.core.Application;
	
	import util.assets.ICreator;

	public class RemoteAssetCreator implements ICreator
	{
		private var _strType:String;
		private var _fTemporary:Boolean;
		private var _strUrl:String;
		
		private var _aobResults:Array = null;
		private var _fStarted:Boolean = false;
		
		private var _afnCallbacks:Array = [];
		
		public function RemoteAssetCreator(strType:String, fTemporary:Boolean, strUrl:String)
		{
			_strType = strType;
			_fTemporary = fTemporary;
			_strUrl = strUrl;
		}
		

		//   fnCreated(err:Number, strError:String, fidAsset:String=null, strImportUrl:String=null): void
		public function Create(fnCreated:Function):void
		{
			_afnCallbacks.push(fnCreated);
			StartIfNeeded();
		}
		
		private function StartIfNeeded(): void {
			if (_fStarted)
				Application.application.callLater(DoCallbacks);
			else
				DoStart();
		}
		
		private function DoCallbacks(): void {
			if (_aobResults != null) {
				while (_afnCallbacks.length > 0) {
					var fnComplete:Function = _afnCallbacks.pop();
					if (fnComplete != null)
						fnComplete.apply(NaN, _aobResults);
				}
			}
		}
		
		private function DoStart(): void {
			if (_fStarted) return;
			_fStarted = true;

			var obFileProps:Object = {};
			if (_strType != null)
				obFileProps['strType'] = _strType;
			obFileProps['fTemporary'] = _fTemporary ? 1 : 0;
			
			var fnOnCreated:Function = function(err:Number, strError:String, fidAsset:String=null,
					strAsyncImportUrl:String=null, strSyncImportUrl:String=null, strFallbackImportUrl:String=null): void {
				if (err == PicnikService.errNone) {
					// var strImportUrl:String = Uploader._fUseFallbackUploadUrls ? strFallbackImportUrl : strAsyncImportUrl;
					// These are allways async right now. We can't use the fallback until we support synchronous import/download
					var strImportUrl:String = strAsyncImportUrl;
					ImportTracker.Instance().ImportCreated(fidAsset, _strUrl, strImportUrl);
				}
				_aobResults = [err, strError, fidAsset, strImportUrl];
				DoCallbacks();
			}
			
			PicnikService.CreateFile(obFileProps, fnOnCreated);
		}
	}
}