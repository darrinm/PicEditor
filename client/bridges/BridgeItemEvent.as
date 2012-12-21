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
package bridges
{
	import flash.events.Event;
	
	// This event is fired by bridge items.
	// Most events have an associated action, which is defined in the Bridge class
	public class BridgeItemEvent extends Event {
		public static const CLICK:String = "bridgeItemClick";
		public static const DOUBLE_CLICK:String = "bridgeItemDoubleClick";
		public static const ITEM_ACTION:String = "bridgeItemAction";
		public static const TOOL_TIP_CREATE:String = "bridgeItemToolTipCreate";

		public var data:Object = null; // Used for actions with data, such as COMMIT_RENAME
		
		private var _britm:BridgeItemBase = null;
		private var _strAction:String = null;
		private var _evtRelay:Event;
		
		public function BridgeItemEvent(strType:String, britm:BridgeItemBase, strAction:String,
				evtRelay:Event=null, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(strType, bubbles, cancelable);
			_britm = britm;
			_strAction = strAction;
			_evtRelay = evtRelay;
		}
		
		// The data associated with the bridge item which triggered the event.
		// This is usually an ImageProperties instance
		public function get bridgeItemData(): Object {
			return _britm.data;
		}
		
		// The bridge item which triggered the event
		public function get bridgeItem(): BridgeItemBase {
			return _britm;
		}

		// The action the user has requested (e.g. edit, email, delete, etc)
		public function get action(): String {
			return _strAction;
		}
		
		public function get relayEvent(): Event {
			return _evtRelay;
		}
	}
}
