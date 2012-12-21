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
	import flash.utils.Dictionary;
	
	public class BitmapCache {
		// A Dictionary of Dictionaries. The first is indexed by owner object, the second by
		// owner-defined entry type.
		private static var s_dctCaches:Dictionary = new Dictionary();
		private static var s_dctCachesToClear:Dictionary = new Dictionary();
		private static var s_aDisposable:Array = [];
		
		private static var s_fLog:Boolean = false;
		
		// Returns null if nothing found.
		static public function Lookup(obOwner:Object, strType:String, strParams:String, bmdSrc:BitmapData): BitmapData {
			var bce:BitmapCacheEntry = LookupEntry(obOwner, strType, strParams, bmdSrc);
			if (bce)
				return bce.result;
			else
				return null;
		}
		
		static public function DumpCaches(): void {
			for (var obOwner:Object in s_dctCaches) {
				trace("=== Cache owned by " + obOwner + ", " + typeof(obOwner) + " ===");
				var dct:Dictionary = s_dctCaches[obOwner];
				if (dct == null)
					trace("   null");
				else
					for (var strType:String in dct)
						trace("   " + strType + ": " + dct[strType]);
			}
		}
		
		static public function AddDisposable(idisp:IDisposable): void {
			s_aDisposable.push(idisp);
		}
		
		// Returns null if nothing found.
		static public function LookupEntry(obOwner:Object, strType:String, strParams:String, bmdSrc:BitmapData): BitmapCacheEntry {
			var dctCache:Dictionary = s_dctCaches[obOwner];
			if (dctCache == null)
				return null;
				
			var bce:BitmapCacheEntry = null;
			if (strType in dctCache) {
				bce = dctCache[strType] as BitmapCacheEntry;
				if (bce && !bce.matches(strParams, bmdSrc)) {
					bce = null; // Not a match
				}
			}
			return bce;
		}
		
		// disposes any bitmaps in the cache
		static public function Clear(): void {
			for (var obOwner:Object in s_dctCaches) {
				var dctCache:Dictionary = s_dctCaches[obOwner] as Dictionary;
				for (var strKey:String in dctCache) {
					var bce:BitmapCacheEntry = dctCache[strKey] as BitmapCacheEntry;
					if (bce)
						bce.Dispose();
					delete dctCache[strKey];
				}
				delete s_dctCaches[obOwner];	
			}
			while (s_aDisposable.length > 0)
				IDisposable(s_aDisposable.pop()).Dispose();
			DelayedClear();
		}
		

		// All about MarkForDelayedClear and DelayedClear:
		// What MarkForDelayedClear is doing is taking the contents of the cache
		// and marking it as something we'd like to get rid of in a little
		// while.  We don't use the regular "Clear" because we're still
		// using some of the contents -- for a little while.  In a little
		// while, we'll call DelayedClear.  We can't call regular "Clear" in
		// a little while because in the meantime, new data that we want
		// to keep around has been added to the cache.
		// This scenario happens when the user is browsing the effects on
		// the create tab and not hitting "cancel".  We render one effect,
		// and stuff its results in the cache.  The user clicks on the next
		// effect.  We continue displaying the current effect while the next
		// effect renders, ending up with a mixed cache. We need some way to
		// clear the cache of the old effect's results or, with enough browsing
		// the cache can get TOO full and we can actually run out of memory. 
		// So, MarkForDelayedClear and DelayedClear handle the temporal splitting
		// of the cache for this scenario.  Direct your questions to Steve.
		static public function DelayedClear(): void {
			for (var obOwner:Object in s_dctCachesToClear) {
				var dctCache:Dictionary = s_dctCachesToClear[obOwner] as Dictionary;
				for (var strKey:String in dctCache) {
					var bce:BitmapCacheEntry = dctCache[strKey] as BitmapCacheEntry;
					if (bce)
						bce.Dispose();
					delete dctCache[strKey];
				}
				delete s_dctCachesToClear[obOwner];	
			}			
		}
				
		// disposes any bitmaps in the cache
		static public function MarkForDelayedClear(): void {
			for (var obOwner:Object in s_dctCaches) {
				s_dctCachesToClear[obOwner] = s_dctCaches[obOwner];
				delete s_dctCaches[obOwner];	
			}
		}
		
		// Remove the BitmapData from the cache but DON'T dispose() it
		static public function Remove(bmd:BitmapData): void {
			for (var obOwner:Object in s_dctCaches) {
				var dctCache:Dictionary = s_dctCaches[obOwner] as Dictionary;
				for (var strKey:String in dctCache) {
					var bce:BitmapCacheEntry = dctCache[strKey] as BitmapCacheEntry;
					if (bce.result == bmd)
						delete dctCache[strKey];
				}
			}
		}
		
		// Keep a copy of a cache entry around for a bit longer
		static public function BackupCacheEntry(obOwner:Object, strType:String): void {
			var dctCache:Dictionary = s_dctCaches[obOwner];
			if (dctCache == null) {
				dctCache = new Dictionary();
				s_dctCaches[obOwner] = dctCache;
			}
				
			if (strType in dctCache) {
				var bce:BitmapCacheEntry = dctCache[strType] as BitmapCacheEntry;
				if (bce) {
					Set(obOwner, strType + "_backup", null, null, bce.result);
				}
			}
		}
		
		static public function ClearOne(obOwner:Object, strType:String): void {
			var dctCache:Dictionary = s_dctCaches[obOwner];
			if (dctCache == null)
				return;
			if (strType in dctCache && (dctCache[strType] != null)) {
				var bce:BitmapCacheEntry = dctCache[strType] as BitmapCacheEntry;
				delete dctCache[strType];
				if (bce && !Contains(bce.result)) {
					bce.Dispose();
				}
			}
		}
		
		static public function Set(obOwner:Object, strType:String, strParams:String,
				bmdSrc:BitmapData, bmdResult:BitmapData, data:Object=null): void {
			var dctCache:Dictionary = s_dctCaches[obOwner];
			if (dctCache == null) {
				dctCache = new Dictionary();
				s_dctCaches[obOwner] = dctCache;
			}
			if (strType in dctCache && (dctCache[strType] != null)) {
				var bce:BitmapCacheEntry = dctCache[strType] as BitmapCacheEntry;
				delete dctCache[strType];
				if (bce && !Contains(bce.result) && (bce.result != bmdResult)) {
					bce.Dispose();
				}
			}
			dctCache[strType] = new BitmapCacheEntry(strParams, bmdSrc, bmdResult, data);
			if (s_fLog)
				trace("Set cache: " + strType + ", " + bmdResult);
		}
		
		static public function Contains(bmdResult:BitmapData): Boolean {
			if (!bmdResult) return false;
			for (var obOwner:Object in s_dctCaches) {
				var dctCache:Dictionary = s_dctCaches[obOwner] as Dictionary;
				for (var strKey:String in dctCache) {
					var bce:BitmapCacheEntry = dctCache[strKey] as BitmapCacheEntry;
					if (bce && bce.result == bmdResult) return true; // Found it
				}
			}
			return false; // Didn't find it.
		}
	}
}
