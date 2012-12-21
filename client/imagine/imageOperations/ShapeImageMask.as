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
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import util.BitmapCache;
	import util.VBitmapData;
	
	[RemoteClass]
	public class ShapeImageMask extends ImageMask
	{
		// Configurations		
		private var _nShapeWidth:Number = 0;
		private var _nShapeHeight:Number= 0;
		private var _xCenter:Number = 0;
		private var _yCenter:Number = 0;
		private var _nInnerAlpha:Number = 0;
		private var _nOuterAlpha:Number = 1;
		private var _strShape:String = "rect";
		
		public function ShapeImageMask(rcBounds:Rectangle = null) {
			super(rcBounds);
		}
		
		override public function writeExternal(output:IDataOutput):void {
			super.writeExternal(output);
			var obMask:Object = {};

			obMask.shapeWidth = _nShapeWidth;
			obMask.shapeHeight = _nShapeHeight;
			obMask.xCenter = _xCenter;
			obMask.yCenter = _yCenter;
			obMask.innerAlpha = _nInnerAlpha;
			obMask.outerAlpha = _nOuterAlpha;
			obMask.shape = _strShape;
			
			output.writeObject(obMask);
		}
		
		override public function readExternal(input:IDataInput):void {
			super.readExternal(input);
			var obMask:Object = input.readObject();

			_nShapeWidth = obMask.shapeWidth;
			_nShapeHeight = obMask.shapeHeight;
			_xCenter = obMask.xCenter;
			_yCenter = obMask.yCenter;
			_nInnerAlpha = obMask.innerAlpha;
			_nOuterAlpha = obMask.outerAlpha;
			_strShape = obMask.shape;
		}
		
		public override function Serialize(): XML {
			var xml:XML = super.Serialize();
			xml.@shapeWidth = _nShapeWidth;
			xml.@shapeHeight = _nShapeHeight;
			xml.@xCenter = _xCenter;
			xml.@yCenter = _yCenter;
			xml.@innerAlpha = _nInnerAlpha;
			xml.@outerAlpha = _nOuterAlpha;
			xml.@shape = _strShape;
			return xml;
		}

		public override function Deserialize(xml:XML): Boolean {
			var fSuccess:Boolean = super.Deserialize(xml);
			if (fSuccess) {
				Debug.Assert(xml.@shapeWidth, "ShapeImageMask shapeWidth argument missing");
				_nShapeWidth = Number(xml.@shapeWidth);
				Debug.Assert(xml.@shapeHeight, "ShapeImageMask shapeHeight argument missing");
				_nShapeHeight = Number(xml.@shapeHeight);
				Debug.Assert(xml.@innerAlpha, "ShapeImageMask innerAlpha argument missing");
				_nInnerAlpha = Number(xml.@innerAlpha);
				Debug.Assert(xml.@outerAlpha, "ShapeImageMask outerAlpha argument missing");
				_nOuterAlpha = Number(xml.@outerAlpha);
				Debug.Assert(xml.@xCenter, "ShapeImageMask xCenter argument missing");
				_xCenter = Number(xml.@xCenter);
				Debug.Assert(xml.@yCenter, "ShapeImageMask yCenter argument missing");
				_yCenter = Number(xml.@yCenter);
				Debug.Assert(xml.@shape, "ShapeImageMask shape argument missing");
				_strShape = String(xml.@shape);
			}
			return fSuccess;
		}
				
		public function get xCenter(): Number {
			return _xCenter;
		}
		
		public function set xCenter(xCenter:Number): void {
			_xCenter = Math.round(xCenter);
		}
		
		public function get yCenter(): Number {
			return _yCenter;
		}
		
		public function set yCenter(yCenter:Number): void {
			_yCenter = Math.round(yCenter);
		}
				
		public function set shapeWidth(n:Number): void {
			_nShapeWidth = Math.round(n);
		}

		public function set shapeHeight(n:Number): void {
			_nShapeHeight = Math.round(n);
		}
		
		public function set outerAlpha(nOuterAlpha:Number): void {
			_nOuterAlpha = nOuterAlpha;
		}
		
		public function set innerAlpha(nInnerAlpha:Number): void {
			_nInnerAlpha = nInnerAlpha;
		}		
		
		public function set shape(s:String): void {
			_strShape = s;
		}
		
//		public function getHeightRadius(): Number {
//			return (_nOuterRadius + _nInnerRadius) / 2;
//		}
//		public function getWidthRadius(): Number {
//			return getHeightRadius() * _nAspectRatio;
//		}

		protected function generateMask(): BitmapData {
			if (_rcBounds == null) {
				return null; // Bail out until we have bounds
			}
			var bmdMask:BitmapData = VBitmapData.Construct(width, height, true, 0xFF000000 + 0xFF*_nOuterAlpha); // Fill with outer alpha
			
			var shp:Shape = new Shape();
			shp.graphics.beginFill(0xFF*_nInnerAlpha);
			if (_strShape.toLowerCase() == "ellipse") {
				shp.graphics.drawEllipse(_xCenter - _nShapeWidth/2, _yCenter-_nShapeHeight/2, _nShapeWidth, _nShapeHeight);
			} else {
				// default is rect
				shp.graphics.drawRect(_xCenter - _nShapeWidth/2, _yCenter-_nShapeHeight/2, _nShapeWidth, _nShapeHeight);
			}
			shp.graphics.endFill();
			bmdMask.draw(shp,null,null,"normal");
			bmdMask.copyChannel(bmdMask,bmdMask.rect,new Point(), BitmapDataChannel.BLUE, BitmapDataChannel.ALPHA);
			return bmdMask;
		}
		
		public override function Mask(bmdOrig:BitmapData): BitmapData {
			var bmdMask:BitmapData = BitmapCache.Lookup(this, "EllipticalImageMask", Serialize().toXMLString(), null);
			if (!bmdMask || bmdMask.width != width || bmdMask.height != height) {
				return generateMask();
			}
			return bmdMask;
		}
	}
}
