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
	import overlays.helpers.RGBColor;
	import imagine.imageOperations.PaletteMapImageOperation;
	
	[RemoteClass]
	public class MultiColorImageOperation extends PaletteMapImageOperation
	{
		private var _aColors:Array = [0xFF0000, 0x00FF00, 0x0000FF];		
		private var _nBaseChannel:Number = BitmapDataChannel.RED;
		private var _nSpread:Number = 0;
		
		public function MultiColorImageOperation()
		{
			super();
			_calcArrays();
		}
		
		public function set BaseDataChannel(n:Number): void {
			if (_nBaseChannel == n)
				return;
			
			Debug.Assert(_nBaseChannel == BitmapDataChannel.RED || _nBaseChannel == BitmapDataChannel.GREEN || _nBaseChannel == BitmapDataChannel.BLUE);

			_nBaseChannel = n;
			_calcArrays();
		}

		public function set Spread(n:Number): void {
			if (_nSpread == n)
				return;
			_nSpread = n;
			_calcArrays();
		}

		public function set Colors(clrs:Array): void {
			_aColors = clrs;
			_calcArrays();
		}
		
		private function _calcArrays(): void {
			var anPrimary:Array = new Array(256);
			var anZeroes:Array = new Array(256);
									
			var nSegments:int = _aColors.length * 2 - 1;
			var nSegLength:int = 256/_aColors.length;
			var i:int = 0;
			
			for (var iSeg:int = 0; iSeg < nSegments; iSeg++ ){
				var nThisSegLength:int = nSegLength;
				if (iSeg % 2 == 0) {
					if (iSeg == nSegments - 1) {
						nThisSegLength = 256 - i;
					} else {
						nThisSegLength = Math.round((1-_nSpread) * nThisSegLength);
					}
				} else {
					nThisSegLength = Math.round(_nSpread * nThisSegLength);
					if (iSeg == 1) {
						nThisSegLength += nThisSegLength / 2;
					}
					if (iSeg == nSegments-2) {
						nThisSegLength += nThisSegLength / 2;
					}
				}
				for (var iPixel:int = 0; iPixel < nThisSegLength; iPixel++) {
					var iColor:uint = Math.floor(iSeg/2);
					var nClrR:Number = RGBColor.RedFromUint(_aColors[iColor]);
					var nClrG:Number = RGBColor.GreenFromUint(_aColors[iColor]);
					var nClrB:Number = RGBColor.BlueFromUint(_aColors[iColor]);
																
					if (iSeg % 2 == 1) {
						var nRatio:Number = iPixel / nThisSegLength;
						nClrR = nClrR * (1-nRatio) + RGBColor.RedFromUint(_aColors[iColor+1]) * nRatio;					
						nClrG = nClrG * (1-nRatio) + RGBColor.GreenFromUint(_aColors[iColor+1]) * nRatio;
						nClrB = nClrB * (1-nRatio) + RGBColor.BlueFromUint(_aColors[iColor+1]) * nRatio;
					}
					anPrimary[i] = RGBColor.RGBtoUint(nClrR, nClrG, nClrB);
					i++;
				}
			}
			
			// Zero everything
			this.Reds = anZeroes;
			this.Greens = anZeroes;
			this.Blues = anZeroes;
			
			// Now set the primary channel
			if (_nBaseChannel == BitmapDataChannel.BLUE)
				this.Blues = anPrimary;
			else if (_nBaseChannel == BitmapDataChannel.GREEN)
				this.Greens = anPrimary;
			else
				this.Reds = anPrimary;
		}		
	}
}