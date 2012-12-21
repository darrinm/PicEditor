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
package {
	import flash.display.Sprite;
	import flash.utils.ByteArray;
	import hurlant.jpeg.as3_jpeg_wrapper;

	public class AlchemyLib extends Sprite {
		public function AlchemyLib() {
		}
		
		// UNDONE: use of this global presumes that JPEGEncode is not called re-entrantly
		private var _fnEncodeCallback:Function;
		private var _ibData:uint = 0;
		
		public function JPEGEncode(baImage:ByteArray, cx:int, cy:int, nQuality:int, aobSegments:Array, nChromaSubsampling:int, fnCallback:Function): ByteArray {
//			trace("a AlchemyLib.JPEGEncode " + cx + "x" + cy + ", quality: " + nQuality + ", segments: " + (aobSegments ? aobSegments.length : 0));
			_fnEncodeCallback = fnCallback;
			
			// It'd be cleaner to just pass baImage into encode_jpeg and let it pull out
			// the data but doing so results in a baImage-sized memory leak. Seems Alchemy
			// holds a reference to it. An explicit AS3_Release(baImage) had no effect.
			if (_ibData != 0) throw new Error("ibData != 0");
			_ibData = as3_jpeg_wrapper.alloc(baImage.length);
			baImage.position = 0;
			baImage.readBytes(as3_jpeg_wrapper.ram, _ibData, baImage.length);
			
			if (fnCallback != null) {
				// Using 'async' makes Alchemy add a Function parameter to the head of the argument list that
				// is called when the function returns.
				as3_jpeg_wrapper.encode_jpeg_async(encode_jpeg_complete, _ibData, cx, cy, 3, 2, nQuality,
						aobSegments, nChromaSubsampling, OnEncodeCallback);
			} else {
				var baJPEG:ByteArray = as3_jpeg_wrapper.encode_jpeg_sync(_ibData, cx, cy, 3, 2, nQuality,
						aobSegments, nChromaSubsampling);
				as3_jpeg_wrapper.free(_ibData);
				_ibData = 0;
				return baJPEG;
			}
			return null;
		}
			
		private function encode_jpeg_complete(...aobArgs): void {
			// NOTE: aobArgs.length is always 1 and the first value in the array is undefined
//			trace("encode_jpeg_complete: " + (aobArgs != null ? aobArgs.length + " args" : "no args"));
			as3_jpeg_wrapper.free(_ibData);
			_ibData = 0;
		}
		
		private function OnEncodeCallback(nPercent:int, baData:ByteArray): Boolean {
			return _fnEncodeCallback(nPercent, baData);
		}
	}
}
