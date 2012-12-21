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
package imagine {
	import flash.display.BitmapData;
	
	import imagine.imageOperations.ImageOperation;
	import imagine.imageOperations.NestedImageOperation;
	
	import imagine.ImageDocument;
	
	import imagine.objectOperations.ObjectOperation;
	
	import util.BitmapCache;
	import util.VBitmapData;
	
	public class ImageUndoTransaction extends UndoTransaction { // iut
		public var bmdBackground:BitmapData;
		public var aop:Array;
		public var coalescable:Boolean = true;
		public var fCacheInUse:Boolean = false;
		
		public function ImageUndoTransaction(bmdBackground:BitmapData, fDirty:Boolean, strName:String=null,
				aop:Array=null, fLog:Boolean=true, fCacheInUse:Boolean=false)
		{
			super(strName, fLog, fDirty);
			this.strName = strName;
			this.bmdBackground = bmdBackground;
			if (aop)
				this.aop = aop;
			else
				this.aop = new Array();
			this.fCacheInUse = fCacheInUse;
		}
		
		public override function Dispose(): void {
			if (bmdBackground)
				VBitmapData.SafeDispose(bmdBackground);			
			for each (var op:ImageOperation in aop) {
				op.Dispose();
			}
			this.aop = new Array();
		}
		
		private static function ArrayContainsImageOp(aop:Array): Boolean {
			for each (var op:ImageOperation in aop) {
				if (op is NestedImageOperation) {
					var nop:NestedImageOperation = op as NestedImageOperation;
					if (ArrayContainsImageOp(nop.children)) return true;
				} else if (!(op is ObjectOperation)) {
					return true;
				}
			}
			return false;
		}
		
		public static function ArrayContainsObjectOp(aop:Array): Boolean {
			for each (var op:ImageOperation in aop) {
				if (op is NestedImageOperation) {
					var nop:NestedImageOperation = op as NestedImageOperation;
					if (ArrayContainsObjectOp(nop.children)) return true;
				} else if (op is ObjectOperation) {
					return true;
				}
			}
			return false;
		}
		
		public function get objectOperationsOnly(): Boolean {
			return !ArrayContainsImageOp(aop);
		}
		
		public function Do(imgd:ImageDocument, fDoObjects:Boolean, fDontDisposeInitialBackground:Boolean=false): void {
			try {
				var bmdInitialBackground:BitmapData = fDontDisposeInitialBackground ? imgd.background : null;
				for each (var op:ImageOperation in aop) {
					var bmdDispose:BitmapData = imgd.background;
					var fSuccess:Boolean = op.Do(imgd, fDoObjects, false);
					
					if (fSuccess && !(op is ObjectOperation)) {
						BitmapCache.Remove(imgd.background);
						BitmapCache.Clear();
						if (bmdDispose != imgd.background && bmdDispose != bmdInitialBackground)
							VBitmapData.SafeDispose(bmdDispose);
					}
				}
				
			// We may be going down but it's still a good idea to clean up what we can
			} catch (err:Error) {
				BitmapCache.Remove(imgd.background);
				BitmapCache.Clear();
				if (bmdDispose != imgd.background && bmdDispose != bmdInitialBackground)
					VBitmapData.SafeDispose(bmdDispose);
			}
		}
	}
}
