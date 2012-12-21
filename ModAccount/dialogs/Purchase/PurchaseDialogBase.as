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
	import api.RpcResponse;
	
	import containers.ResizingDialog;
	
	import controls.PicnikMenu;
	import controls.PicnikMenuItem;
	import controls.ResizingButton;
	import controls.ResizingLabel;
	
	import dialogs.BusyDialogBase;
	import dialogs.CloudyResizingDialog;
	import dialogs.DialogManager;
	import dialogs.EasyDialog;
	import dialogs.EasyDialogBase;
	import dialogs.IBusyDialog;
	import dialogs.RegisterHelper.UpgradePathTracker;
	
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TextEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.collections.ArrayCollection;
	import mx.containers.ViewStack;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.RadioButton;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ItemClickEvent;
	import mx.events.ResizeEvent;
	import mx.formatters.NumberBaseRoundType;
	import mx.formatters.NumberFormatter;
	import mx.resources.ResourceBundle;
	import mx.validators.CreditCardValidatorCardType;
	
	import util.AdManager;
	import util.CreditCard;
	import util.CreditCardTransaction;
	import util.GiftDetails;
	import util.LocUtil;
	import util.PicnikAlert;
	import util.TipManager;
	
	public class PurchaseDialogBase extends CloudyResizingDialog
	{
		// Params to carry forward to old upsell path
		public var strSourceEvent:String;
		public var strUpgradePath:String = "";		
		
		private var _strSubscriptionSkuId:String = CreditCardTransaction.kSku12Months;
		[Bindable] public var subscriptionStatus:SubscriptionStatus = null;
		[Bindable] public var renewalSkuId:String = null;
						
		[Bindable] public var defaultTabName:String = "";
		[Bindable] public var _ccbox:CCBox;		
		[Bindable] public var _ccInfoBox:CCInfoBox;
		[Bindable] public var _tierBox:TierBox;
		[Bindable] public var _btnClose:Button;
		
		[Bindable] public var logEventBase:String = "register";		
		[Bindable] public var fCollectState:Boolean = true;
		
		[Bindable] public var showTierBox:Boolean = false;
		[Bindable] public var showCCBox:Boolean = false;
		[Bindable] public var showInfoBox:Boolean = false;
		[Bindable] public var cc:CreditCard = null;
		[Bindable] public var skuChanged:Boolean = false;
		[Bindable] public var hasCreditCard:Boolean = false;
		[Bindable] public var upgrading:Boolean = false;
		[Bindable] public var fIsGift:Boolean = false;
		[Bindable] public var gift:GiftDetails = null;
		[Bindable] public var gotSubInfo:Boolean = false;
		
		public function PurchaseDialogBase()
		{
			super();
			subscriptionStatus = SubscriptionStatus.GetInstance();
			addEventListener(TextEvent.LINK, OnLink);
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}

		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null):void {
			super.Constructor(fnComplete,uicParent,obParams);
			if (obParams && 'strStart' in obParams) {
				showCCBox = false;
				showInfoBox = false;
				showTierBox = false;
				if (obParams['strStart'].indexOf("tiers") != -1) {
					showTierBox = true;										
				}
				if (obParams['strStart'].indexOf("info") != -1) {
					showInfoBox = true;										
				}
				if (obParams['strStart'].indexOf("cc") != -1) {
					showCCBox = true;										
				}
			}
			
			if (obParams && 'strSourceEvent' in obParams) {
				strSourceEvent = obParams['strSourceEvent'];
				showCCBox = true;
				showInfoBox = false;
				showTierBox = true;
				upgrading = true;
			}
			
			if (obParams && 'gift' in obParams) {
				// save gift details for later passing onwards
				gift = obParams['gift'] as GiftDetails;
			}
		}
		
		[Bindable]
		public function set subscriptionSkuId(strSkuId:String):void {
			if (_strSubscriptionSkuId != strSkuId) {
				_strSubscriptionSkuId = strSkuId;
				skuChanged = true;
			}
		}
		
		public function get subscriptionSkuId():String {
			return _strSubscriptionSkuId;
		}
		
		
		public function OnCreationComplete(evt:Event):void {
			if (_ccInfoBox) {
				_ccInfoBox.addEventListener(PurchaseEvent.ADD_CARD, OnAddCard);
				_ccInfoBox.addEventListener(PurchaseEvent.CHANGE_CARD, OnChangeCard);
				_ccInfoBox.addEventListener(PurchaseEvent.REMOVE_CARD, OnRemoveCard);
			}
		}
		
		override protected function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.ESCAPE) {
				Hide();
			}
		}	
		
		private function OnAddCard(evt:PurchaseEvent): void {
			showCCBox = true;
			showInfoBox = false;
			showTierBox = true;
		}
		
		private function OnChangeCard(evt:PurchaseEvent): void {
			showCCBox = true;
			showInfoBox = false;
			showTierBox = false;
		}
		
		private function OnRemoveCard(evt:PurchaseEvent): void {
			Hide();
			if (subscriptionStatus.isCancelable) {
				DialogManager.Show("ConfirmCancelDialog");
			} else {
				[ResourceBundle("ConfirmRemoveCardDialog")] var rb:ResourceBundle;
				var dlg:EasyDialog =
					EasyDialogBase.Show(
						PicnikBase.app,
						[Resource.getString('ConfirmRemoveCardDialog','_btnRemove'), 	// 'Purchase!',
							Resource.getString('ConfirmRemoveCardDialog','_btnCancel')], // 'Cancel',
						Resource.getString('ConfirmRemoveCardDialog','confirmRemove', [subscriptionStatus.renewalCard.strCCLast4]), 	// 'Purchase Header',
						Resource.getString('ConfirmRemoveCardDialog','membershipExpires', [LocUtil.mediumDate(AccountMgr.GetInstance().dateSubscriptionExpires)]),
						function( obResult:Object ):void {
							if (obResult.success) {
								var bsy:IBusyDialog = BusyDialogBase.Show(PicnikBase.app, Resource.getString("PurchaseDialog", "justOneSec"),BusyDialogBase.OTHER, "IndeterminateNoCancel");
								var fnOnRemove:Function = function(nErr:Number, strErr:String):void {
									LoadCardInfo( function():void {
										bsy.Hide();
										PicnikBase.app.Notify(Resource.getString('PurchaseDialog', 'removed'));						
									} );				
								}
								PurchaseManager.GetInstance().RemoveCreditCard( fnOnRemove );
							}
						});
			}
		}

		override public function Hide():void {
			if (_ccbox != null) _ccbox.OnHide(null);
			AdManager.GetInstance().OnUpgradeWindowHide();
			super.Hide();
			if (_fnComplete != null) {
				_fnComplete({ success: true });
			}
		}
//		
		// TODO(steveler) remove this?
//		protected function ShowPaymentSelector(): void {
//			super.Hide();
//			DialogManager.ShowUpgrade(strSourceEvent, _uicParent, _fnComplete, _obParams, false);
//		}
		
		override protected function OnShow(): void {
			if (!fIsGift) {
				ShowBusy(Resource.getString("PurchaseDialog","justOneSec"));
				LoadCardInfo( function():void {
						HideBusy();						
					} );
			}
			super.OnShow();
			if (_btnClose) {
				_btnClose.setFocus();
			}			
		}
		
		private function LoadCardInfo( fnDone:Function ): void {
			gotSubInfo = false;
			
			SubscriptionStatus.Refresh(function(fSuccess:Boolean): void {
				cc = subscriptionStatus.renewalCard;
				hasCreditCard = cc != null && cc.strCCLast4 && (cc.strCCLast4.length > 0);
				if (!hasCreditCard)
					cc = new CreditCard();
				
				if (subscriptionStatus.renewalSkuId) {
					renewalSkuId = subscriptionStatus.renewalSkuId;
					subscriptionSkuId = subscriptionStatus.renewalSkuId;
					skuChanged = false;
				}

				gotSubInfo = true;
				fnDone();
			});
		}

		// function fnDone( fAccepted:Boolean, cct:CreditCardTransaction ): void
		private function ShowTaxMessage(cct:CreditCardTransaction, fnDone:Function):void {
			if (cct.nTax > 0 && cct.fIsPurchase) {
				var nMonths:int = cct.nDuration == CreditCardTransaction.knOneMonth ? 1 : (cct.nDuration == CreditCardTransaction.kn12Months ? 12 : 6 );
				var strBodyText:String = LocUtil.rbSubst('OrderTab', 'taxmessage', nMonths, 
					LocUtil.moneyUSD(cct.nAmount), LocUtil.moneyUSD(cct.nTax), LocUtil.moneyUSD(cct.nAmount + cct.nTax));
				
				var dlg:EasyDialog =
					EasyDialogBase.Show(
						PicnikBase.app,
						[Resource.getString('OrderTab','_btnCreate'), 	// 'Purchase!',
							Resource.getString('OrderTab','_btnBack')], // 'Cancel',
						Resource.getObject('OrderTab','taxheader'), 	// 'Purchase Header',
						strBodyText,						
						function( obResult:Object ):void {
								fnDone(obResult.success, cct);
							});
				return;
			}
			
			fnDone(true, cct);
		}
		
		public function Purchase():void {	
			var cctPurchase:CreditCardTransaction = PurchaseManager.GetInstance().CreateTransaction();
 			
			if (showCCBox) {
				// TODO: is this the correct log for people who are re-activating a creditcard for later renewal?
				UpgradePathTracker.LogPageView(logEventBase, 'Submitted', 'CreditCard');

				_tierBox.Process(cctPurchase);
				
				cctPurchase.fIsGift = fIsGift;
				cctPurchase.fIsPurchase = upgrading;

				var fnOnPurchase:Function = function(nError:Number, strErr:String, cct:CreditCardTransaction): void {
					HideBusy();

					if (nError || isNaN(nError)) {
						PicnikAlert.show(Resource.getString("OrderTab", "server_error"));
					} else if (cct.aErrors) {
						_ccbox.ReportErrors(cct);														
					} else {
						Hide();	
						if (upgrading) {
							PicnikBase.app.FloatBalloons();
							DialogManager.Show("ReceiptDialog", null, null, { cct:cct } );								
						} else {
							// TODO: some kind of thanks, your card will be charged later dialog.
							PicnikBase.app.Notify(Resource.getString('PurchaseDialog', 'saved'));						
						}
					}
				}
					
				var fnOnTaxRateConfirmed:Function = function(fProceed:Boolean, cct:CreditCardTransaction): void {
					if (fProceed) {
						if (upgrading) {
							PurchaseManager.GetInstance().PurchaseWithNewCard(cct, fnOnPurchase);
						} else {
							PurchaseManager.GetInstance().AddCreditCard(cctPurchase, fnOnPurchase);
						}
					} else {
						HideBusy();
					}
				}
					
				var fnOnProcessed:Function = function(nErr:Number, strErr:String, cct:CreditCardTransaction): void {
						ShowTaxMessage(cct, fnOnTaxRateConfirmed);
					}
				
				var fnOnCCInfo:Function = function(fProceed:Boolean, cc:CreditCard):void {
						if (fProceed) {
							ShowBusy();
							cctPurchase.cc = cc;
							PurchaseManager.GetInstance().PreProcess(cctPurchase, fnOnProcessed);
						} else {
						} 								
					}
				
				_ccbox.Process(fnOnCCInfo);
			} else if (showTierBox) {
				// We're adjusting the user's montly/six/yearly renewal settings
				_tierBox.Process(cctPurchase);

				var strOldSku:String = subscriptionStatus.renewalSkuId;
				var strNewSku:String = cctPurchase.strSkuId;
				var strOldPrice:String = _tierBox.FormatCurrency(CreditCardTransaction.GetPriceFromSkuId(strOldSku));
				var strNewPrice:String = _tierBox.FormatCurrency(CreditCardTransaction.GetPriceFromSkuId(strNewSku));
				
				Hide();
				
				var strBody:String = "";
				
				if (strOldSku != strNewSku) {
					var obPurchaseDialog:PurchaseDialogBase = this;
					[ResourceBundle("ConfirmChangeMembershipDialog")] var rb:ResourceBundle;
					if (AccountMgr.GetInstance().IsCancelable()) {
						EasyDialogBase.Show(
							PicnikBase.app,
							[Resource.getString('ConfirmChangeMembershipDialog','cancelNow'),
								Resource.getString('ConfirmChangeMembershipDialog','neverMind')],
							Resource.getString('ConfirmChangeMembershipDialog','changeMembership'),
							Resource.getString('ConfirmChangeMembershipDialog','gracePeriod'),
							function( obResult:Object ):void {
								if (obResult.success) {
									obPurchaseDialog.Hide();
									DialogManager.Show("ConfirmCancelDialog");
								}
							}
						);						
					} else {
						strBody = Resource.getString('ConfirmChangeMembershipDialog','currentMembership') + " " +
									Resource.getString('ConfirmChangeMembershipDialog', 'membership_'+strOldSku, [strOldPrice]);
						strBody += "<br/>";
						strBody += Resource.getString('ConfirmChangeMembershipDialog','newMembership') + " " +
							Resource.getString('ConfirmChangeMembershipDialog','membership_'+strNewSku, [strNewPrice]);
						strBody += "<br/><br/>"						
						strBody += Resource.getString('ConfirmChangeMembershipDialog','effectiveDate',[LocUtil.mediumDate(AccountMgr.GetInstance().dateSubscriptionExpires)]);
						
						EasyDialogBase.Show(
								PicnikBase.app,
								[Resource.getString('PurchaseDialog','saveChanges'), 				// 'Purchase!',
									Resource.getString('PurchaseDialog','cancel')], 				// 'Cancel',
								Resource.getString('ConfirmChangeMembershipDialog','changeMembership'), 	// 'Purchase Header',
								strBody,
								function( obResult:Object ):void {
									if (obResult.success) {
										var bsy:IBusyDialog = BusyDialogBase.Show(PicnikBase.app, Resource.getString("PurchaseDialog", "justOneSec"),BusyDialogBase.OTHER, "IndeterminateNoCancel");
										cctPurchase.cc = subscriptionStatus.renewalCard;
										PurchaseManager.GetInstance().SetRenewalSku(cctPurchase.strSkuId, function(nErr:Number,strErr:String):void {
											SubscriptionStatus.Refresh(function(fSuccess:Boolean): void {
												bsy.Hide();
												PicnikBase.app.Notify(Resource.getString('PurchaseDialog', 'saved'));						
											});	
										});
									}
								}
							);
					}
				} else {
					PicnikBase.app.Notify(Resource.getString('PurchaseDialog', 'saved'));						
				}
			} else {
				// no credit card: jump over to the CC page
				showCCBox = true;
				showInfoBox = false;
			}
		}


		public function CancelClick(): void {
			Hide();
		}

		private function OnLink(evt:TextEvent): void {
			TipManager.ShowTip(evt.text, true);
		}		
	}
}