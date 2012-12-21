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
	import com.adobe.crypto.MD5;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	
	import imagine.documentObjects.IDocumentSerializable;
	
	import mx.core.Application;
	import mx.core.EventPriority;
	import mx.core.SpriteAsset;
	import mx.core.UIComponent;
	
	import overlays.helpers.Cursor;
	
	import util.ABTest;
	import util.PicnikAlert;
	import util.UrchinProxy;
	import util.UserBucketManager;
	
	// Util is a place to put global static functions that have no other place to live
	public class Util {
		public static const krad90:Number = Math.PI / 2;
		public static const krad180:Number = Math.PI;
		public static const krad360:Number = Math.PI * 2;

		// Constants
		private static const kradCloseTo90:Number = krad90 / 90 / 1000; // CONFIG: Anything less than this is what we consider "close enough" to 90 degrees
		
		// Import this to force it to build (monkey patched)
		private static const _sprass:SpriteAsset = null;

		private static var _astrLogEvents:Array = [];
		private static var _tmrUrchin:Timer = null;
		private static var _strUserAgent:String = null;
		
		// Look for an item in a dictionary without calling toString()
		// For some reason, using (ob in dct) will call toString() on ob
		// if it does not find ob in the dictionary.
		public static function InDict(obKey:Object, dct:Dictionary): Boolean {
			return !(dct[obKey] === undefined);
		}
		
		// Convert degrees into radians
		public static function RadFromDeg(degAngle:Number): Number {
			return degAngle * Math.PI / 180;
		}
		
		// Convert radians into degrees
		public static function DegFromRad(radAngle:Number): Number {
			return radAngle * 180 / Math.PI;
		}

		// Returns true if the radian angle is close to a 90 degree mark (within roughly 1/1000th of a degree)
		public static function IsCloseTo90(radAngle:Number): Boolean {
			return Math.abs(RadsFromNearest90(radAngle)) < kradCloseTo90;
		}
		
		public static function RadNearest90(radAngle:Number): Number {
			return Math.round(radAngle / Util.krad90) * Util.krad90;
		}

		// Helper function which finds the straighten offset for a set angle.
		public static function RadsFromNearest90(radAngle:Number): Number {
			return RadNearest90(radAngle) - radAngle;
		}

		// Convert an arbitrary radian to an equivalent radian between 0 and 2*PI
		public static function NormalizeRad(radAngle:Number): Number {
			if (radAngle < 0) radAngle += Math.ceil(-radAngle / Util.krad360) * Util.krad360;
			else if (radAngle >= Util.krad360) radAngle -= Math.floor(radAngle / Util.krad360) * Util.krad360;
			return radAngle;
		}

		// Returns nom/denom
		// Returns Number.MAX_VALUE if the denominator is zero
		public static function SafeDivide(nNom:Number, nDenom:Number): Number {
			if (nDenom == 0)
				return Number.MAX_VALUE;
			else
				return nNom / nDenom;
		}
		
		// Rounds a number to nDigits significant digits (following digits are 0)
		public static function RoundToSignificant(n:Number, nDigits:Number): Number {
			var strN:String = n.toString();
			var strRet:String = "";
			for (var i:int = 0, j:int = 0; i < nDigits; i++, j++) {
				if (j > strN.length)
					strRet += "0";
				else
					strRet += strN.charAt(j);
				if (strN.charAt(j) == ".")
					strRet += strN.charAt(++j);
			}
			return Number(strRet);
		}
		
		public static function FormatBytes(nBytes:Number): String {
			const astrByteNames:Array = ["bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB", "NB", "DB"];  // NOTE: 1 DB is approx 52,000 times more than enough to store HD video of every hour of every person's life, ever.
			nBytes = Math.round(nBytes);
			var i:Number;
			for (i = 0; (i < (astrByteNames.length - 1)) && (nBytes > 1023); i++) {
				nBytes = nBytes / 1024;
			}
			return RoundToSignificant(nBytes, 3).toString() + " " + astrByteNames[i];
		}
		
		// Return a unique 16-digit hex string
		public static function GetUniqueId(): String {
			return MD5.hash(Math.random().toString() + getTimer().toString());
		}
		
		public static function GetRandomId( nLen:Number = 8): String {
			const kSource:String = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
			var strId:String = ""
			for (var i:int = 0; i<nLen;i++) {
				strId += kSource.charAt(Math.floor(Math.random() * kSource.length));
			}
			return strId;
		}
		
		public static function FindAncestorById(uic:UIComponent, strId:String): UIComponent {
			while (uic != null) {
				if (uic.id == strId)
					return uic;
				uic = uic.parent as UIComponent;
			}
			return null;
		}
		
		// NormalizeURL accepts URLs in various forms and validates and normalizes
		// them. It returns null if the URL is invalid and 'proto://domain/file'
		// if valid. If the URL is determined to be relative (case C below) then
		// the passed in strRoot is prepended to it.
		//
		// We accept URLs in several forms. Any of these forms may have query
		// parameters appended to them.
		//
		// case A: Fully qualified URL
		// http://www.domain.com
		// http://www.domain.com/
		// http://www.domain.com/dir
		// http://www.domain.com/page.html
		// http://www.domain.com/image.jpg
		// ftp://...
		// https://...
		//
		// case B: URL in need of scheme
		// www.domain.com
		// www.domain.com/dir
		// www.domain.com/page.html
		// www.domain.com/image.jpg
		//
		// case C: Relative URL
		// image.jpg
		// dir/image.jpg
		// ./image.jpg
		// ../image.jpg
		// ../dir/image.jpg
		//
		// case D: Domain root relative URL
		// /image.jpg (www.happy.com)
		// /dir/image.jpg
		// //images.whatever.org/image.jpg (slashdot.org)
		//
		// case E: Invalid URL
		// empty string
		
		public static function NormalizeURL(strUrl:String, strRoot:String=null): String {
			// Detect case E (Invalid) URLs
			if (strUrl.length == 0)
				return null;
			if (strUrl.length > 2083) // longest URL IE will allow
				return null;
				
			// URLs comprised solely of whitespace are invalid
			var ich:Number;
			for (ich = 0; ich < strUrl.length; ich++)
				if (!IsWhitespace(strUrl.charAt(ich)))
					break;
			if (ich == strUrl.length)
				return null;
			
			// UNDONE: anything else we can eliminate out of hand?
			
			// Detect case A URLs. The extra check is so we don't confuse a URL
			// like 'www.foo.com/page.html?http://www.bar.com' (case B) as case A
			if (strUrl.indexOf("//:") != -1 && strUrl.indexOf("//:") == strUrl.indexOf("/")) {
				
				// It's good already, leave it alone
				
			// Detect case B URLs and add 'http://' to normalize them to case A
			// UNDONE: differentiate cnn.ca (case B) from cnn.jpg (case C)
			} else {
				var astrSegs:Array = strUrl.split("/");
				// First path segment must have a '.'
				var ichDot:Number = astrSegs[0].indexOf(".");
				if (ichDot != -1) {
					// UNDONE: to be extra robust we should check if the extension
					// is one of "com", "org", "
					strUrl = "http://" + strUrl;
				} else {
					// Prefix URL with the URL it must be relative to
				}
			}
			
			return strUrl;
		}
		
		// The URL root of 'http://www.domain.com/dir/file.html?query=whatever' is
		// 'http://www.domain.com/dir'
		// UNDONE: whose job is it to convert http://localhost into http://localhost/ ?
		public static function GetURLRoot(strUrl:String): String {
			strUrl = GetQuerylessURL(strUrl);
			var ichLastSlash:Number = strUrl.lastIndexOf("/");
			if (ichLastSlash == -1) {
				trace("GetURLRoot: something is wrong with " + strUrl);
				return null;
			}
			var ichSchemeSep:Number = strUrl.indexOf("://");
			
			// Make sure we don't lop off the domain!
			if (ichSchemeSep + 2 == ichLastSlash)
				return strUrl;
				
			return strUrl.slice(0, ichLastSlash);
		}
	
		public static function GetQuerylessURL(strUrl:String): String {
			var ichQuestion:Number = strUrl.indexOf("?");
			if (ichQuestion != -1)
				strUrl = strUrl.slice(0, ichQuestion);
			return strUrl;
		}
	
		//
		// Helpers
		//
		
		private static function IsWhitespace(str:String): Boolean {
			for (var ich:Number = 0; ich < str.length; ich++) {
				var ch:String = str.charAt(ich);
				if (ch != " " && ch != "\t" && ch != "\n")
					return false;
			}
			return true;
		}

		// Remove matching quotes (either ' or ") from the beginning and end
		// of a string. Unquoted strings are returned unchanged.
		public static function RemoveQuotes(strText:String): String {
			if (strText.length > 1) {
				var strFirstChar:String = strText.substr(0,1);
				var strLastChar:String = strText.substr(strText.length-1,1);
				const strQuotes:String = "\"'";
				if (strQuotes.indexOf(strFirstChar) >= 0 && strFirstChar == strLastChar) {
					// Quoted string. Remove the quotes
					strText = strText.substr(1, strText.length - 2);
				}
			}
			if (strText.length < 1) strText = null;
			return strText;
		}
		
		public static function Utf8FromUnicode(strUnicode:String): String {
			var ba:ByteArray = new ByteArray();
			ba.writeUTFBytes(strUnicode);
			ba.position = 0;
			var strUtf8:String = "";
			for (var i:Number = 0; i < ba.length; i++)
				strUtf8 += String.fromCharCode(ba.readByte());
			return strUtf8;
		}
		
		// Convert a string of concatenated query parameters (e.g. "name1=value1&name2=value2")
		// into an object (e.g. { name1: "value1", name2: "value2" }). Names and values are
		// unescaped along the way.
		public static function ObFromQueryString(strQuery:String, fUseDecodeUriComponent:Boolean=false): Object {
			var strName:String, strValue:String;
			var index:int;
			var ob:Object = new Object();
		
			var astrPairs:Array = strQuery.split('&');
			for each (var strPair:String in astrPairs) {
				if (strPair.length == 0)
				  continue;
				 
				var nEqualsPos:Number = strPair.indexOf("=");
				if (nEqualsPos < 0)
					continue;
					
				strName = strPair.substr( 0, nEqualsPos );
				strValue = strPair.substr( nEqualsPos + 1 );

				if (fUseDecodeUriComponent) {
					strName = decodeURIComponent(strName);
					strValue = decodeURIComponent(strValue);
				} else {
					strName = unescape(strName);
					strValue = unescape(strValue);
				}
				
				ob[strName] = strValue;
			}
	
			return ob;
		}
		
		// Perform a deep compare of two objects. Return true if their members
		// are the same and contain the same values all the way down. Otherwise
		// return false.
		public static function CompareObjects(obA:Object, obB:Object): Boolean {
			var baA:ByteArray = new ByteArray();
			var baB:ByteArray = new ByteArray();
			baA.writeObject(obA);
			baB.writeObject(obB);
			if (baA.length != baB.length)
				return false;
			
			var strA:String = baA.toString();
			var strB:String = baB.toString();
			if (strA != strB)
				return false;
			return true;
		}
		
		// Deserialize the XML to an Object with typed fields. If an Object is
		// passed in the fields are written to it instead of creating a new one.
		public static function ObFromXmlProperties(xmlProperties:XML, ob:Object=null, fOverwrite:Boolean=true): Object {
			if (ob == null)
				ob = new Object();
			for each (var xmlProperty:XML in xmlProperties.Property) {
				try {
					var strProp:String = xmlProperty.@name;
					if (fOverwrite || !(strProp in ob))
						ob[strProp] = ObFromProperty(xmlProperty.@value, xmlProperty.@type, xmlProperty);
				} catch (e:Error) {
					trace("Error in ObFromXmlProperties: " + e.message);
					trace(e.getStackTrace());
					trace("xml:");
					trace(xmlProperty.toXMLString());
					trace("All properties:");
					trace(xmlProperties.toXMLString());
					trace("This property: " + xmlProperty.@value + ", " + xmlProperty.@type);
				}
			}
			return ob;
		}
		
		public static function IsComplexType(ob:*): Boolean {
			return typeof ob == "object";
		}

		// Given a string and a type, return an instance of the type initialized
		// to the type-converted value in the string.
		public static function ObFromProperty(strValue:String, strType:String, xmlProperty:XML): * {
			switch (strType.toLowerCase()) {
			case "null":
				return null;
				
			case "boolean":
				return strValue == "true";
				
			case "int":
				return int(Number(strValue));
				
			case "void":
				return undefined;
					
			case "number":
				return Number(strValue);
					
			case "string":
				return strValue;
				
			case "date":
				return new Date(strValue);
				
			case "flash.geom::rectangle":
			case "imagine.serialization::srectangle":
				// parse Rectangle string, e.g.:
				// (x=-128.72761312269904, y=-47.96440217391303, w=257.4552262453981, h=95.92880434782606)
				var rx:RegExp = /\(x=(.*), y=(.*), w=(.*), h=(.*)\)/;
				var ob:Object = rx.exec(strValue);				
				return new Rectangle(Number(ob[1]), Number(ob[2]), Number(ob[3]), Number(ob[4]));

			case "object":
				if (strValue == "null")
					return null;
					
				trace("Util.ObFromProperty: unhandled type " + strType + ", value: " + strValue);
				break;
				
			case "array":
				var aob:Array = [];
				var i:int = 0;
				for each (var xmlT:XML in xmlProperty.Property)
					aob[i++] = ObFromProperty(xmlT.@value, xmlT.@type, xmlT);
				return aob;
				
			default:
				// Is this an IDocumentSerializable?
				var docs:IDocumentSerializable = null;
				try {
					// documentObjects were relocated to imagine.documentObjects 03/17/2011
					// This fix retains backwards compatibility w/ older docs.
					if (strType.indexOf("documentObjects.") == 0)
						strType = "imagine." + strType;
					var clsDocumentObject:Class = getDefinitionByName(strType) as Class;
					docs = (IDocumentSerializable)(new clsDocumentObject());
					Util.ObFromXmlProperties(xmlProperty, docs);
				} catch (err:ReferenceError) {
					trace("Error in ObFromProperty: " + err.message);
					trace(err.getStackTrace());
					trace("xml:");
					trace(xmlProperty.toXMLString());
					Debug.Assert(false, "Unknown DocumentObject " + strType);
					return undefined;
				}
				
				return docs;
			}
			
			return undefined;
		}

		// If strProp is null (e.g. for an array element) then the property is added nameless
		// with ob as its value.		
		private static function AddXmlProperty(xml:XML, ob:Object, strProp:String=null): void {
			var obValue:* = strProp ? ob[strProp] : ob;
			var xmlProp:XML;
			if (obValue is IDocumentSerializable) {
				var docs:IDocumentSerializable = obValue as IDocumentSerializable;
				xmlProp = XmlPropertiesFromOb(docs, "Property", docs.serializableProperties);
				if (strProp)
					xmlProp.@name = strProp;
				// documentObjects were relocated to imagine.documentObjects 03/17/2011
				// This fix retains backwards compatibility w/ older docs.
				var strClassName:String = getQualifiedClassName(docs);
				if (strClassName.indexOf("imagine.") == 0)
					strClassName = strClassName.slice(8);
				xmlProp.@type = strClassName;
			} else {
				var strType:String = getQualifiedClassName(obValue);
				if (strType == "Array") {
					if (strProp)
						xmlProp = <Property name={strProp} type={strType}/>;
					else
						xmlProp = <Property type={strType}/>;
					var aobProps:Array = obValue as Array;
					for (var i:int = 0; i < aobProps.length; i++) {
						var obT:* = aobProps[i];
						AddXmlProperty(xmlProp, obT);
					}
				} else {
					if (strProp)
						xmlProp = <Property name={strProp} value={obValue} type={strType}/>;
					else
						xmlProp = <Property value={ob} type={strType}/>;
				}
			}
			xml.appendChild(xmlProp);
		}
		
		// The caller either wants us to Xml-ize all the object's properties (astrSubset==null),
		// a subset (astrSubset!=null, fExclude==false), or everything but the subset (astrSubset!=null,
		// fExclude==true).
		public static function XmlPropertiesFromOb(ob:Object, strElementName:String="Object",
				astrSubset:Array=null, fExclude:Boolean=false): XML {
			var astrProps:Array = [];
			var strProp:String;
			if (astrSubset != null) {
				if (fExclude) {
					for (strProp in ob)
						if (astrSubset.indexOf(strProp) == -1)
							astrProps.push(strProp);
				} else {
					astrProps = astrSubset;
				}
			} else {
				for (strProp in ob)
					astrProps.push(strProp);
			}
			
			var xml:XML = <{strElementName}/>;
			// DEBUG: Sort to make this predictable
			// astrProps.sort();
			for each (strProp in astrProps)
				AddXmlProperty(xml, ob, strProp);
			return xml;
		}

		public static function ShowAlertWithoutLogging(strMsg:String = "", strTitle:String = "", flags:uint=0x0004): void {
			PicnikAlert.show(strMsg, strTitle, flags);
		}

		public static function AlertLogging(strError:String, e:Error=null, nSeverity:Number=-1): void {
			if (nSeverity == -1)
				nSeverity = PicnikService.knLogSeverityWarning;
			if (strError.length > 1000) strError = strError.substr(0,1000) + "...";
			if (e != null) {
				PicnikService.LogException(strError, e);
				trace(strError + "\n" + e + ", " + e.getStackTrace());
			} else if (strError != null) {
				trace(strError);
				PicnikService.Log(strError, nSeverity);
			}
		}
		
		public static function ShowAlert(strMsg:String, strTitle:String, flags:uint, strError:String, e:Error=null, nSeverity:Number=-1): void {
			AlertLogging(strError, e, nSeverity);
			PicnikAlert.show(strMsg, strTitle, flags);
		}
		
		// Pass events with relative url-like names, e.g. "/MyComputerIn/failure?id=2032"
		// If logging is set to true, events look like: /app/Picnik.swf/MyComputerIn/failure?id=2032
		// If logging is set to false (default), events look like: /app/#/in/flickr
		public static function UrchinLogNav(strEvent:String, fImmediate:Boolean=false): void {
			UserBucketManager.GetInst().OnNav(strEvent);
			var strUrl:String = _UrchinString(strEvent, false);
			_UrchinTracker(strUrl, fImmediate);
			//_QuantCast(strUrl);
		}

		public static function UrchinLogReport(strEvent:String, fImmediate:Boolean=false): void {
			_UrchinTracker(_UrchinString(strEvent, true), fImmediate);
		}
		
		public static function LogUpgradePath(strUpgradePath:String, strPaymentMethod:String="CreditCard"): void {
			Util.UrchinLogReport("/purchase_path" + strUpgradePath);
			ABTest.HandleUpgrade(strUpgradePath, strPaymentMethod);
			Util.UrchinLogReport("/purchase_path_by_visits/" + UserBucketManager.GetInst().GetVisitKey() + strUpgradePath);
		}

		private static function _UrchinString(strEvent:String, fReport:Boolean=false): String {
				var strBase:String;
				if (fReport)
					strBase = "/r";
				else
					strBase = "/app/_"
				return escape(strBase + strEvent);
		}

		private static function OnLogTimer(evt:TimerEvent): void {
			if (_astrLogEvents.length == 0) {
				_tmrUrchin.stop();
			} else {
				_UrchinTracker(_astrLogEvents.pop(), true);
			}
		}

		private static function _UrchinTracker(strEvent:String, fImmediate:Boolean): void {
			if (fImmediate) {
				try {
					var strUrchinProxyCampaign:String = Object(Application.application).urchinProxyCampaign;
					if (strUrchinProxyCampaign != null) {
						if (CheckUrchinProxy()) {
							UrchinProxy.Log(strEvent, strUrchinProxyCampaign);
						}
					} else {
						if (Application.application.name.substr(0, 6) == "Picnik") { // Only log for Picnik swf
							try {
								ExternalInterface.call("urchinTracker", strEvent);
							} catch (err:Error) {
								// Ignore
							}
						}
					}
				} catch (e:Error) {
					PicnikService.Log("Urchin call failed: " + e);
				}
			} else {
				if (_tmrUrchin == null) {
					_tmrUrchin = new Timer(200);
					_tmrUrchin.addEventListener(TimerEvent.TIMER, OnLogTimer);
				}
				_astrLogEvents.push(strEvent);
				if (!_tmrUrchin.running)
					_tmrUrchin.start();
			}
		}

//		private static function _QuantCast(strEvent:String):void {
//			try {
//				if (Object(Application.application).thirdPartyEmbedded) {
//					return; // we don't currently support proxy for quantcast
//				} else {
//					if (Application.application.name.substr(0, 6) == "Picnik") { // Only log for Picnik swf
//						try {
//							ExternalInterface.call("quantserve", strEvent);
//						} catch (err:Error) {
//							// Ignore
//						}
//					}
//				}
//			} catch (e:Error) {
//				PicnikService.Log("_QuantCast call failed: " + e);
//			}
//		}
		
		// Returns true if urchin proxy is on (and sets up the urchin proxy)
		// Returns false if urchin proxy is off
		public static function CheckUrchinProxy(): Boolean {
			// These crazy references to PicnikBase and AccountMgr are done this way as to not
			// introduce a compile-time dependency on PicnikBase.as & AccountMgr.as. This is
			// important because the FlashRenderer uses Util.as but must not import those classes.
			var clsAccountMgr:Object = getDefinitionByName("AccountMgr");
			var fLog:Boolean = clsAccountMgr.GetInstance().GetUserAttribute('logPicnikLite', false);
			if (!fLog) {
				if (Application.application._pas.GetServiceParameter("logPicnikLite")) {
					fLog = true;
				}
			}
			if (fLog) {
				if (UrchinProxy.global.domain == null) {
					UrchinProxy.global.domain = clsAccountMgr.GetInstance().GetUserAttribute('logProxyDomain', '');
				}
			}
			return fLog;
		}
		
		public static function UrchinLogTransaction(strOrderId:String, strAffiliation:String, strTotal:String, strTax:String,
				strShipping:String, strCity:String, strState:String, strCountry:String, strSku:String,
				strProductName:String, strCategory:String, strPrice:String, strQuantity:String): void {
			if (Object(Application.application).thirdPartyEmbedded) {
				if (CheckUrchinProxy()) {
					UrchinProxy.recordTransaction(strOrderId, strAffiliation, strTotal, strTax, strShipping,
						strCity, strState, strCountry, strSku, strProductName, strCategory, strPrice, strQuantity);
				}
			} else {
				if (Application.application.name.substr(0, 6) == "Picnik") // Only log for Picnik swf
					try {
						ExternalInterface.call("recordTransaction", strOrderId, strAffiliation, strTotal, strTax, strShipping,
								strCity, strState, strCountry, strSku, strProductName, strCategory, strPrice, strQuantity);
					} catch (err:Error) {
						// ignore
					}
			}
		}
		
		public static function UrchinSetVar(strName:String, strValue:String): void {
			if (Application.application.name.substr(0, 6) == "Picnik") { // Only log for Picnik swf
				try {
					ExternalInterface.call("urchinSetCustomVariable", strName, strValue);
				} catch (err:Error) {
					// ignore
				}
			}
		}
		
		public static function EnableNavigateAwayWarning(strWarning:String=null): void {
			if (strWarning == null)
				strWarning = Resource.getString("Picnik", "navigate_away_warning");
			try {
				ExternalInterface.call("enableNavigateAwayWarning", strWarning);
			} catch (err:Error) {
				// ignore
			}
		}
				
		public static function DisableNavigateAwayWarning(): void {
			try {
				ExternalInterface.call("disableNavigateAwayWarning");
			} catch (err:Error) {
				// ignore
			}
		}
				
		// Take an arbitrary length string of hexidecimal digits and convert them into  the
		// equivalent string of decimal digits. Optimal? I doubt it but it gets the job done.
		// Thanks to 'Malcom' (http://www.thescripts.com/forum/thread212092.html)
		public static function HexStringToDecimalString(strHex:String): String {
			 // Divide by 10 repeatedly until the hex number is reduced to 0
			 // Each time concat the remainder (a decimal digit) to a new string
			 var strHexTmp:String = strHex;
			 var strDec:String = "";
			 do {
			 	var dct:Object = DivideBy10(strHexTmp);
			 	strDec = String.fromCharCode(dct.nDigit + 0x30) + strDec;
			 	strHexTmp = dct.strHex;
			 } while (strHexTmp != "0");
			
			 return strDec;
		}
		
		private static function DivideBy10(strHex:String): Object {
			var nCarry:Number = 0;
			var strOut:String = "";
			var fLeadingZero:Boolean = true;
			
			for (var ichHex:Number = 0; ichHex < strHex.length; ichHex++) {
				var num:Number = nCarry * 16 + parseInt(strHex.charAt(ichHex), 16);
				if (num != 0 || !fLeadingZero) {
					fLeadingZero = false;
					strOut += (num / 10).toString(16);
				}
				nCarry = num % 10;
			}
			
			return { strHex: strOut, nDigit: nCarry };
		}
		
		// gaanHZC array designates which of (top, left, right, bottom) defines each
		// zone of a padded hit box. The diagram below illustrates the zone values
		// assigned by HitTestPaddedRect. In addition to the interior zones, -1 is
		// assigned to coordinates completely outside the padded box hit zones.
		//         -1
		//          9 (rotate handle, if fTestRotate == true)
		//          |
		//     +-+--+--+-+
		//     |1|  2  |3|
		//     +-+-----+-+
		// -1  |8|  0  |4|  -1
		//     +-+-----+-+
		//     |7|  6  |5|
		//     +-+-----+-+
		//         -1
		public static var gaanHZC:Array = [
			[0, 0, 0, 0], // L, T, R, B
			[1, 1, 0, 0], [0, 1, 0, 0], [0, 1, 1, 0], [0, 0, 1, 0],
			[0, 0, 1, 1], [0, 0, 0, 1], [1, 0, 0, 1], [1, 0, 0, 0],
			[0, 0, 0, 0]
		];
		
		public static var gacsrHitCursors:Array = [
			Cursor.csrSystem, Cursor.csrMove,
			Cursor.csrSize2, Cursor.csrSize4, Cursor.csrSize1, Cursor.csrSize3,
			Cursor.csrSize2, Cursor.csrSize4, Cursor.csrSize1, Cursor.csrSize3,
			Cursor.csrRotate, Cursor.csrIBeam
		];
		
		public static const kcyRotateHandle:Number = 25; // CONFIG:
		
		public static function HitTestPaddedRect(rcl:Rectangle, x:Number, y:Number, cxyPad:Number,
				fTestRotate:Boolean=false, fTestTextEdit:Boolean=false): Number {
			var rclOuter:Rectangle = rcl.clone();
			
			// Test to see if point is outside all hit zones
			rclOuter.inflate(cxyPad, cxyPad);
			if (!rclOuter.contains(x, y)) {
				// Wait a second, it might be in the rotate handle
				if (fTestRotate) {
					// HACK: assume rotatable rectangles are positioned relative to a 0,0 origin
					// and should be rotated around that point
					var rclRotateHandle:Rectangle = new Rectangle(
							/*rcl.left + (rcl.width / 2) + */ Math.round(-cxyPad / 2), rcl.top - kcyRotateHandle - 2, cxyPad, cxyPad);
					if (rclRotateHandle.contains(x, y))
						return 9;
				}
				return -1;
			}
				
			// Test to see if point is inside the box (but not in one of the edge zones)
			// Give priority to the inside 'move' zone over the edges if the rect is so
			// small that they conflict.
			var rclInner:Rectangle = rcl.clone();
			if (!fTestTextEdit) {
				if (rclInner.width > cxyPad * 4)
					rclInner.inflate(-cxyPad, 0);
				if (rclInner.height > cxyPad * 4)
					rclInner.inflate(0, -cxyPad)
			}
			if (rclInner.contains(x, y))
				return 0;
				
			// If the inner rect is empty make sure it doesn't have a negative width or height
			if (rclInner.isEmpty()) {
				if (rclInner.width < 0) {
					rclInner.x = rcl.left + rcl.width / 2;
					rclInner.width = 0;
				}
				if (rclInner.height < 0) {
					rclInner.y = rcl.top + rcl.height / 2;
					rclInner.height = 0;
				}
			}
	
			// Must be one of the edge zones. Figure out which one.
			if (x < rclInner.left) {
				if (y < rclInner.top)
					return 1; 		// top-left
				if (y < rclInner.bottom)
					return 8; 		// left
				return 7;			// bottom-left
			} else if (x >= rclInner.right) {
				if (y < rclInner.top)
					return 3;		// top-right
				if (y < rclInner.bottom)
					return 4;		// right
				return 5;			// bottom-right
			} else if (y < rclInner.top) {
				return 2;			// top
			}
			return 6;				// bottom
		}

		// Constrain a number between a min and max
		public static function ConstrainNumber(n:Number, nMin:Number, nMax:Number): Number {
			if (nMin > nMax) { // Make sure min is less than max
				var nTmp:Number = nMin;
				nMin = nMax;
				nMax = nTmp;
			}
			if (n < nMin) n = nMin;
			else if (n > nMax) n = nMax;
			return n;
		}

		// Constrains a rectangle. Similar to intersect, but it always returns a valid rect.
		// Rectangle.intersect() returns Rect(0,0,0,0) if there is no intersection
		// ConstrainRect() returns the closest intersecting rectangle of at least one pixel
		public static function ConstrainRect(rcd:Rectangle, rcdConstraint:Rectangle): Rectangle {
			rcd.left = ConstrainNumber(rcd.left, rcdConstraint.x, rcdConstraint.right - 1);
			rcd.top = ConstrainNumber(rcd.top, rcdConstraint.y, rcdConstraint.bottom - 1);
			rcd.right = ConstrainNumber(rcd.right, rcd.left+1, rcdConstraint.right);
			rcd.bottom = ConstrainNumber(rcd.bottom, rcd.top+1, rcdConstraint.bottom);

			return rcd;
		}
		
		public static function ConstrainRectDeluxe(rc:Rectangle, nHitZone:Number, ptProportions:Point,
				fReversedX:Boolean, fReversedY:Boolean, fResizeToFit:Boolean, rcBounds:Rectangle=null): Rectangle {
					
			if (rcBounds != null) {
				// Trim the rect to fit within the bounds
				rc = ConstrainRect(rc, rcBounds);
			}
			
			// If the hit zone is -1 that means the caller hasn't decided on a particular edge/corner bias.
			// Since we need one to enforce the desired proportions we'll pick the lower-right corner.
			if (nHitZone == -1)
				nHitZone = 5;
				
			// Resize the rect to conform to the desired proportions. Use nHitZone to decide
			// which edges to resize. While we're at it make sure the conformed rect still fits
			// within the document.
			
			var cxDim:Number = ptProportions.x;
			var cyDim:Number = ptProportions.y;
			if (cxDim != -1 && cyDim != -1) {
				var cxNew:Number, cyNew:Number;
	
				// Pin the specified edges
				switch (nHitZone) {
				case 4: // right edge
				case 8: // left edge -- force the height to conform
					cyNew = Math.max(1, rc.width * cyDim / cxDim);
					var yNew:Number = rc.y + (rc.height - cyNew) / 2;
					if (rcBounds) {
						if (yNew < rcBounds.top)
							yNew = rcBounds.top;
						if (yNew + cyNew >= rcBounds.bottom) {
							yNew = rcBounds.bottom - cyNew;
							if (yNew < rcBounds.top) {
								cyNew += yNew;
								yNew = rcBounds.top;
							}
						}
					}
					var cxOld:Number = rc.width;
					rc.width = cyNew * cxDim / cyDim;
					if ((nHitZone == 4 && fReversedX) || (nHitZone == 8 && !fReversedX))
						rc.x += cxOld - rc.width;
					rc.y = yNew;
					rc.height = cyNew;
					break;
				
				case 2: // top edge
				case 6: // bottom edge -- force the width to conform
					cxNew = Math.max(1, rc.height * cxDim / cyDim);
					var xNew:Number = rc.x + (rc.width - cxNew) / 2;
					if (rcBounds) {
						if (xNew < rcBounds.left)
							xNew = rcBounds.left;
						if (xNew + cxNew >= rcBounds.right) {
							xNew = rcBounds.right - cxNew;
							if (xNew < rcBounds.left) {
								cxNew += xNew;
								xNew = rcBounds.left;
							}
						}
					}
					var cyOld:Number = rc.height;
					rc.height = cxNew * cyDim / cxDim;
					if ((nHitZone == 6 && fReversedY) || (nHitZone == 2 && !fReversedY))
						rc.y += cyOld - rc.height;
					rc.x = xNew;
					rc.width = cxNew;
					break;
					
				case 1: // top-left corner
				case 5: // bottom-right corner
				case 3: // top-right corner
				case 7: // bottom-left corner
					// Rotate proportions to match our drag rect
					if ((rc.height > rc.width) != (cyDim > cxDim) && !fResizeToFit) {
						var nT:Number = cxDim;
						cxDim = cyDim;
						cyDim = nT;
					}
					cxNew = Math.max(1, rc.height * cxDim / cyDim);
					cyNew = Math.max(1, rc.width * cyDim / cxDim);
					if (cxNew > rc.width) {
						cxNew = cyNew * cxDim / cyDim;
					} else if (cyNew > rc.height) {
						cyNew = cxNew * cyDim / cxDim;
					}
					if ((!fReversedY && (nHitZone == 1 || nHitZone == 3)) || (fReversedY && (nHitZone == 5 || nHitZone == 7)))
						rc.top = rc.bottom - cyNew;
					else
						rc.bottom = rc.top + cyNew;
					if ((!fReversedX && (nHitZone == 1 || nHitZone == 7)) || (fReversedX && (nHitZone == 5 || nHitZone == 3)))
						rc.left = rc.right - cxNew;
					else
						rc.right = rc.left + cxNew;
					break;
				}
			}
			return rc;
		}
		
		// Capture all mouse move events until the button is let up.
		public static function CaptureMouse(stage:Stage, fnOnMouseMove:Function, fnOnMouseUp:Function=null): void {
			var fnOnStageCaptureMouseUp:Function = function (evt:MouseEvent): void {
//				trace("CaptureMouseUp");
				Cursor.Release();
				evt.stopImmediatePropagation();
				stage.removeEventListener(MouseEvent.MOUSE_UP, fnOnStageCaptureMouseUp, true);
//				stage.removeEventListener(MouseEvent.MOUSE_MOVE, fnOnMouseMove, true);
				stage.removeEventListener(MouseEvent.MOUSE_UP, fnOnStageCaptureMouseUp, false);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, fnOnMouseMove, false);
				
				if (fnOnMouseUp != null)
					fnOnMouseUp(evt);
			}
			
//			trace("CaptureMouseDown");
			// use_capture = true so we can grab these events before anyone else
			stage.addEventListener(MouseEvent.MOUSE_UP, fnOnStageCaptureMouseUp, true, EventPriority.CURSOR_MANAGEMENT);
//			stage.addEventListener(MouseEvent.MOUSE_MOVE, fnOnMouseMove, true, 10);
			
			// For some reason mouse move events events generated while off the stage aren't sent
			// to fCapture=true handlers so we also have to set targeting/bubble up phase listener
			stage.addEventListener(MouseEvent.MOUSE_UP, fnOnStageCaptureMouseUp, false, EventPriority.CURSOR_MANAGEMENT);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, fnOnMouseMove, false, EventPriority.CURSOR_MANAGEMENT);
			Cursor.Capture();
		}

		// Recurse through all children of the DisplayObjectContainer looking for the strName'd DisplayObject		
		public static function GetChildByName(dobc:DisplayObjectContainer, strName:String): DisplayObject {
			for (var i:int = 0; i < dobc.numChildren; i++) {
				var dob:DisplayObject = dobc.getChildAt(i);
				if (dob.name == strName)
					return dob;
				if (!(dob is DisplayObjectContainer))
					continue;
				dob = GetChildByName(DisplayObjectContainer(dob), strName);
				if (dob != null)
					return dob;
			}
			return null;
		}

		public static function GetChildById(uicContainer:UIComponent, strId:String): UIComponent {
			var astrPath:Array = strId.split('.');
			if (astrPath.length == 0) return null;
			var uicChild:UIComponent = _GetChildById(uicContainer, astrPath[0]);
			var nNextPos:Number = 1;
			while (uicChild != null && nNextPos < astrPath.length) {
				uicChild = _GetChildById(uicChild, astrPath[nNextPos]);
				nNextPos += 1;
			}
			return uicChild;
		}
		
		private static function _GetChildById(uicContainer:UIComponent, strId:String): UIComponent {
			for (var i:int = 0; i < uicContainer.numChildren; i++) {
				var uic:UIComponent = uicContainer.getChildAt(i) as UIComponent;
				if (uic == null)
					continue;
				if (uic.id == strId)
					return uic;
				uic = _GetChildById(uic, strId);
				if (uic != null)
					return uic;
			}
			return null;
		}
		
		// Return true if the DisplayObject is truly visible, i.e. it AND all its parents are visible
		public static function IsVisible(dob:DisplayObject): Boolean {
			while (dob != null) {
				if (!dob.visible)
					return false;
				dob = dob.parent;
			}
			return true;
		}
		
		// Return true if the DisplayObject is a descendant, at any level, of the parent object.
		public static function IsChildOf(dobChild:DisplayObject, dobParent:DisplayObject): Boolean {
			if (dobChild == null || dobParent == null)
				return false;
			while (dobChild.parent != null) {
				dobChild = dobChild.parent;
				if (dobChild == dobParent)
					return true;
			}
			return false;
		}
		
		static public function set userAgent( s:String ): void {
			_strUserAgent = s;
		}
		
		static public function get userAgent(): String {
			var strUserAgent:String = _strUserAgent;
			try {
				if (strUserAgent == null) {
					strUserAgent = ExternalInterface.call("getUserAgent");
				}
			} catch (e:Error) {
			}
			if (strUserAgent == null)
				strUserAgent = "Unknown";
			return strUserAgent;
		}
		
		static public function IsSafari(): Boolean {
			return Util.userAgent.toLowerCase().indexOf("safari") != -1;
		}
		
		static public function IsInternetExplorer(): Boolean {
			var strAgent:String = Util.userAgent.toLowerCase();
			return strAgent.indexOf("msie") != -1;
		}
		
		static public function IsChrome(): Boolean {
			var strAgent:String = Util.userAgent.toLowerCase();
			return strAgent.indexOf("chrome") != -1;
		}
		
		static public function IsVista(): Boolean {
			return Capabilities.os.indexOf("Windows Vista") != -1;
		}
		
		static public function IsWindows(): Boolean {
			return Capabilities.os.indexOf("Windows") != -1;
		}
		
		static public function IsVistaOrWindows7(): Boolean {
			return IsVista() || Capabilities.os == "Windows" || Capabilities.os == "Windows 7" || Capabilities.os == "Win 7";
		}
		
		private static var s_nFlashPlayerMajorVersion:int = 0;
		private static var s_nFlashPlayerMinorVersion:int = 0;
		private static var s_nFlashPlayerBugfixVersion:int = 0;
		private static var s_nFlashPlayerBuildVersion:int = 0;

		public static function FlashVersionIsAtLeast(anVTarget:Array): Boolean {
			return CompareVersions(GetFlashVersionArray(), anVTarget) >= 0;
		}
		
		public static function GetFlashVersionArray(): Array {
			return [GetFlashPlayerMajorVersion(), s_nFlashPlayerMinorVersion,
					s_nFlashPlayerBugfixVersion, s_nFlashPlayerBuildVersion];
		}
		
		// Returns positive if anV1 > anV2, 0 if equal, -1 otherwise
		// Left justified version arrays, missing values are set to 0
		public static function CompareVersions(anV1:Array, anV2:Array): Number {
			while (anV1.length < anV2.length) anV1.push(0);
			while (anV2.length < anV1.length) anV1.push(0);
			for (var i:Number = 0; i < anV1.length; i++) {
				if (anV1[i] > anV2[i])
					return 1;
				else if (anV1[i] < anV2[i])
					return -1;
			}
			return 0; // Equal
		}
		
		// Flash Player versions >= 10.0.12.36 are known to be good. Flash Player 10.0.12.24 (and perhaps
		// others) have a 512K-byte local load limit!
		public static function DoesUserHaveGoodFlashPlayer10(): Boolean {
			return FlashVersionIsAtLeast([10,0,12,36]);
		}
		
		// Windows Vista users don't get local saving until we can figure out how to
		// deal with Flash + Vista + IE 7/8's inability to save outside of the Desktop dir
		// when Protected Mode is enabled. See http://bugs.adobe.com/jira/browse/FP-727
		// DWM 8/5/2009: OMG!!! FP 10.0.32 fixes this! See
		// http://www.adobe.com/devnet/flashplayer/articles/flash_player10.0.32_security_update.html
		
		// BST 4/2/2009: We are seeing error 1069 for flash player version 10.0.1.128 when attempting a local save.
		public static function DoesUserHaveLocalSaveFlashPlayerAndBrowser(): Boolean {
			return Util.DoesUserHaveLocalSaveFlashPlayer() &&
				!(Util.IsVistaOrWindows7() && Util.IsInternetExplorer() && !Util.FlashVersionIsAtLeast([10, 0 , 32, 0]));
		}
		
		public static function DoesUserHaveLocalSaveFlashPlayer(): Boolean {
			return DoesUserHaveGoodFlashPlayer10();
		}
		
		public static function GetFlashPlayerMajorVersion(): int {
			ParseFlashPlayerVersion();
			return s_nFlashPlayerMajorVersion;
		}
		
		public static function GetFlashPlayerMinorVersion(): int {
			ParseFlashPlayerVersion();
			return s_nFlashPlayerMinorVersion;
		}
		
		public static function GetFlashPlayerBugfixVersion(): int {
			ParseFlashPlayerVersion();
			return s_nFlashPlayerBugfixVersion;
		}
		
		public static function GetFlashPlayerBuildVersion(): int {
			ParseFlashPlayerVersion();
			return s_nFlashPlayerBuildVersion;
		}
		
		public static function GetFlashPlayerMajorMinorVersion(): Number {
			return Number(GetFlashPlayerMajorVersion() + "." + GetFlashPlayerMinorVersion());
		}
		
		private static function ParseFlashPlayerVersion(): void {
			if (s_nFlashPlayerMajorVersion != 0)
				return;
				
			// The version number is a list of items divided by ","
			var astrVersion:Array = Capabilities.version.split(",");

			if (astrVersion.length > 1)
				s_nFlashPlayerMinorVersion = parseInt(astrVersion[1]);
			if (astrVersion.length > 2)
				s_nFlashPlayerBugfixVersion = parseInt(astrVersion[2]);
			if (astrVersion.length > 3)
				s_nFlashPlayerBuildVersion = parseInt(astrVersion[3]);
			
			// The main version contains the OS type too so we split it in two
			// and we'll have the OS type and the major version number separately.
			astrVersion = astrVersion[0].split(" ");
			s_nFlashPlayerMajorVersion = parseInt(astrVersion[1]);
		}
		
		// Flash 10's rule for max image size is:
		// width < 8192 && height < 8192 && width * height * 4 < 64 * 1024 * 1024
		// FP9 experience has us not trusting it right up at the limit so we
		// max out at 8000 px/side or 16,000,000 total (instead of 16,777,216).
		private static const kcxyFP10Limit:int = 8000;
		private static const kcxyHalfFP10Limit:int = kcxyFP10Limit / 2;
		
		public static function GetMaxImageWidth(cy:int=0): int {
			return GetLimitedImageSize(kcxyFP10Limit, cy).x;
		}
		
		public static function GetMaxImageHeight(cx:int=0): int {
			return GetLimitedImageSize(cx, kcxyFP10Limit).y;
		}
		
		public static function GetMaxImagePixels(): int {
			if (s_nFlashPlayerMajorVersion < 10)
				return 2800 * 2800;
			else
				return kcxyHalfFP10Limit * kcxyHalfFP10Limit;
		}
		
		// If total number of pixels exceeds the max, calc new dimensions that
		// fit within the max while retaining the original proportions. If the
		// dimensions fit within the max, return them unchanged.
		// Pins the minimum dimensions to 1.
		public static function GetLimitedImageSize(cx:int, cy:int, cxMax:int=0, cyMax:int=0, cPixelsMax:int=0): Point {
			if (cx < 1)
				cx = 1;
			if (cy < 1)
				cy = 1;
			var cxNew:int = cx;
			var cyNew:int = cy;
			
			var fFlashPlayerVersionGreaterOrEqualTo10:Boolean = GetFlashPlayerMajorVersion() >= 10;
			if (cxMax == 0)
				cxMax = fFlashPlayerVersionGreaterOrEqualTo10 ? kcxyFP10Limit : 2800;
			if (cyMax == 0)
				cyMax = fFlashPlayerVersionGreaterOrEqualTo10 ? kcxyFP10Limit : 2800;
			if (cPixelsMax == 0)
				cPixelsMax = fFlashPlayerVersionGreaterOrEqualTo10 ? kcxyHalfFP10Limit * kcxyHalfFP10Limit : 2800 * 2800;
			
			// First fit within the max dims
			if (cxNew > cxMax) {
				cxNew = cxMax;
				cyNew *= cxNew / cx;
				cy *= cxNew / cx;
			}
			if (cyNew > cyMax) {
				cyNew = cyMax;
				cxNew *= cyNew / cy;
			}
			
			var n:Number = Math.sqrt(cPixelsMax) / Math.sqrt(cxNew * cyNew);
			if (n < 1.0) {
				cxNew *= n;
				cyNew *= n;
			}
			return new Point(Math.max(1, Math.round(cxNew)), Math.max(1, Math.round(cyNew)));
		}
		
		public static function GetRotatedImageDims( cx:int, cy:int, radAngle:Number): Point {
			var cxW2:Number = Math.abs(cx * Math.cos(radAngle)) + Math.abs(cy * Math.sin(radAngle));
			var cyH2:Number = Math.abs(cy * Math.cos(radAngle)) + Math.abs(cx * Math.sin(radAngle));
			return new Point(int(cxW2), int(cyH2));			
		}
		
		// Return the angle (in degrees) an object should be rotated to be oriented along the
		// vector from ptS to ptE.
		public static function GetOrientation(ptS:Point, ptE:Point): Number {
			return Util.DegFromRad(Math.atan2(ptE.y - ptS.y, ptE.x - ptS.x));
		}
		
		// HACK: Flex's focusRect updating is buggy so we force it to do the right thing
		static public function UpdateFocusRect(uic:UIComponent): void {
			if (uic.focusManager) {
				var focusObj:DisplayObject = uic.focusManager ? DisplayObject(uic.focusManager.getFocus()) : null;
				uic.drawFocus(focusObj == uic);
			}
		}
		
		// Lines are infinite projections through two points.
		// A Ray is an infinite projection starting from a point and passing through another point.
		// A Segment is portion of a Line, specified by two end points.
		
		// Derived from http://code.google.com/p/cheezeworld/source/browse/trunk/Full%20Game%20Library%20(%20Current%20)/com/cheezeworld/math/Geometry.as

		// Returns the coordinates of the intersection in ptIntersection or null if no intersection.
		public static function GetRaySegmentIntersection(A:Point, B:Point, C:Point, D:Point): Point {
			var dxBA:Number = B.x - A.x;
			var dyBA:Number = B.y - A.y;
			var rTop:Number = (A.y-C.y) * (D.x-C.x) - (A.x-C.x) * (D.y-C.y);
			var sTop:Number = (A.y-C.y) * dxBA - (A.x-C.x) * dyBA;
			var bot:Number = dxBA * (D.y-C.y) - dyBA * (D.x-C.x);                     
			
			if (bot == 0) {
				// Lines are parallel
				return null;
			}
			
			var r:Number = rTop / bot;
			var s:Number = sTop / bot;
			
			if (r >= 0 && s >= 0 && s <= 1) {
				// A + r * (B - A)
				return new Point(A.x + r * dxBA, A.y + r * dyBA);
			}
			
			return null;
		}
		
		/*
		// Returns the coordinates of the intersection in ptIntersection or null if no intersection.
		public static function GetRaySegmentIntersection(ptRayO:Point, ptRayD:Point, ptSegA:Point, ptSegB:Point): Point {
			var obResult:Object = CalcLineLineIntersection(ptRayO, ptRayD, ptSegA, ptSegB);
			if (obResult) {
				if (obResult.r >= 0 && obResult.s >= 0 && obResult.s <= 1) {
					return new Point(ptRayO.x + (ptRayD.x - ptRayO.x) * obResult.r,
							ptRayO.y + (ptRayD.y - ptRayO.y) * obResult.r);
				}
			}
			return null;
		}
		
		private static function CalcLineLineIntersection(ptLine1A:Point, ptLine1B:Point, ptLine2A:Point, ptLine2B:Point): Object {
			var dxLine1:Number = ptLine1B.x - ptLine1A.x;
			var dyLine1:Number = ptLine1B.y - ptLine1A.y;
			var dxLine2:Number = ptLine2B.x - ptLine2A.x;
			var dyLine2:Number = ptLine2B.y - ptLine2A.y;
			
			if (dxLine1 / dyLine2 != dyLine1 / dxLine2) {
				var d:Number = dxLine1 * dyLine2 - dyLine1 * dxLine2;
				if (d != 0) {
					var dxLines:Number = ptLine1A.x - ptLine2A.x;
					var dyLines:Number = ptLine1A.y - ptLine2A.y;
					var r:Number = (dyLines * dxLine2 - dxLines * dyLine2) / d;
					var s:Number = (dyLines * dxLine1 - dxLines * dxLine2) / d;
					return { r: r, s: s };
				}
			}
			return null;
		}
		*/
	}
}
