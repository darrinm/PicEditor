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
package containers.sectionList {
	import mx.containers.HBox;
	import mx.controls.Image;
	import mx.effects.Rotate;
	import mx.utils.ObjectProxy;

	public class SectionHeaderBase extends HBox {
		private var _opxData:ObjectProxy = null;
		
		[Bindable] public var renderer:BoxSectionRenderer = null;
		[Bindable] public var _fExpanded:Boolean = false;
		[Bindable] public var _efRotateDown:Rotate;
		[Bindable] public var _efRotateUp:Rotate;
		[Bindable] public var _imgDropDownArrow:Image;
		
		[Bindable]
		public function set expanded(fExpanded:Boolean): void {
			if (_fExpanded != fExpanded) {
				_fExpanded = fExpanded;

				if (_imgDropDownArrow && _imgDropDownArrow.width) {
					var efRotate:Rotate = new Rotate(_imgDropDownArrow);
					efRotate.originX = _imgDropDownArrow.width / 3;
					efRotate.originY = _imgDropDownArrow.height / 2;
					efRotate.duration = 300;
					if (_fExpanded) {
						efRotate.angleFrom = 0;
						efRotate.angleTo = 90;
					} else {
						efRotate.angleFrom = 90;
						efRotate.angleTo = 0;
					
					}
					_imgDropDownArrow.endEffectsStarted();
					efRotate.play();
				}
			}
		}
		
		protected override function createChildren():void {
			super.createChildren();
			if (expanded) {
				expanded = false;
				expanded = true;
			}
		}
		
		protected function set parentExpanded(f:Boolean): void {
			if (parent && "expanded" in parent) parent["expanded"] = f;
		}

		protected function get parentExpanded(): Boolean {
			if (parent && "expanded" in parent) return parent["expanded"];
			return false;
		}
		
		public function get expanded(): Boolean {
			return _fExpanded;
		}
				
		// 'data' isn't bindable and we want to use its text and premium
		// properties in SectionHeader.mxml so we create a bindable proxy
		// object for it that can be used instead.
		[Bindable]
		public function get dataProxy(): ObjectProxy {
			return _opxData;
		}
		
		public function set dataProxy(opx:ObjectProxy): void {
			_opxData = opx;
		}
		
		override public function set data(ob:Object): void {
			super.data = data;
			if (ob != null) {
				if ("rendererState" in ob)
					this.currentState = ob.rendererState;
				dataProxy = new ObjectProxy(ob);
			}
		}
	}
}
