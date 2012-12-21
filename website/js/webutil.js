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

/** @export */
function navNoHistory(strDest, strTarget) {
	if (parent && parent.location && strTarget == "_parent") {
		parent.location.replace(strDest);
	} else {
		window.location.replace(strDest)
	}
}

/*
 * This function parses ampersand-separated name=value argument pairs from
 * the query string of the URL. The name/value pairs are returned as members
 * of an Object instance.
 *
 * Based on http://www.oreilly.com/catalog/jscript3/chapter/ch13.html
 */
/** @export */
function ExtractArgs() {
	var query = location.search.substring(1);  // Get query string.
	return SplitQueryString( query );
}

/** @export */
function SplitQueryString( query ) {
	var args = new Object();
	var pairs = query.split("&");              // Break at ampersand.
	for (var i = 0; i < pairs.length; i++) {
		var pos = pairs[i].indexOf('=');       // Look for "name=value".
		if (pos == -1) continue;               // If not found, skip.
		var argname = pairs[i].substring(0,pos);  // Extract the name.
		var value = pairs[i].substring(pos+1); // Extract the value.
		args[argname] = unescape(value);
	}
	return args;
}

/*
 * Three functions for handling cookies courtesy of
 * http://www.quirksmode.org/js/cookies.html
 */
/** @export */
function createCookie(name,value,opt_days,opt_domain) {
	// FF can import weird, broken cookies from IE which will then appear as duplicate cookies.
	// To work around this problem, we explicitly erase cookies.  Our erase function removes
	// any random IE cookies that might be lurking around.
	eraseCookie(name);
	createCookie_(name,value,opt_days,opt_domain);
}

/** @private */
function createCookie_(name,value,opt_days,opt_domain) {
	if (opt_days) {
		var date = new Date();
		date.setTime(date.getTime()+(opt_days*24*60*60*1000));
		var expires = "; expires="+date.toGMTString();
	}
	else var expires = "";
	document.cookie = name+"="+value+expires+"; path=/" + (opt_domain ? ";domain=" + opt_domain : "");
}

/** @export */
function readCookie(name) {
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}

/** @export */
function eraseCookie(name) {
	createCookie_(name,"",-1);
	createCookie_(name,"",-1,"." + document.domain);
}

/** @export */
function cookiesEnabled() {
	var strCookie = (new Date()).getTime().toString();
	createCookie( "cookieCheck", strCookie, 1 );
	if (readCookie("cookieCheck") != strCookie)
		return false;
	return true;
}

/** @export */
function tokenCreate(opt_strLastUser) {
	var aToken = [];
	var strUser = opt_strLastUser ? opt_strLastUser : readCookie('lastuser');
	var strPartner = readCookie('partner');
	aToken[0] = ((new Date()).getTime()).toString();		// timestamp
	aToken[1] = Math.floor(Math.random()*100);			// pool
	if (!strUser) aToken[2] = 'A';						// class anon
	else aToken[2] = ((strUser.indexOf(':G') == -1) ? 'R' : 'G'); // class reg/prem or guest
	aToken[3] = strPartner && strPartner.length == 1 ? strPartner : "0";
	aToken[4] = "1";								// access
	return aToken;
}

/** @private */
var storedToken_ = null;

/** @export */
function tokenGet() {
	if (null != storedToken_) return storedToken_;
	var args = ExtractArgs();
	var strToken = null;
	if ("atkn" in args) {
		strToken = args['atkn'];
	} else {
		strToken = readCookie('atkn');
	}
	if (!strToken) return tokenCreate();
	var aToken = strToken.split(".");	
	var aTokenNew = tokenCreate();
	if (aToken.length != 5) return aTokenNew;
	if ((new Date()).getTime() - aToken[0] > 1000 * 3600 * 3) return aTokenNew;	// 3 hour tokens

	// always use the most recent value for our access pool & partner
	if (aToken[2] < aTokenNew[2])
		aToken[2] = aTokenNew[2];
	if (aTokenNew[3] == "1")
		aToken[3] = "1";
	
	return aToken;
}

/** @export */
function tokenSet(aToken, fAccess) {
	aToken[0] = ((new Date()).getTime()).toString();		// timestamp
	aToken[4] = fAccess ? "1" : "0"					// access
	createCookie('atkn', tokenToString(aToken));
	storedToken_ = aToken;
}

/** @export */
function tokenToString(aToken) {
	return aToken.join('.');
}

/** @export */
function tokenCheck(aToken, fPartner) {
	if (!oPicnikState.fAllAccess) return false;
	var nAccess = 0;
	if (aToken[2] == 'A') nAccess = oPicnikState.nAnon;
	else if (aToken[2] == 'G') nAccess = oPicnikState.nGuest;
	else if (aToken[2] == 'R') nAccess = oPicnikState.nReg;
	if (aToken[3] == "1" && fPartner) nAccess = oPicnikState.nPartner;
	if (aToken[1] <= nAccess) return true;
	return false;
}
