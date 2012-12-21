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
	import mx.utils.ObjectProxy;
	
	public class TemplateStructure
	{
		private var _atsect:Array = null;
		private var _atgrps:Array = null;
		
		// Construct the tempalte structure (groups, but no tempaltes) given XML
		// Throws an error if there are problems.
		public function TemplateStructure(xml:XML)
		{
			if (xml == null) throw new Error("null XML");
			
			InitFromXML(xml);
		}
		
		public function get groups():Array {
			return _atgrps;
		}
		
		private function InitFromXML(xml:XML): void {
			_atsect = [];
			_atgrps = [];

			var tsect:TemplateSection;
			var tgrp:TemplateGroup;
			
			for each (var xmlSection:XML in xml.TemplateSection) {
				_atsect.push(new TemplateSection(xmlSection));
			}
			
			// Now populate our group array and group id to group map
			for each (tsect in _atsect) {
				for each (tgrp in tsect.children) {
					_atgrps.push(tgrp)
				}
			}
		}
		
		public function GetStructuredList(adctTemplateProps:Array, fShowHiddenGroups:Boolean): Array {
			var atsect:Array = [];
			var tsect:TemplateSection;
			var tgrp:TemplateGroup;
			var obMapIdToGroup:Object = {};
			
			// First, start with a clone of the structure
			for each (tsect in _atsect) {
				atsect.push(new TemplateSection(tsect.initialXML));
			}

			// Create our group map. Propagate premiumness while we're at it.
			for each (tsect in atsect) {
				for each (tgrp in tsect.children) {
					obMapIdToGroup[tgrp.id] = tgrp;
					if (tsect.premium) tgrp.premium = true;
				}
			}
			
			// Next, fill in our results.
			for each (var dctProps:Object in adctTemplateProps) {
				var strGroupId:String = "";
				if ('groupid' in dctProps) strGroupId = dctProps['groupid'];
				if (!(strGroupId in obMapIdToGroup)) strGroupId = ""; // Default group
				if (!(strGroupId in obMapIdToGroup)) throw new Error("No default group");
				tgrp = obMapIdToGroup[strGroupId];
				tgrp.children.push(dctProps);
				if (tgrp.premium) dctProps['fPremium'] = 'true';
			}
			
			// Now remove hidden templates, empty groups, and empty sections
			var iTSect:Number = 0;
			while (iTSect < atsect.length) {
				tsect = atsect[iTSect];
				var iTGrp:Number = 0;
				while (iTGrp < tsect.length) {
					tgrp = TemplateGroup(tsect.children[iTGrp]);
					if (tgrp.length == 0) {
						// Remove it
						tsect.children.splice(iTGrp,1);
					} else {
						// Move on
						iTGrp++;
					}
				}
				// Groups cleaned up. Now check this section
				if (tsect.length == 0 || (tsect.hidden && !fShowHiddenGroups)) {
					atsect.splice(iTSect, 1);
				} else {
					// Keep this section and move on
					iTSect++;
				}
			}
			
			// Finally, sort group children by name
			for each (tsect in atsect) {
				for each (tgrp in tsect.children) {
					tgrp.children.sortOn('title')
				}
			}
			
			// If a section is premium, make its groups premium
			// if a group is premium, make its templates premium
			
			return Cleanup(atsect); // Convert into something that works with our display format
		}
		
		private function Cleanup(atsect:Array): Array {
			// Convert into something that works with section lists (for now)
			// Remove group hierarchy (move templates under template sections)
			
			// TemplateCategory becomes an array
			// TemplateSection becomes an object with a children: attribute
			// TemplateSection.children is an array of object proxy templates
			
			for each (var tsect:TemplateSection in atsect) {
				for each (var tgrp:TemplateGroup in tsect.children) {
					for (var iTemplate:Number = 0; iTemplate < tgrp.children.length; iTemplate++) {
						var dctProps:Object = tgrp.children[iTemplate];
						var obTemplate:ObjectProxy = new ObjectProxy();
						
						// Set some defaults
						obTemplate.defaultToHighQuality = tgrp.defaultToHighQuality;
						obTemplate.author = '';
						obTemplate.authorurl = '';
						obTemplate.groupid = '';
						obTemplate.strCMSStage = 'private';
						obTemplate.fPremium = 'false';
						
						// Conver to an object proxy
						for (var strKey:String in dctProps) {
							obTemplate[strKey] = dctProps[strKey];
						}
						
						obTemplate.dctProps = dctProps;
						
						// dctProps contains: 'nFileId,iteminfo:title,strCMSStage,strOwnerId,nWidth,nHeight,ref:preview,author,authorurl,groupid'

						//Add extra stuff we need
						var nProps:Number = 50;
						var nRatio:Number = Number(obTemplate.nWidth) / Number(obTemplate.nHeight);
						obTemplate.props = 100 * nRatio / (nRatio + 1);

						obTemplate.fid = obTemplate.nFileId;
						obTemplate.template = "fid:" + obTemplate.nFileId;
						obTemplate.previewUrl = PicnikService.GetFileURL(obTemplate['ref:preview']);
						obTemplate.title = dctProps['title'];
						obTemplate.premium = obTemplate.fPremium == 'true';

						tgrp.children[iTemplate] = obTemplate;
					}
				}
			}
			
			return atsect;
		}
	}
}