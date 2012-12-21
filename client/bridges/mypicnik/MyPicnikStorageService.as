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
package bridges.mypicnik {
	import bridges.picnik.PicnikStorageService;
	import bridges.storageservice.StorageServiceError;

	public class MyPicnikStorageService extends PicnikStorageService {
		public function MyPicnikStorageService() {
			super("mypicnik", null, "My Picnik");
		}
		
		override public function Authorize(strPerm:String=null, fnComplete:Function=null): Boolean {
			return !AccountMgr.GetInstance().isGuest;
		}
		
		override public function IsLoggedIn(): Boolean {
			// Guest users don't have a Picnik store		
			return !AccountMgr.GetInstance().isGuest;
		}
		
		override protected function get includePending(): Boolean {
			return false;
		}
		
		override protected function get defaultOrderBy(): String {
			return "dtModified";
		}
		
		override public function GetServiceInfo(): Object {
			return {
				id: "MyPicnik",
				name: "My Picnik",
				visible: true,
				create_sets: false,
				set_descriptions: false
			}
		}
		
		override protected function get itemType(): String {
			return "mypicnik:p";
		}

		override protected function get itemMimeType(): String {
			return "text/pik";
		}

		// Returns an array of dictionaries filled with information about the sets.
		// Several fields are required and some are optional but understood by the SS
		// in/out bridges. The service may add any others it knows its bridge will know
		// what to do with.
		// - id (req)
		// - itemcount (req)
		// - title (opt)
		// - description (opt)
		// - thumbnailurl (opt)
		// - webpageurl (opt)
		// - last_update (opt)
		// - createddate (opt)
		// - readonly (opt)
		//
		// fnComplete(err:Number, strError:String, adctSetInfo:Array=null)
		// - None
		// - IOError
		// - NotLoggedIn
		//
		// fnProgress(nPercent:Number)
		
		override public function GetSets(strUsername:String, fnComplete:Function, fnProgress:Function=null): void {
			// OPT: cache the album list
			var fnOnGetFileList:Function = function (err:Number, strError:String, adctProps:Array=null): void {
				if (err != PicnikService.errNone) {
					fnComplete(StorageServiceError.Unknown, strError, null);
					return;
				}
			
				var aseti:Array = [];
				aseti.push({
					id: "workspace",
//					itemcount: dctProps.itemcount,	// UNDONE: itemcount not managed yet
					title: "Workspace",	// UNDONE: localize
					description: "Put stuff here while you're working on it. Move items to other albums when you want to organize them.", // UNDONE: localize
					// UNDONE: last_update and createdate for the Workspace album
//					last_update: Number(dctProps.dtModified) * 1000,
//					createddate: Number(dctProps.dtCreated) * 1000,							
					// UNDONE: thumbnailurl, webpageurl
					readonly: false
				});
				
				for each (var dctProps:Object in adctProps) {
					var seti:Object = {
						id: dctProps.nFileId,
						// UNDONE: itemcount not managed yet
						itemcount: dctProps.itemcount,
						title: dctProps.title,
						description: dctProps.description,
						last_update: Number(dctProps.dtModified) * 1000,
						createddate: Number(dctProps.dtCreated) * 1000,							
						// UNDONE: thumbnailurl, webpageurl
						readonly: false
					}
					aseti.push(seti);
				}

				fnComplete(StorageServiceError.None, null, aseti);
			}

			try {
				PicnikService.GetFileList("strType=album", defaultOrderBy, "desc", 0, fileListLimit, null, includePending, fnOnGetFileList, null);
			} catch (err:Error) {
				var strLog:String = "Client exception: PicnikService.GetFileList";
				PicnikService.LogException(strLog, err);
			}												
		}
	}
}
