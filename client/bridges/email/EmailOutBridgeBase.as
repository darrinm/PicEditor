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
	
	import bridges.OutBridge;
	import bridges.storageservice.StorageServiceError;
	
	import com.adobe.crypto.MD5;
	
	import dialogs.BusyDialogBase;
	import dialogs.EasyDialog;
	import dialogs.EasyDialogBase;
	import dialogs.IBusyDialog;
	
	import events.ActiveDocumentEvent;
	
	import flash.events.*;
	import flash.geom.Point;
	
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.ComboBox;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
	import mx.utils.StringUtil;
	
	import util.RenderHelper;
	
	public class EmailOutBridgeBase extends OutBridge {
		// MXML-defined variables
		[Bindable] public var _tiName:TextInput;
		[Bindable] public var _itemPicker:EmailItemPicker;
		[Bindable] public var _tiFrom:TextInput;
		[Bindable] public var _tiSubject:TextInput;
		[Bindable] public var _taMessage:TextArea;
		[Bindable] public var _btnSend:Button;
		[Bindable] public var _imgPreview:ImageView;
		[Bindable] public var _cmboImageSize:ComboBox;
		[Bindable] public var _chkCcMe:CheckBox;
		[Bindable] public var _aContacts:Array;
		
   		[ResourceBundle("EmailOutBridge")] private var _rb:ResourceBundle;
		
		public var _aobSizes:Array;
		
		public var _strEmailSentNotifyMessage:String;
		public var _strInvalidEmailText:String;
		public var _strTooManyRecipients:String;

		public var _strLastUser:String;
		public var _bsy:IBusyDialog;
		
		public function EmailOutBridgeBase() {
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}

		private function OnCreationComplete(evt:FlexEvent):void {
			_btnSend.addEventListener(MouseEvent.CLICK, OnSendClick);
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

			// remove the previous selection
			LoadContacts();
			
			// Initialize the ImageSize labels
			if (_imgd) InitImageSizeDropDown();
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

		protected override function OnActiveDocumentChange(evt:ActiveDocumentEvent): void {
			super.OnActiveDocumentChange(evt);
			InitImageSizeDropDown();
		}
		
		private function InitImageSizeDropDown(): void {
			if (_imgd) {
				var aob:Array = new Array();
				for each (var ob:Object in _aobSizes) {
					if (ob.data < Math.max(_imgd.width, _imgd.height)) {
						var pt:Point = GetConstrainedProportions(ob.data);		
						var strLabel:String = StringUtil.substitute( Resource.getString("EmailOutBridge", "image_size_label"), ob.label, pt.x, pt.y );
						aob.push({label: strLabel, data:ob.data});
					}
				}
				_cmboImageSize.dataProvider = aob;
			}
		}
				
		private function OnSendClick(evt:MouseEvent): void {
			_bsy = BusyDialogBase.Show(this, "Sending", BusyDialogBase.EMAIL, "", 0.5, OnCancel);
			var cxDim:Number = _cmboImageSize.selectedItem.data;
			var cyDim:Number = cxDim;
			if (cxDim == 0) cxDim = _imgd.width;
			if (cyDim == 0) cyDim = _imgd.height;
			
			SaveContacts();
			
			var aToEmails:Array = [];
			var strToEmails:String = "";			
			for each (var friend:EmailFriend in _itemPicker.pickedItems) {
				aToEmails.push( friend.email );
			}
			strToEmails = aToEmails.join(",");
			
			new RenderHelper(_imgd, OnEmailDone, _bsy).Email(strToEmails,strToEmails,
					_tiName.text ? _tiName.text : null, _tiFrom.text,
					_chkCcMe.selected ? _tiFrom.text : "",
					_tiSubject.text ? _tiSubject.text : null,
					_taMessage.text ? _taMessage.text : null,
					cxDim, cyDim, "Email");
					
			PicnikService.Log("EmailOutBridge sending " + _imgd.properties.title +
					", from: " + _tiFrom.text + ", to: " + strToEmails + ", subject: " + _tiSubject.text +
					", message?: " + (_taMessage.text ? "yes" : "no") + ", width: " + cxDim + ", height: " + cyDim);
		}

		private function OnCancel(dctResult:Object): void {
		}

		private function OnEmailDone(err:Number, strError:String, strPikId:String=null): void {
			// We go with the indeterminate progress indicator for now
			_bsy.Hide()
			_bsy = null;
			
			if (err == 0) {
				// Clear out any errors
				_tiFrom.errorString = null;
				
				if (_imgd) {
					// if the user hits cancel on the progress dlg and then navigates away,
					// then OnDeactivate will set _imgd to null.  That's why we check for _imgd first.
					_imgd.isDirty = false;

					var imgpSaveProps:ImageProperties = new ImageProperties;
					_imgd.properties.CopyTo(imgpSaveProps);
					imgpSaveProps./*bridge*/serviceid = "email";
					_imgd.lastSaveInfo = imgpSaveProps;
				}
				
				PicnikBase.app.Notify(_strEmailSentNotifyMessage, 1000);
				ReportSuccess(null, "email");
				PicnikBase.app.NavigateToService(PicnikBase.OUT_BRIDGES_TAB, "postsave");
			} else {
				if (err == StorageServiceError.ChildObjectFailedToLoad) {
					DisplayCouldNotProcessChildrenError();					
				} else if (err == PicnikService.errBadParams) {
					_tiFrom.errorString = _strInvalidEmailText;
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
		
		private function GetConstrainedProportions(cxyMax:Number): Point {
			if (cxyMax <= 0) return new Point(_imgd.width, _imgd.height);
			var xw:Number = _imgd.width;
			var yw:Number = _imgd.height;
			var cxy:Number = cxyMax;
			var nScaleFactor:Number = cxyMax/Math.max(_imgd.width, _imgd.height);
			if (nScaleFactor > 1) nScaleFactor = 1;
			var cy:Number = Math.floor(_imgd.height * nScaleFactor);
			var cx:Number = Math.floor(_imgd.width * nScaleFactor);
			if (cx < 1) cx = 1;
			if (cy < 1) cy = 1;
			return new Point(cx, cy);
		}
	}
}