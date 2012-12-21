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
package bridges.flickr {
	import bridges.storageservice.IStorageService;
	
	public class FlickrThirdPartyAccount extends ThirdPartyAccount {
		
		public function FlickrThirdPartyAccount(strAccountName:String, ss:IStorageService) {
			super(strAccountName, ss);
		}

		override public function RemoveCredentials():void {		
			AccountMgr.GetInstance().SetUserAttribute("flickr_username", "", false);
			AccountMgr.GetInstance().SetUserAttribute("flickr_fullname", "", true);
			super.RemoveCredentials();
		}
		
		override public function GetAttribute(strName:String, obDefaultValue:*=undefined): * {
			var obValue:* = undefined;
			if (strName == "_fTagWithPicnik") {
				obValue = AccountMgr.GetInstance().GetUserAttribute("FlickrOutBridge.fTagWithPicnik", "");
				if (obValue == "") {
					return super.GetAttribute(strName, obDefaultValue);
				} else {
					return obValue;
				}
			} else if (strName == kstrUserId) {
				return AccountMgr.GetInstance().GetUserAttribute("flickr_nsid", obDefaultValue);
			} else if (strName == kstrToken) {
				return AccountMgr.GetInstance().GetUserAttribute("flickrauthtoken", obDefaultValue);
			}				
			return super.GetAttribute( strName, obDefaultValue );
		}
		
		override public function SetAttribute(strName:String, obValue:*, fFlush:Boolean=true): void {
			if (strName == "_fTagWithPicnik") {
				// clear out the old _fTagWithPicnik attribute -- we're storing it elsewhere now.
				AccountMgr.GetInstance().SetUserAttribute("FlickrOutBridge.fTagWithPicnik", "", fFlush);
			} else if (strName == kstrUserId) {
				AccountMgr.GetInstance().SetUserAttribute("flickr_nsid", obValue, fFlush);
				return;
			} else if (strName == kstrToken) {
				AccountMgr.GetInstance().SetUserAttribute("flickrauthtoken", obValue, fFlush);
				return;				
			}				
			return super.SetAttribute(strName, obValue, fFlush);
		}
	}
}
