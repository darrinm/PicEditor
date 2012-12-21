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
	import mx.containers.Canvas;
	import flash.display.DisplayObject;
	import mx.core.UIComponent;
	import flash.events.Event;
	import mx.core.ScrollPolicy;
	import controls.PrintPreviewBase;

	/**
	 * This canvas contains a single child which is sized to fit proportionally
	 **/
	public class ProportionalScaleCanvas extends Canvas
	{
		[Bindable] public var paddingTop:Number = 0;
		[Bindable] public var paddingBottom:Number = 0;
		[Bindable] public var paddingRight:Number = 0;
		[Bindable] public var paddingLeft:Number = 0;
		[Bindable] public var rest:UIComponent = null;
		[Bindable] public var ChildWidth:Number = 0;

		private var _cyUsedHeight:Number = 0;

		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			Relayout(unscaledWidth, unscaledHeight);
//			ForceRelayout();
		}
				
		protected function LayoutChild(uic:UIComponent, unscaledWidth:Number, unscaledHeight:Number, cyRestMinHeight:Number): void {
			unscaledWidth -= paddingRight + paddingLeft;
			// Undone: leave space for "rest" height
			unscaledHeight -= paddingTop + paddingBottom + cyRestMinHeight;
			var nWidth:Number;
			var nHeight:Number;
			
			if (uic is PrintPreviewBase) {
				var prpv:PrintPreviewBase = uic as PrintPreviewBase;
				nWidth = prpv.actualWidth;
				nHeight = prpv.actualHeight;
			} else {
				// UNDONE: These aren't always accurate
				nWidth = uic.measuredWidth;
				nHeight = uic.measuredHeight;
			}
			
			var nScale:Number = Math.min(unscaledWidth / nWidth, unscaledHeight / nHeight);
			ChildWidth = nWidth * nScale;
			
			uic.x = paddingLeft;
			uic.y = paddingTop;
			nScale = Math.min(40, Math.max(nScale, 50/2800));
			uic.scaleX = nScale;
			uic.scaleY = nScale;
			_cyUsedHeight = uic.y + nHeight * nScale + paddingBottom;
		}
		
		public function ForceRelayout(): void {
			Relayout(this.width / scaleX, this.height / scaleY);
		}
		
		protected function Relayout(unscaledWidth:Number, unscaledHeight:Number): void {
			_cyUsedHeight = 0;
			var cyRestMinHeight:Number = 0;
			var uicRest:UIComponent = null;
			if ("rest" in this) uicRest = this["rest"] as UIComponent;
			if (uicRest) {
				uicRest.x = 0;
				uicRest.width = width;
				uicRest.validateSize(true);
				cyRestMinHeight = uicRest.measuredHeight;
			}
			
			for each (var dob:DisplayObject in getChildren()) {
				if (dob is UIComponent && dob != uicRest)
					LayoutChild(dob as UIComponent, unscaledWidth, unscaledHeight, cyRestMinHeight);
			}
			if (uicRest) {
				uicRest.x = 0;
				uicRest.width = width;
				uicRest.y = _cyUsedHeight;
				uicRest.height = this.height - _cyUsedHeight;
			}
		}
		
		public function ProportionalScaleCanvas() {
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
		}
	}
}