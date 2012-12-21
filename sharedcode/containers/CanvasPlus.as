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
package containers {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	import mx.containers.Canvas;
	
	public class CanvasPlus extends Canvas {
		private var _bmdBackground:BitmapData;
		
		public function set tiledBackgroundImage(ob:Object): void{
			Debug.Assert(ob is Class, "Only embedded images are supported at this time");
			var bm:Bitmap = new ob();
			_bmdBackground = bm.bitmapData;
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(cxUnscaled:Number, cyUnscaled:Number): void {
			super.updateDisplayList(cxUnscaled, cyUnscaled);

			if (_bmdBackground) {
				with (graphics) {
					clear();
					beginBitmapFill(_bmdBackground);
					moveTo(0, 0);
					lineTo(cxUnscaled, 0);
					lineTo(cxUnscaled, cyUnscaled);
					lineTo(0, cyUnscaled);
					lineTo(0, 0);
					endFill();
				}
			}			
		}
	}
}
