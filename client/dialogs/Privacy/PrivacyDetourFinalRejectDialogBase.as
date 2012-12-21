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
package dialogs.Privacy
{	
	import controls.NoTipTextInput;
	
	import dialogs.RegisterHelper.FormControls.StandardEffects;
	
	import mx.controls.CheckBox;
	
	import validators.EmailValidatorPlus;
	
	public class PrivacyDetourFinalRejectDialogBase extends PrivacyDetourDialogBase
	{				
		[Bindable] public var _tiEmail:NoTipTextInput;
		[Bindable] public var _cbSendArchive:CheckBox;
		[Bindable] public var _vldEmail:EmailValidatorPlus;
		[Bindable] public var effects:StandardEffects = null;
		
		public function PrivacyDetourFinalRejectDialogBase() {
			super();
		}
				
		override protected function Reject(): void {
			// pop a busy and send a request to the server
			// First, make sure everything is valid
			_vldEmail.validate();
			if (_tiEmail.errorString.length == 0) {
				// Do the form submission
				super.Hide();
				if (null != _fnComplete) {
					_fnComplete( {
							strResult: "rejected",
							strEmail: _tiEmail.text,
							fSendArchive: _cbSendArchive.selected
						});
				}
			} else {
				if (effects && effects.effError) {
					effects.effError.end();
					effects.effError.play();
				}
			}
		}		
	}
}
