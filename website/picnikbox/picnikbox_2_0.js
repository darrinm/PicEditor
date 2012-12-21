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
// picnikbox v2.0
// Inspired by lightbox implementation by Chris Campbell (http://particaltree.com)
// Chris' version inspired by the lightbox implementation found at http://www.huddletogether.com/projects/lightbox/
// /////////////////////////////////////////////////////////////////////////////////////
//
// ALL ABOUT PicnikBox
//
// PicnikBox is a sample Javascript class that you can use to embed Picnik photo editing
// functionality into your website.  It is simple to use: just include the relevant files
// into your application and then add the "pbox" class to each <a> tag.
//
// Version 2.0 adds some new functions:
//
//	- Control the position and framing of the application:
//		PicnikBox.SetPicnikMargin()
//		PicnikBox.SetPicnikMargins()
//		PicnikBox.SetPicnikBorder()
//		PicnikBox.SetPicnikBorders()
//
//	- Control the position and framing of the semi-transparent overlay:
//		PicnikBox.SetOverlayMargin()
//		PicnikBox.SetOverlayMargins()
//		PicnikBox.SetOverlayBorder()
//		PicnikBox.SetOverlayBorders()
//
//	- Receive a callback just before PicnikBox activates the app:
//		PicniBox.SetActivateCallback()
//
//	- Receive a callback just after PicnikBox deactivates the app:
//		PicnikBox.SetDeactivateCallback()
//
//	- Tell PicnikBox to PicnikBox-ify the given <a> tag:
//		PicnikBox.AddLink()
//
// Questions, suggestions, additions? Visit http://www.mywebsite.com/info/api.
//


// /////////////////////////////////////////////////////////////////////////////////////
//
// Global scope helpers swiped from prototype.js (http://www.prototypejs.org) and elsewhere
//
var Class = {
	create: function() {
		return function() {
			this.initialize.apply(this, arguments);
		}
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

Function.prototype.bindAsEventListener = function(object) {
	var __method = this;
	return function(event) {
		return __method.call(object, event || window.event);
	}
}

// /////////////////////////////////////////////////////////////////////////////////////
//
// Browser detect script originally created by Peter Paul Koch at http://www.quirksmode.org/
//
var PBoxDetect = {
	strUserAgent: null,
	strOS: null,
	strBrowser: null,
	strVersion: null,
	strTotal: null,
	strLastCheckItMatch: null,
	nLastCheckItPos: -1,

	GetBrowserInfo: function() {
			this.strUserAgent = navigator.userAgent.toLowerCase();
			if (this.CheckIt('konqueror')) {
				this.strBrowser = "Konqueror";
				this.strOS = "Linux";
			}
			else if (this.CheckIt('safari')) 	this.strBrowser = "Safari";
			else if (this.CheckIt('omniweb')) 	this.strBrowser = "OmniWeb";
			else if (this.CheckIt('opera')) 	this.strBrowser = "Opera";
			else if (this.CheckIt('webtv')) 	this.strBrowser = "WebTV";
			else if (this.CheckIt('icab')) 	this.strBrowser = "iCab";
			else if (this.CheckIt('msie')) 	this.strBrowser = "Internet Explorer";
			else if (this.CheckIt('firefox')) 	this.strBrowser = "Firefox";
			else if (!this.CheckIt('compatible')) {
				this.strBrowser = "Netscape Navigator"
				this.strVersion = this.strUserAgent.charAt(8);
			}
			else this.strBrowser = "An unknown browser";

			if (!this.strVersion) this.strVersion = this.strUserAgent.charAt(this.nLastCheckItPos + this.strLastCheckItMatch.length);

			if (!this.strOS) {
				if (this.CheckIt('linux')) 	this.strOS = "Linux";
				else if (this.CheckIt('x11'))	this.strOS = "Unix";
				else if (this.CheckIt('mac')) this.strOS = "Mac"
				else if (this.CheckIt('win'))	this.strOS = "Windows"
				else
					this.strOS = "an unknown operating system";
			}
		},

	CheckIt: function(string) {
			this.nLastCheckItPos = this.strUserAgent.indexOf(string) + 1;
			this.strLastCheckItMatch = string;
			return this.nLastCheckItPos;
		}

};

// /////////////////////////////////////////////////////////////////////////////////////
//
// Some helper functions
//
var PBoxHelpers = {
	HasClassName: function(element, className) {
			if (element.className.match(new RegExp("(^|\\s)" + className + "(\\s|$)")))
				return true;
			return false;
		},

	ObserveEvent: function (element, name, observer, useCapture) {
			var element = $(element);
			useCapture = useCapture || false;

			if (element.addEventListener) {
				element.addEventListener(name, observer, useCapture);
			} else if (element.attachEvent) {
				element.attachEvent('on' + name, observer);
			}
		},

	GetViewportSize: function() {
			var size = [0, 0];
			if (typeof window.innerWidth != 'undefined') {
				var elMeasure = $('pbox_measure');
				if (elMeasure && elMeasure.scrollWidth) {
					size = [ elMeasure.scrollWidth, elMeasure.scrollHeight ];
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
		},

	GetStyle: function(el, styleProp) {
			var el = $(el);
			if (!el) return "";

			var style = null;
			if (el.currentStyle) {
				style = el.currentStyle[styleProp];
			} else if (document.defaultView.getComputedStyle) {
				var css = document.defaultView.getComputedStyle(el,null);
				if (css)
					style = css[styleProp];
			} else if (window.getComputedStyle) {
				var css = window.getComputedStyle(el,null);
				if (css)
					style = css.getPropertyValue(styleProp);
			}
			return style;
		},

	// retrieves the numeric value of a given style
	GetPicnikBoxStyleValue: function(strStyle) {
			var strT = this.GetStyle($('pbox_picnik'), strStyle);
			if (strT) {
				//  remove the "px" from the end and convert to an int
				return parseInt(strT.substr(0, strT.length - 2));
			}
			return 0;
		}

}

// /////////////////////////////////////////////////////////////////////////////////////
//
// PicnikBoxLink: one of these is created for every Picnik'd link in your document
//
var PBoxLink = Class.create();
PBoxLink.prototype = {
	_yPos: 0,
	_elLink: null,
	initialize: function(ctrl) {
		this._elLink = ctrl;
		PBoxHelpers.ObserveEvent(this._elLink, 'click', this.activate.bindAsEventListener(this), false);
		this._elLink.onclick = function() { return false; };
	},

	// Turn everything on - mainly the IE fixes
	activate: function() {
		if (PBoxDetect.strBrowser == 'Internet Explorer') {
			this.getScroll();
			this.prepareIE('100%', 'hidden');
			this.setScroll(0, 0);
			this.hideSelects('hidden');
		}
		PicnikBox.SetActiveLink( this );
		this.displayPicnikbox("block");
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

	// returns the link element we're wrapped around
	getLinkElement: function() {
			return this._elLink;
		},

	// Taken from lightbox implementation found at http://www.huddletogether.com/projects/lightbox/
	getScroll: function() {
		if (self.pageYOffset) {
			this._yPos = self.pageYOffset;
		} else if (document.documentElement && document.documentElement.scrollTop) {
			this._yPos = document.documentElement.scrollTop;
		} else if (document.body) {
			this._yPos = document.body.scrollTop;
		}
	},

	setScroll: function(x, y) {
		window.scrollTo(x, y);
	},

	displayPicnikbox: function(display) {
		$('pbox_overlay').style.display = display;
		$('pbox_picnik').style.display = display;

		// Write an iframe to house Picnik
		if (display != 'none') {
			PicnikBox.OnResize();
			$('pbox_picnik').innerHTML = "<iframe id='pbox_iframe' frameborder='0' scrolling='no' src='" + this._elLink.href + "'></iframe>";
		} else {
			$('pbox_picnik').innerHTML = '';
		}
	},

	// Remove the picnikbox
	deactivate: function() {
		if (PBoxDetect.strBrowser == "Internet Explorer") {
			this.prepareIE("auto", "auto");
			this.hideSelects("visible");
			this.setScroll(0, this._yPos);
		}
		this.displayPicnikbox("none");
		PicnikBox.SetActiveLink( null );
	}
}

// /////////////////////////////////////////////////////////////////////////////////////
//
// PicnikBox: the uber class for controlling picnik-in-a-box display and interactions with the hosting code
//
var PicnikBox = {
	_obActivePBLink: null,
	_obPBLinks: {},

	_fExpanded: false,
	_obNonExpandedStyle: {},

	_fnActivate: null,
	_fnDeactivate: null,

	_obNoBorders: { top: 0, left: 0, bottom: 0, right: 0, style: "none", color: "#ccc" },
	_obNoMargins: { top: 0, left: 0, bottom: 0, right: 0 },

	_obPicnikMargins: { top: 20, left: 20, bottom: 20, right: 20 },
	_obPicnikBorders: { top: 1, left: 1, bottom: 1, right: 1, style: "solid", color: "#ccc" },
	_obOverlayMargins: { top: 0, left: 0, bottom: 0, right: 0 },
	_obOverlayBorders: { top: 0, left: 0, bottom: 0, right: 0, style: "solid", color: "#ccc" },

	SetPicnikMargin: function( size ) {
			PicnikBox.SetPicnikMargins( size, size, size, size );
		},

	SetPicnikMargins: function( top, right, bottom, left ) {
			PicnikBox._obPicnikMargins.top = top;
			PicnikBox._obPicnikMargins.left = left;
			PicnikBox._obPicnikMargins.bottom = bottom;
			PicnikBox._obPicnikMargins.right = right;
		},

	SetOverlayMargin: function( size ) {
			PicnikBox.SetOverlayMargins( size, size, size, size );
		},

	SetOverlayMargins: function( top, right, bottom, left ) {
			PicnikBox._obOverlayMargins.top = top;
			PicnikBox._obOverlayMargins.left = left;
			PicnikBox._obOverlayMargins.bottom = bottom;
			PicnikBox._obOverlayMargins.right = right;
		},

	SetPicnikBorder: function( size, style, color ) {
			PicnikBox.SetPicnikBorders( size, size, size, size, style, color );
		},

	SetPicnikBorders: function( top, right, bottom, left, style, color ) {
			PicnikBox._obPicnikBorders.top = top;
			PicnikBox._obPicnikBorders.left = left;
			PicnikBox._obPicnikBorders.bottom = bottom;
			PicnikBox._obPicnikBorders.right = right;
			PicnikBox._obPicnikBorders.style = style || "solid";
			PicnikBox._obPicnikBorders.color = color || "#ccc";
		},

	SetOverlayBorder: function( size, style, color ) {
			PicnikBox.SetOverlayBorders( size, size, size, size, style, color );
		},

	SetOverlayBorders: function( top, right, bottom, left, style, color ) {
			PicnikBox._obOverlayBorders.top = top;
			PicnikBox._obOverlayBorders.left = left;
			PicnikBox._obOverlayBorders.bottom = bottom;
			PicnikBox._obOverlayBorders.right = right;
			PicnikBox._obOverlayBorders.style = style || "solid";
			PicnikBox._obOverlayBorders.color = color || "#ccc";
		},

	SetActivateCallback: function( fnActivate ) {
			PicnikBox._fnActivate = fnActivate;
		},

	SetDeactivateCallback: function( fnDeactivate ) {
			PicnikBox._fnDeactivate = fnDeactivate;
		},

	SetActiveLink: function( link ) {
			if (link && PicnikBox._fnActivate) {
				PicnikBox._fnActivate( link.getLinkElement() );
			} else if (!link && PicnikBox._obActivePBLink && PicnikBox._fnDeactivate) {
				PicnikBox._fnDeactivate( PicnikBox._obActivePBLink.getLinkElement() );
			}
			PicnikBox._obActivePBLink = link;
		},

	OnLoad: function() {
		// make all links that need to trigger a picnikbox active
		PBoxDetect.GetBrowserInfo();
		PicnikBox.AddPicnikBoxMarkup();
		var links = document.getElementsByClassName('pbox');
		for (i = 0; i < links.length; i++)
			PicnikBox.AddLink( links[i] );
	},

	AddLink: function( elLink ) {
			var valid = new PBoxLink(elLink);
	},

	SetStyles: function() {
		var pbox = $('pbox_picnik');
		var iframe = $('pbox_iframe');
		var overlay = $('pbox_overlay');

		var obPicnikBorders= !PicnikBox._fExpanded ? PicnikBox._obPicnikBorders : PicnikBox._obNoBorders;
		var obPicnikMargins = !PicnikBox._fExpanded ? PicnikBox._obPicnikMargins : PicnikBox._obNoMargins;
		var obOverlayBorders = !PicnikBox._fExpanded ? PicnikBox._obOverlayBorders : PicnikBox._obNoBorders;
		var obOverlayMargins = !PicnikBox._fExpanded ? PicnikBox._obOverlayMargins : PicnikBox._obNoMargins;

		pbox.style['borderStyle'] = obPicnikBorders.style;
		pbox.style['borderColor'] = obPicnikBorders.color;
		pbox.style['borderTopWidth'] = obPicnikBorders.top + "px";
		pbox.style['borderLeftWidth'] = obPicnikBorders.left + "px";
		pbox.style['borderBottomWidth'] = obPicnikBorders.bottom + "px";
		pbox.style['borderRightWidth'] = obPicnikBorders.right + "px";

		pbox.style['marginTop'] = obPicnikMargins.top + "px";
		pbox.style['marginLeft'] = obPicnikMargins.left + "px";
		pbox.style['marginBottom'] = obPicnikMargins.bottom + "px";
		pbox.style['marginRight'] = obPicnikMargins.right + "px";

		overlay.style['borderStyle'] = obOverlayBorders.style;
		overlay.style['borderColor'] = obOverlayBorders.color;
		overlay.style['borderTopWidth'] = obOverlayBorders.top + "px";
		overlay.style['borderLeftWidth'] = obOverlayBorders.left + "px";
		overlay.style['borderBottomWidth'] = obOverlayBorders.bottom + "px";
		overlay.style['borderRightWidth'] = obOverlayBorders.right + "px";

		overlay.style['marginTop'] = obOverlayMargins.top + "px";
		overlay.style['marginLeft'] = obOverlayMargins.left + "px";
		overlay.style['marginBottom'] = obOverlayMargins.bottom + "px";
		overlay.style['marginRight'] = obOverlayMargins.right + "px";

		overlay.style.zIndex = "9997";
		if (PBoxDetect.strBrowser == "Firefox") {
			// firefox can't handle flash and opacity styles at the same time
			if (!PBoxHelpers.HasClassName( overlay, "pbox_UsePNGForBackground" ))
				overlay.className += " pbox_UsePNGForBackground";
		} else {
			if (!PBoxHelpers.HasClassName( overlay, "pbox_UseOpacityForBackground" ))
				overlay.className += " pbox_UseOpacityForBackground";
		}

		pbox.style.zIndex = "9998";
		if (iframe) {
			iframe.style.zIndex = "9999";
		}
	},

	OnResize: function() {
			// make sure all our styles are set correctly
			PicnikBox.SetStyles();

			// calculate the size based on our borders and all that
			var size = PBoxHelpers.GetViewportSize();

			var obPicnikBorders= !PicnikBox._fExpanded ? PicnikBox._obPicnikBorders : PicnikBox._obNoBorders;
			var obPicnikMargins = !PicnikBox._fExpanded ? PicnikBox._obPicnikMargins : PicnikBox._obNoMargins;
			var obOverlayBorders = !PicnikBox._fExpanded ? PicnikBox._obOverlayBorders : PicnikBox._obNoBorders;
			var obOverlayMargins = !PicnikBox._fExpanded ? PicnikBox._obOverlayMargins : PicnikBox._obNoMargins;

			var cxPicnikBorder =obPicnikBorders.left + obPicnikBorders.right;
			var cyPicnikBorder =obPicnikBorders.top + obPicnikBorders.bottom;
			var cxPicnikMargin = obPicnikMargins.left + obPicnikMargins.right;
			var cyPicnikMargin = obPicnikMargins.top + obPicnikMargins.bottom;
			var cxOverlayBorder =obOverlayBorders.left + obOverlayBorders.right;
			var cyOverlayBorder =obOverlayBorders.top + obOverlayBorders.bottom;
			var cxOverlayMargin = obOverlayMargins.left + obOverlayMargins.right;
			var cyOverlayMargin = obOverlayMargins.top + obOverlayMargins.bottom;

			var overlay = $('pbox_overlay');
			if (overlay) {
				var cxOverlay = size[0] - (cxOverlayMargin + cxOverlayBorder);
				var cyOverlay = size[1] - (cyOverlayMargin + cyOverlayBorder);
				overlay.style.width = cxOverlay + 'px';
				overlay.style.height = cyOverlay + 'px';
			}

			var pbox = $('pbox_picnik');
			if (pbox) {
				var cxPBox = cxOverlay - (cxPicnikMargin + cxPicnikBorder);
				var cyPBox = cyOverlay - (cyPicnikMargin + cyPicnikBorder);
				pbox.style.width = cxPBox + 'px';
				pbox.style.height = cyPBox + 'px';
			}
		},

	OnPicnikClose: function() {
			if (PicnikBox._obActivePBLink)
				PicnikBox._obActivePBLink.deactivate();
		},

	OnPicnikExpand: function(fExpand) {
			if (PicnikBox._fExpanded != fExpand) {
				PicnikBox._fExpanded = fExpand;
				PicnikBox.OnResize();
			}
		},

	AddPicnikBoxMarkup: function() {
		// Add in markup necessary to make this work. Basically three divs:
		//	1. pbox_measure lets us know how big the viewable area is
		// 	2. pbox_overlay holds the shadow
		// 	3. pbox_picnik holds the picnik iframe & app

		var elBody = document.getElementsByTagName('body')[0];

		// pbox_measure is used to figure out the usable size of the window
		var elMeasure = document.createElement('div');
		elMeasure.id = 'pbox_measure';
		elMeasure.style.width = "100%";
		elMeasure.style.height = "100%";
		elMeasure.style.position = "fixed";
		elMeasure.style.left = "0";
		elMeasure.style.top = "0";
		elMeasure.style.visibility = "hidden";
		elMeasure.style.zIndex = "-1";
		elBody.appendChild(elMeasure);

		// pbox_overlay gives us a dark gray border around the app
		var elOverlay = document.createElement('div');
		elOverlay.id = 'pbox_overlay';
		elBody.appendChild(elOverlay);

		// pbox_picnik contains the app
		var elPicnikBox = document.createElement('div');
		elPicnikBox.id = 'pbox_picnik';
		elBody.appendChild(elPicnikBox);
	}
}

// /////////////////////////////////////////////////////////////////////////////////////
//
// Backwards compatibility
//
function onPicnikClose() { PicnikBox.OnPicnikClose() }
function onPicnikExpand( fExpand ) { PicnikBox.OnPicnikExpand( fExpand ) }

// /////////////////////////////////////////////////////////////////////////////////////
//
// Global init
//
PBoxHelpers.ObserveEvent(window, 'load', PicnikBox.OnLoad, false);
PBoxHelpers.ObserveEvent(window, 'resize', PicnikBox.OnResize, false);

