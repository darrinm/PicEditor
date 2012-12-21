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
package util
{
	import mx.resources.ResourceBundle;
	import mx.utils.StringUtil;
	
	public class FontCategory
	{
		[Bindable] public var category:String = "";
		[Bindable] public var title1:String = "";
		[Bindable] public var title2:String = "";
		[Bindable] public var rendererState:String = "";
		[Bindable] public var sectionBadge:String = "";
		[Bindable] public var expanded:String = "";
		
		public function FontCategory(xml:XML) {
			if (xml.hasOwnProperty('@category') && xml.@category != '') category = xml.@category;
			if (xml.hasOwnProperty('@title1') && xml.@title1 != '') title1 = xml.@title1;
			if (xml.hasOwnProperty('@title2') && xml.@title2 != '') title2 = xml.@title2;
			if (xml.hasOwnProperty('@rendererState') && xml.@rendererState != '') rendererState = xml.@rendererState;
			if (xml.hasOwnProperty('@sectionBadge') && xml.@sectionBadge != '') sectionBadge = xml.@sectionBadge;
			if (xml.hasOwnProperty('@expanded') && xml.@expanded != '') expanded = xml.@expanded;
			
		}
	}
}