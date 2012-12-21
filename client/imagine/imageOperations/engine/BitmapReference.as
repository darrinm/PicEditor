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
	import flash.display.BitmapData;
	
	import util.VBitmapData;
	
	public class BitmapReference
	{
		private var _bmdrd:BitmapReferenceData;
		private var _fDisposed:Boolean = false;
		private var _strUser:String = "unknown";
		// public var _bmd:BitmapData;
		// private var _fExternal:Boolean;
		// private var _obSharedInfo:Object = null;
		
		public function get _bmd(): BitmapData {
			return _bmdrd._bmd;
		}
		
		/** TakeOwnership
		 * Take ownership of an external bitmap.
		 * If the bitmap is already reference counted, return a new reference.
		 * If it is not counted, start counting. The bitmap will be automatically
		 * disposed of when the reference count reaches 0.
		 */
		public static function TakeOwnership(strUser:String, bmd:BitmapData): BitmapReference {
			return new BitmapReference(strUser, null, NaN, NaN, true, 0xFFFFFFFF, BitmapReferenceData.TakeOwnership(bmd));
		}
		
		public static function Repurpose(bmdr:BitmapReference, strNewUse:String): BitmapReference {
			var bmdrNew:BitmapReference = bmdr.copyRef(strNewUse);
			bmdr.dispose();
			return bmdrNew;
		}
		
		/** NewExternalReference
		 * Create a new reference to an external, not reference counted bitmap.
		 * This "reference" will not count. It will keep track of outstanding
		 * references but it will never dispose of the bitmap.
		 */
		public static function NewExternalReference(strUser:String, bmd:BitmapData): BitmapReference {
			return new BitmapReference(strUser, null, NaN, NaN, true, 0xFFFFFFFF, BitmapReferenceData.NewExternal(bmd));
		}
		
		public function BitmapReference(strUser:String, strUse:String, nWidth:Number=NaN, nHeight:Number=NaN,
				fTransparent:Boolean=true, nFillColor:uint=0xFFFFFFFF, bmdrd:BitmapReferenceData=null) 
		{
			if (bmdrd == null)
				bmdrd = BitmapReferenceData.New(strUse, nWidth, nHeight, fTransparent, nFillColor);
			_bmdrd = bmdrd;
			_strUser = strUser;
			_bmdrd.AddReference(this);
			validate("Created reference to an invalid bitmap");
		}
		
		public function CopyAndDispose(strUser:String): BitmapReference {
			var bmdrNew:BitmapReference;
			if (_bmdrd._cReferences <= 1) {
				bmdrNew = BitmapReference.Repurpose(this, strUser);
			} else {
				// More than one reference. Deep copy, then release.
				bmdrNew = deepCopy(strUser);
				dispose();
			}
			return bmdrNew;
		}
		
		public function MakeExternal(): void {
			_bmdrd.MakeExternal();
		}
		
		public function get user(): String {
			return _strUser;
		}
		
		public function toString(): String {
			return "BmpRef[" + _strUser + ": " + _bmdrd + "]";
		}
		
		public function get label(): String {
			return toString();
		}
		
		public function validate(strMessage:String): void {
			if (_bmd == null)
				throw new Error(strMessage + ": bmd is null");
			if (_bmd is VBitmapData && !VBitmapData(_bmd).valid)
				throw new Error(strMessage + ": bmd is invalid (disposed?)");
			try {
				_bmd.width;
			} catch (e:Error) {
				throw new Error(strMessage + ": could not get bitmap width: " + e);
			}
			_bmdrd.Validate();
		}
		
		public function dispose(): void {
			if (_fDisposed)
				throw new Error("double disposing reference");
			_fDisposed = true;
			_bmdrd.RemoveReference(this);
		}
		
		/*
		public function writeableClone(): BitmapReference {
			if (_obSharedInfo && _obSharedInfo.refCount > 1)
				return copy();
			else
				return clone();
		}
		*/
		
		public function copyRef(strUser:String): BitmapReference {
			validate("Cloning invalid reference");
			return new BitmapReference(strUser, null, NaN, NaN, true, 0xffffffff, _bmdrd);
		}
		
		public function deepCopy(strUser:String): BitmapReference {
			validate("Copying invalid reference");
			return TakeOwnership(strUser, _bmd.clone());
		}
	}
}