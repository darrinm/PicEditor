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
	public class BeforeAfterImageOperation extends BlendImageOperation {
		private static const knBackgroundGradientOffsetAmount:Number = 0.20;
		private static const kstrSideBySide:String = "side_by_side";
		private static const kstrSplit:String = "split";

		private var _nBorderAmount:Number = 0.01; // 0.0 - 1.0
		private var _nCaptionAmount:Number = 0.0; // 0.0 - 1.0
		private var _coBackground:Number = 0xffffff;
		private var _strType:String = kstrSideBySide;
		private var _cxMax:int;
		private var _cyMax:int;
		private var _cPixelsMax:int;

		public function BeforeAfterImageOperation() {
			_cxMax = Util.GetMaxImageWidth(1);
			_cyMax = Util.GetMaxImageHeight(1);
			_cPixelsMax = Util.GetMaxImagePixels();
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
		
		public function set captionAmount(nAmount:Number): void {
			_nCaptionAmount = nAmount;
		}
		
		public function get captionAmount(): Number {
			return _nCaptionAmount;
		}
		
		public function set type(strType:String): void {
			_strType = strType;
		}
		
		public function get type(): String {
			return _strType;
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

		private static var _srzinfo:SerializationInfo = new SerializationInfo(['borderAmount', 'backgroundColor', 'captionAmount', 'type', 'maxImageWidth', 'maxImageHeight', 'maxPixels']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}

		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@borderAmount, "BeforeAfterImageOperation borderAmount argument missing");
			_nBorderAmount = Number(xmlOp.@borderAmount);

			Debug.Assert(xmlOp.@backgroundColor, "BeforeAfterImageOperation backgroundColor argument missing");
			_coBackground = Number(xmlOp.@backgroundColor);

			Debug.Assert(xmlOp.@captionAmount, "BeforeAfterImageOperation captionAmount argument missing");
			_nCaptionAmount = Number(xmlOp.@captionAmount);

			Debug.Assert(xmlOp.@type, "BeforeAfterImageOperation type argument missing");
			_strType = String(xmlOp.@type);

			Debug.Assert(xmlOp.hasOwnProperty("@maxWidth"), "BeforeAfterImageOperation maxWidth argument missing");
			_cxMax = Number(xmlOp.@maxWidth);
			_cyMax = Number(xmlOp.@maxHeight);
			_cPixelsMax = Number(xmlOp.@maxPixels);
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <BeforeAfter borderAmount={_nBorderAmount} backgroundColor={_coBackground}
					captionAmount={_nCaptionAmount} type={_strType}
					maxWidth={_cxMax} maxHeight={_cyMax} maxPixels={_cPixelsMax}/>;
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			// Calculate an output size that accommodates the before, after, and some optional spacing between them
			var ob:Object = CalcBeforeAfterParams(imgd.original.width, imgd.original.height,
					bmdSrc.width, bmdSrc.height, _nBorderAmount, _nCaptionAmount, _strType, _cxMax, _cyMax, _cPixelsMax);
			var bmdOriginal:BitmapData = imgd.original;
			
			// Scale and inset the DocumentObjects to match the scaled/inset after image
			if (fDoObjects) {
				var dctPropertySets:Object = {};
				SetPropertiesObjectOperation.ScaleDocumentObjects(dctPropertySets, imgd, ob.nScaleX);
				SetPropertiesObjectOperation.OffsetDocumentObjects(dctPropertySets, imgd, ob.xAfter, 0);
				SetPropertiesObjectOperation.SetProperties(dctPropertySets, imgd);
				imgd.documentObjects.Validate();
			}

			var bmdOut:BitmapData = VBitmapData.Construct(ob.cxOut, ob.cyOut, true, _coBackground | 0xff000000);
			
			// Draw before (original) image into the output bitmap
			// Scale it to fit within the available space (UNDONE: but only down, never up)
			var matImage:Matrix = new Matrix();
			matImage.scale(ob.cxBefore / ob.nSplitAmount / bmdOriginal.width, ob.cyBefore / bmdOriginal.height);
			var rcClip:Rectangle = null;
			if (_strType == kstrSplit)
				rcClip = new Rectangle(0, 0, ob.cxBefore, ob.cyAfter);
			matImage.translate(0, (ob.cyOutMinusCaption - ob.cyBefore) / 2);
			bmdOut.draw(bmdOriginal, matImage, null, null, rcClip);
			
			// Draw after (source) image into the output bitmap, scaled and translated past the before image and the gap
			matImage = new Matrix();
			matImage.scale(ob.cxAfter / ob.nSplitAmount / bmdSrc.width, ob.cyAfter / bmdSrc.height);
			rcClip = null;
			if (_strType == kstrSplit) {
				rcClip = new Rectangle(ob.cxBefore + ob.cxGap, 0, bmdSrc.width / 2, bmdSrc.height);
				matImage.translate(-ob.cxAfter + ob.cxBefore + ob.cxGap, 0);
			} else {
				matImage.translate(ob.xAfter, (ob.cyOutMinusCaption - ob.cyAfter) / 2);
			}
			bmdOut.draw(bmdSrc, matImage, null, null, rcClip);
			
			return bmdOut;
		}
		
		static public function CalcBeforeAfterParams(cxBefore:Number, cyBefore:Number, cxAfter:Number, cyAfter:Number, nBorderAmount:Number,
				nCaptionAmount:Number, strType:String, cxMax:Number, cyMax:Number, cPixelsMax:Number): Object {
			var ob:Object = {};
			ob.nSplitAmount = strType == kstrSplit ? 0.5 : 1.0;
			ob.cxGap = Math.round(cxAfter * nBorderAmount);
			
			// Use the after height for the output image
			var ptLimitedBefore:Point = Util.GetLimitedImageSize(cxBefore, cyBefore, cxBefore, cyAfter);
			ob.cxBefore = ptLimitedBefore.x * ob.nSplitAmount;
			ob.cyBefore = ptLimitedBefore.y;
			ob.cxAfter = cxAfter * ob.nSplitAmount;
			ob.cyAfter = cyAfter;
			ob.cxOut = ob.cxBefore + ob.cxGap + ob.cxAfter;
			ob.cyCaption = Math.round(cyAfter * nCaptionAmount);
			ob.cyOutMinusCaption = Math.max(ob.cyBefore, ob.cyAfter);
			ob.cyOut = ob.cyOutMinusCaption + ob.cyCaption;
			
			// Scale the output to fit within the resolution limits
			var ptLimited:Point = Util.GetLimitedImageSize(ob.cxOut, ob.cyOut, cxMax, cyMax, cPixelsMax);
			ob.nScaleX = ptLimited.x / ob.cxOut;
			ob.nScaleY = ptLimited.y / ob.cyOut;
			ob.cxOut = ptLimited.x;
			ob.cyOut = ptLimited.y;
			ob.cxGap *= ob.nScaleX;
			ob.cyCaption *= ob.nScaleY;
			ob.cyOutMinusCaption *= ob.nScaleY;
			ob.cxAfter = ob.cxAfter * ob.nScaleX;
			ob.cyAfter = ob.cyAfter * ob.nScaleY;
			ob.cxBefore = ob.cxBefore * ob.nScaleX;
			ob.cyBefore = ob.cyBefore * ob.nScaleY;
			ob.xGap = ob.cxBefore;
			ob.xAfter = ob.xGap + ob.cxGap;
			
			// This is what the BeforeAfterEffect uses to size and position the objects it overlays
			ob.beforeRect = new Rectangle(0, (ob.cyOutMinusCaption - ob.cyBefore) / 2, ob.cxBefore, ob.cyBefore);
			ob.afterRect = new Rectangle(ob.xAfter, 0, ob.cxAfter, ob.cyAfter);
			return ob;
		}
	}
}
