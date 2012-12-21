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
// picnikbox
// Based on lightbox implementation by Chris Campbell (http://particaltree.com)
// Chris' version inspired by the lightbox implementation found at http://www.huddletogether.com/projects/lightbox/

/*-----------------------------------------------------------------------------------------------*/

//Browser detect script origionally created by Peter Paul Koch at http://www.quirksmode.org/

var detect = navigator.userAgent.toLowerCase();
var OS,browser,version,total,thestring;

function getBrowserInfo() {
	if (checkIt('konqueror')) {
		browser = "Konqueror";
		OS = "Linux";
	}
	else if (checkIt('safari')) browser 		= "Safari"
	else if (checkIt('omniweb')) browser 	= "OmniWeb"
	else if (checkIt('opera')) browser 		= "Opera"
	else if (checkIt('webtv')) browser 		= "WebTV";
	else if (checkIt('icab')) browser 		= "iCab"
	else if (checkIt('msie')) browser 		= "Internet Explorer"
	else if (checkIt('firefox')) browser 		= "Firefox"
	else if (!checkIt('compatible')) {
		browser = "Netscape Navigator"
		version = detect.charAt(8);
	}
	else browser = "An unknown browser";

	if (!version) version = detect.charAt(place + thestring.length);

	if (!OS) {
		if (checkIt('linux')) OS 		= "Linux";
		else if (checkIt('x11')) OS 	= "Unix";
		else if (checkIt('mac')) OS 	= "Mac"
		else if (checkIt('win')) OS 	= "Windows"
		else OS 								= "an unknown operating system";
	}
}

function checkIt(string) {
	place = detect.indexOf(string) + 1;
	thestring = string;
	return place;
}

/* Helpers swiped from prototype.js (http://www.prototypejs.org) and elsewhere ------------------*/

var Class = {
  create: function() {
    return function() {
      this.initialize.apply(this, arguments);
    }
  }
}

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
}

Function.prototype.bindAsEventListener = function(object) {
  var __method = this;
  return function(event) {
    return __method.call(object, event || window.event);
  }
}

function hasClassName(element, className) {
    if (element.className.match(new RegExp("(^|\\s)" + className + "(\\s|$)")))
        return true;
    return false;
}

document.getElementsByClassName = function(className, parentElement) {
  var elements = new Array();
  var children = ($(parentElement) || document.body).getElementsByTagName('*');
  for (var i = 0; i < children.length; i++) {
    var child = children[i];
    if (child.className.match(new RegExp("(^|\\s)" + className + "(\\s|$)")))
      elements.push(child);
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

function getViewportSize() {
	var size = [0, 0];
	if (typeof window.innerWidth != 'undefined') {
		// Don't trust Firefox
		var ovl = $('overlay');
		if (ovl && ovl.scrollWidth) {
			size = [ ovl.scrollWidth, ovl.scrollHeight ];
		} else {
			size = [ window.innerWidth, window.innerHeight ];
		}
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

// Thanks quirksmode.org
function getStyle(el, styleProp) {
	var x = el;	// document.getElementById(el);
	if (x.currentStyle) {
		var y = x.currentStyle[styleProp];
	} else if (document.defaultView.getComputedStyle) {
		var css = document.defaultView.getComputedStyle(x,null);
		if (css)
//			var y = css.getPropertyValue(styleProp);
			var y = css[styleProp];
	} else if (window.getComputedStyle) {
		var css = window.getComputedStyle(x,null);
		if (css)
			var y = css.getPropertyValue(styleProp);
	}
	return y;
}

function parsePx(strPx) {
	return parseInt(strPx.substr(0, strPx.length - 2));
}

function getPicnikboxStyleValue(strStyle) {
	var strT = getStyle($('picnikbox'), strStyle);
	if (strT)
		return parsePx(strT);
	return 0;
}

/*-----------------------------------------------------------------------------------------------*/

var pbActive = null;
observeEvent(window, 'load', onLoad, false);
observeEvent(window, 'resize', onResize, false);

var picnikbox = Class.create();

picnikbox.prototype = {
	yPos : 0,

	initialize: function(ctrl) {
		this.content = ctrl.href;
		observeEvent(ctrl, 'click', this.activate.bindAsEventListener(this), false);
		ctrl.onclick = function() { return false; };
	},
	
	// Turn everything on - mainly the IE fixes
	activate: function() {
		if (browser == 'Internet Explorer') {
			this.getScroll();
			this.prepareIE('100%', 'hidden');
			this.setScroll(0, 0);
			this.hideSelects('hidden');
		}
		this.displayPicnikbox("block");
		pbActive = this;
	},
	
	// IE requires height to 100% and overflow hidden or else you can scroll down past the picnikbox
	prepareIE: function(height, overflow) {
		bod = document.getElementsByTagName('body')[0];
		bod.style.height = height;
		bod.style.overflow = overflow;
 
		htm = document.getElementsByTagName('html')[0];
		htm.style.height = height;
		htm.style.overflow = overflow;
	},
	
	// In IE, select elements hover on top of the picnikbox
	hideSelects: function(visibility) {
		selects = document.getElementsByTagName('select');
		for(i = 0; i < selects.length; i++) {
			selects[i].style.visibility = visibility;
		}
	},
	
	// Taken from lightbox implementation found at http://www.huddletogether.com/projects/lightbox/
	getScroll: function() {
		if (self.pageYOffset) {
			this.yPos = self.pageYOffset;
		} else if (document.documentElement && document.documentElement.scrollTop) {
			this.yPos = document.documentElement.scrollTop;
		} else if (document.body) {
			this.yPos = document.body.scrollTop;
		}
	},
	
	setScroll: function(x, y) {
		window.scrollTo(x, y);
	},
	
	displayPicnikbox: function(display) {
		$('overlay').style.display = display;
		$('picnikbox').style.display = display;
		
		// Write an iframe to house Picnik
		if (display != 'none') {
			$('picnikbox').innerHTML = "<iframe id='picnikiframe' frameborder='0' scrolling='no' src='" + this.content + "'></iframe>";
			onResize();
		} else {
			$('picnikbox').innerHTML = '';
		}
	},
	
	// Remove the picnikbox
	deactivate: function() {
		if (browser == "Internet Explorer") {
			this.prepareIE("auto", "auto");
			this.hideSelects("visible");
			this.setScroll(0, this.yPos);
		}
		
		this.displayPicnikbox("none");
	}
}

/*-----------------------------------------------------------------------------------------------*/

// onload, make all links that need to trigger a picnikbox active
function onLoad() {
	getBrowserInfo();
	addPicnikboxMarkup();
	var links = document.getElementsByClassName('pbox');
	for (i = 0; i < links.length; i++)
		var valid = new picnikbox(links[i]);
}

function onResize() {
	var cxBorder = getPicnikboxStyleValue('borderLeftWidth');
	cxBorder += getPicnikboxStyleValue('borderRightWidth');
	var cyBorder = getPicnikboxStyleValue('borderTopWidth');;
	cyBorder += getPicnikboxStyleValue('borderBottomWidth');
	
	var size = getViewportSize();
	var pbox = $('picnikbox');
	
	var cxMargin = getPicnikboxStyleValue('marginLeft');
	cxMargin += getPicnikboxStyleValue('marginRight');
	var yTop = getPicnikboxStyleValue('top');
	var cyMarginTop = getPicnikboxStyleValue('marginTop');
	var cyMarginBottom = getPicnikboxStyleValue('marginBottom');
	cyBox = size[1] - yTop - cyMarginTop - cyMarginBottom;
	cxBox = size[0] - cxMargin;

	pbox.style.width = (cxBox - cxBorder) + 'px';
	pbox.style.height = (cyBox - cyBorder) + 'px';

	$('overlay').style.zIndex = "9997";
	if (browser == "Firefox") {
		// firefox can't handle flash and opacity styles at the same time
		if (!hasClassName( $('overlay'), "UsePNGForBackground" ))
			$('overlay').className += " UsePNGForBackground";
	} else {
		if (!hasClassName( $('overlay'), "UseOpacityForBackground" ))
			$('overlay').className += " UseOpacityForBackground";
	}
	
	$('picnikbox').style.zIndex = "9998";
	var ifrm = $('picnikiframe');
	if (ifrm) {
		ifrm.style.height = pbox.style.height;
		ifrm.style.zIndex = "9999";
	}
}

function onPicnikClose() {
	if (pbActive)
		pbActive.deactivate();
}

var fExpanded = false;
var strMarginLeftSav, strMarginRightSav, strMarginTopSav, strMarginBottomSav, strLeftSav, strTopSav;

function onPicnikExpand(fExpand) {
	if (fExpanded != fExpand) {
		var pbox = $('picnikbox');
		if (fExpand) {
			strMarginLeftSav = getStyle(pbox, 'marginLeft');
			strMarginTopSav = getStyle(pbox, 'marginTop');
			strMarginRightSav = getStyle(pbox, 'marginRight');
			strMarginBottomSav = getStyle(pbox, 'marginBottom');
			strLeftSav = getStyle(pbox, 'left');
			strTopSav = getStyle(pbox, 'top');
			
			pbox.style.marginLeft = '0px';
			pbox.style.marginTop = '0px';
			pbox.style.marginRight = '0px';
			pbox.style.marginBottom = '0px';
			pbox.style.left = '0px';
			pbox.style.top = '0px';
		} else {
			pbox.style.marginLeft = strMarginLeftSav;
			pbox.style.marginTop = strMarginTopSav;
			pbox.style.marginRight = strMarginRightSav;
			pbox.style.marginBottom = strMarginBottomSav;
			pbox.style.left = strLeftSav;
			pbox.style.top = strTopSav;
		}
		fExpanded = fExpand;
		onResize();
	}
}

// Add in markup necessary to make this work. Basically two divs:
// Overlay holds the shadow
// Picnikbox is the centered square that the Picnik iframe is put into.
function addPicnikboxMarkup() {
	var bod = document.getElementsByTagName('body')[0];
	var overlay = document.createElement('div');
	overlay.id = 'overlay';
	var pbox = document.createElement('div');
	pbox.id = 'picnikbox';
	bod.appendChild(overlay);
	bod.appendChild(pbox);
}
