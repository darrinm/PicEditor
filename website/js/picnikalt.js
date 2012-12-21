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
// PicnikAlt -- a utility class for managing content that will be in the Picnik Alternate frame
// This class has a dependency on picnikxscript.js.  That class must be included before this one.
// 2008-11-07 STL

var PicnikAlt = {
	AppUrl: "/app",
	
	IsInAlternateFrame: function() {
		if (window.parent && PicnikXScript._findFrame("ifrmPicnikAlt"))
			return true;
		return false;
	},

	//
	// The public PicnikScript API interface
	//
	ShowAlternate: function(url) {
		if (PicnikAlt.IsInAlternateFrame()) {
			PicnikXScript.ShowAlternate(url);
		} else {
			window.location = url;
		}
	},
	
	HideAlternate: function() {
		if (PicnikAlt.IsInAlternateFrame()) {
			PicnikXScript.HideAlternate();
		} else {
			window.location = PicnikAlt.AppUrl;
		}
	},

	CloseDocument: function() {
		if (PicnikAlt.IsInAlternateFrame()) {
			PicnikXScript.CloseDocument();
		}
	},

	LoadDocument: function(oArgs) {
		if (PicnikAlt.IsInAlternateFrame()) {
			PicnikXScript.LoadDocument(oArgs);
		} else {
			window.location = "/service/?" + PicnikXScript._encodeArgs(oArgs);
		}
	}
};

