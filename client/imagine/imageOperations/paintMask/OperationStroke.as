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
package imagine.imageOperations.paintMask
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.registerClassAlias;
	
	import imagine.imageOperations.ISimpleOperation;
	import imagine.imageOperations.ImageOperation;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class OperationStroke extends Stroke {
		{ // static block
			// This alias is for backward compatibility with the pre-Imagine class packaging.
			// Yes, that '>' is unexpected but that's what RemoteClass prefixes them all with
			// so that's what we need to be backward-compatible with.
			// The [RemoteClass] above also registers ">imagine.imageOperations.paintMask.OperationStroke"
			registerClassAlias(">imageOperations.paintMask.OperationStroke", OperationStroke);
		}
			
		private var _sop:ISimpleOperation;
		
		private var _bmdOp:BitmapData = null;
		private var _bmdAlpha:BitmapData = null;
		private var _bmdCachedOp:BitmapData = null;
		
		public function OperationStroke(br:Brush=null)
		{
			super(br);
		}
		
		public function set cachedOp(bmd:BitmapData): void {
			_bmdCachedOp = bmd;
		}
		
		public function set operation(sop:ISimpleOperation): void {
			_sop = sop;
		}
		
		public function get simpleOperation(): ISimpleOperation {
			return _sop;
		}

		public function set simpleOperation(sop:ISimpleOperation): void {
			_sop = sop;
		}

		// Old way to serialize files.
		// This needs to here to support loading old files
		public function set serializedOperation(str:String): void {
			_sop = ImageOperation.XMLToImageOperation(new XML(str)) as ISimpleOperation;
		}

		override public function Dispose(): void {
			if (_bmdOp) _bmdOp.dispose();
			_bmdOp = null;
			if (_bmdAlpha) _bmdAlpha.dispose();
			_bmdAlpha = null;
			super.Dispose();
			_bmdCachedOp = null;
		}
		
		private function GetOpBitmap(nWidth:Number, nHeight:Number): BitmapData {
			if (!_bmdOp || _bmdOp.width != nWidth || _bmdOp.height != nHeight) {
				if (_bmdOp) _bmdOp.dispose();
				_bmdOp = VBitmapData.Construct(nWidth, nHeight, true, 0, "stroke op");
			}
			return _bmdOp;
		}
		
		// Draw a point. Updates the children of the stroke canvas as needed.
		// Mask is definitely updated, others are optional
		// Returns the dirty rectangle (part of Mask which was changed)
		override protected function DrawPoint(scv:IStrokeCanvas, pt:Point, iptDab:int): Rectangle {
			var rcDirty:Rectangle;
			// DrawPoint algorithm:
			// composite is prior stroke state of result
			// mask is our painted mask
			// result is the result
			
			rcDirty = brush.DrawInto(scv.strokeBmd, scv.originalBmd, pt, alpha, NaN, NaN, NaN, rotation); // Stroke mask is just for this stroke.
			
			// Update our mask
			scv.maskBmd.copyPixels(scv.compositeBmd, rcDirty, rcDirty.topLeft);
			
			if (erase) {
				scv.maskBmd.copyPixels(scv.originalBmd, rcDirty, rcDirty.topLeft, scv.strokeBmd, rcDirty.topLeft, true);
			} else {
				// Next, fill our operation bitmap with the applied operation
				var rcOp:Rectangle = rcDirty;
				
				var bmdOp:BitmapData = _bmdCachedOp;
				if (bmdOp == null) {
					// We do not have a pre-calculated op
					var bmdSrc:BitmapData = additive ? scv.compositeBmd : scv.originalBmd;
					bmdOp = GetOpBitmap(rcDirty.width, rcDirty.height);
					_sop.ApplySimple(bmdSrc, bmdOp, rcDirty, new Point(0,0)); // Operation applied to the composite
					rcOp = bmdOp.rect;
				}
				// Then, use our alpha mask to draw our operation
				scv.maskBmd.copyPixels(bmdOp, rcOp, rcDirty.topLeft, scv.strokeBmd, rcDirty.topLeft, true);
			}
			return rcDirty;
		}
	}
}