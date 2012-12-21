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
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	
	import mx.core.Application;
	import mx.utils.URLUtil;
	
	public class UrchinProxy
	{
		private static var _up:UrchinProxy = null;

		private var _strCampaign:String = "Unknown";
		
		public static function recordTransaction(strOrderId:String, strAffiliation:String, strTotal:String, strTax:String, strShipping:String,
						strCity:String, strState:String, strCountry:String, strSku:String, strProductName:String, strCategory:String, strPrice:String, strQuantity:String): void {
			UrchinProxy.global.DoRecordTransaction(strOrderId, strAffiliation, strTotal, strTax, strShipping,
						strCity, strState, strCountry, strSku, strProductName, strCategory, strPrice, strQuantity);
		}
		
		public static function Log(strEvent:String, strCampaign:String): void {
			UrchinProxy.global._strCampaign = strCampaign;
			UrchinProxy.global.DoLog(strEvent);
		}
		
		public static function get global(): UrchinProxy {
			if (_up == null) {
				_up = new UrchinProxy();
			}
			return _up;
		}

		public function DoRecordTransaction(strOrderId:String, strAffiliation:String, strTotal:String, strTax:String, strShipping:String,
						strCity:String, strState:String, strCountry:String, strSku:String, strProductName:String, strCategory:String, strPrice:String, strQuantity:String): void {
			try {
				var strUrl:String = GetTransactionUrl(strOrderId, strAffiliation, strTotal, strTax, strShipping,
						strCity, strState, strCountry, strSku, strProductName, strCategory, strPrice, strQuantity);
				HitUrl(strUrl);
				strUrl = GetItemUrl(strOrderId, strAffiliation, strTotal, strTax, strShipping,
						strCity, strState, strCountry, strSku, strProductName, strCategory, strPrice, strQuantity);
				HitUrl(strUrl);
			} catch (e:Error) {
				trace(e + ", " + e.getStackTrace());
			}
		}

		public function DoLog(strEvent:String): void {
			try {
				HitUrl(GetEventUrl(strEvent));
			} catch (e:Error) {
				trace(e + ", " + e.getStackTrace());
			}
		}

		public function GetTransactionUrl(strOrderId:String, strAffiliation:String, strTotal:String, strTax:String, strShipping:String,
						strCity:String, strState:String, strCountry:String, strSku:String, strProductName:String, strCategory:String, strPrice:String, strQuantity:String): String {
			if (domain == null || domain.length == 0) return null;
			var strCacheBuster:String = cacheBuster;
			updateCookies(strCacheBuster);
			var str:String = baseUrl;
			str += "&utmt=tran";
			str += "&utmn=" + strCacheBuster;
			
			str += "&utmtid=" + strOrderId;
			str += "&utmtst=" + strAffiliation;
			str += "&utmtto=" + strTotal;
			str += "&utmttx=" + strTax;
			str += "&utmtsp=" + strShipping;
			str += "&utmtci=" + strCity;
			str += "&utmtrg=" + strState;
			str += "&utmtco=" + strCountry;

			str += "&utmac=" + urchinId;
			str += "&utmcc=" + cookies;
			return str;
		}
		
		public function GetItemUrl(strOrderId:String, strAffiliation:String, strTotal:String, strTax:String, strShipping:String,
						strCity:String, strState:String, strCountry:String, strSku:String, strProductName:String, strCategory:String, strPrice:String, strQuantity:String): String {
			if (domain == null || domain.length == 0) return null;
			var strCacheBuster:String = cacheBuster;
			updateCookies(strCacheBuster);
			var str:String = baseUrl;
			str += "&utmt=item";
			str += "&utmn=" + strCacheBuster;
			
			str += "&utmtid=" + strOrderId;
			str += "&utmipc=" + strSku;
			str += "&utmipn=" + strProductName;
			str += "&utmiva=" + strCategory;
			str += "&utmipr=" + strPrice;
			str += "&utmiqt=" + strQuantity;

			str += "&utmac=" + urchinId;
			str += "&utmcc=" + cookies;
			return str;
		}
		
		// An event request should look something like this:
		protected function GetEventUrl(strEvent:String): String {
			if (domain == null || domain.length == 0) return null;
			var strCacheBuster:String = cacheBuster;
			updateCookies(strCacheBuster);
			var str:String = baseUrl;
			str += "&utmn=" + strCacheBuster;
			str += "&utmsr=" + screenSize;
			str += "&utmul=" + locale;
			str += "&utmfl=" + flashVersion;
			str += "&utmdt=" + title;
			str += "&utmhn=" + hostName;
			str += "&utmr=" + referrer;
			var strPage:String = getPage(strEvent);
			str += "&utmp=" + strPage;
			str += "&utmac=" + urchinId;
			str += "&utmcc=" + cookies;
			return str;
		}
		
		protected function get cookies(): String {
			var str:String = "";
			str += "__utma=" + domainHash + "." + _obSession.id + '.' +  _obSession.firstVisit + '.' + _obSession.mostRecentVisit + '.' + _obSession.nextMostRecentVisit + '.' + _obSession.numVisits;
			str += ";+__utmb=" + domainHash;
			str += ";+__utmc=" + domainHash;
			str += ";+__utmz=" + domainHash + "." + _obSession.id + '.' + _obSession.numVisits + '.' + _obSession.numVisits + '.utmcsr=' + _strCampaign + '|utmccn=' + _strCampaign + '|utmcmd=integration';
			str = escape(str).replace(/\+/g, '%2B');
			return str;
		}
		
		protected const domainHash:String = "<insert your domain hash here>";
		
		// Session logic:
		// - We store four pieces of session information:
		//   1. An ID (same as the cache buster of the first request)
		//   1. The first time we saw you (when the cache buster was created)
		//   2. The start of your most recent session
		//   3. The start of your next most recent session
		//   4. Total number of visits (sessions)
		// - Your session starts when you make your first request.
		// - If you are inactive (no requests) for 30 minutes, you get a new session (and your times are updated)
		// To expire a session, we will also store a "good until" time which will be updated every few minutes
		protected var _obSession:Object = null;
		
		protected function get sessionExpiresDate(): Date {
			var dt:Date = new Date();
			dt.setTime(dt.getTime() +  30 * 60 * 1000);
			return dt;
		}
		
		protected function initSession(strID:String): void {
			_obSession = {};
			_obSession.id = strID;
			var strTime:String = getTimeStamp();
			_obSession.firstVisit = strTime;
			_obSession.mostRecentVisit = strTime;
			_obSession.nextMostRecentVisit = strTime;
			_obSession.expires = sessionExpiresDate;
			_obSession.numVisits = 1;
		}
		
		protected function getTimeStamp(): String {
			var dtNow:Date = new Date();
			
			return Math.round(dtNow.getTime() / 1000).toString();
		}

		protected function updateSession(): void {
			_obSession.nextMostRecentVisit = _obSession.mostRecentVisit;
			_obSession.mostRecentVisit = getTimeStamp();
			_obSession.numVisits++;
		}
		
		protected function loadSession(): void {
			_obSession = getSession();
		}
		
		private const _strSessionKey:String = 'session';
		public function getSession(): Object {
			try {
				var so:SharedObject = SharedObject.getLocal("UrchinSession", "/");
				if (so.data[_strSessionKey] == undefined) return null; // No object
				
				var obData:Object = so.data[_strSessionKey];
				if (!obData) return null;
				var obDataCopy:Object = new Object();
				for (var strParam:String in obData) {
					obDataCopy[strParam] = obData[strParam];
				}
				return obDataCopy;
			} catch (err:Error) {
				trace(err + ": " + err.getStackTrace());
				return null;
			}
			return null;
		}
		
		private var _dtLastSave:Date = null;
		protected function saveSession(): void {
			try {
				var so:SharedObject = SharedObject.getLocal("UrchinSession", "/");

				var obData:Object = new Object();
				for (var strParam:String in _obSession) {
					obData[strParam] = _obSession[strParam];
				}
				
				so.data[_strSessionKey] = obData;
				so.flush();
				_dtLastSave = new Date();
			} catch (err:Error) {
				trace(err + ": " + err.getStackTrace());
			}
		}
		
		private const minutesBetweenSaves:Number = 5; // Save our session "last updated" every time this many minutes pass
		
		protected function get sessionNeedsSaving(): Boolean {
			if (!_dtLastSave) return true; // hasn't been saved yet
			var nTimeSinceLastSave:Number = (new Date().getTime()) - _dtLastSave.getTime();
			return ((nTimeSinceLastSave / 60000) > minutesBetweenSaves);
		}
		
		protected function saveSessionIfNeeded(): void {
			if (sessionNeedsSaving) saveSession();
		}
		
		protected function updateCookies(strID:String): void {
			if (_obSession == null) {
				loadSession();
			}
			
			if (_obSession == null) {
				// If it is still null, this is the first time we've seen this user
				// Initialize our session state.
				initSession(strID);
				saveSession();
			} else {
				var dtNow:Date = new Date();
				var fExpired:Boolean = (dtNow > _obSession.expires);
				_obSession.expires = sessionExpiresDate;
				if (fExpired) {
					// The session expired
					updateSession();
					saveSession();
				} else {
					saveSessionIfNeeded(); // We updated the expires date, save this if needed
				}
			}
		}
		   
		protected function getPage(strEvent:String): String {
			return strEvent;
		}
		
		protected const urchinId:String = "UA-000000-0"; // Use your urchin id
		protected const hostName:String = "www.mywebsite.com";
		protected const title:String = "Picnik";

		protected function get referrer(): String {
			return '-';
		}
		
		protected function get flashVersion(): String {
			var strVersion:String = Capabilities.version;
			if (strVersion == null) return '-';
			var i:Number = strVersion.indexOf(' ');
			if (i < 0) return '-';
			return strVersion.substr(i+1).replace(/,/g,'.');
		}
		
		protected function get locale(): String {
			return CONFIG::locale.toLowerCase().replace('_','-');
		}
		
		protected function get screenSize(): String {
			return Capabilities.screenResolutionX + 'x' + Capabilities.screenResolutionY;
		}
		
		protected function get cacheBuster(): String {
			return Math.round(Math.random() * 2147483647).toString();
		}

		protected function get baseUrl(): String {
			var strBase:String;

			if (URLUtil.isHttpsURL((Application.application as Application).url))
				strBase = "https://ssl";
			else
				strBase = "http://www";
		
			strBase += ".google-analytics.com/__utm.gif?utmwv=1";
			return strBase;
		}
		
		[Bindable] public var domain:String = null;

		// Make sure we keep a pointer to an outstanding request so that it is not garbage collected		
		private var _nRequestId:Number = 0;
		private var _obRequests:Object = {};
		
		private function AddToRequestQueue(nId:Number, ldr:Object, urlr:URLRequest): void {
			_obRequests[nId] = {ldr:ldr, urlr:urlr};
		}
		
		private function RemoveFromRequestQueue(nId:Number): void {
			if (nId in _obRequests) {
				// We shouldn't need to close the request since it should be done by now.
				// _obRequests[nId].urll.close();
				_obRequests[nId] = null;
			}
		}
		
		protected function HitUrl(strUrl:String): void {
			if (strUrl == null || strUrl.length == 0) return;
			var urlr:URLRequest = new URLRequest(strUrl);
			var ldr:Loader = new Loader();
			var nId:Number = _nRequestId++;
			AddToRequestQueue(nId, ldr, urlr);
			ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, function (evt:Event): void {
				RemoveFromRequestQueue(nId);});
			ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function (evt:Event): void {
				RemoveFromRequestQueue(nId);});
			ldr.load(urlr);
		}
	}
}