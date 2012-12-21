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
	import bridges.*;
	import controls.GalleryPreview;
	import mx.containers.ViewStack;
	import mx.core.Container;
	import mx.core.ContainerCreationPolicy;
	import mx.events.FlexEvent;
	import dialogs.DialogContent.IDialogContent;
	import dialogs.DialogContent.IDialogContentContainer;

	public class ShareBridgesBase extends PageContainer implements IDialogContent {
		
		[Bindable] public var _galPreview:GalleryPreview;
		[Bindable] public var item:ItemInfo;
		[Bindable] public var footerHeight:Number = 0;
		[Bindable] public var selectedBridge:ShareBridge = null;
		
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
		}
		
		protected override function ServiceToPage(strService:String): String {
			switch (strService.toLowerCase()) {
			case "email":
				return ShareBridge.EMAIL_SUB_TAB;
			case "embed":
				return ShareBridge.EMBED_SUB_TAB;
			}
			// Default
			return ShareBridge.EMAIL_SUB_TAB; // email!
		}
		
		public override function get defaultTab(): String {
			return ShareBridge.EMAIL_SUB_TAB;
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
		
		override public function OnActivate(strCmd:String=null):void {
			super.OnActivate(strCmd);
			selectedBridge = _vstk.selectedChild as ShareBridge;
			
			// this is necessary to force the label to redraw and position itself correctly.  :(
			selectedBridge.label = selectedBridge.label + " ";
			_galPreview.Activate();
		}		
		
		override public function OnDeactivate():void {
			super.OnDeactivate();
			_galPreview.Deactivate();
		}
		
		override protected function OnViewStackIndexChange(evtT:Event): void {
			super.OnViewStackIndexChange(evtT);
			selectedBridge.OnDeactivate();
			selectedBridge = _vstk.selectedChild as ShareBridge;
			selectedBridge.OnActivate(null);
		}
	}
}
