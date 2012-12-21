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
	import flash.events.MouseEvent;
	
	import mx.containers.TabNavigator;

	public class TabNavigatorPlus extends TabNavigator {
		protected var _tbp:TabBarPlus = null;
		[Bindable] public var maxTabBarWidth:Number = 1200;
		[Bindable] public var _tabBarLeftPadding:Number = 0;
		[Bindable] public var _tabBarRightPadding:Number = 0;
		private var _fCenterTabs:Boolean = true;
		[Bindable] public var resizingTab:Boolean = false;
		
		override protected function updateDisplayList(unscaledWidth:Number,  unscaledHeight:Number): void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if (tabBar.width > 0) {
				tabBar.width = width - tabBarLeftPadding - tabBarRightPadding;
				var cxExtraLeftSpace:Number = 0;
				if (tabBar.width > maxTabBarWidth) {
					if (_fCenterTabs)
						cxExtraLeftSpace = (tabBar.width - maxTabBarWidth) / 2;
					tabBar.width = maxTabBarWidth;
				}
				tabBar.move(cxExtraLeftSpace + tabBarLeftPadding, tabBar.y);
			}
		}

		[Bindable]
		public function get tabBarLeftPadding():Number {
			return _tabBarLeftPadding;
		}
		
		public function set tabBarLeftPadding(n:Number):void {
			_tabBarLeftPadding = n;
			invalidateDisplayList();
		}
		
		[Bindable]
		public function get tabBarRightPadding():Number {
			return _tabBarRightPadding;
		}
		
		public function set tabBarRightPadding(n:Number):void {
			_tabBarRightPadding = n;
			invalidateDisplayList();
		}
		
		public function set centerTabs(f:Boolean): void {
			_fCenterTabs = f;
			invalidateDisplayList();
		}
		
		public function set buttonTabId(strId:String): void {
			if (_tbp)
				_tbp.buttonTabId = strId;
		}
		
	    public function doTabBarClick(nTargetIndex:Number, evt:MouseEvent): void {
	    	var actl:IActionListener = selectedChild as IActionListener;
	    	if (actl) {
	    		actl.PerformActionIfSafe(new Action(select, nTargetIndex));
	    	} else {
	    		_tbp.doClickHandler(evt);
		    }
	    }
	   
	    public function select(nTargetIndex:Number): void {
			// trace("select: target: " + nTargetIndex + ", selected: " + selectedIndex);
	    	if (selectedIndex != nTargetIndex) {
	    		selectedIndex = nTargetIndex;
	    	}
	    }
	   
	    override protected function createChildren():void
	    {
	        super.createChildren();
	        if (!(tabBar is TabBarPlus)) {
	        	_tbp = new TabBarPlus(this, resizingTab);
	            _tbp.name = tabBar.name;
	            _tbp.focusEnabled = tabBar.focusEnabled;
	            _tbp.styleName = tabBar.styleName;
	
	            _tbp.setStyle("borderStyle", tabBar.getStyle("borderStyle"));
	            _tbp.setStyle("paddingTop", tabBar.getStyle("paddingTop"));
	            _tbp.setStyle("paddingBottom", tabBar.getStyle("paddingBottom"));
	            rawChildren.removeChild(tabBar);
	            rawChildren.addChild(_tbp);
	            tabBar = _tbp;
	        }
		
			/*
	        if (!tabBar)
	        {
	            tabBar = new TabBar();
	            tabBar.name = "tabBar";
	            tabBar.focusEnabled = false;
	            tabBar.styleName = this;
	
	            tabBar.setStyle("borderStyle", "none");
	            tabBar.setStyle("paddingTop", 0);
	            tabBar.setStyle("paddingBottom", 0);
	
	            rawChildren.addChild(tabBar);
	        }
	        */
	    }
	}
}
