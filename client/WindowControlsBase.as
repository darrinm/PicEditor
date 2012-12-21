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
package {
	import controls.FullscreenNotifier;
	
	import dialogs.DialogManager;
	
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	
	import mx.containers.HBox;
	import mx.controls.Button;
	import mx.events.EffectEvent;
	import mx.events.FlexEvent;
	
	import util.ExternalService;
	
	public class WindowControlsBase extends HBox {
		[Bindable] public var _btnFullscreen:Button;
		[Bindable] public var _btnExpand:Button;
		[Bindable] public var _btnClose:Button;
		
		[Bindable] public var closeTarget:String = null;
		[Bindable] public var closeTargetLabel:String = null;
		
		private var _fsn:FullscreenNotifier = new FullscreenNotifier();
		
		public function WindowControlsBase() {
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
		}
		
		public function ToggleFullscreen(): void {
			try {
				if (stage.displayState == StageDisplayState.FULL_SCREEN) {
					stage.displayState = StageDisplayState.NORMAL;
				} else {
					stage.displayState = StageDisplayState.FULL_SCREEN;
					
					// Set up the notifier
					if (_fsn.parent != PicnikBase.app) {
						PicnikBase.app.addChild(_fsn);
					} else { // Currently playing.
						_fsn._effNotify.removeEventListener(EffectEvent.EFFECT_END, OnTransitionEnd);
						_fsn._effNotify.end();
					}
		
					// Center the notify canvas. Actually not quite centered to match the FP's message
					_fsn.x = Math.round((PicnikBase.app.width - _fsn.width) / 2) + 42;
					_fsn.y = Math.round((PicnikBase.app.height) / 2.7) + 68;
					_fsn.visible = true;
					_fsn.alpha = 1.0;
		
					// Start the effect
					_fsn._effNotify.addEventListener(EffectEvent.EFFECT_END, OnTransitionEnd);
					_fsn._effNotify.play();
				}
			} catch (err:Error) {
				// ignore
			}
		}
		
		private function OnInitialize(evt:FlexEvent): void {
			_btnFullscreen.addEventListener(MouseEvent.CLICK, OnFullscreenClick);
			_btnExpand.addEventListener(MouseEvent.CLICK, OnExpandClick);
			_btnClose.addEventListener(MouseEvent.CLICK, OnCloseClick);
			addEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
		}

		private function OnAddedToStage(evt:Event): void {
			// Detect transition from fullscreen back to normal to clear _btnFullscreen's toggled state
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, OnFullScreenChange);
		}
		
		// Full-screen toggle handler
		private function OnFullscreenClick(evt:MouseEvent): void {
			if (AccountMgr.GetInstance().isPremium)
				ToggleFullscreen();
			else {
				_btnFullscreen.selected = false;
				DialogManager.ShowUpgrade( "/fullscreen", PicnikBase.app );
			}
		}
		
		private function OnTransitionEnd(evt:Event): void {
			// Clean up the notifier after the effect finishes.
			PicnikBase.app.removeChild(_fsn);
			_fsn._effNotify.removeEventListener(EffectEvent.EFFECT_END, OnTransitionEnd);
		}

		private function OnFullScreenChange(evt:FullScreenEvent): void {
			if (evt.fullScreen) {
				_btnExpand.enabled = false;
			} else {
				_btnFullscreen.selected = false;
				_btnExpand.enabled = true;
				_fsn._effNotify.end();
			}
		}
		
		private function OnExpandClick(evt:MouseEvent): void {
            if (ExternalInterface.available)
				ExternalInterface.call("expand", _btnExpand.selected);
		}
		
		private function OnCloseClick(evt:MouseEvent): void {
			PicnikBase.app.LiteUICancel();
		}
	}
}

