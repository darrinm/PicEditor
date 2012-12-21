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
package validators
{
	// This file contains validators which are here just because we need to create
	// localized versions of their output strings.  No other functionality is changed
	// from the base classes.
	// You should change the code that uses validators to look for validators.ValidatorName
	// instead of mx.ValidatorName
	
	import mx.resources.IResourceManager;
	import mx.resources.ResourceBundle;
	import mx.resources.ResourceManager;
	import mx.validators.CreditCardValidator;
	import mx.validators.CreditCardValidatorCardType;
	import mx.validators.ValidationResult;

	public class PicnikCreditCardValidator extends mx.validators.CreditCardValidator
	{
		public static const ANY:String = "Any";
		public static const JCB:String = "JCB";
		public static const SOLO:String = "Solo";
		public static const MAESTRO:String = "Maestro";
		
		private var _aLocalizedKeys:Object = {
							"invalidCharError": "invalidCharErrorCCV",
							"invalidNumberError": "invalidNumberError",
							"noNumError": "noNumError",
							"noTypeError": "noTypeError",
							"wrongLengthError": "wrongLengthErrorCCV",
							"wrongTypeError": "wrongTypeError" };
		
		[ResourceBundle("validators")] static protected var _rb:ResourceBundle;  	
		
		public function PicnikCreditCardValidator():void {
			if (!_fLocalized) _Localize();
		}
			
		private var _fLocalized:Boolean = false;
		private function _Localize() : void {
			_fLocalized = true;
			for (var i:String in _aLocalizedKeys) {
				this[i] = Resource.getString("validators", _aLocalizedKeys[i]);
			}
		}
		
		// Override validation to call our new validation method
		override protected function doValidation(value:Object):Array
	    {
			var results:Array = doRequiredValidation(value);
			
			// Return if there are errors
			// or if the required property is set to false and length is 0.
			var val:String = value ? String(value) : "";
			if (results.length > 0 || ((val.length == 0) && !required))
				return results;
			else
			    return PicnikCreditCardValidator.validateCreditCard(this, value, null);
	    }
	   
	    // Copied from Validator.as - we can't get to these because one is private and hte other is a super.super method
	    protected function doRequiredValidation(value:Object):Array
	    {
	        var results:Array = [];
	       
	        var result:ValidationResult = validateRequired(value);
	        if (result)
	            results.push(result);
	           
	        return results;
	    }
	           
	    /**
	     *  @private
	     *  Determines if an object is valid based on its
	     *  <code>required</code> property.
	     *  This is a convenience method for calling a validator from within a
	     *  custom validation function.
	     */
	    private function validateRequired(value:Object):ValidationResult
	    {
	        if (required)
	        {
	            var val:String = (value != null) ? String(value) : "";
	
	            val = trimString(val);
	
	            // If the string is empty and required is set to true
	            // then throw a requiredFieldError.
	            if (val.length == 0)
	            {
	                return new ValidationResult(true, "", "requiredField",
	                                            requiredFieldError);                
	            }
	        }
	       
	        return null;
	    }

	    private static function trimString(str:String):String
	    {
	        var startIndex:int = 0;
	        while (str.indexOf(' ', startIndex) == startIndex)
	        {
	            ++startIndex;
	        }
	
	        var endIndex:int = str.length - 1;
	        while (str.lastIndexOf(' ', endIndex) == endIndex)
	        {
	            --endIndex;
	        }
	
	        return endIndex >= startIndex ?
	               str.slice(startIndex, endIndex + 1) :
	               "";
	    }
		/**
		 * Copied from CreditCardValidator.as: Added support for Maestro, JCB, and Solo
		 *  Convenience method for calling a validator.
		 *  Each of the standard Flex validators has a similar convenience method.
		 *
		 *  @param validator The CreditCardValidator instance.
		 *
		 *  @param value A field to validate, which must contain
		 *  the following fields:
		 *  <ul>
		 *    <li><code>cardType</code> - Specifies the type of credit card being validated.
		 *    Use the static constants
		 *    <code>CreditCardValidatorCardType.MASTER_CARD</code>,
		 *    <code>CreditCardValidatorCardType.VISA</code>,
		 *    <code>CreditCardValidatorCardType.AMERICAN_EXPRESS</code>,
		 *    <code>CreditCardValidatorCardType.DISCOVER</code>, or
		 *    <code>CreditCardValidatorCardType.DINERS_CLUB</code>.</li>
		 *    <li><code>cardNumber</code> - Specifies the number of the card
		 *    being validated.</li></ul>
		 *
		 *  @param baseField Text representation of the subfield
		 *  specified in the value parameter.
		 *  For example, if the <code>value</code> parameter
		 *  specifies value.date, the <code>baseField</code> value is "date".
		 *
		 *  @return An Array of ValidationResult objects, with one ValidationResult
		 *  object for each field examined by the validator.
		 *
		 *  @see mx.validators.ValidationResult
		 */
		public static function validateCreditCard(validator:CreditCardValidator,
												  value:Object,
												  baseField:String):Array
		{
			var results:Array = [];
			
			// Resource-backed properties of the validator.
			var allowedFormatChars:String = validator.allowedFormatChars;
	
			var resourceManager:IResourceManager = ResourceManager.getInstance();
	
		    var baseFieldDot:String = baseField ? baseField + "." : "";
			
			var valid:String = DECIMAL_DIGITS + allowedFormatChars;
			var cardType:String = null;
			var cardNum:String = null;
			var digitsOnlyCardNum:String = "";
			var message:String;
	
			var n:int;
			var i:int;
			
			try
			{
				cardType = String(value.cardType);
			}
			catch(e:Error)
			{
				// Use the default value and move on
				message = resourceManager.getString(
					"validators", "missingCardType");
				throw new Error(message);
			}
			
			try
			{
				cardNum = value.cardNumber;
			}
			catch(f:Error)
			{
				// Use the default value and move on
				message = resourceManager.getString(
					"validators", "missingCardNumber");
				throw new Error(message);
			}
			
	        if (validator.required)
	        {
	            if (cardType.length == 0)
	            {
					results.push(new ValidationResult(
						true, baseFieldDot + "cardType",
						"requiredField", validator.requiredFieldError));
	            }
	
	            if (!cardNum)
	            {
	                results.push(new ValidationResult(
						true, baseFieldDot + "cardNumber",
						"requiredField", validator.requiredFieldError));
	            }
	        }
			
			n = allowedFormatChars.length;
			for (i = 0; i < n; i++)
			{
				if (DECIMAL_DIGITS.indexOf(allowedFormatChars.charAt(i)) != -1)
				{
					message = resourceManager.getString(
						"validators", "invalidFormatChars");
					throw new Error(message);
				}
			}
			
			if (!cardType)
			{
				results.push(new ValidationResult(
					true, baseFieldDot + "cardType",
					"noType", validator.noTypeError));
			}
			else if (cardType != CreditCardValidatorCardType.MASTER_CARD &&
					 cardType != CreditCardValidatorCardType.VISA &&
					 cardType != CreditCardValidatorCardType.AMERICAN_EXPRESS &&
					 cardType != CreditCardValidatorCardType.DISCOVER &&
					 cardType != PicnikCreditCardValidator.JCB &&
					 cardType != PicnikCreditCardValidator.MAESTRO &&
					 cardType != PicnikCreditCardValidator.SOLO &&
					 cardType != PicnikCreditCardValidator.ANY &&
					 cardType != CreditCardValidatorCardType.DINERS_CLUB)
			{
				results.push(new ValidationResult(
					true, baseFieldDot + "cardType",
					"wrongType", validator.wrongTypeError));
			}
	
			if (!cardNum)
			{
				results.push(new ValidationResult(
					true, baseFieldDot + "cardNumber",
					"noNum", validator.noNumError));
			}
	
			if (cardNum)
			{
				n = cardNum.length;
				for (i = 0; i < n; i++)
				{
					var temp:String = "" + cardNum.substring(i, i + 1);
					if (valid.indexOf(temp) == -1)
					{
						results.push(new ValidationResult(
							true, baseFieldDot + "cardNumber",
							"invalidChar", validator.invalidCharError));
					}
					if (DECIMAL_DIGITS.indexOf(temp) != -1)
						digitsOnlyCardNum += temp;
				}
			}
			
			if (results.length > 0)
				return results;
	
			var cardNumLen:int = digitsOnlyCardNum.toString().length;			
			var oCalcCardType:Object = PicnikCreditCardValidator.GetCreditCardType(cardNum);
			
			var fLenValid:Boolean = false;
			if (oCalcCardType.type == PicnikCreditCardValidator.ANY) {
				results.push(new ValidationResult(
					true, baseFieldDot + "cardType",
					"wrongType", validator.wrongTypeError));
			} else if (cardType != PicnikCreditCardValidator.ANY && cardType != oCalcCardType.type) {
				results.push(new ValidationResult(
					true, baseFieldDot + "cardType",
					"wrongType", validator.wrongTypeError));				
			} else {
				for (i = 0; i < oCalcCardType.aLen.length; i++) {
					if (cardNumLen == oCalcCardType.aLen[i]) {
						fLenValid = true;
						break;
					}
				}
			}
		
			if (!fLenValid)
			{
				results.push(new ValidationResult(
					true, baseFieldDot + "cardNumber",
					"wrongLength", validator.wrongLengthError));
				return results;
			}
	
			// Implement Luhn formula testing of this.cardNumber
			var doubledigit:Boolean = false;
			var checkdigit:int = 0;
			var tempdigit:int;
			for (i = cardNumLen - 1; i >= 0; i--)
			{
				tempdigit = Number(digitsOnlyCardNum.charAt(i));
				if (doubledigit)
				{
					tempdigit *= 2;
					checkdigit += (tempdigit % 10);
					if ((tempdigit / 10) >= 1.0)
						checkdigit++;
					doubledigit = false;
				}
				else
				{
					checkdigit = checkdigit + tempdigit;
					doubledigit = true;
				}
			}
	
			if ((checkdigit % 10) != 0)
			{
				results.push(new ValidationResult(
					true, baseFieldDot + "cardNumber",
					"invalidNumber", validator.invalidNumberError));
				return results;
			}
	
			return results;
		}

		// returns an object with the following fields:
		//	type: credit card type (might be set to PicnikCreditCardValidator.ANY)
		//  aLen: array of valid credit card lengths
		//
		public static function GetCreditCardType( strCCNumber:String ): Object {
			if (strCCNumber.length == 0) {
				return { type: PicnikCreditCardValidator.ANY, aLen: [], cvvLen:3 };
			}

			// VISA
			if (strCCNumber.charAt(0) == "4") {
				return { type: CreditCardValidatorCardType.VISA, aLen:[13,16], cvvLen:3 };
			}
			
			var strCC2:String = strCCNumber.substr(0,2);

			// MASTER_CARD
			if (strCC2 == "51" || strCC2 == "52" ||
				strCC2 == "53" || strCC2 == "54" ||
				strCC2 == "55") {
				return { type: CreditCardValidatorCardType.MASTER_CARD, aLen:[16], cvvLen:3 };
				
			}
			
			// AMERICAN_EXPRESS
			if (strCC2 == "34" || strCC2 == "37") {
				return { type: CreditCardValidatorCardType.AMERICAN_EXPRESS, aLen:[15], cvvLen:4 };
			}				

			var strCC3:String = strCCNumber.substr(0,3);
			
			// DINERS_CLUB
			if (strCC3 == '300' || strCC3 == '301' ||
				strCC3 == '302' || strCC3 == '303' ||
				strCC3 == '304' || strCC3 == '305' ||
				strCC2 == '36' || strCC2 == '38') {
				return { type: CreditCardValidatorCardType.DINERS_CLUB, aLen:[14], cvvLen:3 };					
			}
			
			var strCC4:String = strCCNumber.substr(0,4);

			// DISCOVER
			if (strCC4 == '6011') {
				return { type: CreditCardValidatorCardType.DISCOVER, aLen:[16], cvvLen:3 };					
			}
			
			// JCB
			if (strCC4 >= '3528' && strCC4 <= '3589') {
				return { type: PicnikCreditCardValidator.JCB, aLen:[16], cvvLen:3 };					
			}
			
			// MAESTRO
			if (strCC4 == '5018' || strCC4 == '5020' ||
				strCC4 == '5038' || strCC4 == '6304' ||
				strCC4 == '6759' || strCC4 == '6761') {
				return { type: PicnikCreditCardValidator.MAESTRO, aLen:[12,13,14,15,16,17,18,19], cvvLen:3 };					
			}
			
			// SOLO
			if (strCC4 == '6334' || strCC4 == '6767') {
				return { type: PicnikCreditCardValidator.SOLO, aLen:[16,17,18,19], cvvLen:3 };					
			}
							
			return { type: PicnikCreditCardValidator.ANY, aLen: [], cvvLen:3 };
		}
	}
}


