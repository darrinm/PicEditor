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
	import containers.CoreDialog;
	
	import dialogs.DialogContent.FeedbackContent;
	
	import flash.events.Event;
	
	import mx.controls.Button;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	import mx.resources.ResourceBundle;
	
	public class FeedbackDialogBase extends CoreDialog {
		// MXML-specified variables
		[Bindable] public var _feedback:FeedbackContent;

   		[Bindable] [ResourceBundle("FeedbackDialog")] protected var rb:ResourceBundle;
		
		// This is here because constructor arguments can't be passed to MXML-generated classes
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			super.Constructor(fnComplete, uicParent, obParams);
			this.addEventListener(Event.RESIZE, OnResize );
		}		

		override public function PostDisplay():void {
			if (AccountMgr.GetInstance().isPaid)
				AccountMgr.GetInstance().DispatchDummyIsPaidChangeEvent();
		}

		protected function OnResize(evt:Event): void {
			PopUpManager.centerPopUp(this);
		}		
	}
}
