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
package imagine.imageOperations
{
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.Graphics;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import util.BitmapCache;
	import util.VBitmapData;
	
	[RemoteClass]
	public class ShapeGradientImageMask extends ImageMask
	{
		// Configurations		
		protected var _nAspectRatio:Number = 1; // width/height - adjusts width
		protected var _nInnerRadius:Number = 0; // applies to height if aspect != 1
		protected var _nOuterRadius:Number = 100; // applies to height if aspect != 1
		protected var _nInnerAlpha:Number = 0;
		protected var _nOuterAlpha:Number = 1;
		protected var _xCenter:Number = 0;
		protected var _yCenter:Number = 0;
		protected var _fCache:Boolean = true;

		public function ShapeGradientImageMask(rcBounds:Rectangle=null)
		{
			super(rcBounds);
		}

		override public function writeExternal(output:IDataOutput):void {
			super.writeExternal(output);
			var obMask:Object = {};
			obMask.aspectRatio = _nAspectRatio;
			obMask.innerRadius = _nInnerRadius;
			obMask.outerRadius = _nOuterRadius;
			obMask.innerAlpha = _nInnerAlpha;
			obMask.outerAlpha = _nOuterAlpha;
			obMask.xCenter = _xCenter;
			obMask.yCenter = _yCenter;
			obMask.fCache = _fCache;
			output.writeObject(obMask);
		}
		
		override public function readExternal(input:IDataInput):void {
			super.readExternal(input);
			var obMask:Object = input.readObject();
			_nAspectRatio = obMask.aspectRatio;
			_nInnerRadius = obMask.innerRadius;
			_nOuterRadius = obMask.outerRadius;
			_nInnerAlpha = obMask.innerAlpha;
			_nOuterAlpha = obMask.outerAlpha;
			_xCenter = obMask.xCenter;
			_yCenter = obMask.yCenter;
			_fCache = obMask.fCache;
			resetMask();
		}

		public override function Serialize(): XML {
			var xml:XML = super.Serialize();
			xml.@aspectRatio = _nAspectRatio;
			xml.@innerRadius = _nInnerRadius;
			xml.@outerRadius = _nOuterRadius;
			xml.@innerAlpha = _nInnerAlpha;
			xml.@outerAlpha = _nOuterAlpha;
			xml.@xCenter = _xCenter;
			xml.@yCenter = _yCenter;
			xml.@fCache = _fCache ? 'true' : 'false';
			return xml;
		}

		public function DrawOutline(gr:Graphics, xOff:Number, yOff:Number, cxWidth:Number, cyHeight:Number): void {
			throw new Error("Override in subclasses");
		} 

		public override function Deserialize(xml:XML): Boolean {
			var fSuccess:Boolean = super.Deserialize(xml);
			if (fSuccess) {
				Debug.Assert(xml.@aspectRatio, "ImageMask aspectRatio argument missing");
				_nAspectRatio = Number(xml.@aspectRatio);
				Debug.Assert(xml.@innerRadius, "ImageMask innerRadius argument missing");
				_nInnerRadius = Number(xml.@innerRadius);
				Debug.Assert(xml.@outerRadius, "ImageMask outerRadius argument missing");
				_nOuterRadius = Number(xml.@outerRadius);
				Debug.Assert(xml.@innerAlpha, "ImageMask innerAlpha argument missing");
				_nInnerAlpha = Number(xml.@innerAlpha);
				Debug.Assert(xml.@outerAlpha, "ImageMask outerAlpha argument missing");
				_nOuterAlpha = Number(xml.@outerAlpha);
				Debug.Assert(xml.@xCenter, "ImageMask xCenter argument missing");
				_xCenter = Number(xml.@xCenter);
				Debug.Assert(xml.@yCenter, "ImageMask yCenter argument missing");
				_yCenter = Number(xml.@yCenter);
				
				if (xml.hasOwnProperty('@fCache'))
					_fCache = xml.@fCache == 'true';
				else
					_fCache = true;
			}
			return fSuccess;
		}
		
		public function calcGradientSubMaskKey(): String {
			// Based on aspect ratio, alphas, radii.
			// Not based on xCenter, yCenter
			var anKey:Array = [_nAspectRatio, _nInnerRadius, _nOuterRadius, _nInnerAlpha, _nOuterAlpha];
			var rcCropped:Rectangle = getCroppedGradientSubMaskRect();
			var rcAbs:Rectangle = getAbstractGradientSubMaskRect();
			if (!rcAbs.equals(rcCropped)) {
				anKey.push(rcCropped.x);
				anKey.push(rcCropped.y);
				anKey.push(rcCropped.width);
				anKey.push(rcCropped.height);
			}
			return anKey.join(",");
		}
		
		public function set cache(f:Boolean): void {
			_fCache = f;
		}
		
		public function get xCenter(): Number {
			return _xCenter;
		}
		
		public function set xCenter(xCenter:Number): void {
			_xCenter = Math.round(xCenter);
			resetMask();
		}
		
		public function get yCenter(): Number {
			return _yCenter;
		}
		
		public function set yCenter(yCenter:Number): void {
			_yCenter = Math.round(yCenter);
			resetMask();
		}
		
		public function set aspectRatio(nAspectRatio:Number): void {
			_nAspectRatio = nAspectRatio;
			resetMask();
		}
		
		public function set innerRadius(nInnerRadius:Number): void {
			_nInnerRadius = Math.round(nInnerRadius);
			resetMask();
		}

		public function set outerRadius(nOuterRadius:Number): void {
			_nOuterRadius = Math.round(nOuterRadius);
			resetMask();
		}
		
		public function set outerAlpha(nOuterAlpha:Number): void {
			_nOuterAlpha = nOuterAlpha;
			resetMask();
		}
		
		public function set innerAlpha(nInnerAlpha:Number): void {
			_nInnerAlpha = nInnerAlpha;
			resetMask();
		}
		
		public function getHeightRadius(): Number {
			return (_nOuterRadius + _nInnerRadius) / 2;
		}
		public function getWidthRadius(): Number {
			return getHeightRadius() * _nAspectRatio;
		}

		protected function resetMask(): void {
			// no longer necessary since our key will be updated if anything changes
			//			var bmdMask:BitmapData = BitmapCache.Lookup(this, maskCacheName, Serialize().toXMLString(), null);
			//			if (bmdMask) {
			//				BitmapCache.Remove(bmdMask);
			// 				bmdMask.dispose(); // Get rid of the old mask
			// 			}
			//			var bmdGradientSubMask:BitmapData = BitmapCache.Lookup(this, subMaskCacheName, calcGradientSubMaskKey(), null);
			//			if (bmdGradientSubMask) {
			//				BitmapCache.Remove(bmdGradientSubMask);
			// 				bmdGradientSubMask.dispose(); // Get rid of the old mask
			// 			}
		}
		
		// This is a cropped version of the abstract rect, below.
		// These are identical until the cropped rect is greater than cxyImageMax on a side.
		// In that case, we crop to [0,0,cxyImageMax,cxyImageMax]
		protected function getCroppedGradientSubMaskRect(): Rectangle {
			var rcAbs:Rectangle = getAbstractGradientSubMaskRect();
			var ptLimited:Point = Util.GetLimitedImageSize(width, height);
			return rcAbs.intersection(new Rectangle(0, 0, ptLimited.x, ptLimited.y));
		}

		// This is the abstract rect, with no height/width bounds
		// If the max height/width is less than cxyImageMax, use the same rect for the cropped version
		protected function getAbstractGradientSubMaskRect(): Rectangle {
			var nOuterRadius:Number = Math.max(_nInnerRadius, _nOuterRadius);
			var nHeight:Number = nOuterRadius * 2;
			var nWidth:Number = nHeight * _nAspectRatio;
			return new Rectangle(Math.round(_xCenter - nWidth/2),
				Math.round(_yCenter - nHeight/2), Math.round(nWidth), Math.round(nHeight));
		}

		protected function generateGradientSubMask(): BitmapData {
			throw new Error("Override in sub-classes.");
		}

		protected function get shapeType(): String {
			return "Shape";
		}
		
		protected function get maskCacheName(): String {
			return shapeType + "GradientImageMask";
		}

		protected function get subMaskCacheName(): String {
			return shapeType + "GradientImageSubMask";
		}

		protected function get maskName(): String {
			return shapeType + " Gradient Mask";
		}

		protected function getGradientSubMask(): BitmapData {
			var bmdGradientSubMask:BitmapData = BitmapCache.Lookup(this, subMaskCacheName, calcGradientSubMaskKey(), null);
			if (!bmdGradientSubMask) {
				bmdGradientSubMask = generateGradientSubMask();
				BitmapCache.Set(this, subMaskCacheName, calcGradientSubMaskKey(), null, bmdGradientSubMask);
			}
			return bmdGradientSubMask;
		}
		
		public override function DoneDrawing(): void {
			super.DoneDrawing();
			if (!_fCache) {
				BitmapCache.ClearOne(this, maskCacheName);
				BitmapCache.ClearOne(this, subMaskCacheName);
			}
		}

		public override function get AlphaBounds(): Rectangle {
			if (_nOuterAlpha != 1) return null; // This only works if outer alpha is 1
			else return getCroppedGradientSubMaskRect();
		}
		
		protected function generateMask(): BitmapData {
			if (_rcBounds == null) {
				return null; // Bail out until we have bounds
			}
			var bmdMask:BitmapData = VBitmapData.Construct(width, height, true, 0, maskName); // Fill with alpha 0
			BitmapCache.Set(this, maskCacheName, Serialize().toXMLString(), null, bmdMask);

			var rcSubMask:Rectangle = getCroppedGradientSubMaskRect();
			var bmdGradientSubMask:BitmapData = getGradientSubMask();
			if (bmdGradientSubMask)
				bmdMask.copyChannel(bmdGradientSubMask, bmdGradientSubMask.rect, rcSubMask.topLeft, BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
			return bmdMask;
		}
		
		public override function Mask(bmdOrig:BitmapData): BitmapData {
			
			if (_nOuterAlpha == 1) {
				return getGradientSubMask();
			} else {
				var bmdMask:BitmapData = BitmapCache.Lookup(this, maskCacheName, Serialize().toXMLString(), null);
				if (!bmdMask || bmdMask.width != width || bmdMask.height != height) {
					return generateMask();
				}
				return bmdMask;
			}
		}
	}
}