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
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceUtil;
	
	import util.assets.ICreator;
	import util.assets.imported.RemoteAssetCreator;
	
	public class RemoteAssetSource implements IAssetSource
	{
		private var _strUrl:String;
		private var _strType:String;
		private var _strThumbUrl:String;
		private var _ss:IStorageService = null;
		private var _imgp:ImageProperties;
		private var _arasrcRelated:Array = null;
		private var _ctr:ICreator;
		
		public function RemoteAssetSource(strUrl:String, strType:String, imgp:ImageProperties) {
			_strUrl = strUrl;
			_strType = strType;
			_strThumbUrl = imgp.thumbnailurl;
			_imgp = imgp;
			if (_imgp) _ss = StorageServiceUtil.StorageServiceFromImageProperties(_imgp);
			Debug.Assert(_strUrl != null);
		}
		
		public function get url(): String {
			return _strUrl;
		}
		
		public function get type(): String {
			return _strType;
		}		
		
		public function get context(): Object {
			return _imgp;
		}
		
		public function set creator(ctr:ICreator): void {
			_ctr = ctr;
		}
		
		public function toString(): String {
			return "RemoteAssetSource[url=" + _strUrl + ", thumb=" + _strThumbUrl;
		}
		
		public function get thumbUrl(): String {
			return _strThumbUrl;
		}
		
		public function get sourceUrl(): String {
			return _strUrl;
		}
		
		public function get hasImport(): Boolean {
			return ImportManager.Instance().FindImportByParams(_strUrl, _strType, true) != null;
		}

		public function CreateAsset(fnOnAssetCreated:Function, fGuaranteedFreshFids:Boolean = false): IPendingAsset {
			// UNDONE: fGuaranteedFreshFids is not implemented
			var obGetInfo:Object = null;
			if (_ss) {
				var obInfo:Object = _ss.GetServiceInfo();
				if (('has_rotated_originals' in obInfo) && obInfo.has_rotated_originals) {
					obGetInfo = {};
					obGetInfo.fnGetInfo = _ss.GetItemInfo;
					obGetInfo.aobParams = [_imgp./*ss_*/setid, _imgp./*ss_item*/id];
				}
			}
			if (_ctr == null)
				_ctr = new RemoteAssetCreator(_strType, true, _strUrl);
			return ImportManager.Import(_strUrl, _strType, true, obGetInfo, fnOnAssetCreated, null /* fnProgress */, null /*on loaded*/, _ctr);
		}
	}
}
