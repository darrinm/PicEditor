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
	import api.PicnikRpc;
	import api.RpcResponse;
	
	import containers.InfoWindow;
	
	import controls.ImageEx;
	import controls.NoTipTextInput;
	
	import dialogs.BusyDialogBase;
	import dialogs.DialogManager;
	import dialogs.EasyDialog;
	import dialogs.EasyDialogBase;
	import dialogs.IBusyDialog;
	import dialogs.RegisterDialog;
	import dialogs.RegisterHelper.DataModel;
	import dialogs.RegisterHelper.UpgradePathTracker;
	
	import mx.core.UIComponent;
	
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
	
	public class PurchaseManager
	{
		private var _fPurchasing:Boolean = false;
		
		private static var s_inst:PurchaseManager = null;

		public static function GetInstance(): PurchaseManager {
			if (s_inst == null)
				s_inst = new PurchaseManager();
			return s_inst;
		}

		public function PurchaseManager()  {
		}
		
		public function CreateTransaction(): CreditCardTransaction {
			return new CreditCardTransaction();
		}
						
		public function SetRenewalSku( strSkuId:String, fnDone:Function = null ): void {
			var obPropValue:Object = { 'renewalsku': strSkuId };
			var fnOnSetUserProperties:Function = function(rpcresp:RpcResponse): void {
				if (fnDone != null) fnDone(rpcresp.errorCode, rpcresp.errorMessage);
			}
			PicnikRpc.SetUserProperties(obPropValue, "subscription", null, fnOnSetUserProperties);
			
		}
		
		// function fnDone( nError:Number, strErr:String ): void
		public function RemoveCreditCard( fnDone:Function ): void {
			var fnOnRemoveCreditCard:Function = function(rpcresp:RpcResponse):void {
				AccountMgr.GetInstance().SetUserAttribute('cAutoRenew', 'N');
				AccountMgr.GetInstance().RefreshUserAttributes( function():void {
						fnDone( rpcresp.errorCode, rpcresp.errorMessage );
					} );
			}
			PicnikRpc.RemoveCreditCard(fnOnRemoveCreditCard);
		}
		
		// fnDone:Function(nErr:Number, strErr:String, cct:CreditCardTransaction):void
		public function AddCreditCard( cct:CreditCardTransaction, fnDone:Function ): void {
			UpgradePathTracker.LogPageView(cct.logEventBase, 'Submitted', 'CreditCard');			
			PicnikRpc.AddCreditCard(cct.cc, function(rpcresp:RpcResponse):void {
				if (rpcresp.errorCode != PicnikService.errNone) {
					UpgradePathTracker.CCStateReached("ServerError", Math.pow(2, 9));
					fnDone( rpcresp.errorCode, rpcresp.errorMessage, cct );				
				} else {
					AccountMgr.GetInstance().SetUserAttribute('cAutoRenew', 'Y');
					SetRenewalSku(cct.strSkuId, function(nErr:Number, strErr:String): void {
						fnDone(rpcresp.errorCode, rpcresp.errorMessage, cct);
					} );
				}
			} );
		}				
		
		// fnDone:Function(nErr:Number, strErr:String, cct:CreditCardTransaction):void
		public function PreProcess( cct:CreditCardTransaction, fnDone:Function ): void {
			UpgradePathTracker.LogPageView(cct.logEventBase, 'Submitted', 'CreditCard');

			cct.fAutoRenew = true;		
			cct.strSource = PicnikBase.app.AsService().apikey;

			// call up to the server to figure out the tax rate
			var fnOnTaxRate:Function = function( rpcresp:RpcResponse ): void {
				if (rpcresp.errorCode == PicnikService.errNone && rpcresp.data.nTaxRate) {
					cct.nTax = cct.nAmount * rpcresp.data.nTaxRate;
				}
				fnDone( rpcresp.errorCode, rpcresp.errorMessage, cct );
			}

			PicnikRpc.CalculateTaxRate(cct, fnOnTaxRate);
		}
		
		// function fnDone( nError:Number, strErr:String, cct:CreditCardTransaction ): void
		public function PurchaseWithNewCard(cct:CreditCardTransaction, fnDone:Function): void {			
			UpgradePathTracker.LogPageView(cct.logEventBase, 'SentToBank', 'CreditCard');
			_fPurchasing = true;
			if (cct.fIsGift) {
				cct.cc.strCCId = "gift";
			}			
			PicnikRpc.AddCreditCard(cct.cc, function(rpcresp:RpcResponse):void {
				if (rpcresp.errorCode != PicnikService.errNone) {
					UpgradePathTracker.CCStateReached("ServerError", Math.pow(2, 9));
					fnDone( rpcresp.errorCode, rpcresp.errorMessage, cct );				
				} else {
//					// DEBUG CODE
//					var aErrors:Array = [
////							CreditCardTransaction.kErrCCNumber
////						CreditCardTransaction.kErrCVV
////							CreditCardTransaction.kErrDate
////							CreditCardTransaction.kErrException
////							CreditCardTransaction.kErrExpired
////							CreditCardTransaction.kErrLimitExceeded
////							CreditCardTransaction.kErrUnknown
////							CreditCardTransaction.kErrZip
////							CreditCardTransaction.kErrFraud
////							CreditCardTransaction.kErrInsufficientFunds
////							CreditCardTransaction.kErrNotAllowed
//							CreditCardTransaction.kErrCallAuth
//					];
//					rpcresp.data.errors = aErrors;
//					// END DEBUG CODE
					if ("aErrors" in rpcresp.data && rpcresp.data.aErrors && rpcresp.data.aErrors.length) {
						StoreErrors(rpcresp.data.aErrors, cct);
						fnDone(rpcresp.errorCode, rpcresp.errorMessage, cct);
					} else {
						// TODO: need to pass in some kind of identifier to make sure we charge the right CC
						SubscribeUser(cct, fnDone);
					}
				}
			} );
		}
		
		// function fnDone( nError:Number, strErr:String, cct:CreditCardTransaction ): void
		public function PurchaseWithExistingCard(cct:CreditCardTransaction, fnDone:Function): void {			
			UpgradePathTracker.LogPageView(cct.logEventBase, 'SentToBank', 'CreditCard');
			_fPurchasing = true;
			SubscribeUser(cct, fnDone);
		}

		private function StoreErrors( aErrors:Array, cct:CreditCardTransaction): void {
			if (aErrors && aErrors.length) {
				cct.aErrors = aErrors;	
			} else {
				cct.aErrors = null;
			}
		}
		
		private function SubscribeUser(cct:CreditCardTransaction, fnDone:Function): void {
			var fnOnPurchaseSuccess:Function = function(rpcresp:RpcResponse): void {				
				if (!rpcresp.isError) {
					var obResult:Object = rpcresp.data;

					if ("aErrors" in obResult && obResult.aErrors && obResult.aErrors.length) {
						StoreErrors(obResult.aErrors, cct);
						fnDone(rpcresp.errorCode, rpcresp.errorMessage, cct);
						return;
					} else if (!obResult.fPaymentAccepted) {
						StoreErrors([obResult.strErrorCode], cct);
						fnDone(rpcresp.errorCode, rpcresp.errorMessage, cct);
						return;
					}
					
					// Credit card was approved. This code mostly just logs that fact in a whole bunch of places
					var strUpgradePath:String = cct.sourceEvent;
					if (strUpgradePath == null || strUpgradePath == "")
						strUpgradePath = "/-";
					if (strUpgradePath != "not_a_purchase") {
						if (strUpgradePath.charAt(0) != "/")
							strUpgradePath = "/" + strUpgradePath;
						Util.LogUpgradePath(strUpgradePath);
					}
					
					// log the result back to the ad manager
					if (cct.nDuration == CreditCardTransaction.knOneMonth) {
						AdManager.GetInstance().LogAdCampaignEvent(AdManager.kAdCampaignEvent_Upgrade1);
					} else if (cct.nDuration == CreditCardTransaction.knSixMonths) {
						AdManager.GetInstance().LogAdCampaignEvent(AdManager.kAdCampaignEvent_Upgrade6);
					} else {
						AdManager.GetInstance().LogAdCampaignEvent(AdManager.kAdCampaignEvent_Upgrade12);
					}

					// report the result to analytics
					var strSite:String = SafeGetProperty(obResult, "strSite", "mywebsite.com");
					var strProduct:String = SafeGetProperty(obResult, "strProduct", "Picnik Premium - Unknown Duration");
					strProduct = strProduct.replace(/\s/g, "_"); // replace whitespace with underscores
					Util.UrchinLogTransaction(SafeGetProperty(obResult, "strInvoice", ""), strSite,
						SafeGetProperty(obResult, "nTotal", "0"), SafeGetProperty(obResult, "nTax", "0"),
						"0", SafeGetProperty(obResult, "strCity", ""), SafeGetProperty(obResult, "strState", ""),
						SafeGetProperty(obResult, "strCountry", ""), SafeGetProperty(obResult, "strSkuId", "PKP1"),
						strProduct,
						"Subscriptions", SafeGetProperty(obResult, "nTotal", "0"), "1");
					
					
					cct.strInvoice = obResult.strInvoice;
					cct.cc.strCCLast4 = obResult.strLast4;
					
					if (cct.fIsGift) {
						cct.strGiftCode = obResult.strGiftCode;
						if (PicnikBase.app.IsServiceActive())
							Util.UrchinLogReport("/api/" + PicnikBase.app.AsService().apikey + "/gift" );
						fnDone( rpcresp.errorCode, rpcresp.errorMessage, cct );
					} else {
						SetRenewalSku(cct.strSkuId);

						AccountMgr.GetInstance().SetUserAttribute('cAutoRenew', 'Y');
						AccountMgr.GetInstance().DelayedCheckForPremium();							
						AccountMgr.GetInstance().RefreshUserAttributes( function():void {
							// when this refresh is done, we expect the user to be premium
							if (!AccountMgr.GetInstance().isPremium) {
								PicnikService.Log( "Postpurchase user not premium (CCBoxBase)" + AccountMgr.GetInstance().userId, PicnikService.knLogSeverityMonitor );
							}						
							UpgradePathTracker.LogPageView(cct.logEventBase, 'Success', 'CreditCard');
							UpgradePathTracker.CCStateReached("Success", Math.pow(2, 11));
							if (strUpgradePath != "not_a_purchase")
								UserBucketManager.GetInst().OnUserUpgraded(strUpgradePath);
							
							if (PicnikBase.app.IsServiceActive())
								Util.UrchinLogReport("/api/" + PicnikBase.app.AsService().apikey + "/upgrade" );
							UpgradePathTracker.LogCCStateReached();
							fnDone( rpcresp.errorCode, rpcresp.errorMessage, cct );
						});
					}
				} else {
					/* UNDONE -- turn address fields on for CC Address missing error
					if (_pdparent.fCollectAddress == false) {
					_pdparent.fCollectAddress = true;
					_pdparent.OnResize(null);
					} */
					var strLogField:String = "Unknown";
					if ('strField' in obResult && obResult.strField != null && String(obResult.strField).length > 0)
						strLogField = obResult.strField;
					UpgradePathTracker.CCStateReached("CardDenied/" + strLogField, Math.pow(2, 10));
					if ("aErrors" in rpcresp.data) {
						StoreErrors(rpcresp.data.aErrors, cct);
					}
					fnDone( rpcresp.errorCode, rpcresp.errorMessage, cct );
				}				
			}
				
			var fnOnPurchased:Function = function( rpcresp:RpcResponse ):void {
					try {
						if (rpcresp.errorCode != PicnikService.errNone) {
							// a server error occurred... bail
							PicnikService.Log( "Purchase server error. user: " + AccountMgr.GetInstance().userId +
												" errcode: " + rpcresp.errorCode +
												" msg: " + rpcresp.errorMessage,
												PicnikService.knLogSeverityError );
							PicnikRpc.AddAdminMessage("Purchase server faulted (" + (cct.fIsGift? "gift" : "purchase") + (cct.fIsPurchase ? "" : "addcard") + ")" +
								" errcode: " + rpcresp.errorCode +
								" msg: " + rpcresp.errorMessage);
							
							if (cct.fIsGift || !cct.fIsPurchase) {
								fnDone( rpcresp.errorCode, rpcresp.errorMessage, cct );		
							} else {
								// The user is attempting to upgrade.
								// Just in case the server was actually successful, force a refresh.
								AccountMgr.GetInstance().DelayedCheckForPremium();							
								AccountMgr.GetInstance().RefreshUserAttributes( function():void {
										// when this refresh is done, we expect the user to be premium
										if (!AccountMgr.GetInstance().isPremium) {
											fnDone( rpcresp.errorCode, rpcresp.errorMessage, cct );		
										} else {
											//
											rpcresp.errorCode = PicnikService.errNone;
											rpcresp.errorMessage = "";
											fnOnPurchaseSuccess(rpcresp);
										}
									});
							}						
							return;
						} else {
							fnOnPurchaseSuccess(rpcresp);
						}
					} catch (e:Error) {
						var strError:String = "PurchaseManager:SubscribeUser:Exception:" + e + ":" + e.getStackTrace();
						trace(strError);
						PicnikService.Log(strError, PicnikService.knLogSeverityError);
						PicnikRpc.AddAdminMessage("Purchase client exception (" + (cct.fIsGift? "gift" : "") + (cct.fIsPurchase ? "" : "addcard") + ")");
					}
				}
			
			if (cct.fIsGift) {
				PicnikRpc.PurchaseGift( cct, fnOnPurchased );
			} else {
				PicnikRpc.SubscribeUser( cct, fnOnPurchased );	
			}
		}
		
		// function fnDone( nError:Number, strErr:String ): void
		public function CancelAutoRenew( fnDone:Function ): void {
			RemoveCreditCard(fnDone );
		}
		
		// function fnDone( nError:Number, strErr:String, cct:CreditCardTransaction ): void
		public function CancelSubscription( fnDone:Function ): void {
			var fnOnCancelSubscription:Function = function(rpcresp:RpcResponse):void {
				if (rpcresp.errorCode != PicnikService.errNone) {
					fnDone( rpcresp.errorCode, rpcresp.errorMessage, null );
					return;
				}

				var obResult:Object = rpcresp.data;

				// report the result to analytics
				var strSite:String = SafeGetProperty(obResult, "strSite", "mywebsite.com");
				var strProduct:String = SafeGetProperty(obResult, "strProduct", "Picnik Premium - Unknown Duration");
				strProduct = strProduct.replace(/\s/g, "_") + "_(cancel)";	// replace whitespace with underscores
				Util.UrchinLogTransaction(SafeGetProperty(obResult, "strInvoice", ""), strSite,
					"-" + SafeGetProperty(obResult, "nTotal", "0"), "-" + SafeGetProperty(obResult, "nTax", "0"),
					"0", SafeGetProperty(obResult, "strCity", ""), SafeGetProperty(obResult, "strState", ""),
					SafeGetProperty(obResult, "strCountry", ""), SafeGetProperty(obResult, "strSkuId", "PKP1"),
					strProduct,
					"Subscriptions", "-" + SafeGetProperty(obResult, "nTotal", "0"), "1");			
	
				var cct:CreditCardTransaction = new CreditCardTransaction( new CreditCard() );
				
				try {
					cct.strInvoice = rpcresp.data.strInvoice;
					cct.nAmount = rpcresp.data.nAmount;
					cct.nTax = rpcresp.data.nTax;
					cct.cc.strCCLast4 = rpcresp.data.strLast4;
				} catch (e:Error) {}

				CancelAutoRenew(function( nError:Number, strError:String ): void {
					fnDone( nError, strError, cct );
				});					
			}
			PicnikRpc.CancelSubscription(fnOnCancelSubscription);
		}
		
		
		private function ArrayContains(astr:Array, str:String): Boolean {
			for each (var strFound:String in astr) {
				if (strFound == str) return true;
			}
			return false;
		}

		private function SafeGetProperty(ob:Object, strProp:String, obDefault:*=undefined): * {
			if (strProp in ob) {
				if (ob[strProp] is String)
					return String(ob[strProp]).toLowerCase();
				else
					return ob[strProp];				
			} else {
				return obDefault;
			}
		}
		
	}

}