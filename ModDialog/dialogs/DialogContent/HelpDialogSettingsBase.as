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
	
	import dialogs.RegisterHelper.RegisterBoxBase;
	import dialogs.RegisterHelper.IFormContainer;
	import dialogs.DialogManager;
	
	import flash.display.DisplayObject;
	import flash.events.TextEvent;
	
	import mx.containers.Canvas;
	import mx.containers.ViewStack;
	import mx.resources.ResourceBundle;
	
	public class HelpDialogSettingsBase extends Canvas implements IFormContainer {
   		[Bindable] [ResourceBundle("HelpDialogSettings")] protected var _rb:ResourceBundle;
   		[Bindable] public var _vstk:ViewStack;
   		
		private var _aPopupStack:Array = [];
	
		protected function OnLink(evt:TextEvent): void {
			if (StringUtil.beginsWith(evt.text.toLowerCase(), "currentstate=")) {
				var strTargetState:String = evt.text.substr("currentstate=".length);
				currentState = strTargetState;
			}
			if (StringUtil.beginsWith(evt.text.toLowerCase(), "action=")) {
				var strTargetAction:String = evt.text.substr("action=".length);
				if (strTargetAction == "upgrade") {
					DialogManager.ShowUpgrade("/flickr_settings", PicnikBase.app);
				}
			}
		}

		// IFormContainer implements	
		[Bindable]	
		public function set working( fWorking:Boolean ): void {
			// not supported
		}
		public function get working(): Boolean {
			// not supported
			return false;
		}	

		public function SelectForm( strName:String, obDefaults:Object = null): void {
			var doChild:DisplayObject = _vstk.getChildByName(strName);
			_vstk.selectedIndex = _vstk.getChildIndex(doChild);
			
			var activeForm:RegisterBoxBase = GetActiveForm();
			if (obDefaults && activeForm) {
				for (var key:String in obDefaults) {
					if (key in activeForm) {
						activeForm[key] = obDefaults[key];
					}
				}
			}
		}
		
		public function PushForm( strName:String, obDefaults:Object = null ): void {
			_aPopupStack.push( _vstk.selectedChild.name );
			SelectForm( strName, obDefaults );
		}
				
		public function GetActiveForm(): RegisterBoxBase {
			var rbx:RegisterBoxBase = _vstk.selectedChild as RegisterBoxBase;
			return rbx;			
		}
		
		public function Hide(): void {			
			if (_aPopupStack.length > 0) {
				SelectForm( _aPopupStack.pop() );
			}
		}
		
		
	}		
}
