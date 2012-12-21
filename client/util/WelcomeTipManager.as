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
	import api.PicnikRpc;
	
	import controls.WelcomeTip;
	import controls.WelcomeTipFooter;
	
	public class WelcomeTipManager
	{
		private var _wt:WelcomeTip = null;
 		private var _obTipsSeen:Object = null; // User tip history
 		private var _strTip:String = null;
 		private const kstrTipFile:String = "WelcomeTips.xml";
 		private var _xmlTips:XML = null;
 		private static var _wtm:WelcomeTipManager = null;

 		private static const knMinTimeBetweenTips:Number = 1000 * 60 * 60 * 20; // Twenty hours between tips.
 		//Use this instead to get a new tip every time you refresh
 		//private static const knMinTimeBetweenTips:Number = 1000; // Twenty hours between tips.
 		
 		
 		[Bindable] public var tipsDisabled:Boolean = false;
		
		public static function ShowTipIfNeeded(): void {
			GetInstance()._ShowTipIfNeeded();
		}

		public static function GetInstance(): WelcomeTipManager {
			if (_wtm == null) _wtm = new WelcomeTipManager();
			return _wtm;
		}
		
		public function WelcomeTipManager()
		{
		}
		
		protected function _ShowTipIfNeeded(): void {
			if (tipsDisabled) return;
			
			if (!_strTip) {
				if (!_xmlTips) {
					LoadTips(_ShowTipIfNeeded);
					return;
				} else if (!_obTipsSeen) {
					LoadUserHistory(_ShowTipIfNeeded);
					return;
				} else {
					var dtLastTipShown:Date = timeLastTipShown;
					var dtNow:Date = new Date();
					if (dtLastTipShown != null && (dtNow.time - dtLastTipShown.time < knMinTimeBetweenTips)) {
						return; // Don't show the tip.
					} else {
						_strTip = GetNextTip();
					}
				}
			}
			if (_strTip) {
				if (_wt == null) _wt = new WelcomeTip();
				if (_wt.showing) _wt.Hide();
				_wt.Show(_strTip, new WelcomeTipFooter());
			}
		}
		
		protected function get timeLastTipShown():Date {
			var dt:Date = null;
			if (_obTipsSeen) {
				for each (var obTip:Object in _obTipsSeen) {
					if (dt == null || dt < obTip.dtUpdated) dt = obTip.dtUpdated;
				}
			}
			return dt;
		}
		
		protected function GetNextTip(): String {
			if (_xmlTips == null) return null;
			if (_obTipsSeen == null) return null;

			// Combine _obTipsSeen and _xmlTips to figure out which tip to show
			// Logic is:
			// Sort tips XML first by seen count, then by priority. Choose the first one that comes back.
			
			var strTipId:String;
			
			var axmlTips:Array = [];
			
			for each (var xmlTip:XML in _xmlTips.Tip) {
				xmlTip.@weight = xmlTip.@priority;
				var strId:String = xmlTip.@id;
				if (strId in _obTipsSeen) {
					var nViewCount:Number = _obTipsSeen[strId].nValue;
					var nWeight:Number = xmlTip.@weight;
					nWeight += nViewCount * 10000; // We'll never have more than 10k tips, I presume
					xmlTip.@weight = nWeight;
				}
				axmlTips.push(xmlTip);
			}
 			axmlTips.sortOn('@weight', Array.NUMERIC);
			
			strTipId = axmlTips[0].@id;
			var strTipPath:String = kstrTipFile + "/" + strTipId;
			
			UpdateViewCount(strTipId);
			return strTipPath;
		}
		
		protected function UpdateViewCount(strTipId:String): void {
			var obTip:Object;
			if (!(strTipId in _obTipsSeen)) {
				_obTipsSeen[strTipId] = {nValue:0};
			}
			obTip = _obTipsSeen[strTipId];
			
			obTip.nValue += 1;
			
			var obUpdate:Object = {};
			obUpdate[strTipId] = obTip.nValue;
			PicnikRpc.SetUserProperties(obUpdate, 'welcometips');
			
			obTip.dtUpdated = new Date();
			
			_obTipsSeen[strTipId] = obTip;
		}
		
		protected function LoadUserHistory(fnDone:Function): void {
			_obTipsSeen = null;
			PicnikService.GetUserProperties("welcometips", function(err:Number, ob:Object=null): void {OnLoadUserHistory(ob, fnDone);});
 		}
 		
 		private function OnLoadUserHistory(obResults:Object, fnDone:Function): void {
 			if (obResults) {
 				if ('welcometips' in obResults) {
	 				_obTipsSeen = obResults.welcometips;
	 				for each (var obTip:Object in _obTipsSeen) {
	 					obTip.dtUpdated = new Date(obTip.updated);
	 					obTip.nValue = Number(obTip.value);
	 				}
	 			} else {
	 				_obTipsSeen = {}; // No questions answered.
	 			}
	 		}
 			fnDone();
 		}
		
		protected function LoadTips(fnDone:Function): void {
			// Load the tips, then call fnDone();
			TipLoader.GetTips("WelcomeTips.xml", function (xml:XML, strFile:String): void { OnTipsLoaded(xml, fnDone); });
		}
		
		protected function OnTipsLoaded(xmlTips:XML, fnDone:Function): void {
			_xmlTips = xmlTips;
			fnDone();
		}
	}
}