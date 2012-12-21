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
	import api.PicnikRpc;
	import api.RpcResponse;
	
	import controls.Tip;
	
	import events.AccountEvent;
	
	import flash.events.Event;
	
	// tip closed?
	// tip seen?
	
	public class TipManager {
 		static private const kstrTipFile:String = "tips.xml";
 		
 		private var _xmlTips:XML = null;
 		private var _dctTipState:Object = null; // TipState values indexed by tip id
 		private var _dctVisibleTips:Object = {};
		private var _aobDeferedTips:Array;
		private var _aobGetTipStateCallbacks:Array;
		
 		private static var _tipm:TipManager = null;
 		
 		//
 		// Public methods
 		//
 		
 		public static function Init(): void {
 			// load tips. UNDONE: retry a couple times
			TipLoader.GetTips(kstrTipFile, GetInstance().OnTipsLoaded);
			
			// Monitor user logins and load the user's tip state then
			AccountMgr.GetInstance().addEventListener(AccountEvent.USER_CHANGE, GetInstance().OnUserChange);
			GetInstance().OnUserChange(null);
 		}

		// If fForce == true, show the tip even it has been closed already
		public static function ShowTip(strTipId:String, fForce:Boolean=false, dctParams:Object=null): Tip {
			return GetInstance()._ShowTip(strTipId, fForce, dctParams);
		}
		
		// fnDone(tip:Tip):void
		// on failure/no-show, tip will be null
		public static function ShowTipIfNotShown(strTipId:String, fnDone:Function=null, dctParams:Object=null): void {
			GetInstance().GetTipState(strTipId, function(strTipId:String, nStatus:uint): void {
				var tip:Tip = null;
				if (!(nStatus & TipState.knClosed)) // Not closed
					tip = ShowTip(strTipId, false, dctParams); // Show it
				fnDone(tip);
			});
		}

		// HideTip doesn't effect the tip's TipState (e.g. doesn't set knClosed)
		public static function HideTip(strTipId:String, fFade:Boolean=true, fClose:Boolean=false): void {
			GetInstance()._HideTip(strTipId, fFade, fClose);
		}

		public static function GetInstance(): TipManager {
			if (_tipm == null) _tipm = new TipManager();
			return _tipm;
		}
		
		// fnCallback(strTipId:String, nStatus:uint): void
		public function GetTipState(strTipId:String, fnCallback:Function): void {
			if (null != _dctTipState) {
				fnCallback( strTipId, _dctTipState[strTipId] );
			} else {
				if (!_aobGetTipStateCallbacks) _aobGetTipStateCallbacks = [];					
				_aobGetTipStateCallbacks.push( {id: strTipId, callback: fnCallback} );
			}
		}
		
		public function UpdateTipState(strTipId:String, stat:uint): void {
			if (_dctTipState && _dctTipState[strTipId] != stat) {
				_dctTipState[strTipId] = stat;
				var obPropValue:Object = {};
				obPropValue[strTipId] = stat;
				PicnikRpc.SetUserProperties(obPropValue, "tips");
			}
		}
		
		public function ResetTips(): void {
			for (var strTipId:String in _dctTipState) {
				UpdateTipState(strTipId, 0);
			}
		}
		
		//
		// Private methods
		//
		
		private function OnTipsLoaded(xmlTips:XML, strFile:String): void {
			_xmlTips = xmlTips;
			
			if (_aobDeferedTips) {
				for each (var ob:Object in _aobDeferedTips) {
					var xmlTip:XML = _xmlTips.Tip.(@id == ob.strTipId)[0];
					ob.tip.Show(null, null, xmlTip, ob.dctParams);
				}
				_aobDeferedTips = null;
			}
		}
		
		// Load per-user tip state (shown, closed, etc)
		private function OnUserChange(evt:AccountEvent): void {
			PicnikRpc.GetUserProperties("tips", OnLoadTipState);
		}
		
		// obResults looks like { "tips": [ { "name": <tip id>, "value": <TipState bitfield>, "updated": <date> }, ... ] }
		// All values are strings? converted?
		private function OnLoadTipState(rpcResp:RpcResponse): void {
			var obTips:Object = null;
			if (rpcResp.data && 'tips' in rpcResp.data)
				obTips = rpcResp.data['tips'];
			
			_dctTipState = {};
 			for (var strKey:String in obTips)
 				_dctTipState[strKey] = int(Number(obTips[strKey][0]));

			if (_aobGetTipStateCallbacks) {
				for each (var obGTS:Object in _aobGetTipStateCallbacks) {
					obGTS.callback( obGTS.id, _dctTipState[obGTS.id] );
				}
				_aobGetTipStateCallbacks = null;				
			}
		}
		
		private function _ShowTip(strTipId:String, fForce:Boolean, dctParams:Object=null): Tip {
			var stat:uint;
			if (_dctTipState == null)
				stat = TipState.knShown;
			else
				stat = _dctTipState[strTipId];
			
			// The caller can force the tip to be displayed even if the user already closed it
			if (fForce)
				stat &= ~TipState.knClosed;
			
			// Don't show the tip if it has already been closed
			if (stat & TipState.knClosed)
				return null;
			
			// OK, we're going to show it
			stat = (stat | TipState.knShown) & ~TipState.knClosed;
			
			// If the TipState has changed update the user's properties
			UpdateTipState(strTipId, stat);
			
			var tip:Tip = new Tip();
			tip.id = strTipId;
			tip.addEventListener(Event.CLOSE, OnTipClose);
			
			// Tips may have not completed loading yet. Defer display of the tip until
			// its data is available.
			// UNDONE: take control of load order and make sure tips are loaded
			// before we ever try to display one.
			if (_xmlTips == null) {
				if (_aobDeferedTips == null)
					_aobDeferedTips = [];
				_aobDeferedTips.push({ tip: tip, strTipId: strTipId, dctParams: dctParams });
			} else {
				var xmlTip:XML = _xmlTips.Tip.(@id == strTipId)[0];
				tip.Show(null, null, xmlTip, dctParams);
			}
			
			// Track shown tips so they can be hidden
			_dctVisibleTips[strTipId] = tip;
			return tip;
		}
		
		private function OnTipClose(evt:Event): void {
			// OnLoadTipState() might not have been called yet if we're closing
			// something the instant the app starts up. 
			if (_dctTipState == null)
				return;
				
			var tip:Tip = evt.target as Tip;
			var strTipId:String = tip.tipId;
			var stat:uint = _dctTipState[strTipId] | TipState.knClosed;
			UpdateTipState(strTipId, stat);
			delete _dctVisibleTips[strTipId];
		}
		
		// If fClose==true set the TipState.knClosed bit on the tip
		private function _HideTip(strTipId:String, fFade:Boolean, fClose:Boolean): void {
			if (!(strTipId in _dctVisibleTips))
				return;
			(_dctVisibleTips[strTipId] as Tip).Hide(fFade);
			
			if (fClose) {
				var stat:uint = _dctTipState[strTipId] | TipState.knClosed;
				UpdateTipState(strTipId, stat);
			}
			delete _dctVisibleTips[strTipId];
		}
	}
}
