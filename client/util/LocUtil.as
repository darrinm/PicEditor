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
package util {
	import mx.formatters.DateFormatter;
	import mx.formatters.NumberFormatter;
	import mx.resources.ResourceBundle;
	import mx.resources.ResourceManager;
	import mx.utils.ObjectProxy;
	import mx.utils.StringUtil;
	
	import picnik.util.LocaleInfo;
	
	public class LocUtil {
  		[ResourceBundle("LocUtil")] static protected var _rb:ResourceBundle;
		[ResourceBundle("templatesXmlText")] static protected var _rbTemplatesXmlText:ResourceBundle;

  		// Validators have the thousands separator
  		[ResourceBundle("validators")] static protected var _rbValidators:ResourceBundle;
		
		// Returns the locales array as an array of object proxies
		public static function get localesOP(): Array {
			var aop:Array = [];
			for each (var obLang:Object in LocUtil.locales)
				aop.push(new ObjectProxy(obLang));
			return aop;
		}

		public static function get locales():Array {
			return LocaleInfo.GetLocales(GooglePlusUtil.UsingGooglePlusAPIKey(PicnikBase.app.parameters));
		}
		
		public static function GetProcessingMessage(nChildrenLeft:Number=0, nChildrenTotal:Number=0): String {
			var nItemNumber:Number = nChildrenTotal - nChildrenLeft + 1;
			
			if (isNaN(nChildrenLeft) || isNaN(nChildrenTotal) || nChildrenTotal < 1 || nChildrenLeft < 0 || nChildrenLeft > nChildrenTotal) {
				return Resource.getString("LocUtil", "Working");
			} else {
				return LocUtil.rbSubst("LocUtil", "WorkingXofY", nItemNumber, nChildrenTotal);
			}
		}

		public static function Untitled(): String {
			return Resource.getString("LocUtil", "Untitled");
		}
		
		private static function GetLocaleInfo(strLocale:String=null): Object {
			if (strLocale == null)
				strLocale = PicnikBase.Locale();
			
			for (var strLoc:String in [strLocale, "en_US"]) { // Default to en_US if we can't find our current locale
				var i:int;
				for (i=0; i<LocUtil.locales.length; i++) {
					if (LocUtil.locales[i]['locale'] == strLocale) {
						return LocUtil.locales[i];
					}
				}
			}
			throw new Error("Couldn't find locale: " + strLocale);
		}

		// returns pretty version of language based on locale, i.e. "English", "Français", etc.
		public static function formattedLanguage(locale:String):String {
			return LocUtil.GetLocaleInfo(locale)['label'];
		}				  		
		
		// same as formattedLanguage(), but operates on current locale only
		public static function formattedCurrentLanguage():String {
			return formattedLanguage(PicnikBase.Locale());
		}
		
		private static const kobGooglePlusColorSubstitutes:Object = {
			'618430':'1155CC',
			'aecc85':'333333'
		};
		
		// Version of getString that does color substitution
		public static function getString(strBundle:String, strKey:String, parameters:Array = null): String {
			var str:String = ResourceManager.getInstance().getString(strBundle, strKey, parameters);
			if (GooglePlusUtil.UsingGooglePlusAPIKey(PicnikBase.app.parameters)) {
				for (var strFind:String in kobGooglePlusColorSubstitutes) {
					var strReplace:String = kobGooglePlusColorSubstitutes[strFind];
					str = replacei(str, strFind, strReplace);
				}
			}
			return str;
		}

		/**
		 *	Replaces all instances of the replace string in the input string
		 *	with the replaceWith string. Ignores case. Based on
		 *  com.adobe.utils.StringUtil
		 *
		 */
		public static function replacei(input:String, replace:String, replaceWith:String):String
		{
			replace = replace.toUpperCase();
			var sb:String = new String();
			var found:Boolean = false;
			
			var sLen:Number = input.length;
			var rLen:Number = replace.length;
			
			for (var i:Number = 0; i < sLen; i++)
			{
				if(input.charAt(i).toUpperCase() == replace.charAt(0))
				{  
					found = true;
					for(var j:Number = 0; j < rLen; j++)
					{
						if(!(input.charAt(i + j).toUpperCase() == replace.charAt(j)))
						{
							found = false;
							break;
						}
					}
					
					if(found)
					{
						sb += replaceWith;
						i = i + (rLen - 1);
						continue;
					}
				}
				sb += input.charAt(i);
			}
			return sb;
		}

		// Formatter for short dates, e.g. 10/10/2007
		private static var _dfShort:DateFormatter = null;
		public static function get shortDateFormatter(): DateFormatter {
			if (_dfShort == null) {
				_dfShort = new DateFormatter();
				_dfShort.formatString = Resource.getString('LocUtil', 'ShortDateFormat');
			}
			return _dfShort;
		}
		
		// Convert a date to a short format string, e.g. 10/10/2007
		public static function shortDate(date:Date): String {
			return shortDateFormatter.format(date);
		}  	
		
		// Formatter for short dates, e.g. 10/10/2007
		private static var _dfMedium:DateFormatter = null;
		public static function get mediumDateFormatter(): DateFormatter {
			if (_dfMedium == null) {
				_dfMedium = new DateFormatter();
				_dfMedium.formatString = Resource.getString('LocUtil', 'MediumDateFormat');
			}
			return _dfMedium;
		}
		
		// Convert a date to a medium format string, e.g. October 10, 2007
		public static function mediumDate(date:Date): String {
			return mediumDateFormatter.format(date);
		}  		
		
		// Convert a date to a smedium format string with unbreakable spaces
		//e.g. October&#xA0;10,&#xA0;2007
		public static function mediumDateNbsp(date:Date): String {
			return mediumDateFormatter.format(date).replace(" ", "\u00A0");
		}  	

		
		// Formatter for casual dates, e.g. Jun 10
		private static var _dfCasual:DateFormatter = null;
		public static function get casualDateFormatter(): DateFormatter {
			if (_dfCasual == null) {
				_dfCasual = new DateFormatter();
				_dfCasual.formatString = Resource.getString('LocUtil', 'CasualDateFormat');
			}
			return _dfCasual;
		}
		
		// Convert a date to a short format string, e.g. Jun 10
		public static function casualDate(date:Date): String {
			return casualDateFormatter.format(date);
		}  	  		
		// Formatter for cc expiration dates, e.g. 11/2013
		private static var _dfCCExpiration:DateFormatter = null;
		public static function get ccExpirationDateFormatter(): DateFormatter {
			if (_dfCCExpiration == null) {
				_dfCCExpiration = new DateFormatter();
				_dfCCExpiration.formatString = Resource.getString('LocUtil', 'CCExpirationDateFormat');
			}
			return _dfCCExpiration;
		}
		
		// Convert a date to a cc expiration, e.g. 11/2013
		public static function ccExpirationDate(date:Date): String {
			return ccExpirationDateFormatter.format(date);
		}  	

  		// Formatter for file date times
 		private static var _dfFileTime:DateFormatter = null;
		public static function get fileTimeFormatter(): DateFormatter {
  			if (_dfFileTime == null) {
  				_dfFileTime = new DateFormatter();
  				_dfFileTime.formatString = Resource.getString('LocUtil', 'FileTimeFormat');
  			}
  			return _dfFileTime;
  		}
  		
  		// Convert a date
  		public static function fileTime(date:Date): String {
  			return fileTimeFormatter.format(date);
  		}
  		  		
  		// Formatter for ISO 8601 dates
  		private static var _dfISO:DateFormatter = null;
  		public static function get isoDateFormatter(): DateFormatter {
  			if (_dfISO == null) {
  				_dfISO = new DateFormatter();
  				_dfISO.formatString = "YYYY-MM-DDTJJ:NN:SS";
  			}
  			return _dfISO;
  		}
  		
  		// convert a timezone offset for a date into something like -8:00
  		public static function isoGetTZ(date:Date): String {
  			var nTZ:Number = date.getTimezoneOffset();
  			var nHours:Number = Math.floor(nTZ/60);
  			var nMinutes:Number = Math.abs(nTZ) % 60;
  			var strTZ:String = (nTZ > 0 ? "-" : "+") + nHours + ":" + (nMinutes < 10 ? "0" : "") + nMinutes;
  			return strTZ;
  		}  	
  		
  		// Convert a date to ISO 8601 time
  		public static function isoDate(date:Date): String {
  			return isoDateFormatter.format(date) + isoGetTZ(date);
  		}  	
  		
  		public static function FormatDate(date:Date, strFormat:String): String {
  			var df:DateFormatter = new DateFormatter();
  			df.formatString = strFormat;
  			return df.format(date);
  		}  	
  			
  		public static function FormatNumberAsDate(date:Number, strFormat:String): String {
  			return FormatDate(new Date(date), strFormat);
  		}
  		
  		// Convert a number into a currency string, eg.  10 -> $10.00 USD
  		public static function moneyUSD(val:Number): String {
  			var nDollars:Number = Math.floor( val );
  			var nCents:Number = Math.round( (val - nDollars) * 100 );  			
  			var strDollars:String = String(nDollars);
  			var strCents:String = String(nCents);
  			if (nCents < 10)
  				strCents = "0" + strCents;  				
  			return LocUtil.rbSubst( "LocUtil", "usd_format", strDollars, strCents );
  		}
  		
  		// Lookup a key in a resource bundle then perform a substitution (with date formatting)
  		// For example, suppose you have a property file with this message:
  		// expires = Your subscription will expire on {0}
  		// You can perform the key lookup, date formatting, and substition like this:
  		// text="{LocUtil.rbSubst(rb, 'expires', AccountMgr.GetInstance().dateSubscriptionExpires)}"
		public static function rbSubst(strBundle:String, strKey:String, ... params): String {
			// Do some formatting of the params: dates get formatted with the locale
			for (var i:Number = 0; i < params.length; i++) {
				var ob:Object = params[i];
				if (ob is Date)
					params[i] = shortDate(ob as Date);
			}
			return StringUtil.substitute.apply(null, [LocUtil.getString(strBundle, strKey)].concat(params));
		}

		// Handle zero, one or plurals by automatically looking up the correct key and performing the substitution
		// For exampe, suppose you have these keys:
		// photos_Zero = No photos
		// photos_One = One photo
		// photos_Many = {0} photos
		// You can then use it like this:
		// text="{LocUtil.zeroOneOrMany(rb, cPhotos, 'photos')}"
		public static function zeroOneOrMany(strBundle:String, nVal:Number, strKeyBase:String): String {
			return zeroOneOrManyCustom(strBundle, nVal, strKeyBase + "_Zero", strKeyBase + "_One", strKeyBase + "_Many");
		}
		
		public static function zeroOneOrManyCustom(strBundle:String, nVal:Number, strKeyZero:String, strKeyOne:String, strKeyMany:String): String {
			var strKey:String;
			if (nVal == 0) strKey = strKeyZero;
			else if (nVal == 1) strKey = strKeyOne;
			else strKey = strKeyMany;
			return rbSubst(strBundle, strKey, nVal.toString());
		}
		
		/***
		 * Special case to handle the "3 photos / 4 albums" strings
		 * create keys like this:
		 * number_albums_photos_Zero_Zero = no albums / no photos
		 * number_albums_photos_Zero_One = no albums / {1} photo
		 * number_albums_photos_Zero_Many = no albums / {1} photos
		 * number_albums_photos_One_Zero = {0} album / no photos
		 * number_albums_photos_Many_Many = {0} albums / {1} photos
		 * etc...
		 ***/
		public static function zeroOneOrMany2(strBundle:String, nVal1:Number, nVal2:Number, strBase:String): String {
			var strKey:String = strBase;

			if (nVal1 == 0) strKey += "_Zero";
			else if (nVal1 == 1) strKey += "_One";
			else strKey += "_Many";

			if (nVal2 == 0) strKey += "_Zero";
			else if (nVal2 == 1) strKey += "_One";
			else strKey += "_Many";
			
			return rbSubst(strBundle, strKey, nVal1.toString(), nVal2.toString());
		}

		// Perform a conditional key lookup
		// If f is true, returns value of key1, else key2		
		public static function iff(strBundle:String, f:Boolean, strKey1:String, strKey2:String): String {
			var strKey:String = f ? strKey1 : strKey2;
			return Resource.getString(strBundle, strKey);
		}
		
		// Formats a number as a degree (including localized degree symbol)
		public static function deg(nVal:Number, nDecimals:Number=0): String {
			var nf:NumberFormatter = new NumberFormatter();
			nf.decimalSeparatorFrom = nf.decimalSeparatorTo = Resource.getString("LocUtil", "decimal_separator");
			nf.thousandsSeparatorFrom = nf.thousandsSeparatorTo = LocUtil.ConvertUnderscore(Resource.getString("validators", "thousandsSeparator"));
			if (nf.decimalSeparatorFrom == nf.thousandsSeparatorFrom) {
				trace("ERROR: thousands separator is decimal separator: " + PicnikBase.Locale());
				if (nf.decimalSeparatorFrom == ".") {
					nf.thousandsSeparatorFrom = nf.thousandsSeparatorTo = ",";
				} else {
					nf.thousandsSeparatorFrom = nf.thousandsSeparatorTo = ".";
				}
			}
			nf.precision = nDecimals;
			return rbSubst("LocUtil", "degrees", nf.format(nVal));
		}
		
		// Formats a number as a decimal with thousands separator
		public static function bignum(nVal:Number, nDecimals:Number=0): String {
			var nf:NumberFormatter = new NumberFormatter();
			nf.decimalSeparatorFrom = nf.decimalSeparatorTo = Resource.getString("LocUtil", "decimal_separator");
			nf.thousandsSeparatorFrom = nf.thousandsSeparatorTo = LocUtil.ConvertUnderscore(Resource.getString("validators", "thousandsSeparator"));
			if (nf.decimalSeparatorFrom == nf.thousandsSeparatorFrom) {
				trace("ERROR: thousands separator is decimal separator: " + PicnikBase.Locale());
				if (nf.decimalSeparatorFrom == ".") {
					nf.thousandsSeparatorFrom = nf.thousandsSeparatorTo = ",";
				} else {
					nf.thousandsSeparatorFrom = nf.thousandsSeparatorTo = ".";
				}
			}
			nf.precision = nDecimals;
			return nf.format(nVal);
		}
		
		// Formats a number as a percent (including localized percent symbol)
		public static function pct(nVal:Number): String {
			return rbSubst("LocUtil", "percent", Math.round(nVal).toString());
		}

		// Formats a number as a percent (including localized percent symbol), adds + to positive
		public static function signedpct(nVal:Number): String {
			return (nVal >= 0 ? '+' : '') + LocUtil.pct(nVal);
		}

		public static function width_by_height(nWidth:Number, nHeight:Number, fTight:Boolean=true, fRound:Boolean = true): String {
			if (fRound) nWidth = Math.round(nWidth);
			if (fRound) nHeight = Math.round(nHeight);
			var strKey:String = "width_by_height";
			if (fTight) strKey += "_tight";
			return rbSubst("LocUtil", strKey, nWidth, nHeight);
		}
		
		public static function width_height_sep(): String {
			return Resource.getString('LocUtil', 'width_height_separator');
		}
		
	    public static function ConvertUnderscore(str:String):String
	    {
    		var aTemp:Array = str.split("_");
			str = aTemp.join(" ");
	    	return str;
	    }
	   
	    // Take in english text, localize it if possible, if not, return english text.
	    // Useful for CMS type things (e.g. fancy collage)
	    public static function EnglishToLocalized(strText:String, strBundle:String="templatesXmlText"): String {
	    	if (strText == null || strText.length == 0)
	    		return strText;
			var strKey:String = strText;
			strKey = strKey.replace(/ *\r */gm,'_n_');
			strKey = strKey.replace(/[ ]+/g,'_');
			strKey = strKey.replace(/[^A-Za-z0-9_]+/g,'');
			strKey = strKey.toLowerCase();

			// Default key
			var strVal:String = ResourceManager.getInstance().getString(strBundle, strKey);
			if (strVal == null) {
				// No match found
				strVal = strText; // Return english text
				if (AccountMgr.GetInstance().isAdmin)
					trace("Template text key not found in " + strBundle + ".properties: " + strKey); 
			}
			return strVal;
	    }
	   
	    public static function PicnikLocToGoogleLoc( strLoc:String = null ): String {
			return LocUtil.GetLocaleInfo(strLoc)['googleCode'];
	    }
	}
}
