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
	import bridges.storageservice.*;
	
	import events.ActiveDocumentEvent;
	
	import flash.events.*;
	import flash.net.URLRequest;
	import flash.system.System;
	
	import mx.controls.CheckBox;
	import mx.resources.ResourceBundle;

	[Event(name="item_saved", type="flash.events.Event")]
	[Event(name="canceled", type="flash.events.Event")]
	
	public class FlickrOutBridgeBase extends StorageServiceOutBridgeBase {
		
   		[ResourceBundle("FlickrOutBridge")] private var _rb:ResourceBundle;
		
		// MXML-specified variables
		[Bindable] public var _chkbBeforeAfter:CheckBox;
		[Bindable] public var _strBandwidthLeft:String = Resource.getString("FlickrOutBridge", "Unknown");
		[Bindable] public var _strBandwidthUsed:String = Resource.getString("FlickrOutBridge", "Unknown");
		[Bindable] public var _strBandwidth:String = Resource.getString("FlickrOutBridge", "Unknown");

		public function FlickrOutBridgeBase() {
			super();
			_tpa = AccountMgr.GetThirdPartyAccount("Flickr");
		}

		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
			UpdatePrivacy();
		}

		override protected function OnActiveDocumentChange(evt:ActiveDocumentEvent): void {
			super.OnActiveDocumentChange(evt);
			UpdatePrivacy();
		}
		
		protected function UpdatePrivacy():void {
			if (_imgd) {
				if (_rbtnPrivate) _rbtnPrivate.selected = !_imgd.properties.flickr_ispublic;
				if (_rbtnPrivate) _rbtnPublic.selected = _imgd.properties.flickr_ispublic;
				if (_chkbFriends) _chkbFriends.enabled = !_imgd.properties.flickr_ispublic;
				if (_chkbFriends) _chkbFriends.selected = _imgd.properties.flickr_isfriend;
				if (_chkbFamily) _chkbFamily.enabled = !_imgd.properties.flickr_ispublic;
				if (_chkbFamily) _chkbFamily.selected = _imgd.properties.flickr_isfamily;
			}
		}
		
		private var _imgpBefore:ImageProperties;
		
		override protected function ValidateBeforeSave(): Boolean {
			if (_rbtnPublic)
				_imgd.properties.flickr_ispublic = _rbtnPublic.selected;
			if (_rbtnPrivate && _chkbFriends)
				_imgd.properties.flickr_isfriend = _rbtnPrivate.selected && _chkbFriends.selected;
			if (_rbtnPrivate && _chkbFamily)
				_imgd.properties.flickr_isfamily = _rbtnPrivate.selected && _chkbFamily.selected;
				
			_imgpBefore = new ImageProperties();
			_imgd.properties.CopyTo(_imgpBefore);
			_imgd.properties.serviceid = "flickr";

			return super.ValidateBeforeSave();
		}
		
		override protected function PostSaveWithItemInfo(iinfo:ItemInfo): void {
			if (iinfo && _chkbBeforeAfter && _chkbBeforeAfter.selected) {
				var strBefore:String = "<b>Before</b>\n<a href='" + _imgpBefore.webpageurl + "'><img src='" +
						_imgpBefore.thumbnailurl + "' title='" + _imgpBefore.title + "'></a>";
				var strAfter:String = "<b>After</b>\n<a href='" + iinfo.webpageurl + "'><img src='" +
						iinfo.thumbnailurl + "' title='" + iinfo.title + "'></a>";
						
				var strEdits:String = "<b>Edits</b>\n" + _imgd.condensedEdits;
			
				System.setClipboard(strBefore + "\n\n" + strAfter); // + "\n\n" + strEdits);
			}
			super.PostSaveWithItemInfo(iinfo);
		}
		
		// Let the server know the user is interested in upgrading to a Flickr Pro account
		protected function OnUpgradeLinkClick(evt:TextEvent): void {
			PicnikBase.app.NavigateToURL(new URLRequest("http://www.flickr.com/upgrade/"), "_blank", true);
		}
		
		override protected function OnUserInfoRefreshed(): void {
			super.OnUserInfoRefreshed();
			RefreshSets();	// need to refresh sets because the "create set" item depends on user state
			UpdateState();
		}
		
		override protected function OnSetsRefreshed(): void {
			_adctSetInfos.unshift( {title:Resource.getString("FlickrOutBridge", "None"), thumbnailurl:null, id:null} );
			super.OnSetsRefreshed();
		}
		
		override protected function GetState(): String {
			var strTargetState:String = "AccountTypeUnknown";
			_strBandwidthLeft = _strBandwidthUsed = _strBandwidth = Resource.getString("FlickrOutBridge", "Unknown");
			if (_dctUserInfo != null) {
				if (_dctUserInfo.is_pro) {
					_strBandwidthLeft = _strBandwidth = Resource.getString("FlickrOutBridge", "Unlimited");
					_strBandwidthUsed = Resource.getString("FlickrOutBridge", "Unknown");
					strTargetState = super.GetState();
				} else { // Non pro
					var cbBandwidthUsed:Number = Number(_dctUserInfo.userbytes);
					var cbBandwidthMax:Number = Number(_dctUserInfo.maxbytes);
					_strBandwidth = Util.FormatBytes(cbBandwidthMax);
					_strBandwidthUsed = Util.FormatBytes(cbBandwidthUsed);
					if (cbBandwidthUsed > cbBandwidthMax)
						_strBandwidthLeft = Resource.getString("FlickrOutBridge", "None");
					else
						_strBandwidthLeft = Util.FormatBytes(cbBandwidthMax - cbBandwidthUsed);
					if (cbBandwidthUsed < cbBandwidthMax)
						strTargetState = "AccountTypeNonPro";
					else {
						strTargetState = "AccountTypeNonProOutOfSpace";
						setFocus(); // Make sure we don't leave the focus on the title
					}
				}
			}
			
			if (_chkbPicnikTag)
				_chkbPicnikTag.selected = _tpa.GetAttribute("_fTagWithPicnik", true);
			
			return strTargetState;
		}
		
		override protected function CanCreateSets(adctSetInfos:Array):Boolean {
			// update the "start a new photo set" item depending whether or not the user has sets remaining
			if (_dctUserInfo && "setsremaining" in _dctUserInfo && (_dctUserInfo.setsremaining > 0 || _dctUserInfo.setsremaining == "lots")) {
				return true;
			}
			return false;
		}

		override protected function IsOverwriteable(itemInfo:ItemInfo=null): Boolean {
			if (_dctUserInfo && _dctUserInfo.is_pro)
				return super.IsOverwriteable(itemInfo);
			return false;
		}	
				
		override public function OnDeactivate(): void {
			super.OnDeactivate();
			if (_chkbPicnikTag)
				_tpa.SetAttribute("_fTagWithPicnik", _chkbPicnikTag.selected);
		}
	}
}
