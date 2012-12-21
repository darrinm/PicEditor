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
	import bridges.picnik.PicnikAssetSource;
	
	import com.adobe.utils.StringUtil;
	
	import imagine.documentObjects.DocumentStatus;
	
	import mx.collections.IViewCursor;
	
	import util.assets.BulkRemoteFilePeers;
	
	public class ImagePropertiesUtil
	{
		public function ImagePropertiesUtil()
		{
		}
		
		static public function GetAssetSourceArray(csr:IViewCursor, nTargets:Number): Array {
			var aasrc:Array = [];
			var asrc:IAssetSource;
			
			while (aasrc.length < nTargets) {
				if (csr.afterLast)
					break;			
			
				var imageProperties:ImageProperties = null;
				if (csr.current is ImageProperties)
					imageProperties = csr.current as ImageProperties;
				else if (csr.current is ItemInfo)
					imageProperties = (csr.current as ItemInfo).asImageProperties();
				if (imageProperties) {
					asrc = ImagePropertiesUtil.GetAssetSource(imageProperties);
					aasrc.push(asrc);
				}
				csr.moveNext();
			}
			
			var arasrcPeers:Array = [];
			var strType:String;
			
			for each (asrc in aasrc) {
				var rasrc:RemoteAssetSource = asrc as RemoteAssetSource;
				
				// Add remote asset sources if they are not already importing
				// (e.g. re-importing the same url, we already have a fid)
				if (rasrc != null && !rasrc.hasImport) {
					arasrcPeers.push(rasrc);
				}
			}
			
			if (arasrcPeers.length > 1)
				new BulkRemoteFilePeers(arasrcPeers, true);
			
			return aasrc;
		}
		
		static public function GetAssetSource(imgp:ImageProperties): IAssetSource {
			// TODO: Should we use PicnikAssetSource for a remote asset source we have seen before (and has a fid)? Probably. But keep the thumbnail the same. Hmm...
			if (IsMyComputerIn(imgp)) {
				return new PicnikAssetSource(imgp./*ss_item*/id, imgp.thumbnailurl, imgp); // With a fid
			} else { // This one creates a new fid
				return new RemoteAssetSource(imgp.sourceurl, ("i_" + imgp./*bridge*/serviceid).substr(0,10), imgp); // No fid
			}			
		}
		
		static public function IsLoading(imgp:ImageProperties): Boolean {
			var pf:IPendingFile = GetPendingFile(imgp);
			if (pf)
				return pf.status == DocumentStatus.Loading;
			else
				return false;
		}

		static private function IsMyComputerIn(iinfo:Object): Boolean {
			if (iinfo && (iinfo./*bridge*/serviceid == "mycomputer" || iinfo./*bridge*/serviceid == "Picnik") && iinfo./*ss_item*/id != null ) {
				// Is this a history entry? (.pik?) [new test]
				if (iinfo.history_serviceid != null)
					return false;
				// Is this a history entry? (.pik?) [old test]
				if ('baseurl' in iinfo) {
					if (iinfo.baseurl && iinfo.baseurl.indexOf("history:") > -1)
						return false;
				}
				return true;
			}
			return false;
		}
		
		// UNDONE: make iinf's name more generic, as it could be an ImageProperties or set info, etc.
		static public function GetPendingFile(iinf:Object, fThrottle:Boolean=false): IPendingFile {
			var pf:IPendingFile = null;
			if (IsMyComputerIn(iinf))
				pf = UploadManager.GetUpload(iinf.id);
			if (fThrottle && null != iinf && ("thumbnailurl" in iinf) && StringUtil.beginsWith(iinf['thumbnailurl'], "/thumbproxy"))
				pf = new ThrottledPendingFileWrapper();
			if (pf == null)
				pf = new PendingFileWrapper(); // Already loaded
			return pf;
		}
	}
}
