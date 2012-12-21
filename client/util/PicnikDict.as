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
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	public class PicnikDict extends EventDispatcher
	{
		public static const knUnknown:Number = -1;
		public static const knPending:Number = 0;
		public static const knExists:Number = 1;
		public static const knDoesNotExist:Number = 2;
		// Exists and has special status
		// For example, the username validator is looking for
		// a valid username. A username associated with a Google account
		// is no longer valid (you can't sign in with Picnik). This account
		// exists and is special - the validator treates it as not valid and
		// shows a specific message.
		public static const knExistsAndIsSpecial:Number = 100;

		/***** BEGIN: Override these *****/
		// Override this to kick off some async process to lookup the state
		protected function LookupStateElsewhere(strVal:String): void {
		}

		// Returns an array of ValidationResult objects
		// These objects contain information about what went wrong, mostly an error string and a code
		// If this function returns a result of length zero, there were no errors.
		public function ValidateChars(strVal:String): Array {
			return []; // Default is everything goes. Override as needed
		}
		/***** END: Override these *****/
	
		public function CharsValid(strVal:String): Boolean {
			return ValidateChars(strVal).length == 0;
		}
		
		protected function CleanState(nState:Number): Number {
			var fKnownState:Boolean = (nState == knUnknown || nState == knPending || nState == knExists || nState == knDoesNotExist || nState == knExistsAndIsSpecial);
			Debug.Assert(fKnownState, "Trying to set user state to unknown state: " + nState);
			return fKnownState ? nState : knUnknown;
		}

		protected var _obDict:Object = new Object();

		// Call this when we know the state
		public function SetExists(strVal:String, fExists:Boolean): void {
			SetState(strVal, fExists ? knExists : knDoesNotExist);
		}

		public function SetState(strVal:String, nState:Number): void {
			nState = CleanState(nState);
			if (GetState(strVal) != nState) {
				_obDict[strVal] = nState;
				dispatchEvent(new Event(Event.CHANGE));
			}
		}

		// Get the state. Returns whatever we know. Does not trigger more investigation.
		public function GetState(strVal:String): Number {
			if (strVal in _obDict) {
				return _obDict[strVal];
			} else {
				return knUnknown;
			}
		}

		// Returns the current state - but may trigger offline investigation (e.g. lookup in db)
		// Will return pending rather than unknown (because we are not looking up the state)
		public function LookupState(strVal:String, fDeepLookup:Boolean = true): Number {
			var nState:Number = GetState(strVal);
			if (fDeepLookup) {
				if (nState == knUnknown || nState == knPending) {
					LookupStateElsewhere(strVal);
					nState = knPending;
				}
			}
			return nState;
		}

		// Clear out the dictionary.  Use this instead of replacing a PicnikDict-derived
		// object with a new empty copy -- some of the validators may reference the object, so
		// it's best to keep the object and reset its' contents.
		public function ResetState(): void {
			_obDict = new Object();
		}
	}
}