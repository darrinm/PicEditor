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
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.engine.OpStateMachine;
	
	import overlays.helpers.RGBColor;
	
	import util.VBitmapData;
	
	public class PerlinSpotsInstruction extends OpInstruction
	{
		private var _clr:Number;
		private var _nThreshold:Number;
		private var _nScale:Number;
		private var _nPixelation:Number;
		private var _fVFlip:Boolean;
		private var _fHFlip:Boolean;

		public function PerlinSpotsInstruction(clr:Number, nThreshold:Number, nScale:Number, nPixelation:Number, fVFlip:Boolean, fHFlip:Boolean)
		{
			super();
			_clr = clr;
			_nThreshold = nThreshold;
			_nScale = nScale;
			_nPixelation = nPixelation;
			_fVFlip = fVFlip;
			_fHFlip = fHFlip;
			key = _clr + ":" + _nThreshold + ":" + _nScale + ":" + _nPixelation + ":" + _fVFlip + ":" + _fHFlip;
		}

		public override function Execute(opsmc:OpStateMachine):void {
			var bmdrSpots:BitmapReference = BitmapReference(opsmc.bitmapStack.pop()).CopyAndDispose("spots");
			var bmdSpots:BitmapData = bmdrSpots._bmd;

			var bmdNoise:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-1])._bmd;
			var bmdOrig:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-2])._bmd;
			
			// Use noise to draw spots into bmdSpots, then push it on the stack.

			var bmdNoise2:BitmapData;
			var mat:Matrix;
			var nOperatingPixelation:Number = _nPixelation > 1 ? 1 : _nPixelation;
			
			if (_nScale == 1 && !_fVFlip && !_fHFlip) {
				bmdNoise2 = bmdNoise.clone();
			} else {
				var xSize:Number = Math.ceil(bmdNoise.width * _nScale);
				var ySize:Number = Math.ceil(bmdNoise.height * _nScale);
				if (nOperatingPixelation < 1) {
					xSize = Math.ceil(xSize * nOperatingPixelation) / nOperatingPixelation;
					ySize = Math.ceil(ySize * nOperatingPixelation) / nOperatingPixelation;
				}
				bmdNoise2 = VBitmapData.Construct(xSize, ySize, true);
				mat = new Matrix();
				mat.scale(bmdNoise2.width / bmdNoise.width, bmdNoise2.height / bmdNoise.height);
				
				mat.scale(_fHFlip ? -1 : 1, _fVFlip ? -1 : 1); // Does this draw in the right place?
				mat.translate(_fHFlip? (bmdNoise2.width) : 0, _fVFlip ? (bmdNoise2.height) : 0);
				
				bmdNoise2.draw(bmdNoise, mat, null, null, null, true);
			}
			
			// Now we have our noise in bmdNoise2. It wraps. Start drawing as appropriate.
			bmdNoise2.threshold(bmdNoise2, bmdNoise2.rect, new Point(0,0), ">", _nThreshold, 0xff00ff00, 0xff);
			
			// Now move green to alpha and set all colors to our target color
			var nRed:Number = RGBColor.RedFromUint(_clr);
			var nGreen:Number = RGBColor.GreenFromUint(_clr);
			var nBlue:Number = RGBColor.BlueFromUint(_clr);

			// Now our alpha is in the blue channel of bmdTemp
			var fltMat:ColorMatrixFilter = new ColorMatrixFilter(
				[0, 0, 0, 0, nRed,
				 0, 0, 0, 0, nGreen,
				 0, 0, 0, 0, nBlue,
				 0, 1, 0, 0, 0
				]);
			bmdNoise2.applyFilter(bmdNoise2, bmdNoise2.rect, new Point(0,0), fltMat);
			
			// Loop and draw based on our pixelation level.
			// Note that our scale factor should be 0.5 or a whole number.
			var iy:Number = 0;
			while (iy < bmdSpots.height) {
				var ix:Number = 0;
				while (ix < bmdSpots.width) {
					mat = new Matrix();
					mat.scale(nOperatingPixelation, nOperatingPixelation);
					mat.translate(ix, iy);
					bmdSpots.draw(bmdNoise2, mat, null, null, null, nOperatingPixelation < 1);
					ix += bmdNoise2.width * nOperatingPixelation;
				}
				iy += bmdNoise2.height * nOperatingPixelation;
			}
			bmdNoise2.dispose();
			opsmc.bitmapStack.push(bmdrSpots);
		}
			// Now draw the original back using a frame alpha that we create using our noise and a bitmap gradient.
	}
}