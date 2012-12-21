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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	
	import mx.containers.Box;
	import mx.core.UIComponent;
	
	import picnik.util.LocaleInfo;
	
	import util.VBitmapData;
	
	/** BitmapBox
	 * This is a box that creates a bitmap cache of the contents and
	 * uses this cache for rendering rotated asian text.
	 *
	 * It will not use the bitmap cache if the language is not asian
	 * or if the box is not rotated.
	 *
	 * You can force bitmap caching by setting "forceBitmapDrawing" to true.
	 */

	public class BitmapBox extends Box
	{
		public function BitmapBox()
		{
			super();
		}
		
		private var _bmd:BitmapData = null;
		private var _bmChild:Bitmap = null;
		
		private var _fBitmapDrawing:Boolean = false;
		
		private var _fForceBitmapDrawing:Boolean = false;
		
		[Bindable]
		public function set forceBitmapDrawing(f:Boolean): void {
			_fForceBitmapDrawing = f;
			UpdateState();
		}
		
		public function get forceBitmapDrawing(): Boolean {
			return _fForceBitmapDrawing;
		}
		
		private function get needsBitmapDrawing(): Boolean {
			if (_fForceBitmapDrawing) return true;

			return LocaleInfo.UsingSystemFont() && rotation != 0 && numChildren > 0;
		}
		
		private function UpdateState(): void {
			var fNeedsBitmapDrawing:Boolean = needsBitmapDrawing;
			if (_fBitmapDrawing != fNeedsBitmapDrawing) {
				// Switch
				for each (var dobChild:DisplayObject in getChildren())
					dobChild.visible = !fNeedsBitmapDrawing;
				_fBitmapDrawing = fNeedsBitmapDrawing;
				if (_bmChild) _bmChild.visible = fNeedsBitmapDrawing;
			}
			if (fNeedsBitmapDrawing)
				Redraw();
		}
		
		public override function addChildAt(child:DisplayObject, index:int):DisplayObject {
			if (_fBitmapDrawing) child.visible = false;
			return super.addChildAt(child, index);
		}
		
		private function Redraw(): void {
			if (_bmChild == null) {
				_bmChild = new Bitmap();
				_bmChild.smoothing = true;
				rawChildren.addChild(_bmChild);
			}
			var nHeight:Number = height;
			var nWidth:Number = width;
			
			if (nWidth > 0 && nHeight > 0) {
				
				var nScale:Number = 2;
				
				if (_bmd != null && (_bmd.width != (nWidth * nScale) || _bmd.height != (nHeight * nScale))) {
					_bmd.dispose();
					_bmd = null;
				}
				if (_bmd == null) {
					_bmd = new VBitmapData(nWidth * nScale, nHeight * nScale, true, 0);
				} else {
					_bmd.fillRect(_bmd.rect, 0);
				}
				var dob:DisplayObject = getChildAt(0);
				var uic:UIComponent = dob as UIComponent;
				if (uic) {
					uic.validateNow();
				}
				var mat:Matrix = new Matrix();
				mat.scale(nScale, nScale);
				_bmd.draw(dob, mat,null,null,null,true);
				_bmChild.bitmapData = _bmd;
				_bmChild.scaleX = 1/nScale;
				_bmChild.scaleY = 1/nScale;
				_bmChild.smoothing = true;
			} else {
				_bmChild.bitmapData = null;
			}
			_bmChild.x = getStyle("paddingLeft");
			_bmChild.y = getStyle("paddingTop");
		}
		
		override public function set rotation(value:Number):void {
			super.rotation = value;
			UpdateState();
		}
		
		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			UpdateState();
		}
	}
}