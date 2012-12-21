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
	import api.PicnikRpc;
	import api.RpcResponse;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.validators.ValidationResult;
	
	import validators.PicnikEmailValidator;
	
	public class UserEmailDictionary extends PicnikDict
	{
		private static var _vld:PicnikEmailValidator = new PicnikEmailValidator();

		private static const DISALLOWED_CHARS:String = "()<>,;:\\\"[] `~!#$%^&*={}|/?'";
		[Bindable (event="restrictedCharsChange")]
		public static function get textInputRestrictChars(): String {
			var str:String = DISALLOWED_CHARS;
			str = str.replace("\\","\\\\"); // Escape backslash
			str = str.replace("^","\\^"); // Escape ^
			str = str.replace("-","\\-"); // Escape -
			str = "^" + str; // Specify "exclude"
			return str;
		}
		
		private static var _uedt:UserEmailDictionary = null;
		public static function get global(): UserEmailDictionary {
			if (_uedt == null) _uedt = new UserEmailDictionary();
			return _uedt;
		}
		
		public static function resetGlobal(): void {
			if (_uedt == null) _uedt = new UserEmailDictionary();
			else _uedt.ResetState();
		}
		
		public override function ValidateChars(strVal:String): Array {
			return validateEmail(_vld, strVal, null);
		}

		// Copied from EmailValidator. Modified DISALLOWED_CHARS to exclude + (allow it)
		public static function validateEmail(validator:PicnikEmailValidator,
											 value:Object,
											 baseField:String):Array
		{
			var results:Array = [];
		
			// Validate the domain name
			// If IP domain, then must follow [x.x.x.x] format
			// Can not have continous periods.
			// Must have at least one period.
			// Must end in a top level domain name that has 2, 3, 4, or 6 characters.
	
			var emailStr:String = String(value);
			var username:String = "";
			var domain:String = "";
			var n:int;
			var i:int;
	
			// Find the @
			var ampPos:int = emailStr.indexOf("@");
			if (ampPos == -1)
			{
				results.push(new ValidationResult(
					true, baseField, "missingAtSign",
					validator.missingAtSignError));
				return results;
			}
			// Make sure there are no extra @s.
			else if (emailStr.indexOf("@", ampPos + 1) != -1)
			{
				results.push(new ValidationResult(
					true, baseField, "tooManyAtSigns",
					validator.tooManyAtSignsError));
				return results;
			}
	
			// Separate the address into username and domain.
			username = emailStr.substring(0, ampPos);
			domain = emailStr.substring(ampPos + 1);
	
			// Validate username has no illegal characters
			// and has at least one character.
			var usernameLen:int = username.length;
			if (usernameLen == 0)
			{
				results.push(new ValidationResult(
					true, baseField, "missingUsername",
					validator.missingUsernameError));
				return results;
			}
	
			for (i = 0; i < usernameLen; i++)
			{
				if (DISALLOWED_CHARS.indexOf(username.charAt(i)) != -1)
				{
					results.push(new ValidationResult(
						true, baseField, "invalidChar",
						validator.invalidCharError));
					return results;
				}
			}
			
			var domainLen:int = domain.length;
			
			// If IP domain, then must follow [x.x.x.x] format
			if (domain.charAt(0) == "[" && domain.charAt(domain.length-1) == "]")
			{
				// Parse out each IP number.
				var ipArray:Array = [];
				var ipAddr:String = domain.substring(1, domain.length - 1);
				var pos:int = 0;
				var newpos:int = 0;
				
				while (true)
				{
					newpos = ipAddr.indexOf(".", pos);
					if (newpos != -1)
					{
						ipArray.push(ipAddr.substring(pos,newpos));
					}
					else
					{
						ipArray.push(ipAddr.substring(pos));
						break;
					}
					pos = newpos + 1;
				}
				
				if (ipArray.length != 4)
				{
					results.push(new ValidationResult(
						true, baseField, "invalidIPDomain",
						validator.invalidIPDomainError));
					return results;
				}
	
				n = ipArray.length;
				for (i = 0; i < n; i++)
				{
					var item:Number = Number(ipArray[i]);
					if (isNaN(item) || item < 0 || item > 255)
					{
						results.push(new ValidationResult(
							true, baseField, "invalidIPDomain",
							validator.invalidIPDomainError));
						return results;
					}
				}
			}
			else
			{
				// Must have at least one period
				var periodPos:int = domain.indexOf(".");
				var nextPeriodPos:int = 0;
				var lastDomain:String = "";
				
				if (periodPos == -1)
				{
					results.push(new ValidationResult(
						true, baseField, "missingPeriodInDomain",
						validator.missingPeriodInDomainError));
					return results;
				}
	
				while (true)
				{
					nextPeriodPos = domain.indexOf(".", periodPos + 1);
					if (nextPeriodPos == -1)
					{
						lastDomain = domain.substring(periodPos + 1);
						if (lastDomain.length != 3 &&
							lastDomain.length != 2 &&
							lastDomain.length != 4 &&
							lastDomain.length != 6)
						{
							results.push(new ValidationResult(
								true, baseField, "invalidDomain",
								validator.invalidDomainError));
							return results;
						}
						break;
					}
					else if (nextPeriodPos == periodPos + 1)
					{
						results.push(new ValidationResult(
							true, baseField, "invalidPeriodsInDomain",
							validator.invalidPeriodsInDomainError));
						return results;
					}
					periodPos = nextPeriodPos;
				}
	
				// Check that there are no illegal characters in the domain.
				for (i = 0; i < domainLen; i++)
				{
					if (DISALLOWED_CHARS.indexOf(domain.charAt(i)) != -1)
					{
						results.push(new ValidationResult(
							true, baseField, "invalidChar",
							validator.invalidCharError));
						return results;
					}
				}
				
				// Check that the character immediately after the @ is not a period.
				if (domain.charAt(0) == ".")
				{
					results.push(new ValidationResult(
						true, baseField, "invalidDomain",
						validator.invalidDomainError));
					return results;
				}
			}
	
			return results;
		}

		// The current user's email is changing. Reflect the change.
		public function UserEmailChanging(strOldVal:String, strNewVal:String): void {
			SetExists(strOldVal, false);
			SetExists(strNewVal, true);
		}
		
		protected override function LookupStateElsewhere(strVal:String): void {
			PicnikRpc.FindByNameOrEmail({email:strVal}, function(rpcresp:RpcResponse): void {
				if (rpcresp.isError) {
					// Ignore errors
				} else {
					var nState:Number = PicnikDict.knDoesNotExist;
					if (rpcresp.data.fExists)
						nState = rpcresp.data.fGoogleCredentials ? PicnikDict.knExistsAndIsSpecial : knExists;
					SetState(strVal, nState);
				}
			});
		}
	}
}