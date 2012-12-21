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

// PicnikScript -- a class for scripting the Picnik client from javascript
// 2008-11-07 STL

function $() {
	var els = new Array();

	for (var i = 0; i < arguments.length; i++) {
		var el = arguments[i];
		if (typeof el == 'string')
			el = document.getElementById(el);
		if (arguments.length == 1)
			return el;

		els.push(el);
	}
	return els;
};

/** @export */
var PicnikScript = {
	isIE_: function() {
		return PicnikScript.getBrowser_() == "IE";
	},
		
	getBrowser_: function() {
		var userAgent = navigator.userAgent.toLowerCase();
		if (/firefox/.test(userAgent)) return "FF";
		if (/opera/.test( userAgent )) return "OP";
		if (/msie/.test(userAgent)) return "IE";
		if (/chrome/.test(userAgent)) return "CH";
		if (/webkit/.test(userAgent)) return "WK";
		return "";
	}
};

//
// The public PicnikScript API interface
//
PicnikScript['LoadDocument'] = function(oArgs) {
		if ($('picnik') && 'LoadDocument' in $('picnik')) {
			$('picnik').LoadDocument(oArgs);
		}
	};

PicnikScript['CloseDocument'] = function() {
		if ($('picnik') && 'CloseDocument' in $('picnik')) {
			$('picnik').CloseDocument();
		}
	};

PicnikScript['ShowAlternate'] = function( oArgs ) {
		$('ifrmPicnikAlt').style.display= "block";			
		$('ifrmPicnikAlt').width= "100%";			
		$('ifrmPicnikAlt').height= "100%";			
		$('ifrmPicnikAlt').src = oArgs['url'];
		// we use the "visibility" to style to avoid flash reloads in FF.
		// but don't muck with visibility in IE or we'll lose all actionscript callbacks
		if (!PicnikScript.isIE_()) {
			$('flashcontent').style.visibility= "hidden";
			$('ifrmLeaderboard').style.visibility= "hidden";
		}
		if ($('picnik')) $('picnik').OnShowAlternate(oArgs);
	};

PicnikScript['HideAlternate'] = function( oArgs ) {
		// switch back to the main Picnik UI
		$('flashcontent').style.visibility= "visible";
		$('ifrmLeaderboard').style.visibility= "visible";
		$('ifrmPicnikAlt').style.display= "none";
		$('ifrmPicnikAlt').width= "0px";			
		$('ifrmPicnikAlt').height= "0px";			
		$('ifrmPicnikAlt').src = "about:blank";
		if ($('picnik')) $('picnik').OnHideAlternate(oArgs);
	};

PicnikScript['Remote'] = function (oArgs) {
		// handle a remote request to do something fun
		var function_ = oArgs['_function'];
		if (!function_ in PicnikScript)
			return;
		PicnikScript[function_](oArgs);
	};

