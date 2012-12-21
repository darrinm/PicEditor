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
package controls
{
	import mx.controls.Image;

	public class SmartLoadImage extends ImageEx
	{
		public function SmartLoadImage()
		{
			super();
		}
		
		private var _fActive:Boolean = true;
		
		public function set active(fActive:Boolean): void {
			if (_fActive == fActive) return;
			_fActive = fActive
			
			if (_fActive) {
				// Activating
				if (super.source != _obSource)
					super.source = _obSource;
			} else {
				// Deactivating
				if (!isLoaded()) {
					super.source = null;
				}
			}
		}
		
		private function isLoaded(): Boolean {
			if (source == null) return true;
			var nWidth:Number = contentWidth;
			return (!isNaN(nWidth)) && nWidth > 0;
		}
		
		private var _obSource:Object = null;
		
		public override function set source(ob:Object): void {
			if (_obSource == ob) return;
			_obSource = ob;
			SetExplicitSource( _obSource );
		}
		public override function get source(): Object {
			return _obSource;
		}
		
	}
}
