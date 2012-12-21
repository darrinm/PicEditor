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
package dialogs.RegisterHelper
{
	import picnik.util.LocaleInfo;
	
	import util.UserBucketManager;
	
	public class UpgradePathTracker
	{
		private static var _upt:UpgradePathTracker = null;
		private var _strBase:String;
		private static const kstrLogBase:String = '/upgradeDialog';
		
		private var _obPagesVisited:Object = {};
		
		private var _nMaxStateReached:Number = 0;
		private var _strMaxStateReached:String = "None";
		
		public static function Reset(): void {
			LogCCStateReached();
			_upt = null;
		}
		
		public static function LogCCStateReached(): void {
			if (_upt) _upt.LogStateReached();
		}
		
		public static function Init(strStartPage:String, strSourceEvent:String): void {
			LogCCStateReached();
			_upt = new UpgradePathTracker(strStartPage, AccountMgr.GetInstance().hasCredentials);
			UserBucketManager.GetInst().OnUpsellShown(strSourceEvent);
		}
		
		public static function GetEventBase(): String {
			if (_upt == null) return null;
			return _upt.eventBase;
		}
		
		public static function LogWithBase(strBase:String, strPageName:String, strExtraName:String=null, strExtraEvent:String=null): void {
			var astrParts:Array = strBase.substr(1).split('/');
			var fHasCreds:Boolean = astrParts[0].substr(0,3) == 'reg';
			_upt = new UpgradePathTracker(astrParts[1], fHasCreds);
			LogPageView(strPageName, strExtraName, strExtraEvent);
		}
		
		public static function LogPageView(strPageName:String, strExtraName:String=null, strExtraEvent:String=null): void {
			if (_upt == null) return;
			if (strPageName == "" || strPageName == null) return;
			_upt._LogPageView(strPageName, strExtraName, strExtraEvent);
		}

		public function UpgradePathTracker(strStartPage:String, fHasCreds:Boolean) {
			_strBase = fHasCreds ? '/reg' : '/guest';
			_strBase += LocaleInfo.IsEnglish() ? "_English" : "_NotEnglish";
			_strBase += '/' + strStartPage;
		}

		public static function CCStateReached(strState:String, nVal:Number): void {
			if (_upt == null) return;
			_upt._CCStateReached(strState, nVal);
		}
		
		private function LogStateReached(): void {
			if (_nMaxStateReached > 0) {
				Util.UrchinLogReport('/CCFormExit/' + PicnikBase.Locale() + "/" + _strMaxStateReached, false);
				_nMaxStateReached = 0;
				_strMaxStateReached = "Unknown";
			}
		}
		
		private function _CCStateReached(strState:String, nVal:Number): void {
			if (_nMaxStateReached < nVal) {
				_nMaxStateReached = nVal;
				_strMaxStateReached = strState;
			}
		}
		
		private function _LogPageView(strPageName:String, strExtraName:String, strExtraEvent:String): void {
			var strFullPageName:String = strPageName;
			if (strExtraName) strFullPageName += strExtraName;
			
			if (strFullPageName in _obPagesVisited) return;
			_obPagesVisited[strFullPageName] = true;
			
			var strEvent:String = kstrLogBase + eventBase + '/' + strFullPageName;
			if (strExtraEvent) strEvent += '/' + strExtraEvent;
			Util.UrchinLogNav(strEvent, false);
		}
		
		private function get eventBase(): String {
			return _strBase;
		}
	}
}