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
package imagine.imageOperations.paintMask
{
	import flash.display.BitmapData;
	import flash.utils.Dictionary;
	
	public class CachedBrush
	{
		private static var _obBrushCache:Object = {};
		
		private var _nReferences:Number = 0;
		private var _bmd:BitmapData = null;
		private var _dctReferences:Dictionary = new Dictionary();
		private var _strKey:String;
		private var _aobParams:Array;
		private var _fnCreate:Function;
		
		private static function ParamsToKey(strType:String, aobParams:Array): String {
			var strKey:String = strType;
			for each (var obParam:Object in aobParams)
				strKey += "|" + obParam;
				
			return strKey;
		}
		
		public static function GetBrush(strType:String, fnCreate:Function, aobParams:Array): CachedBrush {
			var strKey:String = ParamsToKey(strType, aobParams);
			if (!(strKey in _obBrushCache)) {
				_obBrushCache[strKey] = new CachedBrush(strKey, fnCreate, aobParams);
			}
				
			return _obBrushCache[strKey];
		}
		
		public function CachedBrush(strKey:String, fnCreate:Function, aobParams:Array)
		{
			_strKey = strKey;
			_aobParams = aobParams;
			_fnCreate = fnCreate;
		}
		
		public function get bitmapData(): BitmapData {
			return _bmd;
		}
		
		public function AcquireBitmap(obOwner:Object): BitmapData {
			if (!(Util.InDict(obOwner, _dctReferences))) {
				_nReferences += 1;
				_dctReferences[obOwner] = true;
			} else {
				trace("WARNING: Duplicate CachedBrush acquire");
			}
			if (_bmd == null)
				_bmd = _fnCreate.apply(null, _aobParams);
			return _bmd;
		}
		
		public function ReleaseBitmap(obOwner:Object): void {
			if (!(Util.InDict(obOwner, _dctReferences))) {
				trace("WARNING: Duplicate CachedBrush release");
				return;
			}
			delete _dctReferences[obOwner];
			_nReferences -= 1;
			if (_nReferences <= 0) {
				if (_bmd != null)
					_bmd.dispose();
				_bmd = null;
				delete _obBrushCache[_strKey];
			}
		}
	}
}