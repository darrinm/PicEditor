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
	import mx.core.Application;
	
	import util.IPendingAsset;
	
	public class ImporterBase implements IPendingAsset
	{
		private static var _aiaPending:Array = [];
		private static var _nAssetsLoading:Number = 0;
		private static const knMaxAsyncLoads:Number = 2;

		private var _afnComplete:Array = [];
		private var _afnProgress:Array = [];
		private var _afnCreated:Array = [];
		
		protected var _fid:String = null;
		
		public var failed:Boolean = false;

		protected var _obCreatedParams:Object = null;
		private var _obCompleteParams:Object = null;

		public function ImporterBase()
		{
		}

		public function get fid(): String {
			return _fid;
		}

		// function fnComplete(err:Number, strError:String, dctProps:Array=null): void
		public function GetFileProperties(strProps:String, fnComplete:Function): void {
			var fnOnLoaded:Function = function (err:Number, strError:String, fidAsset:String): void {
				
				var fnOnGotProperties:Function = function(err:Number, strError:String, dctProps:Object=null): void {
					if (err != PicnikService.errNone)
						failed = true;
					else if (strProps.indexOf("nWidth") > -1 && dctProps["nWidth"] == undefined)
						failed = true;
					fnComplete(err, strError, dctProps);
				}
				
				if (err != PicnikService.errNone) {
					failed = true;
					fnComplete(err, strError);
				} else {
					PicnikService.GetFileProperties(_fid, null, strProps, fnOnGotProperties);
				}
			}
			_afnComplete.push(fnOnLoaded);
			Application.application.callLater(DoCallbacks);
		}
		
		protected function DoStart(): void {
			var fnOnProgress:Function = function(cbUploaded:Number, cbTotal:Number): void {
				for each (var fnProgress:Function in _afnProgress)
					fnProgress(cbUploaded, cbTotal);
			}
			
			var fnOnComplete:Function = function(err:Number, strError:String, fidAsset:String=null): void {
				try {
					_obCompleteParams = {err:err, strError:strError, fidAsset:fidAsset};
					if (err != PicnikService.errNone)
						failed = true;
					DoCallbacks();
				} catch (e:Error) {
					trace("Exception: " + e + " , " + e.getStackTrace());
				}
				_nAssetsLoading--;
				StartIfSpace(); // Start the next load
			}
			
			// Assume that when we call ImportAsset, fnOnComplete will always get called (even if there are exceptions)
			DoImport(fnOnProgress, fnOnComplete);
			_nAssetsLoading++;
		}
		
		// Override in sub-classes (e.g. ReImporter)
		// var fnOnProgress:Function = function(cbUploaded:Number, cbTotal:Number): void {
		// var fnOnComplete:Function = function(err:Number, strError:String, fidAsset:String=null): void {
		protected function DoImport(fnOnProgress:Function, fnOnComplete:Function): void {
			throw new Error("ImporterBase.DoImport must be override in sub-classes");
		}

		protected static function StartIfSpace(ia:ImporterBase=null): void {
			if (ia) _aiaPending.push(ia);
			while (_nAssetsLoading < knMaxAsyncLoads && _aiaPending.length > 0) {
				var iaPending:ImporterBase = _aiaPending.pop();
				iaPending.DoStart();
			}
		}
		
		protected function get isCreated(): Boolean {
			return _obCreatedParams != null;
		}		

		protected function get isLoaded(): Boolean {
			return _obCompleteParams != null;
		}		

		// This function should not throw an exception
		protected function DoCallbacks(): void {
			if (isCreated) {
				for each (var fnCreated:Function in _afnCreated) {
					try {
						fnCreated(_obCreatedParams.err, _obCreatedParams.strError, _obCreatedParams.fidCreated);
					} catch (e:Error) {
						trace("Exception in ImportedAsset.DoCallbacks.1: " + e + ", " + e.getStackTrace());
					}
				}
				_afnCreated.length = 0;
			}
			if (isLoaded) { // Make sure we have a rotation before we say we are complete.
				for each (var fnComplete:Function in _afnComplete) {
					try {
						fnComplete(_obCompleteParams.err, _obCompleteParams.strError, _obCompleteParams.fidAsset);
					} catch (e2:Error) {
						trace("Exception in ImportedAsset.DoCallbacks.2: " + e2 + ", " + e2.getStackTrace());
					}
				}
				_afnComplete.length = 0;
			}
		}
		
		public function Import(fnCreated:Function, fnProgress:Function, fnComplete:Function): void {
			if (fnCreated != null) _afnCreated.push(fnCreated);
			if (fnProgress != null) _afnProgress.push(fnProgress);
			if (fnComplete != null) _afnComplete.push(fnComplete);
			Application.application.callLater(DoCallbacks);
			StartIfSpace();
		}
	}
}