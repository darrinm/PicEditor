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
// The DrawOverlayEffectCanvas simply collects polylines as an array of Point arrays
// (_aapt) as the user clicks and drags.

package containers {
	import flash.display.Bitmap;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getQualifiedClassName;
	
	import imagine.imageOperations.paintMask.Brush;
	import imagine.imageOperations.paintMask.CircularBrush;
	import imagine.imageOperations.paintMask.PaintMaskController;
	
	import mx.core.Container;
	
	import overlays.helpers.Cursor;
	
	import util.VBitmapData;
	
	public class DrawOverlayEffectCanvasBase extends OverlayEffectCanvasBase {
		[Bindable] public var _cxyBrush:Number = 10; // Brush diameter, in image document pixels
		[Bindable] public var _nBrushHardness:Number = 0; // Brush hardness, 0 to 1
		[Bindable] public var brushAlpha:Number = 1.0; // Brush alpha, 0 to 1
		[Bindable] public var brushRotation:Number = 0.0; // Brush alpha, -360 to 360
		
		private var _fActive:Boolean = true;
		
		private static var _nErrorsToLog:Number = 3;

		private var _bm:Bitmap;
		
		[Bindable]
		public function get brushActive(): Boolean {
			return _fActive;
		}
		
		public function set brushActive(fActive:Boolean): void {
			_fActive = fActive;
		}
		
		private static function NiceTypeName(obType:Object): String {
			var strName:String = "Unknown";
			try {
				if (obType == null)
					return "null";
				strName = getQualifiedClassName(obType);
				var iBreak:Number = strName.indexOf("::");
				if (iBreak >= 0)
					strName = strName.substr(iBreak + 2);
			} catch (e:Error) {
				trace("Ignoring error in NiceTypeName:", e);
			}
			return strName;
		}
		
		protected function HandleError(strLocation:String, e:Error, mctr:PaintMaskController): void {
			var strError:String = "Error in ";
			try {
				strError += NiceTypeName(this) + "." + strLocation + ": ";
				var aobState:Array = [];
				aobState.push(mctr != null);
				if (mctr != null) {
					aobState.push(mctr._fErase);
					aobState.push(mctr._nBrushAlpha);
					aobState.push(mctr._nBrushRotation);
					if (mctr._obExtraStrokeParams != null && 'strokeOperation' in mctr._obExtraStrokeParams) {
						NiceTypeName(mctr._obExtraStrokeParams['strokeOperation']);
					} else {
						aobState.push('null');	
					}
					aobState.push(NiceTypeName(mctr.brush));
					aobState.push(mctr.mask != null);
					if (mctr.mask != null) {
						aobState.push(mctr.mask.numStrokes);
						aobState.push(NiceTypeName(mctr.mask));
					}
				}
				strError += ": " + aobState.join(", ");
			} catch (e2:Error) {
				trace("Error handling error: ", e2);
			}
			trace(strError, e);
			if (_nErrorsToLog > 0) {
				PicnikService.LogException(strError, e);
				_nErrorsToLog -= 1;
			}	
		}
		
		public override function OnOverlayPress(evt:MouseEvent): Boolean {
			super.OnOverlayPress(evt);
			if (!brushActive)
				return false;
				
			var ptd:Point = overlayMouseAsPtd;
			ptd.x = Math.round(ptd.x);
			ptd.y = Math.round(ptd.y);
			StartDrag(ptd);
			return true;
		}
		
		protected function StartDrag(ptd:Point): void {
			// Override in sub-classes
		}
		
		public override function OnOverlayMouseDrag(): Boolean {
			if (!brushActive)
				return false;
				
			var ptd:Point = overlayMouseAsPtd;
			ptd.x = Math.round(ptd.x);
			ptd.y = Math.round(ptd.y);
			
			ContinueDrag(ptd);
			
			return true;
		}
		
		protected function ContinueDrag(ptd:Point): void {
			// Override in sub-classes
		}
		
		protected function UpdateCursor(): void {
			_imgv.overlayCursor = Cursor.csrBlank;
		}

		override public function OnOverlayMouseMove(): Boolean {
			if (!brushActive) {
				_imgv.overlayCursor = Cursor.csrSystem;
				return false;
			}
			
			UpdateCursor();
			UpdateOverlay();
			
			if (_fOverlayMouseDown) {
				return OnOverlayMouseDrag();
			} else {
				return true;
			}
		}
		
		protected function CreateBrush(): Brush {
			return new CircularBrush(100, 0);
		}
		
		protected function CreateBrushPreview(co:uint, nAlpha:Number, nRotation:Number): Object {
			var brPreview:Brush = CreateBrush();
			brPreview.diameter = _cxyBrush;
			brPreview.hardness = _nBrushHardness;
			var rc:Rectangle = brPreview.GetDrawRect(new Point(0, 0), co, nRotation);
			var bmdBrush:VBitmapData = new VBitmapData(rc.width, rc.height, true, 0x00ffffff);			
			var bm:Bitmap = new Bitmap(bmdBrush);
			
			// Match the document's view scaling
			bm.scaleX = PicnikBase.app.zoomView.imageView.zoom;
			bm.scaleY = PicnikBase.app.zoomView.imageView.zoom;
			brPreview.DrawInto(bmdBrush, bmdBrush, new Point(-rc.left, -rc.top), nAlpha, co,
					NaN, NaN, nRotation);
			brPreview.dispose();
			return { bm: bm, rcBounds: rc };
		}
		
		private function DrawBrushPreview(): void {
			var cntParent:Container = PicnikBase.app as Container;
			EraseBrushPreview();
			var obBrushPreview:Object = CreateBrushPreview(0x000000, brushAlpha, brushRotation);
			_bm = obBrushPreview.bm as Bitmap;
			var rc:Rectangle = obBrushPreview.rcBounds;
			cntParent.rawChildren.addChild(_bm);
			_bm.x = cntParent.mouseX - (rc.width * _bm.scaleX) / 2;
			_bm.y = cntParent.mouseY - (rc.height * _bm.scaleX) / 2;
			_bm.alpha = 0.75;
		}
		
		private function EraseBrushPreview(): void {
			var cntParent:Container = PicnikBase.app as Container;
			if (_bm) {
				cntParent.rawChildren.removeChild(_bm);
				_bm.bitmapData.dispose();
				_bm = null;
			}
		}
		
		protected function ShowBrushPreview(): void {
			DrawBrushPreview();
		}
		
		protected function UpdateBrushPreview(): void {
			DrawBrushPreview();
		}
		
		protected function HideBrushPreview(): void {
			EraseBrushPreview();
		}

		override public function UpdateOverlay(): void {
			if (!_mcOverlay)
				return;
			
			_mcOverlay.graphics.clear();
			
			if (!brushActive)
				return;

			// These are in document coordinates
			var ptd:Point = overlayMouseAsPtd;
			ptd.x = Math.round(ptd.x);
			ptd.y = Math.round(ptd.y);
			if (isNaN(ptd.x) || isNaN(ptd.y))
				return;
			
			var rcd:Rectangle = new Rectangle(ptd.x - (_cxyBrush / 2), ptd.y - (_cxyBrush / 2), _cxyBrush, _cxyBrush);
			var rcl:Rectangle = _imgv.RclFromRcd(rcd);

			// Draw cursor's shadow
			_mcOverlay.graphics.lineStyle(1, 0x000000, 0.3, false);
			_mcOverlay.graphics.drawEllipse(rcl.x+1, rcl.y+1, rcl.width, rcl.height);
			
			// Draw cursor
			_mcOverlay.graphics.lineStyle(1, 0xffffff, 1.0, false);
			_mcOverlay.graphics.drawEllipse(rcl.x, rcl.y, rcl.width, rcl.height);
		}
	}
}
