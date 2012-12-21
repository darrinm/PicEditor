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
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	
	import mx.containers.ViewStack;
	import mx.controls.Button;
	import mx.controls.TabBar;
	import mx.core.ClassFactory;
	import mx.core.UIComponent;
	import mx.core.mx_internal;

	use namespace mx_internal;

	public class TabBarPlus extends TabBar {
		protected var _tabn:TabNavigatorPlus = null;
		public var buttonTabId:String;
		
		public function TabBarPlus(tabn:TabNavigatorPlus, fUseResizingTabs:Boolean=false) {
			_tabn = tabn;
			super();
			if (fUseResizingTabs)
		        navItemFactory = new ClassFactory(ResizingTab);
		    else
		        navItemFactory = new ClassFactory(TabPlus);
		}
		
	    protected override function clickHandler(evt:MouseEvent):void {
	    	// HACK: one of the tabs (e.g. Save & Share) can be styled as a button. When it is we
	    	// want it to have standard "click on mouse up" button behavior, not tab behavior.
	        if (simulatedClickTriggerEvent != null) {
	    		var i:Number = getChildIndex(DisplayObject(evt.currentTarget));
	    		var dob:DisplayObject = _tabn.getChildAt(i);
	    		if (dob != null && dob["id"] == buttonTabId)
	        		return;
	        }
	       
	    	var nTargetIndex:Number = getChildIndex(DisplayObject(evt.currentTarget));
	        if (nTargetIndex == selectedIndex)
	        {
	            Button(evt.currentTarget).selected = true;
	            evt.stopImmediatePropagation();
    	        return;
    	    }
    	    Button(evt.currentTarget).selected = false;
    		_tabn.doTabBarClick(nTargetIndex, evt);
	    }
	   
	    public function doClickHandler(evt:MouseEvent): void {
	    	super.clickHandler(evt);
	    }
	   
	    override protected function updateDisplayList(unscaledWidth:Number,
	                                                  unscaledHeight:Number):void {
	    	super.updateDisplayList(unscaledWidth, unscaledHeight);
	    	HideNoNavTabs();
	    }

		private function HideNoNavTabs(): void {
	    	var vstk:ViewStack = dataProvider as ViewStack;

			// walk through all the children and see if their button should be shown
			if (vstk) {
				for (var i:Number = 0; i < numChildren; i++) {
					var uic:UIComponent = getChildAt(i) as UIComponent;
					var brg:DisplayObject = vstk.getChildAt(i);
					if (brg && brg.hasOwnProperty("NoNavBar") && brg['NoNavBar']) {
						uic.visible = false;
						uic.includeInLayout = false;
					}
				}
			}
		}	   
	}
}