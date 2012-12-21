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

	public class CoreDialog extends Dialog {		
		public function CoreDialog() {
			super();
		}
		
		// This is here because constructor arguments can't be passed to MXML-generated classes
		// Subclasses will enjoy this function, I'm sure.
		public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			_fnComplete = fnComplete;			
		}

		// Also for subclasses. Can this be combined with OnCreationComplete ?
		public function PostDisplay(): void {
		}	
	}
}
