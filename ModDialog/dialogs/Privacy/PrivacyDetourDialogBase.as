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
	
	import mx.core.UIComponent;

	public class PrivacyDetourDialogBase extends CloudyResizingDialog
	{
		[Bindable] public var username:String;
		[Bindable] public var freshUser:Boolean;
				
		// This is here because constructor arguments can't be passed to MXML-generated classes
		// Subclasses will enjoy this function, I'm sure.
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			super.Constructor(fnComplete,uicParent,obParams);
			username = obParams['username'];
			freshUser = obParams['freshUser'];
		}
		
		protected function OnComplete(obResult:Object): void {
			if (null != _fnComplete) {
				_fnComplete( obResult );
				_fnComplete = null;
			}
		}
				
		protected function Accept(): void {
			Hide();
			OnComplete({strResult:"accepted"});
		}
		
		protected function Reject(): void {
			Hide();
			OnComplete({strResult:"rejected"});
		}
		
		protected function Cancel(): void {
			Hide();
			OnComplete({strResult:"cancelled"});
		}
	}
}
