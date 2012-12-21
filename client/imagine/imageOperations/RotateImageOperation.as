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
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class RotateImageOperation extends BlendImageOperation {
		private var _radAngle:Number = 0;
		private var _fFlipH:Boolean = false;
		private var _fFlipV:Boolean = false;
		private var _fPadBorder:Boolean = false;
		private var _clrBorder:uint = 0xffffffff;
		private var _cxMax:int;
		private var _cyMax:int;
		private var _cPixelsMax:int;
		
		// Transient, not serialized
		private var _fFastApproximation:Boolean = false;
		
		public function RotateImageOperation(radAngle:Number=NaN, fFlipH:Boolean=false, fFlipV:Boolean=false,
				fFastApproximation:Boolean=false, fPadBorder:Boolean=false, clrBorder:uint=0xffffffff) {
			// ImageOperation constructors are called with no arguments during Deserialization
			if (isNaN(radAngle))
				return;
			
			_radAngle = radAngle;
			_fFlipH = fFlipH;
			_fFlipV = fFlipV;
			_fPadBorder = fPadBorder;
			_clrBorder = clrBorder;
			Debug.Assert(_radAngle < Util.krad360, "Can't rotate more than 360 degrees (" + Util.krad360 + " radians) (attempting " + _radAngle + ")");
			_fFastApproximation = fFastApproximation;
			_cxMax = Util.GetMaxImageWidth(1);
			_cyMax = Util.GetMaxImageHeight(1);
			_cPixelsMax = Util.GetMaxImagePixels();
		}
		
		public function set padBorder(fPadBorder:Boolean): void {
			_fPadBorder = fPadBorder;
		}
		
		public function get padBorder(): Boolean {
			return _fPadBorder;
		}
		
		public function set borderColor(clr:uint): void {
			_clrBorder = clr;
		}
		
		public function get borderColor(): uint {
			return _clrBorder;
		}
		
		public function set radAngle(rad:Number): void {
			_radAngle = rad;
		}
		
		public function get radAngle(): Number {
			return _radAngle;
		}
		
		public function set degAngle(deg:Number): void {
			_radAngle = Util.RadFromDeg(deg);
		}
		
		public function set flipH(f:Boolean): void {
			_fFlipH = f;
		}
		
		public function get flipH(): Boolean {
			return _fFlipH;
		}
		
		public function set flipV(f:Boolean): void {
			_fFlipV = f;
		}
		
		public function get flipV(): Boolean {
			return _fFlipV;
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
			'padBorder', 'borderColor', 'radAngle', 'flipH',
			'flipV', 'maxImageWidth', 'maxImageHeight', 'maxPixels']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@angle, "RotateImageOperation angle argument missing");
			var strAngle:String = xmlOp.@angle;
			_radAngle = Number(strAngle);
			Debug.Assert(_radAngle < Util.krad360, "Can't rotate more than 360 degrees (" + Util.krad360 + " radians) (attempting " + _radAngle + ")");
			_fFlipH = (xmlOp.@flipH && xmlOp.@flipH == "true");
			_fFlipV = (xmlOp.@flipV && xmlOp.@flipV == "true");
			_fPadBorder = (xmlOp.@padBorder && xmlOp.@padBorder == "true");
			_clrBorder = xmlOp.@borderColor ? Number(xmlOp.@borderColor) : 0xffffffff;
			
			Debug.Assert(xmlOp.hasOwnProperty("@maxWidth"), "RotateImageOperation maxWidth argument missing");
			_cxMax = Number(xmlOp.@maxWidth);
			_cyMax = Number(xmlOp.@maxHeight);
			_cPixelsMax = Number(xmlOp.@maxPixels);
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Rotate angle={_radAngle} flipH={_fFlipH} flipV={_fFlipV} padBorder={_fPadBorder} borderColor={_clrBorder}
					maxWidth={_cxMax} maxHeight={_cyMax} maxPixels={_cPixelsMax}/>;
		}
		
		override public function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return Rotate(imgd, bmdSrc, fDoObjects, _radAngle, _fFlipH, _fFlipV, _fPadBorder, _clrBorder, !_fFastApproximation,
					_cxMax, _cyMax, _cPixelsMax);
		}
		
		// Take a crop rect (defined by a point, from the origin)
		// Take a point to rotate (around the origin), and a rotation angle.
		// Rotate the point, then calculate the scale factor required to bring the point back within the crop rect.
		// Return said scale factor
		private static function GetRotationCropMult(ptCrop:Point, ptToRotate:Point, radAngle:Number): Number {
			var matRotDim:Matrix = new Matrix();
			matRotDim.rotate(radAngle);
			var ptRotated:Point = matRotDim.transformPoint(ptToRotate);
			return  Math.min(Math.abs(Util.SafeDivide(ptCrop.x,ptRotated.x)),
					Math.abs(Util.SafeDivide(ptCrop.y, ptRotated.y)),
					1);
		}

		// Draw the old BitmapData into the new VBitmapData through a rotate transform
		private static function Rotate(imgd:ImageDocument, bmdOrig:BitmapData, fDoObjects:Boolean,
				radAngle:Number, fFlipH:Boolean, fFlipV:Boolean, fPadBorder:Boolean, clrBorder:uint,
				fSmooth:Boolean, cxMax:int, cyMax:int, cPixelsMax:int): BitmapData {
			var ptNearest90Dim:Point;
			var fRotated90:Boolean = ((Math.round(radAngle / Util.krad90)) % 2) != 0;
			if (fRotated90)
				ptNearest90Dim = new Point(bmdOrig.height, bmdOrig.width); // for rotated, swap width and height
			else
				ptNearest90Dim = new Point(bmdOrig.width, bmdOrig.height); // keep same width and height
						
			var ptDim:Point; // Our new image dimension
			
			var nScaleFactor:Number = 1; // Less than one means we will shrink to fit in the resolution limit

			if (Util.IsCloseTo90(radAngle)) {
				ptDim = ptNearest90Dim;
			} else {
				if (fPadBorder) {
					var cxW:Number = bmdOrig.width;
					var cyH:Number = bmdOrig.height;
					var ptRot:Point = Util.GetRotatedImageDims( cxW, cyH, radAngle );
					
					ptDim = Util.GetLimitedImageSize(ptRot.x, ptRot.y, cxMax, cyMax, cPixelsMax);
					nScaleFactor = ptDim.x / ptRot.x;
				} else {
					// Funky math to calcuate smaller inner rect for non-90 degree rotations
					// ptNearest90Dim is our desired aspect ratio, ptCrop is our original image width/height
					var ptCrop:Point = new Point(bmdOrig.width, bmdOrig.height);
					// Calculate the scale reduction factor based on rotating two adjacent corners
					// and scaling them to fit inside our crop rect
					var mult:Number = Math.min(GetRotationCropMult(ptCrop, ptNearest90Dim, radAngle),
							GetRotationCropMult(ptCrop, new Point(ptNearest90Dim.x, -ptNearest90Dim.y), radAngle));
					ptDim = new Point(ptNearest90Dim.x * mult, ptNearest90Dim.y * mult);
				}
			}
			
			var bmdNew:BitmapData = VBitmapData.Construct(Math.abs(ptDim.x), Math.abs(ptDim.y), true, clrBorder);
			if (!bmdNew)
				return null;
			
			// Rotate the image around its midpoint by translating its midpoint to 0, 0,
			// performing the rotation, then translating it back.
			var mat:Matrix = new Matrix();
			mat.translate(-(bmdOrig.width / 2), -(bmdOrig.height / 2));
			var xScale:Number = nScaleFactor;
			var yScale:Number = nScaleFactor;
			if (fFlipH) xScale *= -1;
			if (fFlipV) yScale *= -1;
			mat.rotate(radAngle);
			mat.scale(xScale,yScale);
			mat.translate(bmdNew.width / 2, bmdNew.height / 2);
			bmdNew.draw(bmdOrig, mat, null, null, null, fSmooth);

			// Rotate all the DocumentObjects too
			if (fDoObjects) {
				for (var i:Number = 0; i < imgd.numChildren; i++) {
					var dob:DisplayObject = imgd.getChildAt(i);
					var ptRotated:Point = mat.transformPoint(new Point(dob.x, dob.y));
					var dctProperties:Object = {
						rotation: (Util.DegFromRad(radAngle) + dob.rotation) % 360,
						x: ptRotated.x,
						y: ptRotated.y
					}
					if (fFlipH)
						dctProperties.scaleX = -dob.scaleX;
					if (fFlipV)
						dctProperties.scaleY = -dob.scaleY;
					var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(dob.name, dctProperties);
					spop.Do(imgd);
				}
			}
			return bmdNew;
		}
	}
}
