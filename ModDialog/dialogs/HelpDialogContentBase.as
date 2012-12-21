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
package dialogs {
	import com.adobe.utils.StringUtil;
	
	import containers.TabNavigatorPlus;
	
	import dialogs.DialogContent.HelpHubContent;
	
	import flash.display.DisplayObject;
	import flash.events.TextEvent;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.containers.Canvas;
	import mx.core.Container;
	import mx.events.FlexEvent;
		
	[Event(name="canceled", type="flash.events.Event")]
	
	public class HelpDialogContentBase extends Canvas {
		[Bindable] public var _helpHub:HelpHubContent;

		private var _chwHasCredentials:ChangeWatcher;
		private var _strMode:String;

		public function HelpDialogContentBase() {
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}
				
		private function OnCreationComplete(evt:Event): void {
			_helpHub.OnActivate();
		}
	}
}
