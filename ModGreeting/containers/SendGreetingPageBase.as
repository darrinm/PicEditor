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
	
	import containers.SendGreetingContentBase;
	
	import mx.containers.Canvas;
	import mx.containers.ViewStack;
	
	import pages.Page;
	
	import util.ISendGreetingPage;
	
	public class SendGreetingPageBase extends Page implements ISendGreetingPage {
		
		[Bindable] public var footerHeight:Number = 0;
		[Bindable] public var greetingParent:SendGreetingContentBase = null;
		
		private var _nStepIndex:Number = 0;
		
		[Bindable]
		public function set StepIndex(n:Number): void {
			_nStepIndex = n;
		}
		
		public function get StepIndex(): Number {
			return _nStepIndex;	
		}		
				
	}
}
