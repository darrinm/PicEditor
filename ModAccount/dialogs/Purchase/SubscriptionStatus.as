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
package dialogs.Purchase
{
	import api.PicnikRpc;
	import api.RpcResponse;
	
	import flash.events.EventDispatcher;
	
	import util.CreditCard;
	import util.CreditCardTransaction;

	public class SubscriptionStatus extends EventDispatcher
	{
		// Default properties for non-premium user
	
		// Global property (PayPal might be active even if the user is not premium)
		[Bindable] public var payPalActive:Boolean = false;

		// Renewall properties
		[Bindable] public var renewalSkuId:String = null;
		[Bindable] public var renewalCard:CreditCard = null; // Credit card used to renew
		
		// Current subscription status
		[Bindable] public var isGift:Boolean = false; // user did not pay for this (gift or comp)
		[Bindable] public var isCancelable:Boolean = false; // Can the user cancel this?
		[Bindable] public var gracePeriodDays:Number = 0; // Number of grace period days for this subscription (based on sku, not time elapsed)

		private static var _subst:SubscriptionStatus = null;
		private static var _afnCallbacks:Array = [];
		private static var _fWorking:Boolean = false;

		public function SubscriptionStatus()
		{
		}
		
		public static function GetInstance(): SubscriptionStatus {
			if (_subst == null) {
				_subst = new SubscriptionStatus();
				Refresh();
			}
			return _subst;
		}
		
		// fnDone = function(fSuccess:Boolean): void
		public static function Refresh(fnDone:Function=null): void {
			if (fnDone != null)
				_afnCallbacks.push(fnDone);
			if (_fWorking)
				return;
			
			_fWorking = true;
			PicnikRpc.GetSubscriptionStatus(function(rpcresp:RpcResponse):void {
				_fWorking = false;
				try {
					if (!rpcresp.isError)
						GetInstance().UpdateFromResponseData(rpcresp.data);
				} catch (e:Error) {
					trace("Error handling subscription status response: " + e);
				}
				DoCallbacks(!rpcresp.isError);
			});
		}
		
		private static function DoCallbacks(fSuccess:Boolean): void {
			while (_afnCallbacks.length > 0) {
				try {
					var fn:Function = _afnCallbacks.pop();
					fn(fSuccess);
				} catch (e:Error) {
					trace("Ignoring callback error: " + e);
				}
			}
		}
		
		// Returns a date as a string.
		// Returns 1900 for no date
		private function FormatDateAttribute(obDate:Object): String {
			if ((!obDate) || !(obDate as Date))
				obDate = new Date(1900); // Very old
			
			// This string will be converted back into a date like this: new Date(strDate)
			return (obDate as Date).toString();
		}
		
		private function FormatAutoRenewAttribute(fAutoRenew:Boolean): String {
			return fAutoRenew ? 'Y' : 'N';
		}
		
		private function UpdateFromResponseData(obData:Object): void {
			// Some of the fields go straight into user attributes. Handle these first.
			AccountMgr.GetInstance().SetUserAttribute("nPaidDaysLeft", String(obData.nPaidDaysLeft));
			AccountMgr.GetInstance().SetUserAttribute("strSubscription", FormatDateAttribute(obData.dtExpires));
			AccountMgr.GetInstance().SetUserAttribute("cAutoRenew", FormatAutoRenewAttribute('renewalInfo' in obData));

			// Make sure we update all fields.
			if ('premiumState' in obData) { // Paid user
				var obPremiumState:Object = obData['premiumState'];
				isCancelable = obPremiumState['fCancelable'];
				gracePeriodDays = obPremiumState['nGracePeriod'];
				isGift = obPremiumState['fGift'];
			} else { // Not paid user
				isGift = false;
				isCancelable = false;
				gracePeriodDays = 0;
			}
			if ('renewalInfo' in obData) { // Auto-renew on
				var obRenewalInfo:Object = obData['renewalInfo'];
				renewalSkuId = obRenewalInfo['strSkuId'];
				renewalCard = CreditCardFromObject(obRenewalInfo['creditCard']);
			} else { // Auto-renew off
				renewalSkuId = null;
				renewalCard = null; // No card
			}
			
			if ('paypalInfo' in obData) {
				payPalActive = true;
				isCancelable = obData.paypalInfo.fCancelable;
			} else {
				payPalActive = false;
			}
		}
		
		private static function CreditCardFromObject(obCCInfo:Object): CreditCard {
			var cc:CreditCard = new CreditCard();
			if (obCCInfo != null) {
				cc.chCCType = CreditCard.GetCardTypeCode(obCCInfo.strCardType);
				cc.strExpiry = obCCInfo.strExpirationDate;	// comes in as MM/YYYY
				cc.strExpiry = cc.strExpiry.substr(0,2) + cc.strExpiry.substr(-2);
				cc.strCCLast4 = String(obCCInfo.strCardNum).substr(-4);
			}
			return cc;
		}
	}
}