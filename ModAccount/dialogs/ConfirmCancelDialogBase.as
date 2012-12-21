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
	import containers.CoreDialog;
	
	import dialogs.Purchase.PurchaseManager;
	
	import flash.events.MouseEvent;
	
	import mx.controls.Button;
	import mx.controls.Text;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	
	import util.CreditCard;
	import util.CreditCardTransaction;
	import util.LocUtil;
	import util.PicnikAlert;
	
	/**
 	 * The ConfirmCancelDialogBase class is used in conjunction with ConfirmCancelDialog.mxml
	 * to present the user with a chance to back out of canceling their premium subscription.
	 *
   	 */
	public class ConfirmCancelDialogBase extends CloudyResizingDialog {
			
		private function CancelHandler(nErr:Number, strErrMsg:String): Boolean {
			HideBusy();
			Hide();
			if (nErr || isNaN(nErr)) {
				if (nErr == PicnikService.errPayPalFailed) {
					DialogManager.Show("CancelPaypalDialog");
				} else {
					PicnikAlert.show(Resource.getString('SettingsComponent', 'server_problems_error'));
				}
				return false;
			}
			return true;
		}
		
		private function onCancelAutoRenew( nErr:Number, strErrMsg:String ): void {
			if (CancelHandler(nErr, strErrMsg)) {
				EasyDialogBase.Show( null,
					[Resource.getString("ConfirmCancelDialog", "done")],
					Resource.getString("ConfirmCancelDialog", "cancelled"),
					Resource.getString("ConfirmCancelDialog", "enjoy", [LocUtil.mediumDate(AccountMgr.GetInstance().dateSubscriptionExpires)]));
			}
		}
		
		private function onCancelSubscription( nErr:Number, strErrMsg:String, cct:CreditCardTransaction ): void {
			if (CancelHandler(nErr, strErrMsg)) {
				var nAmount:Number = cct.nAmount + cct.nTax;
				EasyDialogBase.Show( null,
					[Resource.getString("ConfirmCancelDialog", "done")],
					Resource.getString("ConfirmCancelDialog", "cancelled"),
					Resource.getString("ConfirmCancelDialog", "refund", [LocUtil.moneyUSD(nAmount)]));
			}
		}
		
		protected function OnYesClick(): void {
			// Turn off autorenew
			ShowBusy(Resource.getString('SettingsComponent', 'working_on_it'));
			PurchaseManager.GetInstance().CancelAutoRenew(onCancelAutoRenew);
		}

		protected function OnYesRefundClick(): void {
			ShowBusy(Resource.getString('SettingsComponent', 'working_on_it'));
			PurchaseManager.GetInstance().CancelSubscription(onCancelSubscription);
		}
	}
}
