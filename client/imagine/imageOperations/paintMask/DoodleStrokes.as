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
	import flash.display.BlendMode;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import util.VBitmapData;

	[RemoteClass]
	public class DoodleStrokes extends PaintPlusImageMask {
		private var _nCompositePos:Number = NaN;
		
		public function DoodleStrokes(rcBounds:Rectangle=null) {
			super(rcBounds);
		}
		
		override public function NewStroke(pt:Point, br:Brush, fErase:Boolean=false, nAlpha:Number=1, nRotation:Number=0,
				fAdditive:Boolean=false, nSpacing:Number=0.2, obExtraParams:Object=null): void {
			var stk:DoodleStroke = new DoodleStroke();
			br = br.clone();
			// if (fErase) br.inverted = !br.inverted;
			stk.brush = br;
			if (obExtraParams) {
				if ('color' in obExtraParams)
					stk.color = obExtraParams.color;
				if ('blendmode' in obExtraParams)
					stk.blendMode = obExtraParams.blendmode;
				if ('autoRotate' in obExtraParams)
					stk.autoRotate = obExtraParams.autoRotate;
				if ('autoRotateStartAngle' in obExtraParams)
					stk.autoRotateStartAngle = obExtraParams.autoRotateStartAngle;
				/*
				if ('smear' in obExtraParams)
					stk.smear = obExtraParams.smear;
				if ('mix' in obExtraParams)
					stk.mix = obExtraParams.mix;
				*/
			}
			stk.alpha = nAlpha;
			stk.erase = fErase;
			stk.additive = fAdditive;
			stk.spacing = nSpacing;
			stk.rotation = nRotation;
			stk.push(pt);
			_NewStroke(stk);
		}
		
		// Called when we have a second to get ready for the next stroke.
		override public function PrepareForNextStroke(fErase:Boolean=false, nAlpha:Number=1, nRotation:Number=0,
				obExtraParams:Object=null):void {
			// _PrepareForNextStroke(fErase, nAlpha, (obExtraParams && 'blendmode' in obExtraParams) ? obExtraParams['blendmode'] : BlendMode.NORMAL, numStrokes);
		}
		
		private var _bmdPreparedForSrc:BitmapData = null;
		
		private function _PrepareForNextStroke(fErase:Boolean, nAlpha:Number, strBlendMode:String, nStrokePos:Number):void {
			if (strokeBmd == null || compositeBmd == null || _bmdPreparedForSrc != originalBmd) {
				_nCompositePos = NaN;
			} else {
				// Doulble check that our bitmaps weren't accidentally disposed
				try {
					strokeBmd.width;
					compositeBmd.width;
				} catch (e:Error) {
					trace("DoodleStrokes: composite/stroke bitmap disposed. recovering gracefeully");
					_nCompositePos = NaN;
				}
			}
			// Create/update two intermediate bitmaps,
			if (nAlpha < 1 || strBlendMode != BlendMode.NORMAL) {
				// We need to get ready for the stroke
				if (_nCompositePos == nStrokePos) {
					// Already ready
				} else {
					_nCompositePos = nStrokePos;
					_bmdPreparedForSrc = originalBmd;
					if (strokeBmd) strokeBmd.dispose();
					strokeBmd = VBitmapData.Construct(originalBmd.width, originalBmd.height, true, 0, "strokes");
					
					if (compositeBmd) compositeBmd.dispose();
					compositeBmd = Mask(originalBmd).clone();
				}
			} 
		}

		override public function InitForStroke(stk:Stroke): void {
			var nStrokePos:Number = numStrokes - (IsLatestStroke(stk) ? 1 : 0);
			_PrepareForNextStroke(stk.erase, stk.alpha, (stk as DoodleStroke).blendMode, nStrokePos);
		}
	}
}