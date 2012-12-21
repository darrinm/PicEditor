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
package effects.basic {
	import containers.NestedControlCanvasBase;
	
	import flash.events.Event;
	import flash.geom.Point;
	
	import mx.binding.utils.BindingUtils;
	import mx.controls.CheckBox;
	import mx.controls.TextInput;
	
	public class ResizeEffectBase extends CoreEditingEffect {
		// MXML-defined variables
		[Bindable] public var _tiResizeWidth:TextInput;
		[Bindable] public var _tiResizeHeight:TextInput;
		[Bindable] public var _chkPercentToggle:CheckBox;
		[Bindable] public var _chkKeepProportions:CheckBox;
		[Bindable] public var displayPercentage:Boolean = false;
		[Bindable] public var keepProportions:Boolean = true;
		[Bindable] public var scaledWidth:int = 1;
		[Bindable] public var scaledHeight:int = 1;
		[Bindable] public var displayWidth:String = "1";
		[Bindable] public var displayHeight:String = "1";
		
		private const WIDTH:int = 1;
		private const HEIGHT:int = 2;

		private var originalDimensions:Point = new Point(1,1);
		private var _fSmooth:Boolean = true;
		private var lastDimensionChanged:int = WIDTH;
	
		public function ResizeEffectBase() {
			super();
		}
		
		protected override function OnAllStagesCreated():void {
			super.OnAllStagesCreated();
			twoWayBind(_tiResizeWidth, "text", this, "displayWidth");
			twoWayBind(_tiResizeHeight, "text", this, "displayHeight");
		}
		
		private function twoWayBind(obj1:Object, prop1:String, obj2:Object, prop2:String) : void {
			BindingUtils.bindProperty(obj1, prop1, obj2, prop2);
			BindingUtils.bindProperty(obj2, prop2, obj1, prop1);
		}

		public override function Select(efcnvCleanup:NestedControlCanvasBase):Boolean {
			if (super.Select(efcnvCleanup)) {
				originalDimensions = new Point(_imgd.background.width, _imgd.background.height);
				scaledWidth = _imgd.background.width;
				scaledHeight = _imgd.background.height;
				lastDimensionChanged = WIDTH;
				UpdateDisplayDimensionsFromScaledDimensions();
				UpdateImageDimControls();
				_tiResizeWidth.setFocus();
				return true;
			}
			return false;
		}
			
		public override function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null):void {
			super.Deselect(fForceRollOutEffect, efcvsNew);
		}

		private function UpdateDisplayDimensionsFromScaledDimensions() : void {
			if (displayPercentage) {
				displayWidth = Math.max(1, Math.round((scaledWidth / originalDimensions.x) * 100)).toString();
				displayHeight = Math.max(1, Math.round((scaledHeight / originalDimensions.y) * 100)).toString();
			} else {
				displayWidth = scaledWidth.toString();
				displayHeight = scaledHeight.toString();
			}
		}
		
		private function UpdateScaledDimensionsFromDisplayDimensions() : void {
			var updatedDisplayDimensions:Point = new Point(Number(displayWidth), Number(displayHeight));
			if (displayPercentage) {
				updatedDisplayDimensions.x = Math.round(updatedDisplayDimensions.x / 100.0 * originalDimensions.x);
				updatedDisplayDimensions.y = Math.round(updatedDisplayDimensions.y / 100.0 * originalDimensions.y);
			}
			if (keepProportions) {
				var scale:Number = (lastDimensionChanged == WIDTH) ? (updatedDisplayDimensions.x / originalDimensions.x) :
					(updatedDisplayDimensions.y / originalDimensions.y);
				scaledWidth = Math.max(1, Math.round(scale * originalDimensions.x));
				scaledHeight = Math.max(1, Math.round(scale * originalDimensions.y));
			} else {
				scaledWidth = Math.max(1, updatedDisplayDimensions.x);
				scaledHeight = Math.max(1, updatedDisplayDimensions.y);
			}
		}
		
		protected function OnKeepProportionsClick(evt:Event): void {
			this.keepProportions = this._chkKeepProportions.selected;
			UpdateScaledDimensionsFromDisplayDimensions();
			UpdateDisplayDimensionsFromScaledDimensions();
			if (keepProportions) {
				// toggling this on will typically cause values to change, so re-render
				UpdateImageDimControls();
			}
		}
	
		protected function OnPercentToggleClick(evt:Event): void {
			displayPercentage = this._chkPercentToggle.selected;
			UpdateDisplayDimensionsFromScaledDimensions();
		}
		
		protected function OnResizeTextInputChange(evt:Event): void {
			lastDimensionChanged = (evt.target == _tiResizeWidth) ? WIDTH : HEIGHT;
			UpdateScaledDimensionsFromDisplayDimensions();
			UpdateDisplayDimensionsFromScaledDimensions();
			UpdateImageDimControls();
		}
		
		private function UpdateImageDimControls(): void {
			// We always display some kind of number but that is weird when a user
			// backspaces to clear out the field and ends up with a one w/ the
			// cursor before it so any typing produces NN1. So in this case we
			// select the 1 so typing replaces it. Looks a bit strange but feels better.
			if (_tiResizeWidth.text == "1")
				_tiResizeWidth.selectionEndIndex = 1;
			if (_tiResizeHeight.text == "1")
				_tiResizeHeight.selectionEndIndex = 1;

			var fDimensionsValid:Boolean = true;
			_tiResizeWidth.errorString = null;
			_tiResizeHeight.errorString = null;

			if (fDimensionsValid) {
				var ptLimited:Point = Util.GetLimitedImageSize(scaledWidth, scaledHeight);
				if (ptLimited.x != scaledWidth || ptLimited.y != scaledHeight) {
					fDimensionsValid = false;
					_tiResizeWidth.errorString = Resource.getString("ResizeOverlay", "exceedsMaxWidthError");
					_tiResizeHeight.errorString = Resource.getString("ResizeOverlay", "exceedsMaxHeightError");
				}
			}
			
			// HACK: Flex's focusRect updating is buggy so we force it to do the right thing
			Util.UpdateFocusRect(_tiResizeWidth);
			Util.UpdateFocusRect(_tiResizeHeight);
			
			if (fDimensionsValid) {
				OnOpChange();
			}
		}
	}
}
