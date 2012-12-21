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
package dialogs.Purchase
{
    import controls.NoTipTextInput;
    import controls.TextAreaPlus;
   
    import dialogs.*;
    import dialogs.RegisterHelper.DataModel;
   
    import flash.events.KeyboardEvent;
    import flash.ui.Keyboard;
   
    import mx.controls.CheckBox;
    import mx.controls.TabBar;
    import mx.controls.Text;
    import mx.core.UIComponent;
    import mx.effects.Sequence;
    import mx.printing.FlexPrintJob;
    import mx.printing.FlexPrintJobScaleType;
    import mx.resources.ResourceBundle;
   
    import util.CreditCardTransaction;
    import util.GiftDetails;
	
	public class GiftPrintEmailDialogBase extends CloudyResizingDialog
	{
		[Bindable] public var _strSuccessFeedbackMessage:String;
		[Bindable] public var _effError:Sequence;
		[Bindable] public var _tiToName:NoTipTextInput;
		[Bindable] public var _tiFromName:NoTipTextInput;
		[Bindable] public var _tiToEmail:NoTipTextInput;
		[Bindable] public var _tiFromEmail:NoTipTextInput;
		[Bindable] public var _cbAnonymous:CheckBox;
		[Bindable] public var _taMessage:TextAreaPlus;
		[Bindable] public var _lblFormError:Text;
		[Bindable] public var _tabBar:TabBar;
		[Bindable] public var _gcp:GiftCardPrinter;

		[Bindable] public var _strToName:String;
		[Bindable] public var _strToEmail:String;
		[Bindable] public var _strFromName:String;
		[Bindable] public var _strFromEmail:String;
		[Bindable] public var _fAnonymous:Boolean;
		[Bindable] public var _strMessage:String;
		
		[Bindable] public var cct:CreditCardTransaction;		
		[Bindable] public var gift:GiftDetails = null;
		
		protected var _bsy:IBusyDialog;
		
   		[Bindable] [ResourceBundle("CreateGiftTab")] protected var rb:ResourceBundle;

		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			if ('cct' in obParams) {
				cct = obParams['cct'] as CreditCardTransaction;
			}
			if ('gift' in obParams) {
				gift = obParams['gift'] as GiftDetails;
			}
			if (!gift) {
				gift = new GiftDetails();
			}
			if ('giftCode' in obParams) {
				gift.strGiftCode = obParams['giftCode'];
			} else if (cct && !gift.strGiftCode) {
				gift.strGiftCode = cct.strGiftCode;
			}
			super.Constructor(fnComplete, uicParent, obParams);
		}
		
		public function GiftPrintEmailDialogBase():void {
		}				

		public function get toEmail(): String {
			return GetFieldValue("toEmail") as String;
		}
		
		public function get fromEmail(): String {
			return GetFieldValue("fromEmail") as String;
		}
		
		public function get toName(): String {
			return GetFieldValue("toName") as String;
		}
		
		public function get fromName(): String {
			return GetFieldValue("fromName") as String;
		}
		
		private function get anonymous(): Boolean {
			return GetFieldValue("anonymous") as Boolean;
		}
		
		private function get message(): String {
			return GetFieldValue("message") as String;
		}		
		
		public function Create(): void {
			if (Validate()) {

				gift.strToName = toName;
				gift.strFromName = fromName;
				gift.strToEmail = toEmail;
				gift.strFromEmail = fromEmail;
				gift.fAnonymous = anonymous;
				gift.strMessage = message;
								
				if (_tabBar.selectedIndex == 0) {
					_gcp.Print(gift);
				} else if (_tabBar.selectedIndex == 1) {
					// send an email
					_bsy = BusyDialogBase.Show(this, Resource.getString("CreateGiftTab", "sending"), BusyDialogBase.OTHER, "IndeterminateNoCancel", 0);					
					PicnikService.EmailGift(
							Resource.getString("CreateGiftTab", "giftEmailSubject"),
							gift.strToName,
							gift.strToEmail,
							gift.strFromName,
							gift.strFromEmail,
							gift.strMessage,
							gift.strGiftCode, OnEmailDone );
					
				}
			}
		}		
		
		public function OnEmailDone( err:Number, strErr: String = ""):void {
			if (_bsy != null) {			
				_bsy.Hide();
				if (err == PicnikService.errNone) {
					var dlg1:EasyDialog =
						EasyDialogBase.Show(
							this,
							[Resource.getString('CreateGiftTab', 'ok')],
							Resource.getString('CreateGiftTab', 'email_sent_title'),						
							Resource.getString('CreateGiftTab', 'email_sent_message'));							
				} else {
					var dlg2:EasyDialog =
						EasyDialogBase.Show(
							this,
							[Resource.getString('CreateGiftTab', 'ok')],
							Resource.getString('CreateGiftTab', 'email_error_title'),						
							Resource.getString('CreateGiftTab', 'email_error_message'));												
				}
			}			
		}
		
		public function Cancel(): void {
			Hide();
		}	
		
		public function OnOrderAgain(): void {
			Hide();
			gift.strToEmail = "";
			gift.strToName  = "";
			gift.strGiftCode = "";
			
			var obParams:Object = {
				strSourceEvent: "orderagain",
				gift:gift };
		
			// TODO: make sure these params get plumbed through properly
			DialogManager.Show("PurchaseGiftDialog", null, null, obParams);
		}		

		// Data modeling functions
		protected function get dataModel(): DataModel {
			if ("_dtmFormFields" in this) return this["_dtmFormFields"] as DataModel;
			else return null; // Not found. Error.
		}
		
		protected function GetFieldValue(strFieldName:String): Object {
			return dataModel.GetValue(strFieldName);
		}

		
		// User clicked a button (etc) to submit the form
		public function Validate(): Boolean {
			var fValid:Boolean = dataModel.validateAll();
			//fire error glow effect
			if (!fValid) {
				_lblFormError.includeInLayout = true;
				_lblFormError.visible = true;
				_lblFormError.text = Resource.getString('CreateGiftTab', 'formError');
				_effError.end();
				_effError.play();
			}
			return fValid;
		}		

		public function CreateKeyEvent(evt:KeyboardEvent):void {
			if (evt.keyCode != Keyboard.ESCAPE && evt.keyCode != Keyboard.TAB && evt.keyCode != Keyboard.SPACE)
				Create();
		}
		
	}
}
