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
	import com.adobe.utils.StringUtil;
	
	import dialogs.RegisterHelper.IFormContainer;
	import dialogs.RegisterHelper.RegisterBoxBase;
	
	import flash.events.TextEvent;
	
	import mx.containers.Canvas;
	import mx.resources.ResourceBundle;
	
	public class LoginTrioBase extends Canvas implements IFormContainer {

   		[Bindable] [ResourceBundle("LoginTrio")] protected var _rb:ResourceBundle;
   		[Bindable] public var activeForm:RegisterBoxBase;
   		[Bindable] public var minimal:Boolean = false;

		public function LoginTrioBase() {
		}
						
		protected function OnLink(evt:TextEvent): void {
			if (StringUtil.beginsWith(evt.text.toLowerCase(), "currentstate=")) {
				var strTargetState:String = evt.text.substr("currentstate=".length);
				currentState = strTargetState;
			}
		}		
		
		// IFormContainer interface
		public function SelectForm( strName:String, obDefaults:Object = null ): void {
			currentState = strName;
			if (obDefaults && activeForm) {
				for (var key:String in obDefaults) {
					if (key in activeForm) {
						activeForm[key] = obDefaults[key];
					}
				}
			}
		}

		public function PushForm( strName:String, obDefaults:Object = null ): void {
			// "stacked" dialogs aren't required in our case, so regular
			// SelectForm will do just fine
			SelectForm( strName, obDefaults);
		}

		public function GetActiveForm(): RegisterBoxBase {
			return activeForm;
		}

		public function Hide(): void {
			// not supported
		}

		public function set working( fWorking:Boolean ): void {
			// not supported
		}
		public function get working(): Boolean {
			// not supported
			return false;
		}		
	}
}
