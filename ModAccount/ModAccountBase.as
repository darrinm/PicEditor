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
package {
	
	import containers.CoreDialog;
	import containers.ResizingDialog;
	
	import dialogs.*;
	import dialogs.Purchase.*;
	import dialogs.Upsell.*;
	
	import module.PicnikModule;
	
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;

	public class ModAccountBase extends PicnikModule {
		[Bindable] public var myAccount:MyAccount = null;

		public function GetActivatableChild( id:String ):IActivatable {
			if ("myAccount" == id) {
				if (!myAccount) {
					myAccount = new MyAccount();
					myAccount.id = "myAccount";
					myAccount.includeInLayout = false;
					myAccount.visible = false;
					this.addChild(myAccount);
				}
				return myAccount;
			}
			return null;	
		}
		
		
		public function Show(strDialog:String, uicParent:UIComponent=null, fnComplete:Function=null, obParams:Object=null): DialogHandle {
			var dlg:Object = null;			
			var dialogHandle:DialogHandle = new DialogHandle(strDialog, uicParent, fnComplete, obParams);
			
			switch (strDialog) {
				case "CancelPaypalDialog":
					dlg = new CancelPaypalDialog();
					break;
				
				case "ChangeEmailDialog":
					dlg = new ChangeEmailDialog();
					break;
				
				case "ChangePasswordDialog":
					dlg = new ChangePasswordDialog();
					break;
				
				case "ChangePerformanceDialog":
					dlg = new ChangePerformanceDialog();
					break;
				
				case "ConfirmCancelDialog":
					dlg = new ConfirmCancelDialog();
					break;
				
				case "ConfirmDelAcctDialog":
					dlg = new ConfirmDelAcctDialog();
					break;
				
				case "GiftPrintEmailDialog":
					dlg = new GiftPrintEmailDialog();
					break;
				
				case "GiftRedeemDialog":
					dlg = new GiftRedeemDialog();
					break;

				case "GiftUpsellDialog":
					dlg = new GiftUpsellDialog();
					break;

				case "PurchaseDialog":
					dlg = new PurchaseDialog();
					break;
				
				case "PurchaseGiftDialog":
					dlg = new PurchaseGiftDialog();
					break;
				
				case "ReceiptDialog":
					dlg = new ReceiptDialog();
					break;
				
				case "SettingsDialog":
					dlg = new SettingsDialog();
					break;
				
				case "TargetedUpsellDialog":
					dlg = new TargetedUpsellDialog();
					break;
				
				default:
					Debug.Assert(false, "Requesting unknown dialog " + strDialog);
					break;				
			}
			
			// figure out what kind of dialog we have and act appropriately
			var coreDialog:CoreDialog = dlg as CoreDialog;
			if (null != coreDialog) {
				if (uicParent == null) uicParent = PicnikBase.app;
				coreDialog.Constructor(fnComplete, uicParent, obParams);
				PopUpManager.addPopUp(coreDialog, uicParent, true);
				PopUpManager.centerPopUp(coreDialog);
				coreDialog.PostDisplay();
			}		
			
			var resizingDialog:ResizingDialog = dlg as ResizingDialog;
			if (null != resizingDialog) {
				if (uicParent == null) uicParent = PicnikBase.app;
				resizingDialog.Constructor(fnComplete, uicParent, obParams);
				ResizingDialog.Show(resizingDialog, uicParent);
			}		
			
			if (null != dlg) {
				dialogHandle.IsLoaded = true;
				dialogHandle.dialog = dlg;
			}
			
			return dialogHandle;
		}
	}
}
