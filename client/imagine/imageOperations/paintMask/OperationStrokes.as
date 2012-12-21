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
	import flash.utils.ByteArray;
	
	import imagine.imageOperations.ISimpleOperation;
	import imagine.imageOperations.ImageOperation;
	
	import util.BitmapCache;
	import util.VBitmapData;

	[RemoteClass]
	public class OperationStrokes extends PaintPlusImageMask
	{
		private var _obCompositeInfo:Object = null;
		private static const kstrOperationCacheKey:String = "OPERATION";

		public function OperationStrokes(rcBounds:Rectangle=null)
		{
			super(rcBounds);
		}

		public function Precalculate(sop:ISimpleOperation, bmdOrig:BitmapData): void {
			// UNDONE: How does this code get called?
			var bmdComp:BitmapData = Mask(bmdOrig); // Set our base operation
			var strKey:String = GetCacheKey(sop);
			if (GetCachedOperationBmdByKey(strKey) == null) {
				// NOTE: This code does not support additive mode
				var bmdOp:BitmapData = VBitmapData.Construct(bmdOrig.width, bmdOrig.height, true, 0xffffffff, "strokes op");
				sop.ApplySimple(bmdComp, bmdOp, bmdOp.rect, new Point(0,0));
				BitmapCache.Set(originalBmd, kstrOperationCacheKey, strKey, originalBmd, bmdOp);
			}
		}
		
		private function GetCacheKey(sop:ISimpleOperation, stk:Stroke=null): String {
			var ba:ByteArray = new ByteArray();
			var astk:Array = GetStrokesExcept(stk);
			ba.writeObject(astk);
			ba.writeObject(sop);
			return ba.toString();
		}
		
		// Look for the operation in the cache
		// If not found, return null
		public function GetCachedOperationBmd(stk:OperationStroke): BitmapData {
			return GetCachedOperationBmdByKey(GetCacheKey(stk.simpleOperation, stk));
		}
		
		private function GetCachedOperationBmdByKey(strKey:String): BitmapData {
			return BitmapCache.Lookup(originalBmd, kstrOperationCacheKey, strKey, originalBmd);
		}
		
		override public function NewStroke(pt:Point, br:Brush, fErase:Boolean=false, nAlpha:Number=1, nRotation:Number=0,
				fAdditive:Boolean=false, nSpacing:Number=0.2, obExtraParams:Object=null): void {
			var stk:OperationStroke = new OperationStroke();
			
			br = br.clone();
			// if (fErase) br.inverted = !br.inverted;
			stk.brush = br;
			stk.operation = obExtraParams.strokeOperation;
			stk.alpha = nAlpha;
			stk.erase = fErase;
			stk.additive = fAdditive;
			stk.spacing = nSpacing;
			stk.rotation = nRotation;

			stk.cachedOp = GetCachedOperationBmd(stk);

			stk.push(pt);
			_NewStroke(stk);
		}
		
		override public function InitForStroke(stk:Stroke): void {
			if (strokeBmd) strokeBmd.dispose();
			strokeBmd = VBitmapData.Construct(originalBmd.width, originalBmd.height, true, 0);
			
			if (compositeBmd) compositeBmd.dispose();
			compositeBmd = Mask(originalBmd).clone();
		}

		// Called when we have a second to get ready for the next stroke.
		override public function PrepareForNextStroke(fErase:Boolean=false, nAlpha:Number=1, nRotation:Number=0,
				obExtraParams:Object=null):void {
			// _PrepareForNextStroke(fErase, nAlpha, (obExtraParams && 'blendmode' in obExtraParams) ? obExtraParams['blendmode'] : BlendMode.NORMAL, numStrokes);
		}
		
		override protected function NewBaseBitmap(): BitmapData {
			BitmapCache.AddDisposable(this);
			return _bmdOrig.clone();
		}
	}
}