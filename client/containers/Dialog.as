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
package containers {
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import mx.containers.TitleWindow;
	import mx.controls.Button;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.events.EffectEvent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	import mx.states.Transition;

	public class Dialog extends TitleWindow {
		[Bindable] public var _btnCancel:Button;
		[Bindable] public var _trn:Transition;

		protected var _fnComplete:Function;
		
		public function Dialog() {
			super();
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}
		
		// Show the dialog centered over the passed in uicParent and modal
		public function Show(uicParent:UIComponent, strTopic:String=null): void {
			PopUpManager.addPopUp(this, uicParent, true);
			PopUpManager.centerPopUp(this);
		}
		
		public function Hide(): void {
			// Don't hide until any in-progress effect is done playing
			if (_trn && _trn.effect.isPlaying) {
				_trn.effect.addEventListener(EffectEvent.EFFECT_END, OnEffectEnd);
				return;
			}
			PopUpManager.removePopUp(this);
		}
		
		protected function OnInitialize(evt:Event): void {
			if (PicnikBase.app.liteUI) {
				setStyle("styleName", "liteDialog");
				setStyle("dropShadowEnabled", "true");
			}
			
			addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown); // To capture ESC
			_btnCancel.addEventListener(MouseEvent.CLICK, OnCancelClick);
			addEventListener(CloseEvent.CLOSE, OnCancelClick);
		}
		
		// For subclasses		
		protected function OnCreationComplete(evt:FlexEvent): void {
		}
		
		private function OnEffectEnd(evt:EffectEvent): void {
			PopUpManager.removePopUp(this);
		}
		
		protected function OnCancel(): void {
			if (_fnComplete != null)
				_fnComplete({ success: false, choice: "cancel" });
			Hide();
		}
	
		protected function OnCancelClick(evt:Event): void {
			OnCancel();
		}
	
		// PORT: create a Dialog base class w/ this? (and _dctArgs/arguments property,
		// OnInitialize event adder/handler, default OnCancel
		private function OnKeyDown(evt:KeyboardEvent):void {
			if (evt.keyCode == Keyboard.ESCAPE)
				OnCancel();
		}
	}
}
