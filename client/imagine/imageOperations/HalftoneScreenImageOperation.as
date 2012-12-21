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
	import flash.geom.Point;
		
	import imagine.ImageDocument;
	
	[RemoteClass]
	public class HalftoneScreenImageOperation extends NestedImageOperation {
		
		protected var _radAngle:Number = 0;
		protected var _dotSize:Number = 1;
		protected var _strChannel:String = "C";
		protected var _width:Number = 1024;
		protected var _height:Number = 1024;

		protected var _opRotate1:RotateImageOperation;
		protected var _opPixelate:PixelateImageOperation;
		protected var _opColorMatrix:ColorMatrixImageOperation;
		protected var _opRotate2:RotateImageOperation;
		protected var _opCrop:CropImageOperation;
		protected var _tileMask:TiledImageMask = null;
		protected var _opScaleDown:ResizeImageOperation;
		protected var _opScaleUp:ResizeImageOperation;

		public function set radAngle(a:Number): void {
			_radAngle = a;
			updateChildren();
		}

		public function set degAngle(a:Number): void {
			radAngle = Util.RadFromDeg(a);			
			updateChildren();
		}

		public function set channel(c:String): void {
			_strChannel = c;
			updateChildren();
		}
		
		public function set dotSize(s:Number): void {
			_dotSize = s;
			updateChildren();
		}

		public function set width(w:Number): void {
			_width = w;
			updateChildren();
		}
		
		public function set height(h:Number): void {
			_height = h;
			updateChildren();
		}		
		
		public function HalftoneScreenImageOperation() {
		}		
		
		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			updateChildren();
			return super.ApplyEffect( imgd, bmdSrc, fDoObjects, fUseCache );			
		}		
		
		
		private function updateChildren(): void {
			if (_aopChildren.length == 0)
				buildChildren();

			var cxMax:Number = Util.GetMaxImageWidth(1);
			var cyMax:Number = Util.GetMaxImageHeight(1);
			var cPixelsMax:Number = Util.GetMaxImagePixels();			
			
			var cxyRotated:Point = Util.GetRotatedImageDims( _width, _height, _radAngle);
			var cxyRotatedLimit:Point = Util.GetLimitedImageSize(cxyRotated.x, cxyRotated.y, cxMax, cyMax, cPixelsMax);
			 		
			var cxyDoubleRotated:Point = Util.GetRotatedImageDims( cxyRotated.x, cxyRotated.y, -1 * _radAngle);
			var cxyDoubleRotatedLimit:Point = Util.GetLimitedImageSize(cxyDoubleRotated.x, cxyDoubleRotated.y, cxMax, cyMax, cPixelsMax);
			
			var nScale:Number = (cxyRotatedLimit.x / cxyRotated.x) * (cxyDoubleRotatedLimit.x / cxyDoubleRotated.x);
			if (nScale == 0) nScale = 1;
			
			_opScaleDown.width = _width * nScale;
			_opScaleDown.height = _height * nScale;
			
			_opRotate1.radAngle = _radAngle;			
			_opPixelate.pixelWidth = _dotSize;
			_opPixelate.pixelHeight = _dotSize;
			
			if (_strChannel == "C")
				_opColorMatrix.Matrix = [1,0,0,0,0, 0,0,0,0,255, 0,0,0,0,255, 0,0,0,1,0];				
			if (_strChannel == "M")
				_opColorMatrix.Matrix = [0,0,0,0,255, 0,1,0,0,0, 0,0,0,0,255, 0,0,0,1,0];				
			if (_strChannel == "Y")
				_opColorMatrix.Matrix = [0,0,0,0,255, 0,0,0,0,255, 0,0,1,0,0, 0,0,0,1,0];				
			
			_tileMask.tileWidth = _dotSize;
			_tileMask.tileHeight = _dotSize;
			_tileMask.scaleWidth = 1.4;
			_tileMask.scaleHeight = 1.4;
			_tileMask.width = cxyRotated.x * nScale;
			_tileMask.height = cxyRotated.y * nScale;

			_opRotate2.radAngle = -1 * _radAngle;			


			_opCrop.x = (cxyDoubleRotated.x - _width) / 2  * nScale;
			_opCrop.y = (cxyDoubleRotated.y - _height) / 2  * nScale;
			_opCrop.width = _width * nScale;			
			_opCrop.height = _height * nScale;			
			_opScaleUp.width = _width;				
			_opScaleUp.height = _height;				

		}
				
		private function buildChildren(): void {
			_aopChildren.length = 0;
			
			// NOTE: the parameters for the individual operations are properly calculated
			// and set in updateChildren(), above.
			
			// scale down to a smaller size. This might be necessary if the rotated screen would be
			// larger than our maximum image size.
			_opScaleDown = new ResizeImageOperation( 1024, 1024 );
			push( _opScaleDown );
			
			// rotate, pixelate, color channel
			_opRotate1 = new RotateImageOperation( 0, false, false, false, true );
			push( _opRotate1 );
			_opPixelate = new PixelateImageOperation( 10, 10 );
			push( _opPixelate );
			
			_opColorMatrix = new ColorMatrixImageOperation( [1,0,0,0,0, 0,0,0,0,255, 0,0,0,0,255, 0,0,0,1,0] );
			push( _opColorMatrix );				

			// save the modified version			
			push( new imagine.imageOperations.SetVar("halftonescreen_screened") );

			// set to white
			var opWhite:ColorMatrixImageOperation = new ColorMatrixImageOperation( [0,0,0,0,255, 0,0,0,0,255, 0,0,0,0,255, 0,0,0,0,255] );
			opWhite.UseAlpha = false;
			push( opWhite );

			// prepare a mask to use for the screening operation
			var cxyRotated:Point = Util.GetRotatedImageDims( _width, _height, _radAngle);		
			
			if (!_tileMask)			
				_tileMask = new TiledImageMask();

			_tileMask.tileWidth = 10;
			_tileMask.tileHeight = 10;
			_tileMask.scaleWidth = 1.4;
			_tileMask.scaleHeight = 1.4;
			_tileMask.width = 1024;
			_tileMask.height = 1024;

			// get the modified image through our screen
			var opGet:GetVarImageOperation = new GetVarImageOperation("halftonescreen_screened");
			opGet.Mask = _tileMask;
			push( opGet );
			
			// rotate back again
			_opRotate2 = new RotateImageOperation( 0, false, false, false, true );
			push( _opRotate2 );
			
			// crop
			_opCrop = new CropImageOperation( 0, 0, 1024, 1024 );
			push( _opCrop );
			
			// scale back up again
			_opScaleUp = new ResizeImageOperation( 1024, 1024 );
			push( _opScaleUp );
			
		}
		
	}
}
