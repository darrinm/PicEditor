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
	public class ImportTracker
	{
		private static var _it:ImportTracker = null;
		
		public static const knCreated:Number = 0;
		public static const knImporting:Number = 1;
		public static const knFinished:Number = 2;
		
		private static const knMaxImportAge:Number = 90;// in minutes
		
		public static function Instance(): ImportTracker {
			if (_it == null)
				_it = new ImportTracker();
			return _it;
		}
		
		private var _obKnownFids:Object = {};
		
		public function ImportTracker()
		{
			// Get the list
			try {
				_obKnownFids = Session.GetPersistentClientState("importtracker", {});
				Cleanup();
			} catch (e:Error) {
				trace("Error in ImportTracker constructor: " + e + ", " + e.getStackTrace());
			}
		}
		
		private function Save(): void {
			Session.SetPersistentClientState("importtracker", _obKnownFids);			
		}
		
		public function ImportCreated(fid:String, strUrl:String, strImportUrl:String): void {
			Debug.Assert(Number(fid) > 0);
			Debug.Assert(strUrl != null);
			Debug.Assert(strImportUrl != null);
			try {
				_obKnownFids[fid] = {};
				_obKnownFids[fid].nStatus = knCreated;
				_obKnownFids[fid].dtLastModified = new Date();
				_obKnownFids[fid].strUrl = strUrl;
				_obKnownFids[fid].strImportUrl = strImportUrl;
				Save();
			} catch (e:Error) {
				trace("Error in ImportTracker.ImportCreated: " + e + ", " + e.getStackTrace());
			}
		}
		
		public function ImportStarted(fid:String): void {
			Debug.Assert(Number(fid) > 0);
			try {
				if (fid in _obKnownFids && _obKnownFids[fid] != null) {
					_obKnownFids[fid].nStatus = knImporting;
					_obKnownFids[fid].dtLastModified = new Date();
					Save();
				}
			} catch (e:Error) {
				trace("Error in ImportTracker.ImportStarted: " + e + ", " + e.getStackTrace());
			}
		}
		
		public function ImportCompleted(fid:String): void {
			Debug.Assert(Number(fid) > 0);
			try {
				if (fid in _obKnownFids) {
					delete _obKnownFids[fid];
					Save();
				}
			} catch (e:Error) {
				trace("Error in ImportTracker.ImportCompleted: " + e + ", " + e.getStackTrace());
			}
		}
		
		public function GetUrl(fid:String): String {
			try {
				if (GetImportStatus(fid) != knFinished) {
					return _obKnownFids[fid].strUrl;
				}
			} catch (e:Error) {
				trace("Error in ImportTracker.GetUrl: " + e + ", " + e.getStackTrace());
			}
			return null;
		}
		
		public function GetImportUrl(fid:String): String {
			try {
				if (GetImportStatus(fid) != knFinished) {
					if (_obKnownFids[fid].strImportUrl == null) {
						trace("null");
					}
					return _obKnownFids[fid].strImportUrl;
					
				}
			} catch (e:Error) {
				trace("Error in ImportTracker.GetImportUrl: " + e + ", " + e.getStackTrace());
			}
			return null;
		}
		
		public function GetImportStatus(fid:String): Number {
			try {
				Cleanup();
				if (fid in _obKnownFids) {
					var obFidInfo:Object = _obKnownFids[fid];
					if (obFidInfo != null) {
						return obFidInfo.nStatus;
					}
				} 
			} catch (e:Error) {
				trace("Error in ImportTracker.GetImportStatus: " + e + ", " + e.getStackTrace());
			}
			return knFinished;
		}

		private function Cleanup(): void {
			var fChange:Boolean = false;
			for (var fid:String in _obKnownFids) {
				var obFidInfo:Object = _obKnownFids[fid];
				if (Expired(obFidInfo)) {
					delete _obKnownFids[fid];
					fChange = true;
				}
			}
			if (fChange)
				Save();
		}
		
		private function Expired(obFidInfo:Object): Boolean {
			if (obFidInfo == null || !('dtLastModified' in obFidInfo)) return true;
			return DateToMinuteAge(obFidInfo['dtLastModified']) > knMaxImportAge;
		}

		// Returns the age, in minutes, of a date.
		// If date == null, returns about 1 year.
		private function DateToMinuteAge(date:Date): Number {
			if (date == null) {
				date = new Date();
				date.setTime(date.getTime() - (1000 * 60 * 60 * 24 * 365)); // Default age is very large, about 1 year
			}
			var dateNow:Date = new Date();
			return Math.abs(date.getTime() - dateNow.getTime()) / 60000;
		}
	}
}