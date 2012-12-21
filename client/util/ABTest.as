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
	import com.adobe.crypto.MD5;
	
	public class ABTest
	{
		/* Inactive but kept as an AB test examples
		public static const kobNewUpgradeDialog:Object = {name:"NewUpgradeDialog", options:["New", "Old"]};
		public static const kobUpgradeButtonTextTest:Object = {name:"UpgradeButtonText", options:["Upgrade", "Subscribe", "Learn"]};
		public static const kobStartBarTest:Object = {name:"StartBar", options:["Show", "Hide", "ShowFeatured", "HideFeatured"]};
		public static const kobStartBarTest:Object = {name:"StartBar", options:["Show", "ConditionalShow"]};
		*/
		
		public static const kobPayPalTest:Object = {name:"PayPal", options:["PayPalOn", "PayPalOff"]};
		// public static const kobTouchupTest:Object = {name:"Touchup", options:["TryIt", "Upgrade"]};
		// public static const kobRedirectTest:Object = {name:"Redirect", options:["OldWay", "NewWay"]};
		// public static var kobAdTest:Object = {name:"AdTest", options:["WithAds", "WithoutAds"]};	
				
		public static var _obIDMap:Object = null;

		private static var _fLockedOut:Boolean = false; // Lock out users who do refunds to ignore nerd pro and other fraud

		public static function GetBucket(obTest:Object): String {
			if ('fPremiumBucket' in obTest && obTest.fPremiumBucket && AccountMgr.GetInstance().isPremium) return "Premium";
			// Create a hash
			// Start with a user id (logged in) or machine id (not logged in)
			// Take the md5 sum of the resulting hash (for better distribution)
			var strHash:String = MD5.hash(GetUserTestId(obTest));
			
			// Take the sum of the hash ascii values
			var nVal:Number = 0;
			for (var i:Number = 0; i < strHash.length; i++) {
				nVal += strHash.charCodeAt(i);
			}
			var astrOptions:Array = obTest.options as Array;
			// Use the sum as our bucket index
			return astrOptions[nVal % astrOptions.length];
		}

		public static function Activate(obTest:Object, strEvent:String): void {
			if (_fLockedOut) return;
			
			var obStatus:Object = LookupTestStatus(obTest);
			if (obStatus == null) {
				obStatus = {};
				_obIDMap[obTest.name] = obStatus;
				SaveActiveTests();
				LogEvent(obTest, "Activate");
			}
			LogEvent(obTest, strEvent);
		}
		
		public static function LogEvent(obTest:Object, strEvent:String): void {
			var obStatus:Object = LookupTestStatus(obTest);
			if (obStatus) { // Active
				if (!(strEvent in obStatus)) {
					var strLog:String = "/ABTest/" + obTest.name + "/" + strEvent + "/" + GetBucket(obTest) + "/" + UserBucketManager.GetUserBucket();
					Util.UrchinLogReport(strLog, false);
					obStatus[strEvent] = true;
				}
			}
		}
		
		private static const kastrTopLevelTabs:Array = ['in','out','home','create','edit','collage','advancedcollage'];
		
		// A navigation event occured
		// See if any tests want to log it as an event
		public static function HandleNav(strEvent:String): void {
			if (strEvent == null) return;
			try {
				/* Inactive but kept as an AB test example
				var astrEvents:Array = strEvent.split('/');
				if (astrEvents.length > 1) {
					var strTab:String = String(astrEvents[1]).toLowerCase();
					if (kastrTopLevelTabs.indexOf(strTab) != -1) {
						// We have a top level tab
						if (IsActive(kobStartBarTest) && strTab != "home")
							ABTest.LogEvent(kobStartBarTest, "Tab_" + strTab);
					}
				}
				*/
			} catch (e:Error) {
				trace("ignoring error in ABTest.HandleNav: " + e + ", " + e.getStackTrace());
			}
		}
		
		public static function HandleRegistration(): void {
			try {
				/* Inactive but kept as an AB test example
				if (IsActive(kobTouchupTest))
					ABTest.LogEvent(ABTest.kobTouchupTest, "Register");
					
				if (IsActive(kobAdTest))
					ABTest.LogEvent(ABTest.kobAdTest, "Register");
					
				if (IsActive(kobNewUpgradeDialog))
					ABTest.LogEvent(kobNewUpgradeDialog, "Register");
				
				// Upgrade button text upgrade handling
				if (IsActive(kobUpgradeButtonTextTest)) {
					if (EventOccured(kobUpgradeButtonTextTest, "Click")) {
						ABTest.LogEvent(kobUpgradeButtonTextTest, "TopBar_Register");
					} else {
						ABTest.LogEvent(kobUpgradeButtonTextTest, "NotTopBar_Register");
					}
				}
				
				if (IsActive(kobStartBarTest)) {
					ABTest.LogEvent(kobStartBarTest, "Register");
				}
				*/
			} catch (e:Error) {
				trace("ignoring error in ABTest.HandleRegistration: " + e + ", " + e.getStackTrace());
			}
		}

		public static function HandleUpgrade(strPath:String, strPaymentMethod:String): void {
			try {
				if (IsActive(kobPayPalTest)) {
					ABTest.LogEvent(ABTest.kobPayPalTest, "Upgrade");
					ABTest.LogEvent(ABTest.kobPayPalTest, strPaymentMethod + "Upgrade");
				}
				/* Inactive but kept as an AB test example
				if (IsActive(kobTouchupTest))
					ABTest.LogEvent(ABTest.kobTouchupTest, "Upgrade");

				if (IsActive(kobRedirectTest))
					ABTest.LogEvent(ABTest.kobRedirectTest, "Upgrade");
					
				if (IsActive(kobAdTest))
					ABTest.LogEvent(ABTest.kobAdTest, "Upgrade");
				if (IsActive(kobNewUpgradeDialog)) {
					ABTest.LogEvent(kobNewUpgradeDialog, "Upgrade");
				}
				
				// Upgrade button text upgrade handling
				if (IsActive(kobUpgradeButtonTextTest)) {
					if (EventOccured(kobUpgradeButtonTextTest, "Click")) {
						ABTest.LogEvent(kobUpgradeButtonTextTest, "TopBar_Upgrade");
					} else {
						ABTest.LogEvent(kobUpgradeButtonTextTest, "NotTopBar_Upgrade");
					}
				}
				
				if (IsActive(kobStartBarTest)) {
					ABTest.LogEvent(kobStartBarTest, "Upgrade");
				}
				*/
			} catch (e:Error) {
				trace("ignoring error in ABTest.HandleUpgrade: " + e + ", " + e.getStackTrace());
			}
		}
		
		public static function EventOccured(obTest:Object, strEvent:String): Boolean {
			var obStatus:Object = LookupTestStatus(obTest);
			if (obStatus == null) return false;
			return (strEvent in obStatus);
		}

		private static function LookupTestStatus(obTest:Object): Object {
			var strUserTestId:String = obTest.name;
			
			if (_obIDMap == null)
				LoadActiveTests();
				
			if (!(strUserTestId in _obIDMap)) return null;
			return _obIDMap[strUserTestId];
		}
		
		public static function IsActive(obTest:Object): Boolean {
			if (_fLockedOut) return false;
			return LookupTestStatus(obTest) != null;
		}
		
		private static function LoadActiveTests(): void {
			// Returns null if this account is locked out
			// Returns an empty array if there are no active tests
			_obIDMap = {};
			var strTests:String = Session.LoadABTests();
			if (strTests == "LOCKED_OUT") {
				_fLockedOut = true;
			} else {
				if (strTests == null || strTests == "") return;
				var astrTests:Array = strTests.split(',');
				for each (var strTest:String in astrTests) {
					_obIDMap[strTest] = {};
				}
			}
		}
		
		private static function SaveActiveTests(): void {
			if (_obIDMap == null) return;
			if (_fLockedOut) return;
			var astrActiveTests:Array = [];
			for (var strKey:String in _obIDMap) astrActiveTests.push(strKey);
			Session.SaveABTests(astrActiveTests.join(','));
		}
		
		// This user has performed some suspicious activity (e.g. a refund)
		// We think they might be a fraudulent users and do not want
		// to consider them for this test. Lock them out forever after
		public static function LockOutUserTests(): void {
			_fLockedOut = true;
			Session.SaveABTests("LOCKED_OUT");
		}
		
		private static function GetUserId(): String {
			return Session.GetMachineId();
		}
		
		private static function GetUserTestId(obTest:Object): String {
			return GetUserId() + obTest.name;
		}
	}
}