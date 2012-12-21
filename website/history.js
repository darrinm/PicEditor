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
// $Revision: 1.49 $
// Vars
Vars = function(qStr) {
	this.numVars = 0;
	if(qStr != null) {
		var nameValue, name;
		var pairs = qStr.split('&');
		var pairLen = pairs.length;
		for(var i = 0; i < pairLen; i++) {
			var pair = pairs[i];
			if( (pair.indexOf('=')!= -1) && (pair.length > 3) ) {
				var nameValue = pair.split('=');
				var name = nameValue[0];
				var value = nameValue[1];
				if(this[name] == null && name.length > 0 && value.length > 0) {
					this[name] = value;
					this.numVars++;
				}
			}
		}
	}
}
Vars.prototype.toString = function(pre) {
	var result = '';
	if(pre == null) { pre = ''; }
	for(var i in this) {
		if(this[i] != null && typeof(this[i]) != 'object' && typeof(this[i]) != 'function' && i != 'numVars') {
			result += pre + i + '=' + this[i] + '&';
		}
	}
	if(result.length > 0) result = result.substr(0, result.length-1);
	return result;
}
function getSearch(wRef) {
	var searchStr = '';
	if(wRef.location.search.length > 1) {
		searchStr = new String(wRef.location.search);
		searchStr = searchStr.substring(1, searchStr.length);
	}
	return searchStr;
}
var lc_id = Math.floor(Math.random() * 100000).toString(16);
if (this != top)
{
	top.Vars = Vars;
	top.getSearch = getSearch;
	top.lc_id = lc_id;
}
