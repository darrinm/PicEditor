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
	 * Item entry for UnusedList
	 * Knows pixel size
	 * Keeps track of in-list-ness
	 */
	public class PendingListEntry
	{
		public var item:ITileListItem;
		public var index:String;
		
		public function PendingListEntry(tli:ITileListItem, strIndex:String)
		{
			if (tli == null) throw new Error("inserting null item");
			if (!strIndex || strIndex.length == 0) throw new Error("invalid index");
			if (tli.data == null) throw new Error("Empty data?!?");
			item = tli;
			index = strIndex;
		}
		
		public function toString(): String {
			var strItem:String = "null";
			if (item != null) {
				strItem = "untitled";
				if ('title' in item)
					strItem = item['title'];
				else if ('data' in item && 'title' in item['data'])
					strItem = item['data']['title'];
			}
			return "PLE[" + index + "]: " + strItem;
		}
	}
}