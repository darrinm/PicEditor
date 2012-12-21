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
// HSliderPlus is exactly the same as Flex's mx.controls.HSlider except that it
// forces the thumb to use SliderThumb subclass that hardwires the dimensions
// needed by the PicnikTheme. It also makes sure the thumbs are above the tick
// marks.

package controls {
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	
	import mx.core.Application;
	import mx.core.IFlexDisplayObject;
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	import mx.events.SliderEvent;
	import mx.events.SliderEventClickTarget;

	use namespace mx_internal;

	public class HSliderPlus extends ResizingHSlider {
		public function HSliderPlus() {
			super();
			// HACK: Use our right-sizing SliderThumb subclass
			sliderThumbClass = controls.SliderThumbPlus;
			// Resizing code gets the wrong height
			// Because these are all the same (for now?) just hard code this
			// as a quick and easy temporary fix.
			height = 22;
			
			addEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
		}
		
		private var _strGlobalShortcutKeys:String = null;
		private var _fListeningToKeys:Boolean = false;
		private var _fGlobalShortcutsEnabled:Boolean = true;
		
		[Bindable] public var trackInfo:Object;

		[Bindable(event="changeMin")]
		override public function get minimum(): Number {
			return super.minimum;
		}
		
		private function OnAddedToStage(evt:Event): void {
			UpdateShortcutListeners();
		}
		
		private function get hasGlobalShortcuts(): Boolean {
			return (_strGlobalShortcutKeys != null && _strGlobalShortcutKeys.length == 2 && _fGlobalShortcutsEnabled);
		}
		
		private function UpdateShortcutListeners(): void {
			if (!hasGlobalShortcuts && _fListeningToKeys) {
				Application.application.stage.removeEventListener(KeyboardEvent.KEY_DOWN, OnStageKeyDown);
				_fListeningToKeys = false;
			} else if (hasGlobalShortcuts && !_fListeningToKeys && Application.application.stage != null) {
				Application.application.stage.addEventListener(KeyboardEvent.KEY_DOWN, OnStageKeyDown);
				_fListeningToKeys = true;
			}		
		}
		
		public function set globalShortcutKeys(str:String): void {
			_strGlobalShortcutKeys = str;
			UpdateShortcutListeners();
		}
		
		private function OnStageKeyDown(evt:KeyboardEvent): void {
			if (hasGlobalShortcuts) {
				var i:Number = _strGlobalShortcutKeys.indexOf(String.fromCharCode(evt.charCode));
				if (i >= 0) {
					var nMove:Number = (i*2)-1; // -1 or 1
					var nOldValue:Number = value;
					var nNewValue:Number = nOldValue + (maximum - minimum) * nMove / 40;
					nNewValue = Math.max(minimum, Math.min(maximum, nNewValue));
					
					if (nNewValue != nOldValue) {
						value = nNewValue;

			            var event:SliderEvent = new SliderEvent(SliderEvent.CHANGE);
			            event.value = nNewValue;
			            event.thumbIndex = 0;
			            event.clickTarget = SliderEventClickTarget.THUMB;
			            //set the triggerEvent correctly
		                event.triggerEvent = new KeyboardEvent(KeyboardEvent.KEY_DOWN);
		                dispatchEvent(event);
			  		}
				}
			}
		}
		
		public function set globalShortcutsEnabled(f:Boolean): void {
			_fGlobalShortcutsEnabled = f;
			UpdateShortcutListeners();
		}
		
		override public function set minimum(nMin:Number): void {
			super.minimum = nMin;
			dispatchEvent(new Event("changeMin"));
		}
		
		[Bindable(event="changeMax")]
		override public function get maximum(): Number {
			return super.maximum;
		}
		
		override public function set maximum(nMax:Number): void {
			super.maximum = nMax;
			dispatchEvent(new Event("changeMax"));
		}
		
		override protected function commitProperties(): void {
			super.commitProperties();
			
			var uic:UIComponent = innerSlider;
			if (uic.numChildren >= 2) {
				var dobTop:DisplayObject = uic.getChildAt(uic.numChildren - 1);
				var dobTopMinusOne:DisplayObject = uic.getChildAt(uic.numChildren - 2);
				
				// HACK: if the second-down UIComponent's children are tab enabled
				// it must be the thumb container
				if (dobTopMinusOne is UIComponent && UIComponent(dobTopMinusOne).tabChildren) {
					// We want the thumbs on top, OVER the tick marks
					uic.swapChildren(dobTop, dobTopMinusOne);
				}
			}
		}

		// HACK: Slider's implementation incorrectly calculates the hit test area
		// of the slider. In addition to fumbling the attempt to include the tick
		// marks in the hit area it also adds rather than unions the heights of
		// track and thumb. The end result is a hit area much taller than desired
		// when the track height is > 1.
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number): void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var uic:UIComponent = innerSlider;
			if (uic.numChildren >= 2) {
				var dobTrack:IFlexDisplayObject = IFlexDisplayObject(uic.getChildAt(0));
				var uicHitArea:UIComponent = UIComponent(uic.getChildAt(1));
				var uicThumbs:UIComponent = UIComponent(uic.getChildAt(uic.numChildren - 1));
				
				if (uicThumbs.numChildren > 0) {
					var g:Graphics = uicHitArea.graphics;
					g.clear();
					g.beginFill(0, 0.0);
					var fullThumbHeight:Number = UIComponent(uicThumbs.getChildAt(0)).getExplicitOrMeasuredHeight();
					var halfThumbHeight:Number = (!fullThumbHeight) ? 0 : (fullThumbHeight / 2);
					var yMin:Number = Math.min(dobTrack.y, dobTrack.y +
							(dobTrack.height - fullThumbHeight) / 2 + getStyle("thumbOffset"));
					var cyMax:Number = Math.max(dobTrack.height, fullThumbHeight);
					g.drawRect(dobTrack.x, yMin, dobTrack.width, cyMax);
					g.endFill();
				}
			}
		}
	}
}
