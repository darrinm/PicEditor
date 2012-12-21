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
package imagine.imageOperations.engine
{
	/** BitmapReferenceData
	 * This is a wrapper for a bitmap class
	 * There should be one (and only one) of these for each bitmap for which we do ref counting
	 * All references to the same bitmap point to the same BitmapReferenceData
	 * This class is responsible for the reference counting and disposing when the last
	 * reference disappears
	 * It should also be responsible, when possible, for creating, duplicating, etc.
	 */
	import flash.display.BitmapData;
	import flash.utils.Dictionary;
	
	import util.VBitmapData;
	
	public class BitmapReferenceData
	{
		public var _fExternal:Boolean;
		public var _bmd:BitmapData;
		public var _cReferences:Number;
		private var _fDisposed:Boolean = false;
		
		private var _dctReferences:Dictionary = new Dictionary();
		private static var _dctMapBitmapToRefBitmap:Dictionary = new Dictionary();
		
		public static function GetDebugInfo(bmd:BitmapData): String {
			if (bmd == null)
				return "null bitmap";
			if (!(Util.InDict(bmd, _dctMapBitmapToRefBitmap)))
				return "unreferenced";
			var bmdrd:BitmapReferenceData = _dctMapBitmapToRefBitmap[bmd];
			return bmdrd.DebugInfo();
		}
	
		public static function TakeOwnership(bmd:BitmapData): BitmapReferenceData {
			if (Util.InDict(bmd, _dctMapBitmapToRefBitmap))
				return _dctMapBitmapToRefBitmap[bmd];
			return new BitmapReferenceData(bmd, false);
		}

		public static function NewExternal(bmd:BitmapData): BitmapReferenceData {
			return new BitmapReferenceData(bmd, true);
		}
		
		public static function New(strUse:String, nWidth:Number=NaN, nHeight:Number=NaN,
				fTransparent:Boolean=true, nFillColor:uint=0xFFFFFFFF): BitmapReferenceData {
			return TakeOwnership(VBitmapData.Construct(nWidth, nHeight, fTransparent, nFillColor, strUse));
		}
		
		public function DebugInfo(): String {
			var str:String = this.toString();
			for each (var bmdr:BitmapReference in _dctReferences) {
				str += "\n  - ref: " + bmdr.user;
			}
			return str;
		}

		public function BitmapReferenceData(bmd:BitmapData, fExternal:Boolean)
		{
			if (Util.InDict(_bmd, _dctMapBitmapToRefBitmap))
				throw new Error("Duplicate bitmap reference");
				
			_bmd = bmd;
			_fExternal = fExternal;
			_fDisposed = false;
			_cReferences = 0; // No one is referencing us yet.
			
			if (!_fExternal) {
				if (_bmd is VBitmapData)
					VBitmapData(_bmd)._fReferenced = true;
				VBitmapData.OnBitmapRefCreated(_bmd);
				_dctMapBitmapToRefBitmap[_bmd] = this;
			}
		}
		
		public function Validate(): void {
			try {
				if (_fExternal) {
					if (Util.InDict(_bmd, _dctMapBitmapToRefBitmap))
						throw new Error("external bitmap in bitmap map");
				} else {
					// Not external: managed
					if (!(Util.InDict(_bmd, _dctMapBitmapToRefBitmap)))
						throw new Error("managed bitmap not in bitmap map");
					if (_cReferences <= 0)
						throw new Error("No references");
				}
				if (_fDisposed)
					throw new Error("Bitmap is disposed");
			} catch (e:Error) {
				trace("Bitmap validation failed: " + e);
				trace(GetDebugInfo(_bmd));
				throw e;
			}
		}
		
		public function MakeExternal(): void {
			// Make this bitmap external - return it to something that doesn't do ref counting,
			// for example the image document. Eventually, everything should do ref counting.
			if (_fExternal)
				return; // Already external
				
			_fExternal = true;
			
			if (!(Util.InDict(_bmd, _dctMapBitmapToRefBitmap)))
				throw new Error("Non-external bitmap not in bitmap map");
				
			_cReferences = 0;

			if (_bmd is VBitmapData)
				VBitmapData(_bmd)._fReferenced = false;
			
			delete _dctMapBitmapToRefBitmap[_bmd];
		}
		
		public function AddReference(bmdr:BitmapReference): void {
			if (_fDisposed)
				throw new Error("Adding reference to disposed bitmap"); // Should this be allowed?
				
			if (Util.InDict(bmdr, _dctReferences))
				throw new Error("duplicate reference");
				
			_dctReferences[bmdr] = bmdr;

			if (_fExternal)
				return;
			_cReferences++;
		}
		
		public function RemoveReference(bmdr:BitmapReference): void {
			if (!(Util.InDict(bmdr, _dctReferences)))
				throw new Error("removing non-existant reference");
				
			delete _dctReferences[bmdr];
			
			if (_fExternal)
				return;
			if (_cReferences <= 0)
				throw new Error("Negative ref count?!?");
			_cReferences--;
			if (_cReferences <= 0)
				Delete();
		}
		
		public function toString(): String {
			return String(_bmd) + ":" + (_fExternal ? "external" : (_cReferences + "/" + _fDisposed));
		}
		
		private function Delete(): void {
			if (_fExternal)
				throw new Error("delete external ref?!?"); // Should never get here
				
			if (_fDisposed)
				throw new Error("double delete");

			if (!(Util.InDict(_bmd, _dctMapBitmapToRefBitmap)))
				throw new Error("_bmd not in map!?!");
				
			delete _dctMapBitmapToRefBitmap[_bmd];

			if (_bmd is VBitmapData)
				VBitmapData(_bmd)._fReferenced = false;

			VBitmapData.OnBitmapRefDispose(_bmd);

			_bmd.dispose();
			_fDisposed = true;
		}
	}
}