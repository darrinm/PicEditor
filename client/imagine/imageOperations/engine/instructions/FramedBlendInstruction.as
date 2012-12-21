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
package imagine.imageOperations.engine.instructions
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;

	import imagine.imageOperations.ImageOperation;
	
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.engine.OpStateMachine;
	
	import imagine.ImageUndoTransaction;
	
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	import util.VBitmapData;
	
	/** FramedBlendInstruction
	 * Do a blend that does some funky positioning overlay work.
	 * Basically, it resizes the base image larger, then places the applied image on top, centered.
	 * Used for mirroed frame effect
	 */ 
	public class FramedBlendInstruction extends OpInstruction
	{
		private var _aopCachedNonImageSideEffectOps:Array = null;
		
		private var _cxMax:Number;
		private var _cyMax:Number;
		private var _cPixelsMax:Number;
		private var _thickness:Number;

		public function FramedBlendInstruction(cxMax:Number, cyMax:Number, thickness:Number, cPixelsMax:Number)
		{
			super();
			_cxMax = cxMax;
			_cyMax = cyMax;
			_thickness = thickness;
			_cPixelsMax = cPixelsMax;
			key = _cxMax + "|" + _cyMax + "|" + _thickness + "|" + _cPixelsMax;
		}

		override public function ReapplyCachedNonImageSideEffects(opsmc:OpStateMachine): void {
			if (_aopCachedNonImageSideEffectOps == null || _aopCachedNonImageSideEffectOps.length == 0)
				return; // Nothing to do
		
			for each (var op:ImageOperation in _aopCachedNonImageSideEffectOps) {
				op.Do(opsmc.imageDocument, true, opsmc.useCache);
			}
		}
		
		// Blends two images on the stack. Modifies the top image, leaves the base image unchanged.
		override public function Execute(opsmc:OpStateMachine):void {
			// Remember our original object state
			_aopCachedNonImageSideEffectOps = null;
			var ut:ImageUndoTransaction = opsmc.imageDocument.pendingUndoTransaction;
			var iopBeforeApply:int = 0;
			if (ut)
				iopBeforeApply = ut.aop.length;

			// Do some work that might modify objects
			var bmdSrc:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-2])._bmd;
			var bmdGet:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-1])._bmd;

			// BEGIN: Code copied from FramedGetVarImageOperation
			var cxNewDim:Number = bmdSrc.width + _thickness*2;
			var cyNewDim:Number = bmdSrc.height + _thickness*2;
			var mat:Matrix;
			var dctPropertySets:Object = {};
			var nShrinkFactor:Number = 1;
			
			var ptT:Point = Util.GetLimitedImageSize(cxNewDim, cyNewDim, _cxMax, _cyMax, _cPixelsMax);
			var cxImageMax:int = ptT.x;
			var cyImageMax:int = ptT.y;
			if (cxNewDim > cxImageMax || cyNewDim > cyImageMax) {
				var cxyTargetMax:Number = cxImageMax - _thickness*2;
				nShrinkFactor = cxyTargetMax / bmdSrc.width;

				cxNewDim = bmdSrc.width * nShrinkFactor + _thickness*2;
				cyNewDim = bmdSrc.height * nShrinkFactor + _thickness*2;

				// Resize all the DocumentObjects too
				if (opsmc.doObjects)
					SetPropertiesObjectOperation.ScaleDocumentObjects(dctPropertySets, opsmc.imageDocument, nShrinkFactor);
			}

			// Reposition the DocumentObjects too
			if (opsmc.doObjects) {
				SetPropertiesObjectOperation.OffsetDocumentObjects(dctPropertySets, opsmc.imageDocument, _thickness, _thickness);
				SetPropertiesObjectOperation.SetProperties(dctPropertySets, opsmc.imageDocument);
			}
			// draw the framing bmp big
			var mat1:Matrix = new Matrix();
			mat1.scale(cxNewDim / bmdSrc.width, cyNewDim / bmdSrc.height);
			var bmdOut:BitmapData = VBitmapData.Construct(cxNewDim, cyNewDim, true, 0xFFFFFF, "Framed Blend");
			bmdOut.draw( bmdSrc, mat1, null, null, null, true );
								
//			var strQuality:String = Application.application.systemManager.stage.quality;
//			if (!fDraftMode) {		
//				// Crank StageQuality to max for the best possible Resize filtering
//				// Use the systemManager.stage instead of application.stage because in some fast loading
//				// cases (e.g. no base image) we can reach this point before the application.stage has
//				// been initialized.
//				
//				// NOTE: this causes callLaters and Event.RENDER to be dispatched immediately
//				Application.application.systemManager.stage.quality = StageQuality.BEST;
//			}
	
			// draw the inner bmp smaller
			var mat2:Matrix = new Matrix();
			mat2.scale(nShrinkFactor, nShrinkFactor);
			mat2.translate(_thickness, _thickness);
			
			bmdOut.draw(bmdGet,mat2,null, null, null, true);
				
//			if (!fDraftMode) {		
//				// Restore StageQuality so everything doesn't bog down
//				Application.application.systemManager.stage.quality = strQuality;
//			}
			// END: Code copied from FramedGetVarImageOperation

			ReplaceHeadBitmap(opsmc, bmdOut);
			
			// Keep track of any objects we changed
			if (ut)
				_aopCachedNonImageSideEffectOps = ut.aop.slice(iopBeforeApply);
		}
		
	}
}