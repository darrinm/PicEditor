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
package pages {
	import mx.containers.Canvas;

	public class Page extends Canvas implements IActivatable {
		// used by UrlKit to compose the URL including this 'page'
		public var urlkit:String;

		// prevents this page from appearing in the navbar, even if it's selected
		[Bindable] public var noNavBar:Boolean = false;

		//
		// IActivatable implementation
		//
		
		private var _fActive:Boolean = false;
		
		public function OnActivate(strCmd:String=null): void {
			if (_fActive)
				trace("Ignoring ERROR: Page.OnActivate: active bridge being reactivated");
			active = true;
		}
		
		public function OnDeactivate(): void {
			if (!_fActive)
				trace("Ignoring ERROR: Page.OnDeactivate: inactive bridge being deactivated");
			active = false;
		}

		[Bindable]
		public function set active(fActive:Boolean): void {
			if (fActive && !_fActive)
				dispatchEvent(new Event("activate2"));
			_fActive = fActive;
		}
		
		public function get active(): Boolean {
			return _fActive;
		}
		
		//
		//
		//
		
		// Wrapper for base NavigateTo
		public function NavigateTo(strTab:String, strSubTab:String = null): void {
			PicnikBase.app.NavigateTo(strTab, strSubTab);
		}
	}
}
