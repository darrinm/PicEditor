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
// show tip(s) if not deliberately closed
// show tip(s) when ui state activated
// hide tip(s) when ui state deactivated
// auto-takedown
// position relative to
// show if not already shown
// reset already shown tips
//

// Tip XML
// - id
// - quasiModal
// - position relative to
// - show once | show until closed

// TipState
// - shown
// - closed

package util {
	import controls.Tip;
	
	import flash.events.Event;
	
	// tip closed?
	// tip seen?
	
	public class HelpManager {
 		static private const kstrHelpFile:String = "help.xml";
 		
 		private var _xmlHelp:XML = null;
 		private var _dctVisibleHelp:Object = {};
		private var _aobDeferedHelp:Array;
		
 		private static var _helpm:HelpManager = null;
 		
 		//
 		// Public methods
 		//
 		
 		public static function Init(): void {
 			// load tips. UNDONE: retry a couple times
			// TipLoader.GetTips(kstrHelpFile, GetInstance().OnHelpLoaded);
 		}

		// If fForce == true, show the tip even it has been closed already
		public static function ShowHelp(strHelpId:String, fInFeedback:Boolean=false): Tip {
			return GetInstance()._ShowHelp(strHelpId, fInFeedback);
		}

		// HideTip doesn't effect the tip's TipState (e.g. doesn't set knClosed)
		public static function HideHelp(strHelpId:String, fFade:Boolean=true): void {
			GetInstance()._HideHelp(strHelpId, fFade);
		}

		public static function GetInstance(): HelpManager {
			if (_helpm == null) _helpm = new HelpManager();
			return _helpm;
		}
		
		//
		// Private methods
		//
		
		private function OnHelpLoaded(xmlHelp:XML, strFile:String): void {
			_xmlHelp = xmlHelp;
			
			if (_aobDeferedHelp) {
				for each (var ob:Object in _aobDeferedHelp) {
					var xmlTip:XML = _xmlHelp.Tip.(@id == ob.strHelpId)[0];
					ob.tip.Show(null, null, xmlTip);
				}
				_aobDeferedHelp = null;
			}
		}
		
		private function _ShowHelp(strHelpId:String, fInFeedback:Boolean): Tip {
			if (strHelpId in _dctVisibleHelp)
				return _dctVisibleHelp[strHelpId]; // Don't re-show a tip
				
			var tip:Tip = new Tip();
			tip.showFeedbackFooter = !fInFeedback;
			tip.id = strHelpId;
			tip.addEventListener(Event.CLOSE, OnTipClose);
			
			// Tips may have not completed loading yet. Defer display of the tip until
			// its data is available.
			// UNDONE: take control of load order and make sure tips are loaded
			// before we ever try to display one.
			if (_xmlHelp == null) {
				if (_aobDeferedHelp == null)
					_aobDeferedHelp = [];
				_aobDeferedHelp.push({ tip: tip, strHelpId: strHelpId });
			} else {
				var xmlTip:XML = _xmlHelp.Tip.(@id == strHelpId)[0];
				tip.Show(null, null, xmlTip);
			}
			
			// Track shown tips so they can be hidden
			_dctVisibleHelp[strHelpId] = tip;
			return tip;
		}
		
		private function OnTipClose(evt:Event): void {
			var tip:Tip = evt.target as Tip;
			var strHelpId:String = tip.tipId;
			delete _dctVisibleHelp[strHelpId];
		}
		
		private function _HideHelp(strHelpId:String, fFade:Boolean): void {
			if (!(strHelpId in _dctVisibleHelp))
				return;
			(_dctVisibleHelp[strHelpId] as Tip).Hide(fFade);
			
			delete _dctVisibleHelp[strHelpId];
		}
	}
}
