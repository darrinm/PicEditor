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
package effects
{
	import containers.DrawOverlayEffectCanvas;
	
	import flash.geom.Point;

	public class DrawPointsOverlayEffectCanvas extends DrawOverlayEffectCanvas
	{
		[Bindable] public var _aapt:Array = null; // Used by Doodle and Blemish
		private var _aptNew:Array; // Used by Doodle and Blemish
		public function DrawPointsOverlayEffectCanvas()
		{
			super();
		}
		
		override protected function StartDrag(ptd:Point): void {
			_aptNew = new Array();
			if (_aapt == null) _aapt = new Array();
			_aapt.push(_aptNew);
			
			_aptNew.push(ptd);
			_aptNew.fUpdated = true;
		}

		override protected function ContinueDrag(ptd:Point): void {
			// Don't record redundant points
			var ptdPrev:Point = _aptNew[_aptNew.length - 1];
			if (ptd.x != ptdPrev.x || ptd.y != ptdPrev.y) {
				_aptNew.push(ptd);
				_aptNew.fUpdated = true;
			}
		}
	}
}