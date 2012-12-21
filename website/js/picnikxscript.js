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
// PicnikXScript -- a class for externally scripting the Picnik client
// 2008-11-10 STL

var PicnikXScript = {

	FrameName: "picnik",
	PicnikCommHost: "http://www.mywebsite.com/",
	PicnikCommPath: "picnikcomm.html",
	
	_setFrameSource: function(ifrmIn, strUrl) {
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
		ifrmIn.location = strUrl;
	},

	_findFrame: function( strName ) {
		var frameParent = window;
		var frame = frameParent.frames[strName];
		while (!frame && frameParent.parent != frameParent) {
			// walk up the frame stack, looking for the given _frame name
			frameParent = frameParent.parent;
			frame = frameParent.frames[strName];
		}
		return frame;
	},
	
	_encodeArgs: function( args ) {
		var result = "";
		for (var key in args) {
			result += "&" + key + "=" + escape(args[key]);
		}
		return result;
	},
	
	_callPicnik: function( func, args) {
		var frm = PicnikXScript._findFrame("picnikcomm");
		if (frm) {
			var url = PicnikXScript.PicnikCommHost + PicnikXScript.PicnikCommPath + "#_frame=" + PicnikXScript.FrameName;
			url  += "&_function=" + func;
			if (args) url += PicnikXScript._encodeArgs(args);
			PicnikXScript._setFrameSource( frm, url );	
		}
	},

	//
	// The public PicnikScript API interface
	//
	ShowAlternate: function(url) {
		PicnikXScript._callPicnik("ShowAlternate", {url:url});
	},
	
	HideAlternate: function() {
		PicnikXScript._callPicnik("HideAlternate");
	},

	CloseDocument: function() {
		PicnikXScript._callPicnik("CloseDocument");
	},

	LoadDocument: function(oArgs) {
		PicnikXScript._callPicnik("LoadDocument", oArgs);
	}
}

document.write('<iframe id="picnikcomm" name="picnikcomm" name="hiddenIFrame" src="about:blank" style="width:0px;height:0px" frameborder="0"></iframe>');
