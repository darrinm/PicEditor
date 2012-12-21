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
	import dialogs.DialogContent.IDialogContent;
	import dialogs.DialogContent.IDialogContentContainer;

	import imagine.ImageDocument;
	
	import mx.events.FlexEvent;

	public class SendGreetingContentBase extends PageContainer implements IDialogContent {
		[Bindable] public var item:ItemInfo;
		[Bindable] public var footerHeight:Number = 0;
		[Bindable] public var imageDocument:ImageDocument;
		[Bindable] public var templateGroupId:String;
		
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			
			// OnActivate is smart and defers itself until initialization is complete.
			OnActivate();
		}
		
		// IDialogContent implementation
		private var _dcc:IDialogContentContainer;
		
		[Bindable]
		public function get container(): IDialogContentContainer {
			return _dcc;			
		}
		
		public function set container(dcc:IDialogContentContainer): void {
			_dcc = dcc;
		}
	}
}
