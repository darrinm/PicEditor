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
package bridges.mycomputer {
	import bridges.Bridge;
	import bridges.IAutoFillSource;
	import bridges.picnik.PicnikStorageService;
	import bridges.projects.ProjectsInBridgeBase;
	import bridges.storageservice.StorageServiceInBridgeBase;
	
	import controls.ResizingButton;
	
	import dialogs.BusyDialogBase;
	import dialogs.DialogManager;
	import dialogs.EasyDialogBase;
	
	import events.AccountEvent;
	import events.NavigationEvent;
	
	import flash.events.*;
	
	import mx.core.UIComponent;
	import mx.effects.IEffectInstance;
	import mx.effects.Sequence;
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
	
	import util.UploadManager;
	
	public class MyComputerInBridgeBase extends StorageServiceInBridgeBase implements IAutoFillSource {
		[Bindable] protected var _fServiceActive:Boolean = false;
		[Bindable] protected var isGuest:Boolean = true;
		[Bindable] protected var isPaid:Boolean = false;
		[Bindable] protected var isUnpaidRegistered:Boolean = false;
		[Bindable] public var _btnRegisterOrUpgrade:ResizingButton;
		
		private var _nFileListLimit:Number = 0;
		private var _nFileUploadLimit:Number = 0;
		
		[Bindable] public var _efGlow:Sequence;
		
   		[ResourceBundle("MyComputerInBridge")] private var _rb:ResourceBundle;

		protected var showListForGuests:Boolean = false;
		private var _ui:MyComputerInBridgeUploadInterface = null;

		override public function set currentState(value:String):void {
			super.currentState = "";
		}
		
		[Bindable]
		public function set currentState2(value:String):void {
			super.currentState = value;
		}
		
		public function get currentState2():String {
			return super.currentState;
		}
		
		public function MyComputerInBridgeBase() {
			super();
			_ui = new MyComputerInBridgeUploadInterface(this);
			
			// UNDONE: loc "Recent Uploads"?
			_tpa = _ui._tpa;
			fileListLimit = UploadInterface.knPaidFileListLimit;
			fileUploadLimit = UploadInterface.knPaidFileListLimit;
		}
	
		public function OnAddedNewFids(): void {
			if (_tlst != null) {
				RefreshItemList();
				_tlst.AnimateScrollToHead();
			}
		}
		
		public function DoValidateOverwrite(fnContinue:Function, fnCanceled:Function=null): void {
			ValidateOverwrite(fnContinue, fnCanceled);
		}
		
		private function OnUploadCanceled(evt:Event): void {
			// An upload was canceled. Refresh our list
			RefreshItemList();
		}
		
		[Bindable]
		protected function set fileListLimit(n:Number): void {
			_nFileListLimit = n;
			
			// This is how many we show
			picnikStorageService.fileListLimit = _nFileListLimit;
		}
		
		protected function get fileListLimit(): Number {
			return _nFileListLimit;
		}
		
		[Bindable]
		protected function set fileUploadLimit(n:Number): void {
			_nFileUploadLimit = n;
		}
		
		protected function get fileUploadLimit(): Number {
			return _nFileUploadLimit;
		}

		private function get picnikStorageService():PicnikStorageService {
			return _tpa.storageService as PicnikStorageService;
		}
		
		protected function CancelUploads(): void {
			UploadManager.CancelAll();
		}
		
		private function HideBusyDialog(): void {
			if (_bsy) {
				_bsy.Hide();
				_bsy = null;	
			}
		}
		
		// e.g. <mx:Button click="Clear()" label="Clear"/>
		protected function Clear(): void {
			var fnOnDeleteAll:Function = function(err:Number, strError:String): void {
				HideBusyDialog();
				if (err != PicnikService.errNone)
					trace("Error deleting: " + err);
				RefreshItemList();
			}
			var this2:UIComponent = this;
			var fnOnClear:Function = function(obResult:Object): void {
				if ('success' in obResult && obResult.success) {
					// Do the deletion
					HideBusyDialog();
					_bsy = BusyDialogBase.Show(this2, Resource.getString("MyComputerInBridge", "Deleting"), BusyDialogBase.DELETE, "IndeterminateNoCancel", 0);
					picnikStorageService.DeleteAll(fnOnDeleteAll);
				}
			}
			
			EasyDialogBase.Show(PicnikBase.app,
				[Resource.getString("MyComputerInBridge", "DeleteThem"), Resource.getString("MyComputerInBridge", "Cancel")],
				Resource.getString("MyComputerInBridge", "DeleteAllAreYouSureTitle"),
				Resource.getString("MyComputerInBridge", "DeleteAllAreYouSureBody"),
				fnOnClear);
		}
		
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			OnUserChange(null);
			// This button only exists in the Basket
			if (_btnRegisterOrUpgrade)
				_btnRegisterOrUpgrade.addEventListener(MouseEvent.CLICK, OnRegisterOrUpgradeClick);
				
		}
		
		public static function GetFileListLimitForUserType(fIsPaid:Boolean, fIsGuest:Boolean): Number {
			return UploadInterface.GetFileListLimitForUserType(fIsPaid, fIsGuest);
		}
		
		override protected function OnUserChange(evt:AccountEvent): void {
			var actm:AccountMgr = AccountMgr.GetInstance();
			isPaid = actm.isPaid;
			isGuest = actm.isGuest;
			isUnpaidRegistered = !(isPaid || isGuest)
			fileListLimit = GetFileListLimitForUserType(isPaid, isGuest);
			fileUploadLimit = GetFileListLimitForUserType(isPaid, isGuest);
			if (isUnpaidRegistered && actm.expiredDaysAgo < 62) {
				picnikStorageService.storageLimit = UploadInterface.knPaidFileListLimit;
			} else {
				picnikStorageService.storageLimit = fileUploadLimit;
			}
			super.OnUserChange(evt);
		}
		
		private function OnRegisterOrUpgradeClick(evt:MouseEvent): void {
			if (AccountMgr.GetInstance().isGuest)
				DialogManager.ShowRegister(PicnikBase.app);
			else
				DialogManager.ShowUpgrade("/in_upload/morephotos", PicnikBase.app);
		}
		
		override protected function GetState(): String {
			return "";
		}
		
		public override function GetMenuItems(): Array {
			return [Bridge.EDIT_ITEM, Bridge.DELETE_ITEM, Bridge.EMAIL_ITEM, Bridge.DOWNLOAD_ITEM];
		}
		
		private var _efiGlow:IEffectInstance;

		// We keep track of the active document because application state
		// restoration may bring us to this bridge BEFORE the current image
		// has finished loading. Once it has loaded we want to update the
		// preview, etc
		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
			if (_efGlow)
				_efiGlow = _efGlow.play()[0];
			_fServiceActive = PicnikBase.app.IsServiceActive();
			
			UploadManager.Instance().addEventListener(UploadManager.UPLOADCANCELED, OnUploadCanceled);
		}
		
		override public function OnDeactivate(): void {
			try {
				if (_efiGlow) {
					_efiGlow.end();
					_efiGlow.finishEffect();
					_efiGlow = null;
				}
				super.OnDeactivate();
				doc = null;
				
				UploadManager.Instance().removeEventListener(UploadManager.UPLOADCANCELED, OnUploadCanceled);
			} catch (e:Error) {
				trace("Ignoring ERROR: " + e);
			}
		}
				
		// Don't make a call to file.list when the file list is hidden (e.g. guests on the in bridge) 
		override protected function get storeIsOff():Boolean {
			return super.storeIsOff || (!showListForGuests && AccountMgr.GetInstance().isGuest);
		}

		public static function MakeImageFileFilter(): Array
		{
			return UploadInterface.MakeImageFileFilter();
		}	
		
		public function DoUpload(fUploadForOpen:Boolean=true, fGoToCreate:Boolean=false): void {
			_ui.DoUpload(fUploadForOpen, fGoToCreate);
		}
		
		protected function DoCollage(): void {
			ProjectsInBridgeBase.OnGridCollageClick();
		}
		
		protected function DoAdvancedCollage(): void {
			ProjectsInBridgeBase.OnAdvancedCollageClick();
		}
		
		protected function DoGallery(): void {
			NavigateTo(PicnikBase.IN_BRIDGES_TAB,'_brgGalleryIn');
		}
		
		override protected function get simpleBridgeName(): String {
			if (_ui._fDownloadingSample)
				return "sample";
			else return super.simpleBridgeName;
		}
		
		public function LoadSample(strPath:String, evtPostLoadDest:NavigationEvent=null): void {
			_ui.LoadSample(strPath, evtPostLoadDest);
		}
	}
}
