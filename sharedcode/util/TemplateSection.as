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
	import flash.net.ObjectEncoding;
	import flash.utils.ByteArray;

	[RemoteClass]
	public class TemplateSection
	{
		[Bindable] public var premium:Boolean = false;
		[Bindable] public var expanded:Boolean = true;
		[Bindable] public var title:String = "";
		[Bindable] public var hidden:Boolean = false;
		
		[Bindable] public var children:Array = [];
		
		[Bindable] public var initialXML:XML;
		
		public function TemplateSection(xml:XML=null)
		{
			super();
			if (xml != null) {
				InitFromXml(xml);
			}
		}

		public function get length(): Number {
			return children.length;
		}

		private function InitFromXml(xmlSection:XML): void {
			initialXML = xmlSection;
			
			if (xmlSection.hasOwnProperty("@premium")) premium = xmlSection.@premium == "true";
			if (xmlSection.hasOwnProperty("@expanded")) expanded = xmlSection.@expanded == "true";
			if (xmlSection.hasOwnProperty("@hidden")) hidden = xmlSection.@hidden == "true";
			title = xmlSection.@title;
		
			for each (var xmlGroup:XML in xmlSection.TemplateGroup) {
				children.push(new TemplateGroup(xmlGroup));
			}
		}
		
		public function get title1(): String {
			return title;
		}
		
		public function get title2(): String {
			return "title 2";
		}
	}
}