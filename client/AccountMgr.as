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
	// AccountMgr owns all the UI and logic for signing in/out, creating/editing accounts,
	// and loading/saving user state.
	
	import api.PicnikRpc;
	import api.RpcResponse;
	
	import bridges.*;
	import bridges.flickr.FlickrThirdPartyAccount;
	import bridges.picnik.PicnikStorageService;
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceRegistry;
	
	import com.adobe.crypto.MD5;
	import com.adobe.utils.DateUtil;
	
	import dialogs.IBusyDialog;
	import dialogs.PrivacyPolicyManager;
	
	import events.*;
	
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.system.Capabilities;
	import flash.utils.*;
	
	import mx.collections.ArrayCollection;
	import mx.core.Application;
	import mx.events.PropertyChangeEvent;
	import mx.resources.ResourceBundle;
	import mx.utils.ObjectProxy;
	import mx.utils.ObjectUtil;
	
	import util.AutoResizeMode;
	import util.CreditCardTransaction;
	import util.GoogleUtil;
	import util.PicnikAlert;
	import util.UserEmailDictionary;

	[Event(name=LoginEvent.COMPLETE, type="events.LoginEvent")]
	
	public class AccountMgr extends EventDispatcher {

  		[Bindable] [ResourceBundle("AccountMgr")] protected var rb:ResourceBundle;
		private static var s_actm:AccountMgr; // AccountMgr singleton
		
		private var _bsy:IBusyDialog;
		private var _strCurrentUserId:String;
		
		// State for the LogIn state machine
		private var _usr:Object = new Object();
		private var _usrLastSaved:Object = new Object();
		
		private var _strTempDisplayName:String = ""; // Used when there is no display name

		// Specify which real variables impact which calculated variables. One real variable to many calc variables.
		private static var kdctUserCalcVals:Object = {
			validated: ['isGuest', 'isPremium'],
			nPaidDaysLeft: ['isPremium', 'isPaid', 'isExpired', 'expiredDaysAgo', 'IsCancelable', 'timeToRenew'],
			strSubscription: ['dateSubscriptionExpires'],
			perms: ['perms','isAdmin', 'isCollageAuthor', 'isBeta'],
			name: ['name', 'isPremium', 'isExpired', 'hasCredentials', 'displayName', 'hasPicnikCredentials', 'timeToRenew'],
			dtCreated: ['dateCreated'],
			autoResizeMode: ['autoResizeMode'],
			flickr_username: ['displayName'],
			strGoogleEmail: ['displayName', 'isGoogleAccount', 'email', 'hasEmailAddress', 'hasGoogleCredentials', 'hasCredentials'],
			email: ['email', 'hasEmailAddress'],
			wantsmail: ['wantsMail'],
			cAutoRenew: ['autoRenew'],
			nCCTransId: ['IsCancelable'] ,
			chCCType: ['isPayPal', 'timeToRenew']
		}
		
		// Service-specific accounts -- these will be abstracted at some point
//		private var _tpaMyPicnik:ThirdPartyAccount;
		private var _tpaFlickr:ThirdPartyAccount;
		private var _tpaPicasaWeb:ThirdPartyAccount;
		private var _tpaFacebook:ThirdPartyAccount;
		private var _tpaPhotobucket:ThirdPartyAccount;
		private var _tpaTwitter:ThirdPartyAccount;
		//private var _tpaTinyPic:ThirdPartyAccount;
		private var _tpaPicnik:ThirdPartyAccount;
		private var _tpaGallery:ThirdPartyAccount;
		private var _tpaYahooMail:ThirdPartyAccount;
		private static var s_atpa:Array = new Array();
		
		private static var _acThirdPartyStoargeServices:ArrayCollection = null;
		private static const kastrThirdPartyStorageServices:Array =
			["picasaweb", "flickr", "facebook", "photobucket"];

		public static function GetThirdPartyAccount(strName:String): ThirdPartyAccount {
			return AccountMgr.GetInstance().GetThirdPartyAccount(strName);
		}

		public static function GetThirdPartyStorageServices(): ArrayCollection {
			if (_acThirdPartyStoargeServices == null) {
				_acThirdPartyStoargeServices = new ArrayCollection();
				for each (var strServiceId:String in kastrThirdPartyStorageServices) {
					var obInfo:Object = StorageServiceRegistry.GetStorageServiceInfo(strServiceId);
					if (obInfo == null) {
						trace("missing service info: " + strServiceId);
						continue;
					}
					if (!('name' in obInfo)) {
						trace("service missing name: " + strServiceId);
						continue;
					}
					var fInclude:Boolean = true;
					if ("visible" in obInfo && !obInfo.visible) fInclude = false;
					if (fInclude) {
						_acThirdPartyStoargeServices.addItem(new ObjectProxy({id:strServiceId, name:obInfo.name}));
					}
				}
			}
			return _acThirdPartyStoargeServices;
		}
		
		public static function GetStorageService(strServiceId:String): IStorageService {
			var tpa:ThirdPartyAccount = GetThirdPartyAccount(strServiceId);
			if (null == tpa) return null;
			return tpa.storageService;
		}
		
		public static function get accounts(): Array {
			return s_atpa;
		}
		
		public static function GetInstance(): AccountMgr {
			if (s_actm == null)
				s_actm = new AccountMgr();
			return s_actm;
		}
		
		private var _tmrPremiumCheckDelay:Timer = null;
		
		public function DelayedCheckForPremium(msDelay:Number=1000): void {
			if (_tmrPremiumCheckDelay != null)
				_tmrPremiumCheckDelay.stop();
			_tmrPremiumCheckDelay = new Timer(msDelay, 1);
			_tmrPremiumCheckDelay.start();
			var strUserID:String = GetUserId();
			_tmrPremiumCheckDelay.addEventListener(TimerEvent.TIMER, function(evt:Event): void {
				_tmrPremiumCheckDelay.stop();
				_tmrPremiumCheckDelay = null;
				if (strUserID == GetUserId() && !isPaid) {
					RefreshUserAttributes();
				}
			});
		}
		
		public function IsLoggedIn(): Boolean {
			return Session.GetCurrent().isLoggedIn;
		}
		
		public function GetUserId(): String {
			return Session.GetCurrent().userId;
		}
		
		/**** BEGIN: User Attribute Wrappers ****/
		[Bindable]
		public function get userId():String {
			return _strCurrentUserId;
		}
		public function set userId(strUserId:String):void
		{
			_strCurrentUserId = strUserId;
		}
		
		[Bindable]
		public function set isGuest(f:Boolean): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: isGuest not directly set-able");
		}
		
		public function get isGuest():Boolean {
			return GetUserAttribute('validated', '') == 'G';
		}
		
		[Bindable]
		public function set hasPicnikCredentials(f:Boolean): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: hasPicnikCredentials not directly set-able");
		}
		
		// "hasCredentials" returns true if the user has PICNIK credentials
		public function get hasPicnikCredentials():Boolean {
			var strName:String = GetUserAttribute('name', '');
			return (strName != '' && strName != 'Guest');
		}
		
		[Bindable]
		public function set hasCredentials(f:Boolean): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: hasCredentials not directly set-able");
		}
		
		// "hasCredentials" returns true if the user has PICNIK credentials or GOOGLE credentials
		public function get hasCredentials():Boolean {
			return hasPicnikCredentials || hasGoogleCredentials;
		}
		
		[Bindable]
		public function set isPayPal(f:Boolean): void {
			Debug.Assert(false, "AccountMgr: isPayPal not directly set-able");
		}
		
		// "isPayPal" is true if the user is premium and paid with paypal
		public function get isPayPal():Boolean {
			return GetUserAttribute('chCCType') == 'P';
		}

		[Bindable]
		public function set hasGoogleCredentials(f:Boolean): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: hasGoogleCredentials not directly set-able");
		}
		
		// "hasCredentials" returns true if the user has PICNIK credentials
		public function get hasGoogleCredentials():Boolean {
			return GetUserAttribute('strGoogleEmail', '').length > 0;
		}

		[Bindable]
		public function set isGoogleAccount(f:Boolean): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: isGoogleAccount not directly set-able");
		}
		
		// "hasCredentials" returns true if the user has PICNIK credentials
		public function get isGoogleAccount():Boolean {
			return hasGoogleCredentials;
		}

		[Bindable]
		public function set hasEmailAddress(f:Boolean):void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: hasEmailAddress not directly set-able");
		}
				
		public function get hasEmailAddress():Boolean {
			if (isGoogleAccount)
				return true;
				
			var obEmail:String = GetUserAttribute("email", "");
			if (!obEmail || obEmail.length==0)	return false;
			return true;
		}			

		[Bindable]
		public function set expiredDaysAgo(n:Number): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: expiredDaysAgo not directly set-able");
		}
		
		// Always returns a number. Returns a very large number for expired accounts. Returns a negative number for not yet expired accounts
		// Does not necessarily return whole numbers
		public function get expiredDaysAgo(): Number {
			return -paidDaysLeft;
		}
		
		private function get paidDaysLeft(): Number {
			var nPaidDaysLeft:Number = -40000; // Expired around 1900
			try {
				nPaidDaysLeft = Number(GetUserAttribute('nPaidDaysLeft', '-40000'));
			} catch (e:Error) {
				trace("Ignoring error: " + e);
				nPaidDaysLeft = -40000;
			}
			return nPaidDaysLeft;
		}
		
		[Bindable]
		public function set dateSubscriptionExpires(dt:Date): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: dateSubscriptionExpires not directly set-able");
		}
		
		// Always returns a date. Returns a date in the past expired/never upgraded accounts
		public function get dateSubscriptionExpires(): Date {
			var dateExpires:Date = new Date(1990); // Default to a very old date
			var strT:String = GetUserAttribute('strSubscription', null);
			if (strT && strT.length > 0) {
				try {
					dateExpires = new Date(strT);
				} catch (e:Error) {
					trace(e + ", " + e.getStackTrace());
				}
			}
			return dateExpires;
		}

		// are we a paid customer?  Is it within 30 days of our expiration date?
		[Bindable]
		public function set timeToRenew(f:Boolean): void {
			Debug.Assert(false, "AccountMgr: timeToRenew not directly set-able");
		}
		public function get timeToRenew():Boolean {
			if (isGuest || isNaN(dateSubscriptionExpires.valueOf()))
				return false;
			if (isPaid && isPayPal)
				return false; // PayPal users have auto-renew. Don't let them renew.
			return (paidDaysLeft < 30) && (paidDaysLeft > -360); // UNDONE: How does this work for monthly subscriptions?
		}

		[Bindable]
		public function set daysUntilExpiration(i:int): void {
			Debug.Assert(false, "AccountMgr: daysUntilExpiration not directly set-able");
		}
		
		// gives number of days until your premium account expires
		// if 0 is returned, account expires today, 1: tomorrow, etc.
		// can return negative numbers if account is already expired
		// you should first make sure the account is premium and has an
		// expiration date to begin with.
		public function get daysUntilExpiration():int {
			return Math.floor(paidDaysLeft);
		}
		
		[Bindable]
		public function set dateCreated(dt:Date): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: dateCreated not directly set-able");
		}
		
		// Always returns a date. Returns a date in the past expired/never upgraded accounts
		public function get dateCreated(): Date {
			var dateCreated:Date = GetUserAttribute('dtCreated', null) as Date;
			if (dateCreated == null) {
				var strT:String = GetUserAttribute('dtCreated', null) as String;
				if (strT && strT.length > 0) {
					try {
						strT = strT.replace(' ', 'T');
						dateCreated = DateUtil.parseW3CDTF(strT + '-00:00');
					}catch(e:Error) {
						trace(e + ", " + e.getStackTrace());
					}
				}
			}
			return dateCreated;
		}
		
		public function GetMaxArea(): Number {
			if (PicnikConfig.autoResizeEnabled) {
				if (autoResizeMode in AutoResizeMode.modeToAreaMap)
					return AutoResizeMode.modeToAreaMap[autoResizeMode];
				else {
					trace("Unknown auto resize mode: " + autoResizeMode);
				}
			}
			// Default
			return Number.MAX_VALUE;
		}
		
		[Bindable]
		public function set autoResizeMode(strMode:String): void {
			if (!(strMode in AutoResizeMode.modeToAreaMap))
				throw new Error("Unknown auto resize mode: " + strMode);
			SetUserAttribute('client.document.autoResizeMode', strMode, false);
		}

		public function get autoResizeMode(): String {
			return GetUserAttribute('client.document.autoResizeMode', AutoResizeMode.PRINT);
		}
		
		[Bindable]
		public function set isPremium(f:Boolean): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: isPremium not directly set-able");
		}
		
		public function get isPremium():Boolean {
			return isPaid || (!isGuest && (PicnikConfig.freeForAll || PicnikConfig.freePremium));
		}		
		
		[Bindable]
		public function set isPaid(f:Boolean): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: isPaid not directly set-able");
		}
		
		public function DispatchDummyIsPaidChangeEvent(): void {
			var obPrevVals:Object = {};
			var obVals:Object = {};
			if (isPaid) {
				obPrevVals.isPaid = false;
				obVals.isPaid = true;
			}
			if (isPremium) {
				obPrevVals.isPremium = false;
				obVals.isPremium = true;
			}
			PicnikBase.app.callLater(DispatchPropertyChangeEvents, [obPrevVals, obVals]);			
		}
		
		public function get isPaid():Boolean {
			return expiredDaysAgo <= 0;
		}
		
		[Bindable]
		public function set isExpired(f:Boolean): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: isExpired not directly set-able");
		}
		
		public function get isExpired():Boolean {
			/*
				return true if the user was a paid user and is no longer a paid user.
				return false if the user is paid and current
				return false if the user was never a paid user
			*/
			var strT:String = GetUserAttribute('strSubscription', null);
			if (strT && strT.length > 0 && strT != "null") {
				var dt:Date = dateSubscriptionExpires;
				if (dt < new Date(1999))
					return false;
				return paidDaysLeft < 0;
			}
			return false;
		}
		
		[Bindable]
		public function set isAdmin(f:Boolean): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: isAdmin not directly set-able");
		}
		
		public function get isAdmin(): Boolean {
			return (perms & Permissions.Admin) != 0;
		}

		[Bindable]
		public function set isCollageAuthor(f:Boolean): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: isCollageAuthor not directly set-able");
		}
		
		public function get isCollageAuthor(): Boolean {
			return isAdmin; // For now, tie this to the admin bit
		}
		
		[Bindable]
		public function set isBeta(f:Boolean): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: isBeta not directly set-able");
		}
		
		public function get isBeta(): Boolean {
			return (perms & Permissions.BetaTester) != 0;
		}

		[Bindable]
		public function set wantsMail(f:Boolean): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: wantsMail not directly set-able");
		}
		
		public function get wantsMail():Boolean {
			return (AccountMgr.GetInstance().GetUserAttribute('wantsmail') != "N" );
		}

		[Bindable]
		public function set autoRenew(f:Boolean): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: autoRenew not directly set-able");
		}
		
		public function get autoRenew():Boolean {
			return (AccountMgr.GetInstance().GetUserAttribute('cAutoRenew') != "N" );
		}

		// TODO (steveler): This function is deprecated in favor of SubscriptionStatus.isCancelable.
		// Remove this after the new myaccount is launched.
		public function IsCancelable(nDuration:int=365):Boolean {
			var strT:String = GetUserAttribute('strSubscription', 'null');
			if (!strT || strT == 'null')
				return false;
			var dateExpire:Date = new Date(strT);

			strT = GetUserAttribute('nCCTransId', '0')	
			var nT:Number = Number(strT);
			if (nT <= 0)
				return false;

			// if the date is more than a year off, than this is a special date, we can't cancel it
			// Make sure we add a little padding for early renewals (e.g. my account expires in a few days so I renew now)
			if (paidDaysLeft > (nDuration + 31))
				return false;
				
			// subtract the duration from the expire date to get the start date.
			// compare the started to the date 31 (or 2) days ago. If the start date is newer than
			// that then we allow it to be canceled.
			var nGracePeriod:Number = (nDuration >= CreditCardTransaction.knSixMonths) ? 31 : 2;
			var nDaysUsed:Number = nDuration - paidDaysLeft;
			return (nDaysUsed < nGracePeriod);
		}

		[Bindable]
		public function set perms(i:int): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: user perms not directly set-able");
		}
		
		public function get perms(): int {
			return int(GetUserAttribute("perms", 0));
		}
		
		[Bindable]
		public function set name(strName:String): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: user name not directly set-able");
		}
		
		public function get name(): String {
			return String(GetUserAttribute('name', ''));
		}	
			
		[Bindable]
		public function set displayName(strName:String): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: displayName not directly set-able");
		}
		
		public function get displayName(): String {
			var strName:String;
			
			// Default to google email
			strName = String(GetUserAttribute('strGoogleEmail', ''));
			
			// Next, try picnik username
			if (strName.length == 0) {
				strName = String(GetUserAttribute('name', ''));
			}
			
			// Then try flickr name
			if (strName.length == 0) {
				// try to find a displayName from the thirdparty account authentication
				// right now flickr is the only one who does this, so we just hardcode flickr
				strName = String(GetUserAttribute('flickr_username', ''));
			}
			if (strName.length == 0) {
				strName = _strTempDisplayName;
			}
			return strName;
		}
		
		// Set the temporary display name to be used if no other display name is available.
		public function set tempDisplayName(strName:String): void {
			var strPrev:String = displayName;
			if (strName == null) strName = ""; // Don't set it to a null value
			_strTempDisplayName = strName;
			var strNew:String = displayName;
			if (strPrev != strNew) {
				dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, 'displayName', strPrev, strNew));
			}
		}

		[Bindable]
		public function set email(strEmail:String): void {
			// change events for this property are manually propagated. 
			// See AccountMgr.kdctUserCalcVals and AccountMgr.DispatchPropertyChangeEvents
			Debug.Assert(false, "AccountMgr: user email not directly set-able");
		}
		
		public function get email(): String {
			if (isGoogleAccount)
				return String(GetUserAttribute('strGoogleEmail', ''));
			return String(GetUserAttribute('email', ''));
		}
		
		/**** END: User Attribute Wrappers ****/

		public function ClearServiceAccounts(fAll:Boolean=true): void {
			if (accounts) {
				for each (var tpa:ThirdPartyAccount in accounts) {
					if (tpa && tpa.HasCredentials() && (fAll || (tpa.IsExclusive() && !tpa.IsPrimary()))) {
						tpa.RemoveCredentials();
					}
				}
			}
		}
		
		public function GetConnectedServiceAccounts(): Array {
			var atpaConnected:Array = new Array;
			
			if (accounts) {
				for each (var tpa:ThirdPartyAccount in accounts) {
					if (tpa && tpa.IsExclusive() && !tpa.IsPrimary() && tpa.HasCredentials()) {
						atpaConnected.push( tpa );		
					}
				}
			}
			return atpaConnected;
		}
		
		private function GetThirdPartyAccount(strAccountName:String): ThirdPartyAccount {
			if (null == strAccountName) return null;
			switch (strAccountName.toLowerCase()) {
//			case "mypicnik":
//				if (!_tpaMyPicnik) {
//					_tpaMyPicnik = new ThirdPartyAccount("MyPicnik", new MyPicnikStorageService());
//					s_atpa.push(_tpaMyPicnik);
//				}
//				return _tpaMyPicnik;
				
			case "flickr":
				if (!_tpaFlickr) {
					_tpaFlickr = new FlickrThirdPartyAccount("Flickr",  StorageServiceRegistry.CreateStorageService("flickr"));
					s_atpa.push(_tpaFlickr);
				}
				return _tpaFlickr;
			
			case "photobucket":
				if (!_tpaPhotobucket) {
					_tpaPhotobucket = new ThirdPartyAccount("Photobucket", StorageServiceRegistry.CreateStorageService("photobucket"));
					s_atpa.push(_tpaPhotobucket);
				}
				return _tpaPhotobucket;

			case "picasaweb":
				if (!_tpaPicasaWeb) {
					_tpaPicasaWeb = new ThirdPartyAccount("PicasaWeb", StorageServiceRegistry.CreateStorageService("picasaweb"));
					s_atpa.push(_tpaPicasaWeb);
				}
				return _tpaPicasaWeb;

			case "facebook":
				if (!_tpaFacebook) {
					_tpaFacebook = new ThirdPartyAccount("Facebook", StorageServiceRegistry.CreateStorageService("facebook"));
					s_atpa.push(_tpaFacebook);
				}
				return _tpaFacebook;
			
			/*	
			case "tinypic":
				if (!_tpaTinyPic) {
					_tpaTinyPic = new ThirdPartyAccount("TinyPic", new TinyPicStorageService());
					s_atpa.push(_tpaTinyPic);
				}
				return _tpaTinyPic;
			*/	
			case "twitter":
				if (!_tpaTwitter) {
					_tpaTwitter = new ThirdPartyAccount("Twitter", StorageServiceRegistry.CreateStorageService("twitter"));
					s_atpa.push(_tpaTwitter);
				}
				return _tpaTwitter;
				
			case "show":
			case "gallery":
				if (!_tpaGallery) {
					_tpaGallery = new PicnikAccount("Show",  StorageServiceRegistry.CreateStorageService("show"));
					s_atpa.push(_tpaGallery);
				}
				return _tpaGallery;

			case "picnik":
				if (!_tpaPicnik) {
					_tpaPicnik = new PicnikAccount("Picnik", new PicnikStorageService("share"));
					s_atpa.push(_tpaPicnik);
				}
				return _tpaPicnik;

			case "yahoomail":
				if (!_tpaYahooMail) {
					_tpaYahooMail = new ThirdPartyAccount("YahooMail",  StorageServiceRegistry.CreateStorageService("yahoomail"));
					s_atpa.push(_tpaYahooMail);
				}
				return _tpaYahooMail;
			}

			return null;
		}

		private function GetDependentVals(strAttribute:String): Object {
			var obVals:Object = new Object();
			obVals[strAttribute] = GetUserAttribute(strAttribute);
			if (strAttribute in kdctUserCalcVals)
				for each (var strCalcFieldName:String in kdctUserCalcVals[strAttribute])
					obVals[strCalcFieldName] = this[strCalcFieldName];
			return obVals;
		}
		
		private function DispatchPropertyChangeEvents(obPrevVals:Object, obVals:Object): void {
			for (var strAttribute:String in obVals)
				if (obPrevVals[strAttribute] != obVals[strAttribute])
					dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, strAttribute, obPrevVals[strAttribute], obVals[strAttribute]));
		}

		[Bindable (event="attributeChange")]
		public function GetUserAttribute(strAttribute:String, obDefaultValue:* = undefined): * {
			var obVal:* = _usr[strAttribute];
			if (obVal == undefined) return obDefaultValue;
			else return obVal;
		}
		
		// UNDONE: Move these field descriptors to the db and fetch them with a REST call
	
		// Some attributes have their own fields in the database, others are
		// adhoc and placed in a single XML field. It's up to us to define
		// namespaces for the adhoc attributes to avoid collision. The
		// convention is to use class name, e.g. YahooSearchInBridge.strLastSearch
		//
		// Set/GetUserAttribute encapsulate the conversion from arbitrary
		// type to/from String for adhoc attributes.
		private static var s_astrDbFields:Array = [
			"id", "name", "email", "password", "lastlogin", "validated", "flickrauthtoken", "cAutoRenew", "wantsmail",
			"userid", "strGoogleEmail", "strGoogleToken", "flickr_nsid", "flickr_username", "flickr_fullname", "testkey", "perms", "strSubscription", "nPaidDaysLeft", "nCCTransId",
			"chCCType", "dtCreated"
		];

		// This dictionary contains fields which are copied over from an account
		// when a guest user logs in within the app. For most fields, we use the current (guest) value.
		// For example, if the guest user has created a connection for a bridge, use that connection.
		// For some fields, it makes more sense to use the saved user value (e.g. permissions)
		private static const kdctLoggedInFields:Object = {
			perms: true, name: true, validated: true, email: true, id: true, wantsmail: true, 
			cAutoRenew: true, userid: true, nPaidDaysLeft:true, dtCreated:true
		};
		
		// UNDONE: how to clear an attribute?
		public function SetUserAttribute(strAttribute:String, obVal:Object, fFlush:Boolean=true): void {
			var obPrevVals:Object = GetDependentVals(strAttribute);
			if (obVal != obPrevVals[strAttribute]) {
				if (strAttribute == "email") UserEmailDictionary.global.UserEmailChanging(obPrevVals[strAttribute] as String, obVal as String);
				_usr[strAttribute] = obVal;
				
				// Delay dispatching so all attributes will be set before change handlers
				// kick in which may be interested in related new attributes.
				DelayedDispatchPropertyChangeEvents(obPrevVals, GetDependentVals(strAttribute));
			}
			
			if (fFlush)
				FlushUserAttributes();
		}
		
		private function DelayedDispatchPropertyChangeEvents(obPrevVals:Object, obVals:Object): void {
			var fn:Function = function (): void {
				dispatchEvent(new AccountEvent(AccountEvent.USER_ATTRIBUTE_CHANGE));
				DispatchPropertyChangeEvents(obPrevVals, obVals);
			}
			PicnikBase.app.callLater(fn);
		}
		
		// fnDone(err:Number, strError:String);
		public function FlushUserAttributes(fnDone:Function=null): void {
			var obAttributes:Object = new Object();
			
			// Write all changed attributes
			var fChanged:Boolean = false;
			for (var strAttribute:String in _usr) {
				if (_usr[strAttribute] != _usrLastSaved[strAttribute]) {
					// Db fields (exclude the XML fields)
					if (s_astrDbFields.lastIndexOf(strAttribute) != -1) {
						obAttributes[strAttribute] = _usr[strAttribute];
						
					// XML fields (exclude the Db fields)
					} else {
						var xmlProperties:XML = Util.XmlPropertiesFromOb(_usr, "Properties", s_astrDbFields, true);
						obAttributes["xml_attrs"] = xmlProperties.toString();
					}
					fChanged = true;
				}
			}
			
			// Update the user's server-persisted state
			if (fChanged) {
				// Work with a copy of the _usr object rather than a reference so we
				// aren't vulnerable to changes to the original.
				var usrSaving:Object = ObjectUtil.copy(_usr);
				PicnikService.SetUserAttributes(obAttributes, function (err:Number, strError:String, obResult:Object=null): void {
					if (err == PicnikService.errNone) {
						_usrLastSaved = usrSaving;
						if ("tokencookie" in obResult) {
							PicnikService.SetUserTokenCookie( obResult["tokencookie"] );
						}						
						if ("userkey" in obResult) {
							var strOldToken:String = Session.GetCurrent().token;
							PicnikService.SetUserToken( obResult["userkey"] );
							Session.GetCurrent().token = obResult["userkey"]
							Session.GetCurrent().SaveSession();
						}
					}
					if (fnDone != null)
						fnDone(err, strError);
				});
			} else {
				if (fnDone != null)
					fnDone(PicnikService.errNone, null);
			}
		}
		
		/* Here is an outline of the login process. Due to all the asynchronous
		operations involved the actual implementation is hard to follow but it
		does execute in this, very important, sequence.
		
		AutoLogIn:
			Check to see if there is a cookie w/ a frob.
			If no frob then send the user back to picnik to login.
			If there is a frob, get the attributes for that user.
			If the getattribute call fails, return the user to picnik to login.
			At this point we believe that we have a valid user.
			if there is already a flickr token
				initialize flickr account info
			
			call the passed in done handler.
 		*/
		
		private function SetName(strUsername:String): void {
			SetUserAttribute('name', strUsername, false);
		}
		
		private function SetIsGuest(fIsGuest:Boolean): void {
			SetUserAttribute('validated', fIsGuest ? 'G' : 'N', false);
		}
		
		// fnDone (optinal) will be called with true for success or false for failure
		// function fnDone()
		public function GuestUserUpgraded(fnDone:Function=null): void {
			RefreshUserAttributes(function(): void {
				PicnikBase.app.FinishLogOn();
				if (fnDone != null)
					fnDone();
			});
		}
		
		private function LogUserType(): void {
			try {
				// Now that we know what kind of user this is (guest, registered, subscriber) set
				// things up so the next Urchin call will pass the data to Google Analytics.
				var strVisitorType:String = "guest";
				if (!isGuest)
					strVisitorType = "registered";
				if (isPaid)
					strVisitorType = "subscriber";
				
				Util.UrchinSetVar("Visitor", strVisitorType);
			} catch (e:Error) {
				trace(e); // Ignore errors
				trace(e.getStackTrace());
			}
		}
		
		private function ParseUserAttributes(usr:Object, fOverwriteAll:Boolean=false): void {
			try {
				// Add each Property in the xml_attrs field to the usr object
				try {
					if (usr.xml_attrs)
						Util.ObFromXmlProperties(new XML(usr.xml_attrs), usr, false);
					usr.canLoadDirect = false;
				} catch (e:Error) {
					PicnikService.Log("Ignored Client Exception: in AccountMgr.ParseUserAttributes.1: " + e, PicnikService.knLogSeverityWarning);
					PicnikService.Log("Possibly invalid attribute xml: " + usr.xml_attrs, PicnikService.knLogSeverityWarning);
					if (e.getStackTrace().length > 0)
						PicnikService.Log("Possibly invalid attribute xml (callstack): " + e.getStackTrace(), PicnikService.knLogSeverityWarning);
					trace("Ignored Client Exception: in AccountMgr.ParseUserAttributes.1: " + e);
				}
				delete usr.xml_attrs;

				try {				
					_usrLastSaved = ObjectUtil.copy(usr); // This user is logging in - update our "last saved" to their state.
	
					MergeUserInfo(usr, fOverwriteAll);
				} catch (e:Error) {
					PicnikService.Log("Ignored Client Exception: in AccountMgr.ParseUserAttributes.2: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityWarning);
					trace("Ignored Client Exception: in AccountMgr.ParseUserAttributes.2: " + e + ", "  +e.getStackTrace());
				}
				
				LogUserType();
				
//				try {				
//					//ShowAlert("no frob", "Notice", Alert.OK);
//					// Create a FlickrAccount instance if one doesn't already exist and the user attributes
//					// contain all the FlickrAccount data
//					if (fOverwriteAll && usr.flickrauthtoken) {
//						usr['tpa.Flickr._token'] = usr.flickrauthtoken;
//						usr['tpa.Flickr._userid'] = usr.flickr_nsid;
//						usr['tpa.Flickr._username'] = usr.flickr_username;
//						usr['tpa.Flickr._fullname'] = usr.flickr_fullname;						
//					}
//				} catch (e:Error) {
//					PicnikService.Log("Ignored Client Exception: in AccountMgr.ParseUserAttributes.3 (loading flickr token): " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityWarning);
//					trace("Ignored Client Exception: in AccountMgr.ParseUserAttributes.3 (loading flickr token): " + e + ", "  +e.getStackTrace());
//				}

			} catch (e:Error) {
				PicnikService.Log("Client Exception: in AccountMgr.ParseUserAttributes: " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityError);
				trace("Client Exception: in AccountMgr.ParseUserAttributes: " + e + ", "  +e.getStackTrace());
				throw e;
			}
		}
		
		private function PreferNewAttribute(strField:String): Boolean {
			return strField in kdctLoggedInFields;
		}
		
		private function EmptyValue(val:*, strField:String): Boolean {
			if (val == null) return true;
			if (val == undefined) return true;
			if (val is Number) return isNaN(val as Number);
			if (strField == "flickrauthtoken" && val == "undefined") return true; // Hack for flickr auth token - "undefined" means null
			if (val is String) return (val as String).length == 0;
			
			// Everything else, non-null means non-empty
			return false;
		}

		private function MergeUserInfo(usrNew:Object, fOverwriteAll:Boolean=false): void {
			// Merge in new settings. Don't overwrite existing settings. Unless PreferNewAttribute() returns true.
			// Clear old fields
			var strField:String;
			
			for (strField in _usr) {
				if (!(strField in usrNew)) {
					SetUserAttribute(strField, null, false);
				}
			}
			for (strField in usrNew) {
				if (fOverwriteAll || PreferNewAttribute(strField) || (!(strField in _usr)) || EmptyValue(_usr[strField], strField) ) {
					SetUserAttribute(strField, usrNew[strField], false);
				}
			}
			FlushUserAttributes();
			dispatchEvent(new AccountEvent(AccountEvent.USER_CHANGE));
		}
		
		// fnDone = function(): void
		public function RefreshUserAttributes(fnDone:Function = null, fSave:Boolean = true):void {
			var fnGetAttributes:Function = function(err:Number=0, str:String=null): void {
				PicnikService.GetUserAttributes(
					function(err:Number, strError:String, usr:Object=null):void {
						try {
							if (usr == null && err == PicnikService.errNone) {
								err = PicnikService.errFail;
								strError = "usr is null";
							}
							if (err != PicnikService.errNone) {
								PicnikService.Log("Refresh_GetUserAttributes failed: " + err + ", strError: " + strError, PicnikService.knLogSeverityError);
							} else {
								try {
									ParseUserAttributes(usr, true);
								} catch (e:Error) {
									// In case there is an error, make sure we always call our return function so the caller can clean up
									var strMsg:String = "Client Exception in AccountMgr.Refresh";
									strMsg += e + ", " + e.getStackTrace();
									PicnikService.Log(strMsg, PicnikService.knLogSeverityError);
								}
							}
						} finally {
							if (fnDone != null) fnDone();
						}
					});
			};
			
			if (fSave)
				FlushUserAttributes(fnGetAttributes);
			else
				fnGetAttributes();
		}

		// function fnDone(fSuccess:Boolean): void
		public function LogOut(fnDone:Function=null, fIgnoreThirdPartyCreds:Boolean=false): Boolean {
			// as we're logged out, make sure the bridges don't allow the new guest account
			// access to the old accounts' bridges
			if (PicnikBase.app._brgcIn._vstk != null) {
				for each (var obChild:Object in PicnikBase.app._brgcIn._vstk.getChildren()) {
					if (obChild as Bridge != null && "RequireAuthorization" in obChild)
						obChild.RequireAuthorization();
				}
			}
			if (PicnikBase.app._brgcOut._vstk != null) {
				for each (obChild in PicnikBase.app._brgcOut._vstk.getChildren()) {
					if (obChild as Bridge != null && "RequireAuthorization" in obChild)
						obChild.RequireAuthorization();
				}
			}
			
			if (isGuest) {
				Session.GetCurrent().LogOut();
				if (fnDone != null) Application.application.callLater(fnDone, [true]);
			} else {
				fIgnoreThirdPartyCreds = fIgnoreThirdPartyCreds || isGoogleAccount || PicnikBase.app.hasGoogleCreds();
				if (isGoogleAccount) {
					GoogleUtil.PopupGoogleLogOut();
				}
				LogOutToNewGuest(function(resp:RpcResponse): void {
					PicnikBase.app.uimode = PicnikBase.kuimWelcome;
					if (resp.isError) {
						PicnikBase.app.HandleError(resp.errorCode, "Signout problem. " + resp.errorMessage);
					} else {
						PicnikBase.app.FinishLogOn();
						PicnikBase.app.Notify(Resource.getString("AccountMgr", "signedOut"));
					}
					if (fnDone != null) fnDone(!resp.isError);
				}, fIgnoreThirdPartyCreds);
			}
			return true;
		}

		public static function GetTokenLogInCredentials(strToken:String): Object {
			return {authtype:'picniktoken', userkey:strToken};
		}
		
		public static function GetGuestLogInCredentials(): Object {
			return {authtype:'guest'};
		}

		public static function GetThirdPartyLogInCredentials(strService:String, strThirdPartyUserId:String, strThirdPartyToken:String): Object {
			return { authtype:'thirdparty', authservice: strService, id: strThirdPartyUserId, token: strThirdPartyToken };
		}
		
		public static function GetGoogleLogInCredentials(strThirdPartyToken:String): Object {
			return { authtype:'thirdparty', authservice: 'google', id: '', token: strThirdPartyToken };
		}
		
		public static function GetPicnikLogInCredentials(strUserName:String, strClearTextPassword:String): Object {
			return { authtype:'picnik', username:strUserName, password: MD5.hash(strClearTextPassword)};
		}

		// fnDone(resp:RpcResponse): void 		
		private function DoLogIn(obParameters:Object, fRetry:Boolean, fnDone:Function): void {
			// Add user instrumentation
			try {
				obParameters.obCabapilities = {os:Capabilities.os, flashVersion:Capabilities.version, userAgent:Util.userAgent};
			} catch (e:Error) {
				trace("Ignoring error:", e);
			}
			var fnOnLogIn:Function = function(resp:RpcResponse): void {
				if (resp.isError) {
					// Something went wrong
					// Something else went wrong. Log it if it is serious
					PicnikService.LogWithExtendedInfo("DoLogin2_Login failed: " + resp.errorCode + ", strError: " + resp.errorMessage, function(): void {
						// Wait for the logging to finish, then carry on.
						fnDone(resp);
					}, PicnikService.knLogSeverityError);
				} else if ('logInFailureCode' in resp.data) {
					// User tried to log in with a bad username or password. This is expected.
					
					// Callers of this function expect the error returned as an exception.
					// Eventually, it would be nice to rewrite the callers to expect these failures as part of the response data
					// Until we have time to rewrite (and test) callers, reformat the response object to make this failure
					// look like an exception.
					resp.errorCode = resp.data.logInFailureCode;
					resp.errorMessage = "bad credentials";
					resp.data = null;
					fnDone(resp);
				} else if ('credsNeedingPrivacyPolicy' in resp.data) {
					PrivacyPolicyManager.ShowDetour(resp.data.credsNeedingPrivacyPolicy, function(fAccepted:Boolean): void {
						if (fAccepted) {
							// Re-log in using new creds.
							obParameters.privacypolicyrequired = false;
							obParameters.credentials = [resp.data.credsNeedingPrivacyPolicy];
							DoLogIn(obParameters, fRetry, fnDone);
						} else {
							fnDone(new RpcResponse("user.login", PicnikService.errCancelled, "Privacy policy rejected", null));
						}
					});
					
				} else {
					var obUserInfo:Object = resp.data.user;
					var obAttributes:Object = resp.data.attributes;
					
					var strErrorLoc:String = "A";
					try {
						// Install the user (set the session cookie, etc)
						if (obUserInfo == null || (!('userkey' in obUserInfo)) || obUserInfo['userkey'] == null || obUserInfo['userkey'] == '')
							throw new Error("Invalid userkey");
						strErrorLoc = "A.1";
						
						PicnikService.InstallUser(obUserInfo.userkey, obUserInfo.userid, obUserInfo.tokencookie);
						strErrorLoc = "B";

						// Update user attributes
						// QuestionManager.UserChanged();
						strErrorLoc = "D";
						InstallUserAttributes(resp.data.attributes, 'fMerge' in obParameters ? obParameters.fMerge : false);

						try {
							dispatchEvent(new AccountEvent(AccountEvent.USER_ID_CHANGE)); // Let listeners know we have a new user
						} catch (e3:Error) {
							// Log these errors but don't consider them fatal
							PicnikService.LogException("DoLogIn2:dispatch user change event", e3);
						}
					} catch (e:Error) {
						// Fatal error installing the user. Oops! Not much we can do.
						// Maybe we should log in a new guest?
						PicnikService.LogException("DoLogin2:" + strErrorLoc, e);
						resp.errorCode = PicnikService.errFail;
						resp.errorMessage = "DoLogin2:" + strErrorLoc + ":Exception: " + e.toString();
					} finally {
						// Callback
						try {
							fnDone(resp);
						} catch (e2:Error) {
							PicnikService.LogException("DoLogin2:Callback", e2);
						}
					}
				}
			};
			PicnikRpc.LogIn(obParameters, fRetry, fnOnLogIn);
		}

		// fnDone(resp:RpcResponse): void
		public function LogOutToNewGuest(fnDone:Function, fIgnoreThirdPartyCreds:Boolean=false): void {
			var obCreds:Object;
			if (PicnikBase.app.thirdPartyCredentials && !fIgnoreThirdPartyCreds) {
				obCreds = PicnikBase.app.GetThirdPartyCredentials();
				obCreds.fForceCreate = true;
			} else {
				obCreds = AccountMgr.GetGuestLogInCredentials();
			}
			var obParameters:Object = {credentials: [obCreds]};
			obParameters.privacypolicyrequired = true;
			obParameters.fMerge = false;
			DoLogIn(obParameters, true, fnDone);
		}

		// fnDone(resp:RpcResponse): void
		public function InitialLogIn(aobCredentials:Array, strCapabilities:String, strApiKey:String, fnDone:Function): void {
			var obParameters:Object = {credentials: aobCredentials};
			obParameters.privacypolicyrequired = true;
			obParameters.strCapabilities = strCapabilities;
			obParameters.fClientConnect = true;
			obParameters.fMerge = false;
			if (strApiKey)
				obParameters._apikey = strApiKey;
			DoLogIn(obParameters, true, fnDone);
		}
		
		// fnDone(resp:RpcResponse): void
		public function UserInitiatedMerge(obCredentials:Object, fnDone:Function): void {
			UserInitiatedLogIn(obCredentials, fnDone); // Same behavior
		}
		
		// fnDone(resp:RpcResponse): void
		public function UserInitiatedLogIn(obCredentials:Object, fnDone:Function): void {
			var obParameters:Object = {credentials: [obCredentials]};
			obParameters.privacypolicyrequired = true;
			obParameters.fMerge = true;
			DoLogIn(obParameters, false, fnDone);
		}

		private function InstallUserAttributes(obAttributes:Object, fMerge:Boolean): void {
			// GetUserAttributes worked. Install this user.
			// Clear previous user
			if (!fMerge) {
				PicnikBase.app.activeDocument = null;
				ClearServiceAccounts();
			}
			
			// Load the new user
			ParseUserAttributes(obAttributes, !fMerge);
			Session.GetCurrent().LogIn(obAttributes, PicnikService.GetUserToken(), PicnikService.GetUserTokenCookie());
			userId = obAttributes.userid;
		}
	}
}
