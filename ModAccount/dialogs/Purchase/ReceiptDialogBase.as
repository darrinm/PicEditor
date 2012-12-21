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
	import dialogs.CloudyResizingDialog;
	import dialogs.DialogManager;
	
	import mx.core.UIComponent;
	import mx.printing.FlexPrintJob;
	import mx.printing.FlexPrintJobScaleType;
	import mx.resources.ResourceBundle;
	
	import util.CreditCardTransaction;
	import util.LocUtil;
	
	public class ReceiptDialogBase extends CloudyResizingDialog
	{
		[Bindable] public var _strTotal:String = "";
		[Bindable] public var _strAddress:String = "";
		[Bindable] public var _strAccountExpires:String = "";
		[Bindable] public var _rp:ReceiptPrinter;
		
		[Bindable] public var cct:CreditCardTransaction;
		
   		[Bindable] [ResourceBundle("ReceiptTab")] protected var _rb:ResourceBundle;

		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			cct = obParams['cct'] as CreditCardTransaction;

			_strTotal = LocUtil.moneyUSD(cct.nAmount + cct.nTax);
			if (cct.nTax > 0) {
				//$%s USD ($%s + $%s tax)
				var strAmount:String = LocUtil.moneyUSD(cct.nAmount);
				var strTax:String = LocUtil.moneyUSD(cct.nTax);
				var strAmountWithTax:String = Resource.getString("ReceiptDialog", "withTax", [strAmount,strTax]);
				_strTotal += ' ' + strAmountWithTax;
			}			
			
			_strAddress = cct.cc.FullAddress();
			_strAccountExpires = LocUtil.mediumDate( AccountMgr.GetInstance().dateSubscriptionExpires );
			
			super.Constructor(fnComplete, uicParent, obParams);
		}

		protected function PrintReceipt(): void {
			_rp.Print( cct );
		}
	
		protected function SendOrPrint(): void {
			Hide();
			DialogManager.Show('GiftPrintEmailDialog', null, null, { cct: cct });
		}
				
		protected function BuyGiftAgain(): void {
			Hide();
			DialogManager.Show("PurchaseGiftDialog", null, null);
		}
				
	}
}