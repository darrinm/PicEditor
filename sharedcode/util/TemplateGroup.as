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
	import mx.collections.ArrayCollection;

	[RemoteClass]
	public class TemplateGroup
	{
		[Bindable] public var premium:Boolean = false;
		[Bindable] public var title:String = "";
		[Bindable] public var icon:String = "";
		[Bindable] public var id:String = "";
		
			// Attribution (for the info window)
		[Bindable] public var by:String = "";
		[Bindable] public var attribIcon:String = "";
		[Bindable] public var attribUrl:String = "";
		[Bindable] public var groupDesc:String = "";
		[Bindable] public var isNew:Boolean = false;
		[Bindable] public var attribLinkEntity:String = "";
		[Bindable] public var defaultToHighQuality:Boolean = false;

		[Bindable] public var children:Array = [];
		
		public function TemplateGroup(xmlGroup:XML=null)
		{
			super();
			if (xmlGroup != null) InitFromXml(xmlGroup);
		}
		
		[Bindable]
		public function set label(str:String): void {
			title = str;
		}
		public function get label(): String {
			return title + " [" + id + "]";
		}
		
		public function get length(): Number {
			return children.length;
		}
		
		private function InitFromXml(xmlGroup:XML): void {
			if (xmlGroup.hasOwnProperty("@premium")) premium = xmlGroup.@premium == "true";
			title = xmlGroup.@title;
			id = xmlGroup.@id;

			if (xmlGroup.hasOwnProperty("@isNew")) isNew = xmlGroup.@isNew == "true";

			icon = "/graphics/fancyCollageGroups/";
			if (xmlGroup.hasOwnProperty('@icon'))
				icon += xmlGroup.@icon;
			else
				icon += id + ".jpg";
			
			icon = PicnikBase.StaticUrl(icon);
			
			// Attribution (for the info window)
			if (!xmlGroup.hasOwnProperty('@by'))
				by = "Picnik";
			else
				by = xmlGroup.@by;
				
			if (xmlGroup.hasOwnProperty('@attribIcon'))
			 	attribIcon = PicnikBase.StaticUrl("../graphics/thirdpartylogos/attributionbadges/" + xmlGroup.@attribIcon);
			
			attribUrl = xmlGroup.@attribUrl;
			if (xmlGroup.hasOwnProperty('@attribLinkEntity'))
				attribLinkEntity = xmlGroup.@attribLinkEntity;
			else
				attribLinkEntity = by;
			
			if (xmlGroup.hasOwnProperty('@defaultToHighQuality'))
				defaultToHighQuality = xmlGroup.@defaultToHighQuality;
			else
				defaultToHighQuality = false;
			
			groupDesc = xmlGroup.@groupDesc;
			
		}
	}
}