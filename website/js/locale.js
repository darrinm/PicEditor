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
/*
 * This function parses ampersand-separated name=value argument pairs from
 * the query string of the URL. The name/value pairs are returned as members
 * of an Object instance.
 *
 * Based on http://www.oreilly.com/catalog/jscript3/chapter/ch13.html
 */
function ExtractArgs() {
	var query = location.search.substring(1);  // Get query string.
	return SplitQueryString( query );
}

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
function eraseCookie(name) {
	_createCookie(name,"",-1);
	_createCookie(name,"",-1,"." + document.domain);
}

function createCookie(name,value,days,domain) {
	// FF can import weird, broken cookies from IE which will then appear as duplicate cookies.
	// To work around this problem, we explicitly erase cookies.  Our erase function removes
	// any random IE cookies that might be lurking around.
	eraseCookie(name);
	_createCookie(name,value,days,domain);
}

function _createCookie(name,value,days,domain) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires = "; expires="+date.toGMTString();
	}
	else var expires = "";
	document.cookie = name+"="+value+expires+"; path=/" + (domain ? ";domain=" + domain : "");
}

function updateLocale() {
	var args = ExtractArgs();
	if ("locale" in args) {
		createCookie('locale', args['locale'], 999);
	}
}


