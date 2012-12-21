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
	import com.adobe.crypto.MD5;
	
	import containers.ResizingDialog;
	
	import controls.NoTipTextInput;
	
	import dialogs.Purchase.PurchaseManager;
	import dialogs.Purchase.SubscriptionStatus;
	import dialogs.RegisterHelper.DataModel;
	
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
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.RadioButton;
	import mx.core.UIComponent;
	import mx.effects.Sequence;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.managers.PopUpManager;
	
	import util.KeyVault;
	
	public class CancelPaypalDialogBase extends CloudyResizingDialog
	{
		[Bindable] protected var updatingSubscriptionStatus:Boolean = false;
		[Bindable] protected var cancelOnly:Boolean = false;
		[Bindable] protected var renewall:Boolean = false;

		private var _cwPayPalActive:ChangeWatcher;
		private var _fnOnPayPalCancel:Function = null;
		
		public function CancelPaypalDialogBase() {
			super();
		}
		
		// obParams: optional: fnOnPayPalCancel = function(): void
		// fnOnPayPalCancel called after paypal is canceled.
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			super.Constructor(fnComplete, uicParent, obParams);
			_cwPayPalActive = ChangeWatcher.watch(SubscriptionStatus.GetInstance(), 'payPalActive', OnPayPalActiveChange);
			addEventListener(Event.ACTIVATE, OnActivate);
			if (obParams != null && 'fnOnPayPalCancel' in obParams)
				_fnOnPayPalCancel = obParams.fnOnPayPalCancel;
			cancelOnly = (_fnOnPayPalCancel == null);
			renewall = (obParams && 'fRenewall' in obParams && obParams.fRenewall);
		}
		
		private function OnPayPalActiveChange(evt:Event): void {
			if (!SubscriptionStatus.GetInstance().payPalActive) {
				// All done. Close the dialog and continue.
				Hide();
				if (_fnOnPayPalCancel != null)
					_fnOnPayPalCancel();
			}
		}
		
		private function OnActivate(evt:Event): void {
			if (updatingSubscriptionStatus)
				return;
			updatingSubscriptionStatus = true;
			SubscriptionStatus.Refresh(function(fSuccess:Boolean): void {
				updatingSubscriptionStatus = false;
			});
		}
		
		public override function Hide():void {
			super.Hide();
			_cwPayPalActive.unwatch();
		}
		
		override protected function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.ESCAPE) {
				Hide();
			} else if (evt.keyCode == Keyboard.ENTER) {
				LaunchPaypal();
			}
		}
		
		protected function LaunchPaypal(): void {
			var fSandbox:Boolean = String(KeyVault.GetInstance().paypal.sandbox).toLowerCase() == "true";
			var url:String = fSandbox ?
				'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_subscr-find&alias=paypal_1228944946_biz%40picnik%2ecom' :
				'https://www.paypal.com/cgi-bin/webscr?cmd=_subscr-find&alias=paypal%40picnik%2ecom';
			
			Util.UrchinLogNav('/dialog/order_paypal/cancel');				
			PicnikBase.app.NavigateToURLInPopup(url, 900, 768);
		}
	}
}
