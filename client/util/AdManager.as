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
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.effects.easing.Exponential;
			
	public class AdManager
	{
		public static const _knMaxAnimationTime:int = 1000;

		private var _fBannerAdsOn:Boolean = false;
		private var _fFullscreenShowing:Boolean = false;
		
		private var _nStart:int; //milliseconds after midnight, start of transistion
		private var _fShowAds:Boolean = false;
		private var _nWidthDiff:int = 0;
		private var _nTopDiff:int = 0;
		private var _nWidthActual:int = 0;
		private var _nTopActual:int = 0;
		private var _nWidthTarget:int = 0;
		private var _nTopTarget:int = 0;
		private var _tmrAnimate:Timer = new Timer(50);
		
		private var _dateLastAd:Date = new Date();
		private static const _knWaitTime:int = 1000 * 30; // wait for 30 seconds before showing and add

		private static var _am:AdManager = null;
		
		private var _fHideBannerAds:Boolean = false;
		private var _cwIsPaid:ChangeWatcher = null;
		private var _cwNewUser:ChangeWatcher = null;
		private static const _knMaxUpdates:Number = 8;
		private var	_nUpdatesLeft:Number = _knMaxUpdates;
		private var _tmrAdRefresh:Timer = new Timer(1000 * 60 * 3);

		private var _fUpgradeShowing:Boolean = false;
		
		public static function GetInstance(): AdManager {
			if (_am == null) _am = new AdManager();
			return _am;
		}
		
		protected function CallJS(strFunction:String): void {
			try {
				ExternalInterface.call(strFunction);
			} catch (e:Error) {
				// Ignore
			}
		}
		
		public function AdManager()
		{
			_tmrAdRefresh.addEventListener(TimerEvent.TIMER, OnTimer);
			_tmrAnimate.addEventListener(TimerEvent.TIMER, timerHandler);
			
			/*
			var abOptions:Array = new Array(100);
			abOptions[0] = 'WithoutAds';
			for (var i:int = 1; i < 99; i++) {
				abOptions[i] = 'WithAds';	
			}
			ABTest.kobAdTest.options = abOptions;
			ABTest.Activate(ABTest.kobAdTest, "Initialize");
			*/
		}
		
		protected function OnTimer(evt:Event=null): void {
			// steveler 2010-05-10 Ads are now turned off for all users
//			if (_fBannerAdsOn && _nUpdatesLeft  > 0) {
//					_nUpdatesLeft -= 1;
//					LoadNewAd();
//				}
		}
		
		private var _fHidingAdsForUpgrade:Boolean = false;
		
		public function OnUpgradeWindowShow(): void {
			// steveler 2010-05-10 Ads are now turned off for all users
//			if (_fUpgradeShowing) return;
//			_fUpgradeShowing = true;
//			
//			if (!_fBannerAdsOn) return;
//			
//			if (Application.application.height <= 490) {
//				_fHidingAdsForUpgrade = true;
//				UpdateAdState();
//			} else {
//				_fHidingAdsForUpgrade = false;
//				CallJS("loadLeaderboardUpgrading");
//			}
		}

		public function OnUpgradeWindowHide(): void {
			// steveler 2010-05-10 Ads are now turned off for all users
//			if (!_fUpgradeShowing) return;
//			_fUpgradeShowing = false;
//			
//			if (_fHidingAdsForUpgrade) {
//				_fHidingAdsForUpgrade = false;
//				UpdateAdState();
//			} else {
//				_dateLastAd = new Date(_dateLastAd.getTime() - _knWaitTime); // Go back in time to force a reload
//				LoadNewAd();
//			}
		}
		
		public function LoadNewAd():void {
			// steveler 2010-05-10 Ads are now turned off for all users
//			if (!_fBannerAdsOn) return;
//			if (_fUpgradeShowing) return;
//			
//			var dateNow:Date = new Date();
//			if ((dateNow.getTime() - _dateLastAd.getTime()) < _knWaitTime)
//				return;
//				
//			_dateLastAd = dateNow;
//			try {
//				ExternalInterface.call("SetAdAttrs", GetGAMAttrs(), GetBTAttrs());
//				ExternalInterface.call("loadLeaderboardAd");
//			} catch (e:Error) {
//				// Ignore
//				// log?
//			}
		}
		
		/*
		 * Return a list of GAM Attributes used for targeting ads
		 */
		// steveler 2010-05-10 Ads are now turned off for all users
//		public function GetGAMAttrs():Object {
//			var o:Object = new Object();
//			var strApiHost:String = PicnikBase.app.AsService().GetServiceName();
//			if (!strApiHost)
//				strApiHost = "direct";
//			o.src = strApiHost;
//			return o;
//		}
		
		/*
		 * Return a list of behavioral traget attributes. These are sometimes used within ad tags.
		 */
		// steveler 2010-05-10 Ads are now turned off for all users
//		public function GetBTAttrs():Object {
//			var o:Object = new Object();
//			return o;
//		}

		// steveler 2010-05-10 Ads are now turned off for all users
//		private function OnActivate(evt:Event): void {
//			_nUpdatesLeft = _knMaxUpdates;
//			//trace('admgr:activate');
//		}

		// steveler 2010-05-10 Ads are now turned off for all users
//		private function OnDeactivate(evt:Event): void {
//			_nUpdatesLeft = 0;
//			//trace('admgr:deactivate');
//		}
		
		public function Init(fHideBannerAds:Boolean): void {
			// steveler 2010-05-10 Ads are now turned off for all users
//			_fHideBannerAds = fHideBannerAds;
//			_cwIsPaid = ChangeWatcher.watch(AccountMgr.GetInstance(), "isPremium", UpdateAdState);
//			_cwNewUser = ChangeWatcher.watch(AccountMgr.GetInstance(), "userId", UpdateTestStatus);
//			UpdateAdState();
		}
		
		public function PrepareForFullScreenAd(): void {
			// steveler 2010-05-10 Ads are now turned off for all users
//			CallJS("prepareForFullScreenAd");
		}
		
		public function LoadFullscreenAd(): void {
			// steveler 2010-05-10 Ads are now turned off for all users
//			CallJS("loadFullScreenAd");
		}

		public function ShowFullscreenAd(): void {
			// steveler 2010-05-10 Ads are now turned off for all users
//			if (!_fFullscreenShowing) {
//				CallJS("showFullScreenAd");
//				_fFullscreenShowing = true;
//			}
		}
		
		public function HideFullscreenAd(): void {
			// steveler 2010-05-10 Ads are now turned off for all users
//			CallJS("hideFullScreenAd");
		}
		
		public function animateAd(fShow:Boolean): void {
			// steveler 2010-05-10 Ads are now turned off for all users
//			_nStart = getTimer();
//			_fShowAds = fShow;
//			_tmrAnimate.start();
//			UIComponent.suspendBackgroundProcessing();
		}
		
		 private function timerHandler(e:TimerEvent):void {
			// steveler 2010-05-10 Ads are now turned off for all users
//		 	var nTop:int = _nTopDiff;
//		 	var nWidth:int = _nWidthDiff;
//		 	var n:Number = getTimer() - _nStart;
//			
//			if (n > _knMaxAnimationTime)
//			{	
//		 		_tmrAnimate.stop();
//				n = _knMaxAnimationTime;
//				UIComponent.resumeBackgroundProcessing();		 		
//			}
//			
// 			nTop = mx.effects.easing.Exponential.easeIn(n, 0, _nTopDiff, _knMaxAnimationTime);
// 			//trace('height in diff: ' + _nTopDiff + "pos: " + nTop + " time: " + n);
//		 		
// 			nWidth = mx.effects.easing.Exponential.easeIn(n, 0, _nWidthDiff, _knMaxAnimationTime);
// 			//trace('width in diff: ' + _nWidthDiff + "pos: " + nTop + " time: " + n);
//
//			// when ads come on, top moves down, width moves left.
//			if (_fBannerAdsOn) {
//				nWidth = _nWidthActual - nWidth;
//				nTop += _nTopActual;
//			} else {
//				nTop = _nTopTarget + (_nTopActual - nTop);
//				nWidth += _nWidthActual;
//			}
//
//			try {
//		 		ExternalInterface.call("movePicnik", nTop, nWidth);
//			} catch (e:Error) {
//				// Ignore
//			}	
		}
		
		public function UpdateTestStatus(evt:Event = null):void {
			// ABTest.Activate(ABTest.kobAdTest, "NewUser");
		}
		
		// Show a leaderboard if needed
		public function UpdateAdState(evt:Event=null): void {
			// steveler 2010-05-10 Ads are now turned off for all users
			
//			var fnLater:Function = function(): void {
//				var fShowBannerAds:Boolean = !_fHideBannerAds && !_fHidingAdsForUpgrade;
//				if (AccountMgr.GetInstance().isPremium) {
//					fShowBannerAds = false;
//				}
//
//				//AB test
//				//if (fShowBannerAds && ABTest.GetBucket(ABTest.kobAdTest) == "WithoutAds") {
//				//	fShowBannerAds = false;			
//				//}
//
//				_fBannerAdsOn = fShowBannerAds;
//
//				if (_fBannerAdsOn) {
//					_tmrAdRefresh.start();
//					try {
//						ExternalInterface.call("SetAdAttrs", GetGAMAttrs(), GetBTAttrs());
//					} catch (e:Error) {
//						// Ignore
//					}
//				} else {	
//					_tmrAdRefresh.stop();
//				}
//				
//				try {
//					var aswfdims:Array = ExternalInterface.call("SetAdState", fShowBannerAds);
//				} catch (e:Error) {
//					// Ignore
//				}
//				
//				// look out for silent javascript failure					
//				if (!aswfdims || aswfdims.length < 4) {
//					//trace('js silent failure');
//					return;
//				}
//				/*
//				 * 0:Top Target
//				 * 1:Width Target
//				 * 2:Top Actual
//				 * 3:Width Actual
//				 */
//				var nTopStop:int = Math.max(aswfdims[0], aswfdims[2]);
//				var nTopStart:int  = Math.min(aswfdims[0], aswfdims[2]);
//				// Some browsers don't handle the down animation very well. For those cases
//				// we just snap. We still animate up.
//				if (aswfdims[0] > aswfdims[2] || _fHidingAdsForUpgrade) {
//					nTopStart = aswfdims[0];
//					nTopStop = aswfdims[0];			
//									
//					try {
//				 		ExternalInterface.call("movePicnik", aswfdims[0], aswfdims[1]);
//					} catch (e:Error) {
//						// Ignore
//					}	
//				} else {
//					_nTopTarget = aswfdims[0];
//					_nTopDiff = nTopStop - nTopStart;
//					_nTopActual = aswfdims[2];
//									
//					var nWidthStop:int = Math.max(aswfdims[1], aswfdims[3]);
//					var nWidthStart:int = Math.min(aswfdims[1], aswfdims[3]);
//					_nWidthTarget = aswfdims[1];
//					_nWidthDiff = nWidthStop - nWidthStart;
//					_nWidthActual = aswfdims[3];
//					
//					animateAd(true);
//				}
//			}
//			var tmr:Timer = new Timer(1000, 1);
//			tmr.addEventListener(TimerEvent.TIMER,fnLater);
//			tmr.start();
		}
		
		public static const kAdCampaignEvent_OpenPicture:int = 2;
		public static const kAdCampaignEvent_Register:int = 3;
		public static const kAdCampaignEvent_Upgrade1:int = 4;
		public static const kAdCampaignEvent_Upgrade6:int = 5;
		public static const kAdCampaignEvent_Upgrade12:int = 6;
		
		public function LogAdCampaignEvent(nEvent:int): void {		
			// bsharon: disabling ad campaign tracking until it can load cleanly via
			// SSL. we aren't serving ads right now anyway.

			// try {
			// 	var strFloodUrl:String = getFloodlightUrl(nEvent);
			// 	if (strFloodUrl) {
			// 	  	var strRand:String = Math.floor(Math.random() * 100000000) + "?";
		  //  			var strTagUrl:String = strFloodUrl + strRand;
	    // 				var strFloodJs:String = 'f = function() { if (document.getElementById("DCLK_FLDiv")) { var flDiv = document.getElementById("DCLK_FLDiv"); }';
			// 	   	strFloodJs += 'else { var flDiv = document.body.appendChild(document.createElement("div"));';
			// 	   	strFloodJs += 'void(flDiv.id="DCLK_FLDiv"); void(flDiv.style.display = "none"); }';
			// 	   	strFloodJs += 'var DCLK_FLIframe = document.createElement("iframe"); void(DCLK_FLIframe.id = "DCLK_FLIframe_' + Math.floor(Math.random() * 10000) + '");';
			// 	   	strFloodJs += 'void(DCLK_FLIframe.src = "' + strTagUrl + '"); void(flDiv.appendChild(DCLK_FLIframe)); }';
				
			// 	   	if (ExternalInterface.available) {
			// 	  		ExternalInterface.call(strFloodJs);
			// 	   	}
			// 	}
			// } catch (e:Error) {
			// 	trace("Ignoring error in LogAdCampaignEvent: " + e);
			// }
		}
		
		private function getFloodlightUrl( nEvent:int ): String {
			// TODO(bsharon): even if you load these links via https, they will load
			// insecure content, producing errors like:
			//   The page at https://fls.doubleclick.net/activityi;src=2542116...
			//   ran insecure content from http://www.googleadservices.com/pagead/conversion.js.
			switch( nEvent ) {
				case kAdCampaignEvent_OpenPicture:
					return "http://fls.doubleclick.net/activityi;src=2542116;type=conap955;cat=picni568;ord=";
				case kAdCampaignEvent_Register:
					return "http://fls.doubleclick.net/activityi;src=2542116;type=conap955;cat=picni609;ord=1;num=";
				case kAdCampaignEvent_Upgrade1:
					return "http://fls.doubleclick.net/activityi;src=2542116;type=conap955;cat=picni424;ord=1;num=";
				case kAdCampaignEvent_Upgrade6:
					return "http://fls.doubleclick.net/activityi;src=2542116;type=conap955;cat=picni101;ord=1;num=";
				case kAdCampaignEvent_Upgrade12:
					return "http://fls.doubleclick.net/activityi;src=2542116;type=conap955;cat=picni393;ord=1;num=";
			}
			return null;
		}
	}
}


