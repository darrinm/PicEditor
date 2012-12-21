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
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.core.Container;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;

	[Event(name="change", type="flash.events.Event")]

	public class MultiColorPaletteBase extends VBox
	{
		private var _clr:Number = 0;
		[Bindable] public var _cntPalettes:Container;
		[Bindable] public var _cntButtons:Container;
		
		private var _nSelectedIndex:Number = -1;
		private var _fSelected:Boolean = false;
		
		public function MultiColorPaletteBase()
		{
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnInit);
		}
		
		public function set selected(f:Boolean): void {
			_fSelected = f;
			Reset();
			for (var i:Number = 0; i < _cntPalettes.numChildren; i++)
				if ('selected' in _cntPalettes.getChildAt(i))
					_cntPalettes.getChildAt(i)['selected'] = f;
		}
		
		protected function OnButtonClick(evt:Event): void {
			selectedIndex = _cntButtons.getChildIndex(evt.target as DisplayObject);
		}
		
		[Bindable]
		public function set color(n:Number): void {
			if (_clr == n) return;
			_clr = n;
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function get color(): Number {
			return _clr;
		}
		
		private function UpdateStateForSelectedIndex(): void {
			var i:Number = 0;
			for each (var btn:Button in _cntButtons.getChildren()) {
				btn.selected = (i == _nSelectedIndex);
				i += 1;
			}
				
			for (i = 0; i < _cntPalettes.numChildren; i++)
				_cntPalettes.getChildAt(i).visible = (i == _nSelectedIndex);
		}
		
		protected function Reset(): void {
			selectedIndex = 0;
		}
		
		private function OnInit(evt:Event): void {
			Reset();
		}
		
		private function get selectedPalette(): UIComponent {
			if (_nSelectedIndex < 0) return null;
			if (_nSelectedIndex >= _cntPalettes.numChildren) return null;
			return _cntPalettes.getChildAt(_nSelectedIndex) as UIComponent;
		}
		
		public function set selectedIndex(n:Number): void {
			if (_nSelectedIndex == n) return;
			if (selectedPalette != null) { // Clean up old
				selectedPalette.visible = false;
				selectedPalette.removeEventListener(Event.CHANGE, OnColorChange);
			}
			_nSelectedIndex = n;
			if (selectedPalette != null) {
				selectedPalette.visible = true;
				selectedPalette.addEventListener(Event.CHANGE, OnColorChange);
				color = selectedPalette['color'];
			}
			UpdateStateForSelectedIndex();
		}
		
		private function OnColorChange(evt:Event): void {
			color = selectedPalette['color'];
		}
	}
}