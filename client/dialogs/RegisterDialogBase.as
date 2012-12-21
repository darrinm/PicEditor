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
	import com.adobe.utils.StringUtil;
	
	import containers.ResizingDialog;
	
	import dialogs.RegisterHelper.ChangePasswordTab;
	import dialogs.RegisterHelper.LostEmailTab;
	import dialogs.RegisterHelper.ForgotPasswordSentTab;
	import dialogs.RegisterHelper.ForgotPasswordTab;
	import dialogs.RegisterHelper.IFormContainer;
	import dialogs.RegisterHelper.LoginTab;
	//import dialogs.RegisterHelper.OrderPayPalTab; steveler 2010-08-18 removed for size
	//import dialogs.RegisterHelper.PaymentSelectorTab;
	import dialogs.RegisterHelper.RegisterBoxBase;
	import dialogs.RegisterHelper.RegisterTab;
	import dialogs.RegisterHelper.SurveyTab;
	import dialogs.RegisterHelper.UpgradePathTracker;
	
	import flash.display.DisplayObject;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	import mx.containers.Canvas;
	import mx.containers.ViewStack;
	import mx.core.Container;
	import mx.core.UIComponent;
	import mx.effects.Fade;
	import mx.events.IndexChangedEvent;
	
	import util.AdManager;
	
	public class RegisterDialogBase extends ResizingDialog implements IFormContainer {
		private static var _dlgRegister:RegisterDialog = null;
		protected var _obAuthResponse:Object = null;

		[Bindable] public var _vstk:ViewStack;
		
		[Bindable] public var _efLongFadeOut:Fade;
		[Bindable] public var _cnvWorking:Canvas;
		
		public static const NO_ACTION:int = 0;
		public static const UPGRADE_PAYMENT_SELECTOR:int = 1;
		public static const UPGRADE_CREDIT:int = 2;
		public static const UPGRADE_PAYPAL:int = 3;
		public static const REDEEM_GIFT:int = 4;
		public static const HELP_HUB:int = 5;
		public var _eRegisterAction:int = NO_ACTION;
		
		private var _fWorking:Boolean = false;
		private var _aPopupStack:Array = [];
		
		public var _strUpgradePath:String = "";
		
		public override function set currentState(strState:String):void {
			// TODO(steveler): remove purchase logic here
			if (strState != "OrderGift" && StringUtil.beginsWith(strState, "Order") && !AccountMgr.GetInstance().hasCredentials) {
				_eRegisterAction = StringUtil.beginsWith(strState, 'OrderPayPal') ? UPGRADE_PAYPAL : UPGRADE_CREDIT;
				strState = "Register";
			}
			if (strState == "RedeemGift" && !AccountMgr.GetInstance().hasCredentials) {
				_eRegisterAction = REDEEM_GIFT;
				strState = "Register";
			}
			
			if (StringUtil.endsWith(strState, "ForUpgrade")) {
				// If we're doing a login-for-upgrade or similar, we don't yet
				// know how they plan to pay
				_eRegisterAction = UPGRADE_PAYMENT_SELECTOR;
			}
			else if (isUpgrading && (strState == "Register" || strState == "ForgotPW" || strState == "Login" || strState == "RedeemGift"))
				strState += "ForUpgrade";
				
			if (StringUtil.endsWith(strState, "ForRedeemGift"))
				_eRegisterAction = REDEEM_GIFT;				
			else if (_eRegisterAction == REDEEM_GIFT && (strState == "Register" || strState == "ForgotPW" || strState == "Login"))
				strState += "ForRedeemGift";

			if (StringUtil.endsWith(strState, "ForHelpHub"))
				_eRegisterAction = HELP_HUB;
			else if (_eRegisterAction == HELP_HUB && (strState == "Register" || strState == "ForgotPW" || strState == "Login"))
				strState += "ForHelpHub";
				

			// a guest user could upgrade to premium, go the create-account dialog,
			// then try to sign in to an existing account.  If they sign into a premium
			// account, the upgrade process is stopped.
			if (isUpgrading && StringUtil.beginsWith(strState, "Order") && AccountMgr.GetInstance().isPaid) {
				Hide();
				return;
			}
			
			if (super.currentState != strState) {
				// if we've already loaded this tab we can get it by name
				var rbx:RegisterBoxBase = _vstk.getChildByName(strState) as RegisterBoxBase;
				// otherwise we'll load the tab and it will be added as child to vstk
				if (rbx == null)
					rbx = loadTab(strState) as RegisterBoxBase;

				super.currentState = strState;
				_vstk.resizeToContent = true;
				if (rbx) {
					_vstk.selectedChild = rbx as Container;
					rbx.OnShow();
				}
			}
		}

		public function get isUpgrading(): Boolean {
			return _eRegisterAction == UPGRADE_CREDIT || _eRegisterAction == UPGRADE_PAYPAL;
		}
	
		
		// IFormContainer implements		
		[Bindable]
		public function get working(): Boolean {
			return _fWorking;
		}
		public function set working(fWorking:Boolean): void {
			if (!fWorking) {
				_efLongFadeOut.alphaFrom = _cnvWorking.alpha;
			}
			_fWorking = fWorking;
		}

		// selects a form for display.  		
		public function SelectForm(strName:String, obDefaults:Object = null ): void {
			currentState = strName;
			var activeForm:RegisterBoxBase = GetActiveForm();
			if (obDefaults && activeForm) {
				for (var key:String in obDefaults) {
					if (key in activeForm) {
						activeForm[key] = obDefaults[key];
					}
				}
			}
		}
		
		public function PushForm( strName:String, obDefaults:Object = null ): void {
			_aPopupStack.push( currentState );
			SelectForm( strName, obDefaults);
		}
				
		public function GetActiveForm(): RegisterBoxBase {
			var rbx:RegisterBoxBase = _vstk.selectedChild as RegisterBoxBase;
			return rbx;			
		}
	
		// Static functions for launching the dialog
		public static function Show(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): RegisterDialog {
			return ShowTab("Register", uicParent, fnComplete, obDefaults);
		}

		public static function ShowForm(strForm:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): RegisterDialog {
			return ShowTab(strForm, uicParent, fnComplete, obDefaults);
		}

		public static function ShowLogin(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): RegisterDialog {		
			return ShowTab("Login", uicParent, fnComplete, obDefaults);
		}				

		public static function ShowLoginForHelpHub(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): RegisterDialog {		
			return ShowTab("LoginForHelpHub", uicParent, fnComplete, obDefaults);
		}				

		public static function ShowDoWeKnowYou(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): RegisterDialog {
			return ShowTab("DoWeKnowYou", uicParent, fnComplete, obDefaults);
		}
		
		public static function ShowLostEmail(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): RegisterDialog {
			return ShowTab("LostEmail", uicParent, fnComplete, obDefaults);
		}

		public static function ShowForgotPW(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): RegisterDialog {
			return ShowTab("ForgotPW", uicParent, fnComplete, obDefaults);
		}
		
		public static function ShowForgotPWReset(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): RegisterDialog {
			return ShowTab("ForgotPWReset", uicParent, fnComplete, obDefaults);
		}
				
		// 2010-08-18 steveler commenting out to reduce swf size
//		public static function ShowSettings(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): RegisterDialog {
//			return ShowTab("Settings", uicParent, fnComplete, obDefaults);
//		}
//				
//		public static function ShowChangePassword(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): RegisterDialog {
//			return ShowTab("ChangePassword", uicParent, fnComplete, obDefaults);
//		}
//		
//		public static function ShowChangeEmail(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): RegisterDialog {
//			return ShowTab("ChangeEmail", uicParent, fnComplete, obDefaults);
//		}
		
		public static function ShowWelcome(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): RegisterDialog {
			return ShowTab("Welcome", uicParent, fnComplete, obDefaults);
		}

		// TODO(steveler): remove receipt tab
//		public static function ShowReceipt(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): RegisterDialog {
//			return ShowTab("Receipt", uicParent, fnComplete, obDefaults);
//		}
//		
		// common function for notifying Urchin about dialogs/tabs being displayed
		private static function UrchinLogReportHelper(strPath:String, strEvent:String): void {
			if (strEvent == null) strEvent = "";
			if (strEvent.length > 0 && strEvent.charAt(0) != '/')
				strEvent = '/' + strEvent;
			strEvent = strPath + strEvent;
			strEvent = StringUtil.replace(strEvent, ' ', '_');
			Util.UrchinLogReport(strEvent);
		}
//		
		// TODO(steveler): delete this
		public static function ShowUpgrade(strSourceEvent:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): void {
			if (AccountMgr.GetInstance().isPaid && !AccountMgr.GetInstance().timeToRenew) {
				return; // Don't show the upgrade dialog to a paid user - unless they are elegible for renewall
			}
			AdManager.GetInstance().OnUpgradeWindowShow();
			
			UrchinLogReportHelper('/upgrade_path', strSourceEvent);
	
			UpgradePathTracker.Init('TargetedUpsell', strSourceEvent);

			if (null == obDefaults) {
				obDefaults = {}
			}
			obDefaults['strSourceEvent'] = strSourceEvent;
			DialogManager.Show( 'TargetedUpsellDialog', uicParent, fnComplete, obDefaults );					
		}
		
		public static function ShowFreeForAllSignIn(strSourceEvent:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): void {
			throw new Error("Commented out");
			// Remove references to 1 billion to reduce code size
			/*
			AdManager.GetInstance().OnUpgradeWindowShow();
			
			UrchinLogReportHelper('/upgrade_path', strSourceEvent);
			
			UpgradePathTracker.Init('TargetedUpsell', strSourceEvent);

			var dlg:FreeForAllSignInDialog = new FreeForAllSignInDialog();
			dlg.SetParams(strSourceEvent, uicParent, fnComplete, obDefaults);
			
			// Undone: Pass the source event? Do something smart here.
			ResizingDialog.Show(dlg, uicParent);
			*/
		}

		// Tabs are states and include: Register, Login, ForgotPW
		private static function ShowTab(strTab:String, uicParent:UIComponent, fnComplete:Function=null, obDefaults:Object=null): RegisterDialog {
			if (_dlgRegister == null) {
				_dlgRegister = new RegisterDialog();
			} else {
				// Reset the dialog state.
				_dlgRegister.ClearErrors();
				_dlgRegister._eRegisterAction = NO_ACTION;
			}
		
			ResizingDialog.Show(_dlgRegister, uicParent);
			_dlgRegister._vstk.addEventListener(IndexChangedEvent.CHANGE, _dlgRegister.OnViewstackChange);
			
			var child:DisplayObject = _dlgRegister._vstk.getChildByName(strTab);
			var rbx:RegisterBoxBase = child as RegisterBoxBase;
			if (rbx) rbx.SetFormDefaults( obDefaults );
			if (fnComplete != null)
				_dlgRegister._fnComplete = fnComplete;
			_dlgRegister.SelectTab( strTab, obDefaults );			
			return _dlgRegister;
		}

		// load tab from childDescriptor. This allows for late loading of tabs
		private function loadTab(strTab:String):Container
		{
	        for (var i:int = 0; i < _vstk.childDescriptors.length; i++) {
				if (_vstk.childDescriptors[i].properties.name == strTab) {
					return _vstk.createComponentFromDescriptor(_vstk.childDescriptors[i], true) as Container;
				}
			}
			return null;
		}


		public function SelectTab(strTab:String, obDefaults:Object=null): void {
			currentState = strTab; 			
			var rbx:RegisterBoxBase = _vstk.selectedChild as RegisterBoxBase;
			//var rbx:RegisterBoxBase = loadTab(strTab) as RegisterBoxBase;
			if (rbx) {
				rbx.OnSelect();
				rbx.SetFormDefaults(obDefaults);
				rbx.registerAction = _eRegisterAction;
			}
		}
				
		public function OnViewstackChange(evt:IndexChangedEvent): void {
			var rbx:RegisterBoxBase = _vstk.selectedChild as RegisterBoxBase;
			if (rbx) {
				rbx.OnSelect();
				if (isUpgrading && StringUtil.endsWith(currentState, "ForUpgrade")) {
					rbx.registerAction = _eRegisterAction;
				}
				if (_eRegisterAction == REDEEM_GIFT && StringUtil.endsWith(currentState, "ForRedeemGift")) {
					rbx.registerAction = _eRegisterAction;
				}
				if (_eRegisterAction == HELP_HUB && StringUtil.endsWith(currentState, "ForHelpHub")) {
					rbx.registerAction = _eRegisterAction;
				}
			}
		}
		
		override protected function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.ESCAPE) {
				var rbx:RegisterBoxBase = _vstk.selectedChild as RegisterBoxBase;
				if (rbx) {
					rbx.OnEscape(evt);
				} else {
					Hide();
				}
			}
		}
		
		public override function Hide(): void {			
			AdManager.GetInstance().OnUpgradeWindowHide();
			UpgradePathTracker.Reset();
			if (_aPopupStack.length > 0) {
				currentState = _aPopupStack.pop();
			} else {
				super.Hide();
			}
		}
		
		override protected function OnHide(): void {
			super.OnHide();
			RegisterDialogBase.ResetValues();
			_vstk.removeEventListener(IndexChangedEvent.CHANGE, OnViewstackChange);
			if (_fnComplete != null) {
				_fnComplete();
				_fnComplete = null;
			}
		}
	
		// Clear out any errors for emtpy fields		
		public function ClearErrors(): void {
			var tabs:Array = _dlgRegister._vstk.getChildren();
			for each ( var tab:Object in tabs ) {
				var rbx:RegisterBoxBase = tab as RegisterBoxBase;
				rbx.ResetValues();
				rbx.ClearErrors();
			}
		}

		// Clear out any values the user has given us
		public static function ResetValues(): void {
			if (_dlgRegister != null) {
				var tabs:Array = _dlgRegister._vstk.getChildren();
				for each ( var tab:Object in tabs ) {
					var rbx:RegisterBoxBase = tab as RegisterBoxBase;
					rbx.ResetValues();
				}
			}			
		}		
		
		public function get viewstack(): ViewStack {
			return _vstk;
		}
	}
}
