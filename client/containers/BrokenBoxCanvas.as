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
	import flash.events.Event;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	public class BrokenBoxCanvas extends Canvas
	{
		private var _fBoxValid:Boolean = false;

		[Bidnable] public var lineColor:Number = 0;
		[Bidnable] public var lineAlpha:Number = 1;
		[Bidnable] public var lineThickness:Number = 1;
		[Bindable] public var breakPadding:Number = 5;
		[Bindable] public var leftBoxPadding:Number = 3;
		[Bindable] public var rightBoxPadding:Number = 3;
		[Bindable] public var bottomBoxPadding:Number = 3;
		
		private static const kastrRenderFields:Array = ['lineColor', 'breakPadding', 'lineThickness', 'lineAlpha', 'leftBoxPadding', 'rightBoxPadding', 'bottomBoxPadding'];
		
		private var _acw:Array = [];
		
		public function BrokenBoxCanvas()
		{
			super();
	
			for each (var strParam:String in kastrRenderFields)
				_acw.push(ChangeWatcher.watch(this, strParam, InvalidateBox));
		}
		
		private function InvalidateBox(evt:Event=null): void {
			_fBoxValid = false;
			invalidateDisplayList();
		}
		
		public override function invalidateSize():void {
			super.invalidateSize();
			InvalidateBox();
		}
		
		private function RedrawBox(nWidth:Number, nHeight:Number): void {
			var yOff:Number = 0;
			var xHeadStart:Number = 0;
			var xHeadStop:Number = 0;
			var xLeft:Number = leftBoxPadding;
			var xRight:Number = nWidth - rightBoxPadding;
			var yBottom:Number = nHeight - bottomBoxPadding;
			
			if (numChildren > 0) {
				var _uicHead:UIComponent = getChildAt(0) as UIComponent;
				xHeadStart = _uicHead.x - breakPadding;
				xHeadStop = _uicHead.x + _uicHead.width + breakPadding;
				xHeadStart = Math.max(xLeft, xHeadStart);
				xHeadStop = Math.min(xRight, xHeadStop);
				yOff = Math.round(_uicHead.height / 2) + _uicHead.y;
			}
			
			graphics.clear();
			graphics.lineStyle(lineThickness, lineColor, lineAlpha, true);
			
			// Draw the top line (with breaks)
			graphics.moveTo(xLeft, yOff); // top left
			graphics.lineTo(xHeadStart, yOff);
			graphics.moveTo(xHeadStop, yOff);
			graphics.lineTo(xRight, yOff); // top right
			
			graphics.lineTo(xRight, yBottom); // Bottom right
			graphics.lineTo(xLeft, yBottom); // Bottom left
			graphics.lineTo(xLeft, yOff); // Top left
		}
		
		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (!_fBoxValid) {
				RedrawBox(unscaledWidth, unscaledHeight);
				_fBoxValid = true;
			}
		}
	}
}