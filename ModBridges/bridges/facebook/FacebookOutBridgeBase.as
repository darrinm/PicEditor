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
package bridges.facebook {
	import bridges.*;
	import bridges.storageservice.StorageServiceOutBridgeBase;
	import bridges.storageservice.StorageServiceSetComboItem;
	
	import events.LoginEvent;
	
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	
	import imagine.ImageDocument;
	
	import mx.containers.Box;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.TextArea;
	import mx.events.FlexEvent;
			
	public class FacebookOutBridgeBase extends StorageServiceOutBridgeBase {
		[Bindable] public var _chkbFBApprove:CheckBox;
		[Bindable] public var _chkbNewsfeed:CheckBox;
		[Bindable] public var _lbtnGetUploadPermission:Button;
		[Bindable] public var _hboxPhotoApproval:Box;
		[Bindable] public var _boxPostToNewsfeed:Box;
		[Bindable] public var _taHeadline:TextArea;
		[Bindable] public var fPublishable:Boolean = false;
		[Bindable] public var fUserInfoReady:Boolean = false;
		
		//[Bindable] public var _taFeedMessage:TextAreaPlus;
		
		public function FacebookOutBridgeBase() {
			super();
			_tpa = AccountMgr.GetThirdPartyAccount("Facebook");
		}

		override protected function GetSignedOutState():String {
			if (!PicnikConfig.facebookEnabled)
				return "ServiceDown";
			return super.GetSignedOutState();
		}

		protected function TellYourFriends(): void {
			Util.UrchinLogReport("/facebook/invite/out/click");
			if (_tpa && (_tpa.storageService as FacebookStorageService)) (_tpa.storageService as FacebookStorageService).TellYourFriends();
		}
					
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			_lbtnGetUploadPermission.addEventListener(MouseEvent.CLICK, OnGetUploadPermissionClick);
		}
		
		override protected function OnLoginComplete(evt:LoginEvent): void {
			super.OnLoginComplete(evt);
			RefreshUserInfo();
		}
		
		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
			if (_ss.IsLoggedIn()) {
				RefreshUserInfo();
				return;
			}
		}
				
		override protected function OnUserInfoRefreshed(): void {
			super.OnUserInfoRefreshed();
			
			if (_dctUserInfo) {
				fUserInfoReady = true;
				if (_dctUserInfo.publish_stream) {	
					fPublishable = true;
				} else {
					fPublishable = false;
				}
			} else {
				fUserInfoReady = false;
			}
		}

		override protected function IsOverwriteable(itemInfo:ItemInfo=null): Boolean {
			if (AccountMgr.GetInstance().isAdmin) {
				// steveler 2010/05/17
				// facebook is behaving badly when overwriting files write now ("unknown error") so
				// disabling this for now, but leaving it in for Admin users so that we can keep testing it.
				if (_dctUserInfo && _dctUserInfo.publish_stream)
					return super.IsOverwriteable(itemInfo);
			}
			return false;
		}		
	
		override protected function OnCreateItemComplete(err:Number, strError:String, itemInfo:ItemInfo=null): void {
			super.OnCreateItemComplete(err, strError, itemInfo);
		
 			if (err == ImageDocument.errNone && _chkbNewsfeed.selected) {	
 				itemInfo.shareHeadline = _taHeadline.text;
				_ss.NotifyOfAction( "CreateItem", _imgd, itemInfo, function( err:Number, strError:String, itemInfo:ItemInfo=null ):void {} );
			}
			
			if (err == ImageDocument.errNone && _chkbFBApprove.selected) {
				var dctSetInfo:Object = (_cboxSets.selectedItem as StorageServiceSetComboItem).setinfo;
				if (dctSetInfo && dctSetInfo.webpageurl)
					PicnikBase.app.NavigateToURL(new URLRequest(dctSetInfo.webpageurl), "_blank");
			}
		}
		
		private function OnGetUploadPermissionClick(evt:MouseEvent): void {
			_ss.Authorize( "publish_stream" );
		}
		
		override protected function GetLocalPhrases():Object {
			// localize some of the words we use to match this bridge
			var obPhrases:Object = super.GetLocalPhrases();
			obPhrases.set = "album";
			return obPhrases;
		}
		
	}
}
