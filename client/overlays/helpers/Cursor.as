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
package overlays.helpers
{
	import mx.managers.CursorManager;
	import mx.managers.DragManager;
	
	public class Cursor
	{
		private var _clsCursor:Class = null;
		private var _cxOffset:Number = 0.0;
		private var _cyOffset:Number = 0.0;
		private var _nPriority:Number = 2.0;

		public static var csrSystem:Cursor = new Cursor(null);

    	[Embed("../../assets/bitmaps/cursors/arrow.png")]
		private static var clsArrow:Class;
		public static var csrArrow:Cursor = new Cursor(clsArrow, 0, 0);
		
    	[Embed("../../assets/bitmaps/cursors/arrowSelect.png")]
		private static var clsArrowSelect:Class;
		public static var csrArrowSelect:Cursor = new Cursor(clsArrowSelect, 0, 0);
		
    	[Embed("../../assets/bitmaps/cursors/level.png")]
		private static var clsLevel:Class;
		public static var csrLevel:Cursor = new Cursor(clsLevel, -1, -16);

    	[Embed("../../assets/bitmaps/cursors/move.png")]
		private static var clsMove:Class;
		public static var csrMove:Cursor = new Cursor(clsMove, -16, -16);

    	[Embed("../../assets/bitmaps/cursors/move_small.png")]
		private static var clsMoveSmall:Class;
		public static var csrMoveSmall:Cursor = new Cursor(clsMoveSmall, -15, -16);

    	[Embed("../../assets/bitmaps/cursors/cross.png")]
		private static var clsCross:Class;
		public static var csrCross:Cursor = new Cursor(clsCross, -15, -16);

    	[Embed("../../assets/bitmaps/cursors/rotate.png")]
		private static var clsRotate:Class;
		public static var csrRotate:Cursor = new Cursor(clsRotate, -16, -16);

    	[Embed("../../assets/bitmaps/cursors/size1.png")]
		private static var clsSize1:Class;
		public static var csrSize1:Cursor = new Cursor(clsSize1, -16, -16);

    	[Embed("../../assets/bitmaps/cursors/size2.png")]
		private static var clsSize2:Class;
		public static var csrSize2:Cursor = new Cursor(clsSize2, -16, -16);

    	[Embed("../../assets/bitmaps/cursors/size3.png")]
		private static var clsSize3:Class;
		public static var csrSize3:Cursor = new Cursor(clsSize3, -16, -16);

    	[Embed("../../assets/bitmaps/cursors/size4.png")]
		private static var clsSize4:Class;
		public static var csrSize4:Cursor = new Cursor(clsSize4, -16, -16);

    	[Embed("../../assets/bitmaps/cursors/hand.png")]
		private static var clsHand:Class;
		public static var csrHand:Cursor = new Cursor(clsHand, -8, -8);
		
    	[Embed("../../assets/bitmaps/cursors/handGrab.png")]
		private static var clsHandGrab:Class;
		public static var csrHandGrab:Cursor = new Cursor(clsHandGrab, -8, -8);
		
    	[Embed("../../assets/bitmaps/cursors/redeye.png")]
		private static var clsRedEye:Class;
		public static var csrRedEye:Cursor = new Cursor(clsRedEye, -12, -12);
		
    	[Embed("../../assets/bitmaps/cursors/redeye_busy.png")]
		private static var clsRedEyeBusy:Class;
		public static var csrRedEyeBusy:Cursor = new Cursor(clsRedEyeBusy, -12, -12);
		
    	[Embed("../../assets/bitmaps/cursors/eyedropper.png")]
		private static var clsEyedropper:Class;
		public static var csrEyedropper:Cursor = new Cursor(clsEyedropper, -7, -24);
		
    	[Embed("../../assets/bitmaps/cursors/ibeam.png")]
		private static var clsIBeam:Class;
		public static var csrIBeam:Cursor = new Cursor(clsIBeam, -15, -16);

    	[Embed("../../assets/bitmaps/cursors/blank.png")]
		private static var clsBlank:Class;
		public static var csrBlank:Cursor = new Cursor(clsBlank, -7, -24);
		
		private static var _gcsrCurrent:Cursor = null;
		private static var s_fCaptured:Boolean = false;
		
		public static function get Current(): Cursor {
			return _gcsrCurrent;
		}
		
		public  function Cursor(clsCursor:Class, cxOffset:Number = 0.0, cyOffset:Number = 0.0) {
			_clsCursor = clsCursor;
			_cxOffset = cxOffset;
			_cyOffset = cyOffset;	
		}
		
		public function Apply(): void {
			if (s_fCaptured)
				return;
				
			// Don't mess with the cursor if in the middle of a drag/drop action
			if (_gcsrCurrent != this && !DragManager.isDragging) {
				Cursor.RemoveAll();
				if (_clsCursor != null) {
					var nPrevCursorID:Number = CursorManager.currentCursorID;
					Cursor.RemoveAll();
					CursorManager.setCursor(_clsCursor, _nPriority, _cxOffset, _cyOffset);
				}
				_gcsrCurrent = this;
			}
		}
		
		public static function RemoveAll(): void {
			CursorManager.removeAllCursors();
		}
		
		public function toString():String {
			return "Cursor[" + _clsCursor + ", " + _cxOffset + ", " + _cyOffset + "]";
		}
		
		public static function Capture(): void {
//			trace("Cursor.Capture");
			s_fCaptured = true;
		}
		
		public static function Release(): void {
//			trace("Cursor.Release");
			s_fCaptured = false;
		}
	}
}
