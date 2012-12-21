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
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	import picnik.util.LocaleInfo;
	
	public class UserBucketManager
	{
		private static var _ubm:UserBucketManager = new UserBucketManager();
		private static const knSessionExpiresMinutes:Number = 10;
		private static const knHistoryDays:Number = 31; // Keep visits for this many days
		private static const knMaxNavLength:Number = 20;
		
		private static const UPGRADE_NAV:String = "upgd_nav";
		private static const FIRST_VISIT_NAV:String = "vst1_nav";
		private static const TENTH_VISIT_NAV:String = "vs10_nav";
		
		private var _aobNavLog:Array = [];
		
		private static const knSigFigs:Number = 6;
		
		private var _obSegmentState:Object = null;
		
		private var _tmrNavLog:Timer = null;
		
		private var _fKeyUser:Boolean = false;
		private var _strNavLogType:String = null;
		private var _nTotalUserMinutesAtNavStart:Number = 0;
		
		public static function GetUserBucket(): String {
			try {
				return _ubm._GetUserBucket();
			} catch (e:Error) {
				trace("Ignore error in UBM.GetUserBucket: " + e);
			}
			return "Unknown";
		}
		
		public static function GetInst(): UserBucketManager {
			return _ubm;
		}
		
		public static function GetCount(strCounter:String): int {
			var ubm:UserBucketManager = GetInst();
			if (!ubm.ValidateSharedObject())
				return 0;
			var obCounts:Object = ubm._obSegmentState.obCounts;
			return obCounts[strCounter];
		}

		private function InitObjectState(): void {
			// Should only be called once per machine (or SO clear)
			_obSegmentState['guid'] = CreateGuid();
			_obSegmentState['obCounts'] = {};
			_obSegmentState['aobVisitHistory'] = [];
			_obSegmentState['obActiveVisit'] = null;
			_obSegmentState['dtFirstVisit'] = new Date();
		}
		
		// REturns type time:
		// weekend - Sat/Sun/Fri Eve
		// businessHours M-F, 9-5
		// beforeAfterWork, Anything else
		private function GetTimeType(dtTime:Date): String {
			var nHourTime:Number = dtTime.getHours();
			var fWorkHours:Boolean = nHourTime > 9 && nHourTime < (5 + 12);
			var nWeekDay:Number = dtTime.day; // 0 == Sunday. 6 == sat, 5 == fri
			if (nWeekDay == 5 && nHourTime > (5+12)) return "weekend";
			if (nWeekDay == 0 || nWeekDay == 6) return "weekend";
			if (nWeekDay > 1 && nWeekDay < 6 && fWorkHours) return "businessHours";
			return "beforeAfterWork";
		}
		
		////////// BEGIN: Navigation logging ////////// 
		
		private function get autoWriteNavLog(): Boolean {
			return _tmrNavLog != null;
		}
		
		private function FlushNav(): void {
			if (!_tmrNavLog) return;
			WriteNavLog();
		}

		private function get recordNav(): Boolean {
			return _strNavLogType != null;
		}
		
		private function LogNav(str:String, fFlush:Boolean=false): void {
			if (recordNav && str != null && str.length > 0)
				_aobNavLog.push({dt:new Date(), strLoc:str});
			if (fFlush || _aobNavLog.length > knMaxNavLength) FlushNav();
		}
		
		private function NavLogToData(nMaxLen:Number): Array {
			var astrData:Array = [];
			if (_aobNavLog.length == 0) return astrData;
			var i:Number = 0;
			var strData:String = "";
			var dtStart:Date = _aobNavLog[0].dt;
			for each (var obNav:Object in _aobNavLog) {
				var nTenthOfSecs:int = int(Math.round((obNav.dt.time - dtStart.time) / 100));
				var strLog:String = nTenthOfSecs.toString() + "|" + obNav.strLoc;
				if (strData.length > 0 && (strData.length + strLog.length + 1) > nMaxLen) {
					astrData.push(strData);
					strData = "";
				}
				if (strData.length > 0) strData += "|";
				strData += strLog;
			}
			if (strData.length > 0) astrData.push(strData);
			return astrData;
		}
		
		private function GetNavLogTimerDelays(): Array {
			var anTimerDelaySecs:Array = [];
			var i:Number;
			for (i = 0; i < 10; i++) anTimerDelaySecs.push(30); // Every 30 seconds for first 5 minutes
			for (i = 0; i < 10; i++) anTimerDelaySecs.push(60); // Every minute for next 10 minutes
			for (i = 0; i < 10; i++) anTimerDelaySecs.push(120); // Every two minutes for next 20 minutes
			anTimerDelaySecs.push(4 * 60); // Every four minutes thereafter
			return anTimerDelaySecs;
		}
		
		public function GetVisitNumber(): Number {
			var nHistoryLength:Number = 0;
			try {
				if (_obSegmentState && _obSegmentState.aobVisitHistory as Array)
					nHistoryLength = (_obSegmentState.aobVisitHistory as Array).length;
			} catch (e:Error) {
				// Ignore errors
			}
			
			return nHistoryLength + 1;
		}
		
		public function GetVisitKey(): String {
			var nVisitNumber:Number = GetVisitNumber();

			if (nVisitNumber <= 1)
				return "first";
			else if (nVisitNumber > 1 && nVisitNumber <= 2)
				return "second";
			else if (nVisitNumber > 2 && nVisitNumber <= 3)
				return "third";
			else if (nVisitNumber > 3 && nVisitNumber <= 4)
				return "fourth";
			else if (nVisitNumber > 4 && nVisitNumber <= 5)
				return "fifth";
			else if (nVisitNumber > 5 && nVisitNumber <= 10)
				return "sixth_to_tenth";
			else if (nVisitNumber > 10 && nVisitNumber <= 20)
				return "eleventh_to_twentieth";
			else  if (nVisitNumber > 20)
				return "twentyfirst_or_later";
			
			return "unknown";
		}
		
		private function SetUpNavLogging(): void {
			if (!_obSegmentState) return;

			if (_fKeyUser && (_obSegmentState.aobVisitHistory as Array).length == 0) {
				StartRecordingNav(FIRST_VISIT_NAV, true); // Start recording and logging
			} else if (!AccountMgr.GetInstance().isPremium) {
				StartRecordingNav(UPGRADE_NAV, false); // Start recording but not logging
			}
		}
		
		private function StartRecordingNav(strType:String, fStartWriting:Boolean): void {
			if (!_obSegmentState) return;
			_strNavLogType = strType;
			if (_obSegmentState.obActiveVisit == null)
				CreateNewActiveVisit();
			var obVisit:Object = _obSegmentState.obActiveVisit;
			_nTotalUserMinutesAtNavStart = TimeDiffToMinutes(obVisit.dtStart, new Date()) + Number(GetUberValue('minutes', 0));
			if (fStartWriting)
				StartWritingNavLog();
		}
		
		private function StartWritingNavLog(): void {
			WriteNavLog(); // Write out what we have so far
			if (_tmrNavLog == null) {
				_tmrNavLog = new VariableTimer(GetNavLogTimerDelays());
				_tmrNavLog.addEventListener(TimerEvent.TIMER, OnNavLogTimer);
				_tmrNavLog.start();			
			}
		}
		
		private function OnNavLogTimer(evt:Event): void {
			WriteNavLog();
		}
		
		// Send it to the server
		private function WriteNavLog(): void {
			if (!_obSegmentState) return;
			if (_aobNavLog.length == 0) return;
			
			var astrData:Array = NavLogToData(1024);

			var strGuid:String = _obSegmentState['guid'];
			for each (var strData:String in astrData) {
				PicnikService.Log("USL:" + strGuid + ':' + _strNavLogType + "|" + FormatVal(_nTotalUserMinutesAtNavStart, 4) + ':' + strData, PicnikService.knLogSeverityUserSegment);
			}
			
			_aobNavLog.length = 0;
		}
		
		////////// END: Navigation logging //////////
		 
		private function CreateNewActiveVisit(): Object {
			var dtStart:Date = new Date()
			var obVisit:Object = {dtStart:dtStart, obCounts:{}, dtLastActive:new Date()};
			_obSegmentState.obActiveVisit = obVisit;
			AddUberValue('visit', 1);
			
			AddVisitCount(1, GetTimeType(dtStart), null);
			
			LogAction("visit", GetSegmentData());
			LogNav("_Visit");
			return obVisit;
		}
		
		private function PingVisit(): void {
			var obVisit:Object = GetVisitObject();
			if (obVisit != null) obVisit.dtLastActive = new Date();
		}
		
		private function TrimVisits(): void {
			if (!ValidateSharedObject()) return;
			
			var iKeepPos:Number = 0;
			var aobVisitHistory:Array = _obSegmentState.aobVisitHistory;
			var dtNow:Date = new Date();
			while (iKeepPos < aobVisitHistory.length && AgeInDays(aobVisitHistory[iKeepPos].dtLastActive) > knHistoryDays) {
				iKeepPos++;
			}
			// If iKeepPos == 0, keep all elements
			// if iKeepPos == aobVisitHistory.length, remove all elements
			if (iKeepPos > 0) {
				(_obSegmentState.aobVisitHistory as Array).splice(0, iKeepPos);
			}
		}

		private function AgeInDays(dt:Date): Number {
			return AgeInMinutes(dt) / (60 * 24);
		}
		
		private function AgeInMinutes(dt:Date): Number {
			return TimeDiffToMinutes(dt, new Date());
		}

		private function TimeDiffToMinutes(dtStart:Date, dtEnd:Date): Number {
			return (dtEnd.time - dtStart.time) / 60000;
		}
		
		// Our active visit has expired.
		// Set minutes and roll it into our total
		private function RotateVisit(): void {
			// Set visit minutes
			// Add minutes to our total minutes count
			// Note that this means that minutes need special care when reporting
			//  - We need to calculate and consider minutes from our active visit
			if (!ValidateSharedObject()) return;
			
			var obVisit:Object = _obSegmentState.obActiveVisit;
			var nMinutes:Number = TimeDiffToMinutes(obVisit.dtStart, obVisit.dtLastActive);

			AddVisitCount(nMinutes, "minutes", null, false, obVisit);
			
			_obSegmentState.aobVisitHistory.push(obVisit);
			_obSegmentState.obActiveVisit = null;
		}
		
		private function GetVisitObject(): Object {
			if (!ValidateSharedObject()) return null;
			
			var obVisit:Object;
			if (_obSegmentState.obActiveVisit == null) {
				obVisit = CreateNewActiveVisit();
				TrimVisits();
			} else {
				if (AgeInMinutes(_obSegmentState.obActiveVisit.dtLastActive) > knSessionExpiresMinutes) {
					RotateVisit();
					TrimVisits();
					obVisit = CreateNewActiveVisit();
				} else {
					obVisit = _obSegmentState.obActiveVisit;
				}
			}

			return obVisit;
		}
		
		private function GetUberValue(strKey:String, obDefault:Object): Object {
			if (!ValidateSharedObject()) return obDefault;
			if (strKey in _obSegmentState.obCounts) return _obSegmentState.obCounts[strKey];
			return obDefault;
		}
		
		private function AddUberValue(strKey:String, nNum:Number): void {
			if (!ValidateSharedObject()) return;
			if (!(strKey in _obSegmentState.obCounts)) _obSegmentState.obCounts[strKey] = 0;
			_obSegmentState.obCounts[strKey] += nNum;
		}
		
		private function AddVisitCount(nAdd:Number, strAction:String, strExtra:String, fPing:Boolean=true, obVisit:Object=null): void {
			if (fPing) PingVisit();
			if (obVisit == null) obVisit = GetVisitObject();
			if (!obVisit) return;
			
			AddUberValue(strAction, nAdd);
			if (!(strAction in obVisit.obCounts)) obVisit.obCounts[strAction] = 0;
			obVisit.obCounts[strAction] += nAdd;

			if (strExtra != null) AddVisitCount(nAdd, strAction + "/" + strExtra, null);
		}
		
		private function GetAverageVisitVal(strKey:String): String {
			if (!ValidateSharedObject()) return "0";
			
			var obVisit:Object;
			var nTotal:Number = 0;
			var nCount:Number = 0;
			for each (obVisit in _obSegmentState.aobVisitHistory) {
				if (strKey in obVisit.obCounts) nTotal += obVisit.obCounts[strKey];
				nCount += 1;
			}
			
			obVisit = GetVisitObject();
			if (obVisit) {
				if (strKey in obVisit.obCounts) {
					nTotal += obVisit.obCounts[strKey];
				}
				else if (strKey == "minutes") {
					nTotal += TimeDiffToMinutes(obVisit.dtStart, new Date());
				}
				nCount += 1;
			}
			
			if (nCount == 0) return "0";
			
			// Now format our result.
			
			var nVal:Number = nTotal / nCount;
			
			return FormatVal(nVal); // Sig figs
		}
		
		private function FormatVal(nVal:Number, nSigFigs:Number=knSigFigs): String {
			var strSign:String = (nVal < 0) ? '-' : '';
			nVal = Math.abs(nVal);
			
			var nMult:Number = 1;
			var i:Number;
			for (i = 0; i < nSigFigs; i++) {
				nMult *= 10;
			}
			// Three sig figs gives us 1000
			if (nVal == Math.round(nVal) && nVal < nMult * 1000) {
				return strSign + nVal.toString();
			}
			
			if (nVal >= nMult && nVal < nMult * 1000) {
				return strSign + Math.round(nVal).toString();
			}
			
			// We have handled whole numbers small enough to display
			// as well as non-whole numbers the  correct size to truncate
			
			// Now handle fractional numbers large enough they don't need scientific notation
			// That would be, any number between nVal < nMult and nVal >= 0.1)
			
			if (nVal < nMult && nVal > 0.01) {
				// Truncate to 5 chars
				return strSign + nVal.toString().substr(0, nSigFigs+3);
			}
				
			// Left are very large and very small numbers
			var nE:Number = 0;
			if (nVal > 1) {
				// Large number
				while (nVal > 10) {
					nE += 1;
					nVal /= 10;
				}
			} else {
				// Small number
				while (nVal < 1) {
					nE -= 1;
					nVal *= 10;
				}
			}
			return strSign + nVal.toString().substr(0, nSigFigs+1) + "e" + nE;
		}
		
		private function GetSegmentData(): Object {
			if (!ValidateSharedObject()) return {};
			
			var ob:Object = {};
			var str:String;
			
			// UT: User type
			str = "?";
			if (AccountMgr.GetInstance().isPremium) str = 'P';
			else if (AccountMgr.GetInstance().isGuest) str = 'G';
			else if (AccountMgr.GetInstance().hasCredentials) str = 'R';
			ob.UT = str;
			
			// Host - first four characters
			ob.Host = "Picn";
			if (PicnikBase.app.parameters["host"])
				ob.Host = String(PicnikBase.app.parameters["host"]).substr(0, 4); // First four chars
			
			var obUberVals:Object = {
				TV:'visit',
				CX:'cancel'
			};
			
			var obSharedVals:Object = {
				OP:'open',
				SV:'save',
				NV:'nav',
				UP:'upsell',
				CN:'connect',
				MN:'minutes',
				TWE:'weekend',
				TBH:'businessHours',
				TWD:'beforeAfterWork'
			}
			
			var strKey:String;

			var obVisit:Object = GetVisitObject();
			
			for (strKey in obUberVals)
				ob[strKey] = FormatVal(Number(GetUberValue(obUberVals[strKey], 0)));
			for (strKey in obSharedVals)
				ob[strKey] = FormatVal(Number(GetUberValue(obSharedVals[strKey], 0)));

			ob.MN = FormatVal(TimeDiffToMinutes(obVisit.dtStart, new Date()) + GetUberValue('minutes', 0));
			
			// More uber values:
			
			// Take averages for visits we know about (including the active visit -> calc minutes
			for (strKey in obSharedVals) {
				ob['v' + strKey] = GetAverageVisitVal(obSharedVals[strKey]);
			}
			
			var dtFirstVisit:Date = _obSegmentState['dtFirstVisit'];
			var nDaysAgo:Number = AgeInDays(dtFirstVisit);
			nDaysAgo = (Math.round(nDaysAgo * 100)) / 100;
			
			// Days ago of first visit
			ob.DFV = FormatVal(nDaysAgo);
			
			var aobVisitHistory:Array = _obSegmentState.aobVisitHistory as Array;
			if (aobVisitHistory.length > 0) {
				nDaysAgo = AgeInDays(aobVisitHistory[0].dtStart);
			}
			nDaysAgo = Math.ceil(nDaysAgo);
			if (nDaysAgo < 1) nDaysAgo = 1;
			
			var nVisits:Number = aobVisitHistory.length + 1;
			var nVisitsPerDay:Number = nVisits / nDaysAgo;
			
			ob.VPD = FormatVal(nVisitsPerDay);
			
			ob.lc = PicnikBase.Locale().substr(0,2);
			
			// Questions
			if ('questions' in _obSegmentState) {
				var obSurveys:Object = _obSegmentState['questions'];
				for (strKey in obSurveys) {
					for (var strQuestion:String in obSurveys[strKey]) {
						ob[strKey + "/" + strQuestion] = obSurveys[strKey][strQuestion];
					}
				}
			}			
			
			return ob;
		}
		
		private function GetABBuckets(): Object {
			// UNDONE: Put some data together
			return {};
		}
		
		//////////// BEGIN: Events /////////////
		public function OnUserRegistered(): void {
			try {
				if (!ValidateSharedObject()) return;
				_obSegmentState['dtRegister'] = new Date();			
				LogActionNoThrottle("register", GetSegmentData(), GetABBuckets());
				// _LogABEvent("register");
				LogNav("_Registered", true);
			} catch (e:Error) {
				trace("ignoring error in OnUserRegistered: " + e + ", " + e.getStackTrace());
			}
		}
		
		public function OnQuestionsAnswered(strSurveyId:String, obAnswers:Object): void {
			try {
				if (!ValidateSharedObject()) return;
				var fHaveAnswers:Boolean = false;
				var obRealAnswers:Object = {};
				for (var strKey:String in obAnswers) {
					if (obAnswers[strKey] != '-' && obAnswers[strKey] != null && obAnswers[strKey] != '') {
						fHaveAnswers = true;
						obRealAnswers[strKey] = obAnswers[strKey];
					}
				}
				if (fHaveAnswers) {
					if (!('questions' in _obSegmentState)) _obSegmentState['questions'] = {};
					_obSegmentState['questions'][strSurveyId] = obRealAnswers;
					PingVisit()
				};
			} catch (e:Error) {
				trace("ignoring error in OnQuestionsAnswered: " + e + ", " + e.getStackTrace());
			}
		}
		
		// CreateCollage
		// ViewCollage
		// CreateFancyCollage
		// ViewFancyCollage
		// ViewEdit
		// ApplyEdit
		// ViewCreate
		// ApplyCreate
		// Connection, Bridge
		// Nav
		public function OnCountableAction(strAction:String, strExtra:String=null): void {
			try {
				AddVisitCount(1, strAction, strExtra);
			} catch (e:Error) {
				trace("ignoring error in OnCountableAction: " + e + ", " + e.getStackTrace());
			}
		}
		
		public function OnUserUpgraded(strSource:String): void {
			try {
				if (!ValidateSharedObject()) return;
				_obSegmentState['dtUpgrade'] = new Date();			
				LogActionNoThrottle("upgrade", GetSegmentData(), {src:strSource}, GetABBuckets());
				StartWritingNavLog();
			} catch (e:Error) {
				trace("ignoring error in OnUserUpgraded: " + e + ", " + e.getStackTrace());
			}
		}
		
		public function OnUserCanceled(): void {
			try {
				if (!ValidateSharedObject()) return;
				AddUberValue("cancel", 1);
				LogNav("_Canceled");
			} catch (e:Error) {
				trace("ignoring error in OnUserCanceled: " + e + ", " + e.getStackTrace());
			}
		}
		
		public function OnConnect(strBridge:String): void {
			try {
				if (!ValidateSharedObject()) return;
				AddVisitCount(1, "connect", strBridge);
				LogNav("_Connect:" + strBridge);
			} catch (e:Error) {
				trace("ignoring error in OnConnect: " + e + ", " + e.getStackTrace());
			}
		}
		
		public function OnUpsellShown(strSource:String): void {
			try {
				AddVisitCount(1, "upsell", null);
				// LogAction("upsell", {src:strSource});
				LogNav("_Upsell:" + strSource);
			} catch (e:Error) {
				trace("ignoring error in OnUpsellShown: " + e + ", " + e.getStackTrace());
			}
		}
		
		public function OnSave(strBridge:String): void {
			try {
				AddVisitCount(1, "save", strBridge);
				// LogAction("save", {bridge:strBridge});
				LogNav("_Save:" + strBridge, true);
			} catch (e:Error) {
				trace("ignoring error in OnSave: " + e + ", " + e.getStackTrace());
			}
		}
				
		public function OnShare(strBridge:String): void {
			try {
				AddVisitCount(1, "share", strBridge);
				// LogAction("share", {bridge:strBridge});
				LogNav("_Share:" + strBridge, true);
			} catch (e:Error) {
				trace("ignoring error in OnShare: " + e + ", " + e.getStackTrace());
			}
		}
		
		public function OnOpen(strBridge:String): void {
			try {
				AddVisitCount(1, "open", strBridge);
				// LogAction("open", {bridge:strBridge});
				LogNav("_Open:" + strBridge, true);
			} catch (e:Error) {
				trace("ignoring error in OnOpen: " + e + ", " + e.getStackTrace());
			}
		}
		
		public function OnNav(strLoc:String): void {
			try {
				if (strLoc != null && strLoc.length > 0) {
					AddVisitCount(1, "nav", null);
					LogNav(strLoc);
				}
			} catch (e:Error) {
				trace("ignoring error in OnNav: " + e + ", " + e.getStackTrace());
			}
		}
		//////////// END: Events /////////////
		
		public function UserBucketManager()
		{
		}
		
		private function SetUpThrottling(): void {
			var nThrottleRatio:Number = 0;
			
			try {
				nThrottleRatio = Number(KeyVault.GetInstance().userSegments.logRatio);
				if (nThrottleRatio == 0) {
					_fKeyUser = false;
				} else {
					var strGuid:String = _obSegmentState['guid'];
	
					var b64:Base64Decoder = new Base64Decoder();
					b64.decode(strGuid);
					var ba:ByteArray = b64.drain(); // 16 random bytes
					var unVal:uint = ba.readUnsignedInt();
					const unMax:uint = 4294967295;
					
					var nPercentToMax:Number = Number(unVal)/Number(unMax);
					var nRatioPercent:Number = 1.0 / nThrottleRatio;
					
					_fKeyUser = nPercentToMax <= nRatioPercent;
				}
			} catch (e:Error) {
				trace("Ignoring error in UserBucketManager.SetUpThrottling: " + e + ", " + e.getStackTrace());
				_fKeyUser = false;
			}
		}
		
		// Return true if we have a shared object
		private function ValidateSharedObject(): Boolean {
			var fInit:Boolean = false;
			if (_obSegmentState == null) {
				fInit = true;
				try {
					_obSegmentState = Session.GetPersistentClientState("UserSegmentData", null);
					if (_obSegmentState == null) {
						Session.SetPersistentClientState("UserSegmentData", {}, true);
						_obSegmentState = Session.GetPersistentClientState("UserSegmentData", null);
					}
				} catch (e:Error) {
					trace("Error getting shared object for UserBucketManager: " + e);
				}
			}
			if (_obSegmentState == null) {
				return false;
			}
			if (!("guid" in _obSegmentState)) {
				InitObjectState();
			}
			if (fInit) {
				SetUpThrottling(); // Call this before calling SetUpNavLogging. Sets _fKeyUser
				SetUpNavLogging(); // Call this after calling SetUpNavLogging. Depends on _fKeyUser
			}
			return true;
		}
		
		// Base64 encoded guid
		private function CreateGuid(): String {
			var ba:ByteArray = new ByteArray();
			for (var i:Number = 0; i < 16; i++) {
				ba.writeByte(Math.floor(Math.random() * 256)); // Random byte
			}
			var b64:Base64Encoder = new Base64Encoder();
			b64.encodeBytes(ba);
			return b64.toString();
		}
		
		private function MergeObjects(ob1:Object, ob2:Object): Object {
			if (ob1 == null) return ob2;
			if (ob2 == null) return ob1;
			for (var strKey:String in ob2) ob1[strKey] = ob2[strKey];
			return ob1;
		}
		
		public function _LogAction(strAction:String, fThrottle:Boolean, obData:Object, obData2:Object, obData3:Object): void {
			if (!ValidateSharedObject()) return;
			if (fThrottle && !_fKeyUser) {
				return;
			}
			// Merge the objects
			obData = MergeObjects(obData, obData2);
			obData = MergeObjects(obData, obData3);
			
			// UNDONE: Implement a new log method
			
			var strData:String = "";
			for (var strKey:String in obData) {
				if (strData.length > 0) strData += "&";
				strData += strKey + "=" + escape(obData[strKey]);
			}
			var strGuid:String = _obSegmentState['guid'];
			PicnikService.Log("USL:" + strGuid + ':' + strAction + ":" + strData, PicnikService.knLogSeverityUserSegment);
		}
		
		public function LogAction(strAction:String, obData:Object, obData2:Object=null, obData3:Object=null): void {
			_LogAction(strAction, true, obData, obData2, obData3);
		}
		
		public function LogActionNoThrottle(strAction:String, obData:Object, obData2:Object=null, obData3:Object=null): void {
			_LogAction(strAction, false, obData, obData2, obData3);
		}
		
		private function _GetUserBucket(): String {
			return _GetUserTypeBucket() + '/' + _GetUserLocaleBucket();
		}

		private function _GetUserTypeBucket(): String {
			// States, in order of priority:
			// JustUpgraded
			// Upgraded
			// JustRegistered
			// Registered
			// Guest
			return GetVisitKey() + "_visit";
			// return "Unknown";
		}
		
		private function _GetUserLocaleBucket(): String {
			if (LocaleInfo.IsEnglish()) return "English";
			return "NonEnglish";
		}
	}
}