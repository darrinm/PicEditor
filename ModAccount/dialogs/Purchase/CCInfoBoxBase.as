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
	import mx.containers.Box;
	
	import util.CreditCard;
	import util.CreditCardTransaction;
	
	public class CCInfoBoxBase extends Box
	{
		[Event(name="addCard", type="Dialogs.Purchase.PurchaseEvent")]
		[Event(name="changeCard", type="Dialogs.Purchase.PurchaseEvent")]
		[Event(name="removeCard", type="Dialogs.Purchase.PurchaseEvent")]
		
		[Bindable] public var _cc:CreditCard = null;
		[Bindable] public var subscriptionSkuId:String = CreditCardTransaction.kSku12Months;
		[Bindable] public var hasCreditCard:Boolean =false;
		[Bindable] public var subscriptionStatus:SubscriptionStatus = null;
	
		public function CCInfoBoxBase()  {
			subscriptionStatus = SubscriptionStatus.GetInstance();
		}
				
		[Bindable]
		public function set creditCard( cc:CreditCard ): void {
			_cc = cc;
			hasCreditCard = _cc && _cc.strCCLast4 && _cc.strCCLast4.length > 0;		
		}
		
		public function get creditCard(): CreditCard {
			return _cc;
		}
		
		public function AddCard(): void {
			dispatchEvent(new PurchaseEvent(PurchaseEvent.ADD_CARD));			
		}
		
		public function ChangeCard(): void {
			dispatchEvent(new PurchaseEvent(PurchaseEvent.CHANGE_CARD));						
		}		

		public function RemoveCard(): void {
			dispatchEvent(new PurchaseEvent(PurchaseEvent.REMOVE_CARD));						
		}		
}

}