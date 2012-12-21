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
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	[RemoteClass]
	public class RadialBlurImageOperation extends BlendImageOperation {
		private var _xCenter:Number;
		private var _yCenter:Number;
		private var _nAmount:Number;
		

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
		
		public function set amount(amount:Number): void {
			_nAmount = Math.floor(amount);
		}		
		
		public function get amount(): Number {
			return _nAmount;
		}		
		
		private static const knMaxBlur:Number = 255;
		private static const knMaxQuality:Number = 15;
		
		public function RadialBlurImageOperation(x:Number=NaN, y:Number=NaN, amount:Number=NaN) {
			_xCenter = x;
			_yCenter = y;
			_nAmount = amount;
		}
	
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['x', 'y', 'amount']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
//			if (xmlOp.@alpha.toString().length > 0) _nAlpha = Number(xmlOp.@alpha);
			Debug.Assert(xmlOp.@x, "BlurImageOperation x parameter missing");
			_xCenter = Number(xmlOp.@x);
			Debug.Assert(xmlOp.@y, "BlurImageOperation y parameter missing");
			_yCenter = Number(xmlOp.@y);
			Debug.Assert(xmlOp.@amount, "BlurImageOperation amount parameter missing");
			_nAmount = Number(xmlOp.@amount);			
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <RadialBlur x={_xCenter} y={_yCenter} amount={_nAmount} />
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return RadialBlur(bmdSrc, _xCenter, _yCenter, _nAmount);
		}
		
		public static function RadialBlur(bmdOrig:BitmapData, x:Number, y:Number, amount:Number):BitmapData {

			var bmdOut:BitmapData = bmdOrig.clone();	
			
			// this value determines the amount of blur.  The bigger it is,
			// the bigger the effect.  But if it's too big, then you start
			// to see the gaps between each step.		
			var nMaxBlur:int = bmdOrig.width * amount/200;
			
			// this value determines the number of iterations in the effect.
			// Because each image is alpha'd on top of the previous, there's
			// no point in doing more than 20 steps.  Anything more than that
			// isn't noticeable.
			var nSteps:int = 5 + amount;
			if (nSteps > 30) nSteps = 30;
					
			// The alpha multiplier determines how rapidly the image trail
			// fades away.  Experiment to find a good value.
			var ctrns:ColorTransform = new ColorTransform();
			ctrns.alphaMultiplier = 0.15;
			
			for( var i:int = nSteps; i > 0; i-- ) {
				var nStep:Number = i * nMaxBlur / nSteps;
				var nSizeX:Number = bmdOrig.width + nStep;
				var nSizeY:Number = bmdOrig.height + nStep;
				var nScaleX:Number = nSizeX / bmdOrig.width;
				var nScaleY:Number = nSizeY / bmdOrig.height;
				var offsetX:Number = ( nSizeX - bmdOrig.width ) * (bmdOrig.width - x) / bmdOrig.width;
				var offsetY:Number = ( nSizeY - bmdOrig.height ) * (bmdOrig.height-y) / bmdOrig.height;
								
				var mat:Matrix = new Matrix();
				mat.scale(nScaleX, nScaleY);
				mat.tx = offsetX - nStep;
				mat.ty = offsetY - nStep;
				
				bmdOut.draw(bmdOrig, mat, ctrns);
			}		
			return bmdOut;
		}
	}
}
