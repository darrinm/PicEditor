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
package bridges.email {
	import api.PicnikRpc;
	
	import bridges.ShareBridge;
	import bridges.storageservice.StorageServiceError;
	
	import com.adobe.crypto.MD5;
	
	import controls.ResizingCheckbox;
	
	import dialogs.BusyDialogBase;
	import dialogs.EasyDialog;
	import dialogs.EasyDialogBase;
	import dialogs.IBusyDialog;
	
	import events.ActiveDocumentEvent;
	
	import flash.events.*;
	import flash.geom.Point;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.ComboBox;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
	import mx.utils.StringUtil;
	
	import util.LocUtil;
	import util.RenderHelper;
	
	public class EmailShareBridgeBase extends ShareBridge {
		// MXML-defined variables
		[Bindable] public var _tiName:TextInput;
		[Bindable] public var _itemPicker:EmailItemPicker;
		[Bindable] public var _tiFrom:TextInput;
		[Bindable] public var _tiSubject:TextInput;
		[Bindable] public var _taMessage:TextArea;
		[Bindable] public var _btnSend:Button;
		[Bindable] public var _cmboImageSize:ComboBox;
		[Bindable] public var _chkCcMe:ResizingCheckbox;
		[Bindable] public var _aContacts:Array;
		
		[Bindable] public var showShareButtons:Boolean = false;
		[Bindable] public var showImageSize:Boolean = false;
		[Bindable] public var itemIsShared:Boolean = false;

		[Bindable] public var paddingTop:int = 20;
		
		[Bindable] public var defaultSubject:String = null;
		[Bindable] public var defaultMessage:String = null;
		[Bindable] public var buttonLabel:String = null;

		[ResourceBundle("EmailShareBridge")] private var _rb:ResourceBundle;
		
		public var _aobSizes:Array;
		
		public var _strEmailSentNotifyMessage:String;
		public var _strInvalidEmailText:String;
		public var _strTooManyRecipients:String;

		public var _strLastUser:String;
		public var _bsy:IBusyDialog;
		
		private var _fItemIsReady:Boolean = false;
		
		public function EmailShareBridgeBase() {
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}

		[Bindable] public function set itemIsReady(f:Boolean): void {
			_fItemIsReady = f;
			if (!_fItemIsReady) {
				itemIsShared = false;
			}
		}
		public function get itemIsReady():Boolean {
			return _fItemIsReady;
		}
		
		private function OnCreationComplete(evt:FlexEvent):void {
			_btnSend.addEventListener(MouseEvent.CLICK, OnSendClick);
		}		

		override protected function GetHeadline():String {
			return itemIsShow ? Resource.getString("EmailShareBridge", "emailThisShow") :
						Resource.getString("EmailShareBridge", "emailThisPhoto");			
		}
		
		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd)
			
			var strUser:String = AccountMgr.GetInstance().GetUserAttribute("name") as String;
			
			// This handles the case where the user logs out. This prevents us from
			// leaving in the last user's email address in the From field.
			if (strUser != _strLastUser) {
				_strLastUser = strUser;
				_tiName.text = "";
				_tiFrom.text = "";
				_itemPicker.UnpickAllItems();
			}
			
			// Populate the input fields with probable text
			if (_tiName.text == "") {
				if (_tiName.text == "") {
					_tiName.text = strUser;
				}
			}

			if (_tiFrom.text == "") {
				var strEmail:String = AccountMgr.GetInstance().GetUserAttribute("email") as String;
				if (strEmail != null)
					_tiFrom.text = strEmail;
			}
			
			if (defaultSubject != null) {
				_tiSubject.text = defaultSubject;
			} else {
				_tiSubject.text = LocUtil.rbSubst('EmailShareBridge', 'defaultEmailSubject', item.title, AccountMgr.GetInstance().displayName)
			}
			
			if (defaultMessage != null) {
				_taMessage.text = defaultMessage;
			} else {
				_taMessage.text = Resource.getString('EmailShareBridge','defaultEmailBody');
			}
			
			if (buttonLabel != null) {
				_btnSend.label = buttonLabel;
			} else {
				_btnSend.label = Resource.getString('EmailShareBridge','_btnSend');
			}
			
			// remove the previous selection
			LoadContacts();
			
			// Initialize the ImageSize labels
			if (item) InitImageSizeDropDown();
			
			if (showShareButtons) {
				// kick off rendering (almost) right away so that the image is processed
				// and available when the sharing buttons are clicked. Otherwise
				// it becomes async and popups get blocked.
				var iidWaitForShow:int = setInterval(function():void {
						clearInterval(iidWaitForShow);
						RenderAsNecessary(null);
					}, 500);	
			}
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

		private function InitImageSizeDropDown(): void {
			if (item) {
				var aob:Array = new Array();
				for each (var ob:Object in _aobSizes) {
					if (ob.data < Math.max(item.width, item.height)) {
						var pt:Point = GetConstrainedProportions(ob.data);		
						var strLabel:String = StringUtil.substitute( Resource.getString("EmailOutBridge", "image_size_label"), ob.label, pt.x, pt.y );
						aob.push({label: strLabel, data:ob.data});
					}
				}
				_cmboImageSize.dataProvider = aob;
			}
		}
		
		private function GetConstrainedProportions(cxyMax:Number): Point {
			if (cxyMax <= 0) return new Point(item.width, item.height);
			var xw:Number = item.width;
			var yw:Number = item.height;
			var cxy:Number = cxyMax;
			var nScaleFactor:Number = cxyMax/Math.max(item.width, item.height);
			if (nScaleFactor > 1) nScaleFactor = 1;
			var cy:Number = Math.floor(item.height * nScaleFactor);
			var cx:Number = Math.floor(item.width * nScaleFactor);
			if (cx < 1) cx = 1;
			if (cy < 1) cy = 1;
			return new Point(cx, cy);
		}
		
		private function OnSendClick(evt:MouseEvent): void {
			_bsy = BusyDialogBase.Show(this, "Sending", BusyDialogBase.EMAIL, "", 0.5, OnBusyCancel);
			SaveContacts();
	
			RenderAsNecessary( function():void {
					var aToEmails:Array = [];
					var strToEmails:String = "";			
					for each (var friend:EmailFriend in _itemPicker.pickedItems) {
						aToEmails.push( friend.email );
					}
					strToEmails = aToEmails.join(",");
					
					if (item && item.species == "gallery") {
						PicnikService.EmailGallery(item.id, item.secret,
							strToEmails,
							strToEmails,
							_tiName.text ? _tiName.text : null,
							_tiFrom.text,
							_chkCcMe.selected ? _tiFrom.text : "",
							_tiSubject.text ? _tiSubject.text : null,
							_taMessage.text ? _taMessage.text : null,
							OnEmailDone);
							
						PicnikService.Log("EmailShareBridgeBase sending show" + item.title +
								", from: " + _tiFrom.text + ", to: " + strToEmails + ", subject: " + _tiSubject.text +
								", message?: " + (_taMessage.text ? "yes" : "no") );

					} else if (item && item.species == "greeting") {
						PicnikService.EmailGreeting(item.id, item.secret,
							strToEmails,
							strToEmails,
							_tiName.text ? _tiName.text : null,
							_tiFrom.text,
							_chkCcMe.selected ? _tiFrom.text : "",
							_tiSubject.text ? _tiSubject.text : null,
							_taMessage.text ? _taMessage.text : null,
							OnEmailDone);
						
						PicnikService.Log("EmailShareBridgeBase sending greeting" + item.title +
							", from: " + _tiFrom.text + ", to: " + strToEmails + ", subject: " + _tiSubject.text +
							", message?: " + (_taMessage.text ? "yes" : "no") );
					} else {
						OnEmailDone( PicnikService.errBadParams, "" );
					}
				} );
		}

		private function OnBusyCancel(dctResult:Object): void {
			CancelRender();
		}

		private function OnEmailDone(err:Number, strError:String): void {
			// We go with the indeterminate progress indicator for now
			_bsy.Hide()
			_bsy = null;
			
			if (err == 0) {
				// Clear out any errors
				_tiFrom.errorString = null;				
				PicnikBase.app.Notify(Resource.getString('EmailShareBridge', '_strEmailSentNotifyMessage'));
				ReportSuccess("email" + item.species);
				itemIsShared = true;
			} else {
				if (err == PicnikService.errBadParams) {
					_tiFrom.errorString = _strInvalidEmailText;
					var dlg1:EasyDialog =
						EasyDialogBase.Show(
							PicnikBase.app,
							[Resource.getString('EmailShareBridge', 'ok')],
							Resource.getString("EmailShareBridge", "unable_to_send"),						
							_strInvalidEmailText
						);							
					
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
			if (container) {
				container.Hide();
			}
		}	
		
		protected function DoBuzzShare(): void {
			RenderAsNecessary( function():void {
					if (item) {
						var strUrl:String = item.webpageurl;
						var strMsg:String = item.title;
						PicnikBase.app.ShareOnBuzz(strMsg, strUrl);
						itemIsShared = true;
						ReportSuccess("buzz" + item.species);

					}
				});
			}

		protected function DoFacebookShare(): void {
			RenderAsNecessary( function():void {
				if (item) {
					var strUrl:String = item.webpageurl;
					var strMsg:String = item.title;
					PicnikBase.app.ShareOnFacebook(strMsg, strUrl);
					itemIsShared = true;
					ReportSuccess("facebook" + item.species);
				}
			});
		}

		protected function DoTwitterShare(): void {
			RenderAsNecessary( function():void {
				if (item) {
					var strUrl:String = item.webpageurl;
					var strMsg:String = item.title;
					PicnikBase.app.ShareOnTwitter(strMsg, strUrl);
					itemIsShared = true;
					ReportSuccess("twitter" + item.species);
				}
			});
		}
	}
}
