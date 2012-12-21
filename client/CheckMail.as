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
package {
	// From http://proto.layer51.com/d.aspx?f=1443
	// by zikey (?)
	
	public class CheckMail
	{
		static public function isEmail (s : String) : Boolean
		{
			if (s.indexOf ("@") == - 1) return false;
			var email : Array;
			var user : String;
			var domain : String;
			var domain_dots : Array;
			var user_dots : Array;
			if ((email = s.split ("@")).length == 2)
			{
				if ((domain = email [1]).split (".").pop ().length > 4) return false;
				if (domain.split (".").length < 2) return false;
				if ((user = email [0]).indexOf (".") && domain.indexOf ("."))
				{
					if (domain.lastIndexOf (".") > domain.length - 3) return false;
					var c:Array;
					user_dots = user.split (".");
					for (var i:Number = user_dots.length - 1; i >= 0; i --)
					{
						if ( ! CheckMail.checkWords (user_dots[i], true)) return false;
					}
					domain_dots = domain.split (".");
					for (i = domain_dots.length - 1; i >= 0; i --)
					{
						if ( ! CheckMail.checkWords (domain_dots[i], false)) return false;
					}
				} else return false;
			} else return false;
			return true;
		}
		
		static private function checkWords (s : String, userBol : Boolean) : Boolean
		{
			var spw:Boolean;
			var len:Number = s.length - 1;
			if (userBol)
			{
				if (s.charAt (0) == "-" || s.charAt (len) == "-" || s.charAt (0) == "_" || s.charAt (len) == "_") return false;
			}else
			{
				if (s.charAt (0) == "-" || s.charAt (len) == "-") return false;
			}
			for (var i:Number = len; i >= 0; i --)
			{
				var c:String = s.charAt (i).toLowerCase ();
				var alpha:Boolean = (c <= "z") && (c >= "a");
				var num:Boolean = (c <= "9") && (c >= "0");
				if (userBol)
				{
					spw = (c == "-") || (c == "_");
				}else
				{
					spw = (c == "-");
				}
				if ( ! alpha && ! num && ! spw) return false;
			}
			return true;
		}
	}
}