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
// javascript email obfuscation script

// Email obfuscator script 2.1 by Tim Williams, University of Arizona
// Random encryption key feature by Andrew Moulden, Site Engineering Ltd
// This code is freeware provided these four comment lines remain intact
// A wizard to generate this code is at http://www.jottings.com/obfuscator/
function emailObf(linkText) {
	coded = "umbL9uL@XJLbJx.umc"
	key = "6Vx2UTWpqutNf9bDyowjYH1Ce57PLhAKX4Omiv8QMlgEGzksSRIrdcJ3ZanB0F"
	shift=coded.length
	link=""
	for (i=0; i<coded.length; i++) {
		if (key.indexOf(coded.charAt(i))==-1) {
			ltr = coded.charAt(i)
			link += (ltr)
		}
		else {    
			ltr = (key.indexOf(coded.charAt(i))-shift+key.length) % key.length
			link += (key.charAt(ltr))
		}
	}
	document.write("<a href='mailto:"+link+"'>"+linkText+"<\/a>")
}