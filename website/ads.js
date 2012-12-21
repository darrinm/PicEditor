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
 * Picnik ad functions
 */

 /*
 * Design Overview
 *
 * Client calls the following functions:
 * Show ads (...)

 * LoadFullScreen
 * HideFullScreen
 *
 * Javascript is responsible for choosing an ad that will fit
 * Ad size selection occurs only on Show/Load/Refresh
 * The client is responsible for calling refresh every 4 minutes (or whatever)
 */

var _fFullScreen = false;
var _fLeaderboard = false;
var _fCalledBySWF = false;

//// Constants
var knMinPicnikWidth = 640; // Don't show skyscraper if it will make Picnik smaller than this
var knMinPicnikHeight = 340; // Don't show leaderboard if it will make picnik shorter than this
var knLargeChange = 50; // Re-check ad sizes if your window size change by more than this amount.

// Fullscreen
var knFullScreenSwfHeight = 70; // When we show a fullscreen ad, reduce the swf to this height
var knMinWidthForLargeFullscreenAd = 600; // If we less wide than this, show  kstrFullScreenSmall
var kstrFullScreen = '/testads/fullscreen.html';
var kstrFullScreenSmall = '/testads/fbfull.html';

// Leaderboard
var knLargeLeaderboardMinWidth = 728 + 10 + 4; // + 190; // Only show the large leaderboard if we have this much width (leaderboard width + padding left + padding right + upgrade button)
var knLargeLeaderboardHeight = 90 + 7; // ad height + padding
var knSmallLeaderboardHeight = 60 + 7; // ad height + padding
var kstrLargeLeaderboard = '/ad_leader';
var kstrSmallLeaderboard = '/ad_banner';

var kstrLargeUpgradingLeaderboard = '/ads/largeUpgradingLeaderboard.html';
var kstrSmallUpgradingLeaderboard = '/ads/smallUpgradingLeaderboard.html';

var _nTopActual = 0;
var _nWidthActual = 0;
var _nTopTarget = 0;
var _nWidthTarget = 0;
var g_GAMAttrs = "";
var g_BTAttrs = "";	

function setFrameSource(ifrmIn, strUrl) {

	var strHash = "";
	if (g_GAMAttrs) {
		if (strHash.length > 0)
			strHash += ".";
			
		for (var key in g_GAMAttrs) {
			strHash += key + "=" + g_GAMAttrs[key]
 		}	
	}

	//if (strHash.length > 0)
	//	strUrl += "#" + strHash;
		
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

function buildAdUrl(strUrl) {
	return strRoot + "app/"+ strLocaleDir + strUrl + "?rel=" + strRelease;
}

function setSocialNetworkUrl(strUrl)
{
	if (g_GAMAttrs && ('src' in g_GAMAttrs)) {
		if (g_GAMAttrs['src'] == 'facebook') {
			strUrl += '_fb'
		} else if (g_GAMAttrs['src'] == 'myspace') {
			strUrl += '_ms';
		}
	}
	return strUrl + '.html';
}

//// Full screen
function loadFullScreenAd() {
	size = getViewportSize();
	if (size[0] < knMinWidthForLargeFullscreenAd) {
		strSrc = kstrFullScreenSmall;
	} else {
		strSrc = kstrFullScreen;
	}
	setFrameSource(document.getElementById("ifrmFullScreen"), strSrc);
}

function prepareForFullScreenAd() {
	document.getElementById("ifrmLeaderboard").height = 0;

	document.getElementById("picnik").style.height = '100%';
	document.getElementById("picnik").style.width = "100%";
}

function showFullScreenAd() {
	_fFullScreen = true;

	// Hide the other ads
	document.getElementById("ifrmLeaderboard").height = 0;

	document.getElementById("picnik").style.height = knFullScreenSwfHeight;
	document.getElementById("picnik").style.width = "100%";

	document.getElementById("ifrmFullScreen").height = "100%";
}

function hideFullScreenAd() {
	_fFullScreen = false;
	document.getElementById("ifrmFullScreen").height = "0";
	setFrameSource(document.getElementById("ifrmFullScreen"), '');

	// Load new ads
	if (_fLeaderboard) {
		loadLeaderboardAd();
	}
	
	onResize();
}

function SetAdAttrs(GAMAttrs, BTAttrs) {
	g_GAMAttrs = GAMAttrs;
	for (var key in GAMAttrs) {
		try {
			g_GAMAttrs[key.toLowerCase()] = GAMAttrs[key].toLowerCase();
		} catch( e ) {
		//
		}
	}
	
	g_BTAttrs = BTAttrs;	
}

//// Leaderboard
function loadLeaderboardAd() {

	if (roomForLargeLeaderboard()) {
		// 728 x 90 leaderboard
		nAdHeight = knLargeLeaderboardHeight;
		strSrc = buildAdUrl(setSocialNetworkUrl(kstrLargeLeaderboard));
		setFrameSource(document.getElementById("ifrmLeaderboard"), strSrc);
	} else {
		// 468 x 60 banner
		nAdHeight = knSmallLeaderboardHeight;
		strSrc = buildAdUrl(setSocialNetworkUrl(kstrSmallLeaderboard));
		setFrameSource(document.getElementById("ifrmLeaderboard"), strSrc);
	}

	size = getViewportSize();
	if ((size[1] - nAdHeight) < knMinPicnikHeight) {
		// Not enough room to show an ad
		nAdHeight = 0;
		//strSrc = '';
	}

	_fLeaderboard = true;
	
	return nAdHeight;
}

function loadLeaderboardUpgrading() {
	if (roomForLargeLeaderboard()) {
		// 728 x 90 leaderboard
		nAdHeight = knLargeLeaderboardHeight;
		strSrc = kstrLargeUpgradingLeaderboard;
		setFrameSource(document.getElementById("ifrmLeaderboard"), strSrc);
	} else {
		// 468 x 60 banner
		nAdHeight = knSmallLeaderboardHeight;
		strSrc = kstrSmallUpgradingLeaderboard;
		setFrameSource(document.getElementById("ifrmLeaderboard"), strSrc);
	}

	size = getViewportSize();
	if ((size[1] - nAdHeight) < knMinPicnikHeight) {
		// Not enough room to show an ad
		nAdHeight = 0;
		//strSrc = '';
	}


	_fLeaderboard = true;

	return nAdHeight;
}

function roomForLargeLeaderboard() {
	size = getViewportSize();
	if ((size[1] - knLargeLeaderboardHeight) < knMinPicnikHeight)
		return false;
	return size[0] >= knLargeLeaderboardMinWidth;
}

// Sets the target widths and loads the proper source.
function SetAdState(fLeaderboard) {
	if (_fFullScreen) {
		_fLeaderboard = fLeaderboard;
	} else {
		fResize = (fLeaderboard != _fLeaderboard);

		if (!_fLeaderboard && fLeaderboard) {
			_nTopTarget = loadLeaderboardAd();
			fResize = true;
		} else if (!fLeaderboard) {
			_nTopTarget = 0;
		}
		_fLeaderboard = fLeaderboard;
		
		var size = getViewportSize();
		_nWidthTarget = size[0];
	}
	return new Array( _nTopTarget, _nWidthTarget, _nTopActual, _nWidthActual);
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

anPrevSize = [0,0];

function largeChange(anSize1, anSize2) {
	var nChange = Math.max(Math.abs(anSize1[0]-anSize2[0]), Math.abs(anSize1[1]-anSize2[1]));
	return (nChange >= knLargeChange);
}


function onResize() {
	if (_fFullScreen) return; // Fullscreen does it's own size management
	//if (!_fCalledBySWF) return; // Don't init the ads until the swf has called us to set the size

	SetAdState(_fLeaderboard);
	size = getViewportSize();

	if (!_fFullScreen && _fLeaderboard && largeChange(anPrevSize, size)) {
		if (_fLeaderboard) _nTopTarget = loadLeaderboardAd();
		anPrevSize = size;
	}

	_nTopActual = _nTopTarget;
	_nWidthActual = _nWidthTarget;

	updateFrames();
		
	// Make sure our leaderboard knows we resized
	if (_fLeaderboard && document.getElementById("ifrmLeaderboard") && document.getElementById("ifrmLeaderboard").contentWindow &&document.getElementById("ifrmLeaderboard").contentWindow.onResize) {
		document.getElementById("ifrmLeaderboard").contentWindow.onResize();
	}
}

function $() {
  var elements = new Array();

  for (var i = 0; i < arguments.length; i++) {
    var element = arguments[i];
    if (typeof element == 'string')
      element = document.getElementById(element);

    if (arguments.length == 1)
      return element;

    elements.push(element);
  }

  return elements;
}

function observeEvent(element, name, observer, useCapture) {
	var element = $(element);
	useCapture = useCapture || false;
	
	if (element.addEventListener) {
		element.addEventListener(name, observer, useCapture);
	} else if (element.attachEvent) {
		element.attachEvent('on' + name, observer);
	}
}

function upgrade(strSource) {
	var strSource = (strSource == null) ? 'adbanner' : strSource;
	document['picnik'].externalUpgrade(strSource);
}

function updateFrames() {
	var cxPicnik = 0;
	var cyPicnik = 0;
	
	size = getViewportSize();
	if (_nWidthActual > 0) {
		cxPicnik = _nWidthActual;
	} else {
		cxPicnik = '100%';
	}
	
	cxPicnik = '100%';
	
	if (_nTopActual > 0) {
		cyPicnik = size[1] - _nTopActual;
	} else {
		cyPicnik = '100%';
	}

	var newStyle = 'position:absolute;z-index:1;top:' + _nTopActual + ';height:' + cyPicnik + ';width:' + cxPicnik + ';';
	var oFlash = document.getElementById("flashcontent");
	if (oFlash) {
		oFlash.style.top = _nTopActual;
		oFlash.style.height = cyPicnik;
		oFlash.style.width = "100%"; // width undone
		//oFlash.setAttribute('style', newStyle);	undone? why doesn't this work?
	}
	
	newStyle = 'height:' + cyPicnik + ';width:' + cxPicnik + ';';
	var oPicnik = document.getElementById("picnik");
	if (oPicnik) {
		oPicnik.setAttribute('style', newStyle);	
	}
	
	var oLeader = document.getElementById("ifrmLeaderboard");
	if (oLeader) {
		oLeader.style.height = _nTopActual;
	
		// hack: try to force redraw on the leaderboard
		var strT = oLeader.style.display;
		oLeader.style.display = 'none';
		oLeader.style.display = strT;
	}		
}

// top, width
function movePicnik(y, w) {
	_fCalledBySWF = true;
	_nTopActual = y;
	_nWidthActual = w;
	updateFrames();
}

_nWidthActual = getViewportSize()[1];
observeEvent(window, 'resize', onResize, false);
