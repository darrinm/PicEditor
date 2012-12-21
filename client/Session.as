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
package
{
	import com.adobe.utils.StringUtil;
	
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.system.Security;
	
	import mx.controls.SWFLoader;
	import mx.utils.ObjectUtil;
	
	import util.GooglePlusUtil;
	import util.LocalSession;
	import util.TipManager;

	public class Session
	{
		/********* Constants *********/
		private const knDeepLinkExpiresMinutes:Number = 30; // We remember the tab you were on if it has been less than this much time.
		private const knGuestSessionExpiresMinutes:Number = 30; // Log out guests who return after 30 minutes of inactivity
		private const knThirdPartySessionExpiresMinutes:Number = 7; // Log out guests who return after 30 minutes of inactivity
		private const knStateUpdateFreqMinutes:Number = Math.min(knGuestSessionExpiresMinutes, knThirdPartySessionExpiresMinutes) * .7; // Update fast enough that we don't loose anything
		private const knLastActiveUpdateFreqMinutes:Number = 10; // Update the last active date in the db every X minutes
		private const knServiceCookiesExpiresMinutes:Number = 5; // Service cookies expire after this many minutes of inactivity.
		private const knServiceCookiesUpdateFreqMinutes:Number = knServiceCookiesExpiresMinutes / 3; // Update fast enough that we don't loose anything
		private static const knSessionStateExpiresDays:Number = 2; // We keep your app state around this long before deleting it.

		/********* Session Memebers and Accessors *********/
		
		// Private members
		private var _strUserId:String = null;
		
		private var _fAppStateDirty:Boolean = false;
		private var _obPrevAppState:Object = null;

		private var _dateLastSessionUpdate:Date = null;
		private var _dateLastActiveUpdate:Date = null;
		private var _dateLastServiceCookieUpdate:Date = null;
		private var _obSessionState:Object = {};

		private var _strToken:String = null;
		
		private var _fCurrent:Boolean = false;
		private var _strId:String = null;
		private var _obSOCookies:Object = null;
		private var _fReconnect:Boolean = false; // remove after abtest
		private var _fSOCookieFlushPending:Boolean = false;
		
		// priate static members
		private static var	_strSORoot:String = "/";
		private static var _fnDone:Function = null;
		private static var _objSO:Object = null;
		private static var _loader:SWFLoader;
		private static var _sesCurrent:Session = null;
		private static var _cSOGetErrors:Number = 0;		// Number of SO get errors encountered
		private static var _cSOFlushErrors:Number = 0;		// Number of SO flush errors encountered
		private static const knErrorThreshold:Number = 4;   // Log SO get or flush errors after we encounter this many errors.
		
		private static var _soClientState:SharedObject = null;

		private static const kstrActiveABTestsKey:String = "ActiveABTests";	

		// Speed up persistent state reads using a cache. Writes are slow and update both the cache and the shared object.
		private static var _obPersistentStateCache:Object = new Object();
		
		// Accessors
		
		[Bindable]
		public function set token(strToken:String): void {
			_strToken = strToken;
		}
		public function get token(): String{
			return _strToken;
		}
		
		public function get userId(): String {
			return _strUserId;
		}
		
		protected function saveSessionState(strUserId:String): void {
			var obSessions:Object = GetPersistentClientState("sessionstate", {});
			obSessions[strUserId] = _obSessionState;
			SetPersistentClientState("sessionstate", obSessions, true); // Flush
		}
		
		protected function clearSessionState(strUserId:String): void {
			_obSessionState = {};
			saveSessionState(strUserId);
		}

		protected function loadSessionState(strUserId:String): void {
			var obSessions:Object = GetPersistentClientState("sessionstate", {});
			if (strUserId in obSessions)
				_obSessionState = obSessions[strUserId];
			else
				_obSessionState = {};
		}

		public function set thirdPartyLogin(f:Boolean): void {
			// Save whenever we change it. This is seldom changed, so this is fine.
			_obSessionState.thirdPartyLogin = f;
			saveSessionState(userId);
		}

		// Returns true if this user session was authenticated using
		// third party credentials (i.e. the user did not use a Picnik username and password to log in)
		public function get thirdPartyLogin(): Boolean {
			if (!('thirdPartyLogin' in _obSessionState))
				thirdPartyLogin = PicnikBase.app.flickrlite;
			if (!_obSessionState.thirdPartyLogin && PicnikBase.app.flickrlite)
				thirdPartyLogin = true;
				
			return _obSessionState.thirdPartyLogin;
		}

		/********* Static Helper Functions *********/
		
		private static function SessionIsStale(strUserId:String, obSessions:Object): Boolean {
			if (!(strUserId in obSessions)) return true;
			var dtLastActive:Date = obSessions[strUserId] as Date;
			if (dtLastActive == null) return true;
			var nDaysOld:Number = ((new Date()).time - dtLastActive.time) / (1000 * 60 * 60 * 24);
			return (nDaysOld > knSessionStateExpiresDays);
		}
		
		public static function DeleteOldSessions(): void {
			// Remove expired guest sessions, old user sessions
			// Walk through app states
			// For each userID:
			//    If the user ID is not in session, delete (very old)
			//    If the user ID is in session, delete if it is older than knSessionStateExpiresDays days old
			var obApp:Object = GetPersistentClientState("app", {});
			var obSessions:Object = GetPersistentClientState("session", {});
			var obSessionStates:Object = GetPersistentClientState("sessionstate", {});
			var fChange:Boolean = false;
			for (var strUserId:String in obApp) {
				if (SessionIsStale(strUserId, obSessions)) {
					delete obApp[strUserId];
					delete obSessions[strUserId];
					delete obSessions['garbage'];
					delete obSessionStates[strUserId];
					fChange = true;
				}
			}
			
			if (fChange) {
				SetPersistentClientState("session", obSessions);
				SetPersistentClientState("sessionstate", obSessionStates);
				SetPersistentClientState("app", obApp);
			}
		}
		
		public static function GetCurrent(): Session {
			if (_sesCurrent == null) {
				_sesCurrent = new Session(true);
				DeleteOldSessions();
			}
			return _sesCurrent;
		}

		// Looks for a good session to reconnect to.
		// Returns null if none found
		// Otherwise, resturns a session with a token
		public static function FindTokenToReconnectTo(): String {
			// UNDONE: Eventually, we want to support multiple simultaneous sessions.
			// For now, we store a single "last activated" token
			var strToken:String = null;
			strToken = GetPersistentClientState("lastActivatedToken", null);
			if (strToken == null) {
				try {
					strToken = CookieJar.readCookie("token");
					if (strToken && strToken.length == 0) {
						strToken = null;
					} else {
						SetPersistentClientState("lastActivatedToken", strToken);
						CookieJar.removeCookie("token");
					}
				} catch (e:Error) {
					// Gracefully ignore errors reading and writing cookies (could be a security error)
					PicnikService.Log("Ignored Client Exception: in Session.FindTokenToReconnectTo (reading/writing cookies?): " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityInfo);
				}
			} else if (strToken.length == 0) {
				strToken = null;
			}
			
			GetCurrent()._fReconnect = (strToken != null); //remove after ab test
			return strToken;
		}
		
		/********* Constructor *********/
		
		public function Session(fCurrent:Boolean=false) {
			_fCurrent = fCurrent;
			var dtNow:Date = new Date();
			var nRandom:Number = Math.random();
			_strId = dtNow.toString() + "." + nRandom;
			RemoveStaleCookies();
			_obSOCookies = GetSoCookieState( new Object() );
			SetSoCookieState(null);
		}
		
		/********* Public Functions *********/
		
		public function get isLoggedIn(): Boolean {
			return userId != null;
		}

		public function LogIn(oUser:Object, strToken:String, strTokenCookie:String): void {
			var strUserId:String = oUser.userid;
			var strUserCookie:String = oUser.name + ":";
			var am:AccountMgr = AccountMgr.GetInstance();
			strUserCookie += (am.isGuest) ? 'G' : (am.isPaid) ? 'P' : 'R';
			_strUserId = strUserId;
			loadSessionState(_strUserId);
			token = strToken;
			if (!thirdPartyLogin && PicnikBase.app.flickrlite) {
				thirdPartyLogin = true;
			}
			
			try {
				CookieJar.setCookie("lastuser", strUserCookie, "31");
			} catch (e:Error) {
				PicnikService.Log("Ignored Client Exception: in Session.LogIn (writing lastuser cookie): " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityInfo);
			}
			
			SetPersistentClientState('lastuser', strUserCookie);
			SaveSession();
			if (strTokenCookie != null) {
				try {
					CookieJar.setCookie("token", strTokenCookie);
				} catch (e:Error) {
					PicnikService.Log("Ignored Client Exception: in Session.LogIn (writing cookie): " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityInfo);
				}
			}
			// Attach any SWF cookies to this session
			// UNDONE: Some of these need to move to relogin sessions - we could set them on call-outs
			
			//read in CDN Cookie. log warning for debug if we don't see the cookie.
			//the cookie isn't used by the client, but it should have been set by the server
			//when the app page was generated. We're checking it here to see if there was a
			//problem with returned server cookie.
			var strCDNCookie:String = null;
			try {
				strCDNCookie = CookieJar.readCookie('CDNKey');
			} catch (e:Error) {
				strCDNCookie = null;
			}
			if (!strCDNCookie) {
				PicnikService.Log("CDN: Missing Client Cookie", PicnikService.knLogSeverityMonitor);
			}
		}
		
		private function ClearAppState(): void {
			var obApp:Object = GetPersistentClientState("app", {});
			delete obApp[_strUserId];
			SetPersistentClientState("app", obApp);
			TipManager.GetInstance().ResetTips();
		}
		
		// Exit the SWF
		// Set fClearSOCookie to false when we are loading the SWF and have connected our SOCookie
		// to the expired session - we need to carry it over to the new session, so we don't
		// want to clear it.
		public function LogOut( strExitUrl:String = "/", fClearSOCookie:Boolean=true, fDeleteAppState:Boolean = false): void {
			if (fDeleteAppState) {
				ClearAppState();
			}
			clearSessionState(_strUserId); // Do this before clearing user id so we clear the session state for the logging out user
			_strUserId = null;
			token = null;
			if (fClearSOCookie) _obSOCookies = new Object(); // Remove all session SO cookies
			SaveSession(fClearSOCookie);
			CookieJar.removeCookie("token");
			CookieJar.removeCookie("lastuser");
			if (strExitUrl != null)
				PicnikBase.app.NavigateToURL(new URLRequest(strExitUrl));
		}
		
		public function OnCallOut(): void {
			// Store the shared object cookies so we can get them back when we return
			SaveSession();
		}

		public function OnNavAway(): void {
			// Store the shared object cookies so we can get them back when we return
			SaveSession();
		}

		// Returns the app state for this session/user
		public function GetAppState(obDefault:Object=null): Object {
			// BST:RF1: This is the old way to get the app state
			var app:Object = GetPersistentClientState("app", obDefault);
			var sto:Object = obDefault;
			if (app != null && userId in app) {
				sto = app[userId];
			}
			return sto;
		}

		// This returns a shallow copy of session objects. DO NOT MODIFY the child objects.
		public function GetSessionForTransfer(): Object {
			// first, tell PicnikBase to save our app state
			PicnikBase.app.SaveApplicationState(true);
			
			// then create copy of the session
			var obSession:Object = {};
			obSession.dtCreated = new Date();
			obSession.ClientState = {data:{app:{}}};
			obSession.ClientState.data.app[userId] = GetAppState();
			obSession.ClientState.data.session = _getLocal('ClientState').data.session;
			obSession.ClientState.data.sessionstate = {};
			obSession.ClientState.data.sessionstate[userId] = _obSessionState;
			obSession.ClientState.data.lastActivatedToken = _getLocal('ClientState').data.lastActivatedToken;
			return obSession;
		}

		public function SetAppState(obState:Object, fForce:Boolean=false): void {
			// BST:RF1: This is the old way to set app state
			var app:Object = GetPersistentClientState("app", new Object());
			app[userId] = obState;
			SetPersistentClientState("app", app, fForce);

			_fAppStateDirty = false;
		}

		public function SaveSession(fWriteSOCookie:Boolean=true): void {
			if (isLoggedIn) {
				SaveLastActivated(token);
				if (token && token.length > 0 && fWriteSOCookie) {
					SetSoCookieState(_obSOCookies);
				}
			} else {
				SaveLastActivated("");
				if (fWriteSOCookie) SetSoCookieState(null);
			}
		}

		private static function SaveLastActivated(strToken:String): void {
			if (strToken == null)
				strToken = ""; // Use empty string for "logged out" so we don't revert back to using an old cookie
			SetPersistentClientState("lastActivatedToken", strToken);
		}
		
		public function OnActivate(): void {
			SaveSession();
		}
		
		// Call this often enough to update our "last active" state
		public function UpdateAppState(obState:Object, fForce:Boolean=false): void {
			// Saving the state takes long enough to glitch interactive operations
			// so we are careful to only save the state when it has actually changed
			// and has stopped changing for 2 seconds. This avoids hitching during
			// zoom, drag, etc.
			
			// Check to see if the app state has changed since last time we were in here.
			var fSame:Boolean = CompareStates(obState, _obPrevAppState);
			_obPrevAppState = obState;

			if (fSame) UpdateSessionLife(); // Hook into the app state events to update session staleness.
			
			// Only update when our app state hasn't changed or we are forced to
			// Otherwise, we update whenever the users is in the middle of doing something.
			if ((fSame && _fAppStateDirty) || fForce) {
				SetAppState(obState, fForce);
			} else {
				_fAppStateDirty = !fSame;
			}
			
			if (fSame && _fSOCookieFlushPending) {
				SetSoCookieState(_obSOCookies);
				_fSOCookieFlushPending = false;
			}			
		}
		
		private function SetLastActive(dt:Date): void {
			// UNDONE: This is using Get/SetPersistentState which may be slow. Should we access SharedObject directly?
			var obSessions:Object = GetPersistentClientState("session", new Object());
			obSessions[userId] = dt;
			SetPersistentClientState("session", obSessions, true);
		}

		private function SetServiceCookieActive(dt:Date): void {
			if (_obSOCookies) {
				SetSOCookie("_svc_last_active", dt, true);
			}
		}

		// Call this every so often to keep the session alive
		public function UpdateSessionLife(): void {
			try {
				if (DateToMinuteAge(_dateLastActiveUpdate) > knLastActiveUpdateFreqMinutes) {
					_dateLastActiveUpdate = new Date();
					PicnikService.callMethod("user.touch", null, null, true, null, OnUserTouch); // Log errors
				}
			} catch (e:Error) {
				// Ignore exceptions
				PicnikService.Log("Ignored Client Exception: in PicnikBase.UpdateSessionLife(): " + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityInfo);
			}
			if (DateToMinuteAge(_dateLastSessionUpdate) > knStateUpdateFreqMinutes) {
				_dateLastSessionUpdate = new Date();
				SetLastActive(_dateLastSessionUpdate);
			}
			if (DateToMinuteAge(_dateLastServiceCookieUpdate) > knServiceCookiesUpdateFreqMinutes) {
				_dateLastServiceCookieUpdate = new Date();
				SetServiceCookieActive(_dateLastServiceCookieUpdate);
			}
		}
		
		// Returns null if none found (e.g. there is one, but it has expired)
		public function GetDeepLink(): String {
			var strDeepLink:String = null;
			var sto:Object = GetAppState();
			if (sto != null && sto.strDeepLink && MinuteAge(sto) < knDeepLinkExpiresMinutes) {
				strDeepLink = sto.strDeepLink;
			}
			return strDeepLink;
		}

		// Get the 'staleness' of a session in minutes.
		// This is the time since it was last updated.
		// "live" sessions should be updated frequently (age should be not much more than knStateUpdateFreqMinutes +10%)
		private function get staleness(): Number {
			// BST:RF1: Use the new session stuff to read this. Fall back to this method when the other is not available.
			var obSessions:Object = GetPersistentClientState("session", null);
			var nAge:Number = 0;
			if (obSessions != null) {
				var date:Date = obSessions[userId] as Date;
				if (date) nAge = DateToMinuteAge(date);
			}
			return nAge;
		}
		
		private function get serviceCookiesStale(): Boolean {
			return serviceCookieStalenessMins > knServiceCookiesExpiresMinutes;
		}
		
		private function get serviceCookieStalenessMins(): Number {
			var nAge:Number = 0;
			var dtLastActive:Date = null;
			var obSOCookies:Object = GetSoCookieState({});
			if (obSOCookies && '_svc_last_active' in obSOCookies) dtLastActive = obSOCookies['_svc_last_active'] as Date;
			if (dtLastActive) {
				nAge = DateToMinuteAge(dtLastActive);
			}
			return nAge;
		}
		
		// Stale means this session hasn't been used in a while (30 minutes?)
		// Guest session expire when they become stale.
		public function get isStale(): Boolean {
			if (thirdPartyLogin)
				return staleness > knThirdPartySessionExpiresMinutes;
			else
				return staleness > knGuestSessionExpiresMinutes;
		}

		public static function SetSORoot(str:String):void {
			_strSORoot = str;
		}

		/********* Helper Functions *********/
		
		private function RemoveStaleCookies(): void {
			if (serviceCookiesStale) {
				var fChanged:Boolean = false;
				var obSOCookies:Object = GetSoCookieState(new Object());
				for (var strName:String in obSOCookies) {
					if (StringUtil.beginsWith(strName, "svc_")) {
						delete obSOCookies[strName];
						fChanged = true;
					}
				}
				if (fChanged) {
					SetSoCookieState(obSOCookies);
				}
			}
			
			// remove stale cookies that might belong to other instances
			var obAllSoCookies:Object = _getSOVars( /socookie..*/ );
			if (obAllSoCookies != null) {
				var fChanged2:Boolean = false;
				for (var k:String in obAllSoCookies) {
					var obCookie:Object = obAllSoCookies[k];
					if (obCookie && '_svc_last_active' in obCookie) {
						var dtLastActive:Date = obCookie['_svc_last_active'] as Date;
						if (dtLastActive) {
							var nAge:Number = DateToMinuteAge(dtLastActive)
							if ( nAge > knServiceCookiesExpiresMinutes ) {
								_clearSOVar( k );
								fChanged2 = true;
							}
						}
					}					
				}
				if (fChanged2) {
					_flushSO();
				}
			}
		}

		private function OnUserTouch(err:Number, strError:String): void {
			if (err == PicnikService.errAuthFailed) {
				AccountMgr.GetInstance().LogOut();
				PicnikService.Log("user.touch auth err: " + err + ", strError: " + strError, PicnikService.knLogSeverityInfo);
				
			}
			else if (err != PicnikService.errNone) {
				PicnikService.Log("user.touch failed err: " + err + ", strError: " + strError, PicnikService.knLogSeverityInfo);
			}
		}
		
		// Compare states. Ignore the timestamp (if present)		
		private function CompareStates(obState1:Object, obState2:Object, fIgnoreTimestamp:Boolean = true): Boolean {
			var fEqual:Boolean = false;
			if (obState1 == null && obState2 == null) return true;
			if (obState1 == null || obState2 == null) return false;
			
			if ("timestamp" in obState1 == "timestamp" in obState2) {
				if ("timestamp" in obState1 && "timestamp" in obState2) {
					var timestamp:Date = obState1.timestamp;
					if (fIgnoreTimestamp) obState1.timestamp = obState2.timestamp;
					fEqual = Util.CompareObjects(obState1, obState2);
					if (fIgnoreTimestamp) obState1.timestamp = timestamp;
				} else {
					// Neither has a timestamp. Do a normal compare
					fEqual = Util.CompareObjects(obState1, obState2);
				}
			}
			return fEqual;
		}
		

		// Returns the age, in minutes, of a date.
		// If date == null, returns about 1 year.
		private function DateToMinuteAge(date:Date): Number {
			if (date == null) {
				date = new Date();
				date.setTime(date.getTime() - (1000 * 60 * 60 * 24 * 365)); // Default age is very large, about 1 year
			}
			var dateNow:Date = new Date();
			return Math.abs(date.getTime() - dateNow.getTime()) / 60000;
		}
		
		private function MinuteAge(obState:Object): Number {
			var date:Date = null;
			if (obState && "timestamp" in obState && obState.timestamp) date = obState.timestamp;
			return DateToMinuteAge(date);
		}

		// Compare states. Ignore the timestamp (if present)		
		private function CompareAppStates(obState1:Object, obState2:Object, fIgnoreTimestamp:Boolean = true): Boolean {
			var fEqual:Boolean = false;
			if (obState1 == null && obState2 == null) return true;
			if (obState1 == null || obState2 == null) return false;
			
			if ("timestamp" in obState1 == "timestamp" in obState2) {
				if ("timestamp" in obState1 && "timestamp" in obState2) {
					var timestamp:Date = obState1.timestamp;
					if (fIgnoreTimestamp) obState1.timestamp = obState2.timestamp;
					fEqual = Util.CompareObjects(obState1, obState2);
					if (fIgnoreTimestamp) obState1.timestamp = timestamp;
				} else {
					// Neither has a timestamp. Do a normal compare
					fEqual = Util.CompareObjects(obState1, obState2);
				}
			}
			return fEqual;
		}

		public function GetSOCookie(strName:String, obDefault:*): * {
			if (strName in PicnikBase.app.parameters)
				return PicnikBase.app.parameters[strName];
			if (StringUtil.beginsWith(strName, "svc_") && serviceCookiesStale) return obDefault;
			if (_obSOCookies && strName in _obSOCookies)
				return _obSOCookies[strName];
			else
				return obDefault;
		}

		public function SetSOCookie(strName:String, obValue:*, fFlush:Boolean=false): void {
			if (_obSOCookies)
				_obSOCookies[strName] = obValue;
			if (fFlush) {
				_fSOCookieFlushPending = !SetSoCookieState(_obSOCookies);
			} else {
				_fSOCookieFlushPending = true;
			}
		}
		
		public static function GetMachineId(): String {
			var strId:String = null;
			try {
				strId = GetPersistentClientState("MachineID", null);
				if (strId == null) {
					strId = String(Math.random());
					SetPersistentClientState("MachineID", strId, true);
				}
			} catch (e:Error) {
				// Ignore errors
				trace("ignoring error: " + e);
			}
			if (strId == null) strId = String(Math.random());
			
			return strId;
		}	

		public static function LoadABTests(): String {
			var strTests:String = null;
			try {
				strTests = GetPersistentClientState(kstrActiveABTestsKey, null);
			} catch (e:Error) {
				// Ignore errors
				trace("ignoring error: " + e);
			}
			return strTests;
		}

		public static function SaveABTests(strTests:String): void {
			try {
				SetPersistentClientState(kstrActiveABTestsKey, strTests, true);
			} catch (e:Error) {
				// Ignore errors
				trace("ignoring error: " + e);
			}
		}	
		
		private static function SetSoCookieState( obState:*, fFlush:Boolean=true ): Boolean {
			return SetPersistentClientState( "socookie" + PicnikBase.app.instanceId, obState, fFlush );
		}
		
		private static function GetSoCookieState( obDefault:* ): * {
			return GetPersistentClientState( "socookie" + PicnikBase.app.instanceId, obDefault );
		}

		// Writes are always slow and update both the persistent state and the cache.
		// Returns a Boolean indicating success (true) or failure (false)
		public static function SetPersistentClientState(strName:String, obState:*, fFlush:Boolean=true): Boolean {
			try {
				if (_soClientState == null) {
					_getLocal("ClientState");
				}
			} catch (err:Error) {
				_cSOGetErrors++;
				if(_cSOGetErrors == knErrorThreshold)
					PicnikService.Log("Ignored Client Exception: in Session.SetPersistentClientState (getting SharedObject): " + strName + ", " +
							err + ", "  + err.getStackTrace(), PicnikService.knLogSeverityWarning);
				return false;
			}
			
			
			_setSOVar(strName, obState); //_soClientState.data[strName] = obState;
			_obPersistentStateCache[strName] = obState;
			if (fFlush) {
				try {
					_flushSO(); //_soClientState.flush();
				} catch (err:Error) {
					// We see this error (2130) occasionally but don't have a consistent repro case.
					// We'll log it so we can keep an eye on it but otherwise ignore it.
					//
					// We can get this if the user has set their sharedobject permissions to "none".
					// In this case, we might want to popup the settings dialog and ask them to adjust.
					_cSOFlushErrors++;
					if( _cSOFlushErrors == knErrorThreshold )
						PicnikService.Log("Ignored Client Exception: in Session.SetPersistentClientState (flushing SharedObject): " + strName + ", " +
								err + ", "  + err.getStackTrace(), PicnikService.knLogSeverityWarning);
					return false;
				}
			}
			return true;
		}


		// Reads are fast when the state is in the cache (and possibly inaccurate when some other process is modifying the state)	
		public static function GetPersistentClientState(strName:String, obDefault:*): * {
			if (strName in _obPersistentStateCache && _obPersistentStateCache[strName]) return _obPersistentStateCache[strName];

			try {
				if (_soClientState == null) {
					_getLocal("ClientState");
				}
			} catch (err:Error) {
				_cSOGetErrors++;
				if(_cSOGetErrors == knErrorThreshold)
					PicnikService.Log("Ignored Client Exception: in Session.GetPersistentClientState (getting SharedObject): " + strName + ", " + 
							err + ", "  + err.getStackTrace(), PicnikService.knLogSeverityWarning);
				return obDefault;
			}
			
			var obRet:Object = _getSOVar(strName);
			if (obRet == null) {
				return obDefault;
			}
			return obRet;
		}

		public static function _getLocal(strName:String):SharedObject {
			if (_objSO) {
				_soClientState = _objSO.initSO(strName, _strSORoot);
				// CONSIDER: NetStatusEvent.FAILED is fired on Vista if UAC is on. Maybe we want to do something about this?
				if (_soClientState != null)
					_soClientState.addEventListener(NetStatusEvent.NET_STATUS, function (evt:NetStatusEvent): void { });
			} else {
				_soClientState = SharedObject.getLocal(strName, _strSORoot);
			}
			return _soClientState;
		}
	
		private static function _flushSO():String
		{
			if (_objSO)
				return _objSO.flush();
			if (_soClientState)
				return _soClientState.flush();
			return "ERROR - No Shared Object";
		}
		
		private static function _getSOVar(strName:String):Object
		{
			if (_objSO)
				return _objSO.getValue(strName);
			if (_soClientState)
				return _soClientState.data[strName];
			return null;
		}
		
			
		private static function _getSOVars(regex:RegExp):Object
		{
			if (_objSO) {
				if ('getValues' in _objSO)
					return _objSO.getValues(regex);
				return null;
			}
			if (_soClientState) {
				var obRet:Object = {}
				for (var k:String in _soClientState.data) {
					if (k.match(regex)) {
						obRet[k] = _soClientState.data[k];
					}
				}
				return obRet;
			}
			return null;
		}	
		
		private static function _clearSOVar(strName:String): void {
			if (_objSO) {
				if ('clearValue' in _objSO)
					_objSO.clearValue(strName);
			} else if (_soClientState) {
				delete _soClientState[strName];
			}
		}
		
		private static function _setSOVar(strName:String, objData:Object):void
		{
			if (_objSO)
				_objSO.setValue(strName, objData);
			else if (_soClientState)
				_soClientState.data[strName] = objData;
		}


		public static function LoadSWF(fnDone:Function, strServer:String): void {
	        // if we are a local test, don't use the production cookie.
	        // in the future this may also be used to load the swf, especially if we
	        // combine modsecure into somgr.
	        if (strServer == null)
	        {
	        	_objSO = null;
	        	_fnDone = null;
	        	if (fnDone != null)
	        		fnDone();
	        } else {
		        strServer = strServer;
		        _fnDone = fnDone;
				
				if ("localsession" in PicnikBase.app.parameters || GooglePlusUtil.UsingGooglePlusAPIKey(PicnikBase.app.parameters)) {
					_objSO = new LocalSession();
					if (fnDone != null)
						fnDone();
					return;
				}
	
				_loader = new SWFLoader();
		        _loader.addEventListener(flash.events.Event.COMPLETE, OnReady);
		        _loader.addEventListener(flash.events.IOErrorEvent.IO_ERROR, OnError);
		        _loader.addEventListener(flash.events.SecurityErrorEvent.SECURITY_ERROR, OnError);
	
				if (!PicnikBase.isDesktop) {
			        Security.allowDomain(strServer);
				}
				Security.loadPolicyFile(strServer + "/crossdomain.xml");
		       
		        try {
		        	_loader.load(strServer + '/somgr_f3.swf?rel=' + PicnikBase.getVersionStamp());
		    	} catch(e:SecurityError) {
		            trace(e);
		            if (_fnDone != null) _fnDone("Security error in Session.LoadSwf", e);
		        }
			}
	    }

	    private static function OnReady(evt:Event): void {
	    	// swf loader loaded, get hook.
	    	try {
	        	_objSO = _loader.content;
	   		} catch (e:Error) {
	   			_objSO = null;
	   		}
	        if (_fnDone != null) _fnDone();
	    }
	
	    private static function OnError(evt:Event): void {
	    	trace("Failed to Load SharedObject SWF.");
	    	_objSO = null;
			PicnikService.Log("Failed to load SharedObject SWF: " + evt.toString(), PicnikService.knLogSeverityError);
	        if (_fnDone != null) _fnDone("Failed to load SharedObject SWF: " + evt.toString());
	    }	
	}
}
