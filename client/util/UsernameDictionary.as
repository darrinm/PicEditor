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
	
	import validators.UsernameValidator;
	
	public class UsernameDictionary extends PicnikDict
	{
		private static const DISALLOWED_CHARS:String = "\"\\/<>@?&|' "; // Also exclude anything <= ' '
		private static var _vld:UsernameValidator = null; // Used for invalid chars error

		[Bindable (event="restrictedCharsChange")]
		public static function get textInputRestrictChars(): String {
			var str:String = DISALLOWED_CHARS;
			str = str.replace("\\","\\\\"); // Escape backslash
			str = str.replace("^","\\^"); // Escape ^
			str = str.replace("-","\\-"); // Escape -
			str = "^" + str; // Specify "exclude"
			return str;
		}

		private static var _undt:UsernameDictionary = null;
		public static function get global(): UsernameDictionary {
			if (_undt == null) _undt = new UsernameDictionary();
			return _undt;
		}

		public static function resetGlobal(): void {
			if (_undt == null) _undt = new UsernameDictionary();
			else _undt.ResetState();
		}
		
		public static function ContainsInvalidUsernameChars(strVal:String): Boolean {
			for (var i:Number = 0; i < strVal.length; i++)
			{
				if (DISALLOWED_CHARS.indexOf(strVal.charAt(i)) != -1 || strVal.charCodeAt(i) <= " ".charCodeAt(0))
				{
					return true;
				}
			}
			return false;
		}
	
		private function getInvalidCharsError(): String {
			if (_vld == null) _vld = new UsernameValidator();
			return _vld.invalidUsernameCharactersError;
		}
	
		public override function ValidateChars(strVal:String): Array {
			var aResults:Array = [];
			if (ContainsInvalidUsernameChars(strVal)) {
				aResults.push(new ValidationResult(true, null, "invalidChar", getInvalidCharsError()));
			}
			return aResults;
		}

		protected override function LookupStateElsewhere(strVal:String): void {
			PicnikRpc.FindByNameOrEmail({name:strVal}, function(rpcresp:RpcResponse): void {
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