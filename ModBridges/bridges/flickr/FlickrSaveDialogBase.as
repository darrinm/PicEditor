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
package bridges.flickr {
	import containers.Dialog;
	import containers.TabNavigatorPlus;
	import containers.ResizingDialog;
	import flash.events.TextEvent;
	import flash.events.KeyboardEvent;
	import com.adobe.utils.StringUtil;
	
	import flash.display.DisplayObject;
	import flash.ui.Keyboard;
	
	import mx.core.Container;
	import mx.core.UIComponent;
	import mx.containers.Canvas;
	
	public class FlickrSaveDialogBase extends ResizingDialog {

		override protected function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.ESCAPE) {
				Hide();
			}
		}		
	}
}
