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
	import imagine.serialization.SerializationUtil;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class GooifyImageOperation extends BlendImageOperation {
		private static var s_shp:Shape;
		private var _aapt:Array;
		private var _nStrength:Number = 100;

		public function set lines(aapt:Array): void {
			// Copy the array of polylines in case the caller keeps messing with it
			_aapt = aapt ? aapt.slice() : null;
		}
		
		public function GooifyImageOperation(aapt:Array=null) {
			if (aapt)
				_aapt = aapt.slice();
		}
		
		public function set strength(nStrength:Number): void {
			_nStrength = nStrength;
		}
	
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			var obParams:Object = {_aapt:_aapt, _nStrength:_nStrength};
			output.writeObject(obParams);
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			var obParams:Object = input.readObject();
			_aapt = SerializationUtil.CleanSrlzReadValue(obParams._aapt);
			_nStrength = obParams._nStrength;
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			_nStrength = xmlOp.@strength;
			_aapt = new Array();
			for each (var xmlLine:XML in xmlOp.PolyLine) {
				var apt:Array = new Array();
				var strT:String = xmlLine.toString();
				Debug.Assert(strT != "", "PolyLine child text missing");
				var dec:Base64Decoder = new Base64Decoder();
				dec.decode(strT);
				var ba:ByteArray = dec.drain();
				ba.uncompress();
				for (var i:Number = 0; i < ba.length / 4; i++) {
					var x:Number = ba.readShort();
					var y:Number = ba.readShort();
					apt.push(new Point(x, y));
				}
				_aapt.push(apt);
			}
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			var xml:XML = <Gooify strength={_nStrength}/>;
			for each (var apt:Array in _aapt) {
				var xmlLine:XML = <PolyLine/>;
				var ba:ByteArray = new ByteArray();
				for (var i:Number = 0; i < apt.length; i++) {
					var pt:Point = apt[i];
					ba.writeShort(pt.x);
					ba.writeShort(pt.y);
				}
				ba.compress();
				var enc:Base64Encoder = new Base64Encoder();
				enc.encodeBytes(ba);
				xmlLine.appendChild(new XML(enc.drain()));
				xml.appendChild(xmlLine);
			}
			return xml;
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return Gooify(bmdSrc, _aapt, _nStrength);
		}
		
		/* Algorithm from Grant Skinner
		// http://www.gskinner.com/blog/archive/2006/03/source_code_ima.html
		
		// find the mouse movement:
		var dx:Number = _xmouse-tmp.oldx;
		var dy:Number = _ymouse-tmp.oldy;
		tmp = {oldx:_xmouse,oldy:_ymouse};
		
		// position the mouse and rotate according to direction of motion:
		brush._rotation = (Math.atan2(dy,dx))*180/Math.PI;
		brush._x = _xmouse;
		brush._y = _ymouse;
		
		// set up a color transform to color the brush according to direction of motion:
		var g:Number = 0x80+Math.min(0x79,Math.max(-0x80,  -dx*2  ));
		var b:Number = 0x80+Math.min(0x79,Math.max(-0x80,  -dy*2  ));
		var ct:ColorTransform = new ColorTransform(0,0,0,1,0x80,g,b,0);
		
		// draw the brush onto the displacement map:
		mapBmp.draw(brush,brush.transform.matrix,ct,"hardlight");
		
		// blur the displacement map to make the results more smooth:
		blurredMapBmp.applyFilter(mapBmp,rect,pt,blurF);
		// do displacement:
		img.filters = [dispMapF];
		*/
		public static function Gooify(bmdOrig:BitmapData, aapt:Array, nStrength:Number): BitmapData {
			var bmdTmp:BitmapData = bmdOrig.clone();
			if (!aapt)
				return bmdTmp;
				
			// Create a displacement map the size of the original. 0x808080 = neutral displacement
			var bmdDisplacement:BitmapData = VBitmapData.Construct(bmdOrig.width, bmdOrig.height, false, 0x808080);
					
			var shp:Shape = GetShape();
			
			var rcDirtyUnion:Rectangle = new Rectangle();
			for each (var apt:Array in aapt) {
				if (apt.length <= 1)
					continue;
				for (var i:Number = 0; i < apt.length - 1; i++) {
					var rcDirty:Rectangle = DrawDisplacement(bmdDisplacement, apt[i], apt[i + 1]);
					
					// Calc the bounding rectangle of affected area
					rcDirtyUnion = rcDirtyUnion.union(rcDirty);
				}
			}
			if (rcDirtyUnion.isEmpty()) {
				bmdDisplacement.dispose();
				return bmdTmp;
			}

			// Blur the displacement map to make the results more smooth
			var bmdBlurredDisplacement:BitmapData = VBitmapData.Construct(rcDirtyUnion.width, rcDirtyUnion.height,
					false, 0x808080);
			var fltBlur:BlurFilter = new BlurFilter(8, 8, 2);
			bmdBlurredDisplacement.applyFilter(bmdDisplacement, rcDirtyUnion,
					bmdBlurredDisplacement.rect.topLeft, fltBlur);
			bmdDisplacement.dispose();
					
			// Apply the blurred displacement map to the original bitmap
			var fltDisplacement:DisplacementMapFilter = new DisplacementMapFilter(bmdBlurredDisplacement,
					new Point(0, 0), BitmapDataChannel.GREEN, BitmapDataChannel.BLUE, nStrength, nStrength,
					DisplacementMapFilterMode.CLAMP);
			var bmdFinal:BitmapData = VBitmapData.Construct(rcDirtyUnion.width, rcDirtyUnion.height, true, 0x808080);
			bmdFinal.copyPixels(bmdOrig, rcDirtyUnion, new Point());
			bmdFinal.applyFilter(bmdFinal, bmdBlurredDisplacement.rect, new Point(), fltDisplacement);
			bmdBlurredDisplacement.dispose();

			// Copy the results to the returned bitmap. Intuitively one would think we could
			// avoid this step by applying the displacement filter directly to the returned
			// bitmap but I was unable to get this to work, I think because the displacement
			// filter tries to pull displacements from off the displacement bitmap when it is
			// smaller than the destination bitmap.
			bmdTmp.copyPixels(bmdFinal, bmdFinal.rect, rcDirtyUnion.topLeft);
			bmdFinal.dispose();
			return bmdTmp;
		}
		
		// Create an ellipse with a green radial gradient fading from 100 to 0% alpha.
		// The focal point of the ellipse is offset to the left as is its axis of rotation.
		private static function GetShape(): Shape {
			if (s_shp)
				return s_shp;
				
			s_shp = new Shape();
			var matGradient:Matrix = new Matrix();
			matGradient.createGradientBox(120, 100, 0, -15, -50);
			s_shp.graphics.beginGradientFill(GradientType.RADIAL,
					[ 0x00ff00, 0x00ff00, 0x00ff00 ], [ 1.0, 0.64, 0.0 ], [ 0, 64, 255 ],
					matGradient, SpreadMethod.PAD, InterpolationMethod.RGB, -0.6);
			s_shp.graphics.drawEllipse(-15, -50, 120, 100);
			s_shp.graphics.endFill();
			return s_shp;
		}
		
		public static function DrawDisplacement(bmdDisplacement:BitmapData, ptStart:Point, ptEnd:Point): Rectangle {
			var shp:Shape = GetShape();
			var mat:Matrix = new Matrix();			
			
			// Rotate according to direction of motion
			var dx:Number  = ptEnd.x - ptStart.x;
			var dy:Number  = ptEnd.y - ptStart.y;
			mat.rotate(Math.atan2(dy, dx));
			
			// Position shape at the recorded point
			mat.tx = ptEnd.x;
			mat.ty = ptEnd.y;
			
			// Set up a color transform to color the shape according to direction of motion
			var nG:Number = 0x80 + Math.min(0x79, Math.max(-0x80, -dx * 2));
			var nB:Number = 0x80 + Math.min(0x79, Math.max(-0x80, -dy * 2));
			var ct:ColorTransform = new ColorTransform(0, 0, 0, 1, 0x80, nG, nB, 0);

			// Draw the shape into the displacement map
			VBitmapData.RepairedDraw(bmdDisplacement, shp, mat, ct, BlendMode.HARDLIGHT);
			
			return new Rectangle(ptEnd.x - 150, ptEnd.y - 150, 300, 300).intersection(bmdDisplacement.rect);
		}
	}
}
