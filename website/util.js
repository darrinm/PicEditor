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
 * Picnik utility functions
 */
/** @export */
function enter_key(evt) {
	var keycode;
	if (window.event) keycode = window.event.keyCode;
	else if (evt) keycode = evt.which;
	else return false;
	return (keycode == 13);
}

/** @export */
function module_submit(frm, strModule) {
	frm.action = frm.action + "/" + strModule;
	frm.submit();
}

/** @export */
function module_md5_submit(frm, strModule) {
	md5_form(frm);
	frm.action = frm.action + "/" + strModule;
	frm.submit();
}

/** @export */
function WriteContactUsLink() {
	WriteEmailLink('Contact Us');
}

/** @export */
function WriteEmailLink(strText) {
	// Email obfuscator script 2.1 by Tim Williams, University of Arizona
	// Random encryption key feature by Andrew Moulden, Site Engineering Ltd
	// This code is freeware provided these four comment lines remain intact
	// A wizard to generate this code is at http://www.jottings.com/obfuscator/
	{ var coded = "R0HyYRy@TrRHrL.R0E"
	  var key = "Nb4EvFBo6df3yrXguz7Cke2Mp09xPSZhn5JacWL1AOTDwQGmIVHUlYR8tisKqj"
	  var shift=coded.length
	  var link=""
	  for (var i=0; i<coded.length; i++) {
		if (key.indexOf(coded.charAt(i))==-1) {
		  var ltr = coded.charAt(i)
		  link += (ltr)
		}
		else {    
		  ltr = (key.indexOf(coded.charAt(i))-shift+key.length) % key.length
		  link += (key.charAt(ltr))
		}
	  }
	document.write("<a href='mailto:"+link+"'>" + strText + "<\/a>")
	}
}

//Remove white space from the beginning and end of a string
/** @export */
function trim(str)
{
   return str.replace(/^\s*|\s*$/g,"");
}

/*
 * Helper method for encoding a single field during a form submit
 * Example:
 *   <form onsubmit="return md5_field(this.password)">
 * <input type="password" name="password">
 * etc...
 * Requires md5.js
 */
/** @export */
function md5_field(inp) {
    var elem_clear = inp.form.elements[inp.name + "_clear"]
    var val = trim(elem_clear.value)
	if (val.length > 0) {
		inp.value = hex_md5(val); // This method requires md5.js
        elem_clear.value = inp.value.substr(0,elem_clear.value.length);
	}
	return true;
}

/*
 * Helper method for encoding all "password" fields during a form submit
 * Any field with a name which ends in "password" (e.g. "login_password") will be encoded.
 * Example:
 *   <form onsubmit="return md5_form(this)">
 * <input type="password" name="login_password">
 * <input type="password" name="register_password">
 * etc...
 * Requires md5.js
*/
/** @export */
function md5_form(frm) {
	var elems = frm.elements;
	var str = 'Form : ' + frm.name + '\n';
	var pwFieldName = "password"
	for (var ix=0; ix < elems.length; ix++) {
		var elem = elems[ix];
		if (elem.name.length >= pwFieldName.length && elem.name.substr(elem.name.length - pwFieldName.length).toLowerCase() == "password") {
			md5_field(elem);
		}
	}
}

