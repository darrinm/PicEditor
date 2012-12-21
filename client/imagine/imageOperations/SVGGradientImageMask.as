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
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import util.VBitmapData;
	import util.svg.PathSegmentsCollection;
	
	[RemoteClass]
	public class SVGGradientImageMask extends ShapeGradientImageMask
	{
		private var _strSVGPath:String = "";
		private var _psgc:PathSegmentsCollection;
		
		public function SVGGradientImageMask(rcBounds:Rectangle = null) {
			super(rcBounds);
			_psgc = new PathSegmentsCollection(null);
		}

		override public function DrawOutline(gr:Graphics, xOff:Number, yOff:Number, cxWidth:Number, cyHeight:Number): void {
			_psgc.generateGraphicsPathInBox(gr, new Rectangle(xOff, yOff, cxWidth, cyHeight));
		} 

		public override function Serialize(): XML {
			var xml:XML = super.Serialize();
			xml.@svgpath = svgpath;
			return xml;
		}

		override public function writeExternal(output:IDataOutput):void {
			super.writeExternal(output);
			var obMask:Object = {};
			obMask.svgpath = svgpath;
			output.writeObject(obMask);
		}
		
		override public function readExternal(input:IDataInput):void {
			super.readExternal(input);
			var obMask:Object = input.readObject();
			svgpath = obMask.svgpath;
		}
		
		public override function Deserialize(xml:XML): Boolean {
			var fSuccess:Boolean = super.Deserialize(xml);
			if (fSuccess) {
				Debug.Assert(xml.hasOwnProperty('@svgpath'), "SVGGradientImageMask svgpath argument missing");
				svgpath = String(xml.@svgpath);
			}
			return fSuccess;
		}
		
		public function set svgpath(str:String): void {
			_strSVGPath = str;
			_psgc = new PathSegmentsCollection(_strSVGPath);
		}
		
		public function get svgpath(): String {
			return _strSVGPath;
		}

		override public function calcGradientSubMaskKey(): String {
			return super.calcGradientSubMaskKey() + "," + svgpath;
		}

		override protected function get shapeType(): String {
			return "SVG";
		}

		override protected function generateGradientSubMask(): BitmapData {
			var bmdMask:BitmapData;
			var rcAbsSubMask:Rectangle = getAbstractGradientSubMaskRect();
			var rcCroppedSubMask:Rectangle = getCroppedGradientSubMaskRect();
			if (rcCroppedSubMask.isEmpty())
				return null;

			var shp:Shape = new Shape();
			var nOuterRadius:Number = Math.max(_nInnerRadius, _nOuterRadius);
			bmdMask = VBitmapData.Construct(rcCroppedSubMask.width, rcCroppedSubMask.height, true, 0, 'circular gradient sub-mask'); // Fill with alpha 0
			
			var xOff:Number = rcAbsSubMask.x - rcCroppedSubMask.x;
			var yOff:Number = rcAbsSubMask.y - rcCroppedSubMask.y;
			
			var nFadeRadius:Number = Math.abs(_nInnerRadius - _nOuterRadius);
			
			var rcDraw:Rectangle = new Rectangle(xOff, yOff, rcAbsSubMask.height, rcAbsSubMask.width);
			
			rcDraw.inflate(-nFadeRadius/2, -nFadeRadius/2);
			
			if (nFadeRadius > 0) {
				shp.filters = [new BlurFilter(nFadeRadius/2, nFadeRadius/2, 2)];
			}
			
			shp.graphics.beginFill(0, 1); // We want to reverse this somehow? WTF?
			_psgc.generateGraphicsPathInBox(shp.graphics, rcDraw);
			shp.graphics.endFill();
			
			bmdMask.draw(shp);
			
			// At this point, our outer alpha is 0 and inner alpha is 1.
			// Adjust to match what we want.
			var nAOff:Number = _nOuterAlpha * 255;
			var nAMult:Number = (_nInnerAlpha *255 - _nOuterAlpha * 255) / 255;
			var fltInvertAlpha:ColorMatrixFilter = new ColorMatrixFilter(
				[1,0,0,0,0,
				 0,1,0,0,0,
				 0,0,1,0,0,
				 0,0,0,nAMult,nAOff]);
			bmdMask.applyFilter(bmdMask, bmdMask.rect, new Point(0,0), fltInvertAlpha);
			
			return bmdMask;
		}
	}
}
