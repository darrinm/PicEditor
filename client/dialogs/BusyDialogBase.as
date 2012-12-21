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
package dialogs {
	import containers.Dialog;
	
	import flash.events.Event;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import mx.controls.Label;
	import mx.controls.ProgressBar;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	
	public class BusyDialogBase extends Dialog implements IBusyDialog {
		// MXML-specified variables
		[Bindable] public var _pb:ProgressBar;
		[Bindable] public var _lbPercent:Label;
		[Bindable] public var _lbStatus:Label;
		
		[Bindable] protected var encourageFlashUpgrade:Boolean = false;
		
		// Busy dialog types (used for determining whether or not we show ads)
		
		// One through 99 are things we want to through ads on
		public static const LOAD_USER_IMAGE:Number = 1; // Excludes service calls
		public static const SAVE_USER_IMAGE:Number = 2; // Excludes service calls
		public static const LOAD_WEBCAM_IMAGE:Number = 3;
		public static const PUBLISH_GALLERY:Number = 4;
		
		public static const AD_ACTION:Number = 99;
		
		// 100+ are events we don't want ads on
		public static const SERVICE_LOAD:Number = 103;
		public static const IMPORT_LOAD:Number = 104;
		public static const SERVICE_EXPORT:Number = 105;
		public static const RESTORE:Number = 106; // restoring app state
		public static const EMAIL:Number = 107;
		public static const LOAD_SAMPLE_IMAGE:Number = 108;
		public static const DELETE:Number = 109;
		public static const RENAME:Number = 110;
		public static const SAVE_GREETING_IMAGE:Number = 111;

		public static const OTHER:Number = 200;
		
		private var _strDesiredState:String;
		private var _strStatus:String;
		private var _fFirstProgress:Boolean = true;
		private var _msStart:Number;
		private var _nTimerId:uint = 0;
		private var _nIntervalId:uint = 0;
		private var _nActualProgress:Number = 0;
		private var _nDisplayProgress:Number = 0;
		private var _nFirstProgress:Number = 0;
		private var _nProgressIntervals:Number = 0;
		private var _aRunningAvg:Array = [];
		private var _isShowCalled:Boolean = false;
		private var _isHideCalled:Boolean = false;
		

		private static const knShowAdEvery:Number = 2; // Show an ad every X times we load/save
		private static var _nTimesToShowAd:Number = 2; // Show an add on the first Xtm time we load/save
		
		private static var _fFullScreenAdsDisabled:Boolean = false;

		public static function DisableFullscreenAds(): void {
			_fFullScreenAdsDisabled = true;
		}
		
		private static function WantsAds(nType:Number): Boolean {
			return false; // All interstitial ads off
			
			if (_fFullScreenAdsDisabled) return false;
			
			if (AccountMgr.GetInstance().isPremium) {
				return false;
			}
			
			if (nType <= AD_ACTION) {
				_nTimesToShowAd -= 1;
				if (_nTimesToShowAd <= 0) {
					_nTimesToShowAd = knShowAdEvery;
					return true;
				}
			}
			return false;
		}
		
		// PORT: msShowDelay
		public static function Show(uicParent:UIComponent, strStatus:String, nType:Number,
				strState:String="", msShowDelay:Number=0.5, fnComplete:Function=null): IBusyDialog {
			
			// Commenting out so that BusyHeader dialog gets excluded from build
			// var fAds:Boolean = WantsAds(nType);
			//if (nType == LOAD_USER_IMAGE && !Util.FlashVersionIsAtLeast([10,0,0,0]) && strState == "ProgressWithCancel" && !fAds)
			
			if (nType == LOAD_USER_IMAGE && !Util.FlashVersionIsAtLeast([10,0,0,0]) && strState == "ProgressWithCancel")
				strState = "ProgressWithCancelAndFlashUpgradeText"
			
			// Commenting out so that BusyHeader dialog gets excluded from build
			//var dlg:IBusyDialog;
			//if (fAds) {
			//	dlg = new BusyHeader(); // UNDONE: Use the ad header version
			//} else {
			//	dlg = new BusyDialog();
			//}
					
			var dlg:IBusyDialog = new BusyDialog();
			
			// PORT: use the cool varargs way to relay these params
			dlg.Constructor(uicParent, strStatus, strState, msShowDelay, fnComplete);			

			return dlg;
		}
		
		public function Position(): void {
			mx.managers.PopUpManager.centerPopUp(this);
		}
		
		// This is here because constructor arguments can't be passed to MXML-generated classes
	    public function Constructor(uicParent:UIComponent, strStatus:String, strState:String, msShowDelay:Number, fnComplete:Function): void {
			_fnComplete = fnComplete;
			_strDesiredState = strState;
			_strStatus = strStatus;
			if (msShowDelay > 0.5) {
				setTimeout( function():void {
						Show(uicParent) },
					msShowDelay );				
			} else {
				Show(uicParent);
			}
		}
	
		override protected function OnInitialize(evt:Event): void {
			super.OnInitialize(evt);
			_lbStatus.text = _strStatus;
			_msStart = getTimer();
			if (_strDesiredState == "IndeterminateNoCancel")
				currentState = _strDesiredState;
		}
		
		override public function Hide():void {
			_isHideCalled = true;
			if (_nIntervalId) {
				clearInterval(_nIntervalId);
				_nIntervalId = 0;
			}			
			if (_isShowCalled) super.Hide();
		}

		// Show the dialog centered over the passed in uicParent and modal
		override public function Show(uicParent:UIComponent, strTopic:String=null): void {
			_isShowCalled = true;
			if (!_isHideCalled) super.Show( uicParent, strTopic );
		}
		
		public function set progress(nPercent:Number): void {
			if (_pb == null)
				return;
				
			if (_fFirstProgress && nPercent > 0) {
				_fFirstProgress = false;

				// Make sure the initial state has some hang time by delaying the onset of
				// any state transition for 1/3 of a second.
				if (currentState != _strDesiredState)
					_nTimerId = setTimeout(OnStartTimeout, Math.min(getTimer() - _msStart, 333));
				
				// Set up an interval to animate the progress bar smoothly every 100 ms
				_nIntervalId = setInterval( OnProgressInterval, 100 );
				_nDisplayProgress = 0;
				_nProgressIntervals = 0;
				_nFirstProgress = nPercent;
				_aRunningAvg = [];
			}			
			if (nPercent == 100) {
				// we're done!  Jump to 100% right away.
				DisplayProgress( 100 );
			} else {
				// store this value for later animation in OnProgressInterval
				// scale it to map 0..(100-first) to 0..100
				_nActualProgress = (nPercent - _nFirstProgress) * 100 / (100-_nFirstProgress);
			}
		}
		
		public function OnProgressInterval():void {
			// This function smoothly animates the progress bar.
			// It assumes it'll get called about 10 times/second			
			
			_nProgressIntervals++;
			
			if (_aRunningAvg.push( _nActualProgress ) > 30)
				_aRunningAvg.shift(); // remove first element
				
			var nRecentRate:Number = (_aRunningAvg[_aRunningAvg.length-1] - _aRunningAvg[0]) / 30;
			
			// if we're falling behind (or getting ahead) make some
			// adjustments to the required rate.  We divide by some constant tp
			// smear this number adjustment across several frames
			nRecentRate += (_nActualProgress - _nDisplayProgress) / 10;

			// Make sure the slider always goes forwards!
			if (nRecentRate < 0 ) nRecentRate = 0;
			
			// update the display!
			_nDisplayProgress += nRecentRate;			
			DisplayProgress( _nDisplayProgress );
		}
		
		private function DisplayProgress(n:Number):void {
			// This function changes what is being displayed.
			// It maps the percent progress to a curve so that there's an
			// acceleration of the progress towards the end.
			
			// cap between 0 and 100
			n = isNaN(n) ? 0 : n;
			n = n < 0 ? 0 : n;
			n = n > 100 ? 100 : n;
			
			// stop animating at 100
			if (n == 100 && _nIntervalId) {
				clearInterval(_nIntervalId);
				_nIntervalId = 0;
			}
			
			// exponentify the progress to give it a curve.
			// mix it with an even slope to give more consistent
			// early movement and reduce the late acceleration
			var nToSet:Number =  n*n/100 * 0.25 + n * 0.75;
			//trace ( "actual: " + _nActualProgress + "; calc mapped " + n + " to " + nToSet );
			_pb.setProgress(nToSet, 100);
			_lbPercent.text = Math.round(nToSet - (nToSet % 5)) + "%";
		}
		
		// Dialog.Hide() makes sure transition gets to finish playing before the dialog is hidden.
		private function OnStartTimeout(): void {
			if (currentState != _strDesiredState)
				currentState = _strDesiredState;
			clearTimeout( _nTimerId );				
		}
		
		public function get progress(): Number {
			return _pb.percentComplete;
		}
		
		public function set message(strMessage:String): void {
			if (_lbStatus != null)
				_lbStatus.text = strMessage;
		}
		
		public function get message(): String {
			if (_lbStatus == null)
				return null;
			return _lbStatus.text;
		}
		
		public function get isDone(): Boolean {
			return _isHideCalled;
		}
	}
}
