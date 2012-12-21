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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.InterpolationMethod;
	import flash.display.Shape;
	import flash.display.SpreadMethod;
	import flash.filters.BlurFilter;
	import flash.filters.DisplacementMapFilter;
	import flash.filters.DisplacementMapFilterMode;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class GradientShapeImageOperation extends BlendImageOperation {
		private var _xCenter:Number;
		private var _yCenter:Number;
		private var _nWidth:Number;
		private var _nHeight:Number;
		private var _strGradType:String = "radial";
		private var _strGradBlend:String = "screen";
		private var _strShape:String = "ellipse";
		private var _xOffset:Number = 0;
		private var _yOffset:Number = 0;
		private var _nColor1:Number = 0x000000;
		private var _nColor2:Number = 0xFFFFFF;
		private var _nAlpha0:Number = 1;
		private var _nAlpha1:Number = 1;
		private var _nAlpha2:Number = 1;
		private var _nAlpha3:Number = 1;
		private var _nPad1:Number = 0;
		private var _nPad2:Number = 0;
		private var _nGradRotation:Number = 0;

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
		
		public function set gradType(s:String): void {
			_strGradType = s;
		}
		
		public function get gradType(): String {
			return _strGradType;
		}
		
		public function set gradBlend(s:String): void {
			_strGradBlend = s;
		}
		
		public function get gradBlend(): String {
			return _strGradBlend;
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
		
		public function set xOffset(n:Number): void {
			_xOffset = n;
		}
		
		public function get xOffset(): Number {
			return _xOffset;
		}
		
		public function set yOffset(n:Number): void {
			_yOffset = n;
		}
		
		public function get yOffset(): Number {
			return _yOffset;
		}
		
		public function set color1(co:Number): void {
			_nColor1 = co;
		}
		
		public function get color1(): Number {
			return _nColor1;
		}
		
		public function set color2(co:Number): void {
			_nColor2 = co;
		}
		
		public function get color2(): Number {
			return _nColor2;
		}
		
		public function set alpha0(a:Number): void {
			_nAlpha0 = a;
		}
		
		public function get alpha0(): Number {
			return _nAlpha0;
		}
		
		public function set alpha1(a:Number): void {
			_nAlpha1 = a;
		}		
		
		public function get alpha1(): Number {
			return _nAlpha1;
		}		
		
		public function set alpha2(a:Number): void {
			_nAlpha2 = a;
		}
		
		public function get alpha2(): Number {
			return _nAlpha2;
		}
		
		public function set alpha3(a:Number): void {
			_nAlpha3 = a;
		}		
		
		public function get alpha3(): Number {
			return _nAlpha3;
		}		
		
		public function set pad1(a:Number): void {
			_nPad1 = a;
		}
		
		public function get pad1(): Number {
			return _nPad1;
		}
		
		public function set pad2(a:Number): void {
			_nPad2 = a;
		}
		
		public function get pad2(): Number {
			return _nPad2;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo([
			'x', 'y', 'width', 'height', 'gradType', 'gradBlend', 'xOffset', 'yOffset', 'color1',
			'color2', 'alpha0', 'alpha1', 'alpha2', 'alpha3', 'pad1', 'pad2', 'gradRotation', 'shape']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		public function GradientShapeImageOperation(x:Number=NaN, y:Number=NaN, width:Number=NaN, height:Number=NaN, gradType:String="linear", gradBlend:String="normal", xOffset:Number=0, yOffset:Number=0, color1:Number=0xFFFFFF, color2:Number=0x000000, alpha0:Number=1, alpha1:Number=1, alpha2:Number=0, alpha3:Number=0, gradrot:Number=0, shape:String=null) {
			_xCenter = x;
			_yCenter = y;
			_nWidth = width;
			_nHeight = height;
			_strGradType = gradType;
			_strGradBlend = gradBlend;
			_xOffset = xOffset;
			_yOffset = yOffset;
			_nColor1 = color1;
			_nColor2 = color2;
			_nAlpha1 = alpha1;
			_nAlpha2 = alpha2;
			_nAlpha0 = alpha0;
			_nAlpha3 = alpha3;
			_nGradRotation = gradrot;
			_strShape = shape;
		}

		override protected function DeserializeSelf(xmlOp:XML): Boolean {
//			if (xmlOp.@alpha.toString().length > 0) _nAlpha = Number(xmlOp.@alpha);
			Debug.Assert(xmlOp.@x, "GradientShapeImageOperation x parameter missing");
			_xCenter = Number(xmlOp.@x);
			Debug.Assert(xmlOp.@y, "GradientShapeImageOperation y parameter missing");
			_yCenter = Number(xmlOp.@y);
			Debug.Assert(xmlOp.@width, "GradientShapeImageOperation width parameter missing");
			_nWidth = Number(xmlOp.@width);
			Debug.Assert(xmlOp.@height, "GradientShapeImageOperation height parameter missing");
			_nHeight = Number(xmlOp.@height);
			Debug.Assert(xmlOp.@gradType, "GradientShapeImageOperation gradType parameter missing");
			_strGradType = String(xmlOp.@gradType);
			Debug.Assert(xmlOp.@gradBlend, "GradientShapeImageOperation gradBlend parameter missing");
			_strGradBlend = String(xmlOp.@gradBlend);
			Debug.Assert(xmlOp.@xOffset, "GradientShapeImageOperation xOffset parameter missing");
			_xOffset = Number(xmlOp.@xOffset);
			Debug.Assert(xmlOp.@yOffset, "GradientShapeImageOperation yOffset parameter missing");
			_yOffset = Number(xmlOp.@yOffset);
			Debug.Assert(xmlOp.@color1, "GradientShapeImageOperation color1 parameter missing");
			_nColor1 = Number(xmlOp.@color1);
			Debug.Assert(xmlOp.@color2, "GradientShapeImageOperation color2 parameter missing");
			_nColor2 = Number(xmlOp.@color2);
			Debug.Assert(xmlOp.@alpha1, "GradientShapeImageOperation alpha1 parameter missing");
			_nAlpha1 = Number(xmlOp.@alpha1);
			Debug.Assert(xmlOp.@alpha2, "GradientShapeImageOperation alpha2 parameter missing");
			_nAlpha2 = Number(xmlOp.@alpha2);
			Debug.Assert(xmlOp.@alpha3, "GradientShapeImageOperation alpha3 parameter missing");
			_nAlpha3 = Number(xmlOp.@alpha3);
			Debug.Assert(xmlOp.@alpha0, "GradientShapeImageOperation alpha0 parameter missing");
			_nAlpha0 = Number(xmlOp.@alpha0);
			Debug.Assert(xmlOp.@pad1, "GradientShapeImageOperation pad1 parameter missing");
			_nPad1 = Number(xmlOp.@pad1);
			Debug.Assert(xmlOp.@pad2, "GradientShapeImageOperation pad2 parameter missing");
			_nPad2 = Number(xmlOp.@pad2);
			Debug.Assert(xmlOp.@gradRotation, "GradientShapeImageOperation gradRotation parameter missing");
			_nGradRotation = Number(xmlOp.@gradRotation);
			Debug.Assert(xmlOp.@shape, "GradientShapeImageOperation shape parameter missing");
			_strShape = String(xmlOp.@shape);
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <GradientShape x={_xCenter} y={_yCenter} width={_nWidth} height={_nHeight} gradType={_strGradType} gradBlend={_strGradBlend} xOffset={_xOffset} yOffset={_yOffset} color1={_nColor1} color2={_nColor2} alpha0={_nAlpha0} alpha1={_nAlpha1} alpha2={_nAlpha2} alpha3={_nAlpha3} pad1={_nPad1} pad2={_nPad2} gradRotation={_nGradRotation} shape={_strShape} />
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return DrawGradientShape(bmdSrc);
		}

		public function DrawGradientShape(bmdOrig:BitmapData): BitmapData {
			var w:Number = isNaN(_nWidth) ? bmdOrig.width : _nWidth;
			var h:Number = isNaN(_nHeight) ? bmdOrig.height : _nHeight;
			var x:Number = isNaN(_xCenter) ? bmdOrig.width/2 : _xCenter;
			var y:Number = isNaN(_yCenter) ? bmdOrig.height/2: _yCenter;
			
			var bmdFinal:BitmapData = bmdOrig.clone();
			var shp:Shape = new Shape();
			var matrGrad:Matrix = new Matrix();
			matrGrad.createGradientBox(w,h,_nGradRotation,x - w/2+_xOffset,y-h/2+_yOffset);
			shp.graphics.beginGradientFill(
					(_strGradType.toLowerCase() == "radial") ? GradientType.RADIAL : GradientType.LINEAR,
					[_nColor1,_nColor1,_nColor1,_nColor2,_nColor2,_nColor2],
					[_nAlpha0,_nAlpha0,_nAlpha1,_nAlpha2,_nAlpha3,_nAlpha3],
					[0,255*_nPad1,255*_nPad1,255*(1-_nPad2),255*(1-_nPad2),255],
					matrGrad);
			if (_strShape.toLowerCase() == "ellipse") {
				shp.graphics.drawEllipse(x - w/2,y-h/2,w,h);
			} else {
				// default is rect
				shp.graphics.drawRect(x - w/2,y-h/2,w,h);
			}
			shp.graphics.endFill();
			
			bmdFinal.draw(shp, null, null, _strGradBlend);
			return bmdFinal;
		}
	}
}
