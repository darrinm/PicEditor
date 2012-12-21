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
package bridges.postsave {
	import bridges.Bridge;
	import bridges.storageservice.StorageServiceError;
	
	import controls.ResizingLabel;
	import controls.TextPlus;
	
	import dialogs.DialogManager;
	import dialogs.EasyDialog;
	import dialogs.EasyDialogBase;
	import dialogs.RegisterHelper.IFormContainer;
	import dialogs.RegisterHelper.RegisterBoxBase;
	
	import events.AccountEvent;
	
	import flash.events.TextEvent;
	import flash.net.URLRequest;
	
	import mx.containers.HBox;
	import mx.events.FlexEvent;
	
	import util.LocUtil;
	import util.NextNavigationTracker;
	
	public class PostSaveBase extends Bridge implements IFormContainer {
		
		[Bindable] public var _hboxBubbles:HBox;
		[Bindable] public var _lblPhotoSavedTo:ResizingLabel;
		[Bindable] public var _tabRegister:RegisterBoxBase;
		[Bindable] public var _txtPhotoHistorySavedSubhead:TextPlus;
		
		[Bindable] public var infoGallery:ItemInfo;
		
		private var _fWorking:Boolean = false;
		
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
		}
		
		public function get photoHistorySavedSubhead(): String {
			var strHistorySavedSubhead:String = LocUtil.rbSubst("PostSave", "photoHistorySavedSubhead");
			if (_imgd && _imgd.lastSaveInfo && _imgd.lastSaveInfo.webpageurl)
				strHistorySavedSubhead += " " + LocUtil.rbSubst("PostSave", "viewSavedPhoto", Bridge.GetServiceName(_imgd.lastSaveInfo.serviceid));
			return strHistorySavedSubhead;
		}

		//
		// IActivatable implementation
		//
		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
			if (_lblPhotoSavedTo)
				_lblPhotoSavedTo.text = GetPhotoSavedText();
			if (_txtPhotoHistorySavedSubhead)
				_txtPhotoHistorySavedSubhead.htmlText = photoHistorySavedSubhead;
			
			if (_imgd && _imgd.lastSaveInfo && _imgd.lastSaveInfo.serviceid == "Show") {
				AccountMgr.GetStorageService("Show").GetSetInfo( _imgd.lastSaveInfo.setid,
					function( err:Number, strErr:String, dctSetInfo:Object ): void {
						if (err == StorageServiceError.None) {
							infoGallery = dctSetInfo as ItemInfo;
						}
					} );
			}
			
			_tabRegister.ClearErrors();
			
			if (null != _hboxBubbles) {
				_hboxBubbles.visible = _imgd && _imgd.lastSaveInfo && _imgd.lastSaveInfo./*bridge*/serviceid=='mycomputer';			
				_hboxBubbles.includeInLayout = _imgd && _imgd.lastSaveInfo && _imgd.lastSaveInfo./*bridge*/serviceid=='mycomputer';
			}			

			LogAdEvent('/view');
			callLater(NextNavigationTracker.RegisterListener, [OnNextNav]);						
		}
		
		private function OnNextNav(strNav:String): void {
			LogAdEvent('/click' + strNav);
			Util.UrchinLogReport("/PostSave" + strNav);
		}
		
		private function LogAdEvent(strEvent:String): void {
			// BST 2/3/10: Users started complaining more about download failures
			//  right about the same time we checked this in. Let's see if this makes any difference
			/*
			var strUserType:String;
			if (AccountMgr.GetInstance().isPremium)
				strUserType = "/paid";
			else if  (AccountMgr.GetInstance().isGuest)
				strUserType = "/guest";
			else
				strUserType = "/registered";
			Util.UrchinLogReport('/ads/post_save' + strUserType + strEvent);
			*/			
		}
		
		protected function GetPhotoSavedText(): String {
			var strService:String = null;
			if (_imgd && _imgd.lastSaveInfo) {
				strService = _imgd.lastSaveInfo./*bridge*/serviceid;
			}
			if (strService == 'Show')
				return LocUtil.rbSubst( "PostSave", "photoSavedToGallery" );
			if (strService == 'email')
				return LocUtil.rbSubst( "PostSave", "photoSavedToEmail" );
			if (strService == "mycomputer") {
				strService = "yourcomputer";
			}
			strService = Bridge.GetServiceName(strService);
			if (!strService || strService.length == 0) {
				return LocUtil.rbSubst( "PostSave", "photoSaved" );
			}
			return LocUtil.rbSubst( "PostSave", "photoSavedTo", strService );
		}		

		protected function DoEditGallery(): void {
			var gald:GalleryDocument = new GalleryDocument();
			
			var fnOnLoadDone:Function = function(err:Number = 0, strErr:String = ""): void {
				if (err == GalleryDocument.errDisabled) {
					var dlg:EasyDialog =
						EasyDialogBase.Show(
							this,
							[Resource.getString('Picnik', 'ok')],
							Resource.getString('Picnik', 'no_gallery_create_title'),						
							Resource.getString('Picnik', 'no_gallery_create_message'),						
							function( obResult:Object ):void {
							}	
						);			
				} else if (err == GalleryDocument.errNone) {
					PicnikBase.app.activeDocument = gald;
					PicnikBase.app.uimode = PicnikBase.kuimGallery;
					PicnikBase.app.activeTabId = PicnikBase.GALLERY_STYLE_TAB;					
				}
			}
			
			gald.InitFromPicnikFile(infoGallery, null, fnOnLoadDone);
		}
		
		protected function OnLink( evt:TextEvent ):void {
			switch (evt.text.toLowerCase()) {
			case "viewsavedphoto":
				if (_imgd && _imgd.lastSaveInfo && _imgd.lastSaveInfo.webpageurl) {
					PicnikBase.app.NavigateToURL(new URLRequest(_imgd.lastSaveInfo.webpageurl), "_blank");
					Util.UrchinLogReport("/PostSave/ViewSavedPhoto/" + _imgd.lastSaveInfo.serviceid);
				}
				break;
			
			case "signin":
				if (!AccountMgr.GetInstance().isGuest) {
					// third party accounts see register
					PicnikBase.app.ShowDialog("register");
					Util.UrchinLogReport("/PostSave/Register");
				} else {
					PicnikBase.app.ShowDialog("login");
					Util.UrchinLogReport("/PostSave/Login");
				}
				break;
			
			case "history":
				PicnikBase.app.NavigateTo(PicnikBase.IN_BRIDGES_TAB, "_brgHistoryIn");
				Util.UrchinLogReport("/PostSave/NavToHistory");
				break;
			}
		}

		// IFormContainer implements		
		[Bindable]
		public function get working(): Boolean {
			return _fWorking;
		}
		
		public function set working(fWorking:Boolean): void {
			_fWorking = fWorking;
		}

		public function SelectForm( strName:String, obDefaults:Object = null ): void {
			_tabRegister.ClearErrors();
			DialogManager.ShowRegisterTab( strName, this, null, obDefaults );
		}
		
		public function PushForm( strName:String, obDefaults:Object = null ): void {
			SelectForm( strName, obDefaults);
		}
				
		public function GetActiveForm(): RegisterBoxBase {
			return _tabRegister;
		}
							
		public function Hide(): void {
			// can't hide!
		}		
	}
}
