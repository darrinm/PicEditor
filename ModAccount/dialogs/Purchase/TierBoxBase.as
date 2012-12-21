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
	import containers.InfoWindow;
	
	import controls.ImageEx;
	import controls.NoTipTextInput;
	import controls.PicnikMenu;
	import controls.PicnikMenuItem;
	import controls.ResizingButton;
	import controls.ResizingLabel;
	import controls.ResizingText;
	
	import dialogs.BusyDialogBase;
	import dialogs.ChangeEmailDialog;
	import dialogs.DialogManager;
	import dialogs.EasyDialog;
	import dialogs.EasyDialogBase;
	import dialogs.IBusyDialog;
	import dialogs.RegisterDialog;
	import dialogs.RegisterHelper.DataField;
	import dialogs.RegisterHelper.DataModel;
	import dialogs.RegisterHelper.UpgradePathTracker;
	
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Point;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.containers.Box;
	import mx.containers.Canvas;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	import mx.controls.RadioButton;
	import mx.controls.Text;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	import mx.effects.Sequence;
	import mx.events.FlexEvent;
	import mx.events.ItemClickEvent;
	import mx.events.ValidationResultEvent;
	import mx.formatters.NumberBaseRoundType;
	import mx.formatters.NumberFormatter;
	import mx.managers.PopUpManager;
	import mx.validators.ValidationResult;
	
	import picnik.util.LocaleInfo;
	
	import util.AdManager;
	import util.CreditCard;
	import util.CreditCardTransaction;
	import util.LocUtil;
	import util.PicnikAlert;
	import util.UserBucketManager;
	
	import validators.PicnikCreditCardValidator;
	import validators.PicnikPhoneNumberValidator;
	import validators.PicnikStringValidator;
	
	public class TierBoxBase extends Canvas
	{
		[Event(name="change", type="Dialogs.Purchase.PurchaseEvent")]

		private var _adctCurrencies:Array = [
			{name:'USD', label:'US dollars', rate:1, symbol:'$'},
			{name:'EUR', label:'Euros', rate:0, symbol:'€'},
			{name:'CAD', label:'CDN Dollars', rate:0, symbol:'C$'},
			{name:'MXN', label:'Pesos', rate:0, symbol:'$'},
			{name:'GBP', label:'Pounds', rate:0, symbol:'£'},
			{name:'JPY', label:'Yen', rate:0, symbol:'¥'},			
			{name:'BRL', label:'Reais', rate:0, symbol:'R$'}
		];
		private var _mnuItems:PicnikMenu = new PicnikMenu();			
		private var _obCurrency:Object;
		
		[Bindable] public var _btnCurrency:ResizingButton;
		[Bindable] public var _radio1month:RadioButton;
		[Bindable] public var _radio6month:RadioButton;
		[Bindable] public var _radio12month:RadioButton;
		[Bindable] public var _lblOneMonthNote:ResizingLabel;
		[Bindable] public var _lblSixMonthNote:ResizingLabel;
		[Bindable] public var _lbl12MonthNote:ResizingLabel;
		[Bindable] public var _rlOneMonthPrice:ResizingLabel;
		[Bindable] public var _rlSixMonthPrice:ResizingLabel;
		[Bindable] public var _rl12MonthPrice:ResizingLabel;
		
		[Bindable] public var nMonths:int = 0;
		[Bindable] public var nPrice:Number = 0;
		[Bindable] public var strPrice:String = "";
		[Bindable] public var strDescription:String = "";
		[Bindable] public var hideTiers:Boolean = false;
		

		private var _strSelectedSku:String = null;	// passed in from the outside
		private var _strOriginalSku:String = null;	// passed in from the outside

		public function TierBoxBase()  {	
			addEventListener(FlexEvent.INITIALIZE, OnInit);

			var ldr:URLLoader = new URLLoader();
			
			var fnError:Function = function(evt:Event): void {
				trace("currency load error: " + evt);
			}
			
			var fnComplete:Function = function(evt:Event): void {
				var strXML:String = String(ldr.data);
				var xmlCurrencies:XML = new XML(strXML);
				InitCurrencies(xmlCurrencies);
			}
			
			// init menu to include USD. The others will get added later
			_mnuItems._acobMenuItems = new ArrayCollection();
			_mnuItems._acobMenuItems.addItem(new PicnikMenuItem('USD', _adctCurrencies[0]));
			
			ldr.addEventListener(Event.COMPLETE, fnComplete);
			ldr.addEventListener(IOErrorEvent.IO_ERROR, fnError);
			ldr.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnError);
			ldr.load(new URLRequest(PicnikService.serverURL + "/currencyxml"));
		}
		
		[Bindable]
		public function set selectedSku(strSkuId:String): void {
			_strSelectedSku = strSkuId;
			nPrice = CreditCardTransaction.GetPriceFromSkuId(strSkuId);
			SetCurrency();
		}
		
		public function get selectedSku(): String {
			return _strSelectedSku;
		}
		
		[Bindable]
		public function set originalSku(strSkuId:String): void {
			_strOriginalSku = strSkuId;
			SetCurrency();
		}
		
		public function get originalSku(): String {
			return _strOriginalSku;
		}
		
		public function OnCurrencyClick(): void {
			_mnuItems.addEventListener(ItemClickEvent.ITEM_CLICK, OnCurrencyMenuClick);
			_mnuItems.Show(_btnCurrency);
		}
		
		public function OnCurrencyMenuClick(evt:ItemClickEvent):void {
			SetCurrency(evt.item);
		}
		
		public function OnInit(evt:Event):void {
			SetCurrency({rate:1, symbol:'$', name:'USD'});
		}
		
		public function FormatCurrency(nPrice:Number):String
		{
			var nRate:Number = Number(_obCurrency.rate);
			var n:Number;
			var nf:NumberFormatter = new mx.formatters.NumberFormatter;
			nf.precision = 2;
			nf.rounding = NumberBaseRoundType.UP;
			n = nRate * nPrice;
			if (n > 100)
				nf.precision = 0;	
			return _obCurrency.symbol + nf.format(n);
		}
		
		public function SetCurrency(oCurrency:Object = null):void
		{
			if (oCurrency) {
				_obCurrency = oCurrency;
			}
			
			// Update the menu label
			_btnCurrency.label = _obCurrency.symbol + ' ' + _obCurrency.name;
			
			// Update Prices
			if (_radio1month != null) {
				strPrice = FormatCurrency( nPrice );
				
				var lblCurrent:Label = null;
				
				_rlOneMonthPrice.htmlText = FormatCurrency(CreditCardTransaction.GetPriceFromSkuId(CreditCardTransaction.kSkuOneMonth));
				if (originalSku == CreditCardTransaction.kSkuOneMonth) {
					lblCurrent = _lblOneMonthNote;
				} else {
					_lblOneMonthNote.htmlText = Resource.getString("PurchaseDialog", "oneMonthNote2",
						[FormatCurrency(CreditCardTransaction.GetPriceFromSkuId(CreditCardTransaction.kSkuOneMonth))]);					
					_lblOneMonthNote.setStyle('color', '#618430');
				}
				
				_rlSixMonthPrice.htmlText = FormatCurrency(CreditCardTransaction.GetPriceFromSkuId(CreditCardTransaction.kSkuSixMonths));
				_lblSixMonthNote.htmlText = Resource.getString("PurchaseDialog", "sixMonthNote2");
				if (originalSku == CreditCardTransaction.kSkuSixMonths) {
					lblCurrent = _lblSixMonthNote;
				} else {
					_lblSixMonthNote.htmlText = Resource.getString("PurchaseDialog", "sixMonthNote2");
					_lblSixMonthNote.setStyle('color', '#618430');
				}
				
				_rl12MonthPrice.htmlText = FormatCurrency(CreditCardTransaction.GetPriceFromSkuId(CreditCardTransaction.kSku12Months));
				if (originalSku == CreditCardTransaction.kSku12Months) {
					lblCurrent = _lbl12MonthNote;
				} else {
					_lbl12MonthNote.htmlText = Resource.getString("PurchaseDialog", "oneYearNote2");
					_lbl12MonthNote.setStyle('color', '#618430');
				}
				
				if (lblCurrent) {
					lblCurrent.htmlText = Resource.getString("PurchaseDialog", "current");
					lblCurrent.setStyle('color', '#005580');					
				}
				
			} else {
				strPrice = FormatCurrency( CreditCardTransaction.GetPriceFromSkuId(CreditCardTransaction.kSku12Months) );
			}
		}
		
		private function formatCurrencyMenuItem(obCurrency:Object):String
		{
			return obCurrency.symbol + " " + obCurrency.name;	
		}	
		
		private function InitCurrencies(xml:XML):void
		{
			// Clear the menu of items
			_mnuItems._acobMenuItems = new ArrayCollection();
			_mnuItems._acobMenuItems.addItem(new PicnikMenuItem(formatCurrencyMenuItem(_adctCurrencies[0]), _adctCurrencies[0]));
			
			for each (var objCurrency:Object in _adctCurrencies) {
				for each (var xmlCurrency:XML in xml.Currency)
				{
					if (objCurrency.name == xmlCurrency.@name) {
						objCurrency.rate = xmlCurrency.@rate;
						_mnuItems._acobMenuItems.addItem(new PicnikMenuItem(formatCurrencyMenuItem(objCurrency), objCurrency));
						break;
					}		
				}
			}
		}	
	
		public function Process( cct:CreditCardTransaction ): void {
			cct.nAmount = nPrice;
			cct.strSkuId = selectedSku;
			cct.nDuration = CreditCardTransaction.GetDurationFromSkuId(selectedSku);
		}

	}

}