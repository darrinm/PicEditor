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
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class TiltShiftBlurImageOperation extends BlendImageOperation {
		private var _nSize:Number;
		private var _nPosition:Number;
		private var _nRotation:Number;
		
		public function set size(nSize:Number): void {
			_nSize = nSize;
		}
		
		public function get size(): Number {
			return _nSize;
		}
		
		public function set position(nPosition:Number): void {
			_nPosition = nPosition;
		}
		
		public function get position(): Number {
			return _nPosition;
		}
		
		public function set rotation(nRotation:Number): void {
			_nRotation = nRotation;
		}
		
		public function get rotation(): Number {
			return _nRotation;
		}
		
		public function TiltShiftBlurImageOperation(nSize:Number=50, nPosition:Number=50, nRotation:Number=0) {
			_nSize = nSize;
			_nPosition = nPosition;
			_nRotation = nRotation;
		}
	
		private static var _srzinfo:SerializationInfo = new SerializationInfo([
			'size', 'position', 'rotation']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@size, "TiltShiftBlurImageOperation size parameter missing");
			_nSize = Number(xmlOp.@size);
			Debug.Assert(xmlOp.@position, "TiltShiftBlurImageOperation position parameter missing");
			_nPosition = Number(xmlOp.@position);
			Debug.Assert(xmlOp.@rotation, "TiltShiftBlurImageOperation rotation parameter missing");
			_nRotation = Number(xmlOp.@rotation);
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Blur size={_nSize} position={_nPosition} rotation={_nRotation}/>
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return Blur(bmdSrc, _nSize, _nPosition, _nRotation);
		}
		
		public static function Blur(bmdOrig:BitmapData, nSize:Number, nPosition:Number, nRotation:Number):BitmapData {
			var alphaMask:BitmapData = null;
			var mask:Sprite = new Sprite();
			var m:Matrix = new Matrix();
			var bmdTemp:BitmapData = bmdOrig.clone();
			nPosition += nSize/2;

			bmdTemp.applyFilter(bmdTemp, bmdTemp.rect, bmdTemp.rect.topLeft, new BlurFilter(5, 5, 3));
			
			m.createGradientBox(bmdTemp.width, bmdTemp.height * (nSize / 100), (nRotation + 90) / (180 / Math.PI), 0, bmdTemp.height * ((nPosition - nSize) / 100));
			mask.graphics.beginGradientFill("linear", new Array(0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF), new Array(0, 1, 1, 0), new Array(0, 85, 170, 255), m);
			mask.graphics.drawRect(0, 0, bmdTemp.width, bmdTemp.height);
			alphaMask = VBitmapData.Construct(bmdTemp.width, bmdTemp.height, true, 0xFFFFFF);
			alphaMask.draw(mask);
			
			bmdTemp.copyPixels(bmdOrig, bmdOrig.rect, bmdOrig.rect.topLeft, alphaMask, alphaMask.rect.topLeft, true);
			
			return bmdTemp;
		}
	}
}
