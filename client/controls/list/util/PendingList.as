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
package controls.list.util
{
	import controls.list.ITileListItem;
	
	/**
	 * A list of pending item renderers.
	 * Keeps track of the total pixel size
	 * Supports Enqueue and Dequeue (least recently used)
	 */
	public class PendingList
	{
		private var _a:Array = [];
		
		private var _obMapKeyToEntries:Object = {};
		
		private var _fAllHidden:Boolean = true;
		
		public function PendingList()
		{
		}
		
		public function Validate(): void {
			var ple:PendingListEntry;
			for (var i:Number = 0; i < _a.length; i++) {
				ple = _a[i];
				if (!ple) throw new Error("null array element at pos: " + i + ", " + length);
				if (!ple.index || ple.index.length == 0) throw new Error("Empty index at pos: " + i);
				if (!ple.item) throw new Error("Missing item, index = " + ple.index);
				if (!(ple.index in _obMapKeyToEntries)) throw new Error("item missing from map: " + ple);
				if (_obMapKeyToEntries[ple.index] != ple) throw new Error("item not mapped to self. item: " + ple + ", mapping: " + _obMapKeyToEntries[ple.index]);
			}
			
			for (var strKey:String in _obMapKeyToEntries) {
				ple = _obMapKeyToEntries[strKey];
				if (ple == null) throw new Error("null map: " + strKey);
				if (_a.indexOf(ple) < 0) throw new Error("item in map not in array: " + ple);
			}
		}
		
		public function get length(): Number {
			return _a.length;
		}
		
		public function RemoveAll(aobTo:Array): void {
			while (_a.length) {
				var ple:PendingListEntry = _a.pop();
				ple.item.data = null;
				ple.item.visible = false;
				aobTo.push(ple.item);
			}
			_obMapKeyToEntries = {};
		}
		
		public function HideAll(): void {
			if (_fAllHidden) return;
			for each (var ple:PendingListEntry in _a) {
				if (ple.item.visible) ple.item.visible = false;
			}
			_fAllHidden = true;
		}
		
		public function RemoveIfFound(strIndex:String, aobTo:Array): void {
			var tli:ITileListItem = Fetch(strIndex);
			if (tli) aobTo.push(tli);
		}
		
		// Returns null if not found
		public function Fetch(strIndex:String): ITileListItem {
			if (!(strIndex in _obMapKeyToEntries)) return null;
			var ple:PendingListEntry = _obMapKeyToEntries[strIndex];
			if (!ple) throw new Error("null item?!?"); 
			delete _obMapKeyToEntries[strIndex];

			var nIndex:Number = _a.indexOf(ple);
			if (nIndex < 0) throw new Error("item in map but not array");
			_a.splice(nIndex, 1);
			return ple.item;
		}
		
		public function Enqueue(tli:ITileListItem, strIndex:String, aobRemovePreviousTo:Array=null): void {
			var ple:PendingListEntry = new PendingListEntry(tli, strIndex);
			if (strIndex in _obMapKeyToEntries) {
				if (aobRemovePreviousTo) {
					RemoveIfFound(strIndex, aobRemovePreviousTo);
				} else {
					trace("Waring: overwriting pending list entry item");
					_obMapKeyToEntries[strIndex].data = null; // free up the data
					_obMapKeyToEntries[strIndex].visible = false;
				}
			}
			_obMapKeyToEntries[strIndex] = ple;
			_a.unshift(ple);
			_fAllHidden = false;
		}
		
		public function RemoveLast(aobTo:Array): void {
			var tli:ITileListItem = Dequeue();
			tli.data = null;
			tli.visible = false;
			aobTo.push(tli);
		}
		
		public function Dequeue(): ITileListItem {
			var ple:PendingListEntry = _a.pop();
			
			// Remove from our key map
			delete _obMapKeyToEntries[ple.index];
			
			return ple.item;
		}

		/** UpdateIndices
		 * The collection has changed in one of three ways:
		 *   1. Items removed (cItems < 0)
		 *   2. Items added (cItems > 0, fReplace == false)
		 *   3. Items replaced (cItems > 0, fReplace == true)
		 * Updates our map to reflect the new indices
		 * Puts removed/replaced items in aobRemoved
		 */
	    public function UpdateIndices(nInsertAt:int, cItems:int, aobRemoved:Array, fReplace:Boolean=false): void {
	    	if (cItems != 0) {
		    	var obNewMap:Object = {};
		    	for (var strOldKey:String in _obMapKeyToEntries) {
	    			var nNewIndex:Number = Number(strOldKey);
	    			var fRemove:Boolean = false;
	    			if (fReplace) {
	    				fRemove = (nNewIndex >= nInsertAt) && (nNewIndex < (nInsertAt + cItems));
	    			} else {
		    			if (nNewIndex >= nInsertAt) {
		    				nNewIndex += cItems;
		    				if (nNewIndex < nInsertAt) {
		    					// Remove this item
		    					fRemove = true;
			    			}
			    		}
			    	}
			    	if (fRemove) {
			    		// Need to remove the item from our array
			    		var ple:PendingListEntry = _obMapKeyToEntries[strOldKey];
			    		var nDeleteIndex:Number = _a.indexOf(ple);
			    		if (nDeleteIndex < 0) throw new Error("could not find item to delete");
			    		_a.splice(nDeleteIndex, 1);
			    		ple.item.data = null;
			    		ple.item.visible = false;
			    		aobRemoved.push(ple.item);
			    	} else {
	    				obNewMap[nNewIndex] = _obMapKeyToEntries[strOldKey];
	    			}
		    	}
		    	_obMapKeyToEntries = obNewMap;
	    	}
	    	// Update our indices
	    	for (var strKey:String in _obMapKeyToEntries) {
	    		PendingListEntry(_obMapKeyToEntries[strKey]).index = strKey;
	    	}
	    }

	    public function UpdateIndicesForMove(nMoveFrom:Number, nMoveTo:Number): void {
	    	if (nMoveTo != nMoveFrom) {
	    		// iShuffleDist is the direction inbetween elemnts are moving
	    		// For example, if we are moving from pos 1 to 5 (down),
	    		// element 1 moves to position 5. Elements 2-5 shuffle up one
		    	var iShuffleDist:Number = (nMoveTo > nMoveFrom) ? -1 : 1;
		    	var nMax:Number = Math.max(nMoveTo, nMoveFrom);
		    	var nMin:Number = Math.min(nMoveTo, nMoveFrom);
		    	var obNewMap:Object = {};
		    	for (var strOldKey:String in _obMapKeyToEntries) {
	    			var nNewIndex:Number = Number(strOldKey);
	    			if (nNewIndex == nMoveFrom)
	    				nNewIndex = nMoveTo;
	    			else if (nNewIndex <= nMax && nNewIndex >= nMin)
	    				nNewIndex += iShuffleDist;
	   				obNewMap[nNewIndex] = _obMapKeyToEntries[strOldKey];
		    	}
		    	_obMapKeyToEntries = obNewMap;
		    }
	    	// Update our indices
	    	for (var strKey:String in _obMapKeyToEntries) {
	    		PendingListEntry(_obMapKeyToEntries[strKey]).index = strKey;
	    	}
	    }

	}
}