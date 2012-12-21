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
var knLargeChange = 50; // Re-check ad sizes if your window size change by more than this amount.

var _fShowAds = true;
var _fFullScreen = false;
var _strAdLocale = "en_US";
var g_GAMAttrs = "";
var g_BTAttrs = "";

function setFrameSource(ifrmIn, strUrl) {
	var strHash = "";
	if (g_GAMAttrs) {
		if (strHash.length > 0) {
			strHash += ".";
		}
		for (var key in g_GAMAttrs) {
			strHash += key + "=" + g_GAMAttrs[key]
 		}
	}
	try {
		// Tricky browser wrangling code to get the iframe document
		var doc = (ifrmIn.contentWindow || ifrmIn.contentDocument);
		if (doc && doc.document) doc = doc.document;
		if (doc) {
			// document.location.replace does not add a history entry
			doc.location.replace(strUrl);
			return;
		}
	} catch( e ) {
	}
	ifrmIn.src = strUrl;
}

function buildAdUrl(strUrl,strPos) {
	return strRoot + "app/"+ g_strLocale + strUrl + "?pos="+strPos+"&rel=" + g_strRelease;
}

function setSocialNetworkUrl(strUrl) {
	if (g_GAMAttrs && ('src' in g_GAMAttrs)) {
		if (g_GAMAttrs['src'] == 'facebook') {
			strUrl += '_fb'
		} else if (g_GAMAttrs['src'] == 'myspace') {
			strUrl += '_ms';
		}
	}
	return strUrl + '.html';
}

/**
 * Originally, this function set ads, and adjusted the green bar. Now it only
 * adjusts the green bar. Function name is legacy.
 */
function SetAdState(aSize) {
	var rectTarget = { top: 0, left: 0, width: aSize[0], height: aSize[1] };
	var divGreenBar = $("#GreenBar");

	if (_fShowAds) {
		divGreenBar.css("display","block");
		rectTarget.height -= divGreenBar.height();
		if (rectTarget.width < 700) {
			$("#GreenBarShare").css("display","none");
		} else {
			$("#GreenBarShare").css("display","block");
		}
		if (rectTarget.width < 300) {
			$("#GreenBarButton").css("display","none");
		} else {
			$("#GreenBarButton").css("display","block");
		}
	} else {
		divGreenBar.css("display","none");
	}
	
	return rectTarget;
}

function getViewportSize() {
	var size = [0, 0];
	if (typeof window.innerWidth != 'undefined') {
		size = [ window.innerWidth, window.innerHeight ];
	} else if (typeof document.documentElement != 'undefined' &&
			typeof document.documentElement.clientWidth != 'undefined' &&
			document.documentElement.clientWidth != 0) {
		size = [ document.documentElement.clientWidth, document.documentElement.clientHeight ];
	} else {
		size = [ document.getElementsByTagName('body')[0].clientWidth,
				document.getElementsByTagName('body')[0].clientHeight ];
	}
	
	return size;
}

function largeChange(anSize1, anSize2) {
	var nChange = Math.max(Math.abs(anSize1[0]-anSize2[0]), Math.abs(anSize1[1]-anSize2[1]));
	return (nChange >= knLargeChange);
}

var _fReadyCalled = false;
function onReady() {
	if (!_fReadyCalled) {
		_fReadyCalled = true;
		onResize();
	}
}

function SetShowAds(fAds) {
	_fShowAds = fAds;
	if (_fReadyCalled) {
		onResize();
	}
}


function onResize() {
	if (_fFullScreen) return true; // Fullscreen does its own size management

	var size = getViewportSize();
	var rectTarget = SetAdState(size);
	
	if (rectTarget != null)
		updateFrames(rectTarget);
		
	// Make sure our leaderboard knows we resized
	return true;
}

function updateFrames(rectTarget) {
	var oFlash = $("#show_holder");
	if (oFlash) {
		oFlash.css( "top", rectTarget.top );
		oFlash.css( "left", rectTarget.left );
		oFlash.css( "height", rectTarget.height );
		oFlash.css( "width", rectTarget.width );
	}
	
	var oPicnik = $("#picnik");
	if (oPicnik) {
		oPicnik.css( "height", rectTarget.height );
		oPicnik.css( "width", rectTarget.width );
	}	

	var oSimple = $("#show_simple");
	if (oSimple) {
		oSimple.css( "height", rectTarget.height );
		oSimple.css( "width", rectTarget.width );
	}	
}

$(document).ready(onReady);
$(window).bind("load",onReady);
$(window).bind("resize",onResize);
