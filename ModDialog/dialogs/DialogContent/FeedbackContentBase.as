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
package dialogs.DialogContent {
	import dialogs.BusyDialogBase;
	import dialogs.IBusyDialog;
	
	import flash.events.Event;
	import flash.system.Capabilities;
	import flash.system.System;
	
	import mx.containers.Box;
	import mx.containers.HBox;
	import mx.controls.Alert;
	import mx.controls.ComboBox;
	import mx.controls.RadioButton;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
	
	import util.LocUtil;
	import util.URLLogger;
	import util.VersionStamp;
	
	public class FeedbackContentBase extends Box {
		// MXML-specified variables
		[Bindable] public var _tiLastFourDigits:TextInput;
		[Bindable] public var _tiEmailAddress:TextInput;
		[Bindable] public var _cboIssueType:ComboBox;
		[Bindable] public var _rbtnYesPremium:RadioButton;
		[Bindable] public var _rbtnNoPremium:RadioButton;		
		[Bindable] public var _taMessage:TextArea;
		[Bindable] public var _app:PicnikBase;
		[Bindable] public var OnSendFeedback:Function = function():void {};

		// The state of premium not active.
		// These are also keys into FeedbackDialog.properties
		protected static const kstrPremiumStatus_Initial:String = 'initial'; // Not checking yet. This is not a key into feedback properties.		
		protected static const kstrPremiumStatus_CheckingAccount:String = 'checkingAccount';		
		protected static const kstrPremiumStatus_LooksFineToMe:String = 'premiumnessLooksFineToMe';
		protected static const kstrPremiumStatus_Fixed:String = 'premiumnessFixed'; // We fixed it. You should be good now
		protected static const kstrPremiumStatus_NotPremium:String = 'accountNotPremium'; // This doesn't look like a premium account
		
		private var _fWasPremium:Boolean = false;
		[Bindable] protected var _strPremiumCheckStatus:String = kstrPremiumStatus_Initial;
		
		public var _strFeedbackSentNotifyMessage:String;
		
		protected var _fnComplete:Function;

		private var _bsy:IBusyDialog;		

   		[Bindable] [ResourceBundle("FeedbackDialog")] protected var _rb:ResourceBundle;

		public function FeedbackContentBase() {
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			_app = PicnikBase.app;
		}
		
		// This is here because constructor arguments can't be passed to MXML-generated classes
		public function Constructor(fnComplete:Function): void {
			_fnComplete = fnComplete;
		}
		
		protected function OnInitialize(evt:Event): void {
			ResetState();
		}

		protected function ResetState(): void {
			currentState = "";
		}
			
		public function ClearFeedback(): void {
			_tiLastFourDigits.text = "";
			_tiEmailAddress.text = "";
			_rbtnYesPremium.selected = false;
			_rbtnNoPremium.selected = false;
			_taMessage.text = "";
		}
		
		private function Reduce(ob:Object): String {
			if (ob == null) {
				return "";
			} else if (ob is Boolean) {
				return ob ? "T" : "F";
			} else if (ob is Number) {
				return Math.round(Number(ob)).toString();
			} else if (ob is Date) {
				var dt:Date = ob as Date;
				return dt.toDateString();
			} else {
				return ob.toString();
			}
		}
		
		protected function OnIssueTypeChange(fPremiumNotActivated:Boolean, fHasCredentials:Boolean): Boolean {
			if (!fHasCredentials) {
				_strPremiumCheckStatus = kstrPremiumStatus_Initial;
				_fWasPremium = false;
			} else if (fPremiumNotActivated && _strPremiumCheckStatus == kstrPremiumStatus_Initial) {
				// Start the check
				_strPremiumCheckStatus = kstrPremiumStatus_CheckingAccount;
				_fWasPremium = AccountMgr.GetInstance().isPaid;
				if (_fWasPremium) {
					AccountMgr.GetInstance().DispatchDummyIsPaidChangeEvent();
					_strPremiumCheckStatus = kstrPremiumStatus_LooksFineToMe;
				} else {
					AccountMgr.GetInstance().RefreshUserAttributes(function(): void {
						_strPremiumCheckStatus = (AccountMgr.GetInstance().isPaid) ? kstrPremiumStatus_Fixed : kstrPremiumStatus_NotPremium;
					});
				}
			}
			return true;
		}
		
		protected function GetPremiumCheckText(strState:String): String {
			if (strState == kstrPremiumStatus_Initial)
				return "";
			var str:String = LocUtil.rbSubst('FeedbackDialog', strState, AccountMgr.GetInstance().name)
			
			if (AccountMgr.GetInstance().isPaid)
				str += " " + Resource.getString('FeedbackDialog', 'helpRefreshPicnik');
			return str;
		}
		
		private function GetPremiumDiagnostics(): String {
			var strSunVisible:String = "?";
			try {
				if ('_hbxPremiumSun' in PicnikBase.app) {
					var hbx:HBox = PicnikBase.app['_hbxPremiumSun'];
					strSunVisible = Reduce(hbx.visible);
				}
			} catch(e:Error) {
				strSunVisible = "E";
			}
			return _strPremiumCheckStatus + "|" + strSunVisible +
					Reduce(AccountMgr.GetInstance().isPaid) + "|" +
					Reduce(AccountMgr.GetInstance().isPremium) + "|" +
					Reduce(PicnikConfig.freeForAll) + "|" +
					Reduce(AccountMgr.GetInstance().GetUserAttribute('strSubscription')) + "|" +
					Reduce(AccountMgr.GetInstance().dateSubscriptionExpires) + "|" +
					Reduce(new Date()) + "|" +
					Reduce(AccountMgr.GetInstance().daysUntilExpiration) + "|" +
					Reduce(AccountMgr.GetInstance().expiredDaysAgo) + "|" +
					Reduce(AccountMgr.GetInstance().isExpired) + "|" +
					Reduce(AccountMgr.GetInstance().autoRenew) + "|" +
					Reduce(AccountMgr.GetInstance().timeToRenew);
		}
			
		// Gather information about the user's current running state and send it along
		// with whatever feedback they want to send.
		public function SendFeedback(): void {
			const strLocale:String = CONFIG::locale;
			var strTimestamp:String = VersionStamp.getVersionStamp();
			
			if (_cboIssueType.selectedItem.id =='cancelSubscription') {
				OnSendFeedback({ success: true, navigate: 'settings' });
				return;
			}
			
			var strEmail:String = "";
			if (!AccountMgr.GetInstance().hasEmailAddress) {
				strEmail = _tiEmailAddress.text;
			}			
			var tpa:ThirdPartyAccount = null;
			var strService:String = PicnikBase.app.AsService().GetServiceName();
			var strApiKey:String = PicnikBase.app.AsService().GetServiceName();

			var strMessage:String = _taMessage.text;
			strMessage += "\n\n----------------";
			if (_tiLastFourDigits.text.length > 0)
				strMessage += "\nCC last 4: " + _tiLastFourDigits.text;
			if (_tiEmailAddress.text.length > 0)
				strMessage += "\nUser email: " + _tiEmailAddress.text;
			
			strMessage += "\nUser: " + AccountMgr.GetInstance().name + "/" + AccountMgr.GetInstance().GetUserId();
			strMessage += "\nUser Agent: " + Util.userAgent;
			strMessage += "\nPicnik Version: " + PicnikBase.knAppVersion + "/" + strTimestamp;
			strMessage += "\nSystem Version: " + Capabilities.version + "/" + Capabilities.os + "/" + Capabilities.manufacturer;
			strMessage += "\nResolution: " + stage.width + "x" + stage.height + "/" +
							Capabilities.screenResolutionX + "x" + Capabilities.screenResolutionY;
			strMessage += "\ntotalMemory: " + Util.FormatBytes(System.totalMemory);	
			strMessage += "\nPrmDiag: " + GetPremiumDiagnostics();
			
			// Hack for Flickr/etc support team
			if (strService) {
				tpa = AccountMgr.GetThirdPartyAccount(strService);
				if (tpa != null) {
					var strAccountDetails:String = "\n" + strServiceName + " userid: " + tpa.GetUserId();
					strMessage += strAccountDetails;
				}
			}		
						
			var strSubject:String = "";
			var strServiceName:String = PicnikBase.app.AsService().GetServiceFriendlyName();
			var strLanguage:String = (CONFIG::locale == "en_US") ? "" : (CONFIG::locale.substr(0, 2).toUpperCase() + ": ");
			strServiceName = strServiceName ? strServiceName = strServiceName.toUpperCase() + ": " : "";
			if (AccountMgr.GetInstance().isPaid || (!AccountMgr.GetInstance().hasCredentials && _rbtnYesPremium.selected)) {
				strSubject += "Premium: "
			} else {
				strSubject += "Feedback: "
			}
			
			strSubject += _cboIssueType.selectedItem.data + ": ";
			strSubject += strServiceName + ": ";
			strSubject += strLanguage;
			
			// NOTE: e4x is awesome and automatically escapes the strings we give it
			var xmlUrlLog:XML = XML( URLLogger.Dump() );
			var xml:XML =
			<feedback user={AccountMgr.GetInstance().GetUserId()} subject={strSubject}>
				<message>
					{strMessage}
				</message>
				<email>
					{strEmail}
				</email>
				<accounts>
				</accounts>
				<appState
					version={PicnikBase.knAppVersion}
					build={strTimestamp}
					locale={strLocale}
					apikey={strApiKey}
					tab={PicnikBase.app.selectedTabName}
					subtab={PicnikBase.app.selectedSubTabName}
				/>
				<flashState
					stageWidth={stage.width}
					stageHeight={stage.height}
					screenResolutionX={Capabilities.screenResolutionX}
					screenResolutionY={Capabilities.screenResolutionY}
					flashVersion={Capabilities.version}
					os={Capabilities.os}
					manufacturer={Capabilities.manufacturer}
				/>
				<userAgent>
					{Util.userAgent}
				</userAgent>
				// removed urllog because it can be huge and is currently being ignored by the server
				//<urllog>
				//	{xmlUrlLog}
				//</urllog>
			</feedback>;
			
			// Create a list of 3rd-party accounts
			for each (tpa in AccountMgr.accounts) {
				if (tpa.GetUserId())
					xml.accounts.appendChild(<account service={tpa.name} userid={tpa.GetUserId()} token={tpa.GetToken()}/>);
			}
			
			if (PicnikBase.app.activeDocument != null) {
				var obState:Object = PicnikBase.app.activeDocument.GetState();
				for (var strName:String in obState)
					try {
						xml.documentState[strName] = obState[strName];
					} catch (e:Error) {
						// ignore -- GalleryDocuments props element can fire a 
						// Error #2090: The Proxy class does not implement callProperty. It must be overridden by a subclass.	
					}	
			}
	
			PicnikService.SendFeedback(xml, OnSendFeedbackDone);
			_bsy = BusyDialogBase.Show(this, Resource.getString('FeedbackDialog', 'sending_feedback'), BusyDialogBase.OTHER, "IndeterminateNoCancel", 0);
			
			Util.UrchinLogReport("/feedback/" + (AccountMgr.GetInstance().isPaid ? "premium" : "free") + "/" +
					PicnikBase.app.selectedTabName + "/" + PicnikBase.app.selectedSubTabName);
		}
		
		private function OnSendFeedbackDone(nError:Number, strError:String): void {
			_bsy.Hide();
			_bsy = null;
			
			if (nError != PicnikService.errNone) {
				Util.ShowAlert(LocUtil.rbSubst('FeedbackDialog', 'feedback_send_failed', nError) , "Error", Alert.OK,
						"ERROR:send feedback failed: " + nError + ", " + strError);
			} else {
				PicnikBase.app.Notify(_strFeedbackSentNotifyMessage);
			}
				
			if (_fnComplete != null)
				_fnComplete({ success: nError == PicnikService.errNone });
				
			if (nError == PicnikService.errNone)
				OnSendFeedback({ success: true });
		}
	}
}
