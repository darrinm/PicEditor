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
package dialogs.RegisterHelper
{
	import com.adobe.utils.StringUtil;
	
	import dialogs.DialogManager;
	import dialogs.RegisterDialogBase;
	import dialogs.RegisterHelper.FormControls.StandardEffects;
	
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TextEvent;
	
	import mx.containers.Box;
	import mx.events.FlexEvent;

	// This is the base class for members of the RegisterDialog viewstack
	// It adds support for:
	//  - htmlText event:selectTab. links to viewstack tabs. example:
	//      <a href="event:selectTab._rbxLogin">Login</a>
	//  - a globalError bindable string which allows conditional display of non-field related errors
	//  - an errors bindable boolean which is true whenever any validation fails or a form submit has failed.
	//     - Listens to all validator members of _avld for validation changes to update the errors boolean
	//  - supports a "validateAll()" function to validate all fields
	public class RegisterBoxBase extends Box
	{
		private var _fWorking:Boolean = false;
		private var _formOwner:IFormContainer = null;
		private var _obDefaults:Object = null;
		
		[Bindable] public var _app:PicnikBase;
		private var _fComponentsCreated:Boolean = false;

		// are we upgrading?  if so, by CC or PayPal?  Or are we redeeming a gift code?
		protected var _eRegisterAction:int = RegisterDialogBase.NO_ACTION;

		protected var _fInline:Boolean;		
		
		[Bindable] public var logEventBase:String = "register";
		[Bindable] public var logExtraEvent:String = null;
		
		[Bindable] public var effects:StandardEffects = null;
		[Bindable] public var formIsDirty:Boolean = false;
		
		[Bindable] public function set registerAction(e:int): void {
			_eRegisterAction = e;
			// This is a bit of a hack to work around a flex bug - we need to make sure
			// we don't change state until child components are created.
			updateStateIfNeeded();
		}

		// strResult should be one of: abandon, googleLogin, pincikLogin, picnikRegister
		protected var _fLogGoogleResults:Boolean = false;
		protected function LogGoogleResults(strResult:String): void {
			if (_fLogGoogleResults) {
				Util.UrchinLogReport("/googleLogin/path/" + (PicnikConfig.googleLoginEnabled ? "googleOn" : "googleOff") + "/" + strResult); 
				_fLogGoogleResults = false;
			}
		}
		
		public function get registerAction(): int {
			return _eRegisterAction;
		}

		public function get isUpgrading(): Boolean {
			return registerAction == RegisterDialogBase.UPGRADE_PAYMENT_SELECTOR
				|| registerAction == RegisterDialogBase.UPGRADE_CREDIT
				|| registerAction == RegisterDialogBase.UPGRADE_PAYPAL;
		}
		
		protected function updateState(): void {
			if (_fInline)
				currentState = "Inline";
			if (isUpgrading)
				currentState = "Upgrading" + (PicnikBase.app.flickrlite ? "Flickr" : "");
			if (registerAction == RegisterDialogBase.REDEEM_GIFT)
				currentState = "RedeemingGift";				
			if (registerAction == RegisterDialogBase.HELP_HUB)
				currentState = "HelpHub";				
		}

		protected function updateStateIfNeeded(): void {
			if (_fComponentsCreated && noState) {
				updateState();
			}
		}
		
		[Bindable]
		public function get Inline(): Boolean {
			return _fInline;
		}
		
		public function set Inline( fInline:Boolean ):void {
			_fInline = fInline;
		}
			
		[Bindable]
		public function get working(): Boolean {
			return _fWorking;
		}
		public function set working(fWorking:Boolean): void {
			_fWorking = fWorking;
			if (formOwner) formOwner.working = fWorking;
		}
		
		public function RegisterBoxBase() {
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			addEventListener(Event.ACTIVATE, OnActivate);
			addEventListener(Event.DEACTIVATE, OnDeactivate);
			_app = PicnikBase.app;
		}
		
		private function get noState(): Boolean {
			return (currentState == null || currentState == "");
		}
		
		// This is a bit of a hack to work around a flex bug - we need to make sure
		// we don't change state until child components are created.
		// This is the best way to know our child components have been created.
		override public function createComponentsFromDescriptors(recurse:Boolean=true):void {
			super.createComponentsFromDescriptors(recurse);
			if (dataModel && _obDefaults) dataModel.SetValues( _obDefaults );			
			_fComponentsCreated = true;
			updateStateIfNeeded();
		}
								
		public function OnSelect(): void {
			// override in sub classes to set the focus when the tab is selected
		}
		
		private function OnActivate(evt:Event): void {
			// SWF is active
		}
		
		private function OnDeactivate(evt:Event): void {
			// SWF is inactive (user clicks on some other window)
		}
		
		private function OnInitialize(evt:FlexEvent): void {
			// Listen for html anchor text events
			addEventListener(TextEvent.LINK, OnLink);
			if (dataModel) dataModel.Init();
			OnSelect();
		}

		public function get formOwner(): IFormContainer {
			if (_formOwner) return _formOwner;
			
			var docParent:DisplayObjectContainer = this.parent;
			while (docParent && !(docParent is IFormContainer))	
				docParent = docParent.parent;

			_formOwner = docParent as IFormContainer;			
			return _formOwner;
		}

		public function OnEscape(evt:KeyboardEvent): void {
			LogGoogleResults("abandon");
			if (formOwner) formOwner.Hide();
		}
		
		private function OnLink(evt:TextEvent): void {
			var strTargetState:String = null;
			var nBreakPos:Number = -1;
			var strPayload:String = "";
			var strPayloadName:String = "";
			
			if (StringUtil.beginsWith(evt.text.toLowerCase(), "hide")) {
				Hide();
			} else if (StringUtil.beginsWith(evt.text.toLowerCase(), "feedback")) {
				DialogManager.Show("FeedbackDialog");
			} else if (StringUtil.beginsWith(evt.text.toLowerCase(), "currentstate=")) {
				strTargetState = evt.text.substr("currentState=".length);
				nBreakPos = strTargetState.indexOf('&');
				if (nBreakPos > -1) {
					strPayloadName = strTargetState.substr(nBreakPos+1);
					strPayloadName = strPayloadName.substr("payload=".length);
					strTargetState = strTargetState.substr(0, nBreakPos);
					if (formOwner && strPayloadName in formOwner) {
						strPayload = formOwner[strPayloadName];
					}
				}
				if (formOwner) {
					formOwner.SelectForm( strTargetState, {payload:strPayload});
				}
			} else  if (StringUtil.beginsWith(evt.text.toLowerCase(), "pushstate=")) {
				strTargetState = evt.text.substr("pushstate=".length);
				nBreakPos = strTargetState.indexOf('&');
				if (nBreakPos > -1) {
					strPayloadName = strTargetState.substr(nBreakPos+1);
					strPayloadName = strPayloadName.substr("payload=".length);
					strTargetState = strTargetState.substr(0, nBreakPos);
					if (formOwner && strPayloadName in formOwner) {
						strPayload = formOwner[strPayloadName];
					}
				}
				if (formOwner) {
					formOwner.PushForm( strTargetState, {payload:strPayload});
				}
			} else  if (StringUtil.beginsWith(evt.text.toLowerCase(), "signinwithgoogle")) {
				DoGoogleLogIn();
			}
		}
		
		protected function DoGoogleLogIn(): void {
			throw new Error("Subclasses must override DoGoogleLogIn");
		}
			
		// Called exactly once whenever this dialog comes up
		// Used for nav tracking
		public function OnShow(): void {
			UpgradePathTracker.LogPageView(logEventBase, null, logExtraEvent);
		 	PicnikBase.app.modalPopup = true;
		}
		
		// Hide the dialog
		protected function Hide(): void {
			LogGoogleResults("abandon");
			if (formOwner) formOwner.Hide();
		 	PicnikBase.app.modalPopup = false;
		}
		
		// Errors and effects
		protected function DoErrorEffect():void {
			if (effects && effects.effError) {
				effects.effError.end();
				effects.effError.play();
			}
		}
		
		// Data modeling functions
		protected function get dataModel(): DataModel {
			if ("_dtmFormFields" in this) return this["_dtmFormFields"] as DataModel;
			else return null; // Not found. Error.
		}

		protected function GetFieldValue(strFieldName:String): Object {
			return dataModel.GetValue(strFieldName);
		}
		
		public function SetFormDefaults( obValues:Object ): void {
			_obDefaults = obValues;
			if (dataModel) dataModel.SetValues( _obDefaults );
		}
		
		public function GetFormValues(): Object {
			return dataModel.GetValues();
		}
		
		public function ClearErrors(): void {
			if (dataModel) dataModel.ClearErrors();
		}
		
		public function ResetValues():void {
			registerAction = RegisterDialogBase.NO_ACTION;
			if (dataModel) dataModel.resetAll();
		}
		
		// some handy boolean processors
		public function and(... args:Array): Boolean {
			var fRet:Boolean = true;
			for each (var f:Boolean in args) {
				fRet = fRet && f;
				if (!fRet) break;
			}
			return fRet;
		}
		
		public function or(... args:Array): Boolean {
			var fRet:Boolean = false;
			for each (var f:Boolean in args) {
				fRet = fRet || f;
				if (fRet) break;
			}
			return fRet;
		}
		
		public function iff(f:Boolean, obTrue:Object, obFalse:Object): Object {
			return f ? obTrue : obFalse;
		}
	}
}
