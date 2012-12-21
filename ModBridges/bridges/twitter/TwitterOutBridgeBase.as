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
package bridges.twitter {
	import bridges.*;
	import bridges.storageservice.StorageServiceOutBridgeBase;
	
	import controls.ImagePlus;
	import controls.ResizingLabel;
	import controls.TextAreaPlus;
	
	import events.ActiveDocumentEvent;
	import events.LoginEvent;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.events.FlexEvent;
	
	import util.VBitmapData;
	
	public class TwitterOutBridgeBase extends StorageServiceOutBridgeBase {
		public static const knMaxTweetLen:int = 110;
		
		[Bindable] public var _lblScreenName:ResizingLabel;
		[Bindable] public var _ipUserIcon:ImagePlus;
		[Bindable] public var _hbWarning:HBox;
		[Bindable] public var _hbUserPresence:HBox;
		[Bindable] public var _taTweet:TextAreaPlus;
		[Bindable] public var _strTweet:String;
		[Bindable] public var _lblCharCount:Label;
		[Bindable] public var _btnSaveProfilePicture:Button;
		[Bindable] public var _btnSaveProfileBackground:Button;
		[Bindable] public var _chkbTileBackground:CheckBox;
		[Bindable] public var _vboxTweet:VBox
		[Bindable] public var _vboxProfilePicture:VBox;
		[Bindable] public var _vboxBackgroundImage:VBox;
//		[Bindable] protected var saveMode:String;
//		[Bindable] public var _cnvSmallest:Canvas;
//		[Bindable] public var _cnvSmall:Canvas;
//		[Bindable] public var _cnvMedium:Canvas;
//		[Bindable] public var _cnvLarge:Canvas;
		[Bindable] public var _imgSmallest:Image;
		[Bindable] public var _imgSmall:Image;
		[Bindable] public var _imgMedium:Image;
		[Bindable] public var _imgLarge:Image;
		
		private var _oDefaultTextColor:Object;
		private var _oDefaultCharTextColor:Object;
		private var _strTwitGooUrl:String = null;
		private var _strTwitterUrl:String = null;
		private var _strSaveMode:String = "tweet";
		public function TwitterOutBridgeBase() {
			super();
			_tpa = AccountMgr.GetThirdPartyAccount("Twitter");
		}
	
		[Bindable]
		public function get saveMode():String
		{
			return _strSaveMode;
		}
	
		public function set saveMode(strMode:String):void
		{
			switch (strMode)
			{
				case 'tweet':
					_vboxTweet.validateNow();
					break;
				case 'profile':
					_vboxProfilePicture.validateNow();
					break;
				case 'background':
					_vboxBackgroundImage.validateNow();
					break;
				default:
					break;
			}
			_strSaveMode = strMode;
		}
		
		override protected function OnActiveDocumentChange(evt:ActiveDocumentEvent): void {
			super.OnActiveDocumentChange(evt);
			OnProfilePic();
		}
		
		private function setthumb(nSize:Number, img:Image):void
		{
			var bmpd:BitmapData = new VBitmapData(nSize, nSize);
			var bmpSrc:BitmapData = _imgd.composite;
		
			if (bmpSrc == null) return;
		
			var nScale:Number = Math.max(nSize/bmpSrc.width, nSize/bmpSrc.height);
			var mx:Matrix = new Matrix(nScale, 0, 0, nScale);
					
			bmpd.draw(_imgd.composite, mx);
			img.source = new Bitmap(bmpd);
		
		}
	
		public function OnProfilePic():void
		{
			//_vboxProfilePicture.validateNow();
			//_vboxBackgroundImage.validateNow();
			//_vboxTweet.validateNow();
			if (_imgd == null) return;
			setthumb(24, _imgSmallest);
			setthumb(31, _imgSmall);
			setthumb(48, _imgMedium);
			setthumb(75, _imgLarge);
		}
		
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			saveMode = "tweet";
		
			_btnSaveProfilePicture.addEventListener(MouseEvent.CLICK, OnSaveClick);
			_btnSaveProfileBackground.addEventListener(MouseEvent.CLICK, OnSaveClick);
			_taTweet.addEventListener(flash.events.TextEvent.TEXT_INPUT, OnTweetChange);
			_taTweet.addEventListener(flash.events.Event.CHANGE, OnTweetChange);
			_taTweet.addEventListener(flash.events.KeyboardEvent.KEY_UP, OnTweetChange);
			_oDefaultTextColor= _taTweet.getStyle("color");
			_oDefaultCharTextColor= _lblCharCount.getStyle("color");
			OnTweetChange(null);
		}
		
		override protected function UpdateItemInfo(itemInfo:ItemInfo):ItemInfo {
			switch (saveMode) {
			case "tweet":
				itemInfo.twitter_strTweet = _taTweet.text;
				itemInfo.setid = 'tweet';
				break;
				
			case "picture":
				itemInfo.setid = "account";
				itemInfo.id = "picture";
				break;
				
			case "background":
				itemInfo.setid = "account";
				itemInfo.id = "background image";
				itemInfo.twitter_profile_background_tile = _chkbTileBackground.selected;
				break;
			}

			return itemInfo;
		}
		
		public function get serviceName(): String {
			return "twitter";
		}	
		
		public function OnTwitterIdClick():void
		{
			if (_strTwitterUrl)
				PicnikBase.app.NavigateToURL(new URLRequest(_strTwitterUrl), '_blank');
		}
		
		public function OnTwitGooClick():void
		{
			if (_strTwitGooUrl)
				PicnikBase.app.NavigateToURL(new URLRequest(_strTwitGooUrl), '_blank');
		}	
	
		// Let the user know if thier tweet is too big
		private function OnTweetChange(evt:Event):void
		{
			var nChars:int = knMaxTweetLen - _taTweet.length;
			_lblCharCount.text = nChars.toString();
			//_lblCharCount.text = nChars.toString() + " " + Resource.getString("TwitterOutBridge", "CharsLeft");
			
			if (_taTweet.length > knMaxTweetLen)
			{
				_taTweet.setStyle("color", "red");
				_lblCharCount.setStyle("color","red");
				_btnSave.enabled = false;
			} else {
				_taTweet.setStyle("color", _oDefaultTextColor);
				_lblCharCount.setStyle("color", _oDefaultCharTextColor);
				_btnSave.enabled = true;
			}
		}
		
		//protected function OnUpgradeLinkClick(evt:MouseEvent): void {
		//}
		
		// update on-screen info
		protected function UpdateUserInfo(): void {			
			var fnUserInfoComplete:Function = function(err:Number, strError:String, dctUserInfo:Object=null):void {
				if (err == 0)
				{
					_lblScreenName.text = dctUserInfo.twitter_screen_name;
					_ipUserIcon.source = dctUserInfo.twitter_profile_image_url;
					_hbUserPresence.visible = true;
					_hbUserPresence.includeInLayout = true;
					var fShowWarning:Boolean =  (dctUserInfo.twitter_protected == true);					
					_hbWarning.visible = fShowWarning;
					_hbWarning.includeInLayout = fShowWarning;
					_strTwitGooUrl = "http://twitgoo.com/u/" + dctUserInfo.twitter_screen_name;
					_strTwitterUrl = "http://twitter.com/" +  dctUserInfo.twitter_screen_name;
				} else {
					_strTwitGooUrl = null;
					_strTwitterUrl = null;
					Logout()
				}
			}

			_tpa.storageService.GetUserInfo(fnUserInfoComplete);
		}
		
		protected override function OnLoginComplete(evt:LoginEvent):void {
			super.OnLoginComplete(evt);
			PicnikBase.app.callLater(UpdateUserInfo);
		}

		protected function Logout(): void {
			_hbUserPresence.visible = false;
			_hbUserPresence.includeInLayout = false;
			_hbWarning.visible = false;
			_hbWarning.includeInLayout = false;
			
			Disconnect();
		}

		// UNDONE: comment
		override protected function GetSelectedSetInfo(): Object {
			return { id: saveMode };
		}
	}
}
