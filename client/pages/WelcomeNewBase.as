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
package pages {
	import bridges.mycomputer.MyComputerInBridgeBase;
	
	import containers.ActivatableModuleLoader;
	import containers.RotatingViewStack;
	
	import controls.TextPlus;
	
	import dialogs.DialogManager;
	
	import events.AccountEvent;
	import events.ActiveDocumentEvent;
	import events.LoginEvent;
	
	import flash.events.TextEvent;
	
	import imagine.ImageDocument;
	
	import mx.controls.Button;
	import mx.controls.RadioButton;
	import mx.events.FlexEvent;
	
	import util.UserBucketManager;
	
	public class WelcomeNewBase extends MyComputerInBridgeBase {
		
		[Bindable] public var _vstkSelected:RotatingViewStack;
		[Bindable] public var _vstkTour:RotatingViewStack;
		[Bindable] public var _vstkFeatured:RotatingViewStack;
		[Bindable] public var _vstkSeasonal:RotatingViewStack;
		[Bindable] public var _btnPicnikTour:RadioButton;
		[Bindable] public var _btnFeatured:RadioButton;
		[Bindable] public var _promoBox:RotatingViewStack;
		[Bindable] public var _btnClose:Button;
		[Bindable] protected var _fFirstActivate:Boolean = true;
		[Bindable] public var _strLastEditedMsg:String;
		[Bindable] public var showStartBar:Boolean = true;
		[Bindable] public var _brgYahooMail:ActivatableModuleLoader;
		[Bindable] public var txtRecentUploads:TextPlus;

		function WelcomeNewBase() {
		}

		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount("YahooMail");
			tpa.addEventListener(LoginEvent.CREDENTIALS_CHANGED, OnYahooMailCredentialsChanged);

/* DWM: test was a success!			
			// Only activate the StartBar test for the class of users it is meant to impact
			// (people who have visited less than 3 times).
			if (UserBucketManager.GetCount("visit") <= 2)
				ABTest.Activate(ABTest.kobStartBarTest, "WelcomeInitialize");
*/
			ConditionallyShowStartBar();
		}

		override public function OnActivate(strCmd:String=null):void {
			super.OnActivate(strCmd);
			if (PicnikBase.app.yahoomail && _brgYahooMail != null) {
				// no special login functionality, we just want to do enough to capture
				// whether or not the client connected to the Yahoo Mail bridge while they
				// were over on the Library tab.
				if (_brgYahooMail.active)
					_brgYahooMail.OnDeactivate();
				_brgYahooMail.OnActivate();
			}
				
			if (_fFirstActivate) {
				// make sure the right tab is showing
				OnUserChange(null);
				_fFirstActivate = false;
			}
			
			if (txtRecentUploads != null && txtRecentUploads.visible != AccountMgr.GetInstance().isPaid)
				AccountMgr.GetInstance().DispatchDummyIsPaidChangeEvent();
			
			// tell the promo box to load.
			<!--_promoBox.createComponentsFromDescriptors();-->
		}

		private function OnYahooMailCredentialsChanged(evt:LoginEvent): void {
			ConditionallyShowStartBar();
		}

		// 1. If running inside of Yahoo Mail and not connected to the mail web service, don't show the start bar
		// 2. Otherwise, show the start bar if the user has visited more than twice or is signed in
		private function ConditionallyShowStartBar(): void {
			var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount("YahooMail");
			if (PicnikBase.app.yahoomail && !tpa.HasCredentials()) {
				showStartBar = false;
			} else {
//				if (ABTest.GetBucket(ABTest.kobStartBarTest) == "ConditionalShow")
					showStartBar = UserBucketManager.GetCount("visit") > 2 || !AccountMgr.GetInstance().isGuest;
			}
		}

		protected override function OnUserChange(evt:AccountEvent): void {
			super.OnUserChange(evt);
			ConditionallyShowStartBar();
			// set the default tour here
			SelectViewStack(_vstkFeatured);
		}
		
		public function SelectViewStack(vstk:RotatingViewStack): void {
			if (_vstkSelected) {
				_vstkSelected.visible = false;
				_vstkSelected.includeInLayout = false;
			}
			_vstkSelected = vstk;
			if (_btnPicnikTour) _btnPicnikTour.selected = _vstkSelected == _vstkTour;
			if (_btnFeatured) _btnFeatured.selected = _vstkSelected == _vstkFeatured;
			if (_vstkSelected) {
				_vstkSelected.createComponentsFromDescriptors();
				_vstkSelected.visible = true;
				_vstkSelected.includeInLayout = true;
			}			
		}
		
		override protected function FilterItemList( aitemInfos:Array ): Array {
			// we only want the first 6 (non-premium will only return max 5)
			return aitemInfos.slice( 0, 6 );	
		}
		
		protected function OnManageUploads(evt:TextEvent): void {
			NavigateTo(PicnikBase.IN_BRIDGES_TAB,'_brgMyComputerIn');
		}				
		
		protected function OnUpsell100LearnMore(evt:TextEvent): void {
			DialogManager.ShowUpgrade('/home_welcome/upsell100',PicnikBase.app)
		}				
				
		override protected function set fileListLimit(n:Number): void {
			// we've only got room for 6 boxes, so only ask for that many.
			if (n > 6) n = 6;
			super.fileListLimit = n;
		}		

		override protected function OnActiveDocumentChange(evt:ActiveDocumentEvent): void
		{
			super.OnActiveDocumentChange(evt);
			var strCloseButton:String
			if (doc is GalleryDocument) {
				_strLastEditedMsg = 'show';
				strCloseButton = 'closeGallery';	
			} else if (doc && doc is ImageDocument && (doc as ImageDocument).isCollage) {
				_strLastEditedMsg = 'collage';	
				strCloseButton = 'closeCollage';	
			} else {
				_strLastEditedMsg = 'photo';
				strCloseButton = 'closePhoto';	
			}
			_btnClose.label = Resource.getString('WelcomeNew', strCloseButton);
		}		
	}
}
