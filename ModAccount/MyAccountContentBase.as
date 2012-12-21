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
package {
	import api.RpcResponse;
	
	import commands.CommandEvent;
	import commands.CommandMgr;
	
	import containers.PaletteWindow;
	
	import creativeTools.ICreativeTool;
	
	import dialogs.BusyDialogBase;
	import dialogs.DialogManager;
	import dialogs.IBusyDialog;
	import dialogs.Purchase.PurchaseManager;
	import dialogs.Purchase.SubscriptionStatus;
	
	import events.*;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.containers.Canvas;
	import mx.containers.ViewStack;
	import mx.controls.Button;
	import mx.controls.Text;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.events.IndexChangedEvent;
	
	import pages.Page;
	
	import util.CreditCard;
	import util.CreditCardTransaction;
	import util.FontManager;
	import util.ITabContainer;
	
	public class MyAccountContentBase extends Page {
		// MXML-defined variables
		[Bindable] public var subscriptionStatus:SubscriptionStatus;
		[Bindable] public var subscriptionInitialized:Boolean = false;
		
		private var _cwSubscription:ChangeWatcher;
		private var _bsy:IBusyDialog;
		
		//
		// Initialization (not including state restoration)
		//
		public function MyAccountContentBase() {
			super();
			subscriptionStatus = SubscriptionStatus.GetInstance();
		}		
		
		//
		// IActivatable implementation
		//
		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
			AccountMgr.GetInstance().addEventListener(AccountEvent.USER_CHANGE, OnUserChange);
			_cwSubscription = ChangeWatcher.watch(AccountMgr.GetInstance(), 'dateSubscriptionExpires', function(evt:Event): void {
				// Reset our state when the user upgrades or signs in/out
				SubscriptionStatus.Refresh();
			});
			subscriptionInitialized = false;
			SubscriptionStatus.Refresh(function(fSuccess:Boolean): void {
				subscriptionInitialized = true;
			});
			
			AccountMgr.GetInstance().SetUserAttribute("hasSeenNewMyAccount", true);			
		}
				
		override public function OnDeactivate(): void {
			super.OnDeactivate();
			AccountMgr.GetInstance().removeEventListener(AccountEvent.USER_CHANGE, OnUserChange);
			_cwSubscription.unwatch();
		}
		
		protected function MembershipStyle(strSkuId:String): String {
			var strStyle:String = "";
			switch (strSkuId) {
				case CreditCardTransaction.kSku12Months:
					strStyle = "12";
					break;
				case CreditCardTransaction.kSkuSixMonths:
					strStyle = "6";
					break;
				case CreditCardTransaction.kSkuOneMonth:
					strStyle = "1";
					break;
				default:
					strStyle = "";
					break;
			}
			return strStyle;
		}
		
		private function OnUserChange(evt:AccountEvent): void {
			SubscriptionStatus.Refresh();
		}
		
		private function _Refresh(obResult:Object=null): void {
			SubscriptionStatus.Refresh();
		}
		
		private function _ShowMembershipDialog(): void {
			if (AccountMgr.GetInstance().isPaid) {
				if (!subscriptionStatus.renewalCard) {
					DialogManager.Show("PurchaseDialog", null, _Refresh, {strStart:"tiers cc"});	
				} else {
					DialogManager.Show("PurchaseDialog", null, _Refresh, {strStart:"tiers"});
				}				
			} else {
				// Not paid. Upgrade.
				// For renewalls (used to be paid) as well as first time upgrades
				// skip the upsell and go straight to the membership/credit card form
				DialogManager.ShowPurchase("/home/myaccount", null, _Refresh);
			}
		}
		
		// User has asked to change their membership status.
		// Upgrade or change renewall settings and/or cancel PayPal.
		public function ShowMembershipDialog(): void {
			if (subscriptionStatus.payPalActive) {
				DialogManager.Show("CancelPaypalDialog", this, null, {'fnOnPayPalCancel':_ShowMembershipDialog, 'fRenewall':!AccountMgr.GetInstance().isPaid});
			} else {
				// Not paypal. Go straight there.
				_ShowMembershipDialog();
			}
		}
		
		protected function CancelMembership(): void {
			if (subscriptionStatus.payPalActive) {
				DialogManager.Show("CancelPaypalDialog", this);
			} else {
				DialogManager.Show("ConfirmCancelDialog", this);
			}			
		}
		
		protected function EditPaymentMethod(): void {
			if (subscriptionStatus.payPalActive) {
				DialogManager.Show("CancelPaypalDialog", this, null, {'fnOnPayPalCancel':_ShowMembershipDialog, 'fRenewall':!AccountMgr.GetInstance().isPaid});
				return;
			}
			if (AccountMgr.GetInstance().isPaid) {
				if (subscriptionStatus.renewalCard) {
					// Edit card
					DialogManager.Show("PurchaseDialog", null, _Refresh, {strStart:"info"});
				} else {
					// Add card
					DialogManager.Show("PurchaseDialog", null, _Refresh, {strStart:"cc tiers"});					
				}
			} else {
				// Delete card
				ShowBusy();
				PurchaseManager.GetInstance().RemoveCreditCard(function(nErr:Number, strErr:String):void {
					// Refresh
					HideBusy();
					SubscriptionStatus.Refresh();
				});
			}
		}

		protected function ChangePassword(): void {
			DialogManager.Show("ChangePasswordDialog", this);
		}
		
		protected function ChangeEmail(): void {
			DialogManager.Show("ChangeEmailDialog", this);
		}
		
		protected function ChangePerformance(): void {
			DialogManager.Show("ChangePerformanceDialog", this);
		}

		protected function DeleteAccount(): void {
			DialogManager.Show("ConfirmDelAcctDialog", this);
		}
		
		private function ShowBusy(): void {
			var strMsg:String = Resource.getString('OrderTab', 'processing');
			_bsy = BusyDialogBase.Show(this, strMsg, BusyDialogBase.OTHER, "IndeterminateNoCancel", 0);
		}	
			
		private function HideBusy(): void {
			if (_bsy) {
				_bsy.Hide();
				_bsy = null;
			}
		}
	}
}


