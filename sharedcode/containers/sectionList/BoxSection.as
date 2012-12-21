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
package containers.sectionList
{
	import mx.binding.utils.BindingUtils;
	import mx.containers.VBox;
	import mx.core.ScrollPolicy;

// <?xml version="1.0" encoding="utf-8"?>
// <BoxSectionRenderer xmlns="containers.sectionList.*" xmlns:mx="http://www.adobe.com/2006/mxml"
// 		expanded="true" width="100%" xmlns:controls="controls.*" verticalGap="0">
// 	<SectionHeader data="{data}" id="_hdr" renderer="{this}" expanded="{expanded}" visible="{showHeader}" includeInLayout="{showHeader}"/>
// 	<mx:VBox id="_bxChildItems" height="{childHeight}" horizontalScrollPolicy="off" verticalScrollPolicy="off" verticalGap="0" width="100%"/>
// </BoxSectionRenderer>

	public class BoxSection extends BoxSectionRenderer
	{
		public function BoxSection()
		{
			expanded = true;
			percentWidth = 100;
			setStyle("verticalGap", "0");

			_bxChildItems = new VBox();
			BindingUtils.bindProperty(_bxChildItems, "height", this, "childHeight");
			_bxChildItems.horizontalScrollPolicy = ScrollPolicy.OFF;
			_bxChildItems.verticalScrollPolicy = ScrollPolicy.OFF;
			_bxChildItems.setStyle("verticalGap", "0");
			_bxChildItems.percentWidth = 100;

			_hdr = new SectionHeader();
			BindingUtils.bindProperty(_hdr, "data", this, "data");
			_hdr.renderer = this;
			BindingUtils.bindProperty(_hdr, "expanded", this, "expanded");
			BindingUtils.bindProperty(_hdr, "visible", this, "showHeader");
			BindingUtils.bindProperty(_hdr, "includeInLayout", this, "showHeader");

			this.addChild(_hdr);
			this.addChild(_bxChildItems);
		}
	}
}
