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
	import util.assets.ICreator;
	import util.assets.imported.ImporterBase;
	import util.assets.imported.Reimporter;
	
	public class ImportManager
	{
		private static var _im:ImportManager = null;
		
		private var _obImportedAssets:Object = {}; // by asset key, see GetAssetKey()
		private var _obReimportedAssets:Object = {}; // by fid
		
		// Wrapper for AssetMgr.import which unites duplicate requests for the same asset
		public static function Import(strUrl:String, strType:String, fTemporary:Boolean, obGetInfo:Object, fnCreated:Function=null, fnProgress:Function=null, fnComplete:Function=null, ctr:ICreator=null): IPendingAsset {
			return Instance()._Import(strUrl, strType, fTemporary, obGetInfo, fnCreated, fnProgress, fnComplete, ctr);
		}
		
		public static function Instance(): ImportManager {
			if (_im == null)
				_im = new ImportManager();
			
			return _im;
		}
		
		public function ImportManager()
		{
		}
		
		private function GetAssetKey(strUrl:String, strType:String, fTemporary:Boolean): String {
			return fTemporary.toString() + "&" + encodeURI(strType) + "&" + strUrl;
		}
		
		// Returns null if none found.
		public function FindImportByFid(fid:String): ImporterBase {
			if (fid == null || fid.length == 0) return null; // Invalid fid
			
			for each (var ia:ImporterBase in _obImportedAssets) {
				if (ia.fid == fid && !ia.failed)
					return ia;
			}
			
			return SafeLookupReimport(fid);
		}
		
		private function SafeLookupReimport(fid:String): Reimporter {
			return SafeLookup(_obReimportedAssets, fid) as Reimporter;
		}

		private function SafeLookupImporter(strKey:String): ImporterBase {
			return SafeLookup(_obImportedAssets, strKey);
		}
		
		private function SafeLookup(obDict:Object, strKey:String): ImporterBase {
			if (!(strKey in obDict)) return null; // Not there
			var ia:ImporterBase = obDict[strKey];
			if (ia == null || ia.failed) {
				delete obDict[strKey];
				ia = null;
			}
			return ia
		}
		
		public function FindImportByParams(strUrl:String, strType:String, fTemporary:Boolean): ImporterBase {
			var strKey:String = GetAssetKey(strUrl, strType, fTemporary);
			return SafeLookupImporter(strKey);
		}
		
		private function GetAsset(strUrl:String, strType:String, fTemporary:Boolean, obGetInfo:Object, ctr:ICreator): ImporterBase {
			var strKey:String = GetAssetKey(strUrl, strType, fTemporary);

			var ia:ImporterBase = SafeLookupImporter(strKey);
			if (ia == null) {
				ia = new Importer(strUrl, strType, fTemporary, obGetInfo, ctr);
				_obImportedAssets[strKey] = ia;
			}
			return ia;
		}
		
		// Reconnect to an ongoing import, status nImportStatus, url to import strUrl
		public function Reimport(fid:String, nImportStatus:Number, strUrl:String): IPendingAsset {
			var ia:ImporterBase = SafeLookupReimport(fid);
			if (ia == null)
				ia = _obReimportedAssets[fid] = new Reimporter(fid);
			return ia;
		}
		
		private function _Import(strUrl:String, strType:String, fTemporary:Boolean, obGetInfo:Object, fnCreated:Function, fnProgress:Function, fnComplete:Function, ctr:ICreator): IPendingAsset {
			var ia:ImporterBase = GetAsset(strUrl, strType, fTemporary, obGetInfo, ctr);
			ia.Import(fnCreated, fnProgress, fnComplete);
			return ia;
		}
	}
}