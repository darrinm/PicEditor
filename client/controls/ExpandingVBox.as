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
package controls
{
	import flash.geom.Point;
	
	import mx.containers.VBox;
	import mx.core.Container;
	import mx.core.UIComponent;
	import mx.effects.Resize;
	import mx.events.EffectEvent;
	import mx.events.ResizeEvent;

[Style(name="gradientFillColors", type="Array", arrayType="Number", inherit="no")]
[Style(name="gradientFillAlphas", type="Array", arrayType="Number", inherit="no")]
[Style(name="gradientFillRatios", type="Array", arrayType="Number", inherit="no")]
/*

[Style(name="border-skin", type="Class", inherit="no")]
[Style(name="border-style", type="String", enumeration="inset,outset,solid,none", inherit="no")]
[Style(name="border-thickness", type="Number", format="Length", inherit="no")]
*/
	public class ExpandingVBox extends VBox
	{
		public var nExpandTargetPos:Number = 1;

		private var _fExpanded:Boolean = true;
    	private var _effResize:Resize;
    	private var _ctrScrollParent:Container = null;
	
		public function ExpandingVBox()
		{
			super();
			setStyle("verticalGap", 0);
		}
		
		public function get scrollContainer(): Container {
			if (!_ctrScrollParent) {
				var ctr:Container = parent as Container;
				while (ctr && ctr.verticalScrollBar == null) {
					ctr = ctr.parent as Container;
				}
				_ctrScrollParent = ctr;
			}
			return _ctrScrollParent;
		}
		
		private function OnResizeComplete(evt:EffectEvent): void {
			// Reset the full height to be dynamic
			// that way, we can resize if our children are collapsed/expanded.
			if (_effResize.heightTo > 0)
				UIComponent(_effResize.target).height = NaN;
			StopListeningForResize();
		}
		
		private function ScrollToShow(evt:ResizeEvent=null): void {
			if (scrollContainer == null) return; // No scrollbar found
			// Resize to show this.
			
			// Rules:
			// If part is off the top, scroll down to show it.
			var ptTop:Point = scrollContainer.globalToLocal(contentToGlobal(new Point(0,0)));
			var ptBottom:Point = new Point(0, ptTop.y + height);
			
			// If everything is visible, we're done
			if (ptTop.y >= 0 && ptBottom.y <= scrollContainer.height) return;
			
			// If we are taller than the space we have, scroll to put our object at the top
			if (height > scrollContainer.height) {
				scrollContainer.verticalScrollPosition += ptTop.y;
			}  else if (ptTop.y < 0) {
				// Top is off. Scroll down to show it
				scrollContainer.verticalScrollPosition += ptTop.y/2;
			} else {
				// Bottom is off. Scroll up to show it
				scrollContainer.verticalScrollPosition -= scrollContainer.height - ptBottom.y;
			}
		}
		
		private function StartListeningForResize(): void {
			addEventListener(ResizeEvent.RESIZE, ScrollToShow);
			ScrollToShow();
		}
		
		private function StopListeningForResize(): void {
			removeEventListener(ResizeEvent.RESIZE, ScrollToShow);
		}
		
		public function ToggleExpanded(): void {
			expanded = !expanded;
		}
		
		[Bindable]
		public function set expanded(fExpanded:Boolean): void {
			if (_fExpanded != fExpanded) {
				_fExpanded = fExpanded;
				// Don't start dispatching grow events until the first time we expand
				
				var uicExpand:UIComponent = (numChildren > nExpandTargetPos) ? getChildAt(nExpandTargetPos) as UIComponent : null;
				
				if (uicExpand != null) {
					uicExpand.endEffectsStarted();

					if (_fExpanded) uicExpand.dispatchEvent(new Event("expanding"));
					if (_effResize == null) {
						_effResize = new Resize(uicExpand);
						_effResize.duration = 300;
						_effResize.addEventListener(EffectEvent.EFFECT_END, OnResizeComplete);
					}
					
					_effResize.heightFrom = uicExpand.height;
					_effResize.heightTo = _fExpanded ? uicExpand.measuredHeight : 0;
					_effResize.play();
					if (_fExpanded) {
						StartListeningForResize();
					}
				}
			}
		}
		
		public function get expanded(): Boolean {
			return _fExpanded;
		}
	}
}