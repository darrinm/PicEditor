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
package util {
	import flash.display.BitmapData;
	import errors.InvalidBitmapError;
	import imagine.ImageDocument;
	
	public class BitmapCacheEntry { // bce
		protected var _strParams:String;
		protected var _bmdSrc:BitmapData;
		protected var _bmdResult:BitmapData;
		
		public var data:Object; // Extra data to be used by the consumer
		
		public function matches(strParams:String, bmdSrc:BitmapData): Boolean {
			return (_bmdResult != null) && (strParams == _strParams) && (bmdSrc == _bmdSrc);
		}
		
		public function BitmapCacheEntry(strParams:String, bmdSrc:BitmapData, bmdResult:BitmapData, obData:Object) {
			if (_bmdResult && _bmdResult != _bmdSrc) {
				if (ImageDocument.IsBackground(bmdResult))
					throw new InvalidBitmapError( InvalidBitmapError.ERROR_IS_BACKGROUND );
				if (ImageDocument.IsComposite(bmdResult))
					throw new InvalidBitmapError( InvalidBitmapError.ERROR_IS_COMPOSITE );
			}
			_strParams = strParams;
			_bmdSrc = bmdSrc;
			_bmdResult = bmdResult;
			data = obData;
		}
		
		public function get result(): BitmapData {
			return _bmdResult;
		}
		
		public function toString(): String {
			return "BitmapCacheEntry[src = " + _bmdSrc + ", result = " + _bmdResult + "]";
		}
		
		public function Dispose(): void {
			
			if (_bmdResult && _bmdResult != _bmdSrc) {
				try {
					VBitmapData.SafeDispose(_bmdResult);
					// Don't dispose if the source and target are the same - we don't own the target
				} catch (e:InvalidBitmapError) {
					if (e.type == InvalidBitmapError.ERROR_IS_BACKGROUND ||
						e.type == InvalidBitmapError.ERROR_IS_COMPOSITE ||
						e.type == InvalidBitmapError.ERROR_IS_KEYFRAME ) {
						throw(e);
					}
					// Ignore other errors - duplicated cached bitmaps can be double disposed - this is OK
				}
			}
			_bmdResult = null;
			_bmdSrc = null;
		}
	}
}
