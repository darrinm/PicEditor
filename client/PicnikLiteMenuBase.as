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
	import containers.ResizingDialog;
	
	import dialogs.DialogManager;
	
	import flash.events.MouseEvent;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	
	import util.LocUtil;
	import util.SessionTransfer;

	public class PicnikLiteMenuBase extends HelpMenuBase {
		// When a menu item is clicked, remove the menu and invoke the appropriate dialog
		override protected function OnItemClick(evt:MouseEvent): void {
			PopUpManager.removePopUp(this);
			
			switch (evt.target.name) {
			case "help":
				if (PicnikBase.app._pas.googlePlusUI)
					PicnikBase.app.NavigateToURLInPopup("http://www.google.com/support/+/?hl=" + LocUtil.PicnikLocToGoogleLoc() + "&p=photo_editing", 800, 600);
				else
					DialogManager.Show("HelpDialog", null, null);
				break;
			
			case "settings":
				DialogManager.Show("SettingsDialog", null, null);
				break;
			
			case "contact":
			case "about":
				DialogManager.Show("HelpDialog", null, null, {navigate:evt.target.name});
				break;
				
			case "signIn":
				DialogManager.ShowLogin(UIComponent(Application.application));
				break;
				
			case "register":
				DialogManager.ShowRegister(UIComponent(Application.application));
				break;
				
			case "signOut":
				PicnikBase.app.SafeSignOut(function(fSuccess:Boolean):void {
					if (fSuccess) PicnikBase.app.LiteUICancel();
				}, true );
				break;
				
			case "fullscreen":
				PicnikBase.app._wndc.ToggleFullscreen();
				break;
				
			case "upgrade":
				DialogManager.ShowUpgrade("/flickr_menu", UIComponent(Application.application));
				break;
				
			case "gift":
				DialogManager.ShowGiveGift("/flickr_menu", UIComponent(Application.application));
				break;
				
			case "openinpicnik":
				SessionTransfer.TransferSession();
				break;
				
			case "german":
				PicnikBase.app.SwitchLocale("de_DE");
				break;
				
			case "english":
				PicnikBase.app.SwitchLocale("en_US");
				break;
			}
		}
	}
}
