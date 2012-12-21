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
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	
	import mx.containers.Canvas;
	
	public class FontItemRendererBase extends Canvas {
		[Bindable] public var _imgPreview:ImageEx;
		[Bindable] public var premiumColor:uint = 0x005580;
		[Bindable] public var selectedColor:uint = PicnikBase.IsGooglePlus() ? 0xf0f0f0 : 0xd6efb2;
		[Bindable] public var deselectedColor:uint = 0xffffff;
		private var _fSelected:Boolean = false;
		
		public function FontItemRendererBase() {
			super();
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
		}
		
		override protected function updateDisplayList(cxUnscaled:Number, cyUnscaled:Number): void {
			var clr:uint = defaultColor;
			if (clr == 0 && isPremium) {
				clr = premiumColor;
			}
			if (clr != 0) {
				var cot:ColorTransform = new ColorTransform();
				cot.color = clr;
				if (_imgPreview) _imgPreview.transform.colorTransform = cot;
			}
			
			// UNDONE: clashes with effect animation?
			backgroundColor = _fSelected ? selectedColor : deselectedColor;
			super.updateDisplayList(cxUnscaled, cyUnscaled);
		}
		
		public function set active(fActive:Boolean): void {
		}

		protected function OnMouseDown(evt:MouseEvent): void {
		}
		
		[Bindable]
		public function get selected(): Boolean {
			return _fSelected;
		}

		public function set selected(f:Boolean): void {
			_fSelected = f;
			invalidateDisplayList();
		}

		// UNDONE: effects can theoretically animate styles (isStyle=true) but doing so
		// leaves some effects unfinished leaving colored turdlets behind.
		[Bindable]		
		public function set backgroundColor(co:uint): void {
			setStyle("backgroundColor", co);
		}
		
		public function get backgroundColor(): uint {
			return uint(getStyle("backgroundColor"));
		}
		
		[Bindable]
		public function get isPremium(): Boolean {
			return ("premium" in data) && data.premium;
		}
		
		public function set isPremium(fPremium:Boolean): void {
			data.premium = true;
		}

		private function get defaultColor(): uint {
			if ("color" in data) return data.color;
			else return 0;
		}
	}
}
