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
	import mx.core.Application;
	
	import util.assets.ICreator;
	import util.assets.imported.ImporterBase;
	import util.assets.imported.RemoteAssetCreator;
	
	public class Importer extends ImporterBase
	{
		private var _strUrl:String = null;
		private var _strType:String = null;
		private var _fTemporary:Boolean = true;
		
		private var _strImportUrl:String = null;
		
		private var _obGetInfo:Object = null;
		
		private var _nRotation:Number = NaN;
		
		private var _ctr:ICreator = null;
		
		public function Importer(strUrl:String, strType:String, fTemporary:Boolean, obGetInfo:Object, ctr:ICreator)
		{
			Debug.Assert(strUrl != null);
			Debug.Assert(strUrl.length > 0);
			
			_strUrl = strUrl;
			_strType = strType;
			_fTemporary = fTemporary;
			_obGetInfo = obGetInfo;
			_ctr = ctr;
			
			// Call create right away, then, once we have results, put hte import on the pending queue
			DoCreate();
		}
		
		private function DoCreate(): void {
			var nRotation:Number = NaN;
			
			var iaThis:Importer = this;

			if (_ctr == null)
				_ctr = new RemoteAssetCreator(_strType, _fTemporary, _strUrl);
				
			var fnSaveRotation:Function = function(): void {
				var fnOnRotationSaved:Function = function(err:Number, strError:String): void {
					_nRotation = nRotation;
					DoCallbacks();
				}
				
				Debug.Assert(_fid != null);
				Debug.Assert(!isNaN(nRotation));
				PicnikService.SetFileProperties({nRotation: nRotation}, _fid, fnOnRotationSaved);
			}
			
			var fnOnCreated:Function = function(err:Number, strError:String, fid:String=null, strImportUrl:String=null): void {
				_fid = fid;
				_strImportUrl = strImportUrl;
				if (!isNaN(nRotation))
					fnSaveRotation();

				_obCreatedParams = {err:err, strError:strError, fidCreated:fid};
				DoCallbacks();
				StartIfSpace(iaThis); // Start the import
			}
			
			var fnOnGotInfo:Function = function(err:Number, strError:String, itemInfo:ItemInfo=null): void {
				nRotation = 0;
				if (err != PicnikService.errNone) {
					trace("Error getting item info: " + err + ", " + strError);
				} else if ("flickr_rotation" in itemInfo) {
					try {
						nRotation = itemInfo["flickr_rotation"];
						// Set the rotation on the fid
						
					} catch (e:Error) {
						trace("error getting rotation: " + e);
					}
				}
				if (_fid != null)
					fnSaveRotation();
			}
			
			if (_obGetInfo) {
				var aobParams:Array = _obGetInfo.aobParams;
				aobParams = aobParams.slice();
				aobParams.push(fnOnGotInfo);

				Application.application.callLater((_obGetInfo.fnGetInfo as Function), aobParams);
			} else {
				_nRotation = 0;
			}
			
			_ctr.Create(fnOnCreated);
		}
		
		// var fnOnProgress:Function = function(cbUploaded:Number, cbTotal:Number): void {
		// var fnOnComplete:Function = function(err:Number, strError:String, fidAsset:String=null): void {
		override protected function DoImport(fnOnProgress:Function, fnOnComplete:Function): void {
			AssetMgr.ImportAsset(_strUrl, _strType, _fTemporary, null, fnOnProgress, fnOnComplete, _ctr);
		}
		
		override protected function get isLoaded(): Boolean {
			return super.isLoaded && !isNaN(_nRotation);
		}		





























	}
}
