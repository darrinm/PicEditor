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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class BitmapImageMask extends ImageMask
	{
		protected var _bmdMask:BitmapData;
		
		public function BitmapImageMask(bmdMask:BitmapData = null, rcBounds:Rectangle = null) {
			super(rcBounds);
			_bmdMask = bmdMask;
		}
		
		public override function Serialize(): XML {
			var xml:XML = super.Serialize();
			xml.appendChild(SerializeAlphaMask());
			return xml;
		}
		
		private function SerializeAlphaMask(): XML {
			var baMaskBytes:ByteArray = _bmdMask.getPixels(_bmdMask.rect);
			baMaskBytes.compress();
			var enc:Base64Encoder = new Base64Encoder();
			enc.encodeBytes(baMaskBytes);
			return new XML(enc.drain());
		}

		override public function writeExternal(output:IDataOutput):void {
			super.writeExternal(output);
			var baMaskBytes:ByteArray = _bmdMask.getPixels(_bmdMask.rect);
			baMaskBytes.compress();
			var obMask:Object = {};
			obMask.bitmapBytes = baMaskBytes;
			output.writeObject(obMask);
		}
		
		override public function readExternal(input:IDataInput):void {
			super.readExternal(input);
			var obMask:Object = input.readObject();
			var baMaskBytes:ByteArray = obMask.bitmapBytes;
			baMaskBytes.uncompress();
			_bmdMask = VBitmapData.Construct(_rcBounds.width, _rcBounds.height, true);
			_bmdMask.setPixels(_bmdMask.rect, baMaskBytes);
		}

		public override function Deserialize(xml:XML): Boolean {
			var fSuccess:Boolean = super.Deserialize(xml);
			if (fSuccess) {
				fSuccess = DeserializeAlphaMask(xml);
			}
			return fSuccess;
		}
		
		private function DeserializeAlphaMask(xmlOp:XML): Boolean {
			var strT:String = xmlOp.toString();
			Debug.Assert(strT != "", "ImageMask child text missing");
			var dec:Base64Decoder = new Base64Decoder();
			dec.decode(strT);
			var baMaskBytes:ByteArray = dec.drain();
			baMaskBytes.uncompress();
			_bmdMask = VBitmapData.Construct(_rcBounds.width, _rcBounds.height, true);
			_bmdMask.setPixels(_bmdMask.rect, baMaskBytes);
			return true;
		}
		
		public override function Mask(bmdOrig:BitmapData): BitmapData {
			return _bmdMask;
		}

		public function setMask(bmdMask:BitmapData): void {
			if (_bmdMask) {
				_bmdMask.dispose();
			}
			_bmdMask = bmdMask;
		}
		
		public override function Dispose(): void {
			if (_bmdMask) {
				_bmdMask.dispose();
			}
		}
		
	}
}