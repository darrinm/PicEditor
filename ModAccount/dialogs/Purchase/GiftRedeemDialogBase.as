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
    import controls.ResizingText;
   
    import dialogs.CloudyResizingDialog;
    import dialogs.DialogManager;
    import dialogs.EasyDialog;
    import dialogs.EasyDialogBase;
    import dialogs.RegisterDialogBase;
   
    import flash.events.KeyboardEvent;
    import flash.ui.Keyboard;
   
    import mx.controls.CheckBox;
    import mx.core.UIComponent;
    import mx.effects.Sequence;
    import mx.resources.ResourceBundle;
   
    import util.GiftDetails;
    import util.LocUtil;
	
	public class GiftRedeemDialogBase extends CloudyResizingDialog
	{
		[Bindable] public var _strSuccessFeedbackMessage:String;
		[Bindable] public var _effError:Sequence;
		[Bindable] public var _tiGiftCode:NoTipTextInput;
		[Bindable] public var _txtGiftCodeError:ResizingText;
		[Bindable] public var _cbReturnToPaymentSelector:CheckBox;
		[Bindable] public var gift:GiftDetails;
		
   		[Bindable] [ResourceBundle("RedeemGiftTab")] protected var rb:ResourceBundle;
		
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			if ('gift' in obParams) {
				gift = obParams['gift'] as GiftDetails;
			}
			if (!gift) {
				gift = new GiftDetails();
			}
			if ('giftCode' in obParams) {
				gift.strGiftCode = obParams['giftCode'];
			}
			super.Constructor(fnComplete, uicParent, obParams);
		}
		
		public function GiftRedeemDialogBase():void {
		}
		
		public function Redeem(): void {
			_txtGiftCodeError.text = "";
			if (_tiGiftCode.text.length == 0) {
				_txtGiftCodeError.text = Resource.getString("RedeemGiftTab", "errEmpty");
			} else {
				ShowBusy();
				PicnikService.ValidateGiftCode( _tiGiftCode.text, true, OnRedeemed );
			}			
		}		
		
		public function OnRedeemed(err:Number, strError:String, obPassThrough:Object = null): void {
			HideBusy();
			if (err == PicnikService.errNone) {
				AccountMgr.GetInstance().RefreshUserAttributes( function():void {
						// when this refresh is done, we expect the user to be premium
						if (!AccountMgr.GetInstance().isPremium) {
							PicnikService.Log( "Postpurchase user not premium (RedeemGiftTabBase)" + AccountMgr.GetInstance().userId, PicnikService.knLogSeverityMonitor );
						}						
					});
				Hide();
				PicnikBase.app.FloatBalloons();
				EasyDialogBase.Show(PicnikBase.app,
						[Resource.getString('RedeemGiftTab', 'getPicniking')],
						Resource.getString('RedeemGiftTab', 'welcomeTitle'),
						Resource.getString('RedeemGiftTab', 'text', [LocUtil.shortDate(AccountMgr.GetInstance().dateSubscriptionExpires)]));
			} else {				
				if (err == PicnikService.errUserAlreadyPaid) {
					_txtGiftCodeError.text = Resource.getString("RedeemGiftTab", "errAlreadyPremium");					
				} else if (err == PicnikService.errGiftCodeAlreadyUsed) {
					_txtGiftCodeError.text = Resource.getString("RedeemGiftTab", "errUsed");					
				} else {
					_txtGiftCodeError.text = Resource.getString("RedeemGiftTab", "errBadCode");
				}
			}
		}
		
		public function Cancel(): void {
			Hide();
		}	

		public function Close(): void {
			_txtGiftCodeError.text = "";
			Hide();
		}	

		public function RedeemKeyEvent(evt:KeyboardEvent):void
		{
			if (evt.keyCode != Keyboard.ESCAPE && evt.keyCode != Keyboard.TAB && evt.keyCode != Keyboard.SPACE)
				Redeem();
		}
		
	}
}
