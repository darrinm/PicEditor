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
package containers
{
	import dialogs.RegisterHelper.FormControls.StandardBackground;
	import dialogs.RegisterHelper.FormControls.StandardCloseBox;
	
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	
	import mx.core.ContainerLayout;
	import mx.events.FlexEvent;

	public class BlueCloudsDialog extends ResizingDialog
	{
		public function BlueCloudsDialog()
		{
			super();
			
			layout = ContainerLayout.ABSOLUTE;
			
			styleName = PicnikBase.GetApp().liteUI ? 'liteDialog' : 'fixedDialog';
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}
		
		// Protected so sub-classes can set the text, add event handlers, whatever.
		protected var _stdcbx:StandardCloseBox = new StandardCloseBox();

		private var _stdbkg:StandardBackground = new StandardBackground();
		
		private function OnCreationComplete(evt:Event): void {
			setStyle("borderStyle", "solid");
			setStyle("borderThickness", "0");
			setStyle("cornerRadius", "10");
			setStyle("backgroundColor", "#85b4cc");
			setStyle("backgroundAlpha", ".75");
			
			_stdbkg.setStyle("paddingRight", 3);
			_stdbkg.setStyle("paddingTop", 3);
			_stdbkg.setStyle("paddingLeft", 3);
			_stdbkg.setStyle("paddingBottom", 3);
			addChildAt(_stdbkg, 0);
			
			_stdcbx.fnClose = Hide;
			_stdcbx.setStyle("paddingRight", 3);
			_stdcbx.setStyle("paddingTop", 3);
			_stdcbx.setStyle("paddingLeft", 3);
			_stdcbx.setStyle("paddingBottom", 3);
			addChildAt(_stdcbx, 1);

			var fltShadow:DropShadowFilter = new DropShadowFilter(2, 90, 0, .6, 12, 12, 1, 3);
			
			filters = [fltShadow];
		}
	}
}