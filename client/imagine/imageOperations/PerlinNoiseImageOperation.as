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
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class PerlinNoiseImageOperation extends BlendImageOperation {
		private var _nBaseX:Number;
		private var _nBaseY:Number;
		private var _cOctaves:uint;
		private var _nRandomSeed:Number;
		private var _fStitch:Boolean;
		private var _fFractalNoise:Boolean;
		private var _nChannelOptions:uint;
		private var _fGrayScale:Boolean;
		
		public function PerlinNoiseImageOperation(nBaseX:Number=NaN, nBaseY:Number=NaN, cOctaves:uint=0,
				nRandomSeed:int=0, fStitch:Boolean=false, fFractalNoise:Boolean=false, nChannelOptions:uint=0,
				fGrayScale:Boolean=false) {
			// ImageOperation constructors are called with no arguments during Deserialization
			if (isNaN(nBaseX))
				return;
			
			_nBaseX = nBaseX;
// UNDONE: validaton
//			Debug.Assert(_nSharpness >= 0 && _nSharpness <= 100, "Sharpness value must 0 <= n <= 100 (attempting " + _nSharpness + ")");
			_nBaseY = nBaseY;
			_cOctaves = cOctaves;
			_nRandomSeed = nRandomSeed;
			_fStitch = fStitch;
			_fFractalNoise = fFractalNoise;
			_nChannelOptions = nChannelOptions;
			_fGrayScale = fGrayScale;
		}
						
		public function set grayScale(fGrayScale:Boolean): void {
			_fGrayScale = fGrayScale;
		}
		
		public function get grayScale(): Boolean {
			return _fGrayScale;
		}
		
		public function set fractalNoise(fFractalNoise:Boolean): void {
			_fFractalNoise = fFractalNoise;
		}
		
		public function get fractalNoise():Boolean {
			return _fFractalNoise;
		}
		
		public function set stitch(fStitch:Boolean): void {
			_fStitch = fStitch;
		}		
		
		public function get stitch(): Boolean {
			return _fStitch;
		}		
		
		public function set randomSeed(n:Number): void {
			_nRandomSeed = n;
		}
		
		public function get randomSeed(): Number {
			return _nRandomSeed;
		}
		
		public function set channelOptions(n:Number): void {
			_nChannelOptions = n;
		}
		
		public function get channelOptions():Number {
			return _nChannelOptions;
		}
		
		public function set octaves(n:int): void {
			_cOctaves = n;
		}
		
		public function get octaves():int {
			return _cOctaves;
		}
		
		public function set baseX(n:Number): void {
			_nBaseX = n;
		}
		
		public function get baseX(): Number {
			return _nBaseX;
		}
		
		public function set baseY(n:Number): void {
			_nBaseY = n;
		}
		
		public function get baseY(): Number {
			return _nBaseY;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['baseX', 'baseY', 'octaves', 'randomSeed', 'stitch', 'grayScale', 'channelOptions', 'fractalNoise']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@baseX, "PerlinNoiseImageOperation baseX argument missing");
			_nBaseX = Number(xmlOp.@baseX);
// UNDONE: validation
//			Debug.Assert(_nSharpness >= 0 && _nSharpness <= 100, "Sharpness value must 0 <= n <= 100 (attempting " + _nSharpness + ")");
			Debug.Assert(xmlOp.@baseY, "PerlinNoiseImageOperation baseY argument missing");
			_nBaseY = Number(xmlOp.@baseY);
			Debug.Assert(xmlOp.@octaveCount, "PerlinNoiseImageOperation octaveCount argument missing");
			_cOctaves= uint(xmlOp.@octaveCount);
			Debug.Assert(xmlOp.@randomSeed, "PerlinNoiseImageOperation randomSeed argument missing");
			_nRandomSeed = Number(xmlOp.@randomSeed);
			Debug.Assert(xmlOp.@stitch, "PerlinNoiseImageOperation stitch argument missing");
			_fStitch = xmlOp.@stitch == "true";
			Debug.Assert(xmlOp.@grayscale, "PerlinNoiseImageOperation grayscale argument missing");
			_fGrayScale = xmlOp.@grayscale == "true";
			Debug.Assert(xmlOp.@channelOptions, "PerlinNoiseImageOperation channelOptions argument missing");
			_nChannelOptions = uint(xmlOp.@channelOptions);
			Debug.Assert(xmlOp.@fractalNoise, "PerlinNoiseImageOperation fractalNoise argument missing");
			_fFractalNoise = xmlOp.@fractalNoise == "true";
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <PerlinNoise baseX={_nBaseX} baseY={_nBaseY} octaveCount={_cOctaves}
					randomSeed={_nRandomSeed} stitch={_fStitch} grayscale={_fGrayScale}
					channelOptions={_nChannelOptions} fractalNoise={_fFractalNoise}/>
		}
		
		override public function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return PerlinNoise(bmdSrc, _nBaseX, _nBaseY, _cOctaves, _nRandomSeed,
					_fStitch, _fFractalNoise, _nChannelOptions, _fGrayScale);
		}
		
		private static function PerlinNoise(bmdOrig:BitmapData, nBaseX:Number, nBaseY:Number,
				cOctaves:uint, nRandomSeed:Number, fStitch:Boolean, fFractalNoise:Boolean,
				nChannelOptions:uint, fGrayScale:Boolean): BitmapData {
			var bmdPerlin:BitmapData = VBitmapData.Construct(bmdOrig.width, bmdOrig.height, true, NaN);
			var bmdNew:BitmapData = bmdOrig.clone();
			if (!bmdNew)
				return null;
			
			bmdPerlin.perlinNoise(nBaseX, nBaseY, cOctaves, nRandomSeed, fStitch, fFractalNoise,
					nChannelOptions, fGrayScale);
			bmdNew.draw(bmdPerlin);
			return bmdNew;
		}
	}
}
