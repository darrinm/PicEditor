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
package controls
{
	import containers.TipCanvas;
	
	import dialogs.DialogManager;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	import inspiration.Inspiration;
	import inspiration.InspirationManager;
	import inspiration.InspirationRenderer;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.effects.Fade;
	import mx.events.FlexEvent;
	import mx.managers.ISystemManager;
	import mx.managers.PopUpManager;
	
	import util.GooglePlusUtil;
	import util.RectUtil;

	public class InspirationTipBase extends TipCanvas {
		
		// True if the tip is all on or becoming on
		// False if the tip is hidden or hiding
		[Bindable] public var showing:Boolean = false;
		[Bindable] public var efFadeInOut:Fade;
		
		[Bindable] public var _tr:InspirationRenderer;
		
		[Bindable] public var _nSize:Number = 400;
		
		private var _fPoppedUp:Boolean = false;
		
		private var _ptDragOffset:Point = null;
		private var _inspContent:Inspiration = null;
		
		//DYNAMIC POINTING:
		// private var _fDynamicThumb:Boolean = false;
	
		public var fixedPosition:Boolean = false;

		public function InspirationTipBase(): void {
			_aChildren.pop();
			_tipBg.closeButtonEnabled = false;
			addEventListener(FlexEvent.CREATION_COMPLETE, UpdateInspration);
		}
		
		private var _uicRelative:UIComponent = null;
		private var _nPointAt:Number=-1;
		private var _nPosition:Number;
		private var _nPadding:Number;
		
		public static var inspTip:InspirationTip = null;
		
		public static function HideTip(fFade:Boolean=true): void {
			ClearTimer();
			InspirationTipBase.SetDelayMode(LONG_DELAY, knSwitchToLongDelayModeMs); // Switch to long delay if we don't show again soon.
			if (inspTip && inspTip.showing)
				inspTip.Hide(fFade);
		}
		
		////// TUNING //////
		public static const LONG_DELAY:Number = 1500;
		public static const SHORT_DELAY:Number = 0;
		public static const knSwitchToLongDelayModeMs:Number = 750;
		private static var _nDelayMs:Number = SHORT_DELAY;
		
		private static var _tmrShow:Timer = null;
		private static var _tmrUpdateDelayMode:Timer = null;
		private static var _aobShowParams:Array = null;
		
		private static var _nNewDelayMs:Number = LONG_DELAY;
		
		public static function OnSubTabActivate(): void {
			SetDelayMode(SHORT_DELAY);
		}
		
		public static function SetDelayMode(nDelayMs:Number, nDelayToSetMs:Number=0): void {
			if (_tmrUpdateDelayMode != null)
				_tmrUpdateDelayMode.reset();
			else {
				_tmrUpdateDelayMode = new Timer(1000, 1);
				_tmrUpdateDelayMode.addEventListener(TimerEvent.TIMER_COMPLETE, function(evt:TimerEvent): void {
					_nDelayMs = _nNewDelayMs;
				});
			}

			if (nDelayToSetMs <= 0) {
				_nDelayMs = nDelayMs;
			} else {
				_nNewDelayMs = nDelayMs;
				_tmrUpdateDelayMode.delay = nDelayToSetMs;
				_tmrUpdateDelayMode.start();
			}
		}
		
		private static function ClearTimer(): void {
			if (_tmrShow != null)
				_tmrShow.reset();
			_aobShowParams = null;
		}
		
		// Takes delay into account.
		// If delay is zero, shows the inspiration. If delay is not zero, starts the count-down to show inspiration.
		public static function ShowInspiration(insp:Inspiration, uicRelative:UIComponent=null, nPointAt:Number=9, nPosition:Number=RectUtil.RIGHT, nPadding:Number=10): void {
			if (!insp)
				return;
			// Turn off inspiration for Google Plus
			if (PicnikBase.app._pas.googlePlusUI)
				return;
			_aobShowParams = [insp, uicRelative, nPointAt, nPosition, nPadding];
			if (_nDelayMs <= 0) {
				ShowUsingParams();
			} else {
				// Delayed show
				ShowAfterDelay(_nDelayMs);
			}
		}
		
		private static function ShowAfterDelay(nDelayMs:Number): void {
			if (_tmrShow != null) {
				_tmrShow.reset();
				_tmrShow.delay = nDelayMs;
			} else {
				_tmrShow = new Timer(nDelayMs, 1);
				_tmrShow.addEventListener(TimerEvent.TIMER_COMPLETE, ShowUsingParams);
			}
			_tmrShow.start();
		}
		
		private static function ShowUsingParams(evt:TimerEvent=null): void {
			if (_aobShowParams == null)
				throw new Error("No params");
			ShowInpsirationNow.apply(null, _aobShowParams);
			_aobShowParams = null;
		}
		
		// Show inspiration now. Ignores any delays.
		public static function ShowInpsirationNow(insp:Inspiration, uicRelative:UIComponent=null, nPointAt:Number=9, nPosition:Number=RectUtil.RIGHT, nPadding:Number=10): void {
			if (!insp)
				return;
			// Turn off inspiration for Google Plus
			if (PicnikBase.app._pas.googlePlusUI)
				return;
			if (inspTip == null)
				inspTip = new InspirationTip();
			inspTip._Show(insp, uicRelative, nPointAt, nPosition, nPadding);
			InspirationTipBase.SetDelayMode(SHORT_DELAY, 0); // Switch to instant
		}
		
		public static function ShowInspirationByTag(strTag:String, uicRelative:UIComponent=null, nPointAt:Number=9, nPosition:Number=RectUtil.RIGHT, nPadding:Number=10): void {
			InspirationTipBase.ShowInspiration(InspirationManager.inst.GetInspiration(strTag), uicRelative, nPointAt, nPosition, nPadding);
		}
		
		public static function ShowInspirationByTagNow(strTag:String, uicRelative:UIComponent=null, nPointAt:Number=9, nPosition:Number=RectUtil.RIGHT, nPadding:Number=10): void {
			InspirationTipBase.ShowInpsirationNow(InspirationManager.inst.GetInspiration(strTag), uicRelative, nPointAt, nPosition, nPadding);
		}
		
		private function _Show(insp:Inspiration, uicRelative:UIComponent, nPointAt:Number, nPosition:Number, nPadding:Number): void {
			if (insp == null) {
				Hide();
				return;
			}
			
			// If it is visible
			if (!showing) {
				content = insp;
				_uicRelative = uicRelative;
				_nPointAt = nPointAt;
				_nPosition = nPosition;
				_nPadding = nPadding;

				// Don't position the tip until its creation is complete
				addEventListener(FlexEvent.CREATION_COMPLETE, RepositionTip);
				
				// This tip might resize vertically when its child TipRenderer parses the xml content
				addEventListener(Event.RESIZE, RepositionTip);
			
				showing = true;
				DoFade(1);
				AddPopup();
			}
			RepositionTip();
		}

		public function Hide(fFade:Boolean=true): void {
			if (showing) {
				showing = false;
				content = null;
				if (fFade)
					DoFade(0);
				else
					RemovePopup();
			}
		}
		
		[Bindable]
		public function set content(insp:Inspiration): void {
			_inspContent = insp;
			UpdateInspration();
		}
		
		public function get content(): Inspiration {
			return _inspContent;
		}
		
		private function UpdateInspration(evt:Event=null): void {
			if (_tr != null && _tr.inspiration != content)
				_tr.inspiration = content;
		}
		
		private function OnClose(evt:Event=null): void {
			Hide();
		}
		
		private function DoFade(nToAlpha:Number): void {
			var nFadeFrom:Number = alpha;
			endEffectsStarted();
			efFadeInOut.alphaFrom = nFadeFrom;
			efFadeInOut.alphaTo = nToAlpha;
			efFadeInOut.play();
		}
		
		protected function OnFadeFinished(): void {
			if (!showing) {
				RemovePopup();
			}
		}
		
		private function AddPopup(): void {
			if (!_fPoppedUp) PopUpManager.addPopUp(this, PicnikBase.app, false);
			_fPoppedUp = true;
		}
		
		private function RemovePopup(): void {
			if (_fPoppedUp) PopUpManager.removePopUp(this);
			_fPoppedUp = false;
		}
		
		public function PointThumbAt(uic:UIComponent): void {
			_tipBg.PointThumbAtUIC(uic);
		}
		
		public function RepositionTip(evt:Event=null): void {
			// Is it too early?
			if (content == null)
				return;
			
			if (_tr == null)
				return;
			
			PositionTipWithParams(_uicRelative, _nPointAt != -1, _nPointAt, _nPosition, _nPadding);
		}
		
		private function PositionTipWithParams(uicRelative:UIComponent, fPointAt:Boolean, nPointAtPadding:Number, nPosition:Number, nPadding:Number): void {
			var aobConstraints:Array = [];
			// These are all stage coordinates
	
			var pt:Point;
			var rcNear:Rectangle;
			
			// First, it must be on the app
			var rcApp:Rectangle = new Rectangle(0,0,PicnikBase.app.width,PicnikBase.app.height);
			aobConstraints.push({ rcInside: rcApp });

			// Try to stay off the sub-tabs
			var nHeaderHeight:Number = 97;
			if (uicRelative)
				nHeaderHeight = Math.min(nHeaderHeight, uicRelative.localToGlobal(new Point(uicRelative.height, 0)).y);
			var rcView:Rectangle = rcApp.clone();
			rcView.height -= nHeaderHeight;
			rcView.y = nHeaderHeight;
			aobConstraints.push({ rcInside: rcView} );
			
			var obConstraints:Object = {};

			var obPadding:Object = null;
			
			// Position it as specified in the tip XML
			if (nPosition != RectUtil.CENTER) {
				obConstraints.prefer = nPosition;
				
				obPadding = {};
				obPadding[nPosition] = nPadding;
			}
			// Walk the UIComponent hierarchy to find the UIComponent with the relativeTo or pointAt id
			if (uicRelative) {
				// in some weird instances (currently, tip #4/7 for Show) the width and height
				// of uicRelative will be seen as 800,000 pixels larger than they should be.  So, we
				// convert to stage coordinates manually.
				//var rc:Rectangle = uicRelative.getBounds(stage);
				var p1:Point = uicRelative.localToGlobal(new Point(0, 0));
				var p2:Point = uicRelative.localToGlobal(new Point(uicRelative.width, uicRelative.height));
				var rc:Rectangle = new Rectangle( p1.x, p1.y, p2.x - p1.x, p2.y - p1.y );
				if (nPointAtPadding > 0)
					rc.inflate(nPointAtPadding * 2, nPointAtPadding * 2);
				if (nPosition == RectUtil.CENTER) {
					obConstraints.rcInside = RectUtil.ApplyPadding(rc, obPadding, false);
				} else {
					obConstraints.rcOutside = RectUtil.ApplyPadding(rc, obPadding, true);
				}
				if (fPointAt) {
					// Point at the pointAt component
					obConstraints.rcPointAt = RectUtil.ApplyPadding(rc, obPadding, true);
				} 
			} else {
				// Center within the app by default
				obConstraints.rcInside = new Rectangle(0, 0, rcApp.width, rcApp.height);
			}
			aobConstraints.push(obConstraints);
			
			pt = RectUtil.PlaceRect(aobConstraints, new Point(width, height));
			
			if (!fixedPosition) {
				x = Math.round(pt.x);
				y = Math.round(pt.y);
			}
			
			if (uicRelative && fPointAt)
				_tipBg.PointThumbAtUIC(uicRelative);
			
			validateNow();
		}
	}
}
