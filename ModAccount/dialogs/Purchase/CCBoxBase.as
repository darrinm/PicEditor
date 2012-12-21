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
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.containers.Box;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.Text;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	import mx.effects.Sequence;
	import mx.events.FlexEvent;
	import mx.events.ValidationResultEvent;
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
	
	public class CCBoxBase extends Box
	{
		[Event(name="submitCard", type="Dialogs.Purchase.PurchaseEvent")]

		private var _fHasFieldErrors:Boolean = false;
		[Bindable] public var _tiCardNumber:NoTipTextInput;
		[Bindable] public var _tiCardVerification:NoTipTextInput;
		[Bindable] public var _cmboMonth:ComboBox;
		[Bindable] public var _cmboYear:ComboBox;
		[Bindable] public var _fCollectState:Boolean = true;
		[Bindable] public var _fValidateZip:Boolean = true;
		[Bindable] public var _fCollectZip:Boolean = true;
		[Bindable] public var _fCollectCity:Boolean = true;
		[Bindable] public var _tiName:NoTipTextInput;
		[Bindable] public var _tiEmail:NoTipTextInput;
		[Bindable] public var _tiState:NoTipTextInput;
		[Bindable] public var _tiZip:NoTipTextInput;
		[Bindable] public var _cmboCountry:ComboBox;
		[Bindable] public var _vldCC:PicnikCreditCardValidator;
		[Bindable] public var _vldPhone:PicnikPhoneNumberValidator;
		[Bindable] public var _vldCV2:PicnikStringValidator;
		[Bindable] public var _effError:Sequence;
		[Bindable] public var _acCountries:ArrayCollection;
		[Bindable] public var _detectedCCType:String = PicnikCreditCardValidator.ANY;
		[Bindable] public var _lblGenericError:ResizingLabel;
		[Bindable] public var _lblGenericError2:ResizingLabel;
		
		[Bindable] public var _app:PicnikBase;
		[Bindable] public var _btnInfo:Button;
		[Bindable] public var creditCard:CreditCard;
		[Bindable] public var subscriptionSkuId:String = CreditCardTransaction.kSku12Months;
		[Bindable] public var gift:Boolean = false;
		
		[Bindable] protected var _fDateError:Boolean = false;
		
		private var _fPurchasing:Boolean = false;

		public var _dlgBusy:IBusyDialog;

		private static var _validCCYears:Array = [];
		private static const kastrCountriesWithoutPostalCodes:Array = ['af', 'ao', 'ai', 'aq', 'aw', 'bs', 'bz', 'bj', 'bt', 'bw', 'bi', 'cm', 'co', 'km', 'cg', 'ck', 'cr', 'cu', 'cy',
'dj', 'dm', 'ec', 'gq', 'er', 'et', 'fj', 'gm', 'gi', 'gd', 'gn', 'gy', 'hk', 'ie', 'jo', 'ke', 'ki', 'mw', 'ml',
'mr', 'mu', 'ms', 'na', 'nr', 'an', 'nu', 'om', 'pa', 'rw', 'kn', 'lc', 'pm', 'st', 'sa', 'sc', 'sl', 'sb', 'so',
'za', 'sr', 'tj', 'tk', 'to', 'tt', 'tv', 'ug', 'ae', 'vu', 'ye', 'zm', 'zw'];

		private static const kastrCountriesWithoutCities:Array = ['hk'];

		private var _pwndCcvInfo:InfoWindow = null;

		public function CCBoxBase()  {
			addEventListener(FlexEvent.INITIALIZE, OnInit);
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
			addEventListener(FlexEvent.SHOW, OnShow);
			addEventListener(FlexEvent.HIDE, OnHide);
			Reset();
			_app = PicnikBase.app;
		}
		
		// Data modeling functions
		protected function get dataModel(): DataModel {
			if ("_dtmFormFields" in this) return this["_dtmFormFields"] as DataModel;
			else return null; // Not found. Error.
		}
		
		public function OnHide(evt:FlexEvent): void {
			_btnInfo.selected = false;
		}
		
		public function set showVerificationHelp(fShow:Boolean): void {
			if (fShow) {
				if (_pwndCcvInfo == null) {
					_pwndCcvInfo = new InfoWindow();
					_pwndCcvInfo.x = 285;
					_pwndCcvInfo.y = 58;
					_pwndCcvInfo.title = Resource.getString('OrderTab', '_pwndCcvInfo');
					_pwndCcvInfo.addEventListener("close", function(evt:Event): void {_btnInfo.selected = false;}, false, 0, true);
					
					var bx:Box = new Box();
					bx.setStyle("paddingLeft", -3);
					bx.setStyle("paddingTop", -4);
					_pwndCcvInfo.addChild(bx);
					
					var img:ImageEx = new ImageEx();
					img.source = PicnikBase.StaticUrl("../graphics/cc_ccv_finder.png");
					bx.addChild(img);
					
					_pwndCcvInfo.visible = false;
				}
				if (!_pwndCcvInfo.visible) {
					PopUpManager.addPopUp(_pwndCcvInfo, this, false);
					_pwndCcvInfo.visible = true;
				}
				// Position it
				var pt:Point = new Point(_btnInfo.width/2, _btnInfo.height);
				pt = _btnInfo.localToGlobal(pt); // Global position of top/center of dialog
				
				_pwndCcvInfo.x = pt.x - 93;
				_pwndCcvInfo.y = pt.y + 6;
			} else {
				// Hide the window
				if (_pwndCcvInfo != null) {
					_pwndCcvInfo.visible = false;
					PopUpManager.removePopUp(_pwndCcvInfo);
				}
			}
		}
		
		public function get purchaseDialog():PurchaseDialog
		{
			var docParent:DisplayObjectContainer = this.parent;
			while (docParent && !(docParent is PurchaseDialog))	
				docParent = docParent.parent;
			return docParent as PurchaseDialog;
		}
		
		private function InitCountries(): void {
			// First, convert all objects to objectproxys
			for (var i:Number = 0; i < _acCountries.length; i++)
				_acCountries.setItemAt(new ObjectProxy(_acCountries.getItemAt(i)),i);

			var sort:Sort = new Sort();
			sort.fields = [ new SortField("label") ];
			var oldSort:Sort = _acCountries.sort;
			_acCountries.sort = sort;
			_acCountries.refresh();
			_acCountries.sort = oldSort;
			
			// given a list of country codes, move them to the top of the list.
			var promote:Function = function(codes:Array) : void {
				if (_acCountries.length == 0)
					return;
				for each (var code:String in codes.reverse()) {
					var idx:int;
					for (idx=0; idx<_acCountries.length; idx++) {
						if (_acCountries[idx].data != code)
							continue;
						var o:Object = _acCountries.removeItemAt(idx);
						_acCountries.addItemAt(o, 0);
						break;
					}
				}
			}
			
			// per locale, move the most likely country/-ies to the top
			promote(LocaleInfo.GetCountryHints());
		}		
		
		public function setError(s1:String, s2:String = "") : void {			
			_lblGenericError.text = s1;
			_lblGenericError2.text = s2;
		}
		
		public function OnShow(evt:FlexEvent) : void {
			Reset();
			
			// sort all countries by their localized labels
			UpgradePathTracker.CCStateReached("View", Math.pow(2,0));

			OnChangeCountry(); // Make sure we update the zip code validator appropriately
		}
		
		// User clicked a button (etc) to submit the form
		public function Validate(): Boolean {
			var fValid:Boolean = dataModel.validateAll();
			//fire error glow effect
			if (!fValid) {
				var aTargets:Array = [];
				for (var i:int = 0; i < dataModel.length; i++) {
					var uicTarget:UIComponent = (dataModel[i] as DataField).getSource() as UIComponent;
					if (uicTarget && uicTarget.errorString && uicTarget.errorString.length) {
						aTargets.push(uicTarget);
					}
				}
				_effError.end();
				_effError.targets = aTargets;
				_effError.play();
			}
			return fValid;
		}
		
		public function Reset(): void {
			// TODO: these debug values are just to make debugging faster.
			// They should be changed to '' (except for _tiEmail).
			var oFields:Object = {_tiCardNumber: '',
				_tiCardVerification: '',
				_tiName: '',
				_tiZip: '',
				_tiState: '',
				_tiEmail: AccountMgr.GetInstance().email
			}

			if (_cmboCountry) {
				_cmboCountry.selectedIndex = FindCountryIndex();	
			}

			if (creditCard) {
				oFields._tiCardNumber = creditCard.strCC;
				oFields._tiName = creditCard.FullName();
				oFields._tiZip = creditCard.strZip;
				oFields._tiState = creditCard.strState;
				_cmboCountry.selectedIndex = FindCountryIndex(creditCard.strCountry);
				
			}

			if (false) {
				oFields = {_tiCardNumber: '4111111111111111',
					_tiCardVerification: '123',
					_tiName: 'User For Debugging',
					_tiZip: '12345',
					_tiState: 'WW',
					_tiEmail: AccountMgr.GetInstance().email
				}
			}
			for (var strName:String in oFields) {
				var ti:TextInput = this[strName] as TextInput;
				if (ti) {
					ti.text = oFields[strName];
					ti.errorString = '';
				}
			}
			OnCCNumberChange(null);
			OnChangeCountry();
		}

		// when starting up, build a list of years for the next decade
		// to place in the credit card year dropdown.  Also, set the
		// default month/year to be this month/year
		public function OnInit(evt:Event): void {
			var now:Date = new Date();
			var i:int;
			for (i=0; i<30; i++) {
				var year:String = (now.fullYear + i).toString();
				_validCCYears.push( { label: year, data: year } );
			}
			_cmboYear.dataProvider = _validCCYears;
			
			// set default month to be current month
			// fortunately, 0-based months and 0-based ComboBox indices correlate nicely
			_cmboMonth.selectedIndex = now.month;
			
			InitCountries();			
			_cmboCountry.dataProvider = _acCountries;
			_cmboCountry.selectedIndex = FindCountryIndex();
		}
		
		public function OnCreationComplete( evt:Event ): void {
			// we might have auto-set the country in the MXML, so make sure this gets called.
			OnChangeCountry();
			_tiCardNumber.addEventListener(Event.CHANGE, OnCCNumberChange);
		}
		
		// Take the user locale and try to map it to a country
		// return the index of the country in the combo box which best matches the user locale
		public function FindCountryIndex( strCountry:String=null ): Number {
			if (!strCountry) {
				strCountry = CONFIG::locale.substr(3,2).toLowerCase();
			}
			
			var nMatch:Number = 0;
			
			for (var i:Number = 0; i < _acCountries.length; i++) {
				if (_acCountries.getItemAt(i).data == strCountry) {
					nMatch = i;
					break;
				}
			}
			return nMatch;
		}

		public function PurchaseKeyEvent(evt:KeyboardEvent):void
		{
			if (evt.keyCode != Keyboard.ESCAPE && evt.keyCode != Keyboard.TAB && evt.keyCode != Keyboard.SPACE) {
				dispatchEvent( new PurchaseEvent( PurchaseEvent.SUBMIT_CARD ) );
			}
		}
		
		public function ReportErrors( cct:CreditCardTransaction ): void {
			if (cct && cct.aErrors && cct.aErrors) {
				for (var i:int = 0; i < cct.aErrors.length; i++) {
					if (cct.aErrors[i] == CreditCardTransaction.kErrException) {
						setError( Resource.getString("OrderTab","SorryCardRejected") );
						
					} else if (cct.aErrors[i] == CreditCardTransaction.kErrUnknown) {
						setError( Resource.getString("OrderTab","SorryCardRejected") );
						
					} else if (cct.aErrors[i] == CreditCardTransaction.kErrCCNumber) {
						setError( Resource.getString("OrderTab","invalid_number"), Resource.getString("OrderTab","bank_questions") );
						_tiCardNumber.errorString = Resource.getString("OrderTab","invalid");
						
					} else if (cct.aErrors[i] == CreditCardTransaction.kErrCVV) {
						setError( Resource.getString("OrderTab","cvv_error"), Resource.getString("OrderTab","bank_information") );
						_tiCardVerification.errorString = Resource.getString("OrderTab","invalid");
				
					} else if (cct.aErrors[i] == CreditCardTransaction.kErrDate) {
						setError( Resource.getString("OrderTab","invalid_date"), Resource.getString("OrderTab","invalid_date2") );	
						_fDateError = true;
						
					} else if (cct.aErrors[i] == CreditCardTransaction.kErrCVVOrDate) {
						setError( Resource.getString("OrderTab","invalid_card_code_or_date"), Resource.getString("OrderTab","bank_questions") );	
						_tiCardVerification.errorString = " ";
						_fDateError = true;

					} else if (cct.aErrors[i] == CreditCardTransaction.kErrExpired) {
						setError( Resource.getString("OrderTab","card_expired"), Resource.getString("OrderTab","card_expired2")  );	
						_fDateError = true;						
						
					} else if (cct.aErrors[i] == CreditCardTransaction.kErrLimitExceeded) {
						setError( Resource.getString("OrderTab","limit_exceeded"), Resource.getString("OrderTab","bank_information") );	
						
					} else if (cct.aErrors[i] == CreditCardTransaction.kErrInsufficientFunds) {
						setError( Resource.getString("OrderTab","insufficient_funds"), Resource.getString("OrderTab","bank_information") );	
						
					} else if (cct.aErrors[i] == CreditCardTransaction.kErrCallAuth) {
						setError( Resource.getString("OrderTab","call_auth") );	
						
					} else if (cct.aErrors[i] == CreditCardTransaction.kErrNotAllowed) {
						setError( Resource.getString("OrderTab","trans_not_allowed"), Resource.getString("OrderTab","bank_information") );	
						
					} else if (cct.aErrors[i] == CreditCardTransaction.kErrZip) {
						_tiZip.errorString = Resource.getString("OrderTab","invalid");
						setError( Resource.getString("OrderTab","bad_zip") );
						
					} else if (cct.aErrors[i] == CreditCardTransaction.kErrFraud) {
						setError( Resource.getString("OrderTab","err_fraud"), Resource.getString("OrderTab","bank_information") );
					
					}
				}
			}
		}
		
		public function ErrorKeyToMessage(strKey:String): String {
			if (Resource.getObject('OrderTab',strKey)) {
				return Resource.getString('OrderTab',strKey);
			} else {
				// Log this
				if (strKey != 'active_paypal_sub') {
					trace("Unknown error string returned: " + strKey);
					PicnikService.Log("Unknown error returned by credit card auth: " + strKey, PicnikService.knLogSeverityError);
				}
				return Resource.getString('OrderTab', 'unknown_error');
			}
		}
		
		private static const kobErrorFields:Object = {
			creditcard:{weight:6, priority:0},
			cv2:{weight:5, priority:1},
			creditcard_expire_month:{weight:4, priority:1},
			creditcard_expire_year:{weight:4, priority:1},
			zip:{weight:3, priority:2},
			name:{weight:2, priority:2},
			email:{weight:2, priority:2},
			phone:{weight:2, priority:2},
			tos_agree:{weight:1, priority:2},
			address:{weight:0, priority:2},
			city:{weight:0, priority:2},
			state:{weight:0, priority:2}
		};
		
		private static const kstrLogStatePriorityNames:Array = ['Number', 'CCInfo', 'UserInfo'];
		private static const kstrLogStateWeightNames:Array = ['Number', 'CVC', 'Expires', 'Zip', 'ContactInfo', 'TOS', 'Addr'];
		
		private function LogInvalidState(): void {
			// Figure out out invalid state and log it
			var nStateVal:Number = 0;
			var strState:String = "InvalidSubmit/";
			
			var astrErrorFields:Array = dataModel.GetFieldsWithErrors();
			if (astrErrorFields.length > 0) {
				
				// First, group things by weight. No two entries should have the same weights.
				var obMapWeightToFieldInfo:Object = {};
				var obFieldInfo:Object;
				for each (var strField:String in astrErrorFields) {
					if (strField in kobErrorFields) {
						obFieldInfo = kobErrorFields[strField];
						obMapWeightToFieldInfo[obFieldInfo.weight] = obFieldInfo;
					}
				}
				
				// Now we have removed duplicate entries with the same weight. Use the weights to calculate our value
				var nHighestPriority:Number = 1000;
				nStateVal = Math.pow(2, 8) - 1; // Start with the max value - everything valid.
				
				for each (obFieldInfo in obMapWeightToFieldInfo) {
					// Subtract for invalid weights
					nStateVal -= Math.pow(2, obFieldInfo.weight + 1);
					nHighestPriority = Math.min(nHighestPriority, obFieldInfo.priority);
				}
				
				var astrSubVals:Array = [];
				for each (obFieldInfo in obMapWeightToFieldInfo) {
					if (obFieldInfo.priority == nHighestPriority) {
						astrSubVals.push(kstrLogStateWeightNames[6-obFieldInfo.weight]);
					}
				}
				
				astrSubVals = astrSubVals.sort();
				strState += "Invalid" + kstrLogStatePriorityNames[nHighestPriority] + "/" + astrSubVals.join('_');
				if (nHighestPriority == 0 && _vldCC) {
					// Credit card number error. Add some information
					var evt:ValidationResultEvent = _vldCC.validate();
					var astrCodes:Array = [];
					if (evt.type == ValidationResultEvent.INVALID) {
						var avrResults:Array = evt.results;
						for each (var vr:ValidationResult in avrResults) {
							astrCodes.push(vr.errorCode);
						}
					}
					if (astrCodes.length > 0) {
						astrCodes = astrCodes.sort();
						strState += "/" + astrCodes.join("_");
					}
				}
			} else {
				nStateVal = 1.5;
				strState += "Unknown";
			}

			UpgradePathTracker.CCStateReached(strState, nStateVal);
		}
		
		// fnDone:Function( fProceed:Boolean, cc:CreditCard )
		public function Process(fnDone:Function ): void {
			if (Validate()) {
				var cc:CreditCard = new CreditCard;
				cc.strCC = _tiCardNumber.text;
				cc.chCCType = CreditCard.GetCardTypeCode(_detectedCCType);
				cc.strCVS = _tiCardVerification.text;
				cc.strLastName = _tiName.text;
				cc.strEmail = _tiEmail.text;
				cc.strZip = _tiZip.text;
				cc.strCountry = String(_cmboCountry.selectedItem.data);
				cc.strState = _tiState.text.toLowerCase();
				cc.strExpiry = _cmboMonth.text + _cmboYear.text.slice(2);	// format is MMYY

				_fPurchasing = true;

				var amgr:AccountMgr = AccountMgr.GetInstance();
				if (!gift && (amgr.email.length > 0) && _tiEmail.text != amgr.email) {
					UpgradePathTracker.CCStateReached("DuplicateEmail", Math.pow(2, 8));
					var strBodyText:String = LocUtil.rbSubst('OrderTab', '_lblEmailMismatch', _tiEmail.text, amgr.email);
					var dlg2:EasyDialog =
						EasyDialogBase.Show(
							PicnikBase.app,
							[Resource.getString('OrderTab', '_lblEmailMismatchContinue'),
								Resource.getString('OrderTab', '_lblEmailMismatchCancel')],
							Resource.getString('OrderTab', '_lblEmailMismatchHeader'),
							strBodyText,						
							function( obResult:Object ):void {
									fnDone(obResult.success, cc);
								}
							);
					return;																	
				}
				fnDone(true, cc);
			} else {
				fnDone(false, cc);
			}
		}
		
		public function Cancel(): void {
			DialogManager.ResetDialogs();
			UpgradePathTracker.Reset();
		}	
		
		private function ArrayContains(astr:Array, str:String): Boolean {
			for each (var strFound:String in astr) {
				if (strFound == str) return true;
			}
			return false;
		}

		public function OnChangeCountry():void {
			if (!_cmboCountry) return;
			var strCountry:String = _cmboCountry.selectedItem.data;
			_fValidateZip = (!strCountry || strCountry == 'ca' || strCountry == 'us');

			if (!_fValidateZip && _tiZip)
				_tiZip.errorString = null;
				
			_fCollectZip = !ArrayContains(kastrCountriesWithoutPostalCodes, strCountry);
			if (!_fCollectZip && _tiZip) _tiZip.text = "";
			
			_fCollectState = (!strCountry || strCountry == 'ca' || strCountry == 'us'); // came from OrderTabBase.OnChangeCountry
			if (!_fCollectState && _tiState) _tiZip.text = "";			
		}
				
		public function OnCCNumberChange(evt:Event): void {
			if (_tiCardNumber && _tiCardVerification) {
				var oCardType:Object = PicnikCreditCardValidator.GetCreditCardType(_tiCardNumber.text);
				_tiCardNumber.maxChars = oCardType.aLen.length > 0 ? oCardType.aLen[oCardType.aLen.length-1] : 16;
				_tiCardVerification.maxChars = oCardType.cvvLen;
				_vldCV2.minLength = oCardType.cvvLen;
				_detectedCCType = PicnikCreditCardValidator.ANY;
				for (var i:int = 0; i < oCardType.aLen.length; i++) {
					if (_tiCardNumber.text.length == oCardType.aLen[i]) {
						_detectedCCType = oCardType.type;
						break;
					}
				}
			}
		}
		
		[Bindable (event="validChanged")]
		public function get hasFieldErrors(): Boolean {
			return _fHasFieldErrors;
		}
		
	}

}