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
package dialogs
{
	import api.PicnikRpc;
	
	import bridges.email.EmailFriend;
	import bridges.email.EmailItemPicker;
	
	import com.adobe.crypto.MD5;
	
	import containers.ResizingDialog;
	
	import controls.ResizingButton;
	
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	import mx.resources.ResourceBundle;
	
	public class PartyInviteDialogBase extends CloudyResizingDialog
	{
		[Bindable] public var _aContacts:Array;
		[Bindable] public var _itemPicker:EmailItemPicker;
		[Bindable] public var _tiFromName:TextInput;
		[Bindable] public var _tiFromEmail:TextInput;
		[Bindable] public var _tiLocation:TextInput;
		[Bindable] public var _tiDate:TextInput;
		[Bindable] public var _tiTime:TextInput;
		[Bindable] public var _tiRsvpDate:TextInput;
		[Bindable] public var _btnSend:ResizingButton;

		// Params to carry forward to old upsell path
		private var _obDefaults:Object;
		private var _bsy:IBusyDialog;
				
		public var _strEmailSentNotifyMessage:String;
		public var _strInvalidEmailText:String;
		public var _strTooManyRecipients:String;
						
		[Bindable] public var firstRunMode:Boolean = false;

  		[Bindable] [ResourceBundle("PartyInviteDialogBase")] protected var _rb:ResourceBundle;
		
		override protected function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.ESCAPE) {
				Hide();
			} else if (evt.keyCode == Keyboard.ENTER) {
				
			}
		}
				
		private function OnSendClick( evt:MouseEvent ): void {
			_bsy = BusyDialogBase.Show(this, "Sending", BusyDialogBase.EMAIL, "", 0.5, OnCancel);		
			SaveContacts();
			
			var aToEmails:Array = [];
			var strToEmails:String = "";			
			for each (var friend:EmailFriend in _itemPicker.pickedItems) {
				aToEmails.push( friend.email );
			}
			strToEmails = aToEmails.join(",");
			
			PicnikService.EmailPartyInvite(strToEmails, _tiFromName.text, _tiFromEmail.text,
										 Resource.getString('PartyInviteDialogBase','emailSubject'),
										 _tiLocation.text, _tiDate.text, _tiTime.text,
										 _tiRsvpDate.text, OnEmailDone );			
		}
		

		private function OnCancel(dctResult:Object): void {
		}

		private function OnEmailDone(err:Number, strError:String): void {
			// We go with the indeterminate progress indicator for now
			_bsy.Hide()
			_bsy = null;
			
			if (err == 0) {
				PicnikBase.app.Notify(_strEmailSentNotifyMessage, 1000);
				Hide();
			} else {
				if (err == PicnikService.errBadParams) {
					_tiFromEmail.errorString = _strInvalidEmailText;
					var dlg1:EasyDialog =
						EasyDialogBase.Show(
							PicnikBase.app,
							[Resource.getString('EmailOutBridge', 'ok')],
							Resource.getString("EmailOutBridge", "unable_to_send"),						
							_strInvalidEmailText);							
					
				} else if (err == PicnikService.errTooManyRecipients) {
					var dlg2:EasyDialog =
						EasyDialogBase.Show(
							PicnikBase.app,
							[Resource.getString('EmailOutBridge', 'ok')],
							Resource.getString("EmailOutBridge", "unable_to_send"),
							_strTooManyRecipients);							
				} else {				
					var dlg3:EasyDialog =
						EasyDialogBase.Show(
							PicnikBase.app,
							[Resource.getString('EmailOutBridge', 'ok')],
							Resource.getString("EmailOutBridge", "Error"),						
							Resource.getString("EmailOutBridge", "unable_to_send"));
				}
			}

		}		
		
		override protected function OnShow(): void {
			super.OnShow();

			_btnSend.addEventListener(MouseEvent.CLICK, OnSendClick);
			
			var strUser:String = AccountMgr.GetInstance().GetUserAttribute("name") as String;
			
			_itemPicker.UnpickAllItems();
			
			// Populate the input fields with probable text			
			_tiFromName.text = strUser;
			var strEmail:String = AccountMgr.GetInstance().GetUserAttribute("email") as String;
			if (strEmail != null) {
				_tiFromEmail.text = strEmail;
			} else {
				_tiFromEmail.text = "";
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
		
		override protected function OnHide(): void {
			_btnSend.removeEventListener(MouseEvent.CLICK, OnSendClick );
			super.OnHide();
		}
	}
}
