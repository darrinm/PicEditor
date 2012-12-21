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
package validators
{
	import mx.resources.ResourceBundle;
	import mx.validators.Validator;

	public class PicnikValidator extends Validator
	{
  		[Bindable] [ResourceBundle("PicnikValidator")] protected var _rb:ResourceBundle;

		public function PicnikValidator()
		{
			super();
			loadResources();
		}
		
		// Override in sub-classes.
		// Make sure you call super.loadResources
		// This will be called in the constructor but it should also be called
		// whenever the resource bundel changes
		protected function loadResources(): void {
			for each (var strResource:String in resourceList) {
				this[strResource] = Resource.getObject('PicnikValidator', strResource);
			}
		}
		
		protected function get resourceList(): Array {
			return [];
		}
	}
}