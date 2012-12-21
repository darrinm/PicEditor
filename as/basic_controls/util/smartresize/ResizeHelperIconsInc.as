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
// ActionScript include

// it would be nice if iconVisible_X vars could be of type Boolean, but Boolean vars
// don't allow null values, which we want to take advantage of.

public var has_iconVisible_property:Boolean = true;
public var iconVisible_0:String = "true";
public var iconVisible_1:String = null;
public var iconVisible_2:String = null;
public var iconVisible_3:String = null;
public var iconVisible_4:String = null;
public var iconVisible_5:String = null;
public var iconVisible_6:String = null;
public var iconVisible_7:String = null;
public var iconVisible_8:String = null;
public var iconVisible_9:String = null;

private var _clsSavedIcon:Class = null;
private var _strIconVisible:String = "true";

public function set iconVisible(s:String): void {
	if (s != "true" && s != "false")
		return;
	if (s == _strIconVisible)
		return;			// NOP
	if (s == "true") {
		if (_clsSavedIcon != null) {
			this.setStyle("icon", _clsSavedIcon);
			_clsSavedIcon = null;
		}
	} else {
		_clsSavedIcon = this.getStyle("icon");
		this.setStyle("icon", null);
	}
	_strIconVisible = s;
}

public function get iconVisible(): String {
	return _strIconVisible;
}
