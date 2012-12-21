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
	import flash.display.BitmapDataChannel;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import util.BitmapCache;
	import util.VBitmapData;
	import util.svg.PathSegmentsCollection;
	
	[RemoteClass]
	public class ShapeImageOperation extends BlendImageOperation {
		private var _xCenter:Number = NaN;
		private var _yCenter:Number = NaN;
		private var _nWidth:Number = NaN;
		private var _nHeight:Number = NaN;
		private var _strGradType:String = "radial";		// radial, linear
		private var _strShapeBlend:String = "normal";
		private var _strShape:String = "ellipse";
		private var _xGradOffset:Number = 0;
		private var _yGradOffset:Number = 0;
		private var _nGradRotation:Number = 0;
		private var _aColors:Array = [ 0x000000 ];
		private var _aAlphas:Array = [ 1.0 ];
		private var _aRatios:Array = [ 0 ];
		private var _nRotation:Number = 0;
		private var _fMaintainAspectRatio:Boolean = true;
		private var _fInvertFill:Boolean = false;
		private var _fAlphaMask:Boolean = false;
		private var _fCacheShape:Boolean = false;

		public function set x(x:Number): void {
			_xCenter = x;
		}
		
		public function get x(): Number {
			return _xCenter;
		}
		
		public function set y(y:Number): void {
			_yCenter = y;
		}
		
		public function get y(): Number {
			return _yCenter;
		}
		
		public function set width(n:Number): void {
			_nWidth = n;
		}
		
		public function get width(): Number {
			return _nWidth;
		}
		
		public function set height(n:Number): void {
			_nHeight = n;
		}
		
		public function get height(): Number {
			return _nHeight;
		}
		
		public function set rotation(n:Number): void {
			_nRotation = n;
		}
		
		public function get rotation(): Number {
			return _nRotation;
		}
		
		public function set gradType(s:String): void {
			_strGradType = s;
		}
		
		public function get gradType(): String {
			return _strGradType;
		}
		
		public function set shapeBlend(s:String): void {
			_strShapeBlend = s;
		}
		
		public function get shapeBlend(): String {
			return _strShapeBlend;
		}
		
		public function set gradRotation(n:Number): void {
			_nGradRotation = n;
		}
		
		public function get gradRotation(): Number {
			return _nGradRotation;
		}
		
		public function set shape(s:String): void {
			_strShape = s;
		}
		
		public function get shape(): String {
			return _strShape;
		}
		
		public function set xGradOffset(n:Number): void {
			_xGradOffset = n;
		}
		
		public function get xGradOffset(): Number {
			return _xGradOffset;
		}
		
		public function set yGradOffset(n:Number): void {
			_yGradOffset = n;
		}
		
		public function get yGradOffset(): Number {
			return _yGradOffset;
		}
		
		public function set colors(a:Array): void {
			_aColors = a;
		}
		
		public function get colors(): Array {
			return _aColors;
		}
		
		public function set alphas(a:Array): void {
			_aAlphas = a;
		}
		
		public function get alphas(): Array {
			return _aAlphas;
		}
		
		public function set ratios(a:Array): void {
			_aRatios = a;
		}
		
		public function get ratios(): Array {
			return _aRatios;
		}
		
		public function set maintainAspectRatio(f:Boolean): void {
			_fMaintainAspectRatio = f;
		}
		
		public function get maintainAspectRatio(): Boolean {
			return _fMaintainAspectRatio;
		}
		
		public function set invertFill(f:Boolean): void {
			_fInvertFill = f;
		}
		
		public function get invertFill(): Boolean {
			return _fInvertFill;
		}
		
		public function set alphaMask(f:Boolean): void {
			_fAlphaMask = f;
		}
		
		public function get alphaMask(): Boolean {
			return _fAlphaMask;
		}
		
		public function set cacheShape(f:Boolean): void {
			_fCacheShape = f;
		}
		
		public function get cacheShape(): Boolean {
			return _fCacheShape;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo([
			'x', 'y', 'width', 'height', 'rotation', 'gradType', 'shapeBlend', 'gradRotation',
			'shape', 'xGradOffset', 'yGradOffset', 'colors', 'alphas', 'ratios', 'maintainAspectRatio',
			'invertFill', 'alphaMask', 'cacheShape']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		public function ShapeImageOperation() {
		}

		override protected function DeserializeSelf(xmlOp:XML): Boolean {
//			if (xmlOp.@alpha.toString().length > 0) _nAlpha = Number(xmlOp.@alpha);
			Debug.Assert(xmlOp.@x, "ShapeImageOperation x parameter missing");
			_xCenter = Number(xmlOp.@x);
			Debug.Assert(xmlOp.@y, "ShapeImageOperation y parameter missing");
			_yCenter = Number(xmlOp.@y);
			Debug.Assert(xmlOp.@width, "ShapeImageOperation width parameter missing");
			_nWidth = Number(xmlOp.@width);
			Debug.Assert(xmlOp.@height, "ShapeImageOperation height parameter missing");
			_nHeight = Number(xmlOp.@height);
			Debug.Assert(xmlOp.@gradType, "ShapeImageOperation gradType parameter missing");
			_strGradType = String(xmlOp.@gradType);
			Debug.Assert(xmlOp.@shapeBlend, "ShapeImageOperation shapeBlend parameter missing");
			_strShapeBlend = String(xmlOp.@shapeBlend);
			Debug.Assert(xmlOp.@xGradOffset, "ShapeImageOperation xGradOffset parameter missing");
			_xGradOffset = Number(xmlOp.@xGradOffset);
			Debug.Assert(xmlOp.@yGradOffset, "ShapeImageOperation yGradOffset parameter missing");
			_yGradOffset = Number(xmlOp.@yGradOffset);
			Debug.Assert(xmlOp.@colors, "ShapeImageOperation colors parameter missing");
			_aColors = String(xmlOp.@colors).split(",");
			Debug.Assert(xmlOp.@alphas, "ShapeImageOperation alphas parameter missing");
			_aAlphas = String(xmlOp.@alphas).split(",");
			Debug.Assert(xmlOp.@ratios, "ShapeImageOperation ratios parameter missing");
			_aRatios = String(xmlOp.@ratios).split(",");
			Debug.Assert(xmlOp.@gradRotation, "ShapeImageOperation gradRotation parameter missing");
			_nGradRotation = Number(xmlOp.@gradRotation);
			Debug.Assert(xmlOp.@shape, "ShapeImageOperation shape parameter missing");
			_strShape = String(xmlOp.@shape);
			Debug.Assert(xmlOp.@rotation, "ShapeImageOperation rotation parameter missing");
			_nRotation = Number(xmlOp.@rotation);
			Debug.Assert(xmlOp.@maintainAspectRatio, "ShapeImageOperation maintainAspectRatio parameter missing");
			_fMaintainAspectRatio = Boolean(xmlOp.@maintainAspectRatio == "true");
			Debug.Assert(xmlOp.@invertFill, "ShapeImageOperation invertFill parameter missing");
			_fInvertFill = Boolean(xmlOp.@invertFill == "true");
			Debug.Assert(xmlOp.@alphaMask, "ShapeImageOperation alphaMask parameter missing");
			_fAlphaMask = Boolean(xmlOp.@alphaMask == "true");
			Debug.Assert(xmlOp.@cacheShape, "ShapeImageOperation cacheShape parameter missing");
			_fCacheShape = Boolean(xmlOp.@cacheShape == "true");
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Shape x={_xCenter} y={_yCenter}
							width={_nWidth} height={_nHeight}
							rotation={_nRotation}
							shape={_strShape} shapeBlend={_strShapeBlend}
							xGradOffset={_xGradOffset} yGradOffset={_yGradOffset}
							colors={_aColors.join(",")}
							alphas={_aAlphas.join(",")}
							ratios={_aRatios.join(",")}
							gradType={_strGradType} gradRotation={_nGradRotation} cacheShape={_fCacheShape}
							maintainAspectRatio={_fMaintainAspectRatio} invertFill={_fInvertFill} alphaMask={_fAlphaMask}
						/>
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return DrawShape(bmdSrc);
		}

		static public function DrawSVGShape(strShape:String, shp:Shape, x:Number, y:Number, w:Number, h:Number, fMaintainAspectRatio:Boolean): Point {
			if (strShape.toLowerCase() == "ellipse") {
				shp.graphics.drawEllipse(x-w/2,y-h/2,w,h);
				return new Point(w,h);
			} else if (strShape.toLowerCase() == "rect") {
				shp.graphics.drawRect(x-w/2,y-h/2,w,h);
				return new Point(w,h);
 			} else {
 				// assume SVG string
 				var psc:PathSegmentsCollection = new PathSegmentsCollection(strShape); 				
				var rcNativeBounds:Rectangle = psc.getBounds();
				var xNativeMid:Number = (rcNativeBounds.left + rcNativeBounds.right) / 2;
				var yNativeMid:Number = (rcNativeBounds.top + rcNativeBounds.bottom) / 2;
				var xScale:Number = w / rcNativeBounds.width;
				var yScale:Number = h / rcNativeBounds.height;

				if (fMaintainAspectRatio) {
					xScale = yScale = Math.min(xScale,yScale);
				}

				var xScaledMid:Number = xNativeMid * xScale;
				var yScaledMid:Number = yNativeMid * yScale;
				var xOff:Number = x - xScaledMid;
				var yOff:Number = y - yScaledMid;
		
				psc.generateGraphicsPath(shp.graphics, xOff, yOff, xScale, yScale); 				
				return new Point(rcNativeBounds.width, rcNativeBounds.height);
 			}
		}
		
		private function _rotatePoint( ptPoint:Point, nAngle:Number, ptAround:Point ): Point {
			var nX:Number = (ptPoint.x-ptAround.x) * Math.cos(nAngle) - (ptPoint.y-ptAround.y) * Math.sin(nAngle) + ptAround.x;
			var nY:Number = (ptPoint.y-ptAround.y) * Math.cos(nAngle) + (ptPoint.x-ptAround.x) * Math.sin(nAngle) + ptAround.y;
			return new Point(nX, nY);
		}

		private function _drawRotatedRect( shp:Shape, x:Number, y:Number, w:Number, h:Number, a:Number ): void {
			var ptCenter:Point = new Point(0,0);
			var aRect:Array = [ new Point(x, y),
								new Point(x+w, y),
								new Point(x+w, y+h),
								new Point(x, y+h) ];
			for (var i:int = 0; i < aRect.length; i++ ) {
				aRect[i] = _rotatePoint(aRect[i], a, ptCenter);
			}
			shp.graphics.moveTo(aRect[3].x, aRect[3].y);
			for (i = 0; i < aRect.length; i++ ) {
				shp.graphics.lineTo(aRect[i].x, aRect[i].y);
			}
		}
		
		private function _getCacheableShapeParams(x:Number, y:Number, w:Number, h:Number): String {
			var xmlParams:XML = <Shape x={x} y={y}
					width={w} height={h}
					rotation={_nRotation} shape={_strShape}
					maintainAspectRatio={_fMaintainAspectRatio}/>
			return xmlParams.toXMLString()
		}

		private function _drawFilledShape(bmdFinal:BitmapData): BitmapData {
			var w:Number = isNaN(_nWidth) ? bmdFinal.width : _nWidth;
			var h:Number = isNaN(_nHeight) ? bmdFinal.height : _nHeight;
			var x:Number = isNaN(_xCenter) ? bmdFinal.width/2 : _xCenter;
			var y:Number = isNaN(_yCenter) ? bmdFinal.height/2: _yCenter;
			
			var shp:Shape = new Shape();
			var ptSize:Point = null;
			if (_aColors == null || _aColors.length < 2) {
				// solid
				var nColor:uint = (_aColors && _aColors.length == 1) ? _aColors[0]: 0x000000;
				var nAlpha:Number = (_aAlphas && _aAlphas.length == 1) ? _aAlphas[0]: 1.0;
				
				shp.graphics.beginFill(nColor,nAlpha);
				if (_fInvertFill) {
					_drawRotatedRect(shp, -x,-y,bmdFinal.width, bmdFinal.height, -_nRotation);
				}
				ptSize = DrawSVGShape(_strShape, shp, 0, 0, w, h, _fMaintainAspectRatio);
				shp.graphics.endFill();
				
			} else {
				// gradient
				var aColors:Array = _aColors;
				var aAlphas:Array = _aAlphas;
				var aRatios:Array = _aRatios;
				
				// make them all the same length
				var nEls:int = Math.min(aColors.length, aAlphas.length, aRatios.length);
				if (aColors.length > nEls) {
					aColors.splice(nEls, aColors.length-nEls);
				}
				if (aAlphas.length > nEls) {
					aAlphas.splice(nEls, aAlphas.length-nEls);
				}
				if (aRatios.length > nEls) {
					aRatios.splice(nEls, aRatios.length-nEls);
				}
				var matrGrad:Matrix = new Matrix();
				matrGrad.createGradientBox( w,h,_nGradRotation,0 - w/2+_xGradOffset,0-h/2+_yGradOffset );
				shp.graphics.beginGradientFill(
						(_strGradType.toLowerCase() == "radial") ? GradientType.RADIAL : GradientType.LINEAR,
						aColors, aAlphas, aRatios,
						matrGrad);
				if (_fInvertFill) {
					_drawRotatedRect(shp, -x,-y,bmdFinal.width, bmdFinal.height, -_nRotation);
				}
				ptSize = DrawSVGShape(_strShape, shp, 0, 0, w, h, _fMaintainAspectRatio);
				shp.graphics.endFill();
			}
			
			var matrDraw:Matrix = new Matrix();
			matrDraw.rotate(_nRotation);
			matrDraw.translate(x,y);
			if (_fAlphaMask) {
				var bmdTemp:VBitmapData = VBitmapData.Construct(bmdFinal.width, bmdFinal.height, true, 0x00FFFFFF, "shape_alphamask_temp");
				VBitmapData.RepairedDraw(bmdTemp,shp,matrDraw,null,_strShapeBlend);
				bmdFinal.copyChannel(bmdTemp,bmdTemp.rect, new Point(0,0), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
				bmdTemp.dispose();
			} else {
				VBitmapData.RepairedDraw(bmdFinal,shp,matrDraw,null,_strShapeBlend);
				//bmdFinal.draw(shp, matrDraw, null, _strShapeBlend);
			}
			return bmdFinal;
		}
		
		public function DrawShape(bmdOrig:BitmapData): BitmapData {
			var w:Number = isNaN(_nWidth) ? bmdOrig.width : _nWidth;
			var h:Number = isNaN(_nHeight) ? bmdOrig.height : _nHeight;
			var x:Number = isNaN(_xCenter) ? bmdOrig.width/2 : _xCenter;
			var y:Number = isNaN(_yCenter) ? bmdOrig.height/2: _yCenter;			
			var bmdFinal:BitmapData = null;
			
			// (STL) Just FYI: shape caching is actually slower than redrawing the
			//	shape each time, so I don't recommend it.  However, if one could
			//  figure out how to condense the following rendering steps a bit
			//  through some clever filters and/or draws, then it might be an improvement.
			if (_fCacheShape && (_aColors == null || _aColors.length < 2)) {
				// no gradient, so try to use a cached version
				var bmdShape:BitmapData = BitmapCache.Lookup(null, "ShapeImageOperation.shape", _getCacheableShapeParams(x,y,w,h), null);
				if (!bmdShape) {
					var fInvertFill:Boolean = _fInvertFill;
					var fAlphaMask:Boolean = _fAlphaMask;
					var aColors:Array = _aColors;
					var aAlphas:Array = _aAlphas;
					var strShapeBlend:String = _strShapeBlend;
					
					_fInvertFill = false;
					_aColors = [0xFFFFFF];
					_aAlphas = [1];
					_fAlphaMask = false;
					_strShapeBlend = "normal";
					
					bmdShape = VBitmapData.Construct(bmdOrig.width, bmdOrig.height, true, 0xFF000000);
					bmdShape = _drawFilledShape(bmdShape);
					BitmapCache.Set(null, "ShapeImageOperation.shape", _getCacheableShapeParams(x,y,w,h), null, bmdShape);
					_fInvertFill = fInvertFill;
					_aColors = aColors;
					_aAlphas = aAlphas;
					_fAlphaMask = fAlphaMask;
					_strShapeBlend = strShapeBlend;
				}
				
				// use the cached rendering to draw the shape with the right color, alpha, and inverted fill
				var nColor:uint = (_aColors && _aColors.length == 1) ? _aColors[0]: 0x000000;
				var nAlpha:Number = (_aAlphas && _aAlphas.length == 1) ? _aAlphas[0]: 1.0;
							
				var bmdTemp:BitmapData = bmdShape.clone();		
				var r:Number = (nColor & 0xFF0000) >> 16;
				var g:Number = (nColor & 0x00FF00) >> 8;
				var b:Number = (nColor & 0x0000FF);				
				var anMatrix:Array;
				
				if (_fInvertFill) {
					anMatrix = [	r/255, 0, 0, 0, 0,
									g/255, 0, 0, 0, 0,
									b/255, 0, 0, 0, 0,
									-nAlpha, 0, 0, 0, 255 ];
				} else {
					anMatrix = [	r/255, 0, 0, 0, 0,
									g/255, 0, 0, 0, 0,
									b/255, 0, 0, 0, 0,
									nAlpha, 0, 0, 0, 0 ];				
				}
				
				var fltCM:ColorMatrixFilter = new ColorMatrixFilter(anMatrix);
				bmdTemp.applyFilter( bmdTemp, bmdTemp.rect, new Point(0,0), fltCM );
				
				bmdFinal = bmdOrig.clone();
				if (_fAlphaMask) {
					bmdFinal.copyChannel(bmdTemp,bmdTemp.rect, new Point(0,0), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
				} else {
					bmdFinal.draw(bmdTemp,null,null,_strShapeBlend);

				}
				bmdTemp.dispose();
			} else {
				bmdFinal = _drawFilledShape(bmdOrig.clone());
			}
			return bmdFinal;
		}
	}
}
