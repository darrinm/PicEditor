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
package containers
{
	import flash.events.Event;
	import containers.NestedControlCanvasBase;

	public class NestedControlEvent extends Event
	{
		public static var SELECT_NICELY:String = "EFFECT_SELECT_NICELY"; // Select with the "loose changes?" dialog (if needed)
		public static var DESELECT_NICELY:String = "EFFECT_DESELECT_NICELY"; // Deselect with the "loose changes?" dialog (if needed)
		public static var SELECTED:String = "EFFECT_SELECTED";
		public static var DESELECTED:String = "EFFECT_DESELECTED";
		public static var OP_CHANGED:String = "OP_CHANGED";
		public static var SELECTED_EFFECT_BEGIN:String = "SELECTED_EFFECT_BEGIN";
		public static var SELECTED_EFFECT_END:String = "SELECTED_EFFECT_END";
		public static var SELECTED_EFFECT_UPDATED_BITMAPDATA:String = "SELECTED_EFFECT_UPDATED_BITMAPDATA";
		public static var DESELECTED_EFFECT_END:String = "DESELECTED_EFFECT_END";

		protected var _efcnv:NestedControlCanvasBase = null;
		protected var _fEffectButtonClick:Boolean = false;
		
		public function NestedControlEvent(strState:String, efcnv:NestedControlCanvasBase, fEffectButtonClick:Boolean=false) {
			_efcnv = efcnv;
			_fEffectButtonClick = fEffectButtonClick;
			super(strState, true); // bubble it up so that our eventual container can catch it
		}
		
		public function get NestedControlCanvas(): NestedControlCanvasBase {
			return _efcnv;
		}

		public function get effectButtonClick(): Boolean {
			return _fEffectButtonClick;
		}
	}
}