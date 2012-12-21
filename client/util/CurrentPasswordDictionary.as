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
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import mx.validators.ValidationResult;
	import com.adobe.crypto.MD5;
	
	public class CurrentPasswordDictionary extends PicnikDict
	{
		private var _obMd5ToPw:Object = new Object();
		// This dictionary has one "in" dictionary value, the md5 encoding of the user password
		// If a user changes their password, the dictionary needs to be reset.
		protected override function LookupStateElsewhere(strVal:String): void {
			var strMD5Pw:String = MD5.hash(strVal);
			_obMd5ToPw[strMD5Pw] = strVal;
			PicnikService.PasswordCorrect(strMD5Pw, OnPasswordCorrect);
		}

		private function OnPasswordCorrect(err:Number, strError:String, obData:Object=null): void {
			if (err == 0) {
				if (("correct" in obData) && ("password" in obData)) {
					var fCorrect:Boolean = obData["correct"].toString().toLowerCase() == "true";
					SetExists(_obMd5ToPw[obData["password"]], fCorrect); // Exists === Correct
				}
			} else {
				// There was some sort of error. Don't update anything.
			}
		}
	}
}