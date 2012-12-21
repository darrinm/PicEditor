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
	public class CreditCard
	{
		public static const kchPaypal:String = 'P';
		public static const kchVisa:String = 'V';
		public static const kchDiscover:String = 'D';
		public static const kchMastercard:String = 'M';
		public static const kchAmex:String = 'A';
		public static const kchJCB:String = 'J';
		public static const kchDinersClub:String = 'N';
		public static const kchMaestro:String = 'R';
		public static const kchSolo:String = 'S';
		
		public var strCC:String = null; //credit card number
		public var strCCLast4:String = null; // credit card number last 4
		public var strExpiry:String = null; // expiration date {MMYY}
		public var strCVS:String = null; // CVS code from back of card
		public var chCCType:String = null; // {VMAD} Visa/Mastercard/Amex/Discover

		public var strFirstName:String = null;
		public var strLastName:String = null;
		public var strCity:String = null;
		public var strState:String = null;
		public var strZip:String = null;
		public var strCountry:String = null;
		public var strAddress:String = null;
		public var strPhone:String = null;
		public var strEmail:String = null;
		public var strCCId:String = null;
		public var strBrainTreeConfToken:String = null;

		// Return a one letter code for a card type
		public static function GetCardTypeCode(strCardType:String): String {
			var strCode:String = strCardType.charAt(0);
			
			// Maestro and MasterCard collide.
			if (strCardType == PicnikCreditCardValidator.MAESTRO)
				strCode = "R"; // 'Ro short for Maest_ro_?
			
			// Diner's Club and Discover collide.
			if (strCardType == CreditCardValidatorCardType.DINERS_CLUB)
				strCode = "N"; // 'diNers Club
			
			// Handle the "ANY" card type
			if (strCardType == PicnikCreditCardValidator.ANY)
				strCode = "?"; // any/unknown
			
			return strCode;
		}
		
		public function FullName():String {
			var strName:String = strFirstName ? strFirstName : '';
			
			if (strLastName) {
				strName += (strName.length ? ' ' : ''); // insert a space
				strName += strLastName;
			}
			return strName;
		}
		
		
		public function FullAddress():String {
			var strFullAddress:String = "";
			if (strAddress && strAddress.length > 0) {
				strFullAddress += strAddress;
			}
			if (strCity && strCity.length > 0) {
				if (strFullAddress.length > 0)
					strFullAddress += ", ";
				strFullAddress += strCity;
			}
			if (strState && strState.length > 0) {
				if (strFullAddress.length > 0)
					strFullAddress += ", ";
				strFullAddress += strState;
			}
			if (strZip && strZip.length > 0) {
				if (strFullAddress.length > 0)
					strFullAddress += ", ";
				strFullAddress += strZip;
			}
			if (strCountry && strCountry.length > 0) {
				if (strFullAddress.length > 0)
					strFullAddress += ", ";
				strFullAddress += strCountry;
			}
			return strFullAddress;
		}
		
		public function set dtExpiry(dtExp:Date): void {
			strExpiry = dtExp.month.toString() + dtExp.fullYear.toString();
		}
		
		public function get dtExpiry(): Date {
			if (strExpiry) {
				return new Date("20" + strExpiry.slice(2,4), int(strExpiry.slice(0,2))-1);
			} else {
				return null;
			}
		}

		public function getBrainTreeVars():URLVariables {
			var urlv:URLVariables = new URLVariables();
			
			var strCardholder:String = new String();
			if (strFirstName)
			{
				urlv["customer[first_name]"] = strFirstName;
				urlv["customer[credit_card][billing_address][first_name]"] = strFirstName;
				strCardholder = strFirstName+" ";
			}
			
			if (strLastName)
			{
				urlv["customer[last_name]"] = strLastName;
				urlv["customer[credit_card][billing_address][last_name]"] = strLastName;
				strCardholder += strLastName;
			}
			
			urlv["customer[credit_card][cardholder_name]"] = strCardholder;
			
			if (strPhone) urlv["customer[phone]"] = strPhone;
			
			if (strCC) urlv["customer[credit_card][number]"] = strCC;
			if (strExpiry)
			{
				urlv["customer[credit_card][expiration_month]"] = strExpiry.substr(0,2);
				urlv["customer[credit_card][expiration_year]"] = "20"+strExpiry.substr(2,2);
			}
			
			if (strCVS) urlv["customer[credit_card][cvv]"] = strCVS;
			
			if (strAddress) urlv["customer[credit_card][billing_address][street_address]"] = strAddress;
			if (strCity) urlv["customer[credit_card][billing_address][locality]"] = strCity;
			if (strState) urlv["customer[credit_card][billing_address][region]"] = strState;
			if (strZip) urlv["customer[credit_card][billing_address][postal_code]"] = strZip;
			if (strCountry) urlv["customer[credit_card][billing_address][country_name]"] = strCountry;
			if (strEmail) urlv["customer[email]"] = strEmail;			

			return urlv;
		}		
	}
}
