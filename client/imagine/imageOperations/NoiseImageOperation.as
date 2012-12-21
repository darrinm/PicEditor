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
// The NoiseImageOperation wraps exactly the parameters and functionality of the BitmapData.noise() method

package imagine.imageOperations {
	import flash.display.BitmapData;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class NoiseImageOperation extends BlendImageOperation {
		private var _nRandomSeed:int;
		private var _nLow:uint;
		private var _nHigh:uint;
		private var _nChannelOptions:uint;
		private var _fGrayScale:Boolean;
		
		public function set randomSeed(nRandomSeed:int): void {
			_nRandomSeed = nRandomSeed;
		}
		
		public function get randomSeed(): int {
			return _nRandomSeed;
		}
		
		public function set low(nLow:int): void {
			_nLow = nLow;
		}
		
		public function get low(): int {
			return _nLow;
		}
		
		public function set high(nHigh:int): void {
			_nHigh = nHigh;
		}
		
		public function get high(): int {
			return _nHigh;
		}
		
		public function set channelOptions(nChannelOptions:uint): void {
			_nChannelOptions = nChannelOptions;
		}
		
		public function get channelOptions(): uint {
			return _nChannelOptions;
		}
		
		public function set grayScale(fGrayScale:Boolean): void {
			_fGrayScale = fGrayScale;
		}
		
		public function get grayScale(): Boolean {
			return _fGrayScale;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['randomSeed', 'low', 'high', 'channelOptions', 'grayScale']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		public function NoiseImageOperation(nRandomSeed:int=0, nLow:int=0, nHigh:int=255,
				nChannelOptions:uint=7 /* RGB */, fGrayScale:Boolean=false) {
			_nRandomSeed = nRandomSeed;
			_nLow = nLow;
			_nHigh = nHigh;
			_nChannelOptions = nChannelOptions;
			_fGrayScale = fGrayScale;
		}
	
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@randomSeed, "NoiseImageOperation randomSeed parameter missing");
			_nRandomSeed = int(xmlOp.@randomSeed);
			Debug.Assert(xmlOp.@low, "NoiseImageOperation low parameter missing");
			_nLow = int(xmlOp.@low);
			Debug.Assert(xmlOp.@high, "NoiseImageOperation high parameter missing");
			_nHigh= int(xmlOp.@high);
			Debug.Assert(xmlOp.@channelOptions, "NoiseImageOperation channelOptions parameter missing");
			_nChannelOptions = uint(xmlOp.@channelOptions);
			Debug.Assert(xmlOp.@grayScale, "NoiseImageOperation grayScale parameter missing");
			_fGrayScale = xmlOp.@grayScale && xmlOp.@grayScale == "true";
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Noise randomSeed={_nRandomSeed} low={_nLow} high={_nHigh}
					channelOptions={_nChannelOptions} grayScale={_fGrayScale}/>
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			var bmdNew:BitmapData = VBitmapData.Construct(bmdSrc.width, bmdSrc.height, true, NaN);
			bmdNew.noise(_nRandomSeed, _nLow, _nHigh, _nChannelOptions, _fGrayScale);
			return bmdNew;
		}
	}
}
