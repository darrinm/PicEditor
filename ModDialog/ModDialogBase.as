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
	import dialogs.Privacy.*;
	import dialogs.Purchase.*;
	import dialogs.Upsell.TargetedUpsellDialog;
	
	import module.PicnikModule;
	
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	
	import pages.HelpHub;

	public class ModDialogBase extends PicnikModule {
		public function Show(strDialog:String, uicParent:UIComponent=null, fnComplete:Function=null, obParams:Object=null): DialogHandle {
			var dlg:Object = null;
			
			var dialogHandle:DialogHandle = new DialogHandle(strDialog, uicParent, fnComplete, obParams);

			// TODO (steveler) : move this over to a DialogRegistry class
			switch (strDialog) {
				case "AskForPremiumDialog":
					dlg = new AskForPremiumDialog();
					break;
				
				case "BlockedPopupDialog":				
					dlg = new BlockedPopupDialog();
					break;
				
				case "ConfirmApplyEffectDialog":
					dlg = new ConfirmApplyEffectDialog();
					break;

				case "ConfirmCancelDialog":
					dlg = new ConfirmCancelDialog();
					break;
				
				case "ConfirmDelAcctDialog":
					dlg = new ConfirmDelAcctDialog();
					break;
				
				case "ConfirmDeleteDialog":
					dlg = new ConfirmDeleteDialog();
					break;
				
				case "ConfirmLoadOverEditDialog":
					dlg = new ConfirmLoadOverEditDialog();
					break;
				
				case "ConfirmOverwriteDialog":
					dlg = new ConfirmOverwriteDialog();
					break;

				case "CreateAlbumDialog":
					dlg = new CreateAlbumDialog();
					break;
				
				case "FeedbackDialog":
					dlg = new FeedbackDialog();
					break;
				
				case "GalleryPrivacyDialog":
					dlg = new GalleryPrivacy();
					break;
				
				case "HelpDialog":
				case "SettingsDialog":
					dlg = new HelpDialog();
					break;
				
				case "NewCanvasDialog":
					dlg = new NewCanvasDialog();
					break;
				
				case "PartyInviteDialog":
					dlg = new PartyInviteDialog();
					break;
				
				case "PrivacyDetourDialog":
					dlg = new PrivacyDetourDialog();
					break;

				case "PrivacyDetourConfirmRejectDialog":
					dlg = new PrivacyDetourConfirmRejectDialog();
					break;

				case "PrivacyDetourFinalRejectDialog":
					dlg = new PrivacyDetourFinalRejectDialog();
					break;

				case "PrivacyDetourCompleteRejectDialog":
					dlg = new PrivacyDetourCompleteRejectDialog();
					break;

				case "PublishTemplateDialog":
					dlg = new PublishTemplateDialog();
					break;
				
				case "ShareContentDialog":
					dlg = new ShareContentDialog();
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
	
		private var _aSupportedActivatables:Array = [
				{ id: "_pagHelpHub",
					cls: HelpHub }
			];
				
		
		public function GetActivatableChild( id:String ):IActivatable {
			for (var i:int = 0; i < _aSupportedActivatables.length; i++) {
				if (_aSupportedActivatables[i].id == id) {
					var oac:Object = _aSupportedActivatables[i];
					if (!('instance' in oac)) {
						oac.instance = new oac.cls();
						oac.instance.id = ('instanceId' in oac) ? oac.instanceId : oac.id;
						oac.instance.includeInLayout = false;
						oac.instance.visible = false;
						this.addChild(oac.instance);	
					}
					return oac.instance;
				}
			}
			return null;
		}
	}		
}
