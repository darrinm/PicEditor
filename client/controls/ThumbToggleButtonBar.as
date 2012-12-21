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
package controls {
	import bridges.Bridge;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.containers.ViewStack;
	import mx.controls.Button;
	import mx.core.Container;
	import mx.core.IFlexDisplayObject;
	import mx.core.IInvalidating;
	import mx.core.UIComponent;
	import mx.effects.easing.Quintic;
	import mx.events.ChildExistenceChangedEvent;
	import mx.events.FlexEvent;
	import mx.skins.ProgrammaticSkin;
	import mx.styles.ISimpleStyleClient;

	import picnik.util.Animator;

	[Style(name="selectedThumbSkin", type="Class", inherit="no")]

	// This class implements a toggle button bar with a thumb/nubbin underneath the
	// selected button.
	// use the "selectedThumbSkin" style to set the skin for the thumb/nubbin.
	public class ThumbToggleButtonBar extends ToggleButtonBarPlus
	{
		private var _dobThumb:DisplayObject = null;

		private static const kstrSelectedThumbSkinName:String = "selectedThumbSkin";
		
		public function ThumbToggleButtonBar() {
			super();			
		}

	    override protected function clickHandler(event:MouseEvent):void
	    {
	    	var vstk:ViewStack = dataProvider as ViewStack;
	    	if (vstk == null) {
	    		$clickHandler(event);
	    	} else {
	    		var actl:IActionListener = vstk.selectedChild as IActionListener;
	    		if (!actl) {
		    		$clickHandler(event);
	    		} else {
   			        var nIndex:int = getChildIndex(Button(event.currentTarget));
	    			actl.PerformActionIfSafe(new Action(SelectIndex, nIndex));
	    		}
		    }
	    }
	   
	    public function SelectIndex(nIndex:Number): void {
	    	selectedIndex = nIndex;
	    }

	    protected function $clickHandler(event:MouseEvent):void {
	    	super.clickHandler(event);
	    }
		
		protected override function initializationComplete():void {
			super.initializationComplete();
			addEventListener(FlexEvent.VALUE_COMMIT, OnSelectedIndexChange);
			
			// We need to know when children are removed by the state change to FlickrSubset
			// so we can update the thumb. We con't care about children being added at the
			// moment because we don't have any cases doing that.
			addEventListener(ChildExistenceChangedEvent.CHILD_REMOVE, OnChildRemove);
			createThumb();
		}
		
		private function OnChildRemove(evt:ChildExistenceChangedEvent): void {
			// This event is received BEFORE the child is actually removed. callLater
			// so our update happens AFTER the button is gone.
			callLater(UpdateThumb);
		}
		
		public function OnSelectedIndexChange(evt:FlexEvent): void {
			UpdateThumb();
		}
		
		protected function get thumbContainer(): Container {
			// Inject the thumb into the parent of this object
			// This will allow the thumb to overlay other sibblings.
			return Container(parent);
		}
		
		// Inspired by Button.as, viewSkinForPhase()
		// Create the thumb skin
		protected function createThumb(): void {
			var strSkinName:String = kstrSelectedThumbSkinName; // Change this when we support multiple skins?
			
			// Has this skin already been created?
			var dobSkin:IFlexDisplayObject =
				IFlexDisplayObject(thumbContainer.rawChildren.getChildByName(strSkinName));

			// If not, create it.
			if (!dobSkin)
			{
				var newSkinClass:Class = Class(getStyle(strSkinName));
				if (newSkinClass)
				{
					dobSkin = IFlexDisplayObject(new newSkinClass());
	
					// Set its name so that we can find it in the future
					// using getChildByName().
					dobSkin.name = strSkinName;
	
					// Make the getStyle() calls in ButtonSkin find the styles
					// for this Button.
					var styleableSkin:ISimpleStyleClient = dobSkin as ISimpleStyleClient;
					if (styleableSkin)
						styleableSkin.styleName = this;
						
					thumbContainer.rawChildren.addChild(DisplayObject(dobSkin));
	
					// If the skin is programmatic, and we've already been
					// initialized, update it now to avoid flicker.
					if (dobSkin is IInvalidating && initialized)
					{
						IInvalidating(dobSkin).validateNow();
					}
					else if (dobSkin is ProgrammaticSkin && initialized)
					{
						ProgrammaticSkin(dobSkin).validateDisplayList()
					}
	
					// Keep track of all skin children that have been created.
					_dobThumb = DisplayObject(dobSkin);
					_dobThumb.visible = false;
				}
			}
			UpdateThumb(); // Make sure we position the thumb correctly
		}
		
		private var _amtr:Animator;

	    override protected function updateDisplayList(unscaledWidth:Number,
	                                                  unscaledHeight:Number):void
	    {
	    	super.updateDisplayList(unscaledWidth, unscaledHeight);
	    	UpdateThumb();
	    }

		public function UpdateThumb(): void {
	    	var vstk:ViewStack = dataProvider as ViewStack;
	    	var fShowThumb:Boolean = true;

			// walk through all the buttons and see if they should be shown
			if (vstk) {
				for (var i:Number = 0; i < numChildren; i++) {
					var uic:UIComponent = getChildAt(i) as UIComponent;
					var brg:DisplayObject = vstk.getChildAt(i);
					if (brg && brg.hasOwnProperty("NoNavBar") && brg['NoNavBar']) {				
						uic.visible = false;
						uic.includeInLayout = false;
						if (i == selectedIndex) {
							fShowThumb = false;
						}
					}
				}
				
				if (vstk.selectedIndex != selectedIndex)
					fShowThumb = false;
			}
			
			if (fShowThumb && _dobThumb && selectedIndex >= 0) {
				var nIndex:Number = selectedIndex;
				var btnSel:Button = Button(getChildAt(nIndex));
				while (!btnSel.visible && nIndex > 0) {
					// the selected button might be invisible because it was
					// replaced with a drop-down menu item. We'll make the
					// thumb position point to somewhere after the previous visible item.
					nIndex--;
					btnSel= Button(getChildAt(nIndex));
				}
				var pt:Point;
				if (nIndex == selectedIndex) {
					pt = new Point(btnSel.x + btnSel.width / 2 - _dobThumb.width / 2, btnSel.y + btnSel.height);				
				} else {
					// we want to point somewhere AFTER btnSel.
					// HACK it would be nice to determine the extra X offset programmatically
					pt = new Point(btnSel.x + btnSel.width + 17, btnSel.y + btnSel.height);				
				}
								
				pt = localToGlobal(pt);
				pt = thumbContainer.globalToLocal(pt);
				_dobThumb.y = Math.round(pt.y); // Keep it pixel aligned
				if (!_dobThumb.visible) {
					_dobThumb.visible = true;
					_dobThumb.x = Math.round(pt.x);
				} else {
					if (_amtr)
						_amtr.Dispose();
					_amtr = new Animator(_dobThumb, "x", NaN, Math.round(pt.x), 333, Quintic.easeOut);
				}
			} else if (_dobThumb) {
				// send it offstage
				_dobThumb.x = -100 - _dobThumb.width;
			}
		}
	}
}
