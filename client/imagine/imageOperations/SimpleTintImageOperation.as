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
package imagine.imageOperations
{
	import flash.display.BitmapDataChannel;
	
	import imagine.imageOperations.PaletteMapImageOperation;
	import imagine.imageOperations.TintImageOperation;
	
	/**
	 *  The SimpleTintImageOperation is a tint which considers only a single
	 *  base data channel rather than using the luminosity. This is useful
	 *  for cases where we do not need to do the pre-map desaturation -
	 *  because we already have a color channel we can use for our luminosity.
	 * 
	 *  As a result, it is a bit faster than Tint.
	 */
	[RemoteClass]
	public class SimpleTintImageOperation extends PaletteMapImageOperation
	{
		private var _clr:Number = 0xddc9ae; // Sepia
		
		private var _nBaseChannel:Number = BitmapDataChannel.BLUE;
		
		public function SimpleTintImageOperation()
		{
			super();
			CalcArrays();
		}
		
		public function set BaseDataChannel(n:Number): void {
			if (_nBaseChannel == n)
				return;
			
			Debug.Assert(_nBaseChannel == BitmapDataChannel.RED || _nBaseChannel == BitmapDataChannel.GREEN || _nBaseChannel == BitmapDataChannel.BLUE);

			_nBaseChannel = n;
			CalcArrays();
		}

		public function set Color(clr:Number): void {
			if (_clr != clr) {
				_clr = clr;
				CalcArrays();
			}
		}
		
		private function CalcArrays(): void {
			TintImageOperation.CalcTintArrays(this, _clr, _nBaseChannel);
		}
	}
}