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
package dialogs {
	
	import api.RpcResponse;
	
	import com.adobe.utils.StringUtil;
	
	import containers.Dialog;
	
	import dialogs.DialogContent.UserWelcome;
	import dialogs.DialogManager;
	import dialogs.RegisterHelper.UpgradePathTracker;
	
	import flash.net.URLRequest;
	
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	import mx.resources.ResourceBundle;
	
	import util.AdManager;
	import util.DynamicLocalConnection;
	import util.KeyVault;
	import util.ModLoader;
	import util.NextNavigationTracker;
	
	public class DialogManager {

		private static var s_mdm:DialogManager; // ModalDialogManager singleton

  		[Bindable] [ResourceBundle("DialogManager")] protected var _rb:ResourceBundle;
		
		private var _fModalDialogMode:Boolean = false;
		private var _fPopupSecureDialogs:Boolean = false;
		private var _lconPicnik:DynamicLocalConnection = null;
		private var _modules:Object = {};
		
		private var _dlgBlockedPopup:DialogHandle = null;
		
		private static function inst(): DialogManager {
			if (s_mdm == null) {
				s_mdm = new DialogManager();
			}
			return s_mdm;
		}

		public static function IsModalDialogMode():Boolean {
			return inst()._fModalDialogMode;
		}
		
		public static function SetModalDialogMode(f:Boolean):void {
			inst()._fModalDialogMode = f;
		}
		
		public static function PopupSecureDialogs( fPopEm:Boolean = true ):void {
			inst()._fPopupSecureDialogs = fPopEm;
		}

		public static function ShowUpgrade(strPath:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): void {
			NextNavigationTracker.OnClick("/upgrade" + strPath);
			inst()._ShowUpgrade(strPath, uicParent,fnComplete,obDefaults);
		}		
		
		private function _ShowUpgrade( strPath:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): void {
			RegisterDialogBase.ShowUpgrade(strPath, uicParent, fnComplete, obDefaults);	
		}
		
		public static function ShowFreeForAllSignIn(strPath:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): void {
			NextNavigationTracker.OnClick("/upgrade" + strPath);
			inst()._ShowFreeForAllSignIn(strPath, uicParent,fnComplete,obDefaults);
		}				
		
		private function _ShowFreeForAllSignIn( strPath:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): void {
			RegisterDialogBase.ShowFreeForAllSignIn(strPath, uicParent, fnComplete, obDefaults);	
		}

		public static function ShowPurchase(strPath:String, uicParent:UIComponent=null, fnComplete:Function=null,
				obDefaults:Object=null, fInitPath:Boolean=true, fLogUpgradePath:Boolean=false): void {
			inst()._ShowPurchase(strPath, uicParent, fnComplete, obDefaults, fInitPath, fLogUpgradePath);
		}		
		private function _ShowPurchase(strPath:String, uicParent:UIComponent=null, fnComplete:Function=null,
				obDefaults:Object=null, fInitPath:Boolean=true, fLogUpgradePath:Boolean=false): void {
			
			var fnOnRegister:Function = function(): void {
				if (AccountMgr.GetInstance().hasCredentials) {
					AdManager.GetInstance().OnUpgradeWindowShow();
							
					if (fLogUpgradePath) {
						UrchinLogReportHelper('/upgrade_path', strPath);
						UpgradePathTracker.Init('Purchase', strPath);
					}
							
					if (AccountMgr.GetInstance().isPaid && !AccountMgr.GetInstance().timeToRenew)
						return; // User is not eligible to upgrade
					
					if (fInitPath)
						UrchinLogReportHelper('/paymentselector_path', strPath);
					
					if (null == obDefaults) {
						obDefaults = {}
					}
					obDefaults['strSourceEvent'] = strPath;
					DialogManager.Show( 'PurchaseDialog', uicParent, fnComplete, obDefaults );
					
				} else if (fnComplete != null) {
					fnComplete();
				}
			}

			if (!AccountMgr.GetInstance().hasCredentials) {
				RegisterDialogBase.Show(uicParent, fnOnRegister, obDefaults);
			} else {
				fnOnRegister();
			}
		}
		
		public static function ShowGiveGift(strPath:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): void {
			inst()._ShowGiveGift(strPath,uicParent,fnComplete,obDefaults);
		}
		
		private function _ShowGiveGift( strPath:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): void {
			if (!IsModalDialogMode() && _fPopupSecureDialogs) {
				PicnikBase.app.NavigateToURLInPopup( "/app?mdlg=give&path="+strPath+"&_apikey="+PicnikBase.app.AsService().apikey+"&locale="+PicnikBase.Locale(), 700, 600, fnComplete );
			} else {
				// try to let the dialog manager show us because maybe
				// we're using the new way to display the GiftUpsellDialog
				if (obDefaults) {
					obDefaults['strPath'] = strPath;
				} else {
					obDefaults = {strPath: strPath};
				}
				DialogManager.Show("GiftUpsellDialog", uicParent, fnComplete, obDefaults);
				
			}
		}
		
		private function _ShowGiftCard( strPath:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): void {
			// try to let the dialog manager show us because maybe
			// we're using the new way to display the GiftPrintEmailDialog
			if (obDefaults) {
				obDefaults['strPath'] = strPath;
			} else {
				obDefaults = {strPath: strPath};
			}
			DialogManager.Show("GiftPrintEmailDialog", uicParent, fnComplete, obDefaults);
		}
				
		public static function ShowShareItemBySetId( strSetId:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null ):void {			
			var fnDone:Function = fnComplete;
			if (inst()._fModalDialogMode) {
				fnDone = inst().OnAllDone
			}			
			DialogManager.Show("ShareContentDialog", uicParent, fnDone, { setid: strSetId, service: "gallery" });
		}
		
		public static function ShowShareItemById( strId:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null ):void {			
			var fnDone:Function = fnComplete;
			if (inst()._fModalDialogMode) {
				fnDone = inst().OnAllDone
			}			
			DialogManager.Show("ShareContentDialog", uicParent, fnDone, { id: strId, service: "gallery" });
		}
				
		public static function ShowShareItem( item:ItemInfo, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null ):void {
			var fnDone:Function = fnComplete;
			if (inst()._fModalDialogMode) {
				fnDone = inst().OnAllDone
			}			
			DialogManager.Show("ShareContentDialog", uicParent, fnDone, { item: item });
		}	
							
		public static function ShowLogin(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): void {
			inst()._ShowLogin(uicParent,fnComplete,obDefaults);
		}		
		private function _ShowLogin( uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): void {
			if (!IsModalDialogMode() && _fPopupSecureDialogs) {
				_PopupLoginOrRegister( "login" );
			} else {
				RegisterDialogBase.ShowLogin(uicParent, fnComplete, obDefaults);			
			}
		}

		public static function ShowRegister(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): void {
			inst()._ShowRegister(uicParent, fnComplete, obDefaults);
		}		
		private function _ShowRegister( uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null): void {
			if (!IsModalDialogMode() && _fPopupSecureDialogs) {
				_PopupLoginOrRegister( "register" );
			} else {
				RegisterDialogBase.Show(uicParent, fnComplete, obDefaults);			
			}
		}
				
		private function _PopupLoginOrRegister( strDialog:String ): void {
			var fnCloseConnection:Function = function(): void {
				try {
					_bsy.Hide();			
					_lconPicnik.close();
				} catch (e:Error) {
					//
				}
				_lconPicnik = null;
			}

			if (null == _lconPicnik) {
				_lconPicnik = new DynamicLocalConnection();
				_lconPicnik.allowPicnikDomains();
				_lconPicnik["successMethod"] = function(strCBParams:String=null): void {
					fnCloseConnection();
					var obParams:Object = util.Unpickler.loads(strCBParams);		
					if ('token' in obParams) {			
						AccountMgr.GetInstance().UserInitiatedLogIn(AccountMgr.GetTokenLogInCredentials(obParams['token']),
								function(resp:RpcResponse): void {
									if (strDialog == "login") {		
										PicnikBase.app.Notify(Resource.getString('LoginTab', '_strSuccessFeedbackMessage'),500);
									} else {
										PicnikBase.app.Notify(Resource.getString('RegisterTab', '_strSuccessFeedbackMessage'),500);
									}
								} );
					} else {
						AccountMgr.GetInstance().RefreshUserAttributes();
					}
				};

				_lconPicnik["failureMethod"] = function(str:String=null): void {
					fnCloseConnection();
				}
			
				try {
					_lconPicnik.connect("picnikAuth");
				} catch (e:Error) {
					trace( "DialogManager: can't connect to picnikAuth local connection" );
				}
			}
			
			var fnOnCancel:Function = function(obResult:Object):void {
				fnCloseConnection();
			}
			var _bsy:IBusyDialog = BusyDialogBase.Show(PicnikBase.app, Resource.getString("DialogManager", "openingPicnikWindow"), BusyDialogBase.OTHER, "", 0, fnOnCancel);
			PicnikBase.app.NavigateToURLInPopup( PicnikService.serverURL + "/app?mdlg=" + strDialog+"&locale="+PicnikBase.Locale(), 600, 400,
					function(err:Number, strErr:String, strResult:String):void {
						if (PicnikService.errFail != err) {
							_bsy.Hide();
							var strMessage:String = Resource.getString("DialogManager", (strDialog=="login")?"waitingForLogin":"waitingForRegister");
							_bsy = BusyDialogBase.Show(PicnikBase.app, strMessage, BusyDialogBase.OTHER, "", 0, fnOnCancel);
						}
					} );
		}
		
		// TODO(steveler): remvoe ShowPaymentSelector everywhere
		public static function ShowPaymentSelector(strSourceEvent:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null, fInitPath:Boolean=true): void {
			inst()._ShowPaymentSelector(strSourceEvent,uicParent,fnComplete,obDefaults);
		}		
		private function _ShowPaymentSelector(strSourceEvent:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null, fInitPath:Boolean=true): void {
			if (!IsModalDialogMode() && _fPopupSecureDialogs) {
				var fnCloseConnection:Function = function(): void {
					try {
						_bsy.Hide();			
						_lconPicnik.close();
					} catch (e:Error) {
						//
					}
					_lconPicnik = null;
				}
	
				if (null == _lconPicnik) {
					_lconPicnik = new DynamicLocalConnection();
					_lconPicnik.allowPicnikDomains();
					_lconPicnik["successMethod"] = function(strCBParams:String=null): void {
						fnCloseConnection();
						AccountMgr.GetInstance().RefreshUserAttributes();
					};
	
					_lconPicnik["failureMethod"] = function(str:String=null): void {
						fnCloseConnection();
					}
				
					try {
						_lconPicnik.connect("picnikAuth");
					} catch (e:Error) {
						trace( "DialogManager: can't connect to picnikAuth local connection" );
					}
				}
				var fnOnCancel:Function = function(obResult:Object):void {
					fnCloseConnection();
				}
				var _bsy:IBusyDialog = BusyDialogBase.Show(PicnikBase.app, Resource.getString("DialogManager", "openingPicnikWindow"), BusyDialogBase.OTHER, "", 0, fnOnCancel);
				PicnikBase.app.NavigateToURLInPopup( "/app?mdlg=paysel&path="+strSourceEvent+"&_apikey="+PicnikBase.app.AsService().apikey+"&locale="+PicnikBase.Locale(), 600, 600, 						
						function(err:Number, strErr:String, strResult:String):void {
							if (PicnikService.errFail != err) {
								_bsy.Hide();
								var strMessage:String = Resource.getString("DialogManager", "waitingForUpgrade");
								_bsy = BusyDialogBase.Show(PicnikBase.app, strMessage, BusyDialogBase.OTHER, "", 0, fnOnCancel);
							}
						} );

			} else {
				DialogManager.ShowPurchase(strSourceEvent, uicParent, fnComplete, obDefaults, fInitPath);
			}
		}		
		
		
		public static function ShowRedeemGift(strSourceEvent:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null, fInitPath:Boolean=true): void {
			inst()._ShowRedeemGift(strSourceEvent,uicParent,fnComplete,obDefaults);
		}		
		private function _ShowRedeemGift(strSourceEvent:String, uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null, fInitPath:Boolean=true): void {
			// try to let the dialog manager show us because maybe
			// we're using the new way to display the GiftRedeemDialog
			if (obDefaults) {
				obDefaults['strPath'] = strSourceEvent;
			} else {
				obDefaults = {strPath: strSourceEvent};
			}
			
			var fnShowRedeemGift:Function = function(): void {
				if (AccountMgr.GetInstance().hasCredentials) {
					DialogManager.Show("GiftRedeemDialog", uicParent, fnComplete, obDefaults);
				}
			};
			
			if (!AccountMgr.GetInstance().hasCredentials) {
				RegisterDialogBase.Show(uicParent, fnShowRedeemGift, obDefaults);
			} else {
				fnShowRedeemGift();	
			}
			
		}
		
		public static function ShowForgotPW(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null, fInitPath:Boolean=true): void {
			inst()._ShowForgotPW(uicParent,fnComplete,obDefaults);
		}		
		private function _ShowForgotPW(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null, fInitPath:Boolean=true): void {
			RegisterDialogBase.ShowForgotPW(uicParent, fnComplete, obDefaults);			
		}
		
		public static function ShowLostEmail(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null, fInitPath:Boolean=true): void {
			inst()._ShowLostEmail(uicParent,fnComplete,obDefaults);
		}
		private function _ShowLostEmail(uicParent:UIComponent=null, fnComplete:Function=null, obDefaults:Object=null, fInitPath:Boolean=true): void {
			RegisterDialogBase.ShowLostEmail(uicParent, fnComplete, obDefaults);
		}

		public static function ShowRegisterTab(strTab:String, uicParent:UIComponent=null, fnComplete:Function=null, obParams:Object=null): RegisterDialog {
			return inst()._ShowRegisterTab(strTab, uicParent, fnComplete, obParams);			
		}
		
		private function _ShowRegisterTab(strDialog:String, uicParent:UIComponent=null, fnComplete:Function=null, obParams:Object=null): RegisterDialog {
			return RegisterDialogBase.ShowForm(strDialog, uicParent, fnComplete, obParams);
		} 		
		
		
		public static function Hide(dialogHandle:DialogHandle): void {
			inst()._Hide(dialogHandle);			
		}
		
		private function _Hide(dialogHandle:DialogHandle): void {
			if (dialogHandle) dialogHandle.Hide();
		}
	
		public static function HideBlockedPopupDialog(): void {
			inst()._HideBlockedPopupDialog();
		}
		
		private function _HideBlockedPopupDialog(): void {
			_Hide(_dlgBlockedPopup);
		}

		public static function Show(strDialog:String, uicParent:UIComponent=null, fnComplete:Function=null, obParams:Object=null): DialogHandle {
			return inst()._Show(strDialog, uicParent,fnComplete,obParams);			
		}
		
		private function _Show(strDialog:String, uicParent:UIComponent=null, fnComplete:Function=null, obParams:Object=null): DialogHandle {
			var dialogHandle:DialogHandle = new DialogHandle(strDialog, uicParent, fnComplete, obParams);
			var strModule:String = null;
			
			// ModAccount dialogs
			if (null == strModule) {
				switch (strDialog) {
					case "CancelPaypalDialog":
					case "ChangeEmailDialog":
					case "ChangePasswordDialog":
					case "ChangePerformanceDialog":
					case "ConfirmCancelDialog":
					case "ConfirmDelAcctDialog":
					case "GiftPrintEmailDialog":
					case "GiftRedeemDialog":
					case "GiftUpsellDialog":
					case "PurchaseDialog":
					case "PurchaseGiftDialog":
					case "ReceiptDialog":
					case "SettingsDialog":
					case "TargetedUpsellDialog":
						strModule = "ModAccount";
						break;
				}
			}
			
			// ModDialog dialogs
			if (null == strModule) {
				switch (strDialog) {
					case "AskForPremiumDialog":
					case "GoogleMergeDialog":
					case "BlockedPopupDialog":
					case "ConfirmApplyEffectDialog":
					case "ConfirmCancelDialog":
					case "ConfirmDelAcctDialog":
					case "ConfirmDeleteDialog":
					case "ConfirmLoadOverEditDialog":
					case "ConfirmOverwriteDialog":
					case "CreateAlbumDialog":
					case "FeedbackDialog":
					case "GalleryPrivacyDialog":
					case "HelpDialog":
					case "NewCanvasDialog":
					case "PartyInviteDialog":
					case "PrivacyDetourDialog":
					case "PrivacyDetourConfirmRejectDialog":
					case "PrivacyDetourFinalRejectDialog":
					case "PrivacyDetourCompleteRejectDialog":
					case "PublishTemplateDialog":
					case "SettingsDialog":
					case "ShareContentDialog":
						strModule = "ModDialog";
						break;
				}
			}			
			
			// ModBridges dialogs
			if (null == strModule) {
				switch (strDialog) {
					case "FlickrSaveDialog":
						strModule = "ModBridges";
						break;
				}
			}			
			
			// ModGreeting dialogs
			if (null == strModule) {
				switch (strDialog) {
					case "SendGreetingDialog":
						Util.UrchinLogReport("/sendgreeting/invoke/" + (obParams ? obParams.strSource : "unknown"));					
						strModule = "ModGreeting";
				}			
			}
			
			if (!strModule) {
				// dialog not found!
				dialogHandle = null;
			} else {			
				if (strModule in _modules && _modules[strModule]['module'] != null) {
					dialogHandle.ProxyLoaded(_modules[strModule]['module']);
				} else {
					if (!(strModule in _modules) || _modules[strModule]['loader'] == null) {
						_modules[strModule] = {
								loader: new ModLoader( strModule, function(obResult:Object):void {
												_modules[strModule]['module'] = obResult;
											}),
								module: null
							};
						
					}
					dialogHandle.ProxyLoad(_modules[strModule]['loader']);
				}
	
				if (strDialog == "BlockedPopupDialog") {
					_dlgBlockedPopup = dialogHandle;
				}
			}
			
			return dialogHandle;
		}
		
		public static function HandleShowDialogParam(strDialog:String, obDialogParams:Object): Boolean {
			return inst()._HandleShowDialogParam(strDialog, obDialogParams);
		}		
		private function _HandleShowDialogParam(strDialog:String, obDialogParams:Object): Boolean {
			if (strDialog.length > 0) {		
				var strPath:String = "/golink";
				var strReport:String = null;
				if ('path' in obDialogParams)
					strPath = obDialogParams['path'];
								
				// navigating to a loadable module and showing a dialog at the same time
				// can fire an exception in the Flex ModuleManager, so prevent that here.
				PicnikBase.DeepLink = "/home";
					
				switch (strDialog) {
					
				// these dialogs might be opened up in "dialog_mode".
				case "gift":
					if ("path1" in obDialogParams) {
						obDialogParams["giftCode"] = obDialogParams["path1"];
					}
					obDialogParams["fReturnToPaymentSelector"] = false;
					_ShowRedeemGift(strPath, PicnikBase.app, null, obDialogParams);
					break;
					
				case "upgrade":
					_ShowUpgrade(strPath, PicnikBase.app, OnUpgrade);
					break;
					
				case "give":
					_ShowGiveGift(strPath, PicnikBase.app, OnGiveGift);
					break;
					
				case "login":
					_ShowLogin(PicnikBase.app, OnLoginOrRegister);
					break;
					
				case "help":
					//DialogManager.Show("HelpDialog", PicnikBase.app, null, {navigate:"help"});
					PicnikBase.DeepLink = "/home/HelpHub";
					break;
					
				case "settings":
					PicnikBase.DeepLink = "/home/settings";
					break;
				
				case "register":
					_ShowRegister(PicnikBase.app, OnLoginOrRegister);
					break;
					
				case "paysel":
					_ShowPaymentSelector(strPath,PicnikBase.app, OnUpgrade);
					break;

				case "giftcard":
					if ("path1" in obDialogParams) {
						obDialogParams["giftCode"] = obDialogParams["path1"];
					}
					_ShowGiftCard("/golink", PicnikBase.app, null, obDialogParams);
					break;

				case "partyinvite":
					DialogManager.Show("PartyInviteDialog");
					break;

				case "forgotpw":
					_ShowForgotPW(PicnikBase.app);
					break;					
																
				case "lostemail":
					_ShowLostEmail(PicnikBase.app);
					break;

				case "resetpw":
					if ("path1" in obDialogParams) {
						obDialogParams["email"] = obDialogParams["path1"];
					}
					if ("path2" in obDialogParams) {
						obDialogParams["token"] = obDialogParams["path2"];
					}
					RegisterDialogBase.ShowForgotPWReset(PicnikBase.app, null, obDialogParams);
					break;
					
				case "share":
					if ("id" in obDialogParams)
						ShowShareItemById(obDialogParams["id"]);
					else
						ShowShareItemBySetId(obDialogParams["setid"]);
					break;
					
				case "askforpremium":
					DialogManager.Show("AskForPremium", PicnikBase.app);
					break;

				case "soccerfever":
				case "footballfever":
					PicnikBase.DeepLink = "/create/featured";
					//PicnikConfig.worldCup = true;
					
					strReport = "/soccerfever/tryitnow/";
					if ('geoip' in KeyVault.GetInstance() && 'country' in KeyVault.GetInstance().geoip) {
						strReport += KeyVault.GetInstance().geoip.country + "/";
					}
					Util.UrchinLogReport(strReport);					
					break;
				
				case "halloween":
					PicnikBase.DeepLink = "/create/featured";
					break;				

				case "backtoschool":
					PicnikBase.DeepLink = "/advancedcollage/grid";					
					strReport = "/backtoschool/tryitnow/";
					if ('geoip' in KeyVault.GetInstance() && 'country' in KeyVault.GetInstance().geoip) {
						strReport += KeyVault.GetInstance().geoip.country + "/";
					}
					Util.UrchinLogReport(strReport);
					break;
				
				case "touchup":
					PicnikBase.DeepLink = "/create/touchup";
					strReport = "/touchup/landingpage/";
					if ('geoip' in KeyVault.GetInstance() && 'country' in KeyVault.GetInstance().geoip) {
						strReport += KeyVault.GetInstance().geoip.country + "/";
					}
					Util.UrchinLogReport(strReport);		
					break;
				
				case "weddings":
					PicnikBase.DeepLink = "/advancedcollage";
					strReport = "/weddings/landingpage/";
					if ('geoip' in KeyVault.GetInstance() && 'country' in KeyVault.GetInstance().geoip) {
						strReport += KeyVault.GetInstance().geoip.country + "/";
					}
					Util.UrchinLogReport(strReport);		
					break;
				
				case "feedback":
				case "contact":
					Show("FeedbackDialog", null, function(res:Object):void {
							if (res && "navigate" in res && res['navigate'] == "settings") {
								PicnikBase.app.NavigateToMyAccount();
							}
						});
					break;
					
				case "showusermessage":
					UserMessageDialog.Show(PicnikBase.app, obDialogParams['msg']);
					break;
				
				case "holidaygreeting":
					Show("SendGreetingDialog", null, null, {strSource: 'golink', templateGroupId: "holidayGreetings_picnik"});
					break;
				
				case "vdaygreeting":
					Show("SendGreetingDialog", null, null, {strSource: 'golink', templateGroupId: "vdayGreetings_picnik"});
					break;
				}
						
				Session.GetCurrent().SetSOCookie("show_dialog", "", false);
				Session.GetCurrent().SetSOCookie("show_dialog_params", "", true);
				return true;
			}
			
			return false;
		}		

		// Clear out any values the user has given us
		public static function ResetDialogs(): void {
			RegisterDialogBase.ResetValues();
		}
		
		private function OnUpgrade(): void {
			if (_fModalDialogMode) {
				var strUrl:String = "/callback/picnik/?";
				var obParams:Object = {
					userid: AccountMgr.GetInstance().GetUserId(),
					token: PicnikService.GetUserToken(),
					tokencookie: PicnikService.GetUserTokenCookie() };
				for (var k:String in obParams) {
					strUrl += k + '=' + escape(obParams[k]) + '&';
				}
				PicnikBase.app.NavigateToURL( new URLRequest(strUrl) );
			}
		}

		private function OnGiveGift(): void {
			if (_fModalDialogMode) {
				PicnikBase.app.NavigateToURL( new URLRequest("/picnikauth") );
			}
		}
			
		private function OnLoginOrRegister(): void {
			if (_fModalDialogMode) {
				var strUrl:String = "/callback/picnik/?";
				var obParams:Object = {
					userid: AccountMgr.GetInstance().GetUserId()
				};
				
				if (AccountMgr.GetInstance().hasCredentials) {
					obParams.token = PicnikService.GetUserToken();
					obParams.tokencookie = PicnikService.GetUserTokenCookie();
				}
				
				for (var k:String in obParams) {
					strUrl += k + '=' + escape(obParams[k]) + '&';
				}
				PicnikBase.app.NavigateToURL( new URLRequest(strUrl) );
			}
		}			
		
		private function OnAllDone(): void {
			if (_fModalDialogMode) {
				PicnikBase.app.NavigateToURL( new URLRequest("/alldone") );
			}
		}

		// TODO(bsharon): Apparently unused?
		private function OnForgotPassword(): void {
			if (_fModalDialogMode) {
				PicnikBase.app.NavigateToURL( new URLRequest("/picnikauth") );
			}
		}
		
		// common function for notifying Urchin about dialogs/tabs being displayed
		private function UrchinLogReportHelper(strPath:String, strEvent:String): void {
			if (strEvent == null) strEvent = "";
			if (strEvent.length > 0 && strEvent.charAt(0) != '/')
				strEvent = '/' + strEvent;
			strEvent = strPath + strEvent;
			strEvent = StringUtil.replace(strEvent, ' ', '_');
			Util.UrchinLogReport(strEvent);
		}
				
	}
}
