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
	import bridges.storageservice.IStorageService;
	
	import events.LoginEvent;

	import flash.events.EventDispatcher;
	
	public class ThirdPartyAccount extends EventDispatcher {
		private var _strAccountName:String;
		protected var _ss:IStorageService;
		protected const kstrUserId:String = "_userid";
		protected const kstrToken:String = "_token";
		protected const kstrApiUrl:String = "_url";
		
		public function ThirdPartyAccount(strAccountName:String, ss:IStorageService) {
			_strAccountName = strAccountName;
			_ss = ss;
		}
		
		public override function toString(): String {
			return "[ThirdPartyAccount: " + this.name + ", " + this.GetToken() + ", " + this.GetUserId() + ", " + this.storageService + "]";
		}
		
		public function get storageService(): IStorageService {
			return _ss;
		}
		
		[Bindable]
		public function set name(strName:String): void {
			// This is to shut up MXMLC "[Bindable] on read-only getter is unnecessary and will be ignored"
		}
		
		// BUGBUG: this is being used both as a human-readable string (not localized) and as an id (GetAttribute).
		public function get name(): String {
			return _strAccountName;
		}
		
		public function HasCredentials(): Boolean {
			var strToken:String = GetToken();
			return (strToken != null && strToken != "");
		}
		
		public function RemoveCredentials():void {
			SetAttribute(kstrToken, "", false);
			SetAttribute(kstrUserId, "", true);
			_ss.LogOut();
		}
		
		// Returns true if this tpa is exclusive for non-paid users
		// That means that this is included in our "only-one-service-active-at-a-time" limit
		public function IsExclusive(): Boolean {
			var strServiceId:String = storageService.GetServiceInfo().id.toLowerCase();
			if (strServiceId == "show" || strServiceId == "picnik")
				return false;
			return true;
		}
		
		// Returns true if this tpa is our current "primary" tpa.  The "primary" one belongs
		// to the current host: facebook when we're in Facebook, yahoomail, when we're in YahooMail, etc.
		public function IsPrimary(): Boolean {
			var obServiceInfo:Object = storageService.GetServiceInfo();
			var strApiHost:String = PicnikBase.app.AsService().GetServiceName();
			if (!strApiHost)
				return false;
			if (obServiceInfo.id.toLowerCase() == strApiHost.toLowerCase()) {
				// the current api service provider is not exclusive
				return true;
			}
			return false;
		}		
		
		public function GetUserId(): String {
			return GetAttribute(kstrUserId);
		}
		
		public function SetUserId(strUserId:String, fFlush:Boolean=true): void {
			SetAttribute(kstrUserId, strUserId, fFlush);
		}

		public function GetToken(): String {
			return GetAttribute(kstrToken);
		}
		
		public function SetToken(strToken:String, fFlush:Boolean=true): void {
			SetAttribute(kstrToken, strToken, fFlush);
			dispatchEvent(new LoginEvent(LoginEvent.CREDENTIALS_CHANGED, (strToken != null && strToken != "") ));
		}
		
		public function GetApiUrl(): String {
			return GetAttribute(kstrApiUrl);
		}
		
		public function SetApiUrl(strApiUrl:String, fFlush:Boolean=true): void {
			SetAttribute(kstrApiUrl, strApiUrl, fFlush);
		}
		
		public function GetAttribute(strName:String, obDefaultValue:*=undefined): * {
			return AccountMgr.GetInstance().GetUserAttribute("tpa." + _strAccountName + "." + strName, obDefaultValue);
		}
		
		public function SetAttribute(strName:String, obValue:*, fFlush:Boolean=true): void {
			AccountMgr.GetInstance().SetUserAttribute("tpa." + _strAccountName + "." + strName, obValue, fFlush);
		}
	}
}
