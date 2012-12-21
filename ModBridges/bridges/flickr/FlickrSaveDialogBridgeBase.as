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
package bridges.flickr {
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.events.FlexEvent;
	
	public class FlickrSaveDialogBridgeBase extends FlickrOutBridgeBase {
		[Bindable] public var _btnCancel:Button;
		[Bindable] public var _cboxPrivacy:ComboBox;
		[Bindable] public var _btnAddPicnikTag:Button;
		
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			_btnCancel.addEventListener(MouseEvent.CLICK, OnCancelClick);
			_cboxPrivacy.addEventListener(Event.CHANGE, OnPrivacyChange);
			_btnAddPicnikTag.addEventListener(MouseEvent.CLICK, OnAddPicnikTagClick);
		}

		private function OnCancelClick(evt:MouseEvent): void {
			dispatchEvent(new Event("canceled"));
		}
		
		private function OnAddPicnikTagClick(evt:MouseEvent): void {
			AddPicnikTag();			
		}
		
		override protected function PostSaveWithItemInfo(iinfo:ItemInfo): void {
			super.PostSaveWithItemInfo(iinfo);
			dispatchEvent(new Event("item_saved"));
		}
		
		// Flickr lite shows privacy settings in a combobox instead of radio/check buttons.
		// Override functions that update the privacy UI or image properties.
		private function OnPrivacyChange(evt:Event): void {
			switch (_cboxPrivacy.selectedItem.data) {
			case "public":
				_imgd.properties.flickr_ispublic = true;
				_imgd.properties.flickr_isfriend = false;
				_imgd.properties.flickr_isfamily = false;
				break;
				
			case "private":
				_imgd.properties.flickr_ispublic = false;
				_imgd.properties.flickr_isfriend = false;
				_imgd.properties.flickr_isfamily = false;
				break;
				
			case "family":
				_imgd.properties.flickr_ispublic = false;
				_imgd.properties.flickr_isfriend = false;
				_imgd.properties.flickr_isfamily = true;
				break;
				
			case "friends":
				_imgd.properties.flickr_ispublic = false;
				_imgd.properties.flickr_isfriend = true;
				_imgd.properties.flickr_isfamily = false;
				break;
				
			case "friends_and_family":
				_imgd.properties.flickr_ispublic = false;
				_imgd.properties.flickr_isfriend = true;
				_imgd.properties.flickr_isfamily = true;
				break;
			}
		}
		
		override protected function UpdatePrivacy():void {
			if (_imgd) {
				var strPrivacy:String = "private"; // default to private
				if (_imgd.properties.flickr_isfriend && _imgd.properties.flickr_isfamily)
					strPrivacy = "friends_and_family";
				else if (_imgd.properties.flickr_isfriend)
					strPrivacy = "friends";
				else if (_imgd.properties.flickr_isfamily)
					strPrivacy = "family";
				else if (_imgd.properties.flickr_ispublic)
					strPrivacy = "public";
					
				for (var i:int = 0; i < _cboxPrivacy.dataProvider.length; i++) {
					var obT:Object = _cboxPrivacy.dataProvider[i];
					if (obT.data == strPrivacy) {
						_cboxPrivacy.selectedIndex = i;
						break;
					}
				}
			}
		}
		
		override protected function PostSaveAction(dctItemInfo:Object): void {
			// specifically do nothing. Especially don't navigate around.
		}
		
		override protected function get isOutBridge(): Boolean {
			return true;
		}
	}
}
