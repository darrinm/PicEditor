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
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.engine.OpStateMachine;
	
	import util.VBitmapData;
	
	public class PerlinSpotsFrameInstruction extends OpInstruction
	{
		private var _nSize:Number;
		private var _nBleed:Number;
		private var _nPixelation:Number;
		private var _fRoundedCorners:Boolean; // We may eventually want this to be configurable
		
		public function PerlinSpotsFrameInstruction(nPixelation:Number, nSize:Number, nBleed:Number, fRoundedCorners:Boolean)
		{
			super();
			_nSize = nSize;
			_nBleed = nBleed;
			_nPixelation = nPixelation;
			_fRoundedCorners = fRoundedCorners;
			key = _nSize + ":" + _nBleed + ":" + _nPixelation + ":" + _fRoundedCorners;
		}
		
		private static const kstrBlendMode:String = BlendMode.ADD;
		private static const knThreshold:Number = 255;
		
		//private static const kstrBlendMode:String = BlendMode.OVERLAY;
		//private static const knThreshold:Number = 128;

		public override function Execute(opsmc:OpStateMachine):void {
			var bmdrSpots:BitmapReference = opsmc.bitmapStack.pop();
			var bmdSpots:BitmapData = bmdrSpots._bmd;
			var bmdNoise:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-1])._bmd;
			var bmdOrig:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-2])._bmd;

			var ptOperatingSize:Point;
			if (_nPixelation < 1)
				ptOperatingSize = new Point(bmdOrig.width, bmdOrig.height);
			else
				ptOperatingSize = new Point(Math.ceil(bmdOrig.width / _nPixelation), Math.ceil(bmdOrig.height / _nPixelation));

			var bmdGrad:BitmapData;
			var bmdResult:BitmapData;
			
			var iy:Number;
			var ix:Number;
			var mat:Matrix;

			if (_nPixelation >= 1) {
				// Pixelated version.
				// Take noise + linear radial gradient, combine, threshold, use the results for the alpha on bmd.
				// Then draw that (scaled) on top of our original
				bmdGrad = VBitmapData.Construct(ptOperatingSize.x, ptOperatingSize.y, true);
				DrawLinearRadialGradient(bmdGrad);

				iy = 0;
				while (iy < bmdSpots.height) {
					ix = 0;
					while (ix < bmdSpots.width) {
						mat = new Matrix();
						mat.translate(ix, iy);
						bmdGrad.draw(bmdNoise, null, null, kstrBlendMode, null, true);
						ix += bmdNoise.width;
					}
					iy += bmdNoise.height;
				}
				// Now we have combined our noise with our linear radial gradient
				// Next, we need to threshold this and use the result to punch a hole in bmdSpots
				
				bmdrSpots = bmdrSpots.CopyAndDispose("spots frame"); // Create a copy before we modify
				bmdSpots = bmdrSpots._bmd;
				bmdSpots.threshold(bmdGrad, bmdGrad.rect, new Point(0,0), "<", knThreshold,0, 0xff);
				bmdGrad.dispose();
				
				// bmd now contains our pixelated spots with alpha. Draw scaled up on a copy of the original
				mat = new Matrix();
				mat.scale(bmdOrig.width/bmdSpots.width, bmdOrig.height/bmdSpots.height);
				bmdResult = bmdOrig.clone();
				bmdResult.draw(bmdSpots, mat);
			} else {
				// Fancy schmancy noise needs to be smoothed out.
				
				// bmdAlpha is our alpha channel. Use this to draw bmd onto a copy of bmdOrig
				// bmdGrad is our gradient
				
				var bmdAlpha:BitmapData = VBitmapData.Construct(bmdOrig.width, bmdOrig.height, true, 0);
				// Take noise + linear radial gradient, combine, threshold, use the results for the alpha on bmd.
				// Then draw that (scaled) on top of our original
				
				bmdGrad = VBitmapData.Construct(bmdNoise.width, bmdNoise.height, true);
				
				iy = 0;
				while (iy < bmdSpots.height) {
					ix = 0;
					while (ix < bmdSpots.width) {
						var mat2:Matrix = new Matrix();
						mat2.translate(-ix, -iy);
						mat2.scale(1/_nPixelation, 1/_nPixelation);
						DrawLinearRadialGradient(bmdGrad, mat2, ptOperatingSize);
						bmdGrad.draw(bmdNoise, null, null, kstrBlendMode);
						
						// Threshold - punch a hole in alpha for the middle points
						bmdGrad.threshold(bmdGrad, bmdGrad.rect, new Point(0,0), "<", knThreshold,0, 0xff);
						
						// Now draw our gradient into bmdAlpha scaled
						mat = new Matrix();
						mat.scale(_nPixelation, _nPixelation);
						mat.translate(ix, iy);
						bmdAlpha.draw(bmdGrad, mat, null, null, null, true);
						
						ix += bmdGrad.width * _nPixelation;
					}
					iy += bmdGrad.height * _nPixelation;
				}
				// Now we have combined our noise with our linear radial gradient
				// Next, we need to threshold this and use the result to punch a hole in bmd
				
				// bmd now contains our pixelated spots with alpha. Draw scaled up on a copy of the original
				bmdResult = bmdOrig.clone();
				bmdResult.copyPixels(bmdSpots, bmdSpots.rect, new Point(0,0), bmdAlpha, null, true);
				bmdAlpha.dispose();
				bmdGrad.dispose();
			}
			bmdrSpots.dispose();
			PushBitmap(opsmc, bmdResult);
		}

		private function CreateGradientBox(mat:Matrix, nWidth:Number, nHeight:Number, nRotation:Number, xStart:Number, yStart:Number): void {
			mat.createGradientBox(nWidth+1, nHeight+1, nRotation, xStart-1, yStart-1);
		}

		private function DrawLinearRadialGradient(bmd:BitmapData, matShift:Matrix=null, ptSize:Point=null): void {
			var spr:Sprite = new Sprite();
			var gr:Graphics = spr.graphics;
			
			var mat:Matrix = new Matrix();
			if (ptSize == null)
				ptSize = new Point(bmd.width, bmd.height);

			var nScale:Number = 1;
			if (matShift != null) {
				var ptOrigin:Point = matShift.transformPoint(new Point(0,0));
				var pt11:Point = matShift.transformPoint(new Point(1,1));
				nScale = Math.abs(pt11.x - ptOrigin.x);
			}

			// Figure out the size of the frame in pixels			
			var nMaxFrameInsetPix:Number = Math.min(ptSize.x, ptSize.y) / 2;
			var nFrameInsetPix:Number = nMaxFrameInsetPix * _nSize / 100; // Middle of the gradient
			nFrameInsetPix = Math.max(1, nFrameInsetPix);
			
			// Cap this at 127 (255 max) because otherwise we get ugly steps
			var nMaxBleedPix:Number = Math.min(127.5/nScale, nFrameInsetPix, nMaxFrameInsetPix - nFrameInsetPix); // per side
			var nBleedPix:Number = nMaxBleedPix * _nBleed / 100; // Half the total width of the gradient.
			
			var rcOuter:Rectangle = new Rectangle(0, 0, ptSize.x, ptSize.y);
			
			var rcInset:Rectangle = rcOuter.clone();
			rcInset.inflate(-nFrameInsetPix, -nFrameInsetPix);
			
			var rcStartGradient:Rectangle = rcInset.clone();
			rcStartGradient.inflate(nBleedPix, nBleedPix);
			
			var nGradientWidth:Number = nBleedPix * 2;

			var rcEndGradient:Rectangle = rcStartGradient.clone();
			rcEndGradient.inflate(-nGradientWidth, -nGradientWidth); // Middle
			
			// Background is white
			gr.beginFill(0xffffff, 1);
			gr.drawRect(0, 0, ptSize.x, ptSize.y);
			gr.endFill();
			
			// Middle is black
			gr.beginFill(0, 1);
			gr.drawRect(rcEndGradient.x-1, rcEndGradient.y-1, rcEndGradient.width+2, rcEndGradient.height+2);
			gr.endFill();
			
			// First, draw left and right gradients
			// Left
			CreateGradientBox(mat, nGradientWidth, rcStartGradient.height, 0, rcStartGradient.left, rcStartGradient.top);
			gr.beginGradientFill(GradientType.LINEAR, [0xffffff, 0], [1,1], [0,255], mat);
			gr.drawRect(rcStartGradient.x, rcStartGradient.y, nGradientWidth, rcStartGradient.height);
			gr.endFill();
			
			// Right
			CreateGradientBox(mat, nGradientWidth, rcStartGradient.height, 0, rcStartGradient.right - nGradientWidth, rcStartGradient.top);
			gr.beginGradientFill(GradientType.LINEAR, [0, 0xffffff], [1,1], [0,255], mat);
			gr.drawRect(rcStartGradient.right-nGradientWidth, rcStartGradient.y, nGradientWidth, rcStartGradient.height);
			gr.endFill();

			// top gradient
			CreateGradientBox(mat, rcStartGradient.width, nGradientWidth, 90 * Math.PI / 180, rcStartGradient.left, rcStartGradient.top);
			gr.beginGradientFill(GradientType.LINEAR, [0xffffff, 0], [1,1], [0,255], mat);
			gr.moveTo(rcStartGradient.left, rcStartGradient.top);
			gr.lineTo(rcEndGradient.left, rcEndGradient.top);
			gr.lineTo(rcEndGradient.right, rcEndGradient.top);
			gr.lineTo(rcStartGradient.right, rcStartGradient.top);
			gr.endFill();
			
			// bottom gradient
			CreateGradientBox(mat, rcStartGradient.width, nGradientWidth, 90 * Math.PI / 180, rcStartGradient.left, rcEndGradient.bottom);
			gr.beginGradientFill(GradientType.LINEAR, [0, 0xffffff], [1,1], [0,255], mat);
			gr.moveTo(rcStartGradient.left, rcStartGradient.bottom);
			gr.lineTo(rcEndGradient.left, rcEndGradient.bottom);
			gr.lineTo(rcEndGradient.right, rcEndGradient.bottom);
			gr.lineTo(rcStartGradient.right, rcStartGradient.bottom);
			gr.endFill();
			
			if (_fRoundedCorners) {
				// Draw the end-caps.
				// Radius = nGradientWidth
				var rcGradient:Rectangle;
				var rcDraw:Rectangle;

				// Top left
				rcGradient = new Rectangle(rcEndGradient.left, rcEndGradient.top, 0, 0);
				rcGradient.inflate(nGradientWidth, nGradientWidth);
				// Expand towards the center
				rcGradient.right += 1;
				rcGradient.bottom += 1;
				rcDraw = new Rectangle(rcStartGradient.left, rcStartGradient.top, nGradientWidth, nGradientWidth);
				DrawGradientCap(gr, rcGradient, rcDraw);

				// Top right
				rcGradient = new Rectangle(rcEndGradient.right, rcEndGradient.top, 0, 0);
				rcGradient.inflate(nGradientWidth, nGradientWidth);
				// Expand towards the center
				rcGradient.left -= 1;
				rcGradient.bottom += 1;
				rcDraw = new Rectangle(rcEndGradient.right, rcStartGradient.top, nGradientWidth, nGradientWidth);
				DrawGradientCap(gr, rcGradient, rcDraw);

				// bottom left
				rcGradient = new Rectangle(rcEndGradient.left, rcEndGradient.bottom, 0, 0);
				rcGradient.inflate(nGradientWidth, nGradientWidth);
				// Expand towards the center
				rcGradient.right += 1;
				rcGradient.top -= 1;
				rcDraw = new Rectangle(rcStartGradient.left, rcEndGradient.bottom, nGradientWidth, nGradientWidth);
				DrawGradientCap(gr, rcGradient, rcDraw);

				// bottom right
				rcGradient = new Rectangle(rcEndGradient.right, rcEndGradient.bottom, 0, 0);
				rcGradient.inflate(nGradientWidth, nGradientWidth);
				// Expand towards the center
				rcGradient.left -= 1;
				rcGradient.top -= 1;
				rcDraw = new Rectangle(rcEndGradient.right, rcEndGradient.bottom, nGradientWidth, nGradientWidth);
				DrawGradientCap(gr, rcGradient, rcDraw);
			}

			bmd.draw(spr, matShift, null, null, null, true);
		}
		
		private function DrawGradientCap(gr:Graphics, rcGradient:Rectangle, rcDraw:Rectangle): void {
			var mat:Matrix = new Matrix();
			CreateGradientBox(mat, rcGradient.width, rcGradient.height, 0, rcGradient.x, rcGradient.y);
			gr.beginGradientFill(GradientType.RADIAL, [0, 0xffffff], [1,1], [0,255], mat);
			gr.drawRect(rcDraw.x, rcDraw.y, rcDraw.width, rcDraw.height);
			gr.endFill();
		}
	}
}