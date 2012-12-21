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
package imagine.imageOperations {
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.SpreadMethod;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class ReflectionImageOperation extends BlendImageOperation {
		private static const knBackgroundGradientOffsetAmount:Number = 0.20;

		private var _nReflectionAmount:Number = 0.0; // 0.0 - 1.0
		private var _nReflectionScale:Number = 0.75; // 0.0 - 1.0
		private var _nBorderAmount:Number = 0.1; // 0.0 - 1.0
		private var _nReflectionAlpha:Number = 0.7; // 0.0 - 1.0
		private var _cxyReflectionBlur:int = 0;
		private var _cxyFrameThickness:int = 4;
		private var _coBackground:Number = 0x000000;
		private var _coFrame:Number = 0xffffff;
		private var _cxMax:int;
		private var _cyMax:int;
		private var _cPixelsMax:int;

		public function ReflectionImageOperation() {
			_cxMax = Util.GetMaxImageWidth(1);
			_cyMax = Util.GetMaxImageHeight(1);
			_cPixelsMax = Util.GetMaxImagePixels();
		}

		public function set reflectionAmount(nAmount:Number): void {
			_nReflectionAmount = nAmount;
		}
		
		public function get reflectionAmount(): Number {
			return _nReflectionAmount;
		}
		
		public function set reflectionScale(nScale:Number): void {
			_nReflectionScale = nScale;
		}
		
		public function get reflectionScale(): Number {
			return _nReflectionScale;
		}
		
		public function set reflectionAlpha(nAlpha:Number): void {
			_nReflectionAlpha = nAlpha;
		}
		
		public function get reflectionAlpha(): Number {
			return _nReflectionAlpha;
		}
		
		public function set reflectionBlur(nBlur:int): void {
			_cxyReflectionBlur = nBlur;
		}
		
		public function get reflectionBlur(): int {
			return _cxyReflectionBlur;
		}
		
		public function set borderAmount(nAmount:Number): void {
			_nBorderAmount = nAmount;
		}
		
		public function get borderAmount(): Number {
			return _nBorderAmount;
		}
		
		public function set backgroundColor(coBackground:Number): void {
			_coBackground = coBackground;
		}
		
		public function get backgroundColor(): Number {
			return _coBackground;
		}
		
		public function set frameColor(coFrame:Number): void {
			_coFrame = coFrame;
		}
		
		public function get frameColor(): Number {
			return _coFrame;
		}
		
		public function set frameThickness(cxy:int): void {
			_cxyFrameThickness = cxy;
		}
		
		public function get frameThickness(): int {
			return _cxyFrameThickness;
		}
		
		public function set maxImageWidth(n:Number): void {
			_cxMax = n;
		}
		
		public function get maxImageWidth(): Number {
			return _cxMax;
		}
		
		public function set maxImageHeight(n:Number): void {
			_cyMax = n;
		}
		
		public function get maxImageHeight(): Number {
			return _cyMax;
		}
		
		public function set maxPixels(n:Number): void {
			_cPixelsMax = n;
		}
		
		public function get maxPixels(): Number {
			return _cPixelsMax;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo([
			'reflectionAmount', 'reflectionScale', 'reflectionAlpha', 'reflectionBlur',
			'borderAmount', 'backgroundColor', 'frameColor', 'frameThickness',
			'maxImageWidth', 'maxImageHeight', 'maxPixels']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@reflectionAmount, "ReflectionImageOperation reflectionAmount argument missing");
			_nReflectionAmount = Number(xmlOp.@reflectionAmount);

			Debug.Assert(xmlOp.@reflectionScale, "ReflectionImageOperation reflectionScale argument missing");
			_nReflectionScale = Number(xmlOp.@reflectionScale);

			Debug.Assert(xmlOp.@reflectionAlpha, "ReflectionImageOperation reflectionAlpha argument missing");
			_nReflectionAlpha = Number(xmlOp.@reflectionAlpha);

			Debug.Assert(xmlOp.@borderAmount, "ReflectionImageOperation borderAmount argument missing");
			_nBorderAmount = Number(xmlOp.@borderAmount);

			Debug.Assert(xmlOp.@backgroundColor, "ReflectionImageOperation backgroundColor argument missing");
			_coBackground = Number(xmlOp.@backgroundColor);
				
			Debug.Assert(xmlOp.@frameColor, "ReflectionImageOperation frameColor argument missing");
			_coFrame = Number(xmlOp.@frameColor);
				
			Debug.Assert(xmlOp.@reflectionBlur, "ReflectionImageOperation reflectionBlur argument missing");
			_cxyReflectionBlur = int(Number(xmlOp.@reflectionBlur));

			Debug.Assert(xmlOp.@frameThickness, "ReflectionImageOperation frameThickness argument missing");
			_cxyFrameThickness = int(Number(xmlOp.@frameThickness));

			Debug.Assert(xmlOp.hasOwnProperty("@maxWidth"), "ReflectionImageOperation maxWidth argument missing");
			_cxMax = Number(xmlOp.@maxWidth);
			_cyMax = Number(xmlOp.@maxHeight);
			_cPixelsMax = Number(xmlOp.@maxPixels);
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Reflection reflectionAmount={_nReflectionAmount} reflectionScale={_nReflectionScale}
					borderAmount={_nBorderAmount} reflectionAlpha={_nReflectionAlpha}
					reflectionBlur={_cxyReflectionBlur} backgroundColor={_coBackground}
					frameThickness={_cxyFrameThickness} frameColor={_coFrame}
					maxWidth={_cxMax} maxHeight={_cyMax} maxPixels={_cPixelsMax}/>;
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			// Calculate an output size that accommodates the reflection and the border
			var cxBorder:Number = bmdSrc.width * _nBorderAmount;
			var cyBorder:Number = cxBorder;
			var cyReflection:Number = (bmdSrc.height * _nReflectionAmount * _nReflectionScale) + cyBorder;
			var cxOut:Number = bmdSrc.width + (2 * cxBorder) + (2 * _cxyFrameThickness);
			var cyOut:Number = bmdSrc.height + cyReflection + cyBorder + (2 * _cxyFrameThickness);
			
			// Scale the output to fit within the resolution limits
			// NOTE: Flash can't seem to draw the background gradient wider/taller than 408x pixels
			var ptLimited:Point = Util.GetLimitedImageSize(cxOut, cyOut, _cxMax, _cyMax, _cPixelsMax);
			var nScaleX:Number = ptLimited.x / cxOut;
			var nScaleY:Number = ptLimited.y / cyOut;
			cxOut = ptLimited.x;
			cyOut = ptLimited.y;
			cxBorder *= nScaleX;
			cyBorder *= nScaleY;
			cyReflection *= nScaleY;
			var cxSrc:Number = bmdSrc.width * nScaleX;
			var cySrc:Number = bmdSrc.height * nScaleY;
			var cxyFrameThickness:Number = _cxyFrameThickness * nScaleX;
			var cxSrcFrame:Number = cxSrc + (cxyFrameThickness * 2);
			var cySrcFrame:Number = cySrc + (cxyFrameThickness * 2);
			var cySrcFrameBorder:Number = cySrcFrame + cyBorder;
			var cxBorderFrame:Number = cxBorder + cxyFrameThickness;
			var cyBorderFrame:Number = cyBorder + cxyFrameThickness;
			
			// Scale and inset the DocumentObjects to match the scaled/inset image
			if (fDoObjects) {
				var dctPropertySets:Object = {};
				SetPropertiesObjectOperation.ScaleDocumentObjects(dctPropertySets, imgd, nScaleX);
				SetPropertiesObjectOperation.OffsetDocumentObjects(dctPropertySets, imgd, cxBorderFrame, cyBorderFrame);
				SetPropertiesObjectOperation.SetProperties(dctPropertySets, imgd);
				imgd.documentObjects.Validate();
			}

			var bmdOut:BitmapData = VBitmapData.Construct(cxOut, cyOut, true, _coBackground | 0xff000000);
			
			// Draw the background/surface gradient into the output bitmap
			var shp:Shape = new Shape();
			var matGradient:Matrix = new Matrix();
			matGradient.createGradientBox(cxOut, cyOut, Util.RadFromDeg(90), 0,
					cyOut * knBackgroundGradientOffsetAmount);
			shp.graphics.beginGradientFill(GradientType.LINEAR, [ _coBackground, 0xffffff ], [ 1, 1 ],
					[ 0x00, 0xff ],	matGradient, SpreadMethod.PAD);
			shp.graphics.drawRect(0, 0, cxOut, cyOut);
			shp.graphics.endFill();
			VBitmapData.RepairedDraw(bmdOut, shp);
//			bmdOut.draw(shp);
			
			// Draw the frame into the output bitmap
			var rcFrame:Rectangle = new Rectangle(cxBorder, cyBorder, cxSrcFrame, cySrcFrame);
			if (_cxyFrameThickness >= 0.5)
				bmdOut.fillRect(rcFrame, _coFrame | 0xff000000);
			
			// Draw source image into the output bitmap, scaled and inset by the border amounts
			var matImage:Matrix = new Matrix();
			matImage.scale(nScaleX, nScaleY);
			matImage.translate(cxBorderFrame, cyBorderFrame);
			bmdOut.draw(bmdSrc, matImage);
			if (cyReflection == 0)
				return bmdOut;
				
			// Draw reflection into the reflection bitmap
			var bmdReflection:BitmapData = VBitmapData.Construct(cxOut, cyReflection, true, 0x00000000);
			var mat:Matrix = new Matrix();
			mat.translate(0, -cySrcFrameBorder);
			mat.scale(1, -_nReflectionScale);
			var rcClip:Rectangle = new Rectangle(cxBorder, 0, cxSrcFrame, cySrcFrame * _nReflectionScale);
			bmdReflection.draw(bmdOut, mat, null, null, rcClip);

			/* UNDONE: DocumentObjects may not have finished loading yet (at render or document load time)			
			if (imgd.documentObjects)
				bmdReflection.draw(imgd.documentObjects, mat, null, null, rcClip);
			*/
			
			// Blur the reflection
			if (_cxyReflectionBlur > 0) {
				var flt:BlurFilter = new BlurFilter(_cxyReflectionBlur, _cxyReflectionBlur, 3);
				bmdReflection.applyFilter(bmdReflection, bmdReflection.rect, bmdReflection.rect.topLeft, flt);

				/* NEW, but not working well				
				// Blur the reflection
				var bmdBlurredReflection:BitmapData = bmdReflection.clone();
//				var bmdBlurredReflection:BitmapData = new BitmapData(bmdReflection.width, bmdReflection.height, false);
				bmdBlurredReflection.copyPixels(bmdReflection, bmdReflection.rect, new Point(0, 0));
				var flt:BlurFilter = new BlurFilter(_cxyReflectionBlur, _cxyReflectionBlur, 3);
				bmdBlurredReflection.applyFilter(bmdBlurredReflection, bmdReflection.rect, bmdReflection.rect.topLeft, flt);
				
				// Create linear gradient alpha mask to draw the blur through
				var bmdBlurMask:BitmapData = VBitmapData.Construct(cxOut, cyReflection, true, 0x00000000);
				shp = new Shape();
				matGradient = new Matrix();
				matGradient.createGradientBox(bmdBlurMask.width, bmdBlurMask.height, Util.RadFromDeg(90));
				shp.graphics.beginGradientFill(GradientType.LINEAR, [ 0x000000, 0x000000 ], [ 0.25, 1 ],
						[ 0, 127 ],	matGradient, SpreadMethod.PAD);
				shp.graphics.drawRect(0, 0, bmdBlurMask.width, bmdBlurMask.height);
				shp.graphics.endFill();
				bmdBlurMask.draw(shp);

				// Draw the masked reflection back into the reflection bitmap
				bmdReflection.copyPixels(bmdBlurredReflection, bmdReflection.rect, new Point(0, 0),
						bmdBlurMask, new Point(0, 0), false);
				bmdBlurredReflection.dispose();
				bmdBlurMask.dispose();
				*/
			}
			
			// Create linear gradient alpha mask to draw the reflection through
			var bmdReflectionMask:BitmapData = VBitmapData.Construct(cxOut, cyReflection, true, 0x00000000);
			shp = new Shape();
			matGradient = new Matrix();
			matGradient.createGradientBox(bmdReflectionMask.width, bmdReflectionMask.height, Util.RadFromDeg(90));
			shp.graphics.beginGradientFill(GradientType.LINEAR, [ 0x000000, 0x000000 ], [ _nReflectionAlpha, 0 ],
					[ 0x00, 0xff ],	matGradient, SpreadMethod.PAD);
			shp.graphics.drawRect(0, 0, bmdReflectionMask.width, bmdReflectionMask.height);
			shp.graphics.endFill();
			VBitmapData.RepairedDraw(bmdReflectionMask, shp);

			// Draw the masked reflection into the output bitmap
			bmdOut.copyPixels(bmdReflection, bmdReflection.rect, new Point(0, cySrcFrameBorder),
					bmdReflectionMask, new Point(0, 0), true);
			
			bmdReflectionMask.dispose();
			bmdReflection.dispose();
			
			return bmdOut;
		}
	}
}
