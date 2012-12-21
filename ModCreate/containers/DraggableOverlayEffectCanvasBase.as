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
	public class DraggableOverlayEffectCanvasBase extends OverlayEffectCanvasBase {

		protected var _xFocusMin:Number = 0;
		protected var _xFocusMax:Number = 0;
		protected var _yFocusMin:Number = 0;
		protected var _yFocusMax:Number = 0;
		
		[Inspectable]
		[Bindable]
		public function get xFocusMin(): Number {
			return _xFocusMin;
		}
		
		public function set xFocusMin(n:Number): void {
			_xFocusMin = Math.round(n);
		}
		
		[Inspectable]
		[Bindable]
		public function get xFocusMax(): Number {
			return _xFocusMax;
		}
		
		public function set xFocusMax(n:Number): void {
			_xFocusMax = Math.round(n);
		}		
		
		[Inspectable]
		[Bindable]
		public function get yFocusMin(): Number {
			return _yFocusMin;
		}
		
		public function set yFocusMin(n:Number): void {
			_yFocusMin = Math.round(n);
		}
		
		[Inspectable]
		[Bindable]
		public function get yFocusMax(): Number {
			return _yFocusMax;
		}
		
		public function set yFocusMax(n:Number): void {
			_yFocusMax = Math.round(n);
		}
		
		public override function hitDragArea(): Boolean {
			if (!_mcOverlay) return false;
			return true;
		}
		
		public override function UpdateOverlay(): void {
			return;
		}
		
		protected override function SetFocus(x:Number, y:Number ): void {
			//trace("set focus " + x + "," + y + " -- " + _xFocusMin + "," + _yFocusMin + " " + _xFocusMax + "," + _yFocusMax);
			_xFocus = Math.max(_xFocusMin, Math.min(x,_xFocusMax));				
			_yFocus = Math.max(_yFocusMin, Math.min(y,_yFocusMax));				
		}
	}
}
