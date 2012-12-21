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
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	import imagine.ImageDocument;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
	
	import util.ISendGreetingPage;

	public class SendGreetingDialogBase extends GreetingResizingDialog {
  		[Bindable] [ResourceBundle("SendGreetingDialogBase")] protected var _rb:ResourceBundle;
		[Bindable] public var templateGroupId:String;
		
		// This is here because constructor arguments can't be passed to MXML-generated classes
		// Subclasses will enjoy this function, I'm sure.
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			super.Constructor(fnComplete, uicParent, obParams);
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
			Util.UrchinLogReport("/sendgreeting/invokesuccess/" + (obParams ? obParams.strSource : "unknown") +
					((PicnikBase.app.activeDocument as ImageDocument) != null ? "/image" : "/noimage"));					
		}

		private function OnCreationComplete(evt:FlexEvent):void {
			if (_obParams && ("templateGroupId" in _obParams)) {
				templateGroupId = _obParams.templateGroupId;
				currentState = _obParams.templateGroupId;
			}
		}
		
		override protected function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.ESCAPE) {
				Hide();
			} else if (evt.keyCode == Keyboard.ENTER) {
			}
		}
		
		// Defaults to true.
		public function get useOpenDocument(): Boolean {
			if (_obParams && ('fUseOpenDocument' in _obParams))
				return _obParams.fUseOpenDocument;
			return true;
		}
	}
}
