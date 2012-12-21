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
// ==UserScript==
// @name          Picnik Edit Link
// @description	  This script adds a button to your Flickr Photo page that loads the photo into Picnik.
// @author        Peter Roman
// @version       0.2 (01/28/07)
// @namespace     http://www.mywebsite.com/
// @include       http://flickr.com/photos/*
// @include       http://www.flickr.com/photos/*
// ==/UserScript==

// v0.1 initial release
// v0.2 working towards in-page editing

(function() {

function Main() {
	var links = document.getElementById("button_bar");
	if (!links)
		return;
		
	// images URLs -- images aren't data-ized as FF doesn't like the crazy escaping when attempting to trigger the over/down states
	var strPicnikButtonUpURL = "http://www.mywebsite.com/graphics/gm/picnik_grey.gif";
	var strPicnikButtonOverURL = "http://www.mywebsite.com/graphics/gm/picnik_color.gif";
	var strPicnikButtonDownURL = "http://www.mywebsite.com/graphics/gm/picnik_color_down.gif";		
	
	// Create the 'Edit with Picnik' HTML element
	var imgPicnik = document.createElement("img");
	imgPicnik.src = strPicnikButtonUpURL;
	imgPicnik.title = "Edit this photo with Picnik";
	imgPicnik.alt = "Edit with Picnik";
	imgPicnik.width = 56;
	imgPicnik.height = 24;
	imgPicnik.addEventListener("click", ShowPicnik, true);
	
	imgPicnik.addEventListener("mouseover", function() { imgPicnik.src = strPicnikButtonOverURL; }, true);
	imgPicnik.addEventListener("mouseout", function() { imgPicnik.src = strPicnikButtonUpURL; }, true);
	imgPicnik.addEventListener("mousedown", function() { imgPicnik.src = strPicnikButtonDownURL; }, true);
	imgPicnik.addEventListener("mouseup", function() { imgPicnik.src = strPicnikButtonOverURL; }, true);
	
	// append it at the end of the button_bar list
	links.appendChild(imgPicnik);

	// Create a div to hold the iframe that will contain Picnik
	var divPicnik = document.createElement("div");
	divPicnik.id = "divPicnik";
	divPicnik.style.visibility = "hidden";
	divPicnik.style.position = "absolute";
	divPicnik.style.left = 0;
	divPicnik.style.width = "100%";
	divPicnik.style.top = 100;
	divPicnik.style.height = (window.innerHeight ? window.innerHeight : document.body.clientHeight) - 100 - 22; // HACK: that 22
	
	divPicnik.innerHTML = "<input type='button' name='btnClose' value='Close Picnik'  onClick='document.getElementById(\"divPicnik\").style.visibility=\"hidden\"'/><iframe src=\"about:blank\" id='ifrmPicnik' name='ifrmPicnik' width='100%' height='100%' frameBorder='0'>IFRAME support required</iframe>";
	
	document.body.appendChild(divPicnik);
}

function ShowPicnik() {
	// Picnik's import recognizes Flickr URLs and will automatically grab the original image
	var strPhotoEditURL = "http://www.mywebsite.com/?import=" + escape(window.location.href);
	
	var divPicnik = document.getElementById("divPicnik");
	var ifrmPicnik = document.getElementById("ifrmPicnik");
	if (ifrmPicnik.src != strPhotoEditURL)
		ifrmPicnik.src = strPhotoEditURL;
	divPicnik.style.visibility = "visible";
}

Main();

})();
