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
	import dialogs.CloudyResizingDialog;

	public class PrivacyDetourDialogBase extends CloudyResizingDialog
	{
		protected var _fnComplete:Function;
		[Bindable] public var username:String;
		[Bindable] public var freshUser:Boolean;
		
		public function PrivacyDetourDialogBase() {
			super();
		}
		
//		override protected function OnKeyDown(evt:KeyboardEvent): void {
//			if (evt.keyCode == Keyboard.ESCAPE) {
//				Cancel();
//			}
//		}
		
		public function SetCallback( fnComplete:Function ): void {
			_fnComplete = fnComplete;
		}
				
		protected function Accept(): void {
			Hide();
			if (null != _fnComplete) _fnComplete({strResult:"accepted"});
		}
		
		protected function Reject(): void {
			Hide();
			if (null != _fnComplete) _fnComplete({strResult:"rejected"});
		}
		
		protected function Cancel(): void {
			Hide();
			if (null != _fnComplete) _fnComplete({strResult:"cancelled"});
		}
	}
}
