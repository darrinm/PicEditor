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
	import controls.Tip;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import imagine.ImageDocument;
	import imagine.documentObjects.Photo;
	
	import mx.core.Application;

	public class PhotoBasketVisibility
	{
		// This class has to do with making the layering feature more prominent. We
		// are tinkering with different strategies for doing so, so this is somewhat more
		// complex than it seems like it should be. The general notion is that we have a
		// current strategy (_currentStrategy) we are trying, and
		// a state describing what we have tried. The three states [currently] are:
		//     NONE         we could have tried something but chose not to. Either this
		//                  user has already seen it or we chose to leave it as is for
		//                  experimental purposes
		//     MAXIMIZE         we open / maximize the basket at the first layering opportunity
		// This is the database attribute name where we store which strategy the user has
		// most recently seen.
		private static const USER_STRATEGY_SEEN_ATTR_NAME:String = "photobasket.VisibilityStrategySeen";
		
		// Enums for the different strategies. Note that NONE is an explicit strategy, this is important for
		// the state machine and logging
		public static const STRATEGY_NONE:int = 0;      // leave the feature as is, the basket starts out minimized
		public static const STRATEGY_MAXIMIZE:int = 1;  // maximize at the first opportunity
		
		// The strategy we are currently using in production. Someday this may be a dynamic variable, perhaps even
		// tailored per user.
		private static var _currentStrategy:int = STRATEGY_MAXIMIZE;
		
		// Have we done the check yet? These functions are called a bunch as the user tabs around, so we
		// avoid asking the question repeatedly.
		private static var _strategyCheckDone:Boolean = false;
		
		// What we decided to do when (if) the opportunity arose to apply a strategy
		private static var _strategyAppliedThisSession:int = STRATEGY_NONE;
		
		private static var _activeTip:Tip;
		private static var _tipShownAlready:Boolean = false;
		
		public static function GetStrategy(): int {
			// We only want to apply these strategies (for now) when in layering contexts. Thus we make
			// sure we are in one of the editing modes and not collages and such. Note that we do not set the
			// _checkDone flag, because we haven't done it in the layering context yet.
			if (Application.application.uimode != PicnikBase.kuimPhotoEdit) {
				return STRATEGY_NONE;
			}
			
			if (_strategyCheckDone) {
				return STRATEGY_NONE;
			}
			
			_strategyCheckDone = true;
			
			// this is our first opportunity this session to try our strategy. We decide now
			// whether and how to do that. Note that we treat "none" as an actual forced technique, this
			// lets us see that the user was in a situation where we *could* have forced visibility.
			// This lets us distinguish users who could have used the basket but chose not to from those
			// who were doing other sorts of things.
			var am:AccountMgr = AccountMgr.GetInstance();
			var userSeenStrategy:int = am.GetUserAttribute(USER_STRATEGY_SEEN_ATTR_NAME, -1);
			if (userSeenStrategy < _currentStrategy) {
				_strategyAppliedThisSession = _currentStrategy;
				am.SetUserAttribute(USER_STRATEGY_SEEN_ATTR_NAME, _currentStrategy)
				return _currentStrategy;
			} else {
				return STRATEGY_NONE;
			}
		}
		
		private static function ReportUserAction(action:String): void {
			var appliedStrategy:String;
			if (_strategyCheckDone) {
				appliedStrategy = "/strategy_" + _strategyAppliedThisSession;
			} else {
				appliedStrategy = "/strategy_no_opportunity";
			}
			
			var userSeen:String = "/userseen_" + AccountMgr.GetInstance().GetUserAttribute(USER_STRATEGY_SEEN_ATTR_NAME, 0);
			// Results in a report like /photobasket/clickedopen/layer/visibility_strategy_1/history_1
			Util.UrchinLogReport("/photobasket/" + action + appliedStrategy + userSeen);
		}
		
		public static function ReportDragDrop(): void {
			if (Application.application.uimode == PicnikBase.kuimPhotoEdit)
			{
				ReportUserAction("dragdrop");
			}
		}
		
		public static function ReportToggle(opened:Boolean): void {
			if (Application.application.uimode == PicnikBase.kuimPhotoEdit)
			{
				ReportUserAction(opened ? "clickedopen" : "clickedclose");
				if (opened) {
					ShowTip();
				} else {
					HideTip();
				}
			}
		}
		
		public static function ReportSave(imgd:ImageDocument): void {
			// Report a multi-layer image save even if we are not in "edit" mode.
			
			// Look for a photo child in the document. If there is one, this is a layer (surprisingly
			// not the background image itself). If there is one, log that fact.
			for (var i:int = 0; i < imgd.documentObjects.numChildren; i++) {
				var dob:DisplayObject = imgd.documentObjects.getChildAt(i);
				if (dob is Photo) {
					ReportUserAction("saved");
					return; // only need to do this once. :)
				}
			}
		}
		
		private static function ShowTip(): void {
			if (!_tipShownAlready) {
				_tipShownAlready = true;
				_activeTip = TipManager.ShowTip("photobasket_dragdrop");
				if (_activeTip != null) {
					_activeTip.addEventListener(Event.REMOVED, OnTipHide);
				}
			}
		}
		
		public static function HideTip(): void {
			if (_activeTip != null) {
				TipManager.HideTip(_activeTip.id, false, false); // don't fade out the tip
			}
		}
		
		private static function OnTipHide(evt:Event): void {
			// Distinguish between the REMOVED event we care about and bubbled up events
			if (evt.target != _activeTip)
				return;
			
			if (_activeTip) {
				_activeTip.removeEventListener(Event.REMOVED, OnTipHide);
				_activeTip = null;
			}
		}
	}
}
