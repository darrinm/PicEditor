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

var g_strSelected = null;
var g_fCaptions = true;
var g_cyImages = 0;
var g_scrollTimer = null;
var g_nCurrentWidth = 0;

function onResize() {
	updateFrames();	
	return true;
}

function initSelected() {
	if (!g_strSelected || g_strSelected.length == 0) {
		aThumbs = $(".slideshow-thumbnails li a");
		if (aThumbs.length)
			g_strSelected = aThumbs[0].href;
	}
	if (!g_strSelected) {
		g_strSelected = window.location.hash;
	}
	g_strSelected = g_strSelected.substring(g_strSelected.indexOf("#")+1);
}	

function onReady() {
	initSelected();
	$(".slideshow-image").bind("load", function(e) {
		$(e.target).css("padding-top", (g_cyImages-$(e.target).height())/2);
	});
	$(".slideshow-thumbnails").css("overflow", "hidden");
	setInterval(checkLayout, 500);	
	updateFrames();
	setDefaultScrollPosition();	
	return true;
}

function checkLayout() {
    if (window.innerWidth != g_nCurrentWidth) {
	g_nCurrentWidth = window.innerWidth;
        document.body.setAttribute("orient", g_nCurrentWidth == 320 ? "profile" : "landscape");
	updateFrames();
    }
}

function updateFrames() {
	var cxShow = $(window).width();
	var cyShow = $(window).height();
	var cyCaption = 	$(".slideshow-captions").outerHeight();
	var cyControls = $('.slideshow-controls').outerHeight();
	var cxScrollButton = $("#ss_th_right").outerWidth();
	var cyScollButton = $("#ss_th_right").outerHeight();
	var cxThumbHolder = cxShow;
	var cxThumbHolderControls = cxScrollButton * 2;
	var cxThumbs = cxThumbHolder - cxThumbHolderControls;
	var cyThumbs = cyShow * 0.1 < 65 ? 65 : Math.ceil(cyShow * 0.1);
	var cxyThumbs = cyThumbs - 8;
	var cxImages = cxShow;
	var cyImages = cyShow - cyThumbs - cyControls - 2;
	var nThumbs = $(".slideshow-thumbnails a").length;

	g_cyImages = cyImages;
	
	$(".slideshow").css("width", cxShow);
	$(".slideshow").css("height", cyShow);

	$(".slideshow-image").css("margin-bottom", cyImages);	
	$(".slideshow-images").css("width", cxImages);
	$(".slideshow-images").css("height", cyImages);
	$(".slideshow-captions").css("top", -1 * (cyImages+cyCaption));
	$(".slideshow-thumbholder").css("width", cxThumbHolder);
	$(".slideshow-thumbholder").css("height", cyThumbs);
	$(".slideshow-thumbnails").css("width", cxThumbs);
	$(".slideshow-thumbnails").css("height", cyThumbs);
	$(".slideshow-thumbnails ul").css("height", cxyThumbs);
	$(".slideshow-thumbnails ul").css("width", nThumbs * (cxyThumbs+7));
	$(".slideshow-thumbnail").css("width", cxyThumbs);
	$(".slideshow-thumbnail").css("height", cxyThumbs);
	$(".slideshow-thumbholder-control").css("margin-top", Math.max(Math.floor((cyThumbs-cyScollButton)/2),0));
	var aEls = $(".slideshow-image");
	for (var i = 0; i < aEls.length; i++) {
		if ( !("complete" in aEls[i]) || aEls[i].complete) {
			var imgHeight = $(aEls[i]).height();
			$(aEls[i]).css("padding-top", Math.max(Math.floor((cyImages-imgHeight)/2),0));
		}
		if ($(aEls[i]).hasClass("sizable-image")) {
			var aSizes = [160,320,640,1280,2800];
			var strSrc = aEls[i].src;
			var nSize = 0;
			var nOldSize = 0;
			for (var j=0; j < aSizes.length;j++) {
				var a = strSrc.lastIndexOf(aSizes[j]);
				var b = strSrc.length - aSizes[j].toString().length;
				if (a == b) {
					nOldSize = parseInt(strSrc.substring(b));
					strSrc = strSrc.substring(0,b);
					break;
				}
			}
			nSize = 2800;
			for (j = 0; j < aSizes.length;j++) {
				if (aSizes[j] >= cxImages && aSizes[j] >= cyImages) {
					nSize = aSizes[j];
					break;
				}
			}
			if (nSize > nOldSize) {
				strSrc += nSize;
				aEls[i].src = strSrc;
			}
		}
	}
	
	var nPos = $(".slideshow-thumbnails ul").css("marginLeft");	
	nPos = parseInt(nPos);
	setScrollPosition(nPos, false);

	initSelected();	
	if (g_strSelected) {
		window.location.hash = g_strSelected + "_";
		window.location.hash = g_strSelected;
	}
	
	// iphone goodies
	setTimeout(function(){window.scrollTo(0, 1);}, 100);	
}

function onThumbClick(strSelected) {
	g_strSelected = strSelected;
}

function toggleCaptions() {
	if (g_fCaptions) {
		g_fCaptions = false;
	} else {
		g_fCaptions = true;
	}
	$(".slideshow-captions").css("opacity", g_fCaptions ? 0.8 : 0 );
}


function setDefaultScrollPosition() {
	setScrollPosition(0, false);
}

function setScrollPosition(nPos, fAnimate){
	if (isNaN(nPos)) nPos = 0;
	
	var elThumbs = $(".slideshow-thumbnails ul");
	var elThumbView= $(".slideshow-thumbnails");
	var nWidth = elThumbs.width();
	var nViewWidth = elThumbView.width()-1;
	var nPosMax = 0;
	var nPosMin = nViewWidth - nWidth - 6;
	if (nWidth < nViewWidth) {
		elThumbs.css("marginLeft", Math.floor((nViewWidth-nWidth)/2));
		$(".slideshow-thumbholder-control").css("opacity","0.2");
	} else {
		if (nPos > nPosMax) {
			nPos = nPosMax;
		} else if (nPos < nPosMin ) {
			nPos = nPosMin;
		}

		if (fAnimate) {
			elThumbs.animate({"marginLeft":nPos},500,"swing");
		} else {
			elThumbs.css("marginLeft", nPos);
		}
		
		if (nPos == nPosMax) {
			$("#ss_th_left").fadeTo(100,0.2);
			$("#ss_th_right").fadeTo(100,1.0);
		} else if (nPos == nPosMin) {
			$("#ss_th_right").fadeTo(100,0.2);
			$("#ss_th_left").fadeTo(100,1.0);
		} else {
			$("#ss_th_right").fadeTo(100,1.0);
			$("#ss_th_left").fadeTo(100,1.0);
		}
	}
}

function scrollToTheRight() {
	var elThumbs = $(".slideshow-thumbnails ul");
	var elThumbView= $(".slideshow-thumbnails");
	var nViewWidth = elThumbView.width();
	var nPos = parseInt(elThumbs.css("marginLeft"));
	setScrollPosition(nPos-nViewWidth,true);
}

function scrollToTheLeft() {
	var elThumbs = $(".slideshow-thumbnails ul");
	var elThumbView= $(".slideshow-thumbnails");
	var nViewWidth = elThumbView.width();
	var nPos = parseInt(elThumbs.css("marginLeft"));
	setScrollPosition(nPos+nViewWidth,true);
}

function toggleCaptions() {
	if (g_fCaptions) {
		g_fCaptions = false;
	} else {
		g_fCaptions = true;
	}
	$(".slideshow-captions").fadeTo(200, g_fCaptions ? 0.8 : 0 );
}

$(document).ready(onReady);
$(window).bind("resize",onResize);
