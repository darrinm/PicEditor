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
	import flash.net.URLVariables;
	
	import mx.validators.CreditCardValidatorCardType;
	
	import validators.PicnikCreditCardValidator;

	[Bindable]
	public class CreditCardTransaction
	{
		public static const kErrLimitExceeded:String = 'LIMIT_EXCEEDED';
		public static const kErrCCNumber:String =  'CC_NUMBER'
		public static const kErrExpired:String = 'EXPIRED'
		public static const kErrDate:String = 'DATE'
		public static const kErrCVV:String = 'CVV'
		public static const kErrZip:String = 'ZIP'
		public static const kErrUnknown:String = 'ERROR';
		public static const kErrException:String = 'ERROR_PICNIK';
		public static const kErrFraud:String = 'FRAUD';
		public static const kErrInsufficientFunds:String = 'INSUFFICIENT_FUNDS';
		public static const kErrNotAllowed:String = 'NOT_ALLOWED';
		public static const kErrCallAuth:String = 'CALL_AUTH';
		public static const kErrCVVOrDate:String = 'CVV_OR_DATE';
		
		public static const knUnknownDuration:int = -1;
		public static const knOneMonth:int = 31;
		public static const knSixMonths:int = 183;
		public static const kn12Months:int = 366;
		
		public static const kSkuOneMonth:String = "PP01";
		public static const kSkuSixMonths:String = "PP06";
		public static const kSku12Months:String = "PP12";
		
		public static const knOneMonthPrice:Number = 4.95;
		public static const knSixMonthPrice:Number = 19.95;
		public static const kn12MonthPrice:Number = 24.95;
		
		public var cc:CreditCard = null;
		public var nAmount:Number = 0;
		public var nTax:Number = 0;
		public var strEmail:String = null;
		public var fAutoRenew:Boolean = true;
		public var strSource:String = null;
		public var fIsGift:Boolean = false;
		public var fIsComp:Boolean = false;
		public var strGiftName:String = null;
		public var strGiftEmail:String = null;
		public var strInvoice:String = null;
		public var strGiftCode:String = null;
		public var fIsRenewal:Boolean = false;
		public var fIsPurchase:Boolean = false;	// if we're trying to execute a purchase now
		public var nDuration:int = kn12Months;
		public var strSkuId:String = kSku12Months;
		public var aErrors:Array = null;
		public var dtSubscriptionExpires:Date = null;
		
		public var logEventBase:String = null;
		public var sourceEvent:String = null;
		
		public function CreditCardTransaction( ccIn:CreditCard = null ) {
			cc = ccIn;
		}
		
		static public function GetDurationFromSkuId(strSkuId:String): int {
			if (strSkuId == CreditCardTransaction.kSkuOneMonth) {
				return CreditCardTransaction.knOneMonth;
			} else if (strSkuId == CreditCardTransaction.kSkuSixMonths) {
				return CreditCardTransaction.knSixMonths;
			}
			return CreditCardTransaction.kn12Months;
		}

		static public function GetPriceFromSkuId(strSkuId:String): Number {
			if (strSkuId == CreditCardTransaction.kSkuOneMonth) {
				return CreditCardTransaction.knOneMonthPrice;
			} else if (strSkuId == CreditCardTransaction.kSkuSixMonths) {
				return CreditCardTransaction.knSixMonthPrice;
			}
			return CreditCardTransaction.kn12MonthPrice;
		}
	}
}
