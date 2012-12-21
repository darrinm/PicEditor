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
package controls {
	import containers.sectionList.SectionListBase;
	
	import flash.events.Event;
	import flash.text.Font;
	import flash.text.FontType;
	import flash.utils.getTimer;
	
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
	
	import util.FontFamily;
	import util.FontManager;
	import util.PicnikFont;
	import util.SectionBadgeInfo;

	[Event(name="loaded", type="flash.events.Event")]

	public class FontListBase extends SectionListBase {
		[Bindable] public var loaded:Boolean = false;
  		[Bindable] [ResourceBundle("SectionHeader")] private var _rb:ResourceBundle;
		[Bindable] [ResourceBundle("FontList")] private var _rbFontList:ResourceBundle;
		[Bindable] [ResourceBundle("FontsXml")] private var _rbFontsXml:ResourceBundle;
  		
		private var _fEnabled:Boolean = true;
		
		public function FontListBase(): void {
			// Start out disabled until the font list is loaded
			super.enabled = false;
			
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
		}

		private function OnInitialize(evt:Event): void {
			FontManager.GetFontList(SetFontList);
		}
		
		private function SetFontList(afntf:Array, obCategories:Object = null): void {
			PrependDeviceFonts(afntf);
			
			// Organize the fonts into categorized buckets. The category order is
			// determined by the order in which they are encountered in the fonts.xml file.
			var asec:Array = new Array();
			var dctSections:Object = {};
			for each (var fntf:FontFamily in afntf) {
				if (fntf.premium && PicnikBase.app._pas.googlePlusUI)
					continue;
				var sec:Object;
				if (fntf.category in dctSections) {
					sec = dctSections[fntf.category];
				} else {
					// New category. Add it to the dict for easy lookup and add it
					// to the array of FontFamily arrays used as the SectionList's DataProvider.
					if (obCategories && fntf.category in obCategories && obCategories[fntf.category] != null) {
						var aKids:Array = [];
						if (obCategories[fntf.category].sectionBadge != "")
							aKids.push( new SectionBadgeInfo(obCategories[fntf.category].sectionBadge))
						sec = { title1: obCategories[fntf.category].title1,
								title2: obCategories[fntf.category].title2,
								rendererState: obCategories[fntf.category].rendererState,
								expanded: obCategories[fntf.category].expanded,								
								children: aKids };	
					} else {
						sec = { title1: fntf.category,
								title2: "",
								children: [] };
					}
					dctSections[fntf.category] = sec;
					asec.push(sec);
				}
				if (fntf.premium)
					sec.premium = true;
				if (sec.premium && sec.title2.length == 0) {
					sec.title2 = Resource.getString("SectionHeader", "_lbPremium");
				}
				
				if (fntf.rendererState == "")
					fntf.rendererState = sec.rendererState;
				sec.children.push(fntf);
			}
			
			dataProvider = asec;
			super.enabled = _fEnabled;
			loaded = true;
			dispatchEvent(new Event("loaded"));
		}
		
		private function PrependDeviceFonts(afntf:Array): void {
			if (AccountMgr.GetInstance().isAdmin) {
				// Add all the other device fonts from this machine.
				var afnt:Array = Font.enumerateFonts(true);
				afnt.sortOn("fontName");
				for each (var fnt:Font in afnt) {
					if (fnt.fontType == FontType.EMBEDDED)
						continue;
					var fntf:FontFamily = CreateFontFamily(fnt.fontName, fnt.fontName, "My Fonts");
					afntf.push(fntf);
				}
			}
		}
		
		private function CreateFontFamily(strFamilyName:String, strDisplayName:String, strCategory:String): FontFamily {
			var xmlFamily:XML = <fontFamily
				baseFileName=''
				familyName={strFamilyName}
				displayName={strDisplayName}
				authorName='*author*'
				authorUrl='*authorUrl*'
				category={strCategory}
				rendererState='DeviceFont'
				isDevice='1'
			/>;
			
			var xmlFont:XML = <font
				isBold='0'
				isItalic='0'
				altBold='0'
				altItalic='0'
				familyName={strFamilyName}
				baseFileName=''
				isEmbeded='1'
				fakeBold='0'
				size='0'
				leading='0'
				isDevice='1'
			/>;
			var pfnt:PicnikFont = new PicnikFont(xmlFont);
			xmlFamily.appendChild(xmlFont);
			
			xmlFont = <font
				isBold='1'
				isItalic='0'
				altBold='0'
				altItalic='0'
				familyName={strFamilyName}
				baseFileName=''
				isEmbeded='1'
				fakeBold='0'
				size='0'
				leading='0'
				isDevice='1'
			/>;
			pfnt = new PicnikFont(xmlFont);
			xmlFamily.appendChild(xmlFont);
			
			xmlFont = <font
				isBold='0'
				isItalic='1'
				altBold='0'
				altItalic='0'
				familyName={strFamilyName}
				baseFileName=''
				isEmbeded='1'
				fakeBold='0'
				size='0'
				leading='0'
				isDevice='1'
			/>;
			pfnt = new PicnikFont(xmlFont);
			xmlFamily.appendChild(xmlFont);
			
			xmlFont = <font
				isBold='1'
				isItalic='1'
				altBold='0'
				altItalic='0'
				familyName={strFamilyName}
				baseFileName=''
				isEmbeded='1'
				fakeBold='0'
				size='0'
				leading='0'
				isDevice='1'
			/>;
			pfnt = new PicnikFont(xmlFont);
			xmlFamily.appendChild(xmlFont);
			
			return new FontFamily(xmlFamily);
		}
		
		public override function set enabled(fEnabled:Boolean): void {
			_fEnabled = fEnabled;
			if (loaded) super.enabled = fEnabled;
		}
		
	    public override function get enabled():Boolean {
			return _fEnabled;
		}
	}
}
