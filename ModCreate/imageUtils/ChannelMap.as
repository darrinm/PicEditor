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
package imageUtils
{
	public class ChannelMap
	{
		// Channel map is used to hold level values.
		
		/* ???
		[Bindable] public var histOut:Histogram;
		[Bindable] public var histIn:Histogram;
		*/
		
		// Focus first on controls
		
		// In levels
		private var _nMinIn:Number = 0; // whole numbers, < _nMaxIn
		private var _nMaxIn:Number = 255; // whole numbers, > _nMinIn
		
		// Out levels
		private var _nMinOut:Number = 0; // whole numbers, < _nMaxOut
		private var _nMaxOut:Number = 255; // whole numbers, > _nMinOut
		private var _nMid:Number = 0.5; // Used to calculate gamma
		
		private var knLog127Over255:Number = Math.log(127/255);
		
		public function Reset(): void {
			_nMinOut = 0;
			_nMaxOut = 255;
			_nMid = 0.5;
			_nMinIn = 0;
			_nMaxIn = 255;
			invalidateLevels();
		}
		
		// Given a midpoint, we can calculate gamma as follows:
		[Bindable]
		public function set midPoint(nMid:Number): void {
			invalidateLevels();
			_nMid = nMid;
		}
		
		public function get midPoint(): Number {
			return _nMid;
		}
		
		[Bindable]
		public function set inMin(n:Number): void {
			invalidateLevels();
			_nMinIn = n;
		}
		public function get inMin(): Number {
			return _nMinIn;
		}
		
		[Bindable]
		public function set inMax(n:Number): void {
			invalidateLevels();
			_nMaxIn = n;
		}
		public function get inMax(): Number {
			return _nMaxIn;
		}
		
		[Bindable]
		public function set outMin(n:Number): void {
			invalidateLevels();
			_nMinOut = n;
		}
		public function get outMin(): Number {
			return _nMinOut;
		}
		
		[Bindable]
		public function set outMax(n:Number): void {
			invalidateLevels();
			_nMaxOut = n;
		}
		public function get outMax(): Number {
			return _nMaxOut;
		}
		
		// nMid is in the range of 0 to 1
		// nGamma is in the range of 0.1 to 10
		public static function midToGamma(nMid:Number): Number {
			var nGamma:Number = Math.pow(10, 2 * nMid - 1);
			return Math.min(Math.max(nGamma, 0.1), 10);
		}
		
		private function get gamma(): Number {
			return Math.pow(Math.E, knLog127Over255 / midPoint);
		}

		// Given nGamma, we can calculate midPoint as follows:
		private function set gamma(nGamma:Number): void {
			midPoint = knLog127Over255 / Math.log(nGamma);
		}
		
		private function invalidateLevels(): void {
		}
		
		// Map from one color to another
		public function map(n:Number, fRound:Boolean=true): Number {
			var nIn:Number = n;
			
			// First, convert n to new range based on in levels
			n = (n - _nMinIn) / (_nMaxIn - _nMinIn); // n goes from 0 to 1
			
			// Now apply our gamma
			// First, calculate gamma
			
			var nGamma:Number = midToGamma(_nMid);
			n = Math.pow(n, nGamma);

			// n is in the range of 0 to 1. Now shift it to outMin, outMax
			n = _nMinOut + n * (_nMaxOut - _nMinOut);
			if (n > _nMaxOut) n = _nMaxOut;
			else if (n < _nMinOut) n = _nMinOut;
			
			if (fRound) n = Math.round(n);
			return n;
		}
	}
}