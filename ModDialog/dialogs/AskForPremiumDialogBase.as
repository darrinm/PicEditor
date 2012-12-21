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
package dialogs {
	import api.PicnikRpc;
	
	import bridges.ShareBridge;
	import bridges.email.EmailFriend;
	import bridges.email.EmailItemPicker;
	import bridges.storageservice.StorageServiceError;
	
	import com.adobe.crypto.MD5;
	
	import containers.ResizingDialog;
	
	import dialogs.BusyDialogBase;
	import dialogs.EasyDialog;
	import dialogs.EasyDialogBase;
	import dialogs.IBusyDialog;
	
	import events.ActiveDocumentEvent;
	
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.containers.ViewStack;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.ComboBox;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.resources.ResourceBundle;
	import mx.utils.StringUtil;
	
	import util.LocUtil;
	import util.RenderHelper;
	
	public class AskForPremiumDialogBase extends CloudyResizingDialog {
		// MXML-defined variables
		[Bindable] public var _itemPicker:EmailItemPicker;
		[Bindable] public var _tiFromEmail:TextInput;
		[Bindable] public var _tiFromName:TextInput;
		[Bindable] public var _tiToName:TextInput;
		[Bindable] public var _tiSubject:TextInput;
		[Bindable] public var _taMessage:TextArea;
		[Bindable] public var _btnSend:Button;
		[Bindable] public var _chkCcMe:CheckBox;
		[Bindable] public var _aContacts:Array;
		
   		[ResourceBundle("AskForPremiumDialogBase")] private var _rb:ResourceBundle;
		
		public var _aobSizes:Array;
		
		public var _strEmailSentNotifyMessage:String;
		public var _strInvalidEmailText:String;
		public var _strTooManyRecipients:String;

		public var _strLastUser:String;
		public var _bsy:IBusyDialog;
		
		public function AskForPremiumDialogBase() {
			super();
			
		}

		override protected function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.ESCAPE) {
				Hide();
			} else if (evt.keyCode == Keyboard.ENTER) {
			}
		}
		
		override protected function createChildren():void {
			super.createChildren();
			_btnSend.addEventListener(MouseEvent.CLICK, OnSendClick);
		}		
	
		private function PopulateFields(): void {
			if (!_tiFromName) return;
			
			var strUser:String = AccountMgr.GetInstance().GetUserAttribute("name") as String;
			
			// This handles the case where the user logs out. This prevents us from
			// leaving in the last user's email address in the From field.
			if (strUser != _strLastUser) {
				_strLastUser = strUser;
				_tiFromName.text = "";
				_tiFromEmail.text = "";
				_itemPicker.UnpickAllItems();
			}
			
			if (_tiFromEmail.text == "") {
				var strEmail:String = AccountMgr.GetInstance().GetUserAttribute("email") as String;
				if (strEmail != null)
					_tiFromEmail.text = strEmail;
			}

			// remove the previous selection
			LoadContacts();
		}	
		
		private function LoadContacts(): void {
			_aContacts = [];
			PicnikService.GetUserProperties("email_contacts", OnLoadContacts);
		}
		
		// obResults looks like { "contacts": [ { "name": <email>, "value": <name>, "updated": <date> }, ... ] }
		private function OnLoadContacts(err:Number, obResults:Object): void {
 			if (obResults && "email_contacts" in obResults) {
 				for (var strKey:String in obResults.email_contacts) { 					
 					var ef:EmailFriend = new EmailFriend();
 					ef.Restore( obResults.email_contacts[strKey].value );
 					_aContacts.push(ef);
 				}
 				_aContacts.sort( function( a:EmailFriend,b:EmailFriend ): Number {
 						return (a.email < b.email ? -1 : a.email == b.email ? 0 : 1);	
 					} );
 				_itemPicker.dataProvider = _aContacts;
 			}
		}
		
		private function SaveContacts(): void {
			var obPropValue:Object = {};
			for each (var friend:EmailFriend in _itemPicker.pickedItems) {				
				obPropValue[MD5.hash(friend.email)] = friend.Persist();
			}
			PicnikRpc.SetUserProperties(obPropValue, "email_contacts");
		}


		private function OnCancel(dctResult:Object): void {
			Hide();
		}

		private function OnSendClick(evt:MouseEvent): void {
			_bsy = BusyDialogBase.Show(this, "Sending", BusyDialogBase.EMAIL, "", 0.5, OnCancel);
			SaveContacts();
	
			var aToEmails:Array = [];
			var strToEmails:String = "";			
			for each (var friend:EmailFriend in _itemPicker.pickedItems) {
				aToEmails.push( friend.email );
			}
			strToEmails = aToEmails.join(",");
			
			var strUser:String =  AccountMgr.GetInstance().GetUserAttribute("name") as String;

			PicnikService.EmailAskForPicnik(
				_tiSubject.text ? _tiSubject.text : LocUtil.rbSubst('AskForPremiumDialogBase', 'defaultSubject', strUser),			
				_tiToName.text ? _tiToName.text : Resource.getString('AskForPremiumDialogBase', 'Santa'),
				strToEmails,
				_tiFromName.text ? _tiFromName.text : strUser,
				_tiFromEmail.text,
				_chkCcMe.selected ? _tiFromEmail.text : "",
				_taMessage.text ? _taMessage.text : null,
				OnEmailDone);				
		}
		

		private function OnEmailDone(err:Number, strError:String): void {
			// We go with the indeterminate progress indicator for now
			_bsy.Hide()
			_bsy = null;
			
			if (err == 0) {
				// Clear out any errors
				_tiFromEmail.errorString = null;				
				PicnikBase.app.Notify(Resource.getString('EmailShareBridge', '_strEmailSentNotifyMessage'));
				//ReportSuccess(null, "emailgallery");
				Hide();
			} else {
				if (err == PicnikService.errBadParams) {
					_tiFromEmail.errorString = _strInvalidEmailText;
					var dlg1:EasyDialog =
						EasyDialogBase.Show(
							PicnikBase.app,
							[Resource.getString('EmailShareBridge', 'ok')],
							Resource.getString("EmailShareBridge", "unable_to_send"),						
							_strInvalidEmailText );							
					
				} else if (err == PicnikService.errTooManyRecipients) {
					var dlg2:EasyDialog =
						EasyDialogBase.Show(
							PicnikBase.app,
							[Resource.getString('EmailShareBridge', 'ok')],
							Resource.getString("EmailShareBridge", "unable_to_send"),
							_strTooManyRecipients);							
				} else {				
					var dlg3:EasyDialog =
						EasyDialogBase.Show(
							PicnikBase.app,
							[Resource.getString('EmailShareBridge', 'ok')],
							Resource.getString("EmailShareBridge", "Error"),						
							Resource.getString("EmailShareBridge", "unable_to_send"));
				}
			}
		}		
	}
}
