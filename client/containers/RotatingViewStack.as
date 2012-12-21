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
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.utils.*;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.containers.ViewStack;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	public class RotatingViewStack extends ViewStack{
		
		private var _nDelay:Number = 6000;
		private var _fRotating:Boolean = true;
		private var _fPauseRotating:Boolean = false;
		private var _nTimerId:Number;
		private var _fTransitioning:Boolean = false;

		[Bindable] public var UnbrokenTransitions:Boolean = false;
		
		public function RotatingViewStack(): void {
			resizeToContent = true;
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			addEventListener(MouseEvent.ROLL_OUT, OnRollOut);
			addEventListener(MouseEvent.ROLL_OVER, OnRollOver);
		}

		private function OnInitialize(evt:FlexEvent): void {
			// Watch the enabled state of every child in the stack. If a child becomes
			// disabled while it is visible, move on to the next child.
			for (var i:int = 0; i < numChildren; i++) {
				var uic:UIComponent = getChildAt(i) as UIComponent;
				Debug.Assert(uic != null);
				ChangeWatcher.watch(uic, "enabled", OnChildEnabledChange);
			}
			
			StartTimer();
			if (selectedChild != null) {
				if (!selectedChild.enabled) {
					Next();
				}
				selectedChild.dispatchEvent(new FlexEvent(FlexEvent.SHOW));
			}
		}
		
		private function OnChildEnabledChange(evt:Event): void {
			if (evt.target == selectedChild && !(evt.target as UIComponent).enabled)
				Next();
		}

		private function OnRollOut(evt:MouseEvent): void {
			_fPauseRotating = false;
		}

		private function OnRollOver(evt:MouseEvent): void {
			_fPauseRotating = true;
		}

		[Bindable]
		public function set rotating(f:Boolean): void {
			if (_fRotating != f) {
				_fRotating = f;
				StartTimer();
			}
		}
		
		public function get rotating(): Boolean {
			return _fRotating;
		}
		
		[Bindable]
		public function set delay(ms:Number): void {			
			_nDelay = ms;
			StartTimer();
		}
		
		public function get delay(): Number {
			return _nDelay;
		}
		
		public function Next(): void {
			if (_fTransitioning) return;
			selectedChild.endEffectsStarted();
			var nIndex:Number = selectedIndex + 1;
			if (nIndex >= getChildren().length) nIndex = 0;
			var dob:DisplayObject = getChildAt(nIndex);
			var nCount:Number = 0;
			while (dob && 'enabled' in dob && !dob['enabled'] && nCount < getChildren().length) {
				nIndex++;
				nCount++;
				if (nIndex >= getChildren().length) nIndex = 0;
				dob = getChildAt(nIndex);
			}
			SelectNewChild(nIndex);			
		}
		
		public function Previous(): void {
			var nIndex:Number = selectedIndex - 1;
			if (nIndex < 0) nIndex = getChildren().length - 1;
			var dob:DisplayObject = getChildAt(nIndex);
			var nCount:Number = 0;
			while (dob && 'enabled' in dob && !dob['enabled'] && nCount < getChildren().length) {
				nIndex--;
				nCount++;
				if (nIndex < 0) nIndex = getChildren().length - 1;
				dob = getChildAt(nIndex);
			}
			SelectNewChild(nIndex);			
		}

		private function OnChildShow(evt:FlexEvent):void {
			_fTransitioning = false;
			selectedChild.removeEventListener(FlexEvent.SHOW, OnChildShow);
		}
		
		private function SelectNewChild(index:Number): void {
			// to prevent effects from getting all broken,
			// we ignore select requests while transitioning
			if (_fTransitioning) return;
			selectedChild.endEffectsStarted();
			
			if (UnbrokenTransitions) {
				var dobNew:DisplayObject = getChildAt(index);
				if (dobNew) {
					dobNew.addEventListener(FlexEvent.SHOW, OnChildShow);			
					_fTransitioning = true;
				}
			}
			ResetTimer();
			selectedIndex = index;			
		}	
			
		private function ResetTimer(): void {
			StartTimer();
		}
		
		private function StartTimer(): void {
			if (_nTimerId) {
				clearTimeout(_nTimerId);
				_nTimerId = 0;
			}
			if (_fRotating)
				_nTimerId = setTimeout(_onTimeout, delay);			
		}
		
		private function _onTimeout(): void {
			if (_fRotating && !_fPauseRotating) {
				Next();
			}
			StartTimer();
		}
	}
}
