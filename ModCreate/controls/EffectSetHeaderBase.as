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
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	import mx.effects.Rotate;
	import mx.events.FlexEvent;

	public class EffectSetHeaderBase extends Canvas
	{
		private var _fExpanded:Boolean = false;

		public var expandingVBox:ExpandingVBox = null;
		
		private var _uicRotateTarget:UIComponent = null;
		public var rotateDuration:Number = 300;
		public var rotateAngleCollapsed:Number = 0;
		public var rotateAngleExpanded:Number = 360 * 2 + 90;
		public var rotateOriginXPercent:Number = 1/3;
		public var rotateOriginYPercent:Number = 1/2;
		
		private var _efRotate:Rotate = null;
		
		public function EffectSetHeaderBase()
		{
			super();
			width = 210;

			// DropShadowFilter blurX="2" blurY="2" distance="1" color="#000000" alpha=".6"
			// quality="3" angle="90" id="_fiHeadShad"/>
			filters = [new DropShadowFilter(1, 90, 0, 0.6, 2, 2, 1, 3)];
			
			_efRotate = new Rotate();
			
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}
		
		private function OnCreationComplete(evt:Event): void {
			UpdateExpandedState();
		}
		
		public function set rotateTarget(uic:UIComponent): void {
			if (_uicRotateTarget == uic)
				return;
			_uicRotateTarget = uic;
			UpdateExpandedState();
		}
		
		public function get rotateTarget(): UIComponent {
			return _uicRotateTarget;
		}
		
		public function ToggleExpanded(): void {
			if (expandingVBox != null) {
				expandingVBox.expanded = !expandingVBox.expanded;
			}
		}
		
		private function UpdateExpandedState(): void {
			if (rotateTarget == null || rotateTarget.width == 0 || _efRotate == null)
				return;
				
			var nFromAngle:Number = rotateTarget.rotation;
			if (_efRotate.isPlaying)
				_efRotate.stop();
			_efRotate.angleFrom = nFromAngle;
			_efRotate.angleTo = _fExpanded ? rotateAngleExpanded : rotateAngleCollapsed;
			_efRotate.duration = rotateDuration;
			_efRotate.originX = rotateOriginXPercent * rotateTarget.width;
			_efRotate.originY = rotateOriginYPercent * rotateTarget.height;
			_efRotate.target = rotateTarget;
			_efRotate.play();
		}
		
		[Bindable]
		public function set expanded(fExpanded:Boolean): void {
			if (_fExpanded != fExpanded) {
				_fExpanded = fExpanded;
				UpdateExpandedState();
			}
		}
		
		public function get expanded(): Boolean {
			return _fExpanded;
		}
	}
}