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
	import flash.utils.Dictionary;
	import mx.states.State;
	import flash.geom.Point;
	
	
	/***
	 * StateSizer supports dyanimc selection of sized states based on component size.
	 *
	 * To use it:
	 * 1. Create a control with display components.
	 * 2. Create smaller states, in order.
	 * 3. Add this to your component:  resize="StateSizer.ChooseSizedState(this)"
	 *
	 * When you do this, whenever your component is resized, it will check to see if the
	 * current state "fits" the contents by checking the measuredWidth variable.
	 * If it doesn't fit, it will resize up or down to make it fit.
	 *
	 * In order to work:
	 * 1. States must be listed in order from largest to smallest.
	 * 2. If the default state isn't "", you should pass the default state in to ChooseSizedState
	 * 3. Your components must not do any clipping or scrolling.
	 *    If they do, their measured width will be incorrect.
	 ***/
	public class StateSizer
	{
		private static var _dctSizeInfo:Dictionary = null;

		// Get the states from the component. Assume they are in size order, top to bottom.
		protected static function SizeStatesFromStatesArray(asts:Array, strDefaultState:String=""): Array {
			var astrSizeStates:Array = [];
			astrSizeStates.push(strDefaultState);
			for each (var st:State in asts) {
				if (st.name != strDefaultState) {
					astrSizeStates.push(st.name);
				}
			}
			return astrSizeStates;
		}
		
		public static function CleanState(strState:String): String {
			return strState == null ? "" : strState;
		}

		public static function ChooseSizedState(uic:UIComponent, strDefaultState:String=""): void {
			var astrSizeStates:Array = uic["_astrSizeStates"];
			if (astrSizeStates == null || astrSizeStates.length == 0) {
				astrSizeStates = SizeStatesFromStatesArray(uic.states, strDefaultState);
				uic["_astrSizeStates"] = astrSizeStates;
			}
			if (astrSizeStates.length < 2) return;
			
			if (astrSizeStates.indexOf(CleanState(uic.currentState)) < 0) {
				trace("ChooseSizedStates failed because " + uic.name + " is in state " + uic.currentState + " which is not in _astrSizeStates");
				return;
			}
			
			if (_dctSizeInfo == null) _dctSizeInfo = new Dictionary();
			
			var obSizeInfo:Object; // Maps states we've seen to measured widths. Used for going back to bigger states.
			if (!(uic in _dctSizeInfo)) {
				_dctSizeInfo[uic] = new Object();
			}
			obSizeInfo = _dctSizeInfo[uic];
			
			var sszr:StateSizer = new StateSizer(uic, astrSizeStates, obSizeInfo);
			sszr.Go();
		}
		
		private var _uic:UIComponent;
		private var _astrSizeStates:Array;
		private var _obSizeInfo:Object;
		
		private var _nCurrentStatePos:Number = -1;

		public function StateSizer(uic:UIComponent, astrSizeStates:Array, obSizeInfo:Object) {
			_uic = uic;
			_astrSizeStates = astrSizeStates;
			_obSizeInfo = obSizeInfo;
			_nCurrentStatePos = astrSizeStates.indexOf(CleanState(uic.currentState));
		}
		
		private function ChangeState(nTargetStatePos:Number): void {
			// First, record the current measuredWidth
			RecordCurrentStateSize();
			
			// Next, update the state
			_nCurrentStatePos = nTargetStatePos;
			_uic.currentState = _astrSizeStates[_nCurrentStatePos];
			_uic.validateSize(true); // UNDONE: Is this needed? What is the cost?
			RecordCurrentStateSize(); // Remember the new size.
		}
		
		private function SizeDown(): void {
			// Size down. remember the current measured width.
			while (_uic.measuredWidth > _uic.width && (_nCurrentStatePos < (_astrSizeStates.length-1))) {
				ChangeState(_nCurrentStatePos + 1); // Select a smaller state.
			}
		}
		
		private function RecordCurrentStateSize(): void {
			_obSizeInfo[CleanState(_uic.currentState)] = new Point(_uic.measuredWidth, _uic.measuredHeight);
		}

		private function Go(): void {
			// Do we need this? Leave it here for now.
			_uic.validateSize(true);
			
			// Do we need to go up or down?
			if (_uic.measuredWidth > _uic.width) {
				SizeDown();
			} else if (_nCurrentStatePos > 0) {
				SizeUp();
			}
		}

		private function StateIsTooLarge(nTargetState:Number): Boolean {
			var ptStateRequiredSize:Point = _obSizeInfo[_astrSizeStates[nTargetState]] as Point;
			return ((ptStateRequiredSize.x > _uic.width) || (ptStateRequiredSize.y > _uic.height));
		}

		
		// Look for a bigger state that still fits our width
		private function SizeUp(): void {
			// Look back up the list looking for the first state which is one of:
			//  - The first state
			//  - A state with an unknown size
			//  - A state whose next bigger state is too large.
			
			var nTargetState:Number = _nCurrentStatePos;
			while (nTargetState > 0) {
				if (!(_astrSizeStates[nTargetState] in _obSizeInfo)) {
					// Found a state without a size. Try this one.
					break;
				}
				if (_astrSizeStates[nTargetState - 1] in _obSizeInfo) {
					// Get the next state size
					if (StateIsTooLarge(nTargetState - 1)) {
						// Found a state whose next bigger size is too big. This is it.
						break;
					}
				}
				nTargetState--;
			}
			
			// Now we have a target state
			if (nTargetState != _nCurrentStatePos) {
				ChangeState(nTargetState);
				if (_uic.measuredWidth > _uic.width) SizeDown(); // We went too far.
			}
		}
		
	}
}