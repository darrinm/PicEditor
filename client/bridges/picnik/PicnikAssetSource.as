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
package bridges.picnik
{
	import bridges.Uploader;
	
	import imagine.documentObjects.DocumentStatus;
	
	import flash.events.Event;

	import mx.core.Application;
	
	import util.IAssetSource;
	import util.IPendingAsset;
	import util.IPendingFile;
	import util.UploadManager;
	
	/** PicnikAssetSource
	 * This is a picnik image.
	 * When we add it to a document, do not create a new fid.
	 * If the fid is in progress, wait for that to complete before calling our callback functions
	 */
	public class PicnikAssetSource implements IAssetSource, IPendingAsset
	{
		private var _fid:String;
		private var _strThumbnailUrl:String;
		private var _fnOnAssetCreated:Function;
		private var _pf:IPendingFile = null;
		private var _fPendingClone:Boolean = false;
		private var _imgp:ImageProperties;
		private var _afnOnCloned:Array = [];

		public function PicnikAssetSource(fid:String, strThumbnailUrl:String, imgp:ImageProperties)
		{
			_fid = fid;
			_pf = UploadManager.GetPendingFile(fid);
			_strThumbnailUrl = strThumbnailUrl;
			_imgp = imgp;
		}
		
		private function get assetCreated(): Boolean {
			return (_pf.status != DocumentStatus.Loading);
		}		
		
		private function get assetReady(): Boolean {
			return (assetCreated && !_fPendingClone);
		}

		public function get context(): Object {
			return _imgp;
		}
		
		// fnOnAssetCreated(err:Number, strError:String, fidCreated:String=null): void
		public function CreateAsset(fnOnAssetCreated:Function, fGuaranteedFreshFids:Boolean = false): IPendingAsset {
			var fnOnPendingStatusUpdate:Function = function(evt:Event=null): void {
				if (assetCreated) {
					if (fGuaranteedFreshFids) {
						PicnikService.CloneFile(_fid,
							{ 'strType':'None',
							  'fTemporary':1 },
					     	function( err:Number, strErr:String, strFid:String = null ): void {
					     		_fid = strFid;
					     		_fPendingClone = false;
								fnOnAssetCreated(err, strErr, strFid);
								DoCallbacks();
							} );
					} else {
						fnOnAssetCreated(PicnikService.errNone, "No error", _fid);
					}
				}	
				DoCallbacks();			
			}
			
			_fPendingClone = fGuaranteedFreshFids;
			
			// UNDONE: Call asset created right away or when the asset is loaded?
			if (!assetCreated) {
				// Wait for it to load
				_pf.addEventListener("statusupdate", fnOnPendingStatusUpdate);
				return _pf as Uploader;
			} else {
				// Loaded. Call back (delayed)
				if (fGuaranteedFreshFids) {
					Application.application.callLater(fnOnPendingStatusUpdate);
					return this;
				} else {
					fnOnPendingStatusUpdate();
					return null;
				}
			}
			return null;
		}
		
		// We do not have a thumbnail url - just load the asset directly once it is ready
		public function get thumbUrl():String {
			return (_pf.status == DocumentStatus.Loading) ? null : _strThumbnailUrl;
		}
		
		// We do not have a source url - just return null
		public function get sourceUrl():String {
			return null;
		}
		
		
		// public function fnComplete(err:Number, strError:String, dctProps:Array=null): void
		public function GetFileProperties(strProps:String, fnComplete:Function): void {
			var fnOnLoad:Function = function(): void {
				PicnikService.GetFileProperties(_fid, null, strProps, fnComplete);
			}
			AddOnCloneCallback(fnOnLoad);
		}	
		
					
		private function AddOnCloneCallback(fnOnLoad:Function): void {
			_afnOnCloned.push(fnOnLoad);
			Application.application.callLater(DoCallbacks);
		}
		
		private function DoCallbacks(): void {
			if (assetReady) {
				while (_afnOnCloned.length > 0) {
					var fnOnLoad:Function = _afnOnCloned.pop();
					fnOnLoad();
				}
			}
		}
	}
}
