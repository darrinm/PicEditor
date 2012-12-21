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
﻿package {
	import flash.external.ExternalInterface;
	/*
	 * This class was created to manage Cookies from directly within flash
	 * Here we will eliminate the need to have an environment outside of flash
	 * maintain our cookies.
	 *
	 *@author: Michael Avila
	 *@version: 1.0
	 *@doc: http://www.createage.com/blog/?p=40
	 *
	*/
	public class CookieJar
	{
		public static function cookieEscape(strVal:String): String {
			return strVal.replace(/\\/g, "\\\\");
		}
		
		// The functions that were here were moved into index.html to support safari
		public static function setCookie(name:String, value:String, strDays:String=null, strDomain:String=null): Boolean {
			try {
				ExternalInterface.call("createCookie", name, cookieEscape(value), strDays, strDomain);
				return true;
			} catch (e:Error) {
				PicnikService.Log("Ignored Client Exception: in CookieJar.createCookie: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityInfo);
			}
			return false;
		}
		
		public static function readCookie(name:String): String {
			try {
				return ExternalInterface.call("readCookie", name);
			} catch (e:Error) {
				PicnikService.Log("Ignored Client Exception: in CookieJar.readCookie: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityInfo);
			}
			return null; // default value for exceptions
		}
		
		public static function removeCookie(name:String): Boolean {
			try {
				ExternalInterface.call("eraseCookie", name);
				return true;
			} catch (e:Error) {
				PicnikService.Log("Ignored Client Exception: in CookieJar.eraseCookie: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityInfo);
			}
			return false;
		}
	}
}