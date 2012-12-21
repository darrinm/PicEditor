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
package util
{
	import mx.core.UIComponent;
	
	public class StateSize
	{
		public static function UpdateState(uic:UIComponent, astszStateSizes:Array = null): void {
			// First, look for an array
			
			if (astszStateSizes == null) {
				if ("_astszStateSizes" in uic) {
					astszStateSizes = uic["_astszStateSizes"] as Array;
				}
			}
			
			if (astszStateSizes != null) {
				// Walk the array, in reverse.
				// Choose the first state that fits.
				// Default state is ""
				var strState:String = "";
				for (var i:Number = astszStateSizes.length-1; i >= 0; i--) {
					var stsz:StateSize = astszStateSizes[i] as StateSize;
					if (stsz && uic.width <= stsz.maxwidth && uic.height <= stsz.maxheight) {
						strState = stsz.state;
						break;
					}
				}
				uic.currentState = strState;
			}
		}
		
		private var _cxMaxWidth:Number = Number.MAX_VALUE;
		private var _cyMaxHeight:Number = Number.MAX_VALUE;
		private var _strState:String = "";
		
		public function get maxwidth(): Number {
			return _cxMaxWidth;
		}
		
		public function set maxwidth(cxMaxWidth:Number): void {
			_cxMaxWidth = cxMaxWidth;
		}
		
		public function get maxheight(): Number {
			return _cyMaxHeight;
		}
		
		public function set maxheight(cyMaxHeight:Number): void {
			_cyMaxHeight = cyMaxHeight;
		}
		
		public function get state(): String {
			return _strState;
		}
		
		public function set state(strState:String): void {
			_strState = strState;
		}
	}
}
