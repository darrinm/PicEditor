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
package controls.list.util.tests
{
	import controls.list.ITileListItem;
	import controls.list.util.PendingList;
	
	public class PendingListTestState
	{
		public var pl:PendingList;
		public var aobFree:Array = [];
		public var aobCreated:Array = [];
		
		public function PendingListTestState()
		{
			pl = new PendingList();
		}
		
		public function Validate(fRemoveAll:Boolean=false): void {
			if (fRemoveAll) Validate(false);
			pl.Validate();
			// Validate other things?
			
			// Let's make sure all of our created items appear everywhere.
			
			
			if (fRemoveAll) pl.RemoveAll(aobFree);
			
			if ((aobFree.length + pl.length) != aobCreated.length) throw new Error("missing items: " + pl.length + ", " + aobFree.length + ", " + aobCreated.length);
			
			var tli:ITileListItem;
			
			var i:Number = 0;
			for each (tli in aobFree) {
				if (aobCreated.indexOf(tli) < 0) throw new Error("Item in free not in created: " + tli);
				if (aobFree.indexOf(tli) != i) throw new Error("Item in free two times: " + tli);
				i++;
			}
			i = 0;
			
			var cNotFree:Number = 0;
			for each (tli in aobCreated) {
				if (aobFree.indexOf(tli) < 0) {
					// Not in free list
					cNotFree += 1;
					if (pl.length < cNotFree) {
						throw new Error("Item in created not in free, no room in list: " + tli);
					}
				}
				if (aobCreated.indexOf(tli) != i) throw new Error("Item in created two times: " + tli);
				i++;
			}
		}
		
		public function Create(nIndex:Number): ITileListItem {
			var tli:ITileListItem = new TestTileListItem(nIndex);
			aobCreated.push(tli);
			return tli;
		}
	}
}