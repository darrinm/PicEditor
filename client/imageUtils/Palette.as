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
	public class Palette {
		private var _achnl:Array;
	
		public function Palette(cchnl:Number = 3) {
			_achnl = new Array();
			for (var ichnl:Number = 0; ichnl < cchnl; ichnl++) {
				var chnl:Channel = new Channel(256);
				for (var i:Number = 0; i < 256; i++)
					chnl[i] = i;
				_achnl[ichnl] = chnl;
			}
		}
		
		public function AdjustBrightness(nOffset:Number):void {
			if (nOffset == 0)
				return;
				
			for (var ichnl:Number = 0; ichnl < _achnl.length; ichnl++) {
				Channel(_achnl[ichnl]).AdjustBrightness(nOffset);
			}
		}
		
		public function AdjustContrast(nMultiplier:Number, nMidValue:Number):void {
			if (nMultiplier == 1.0)
				return;
				
			for (var ichnl:Number = 0; ichnl < _achnl.length; ichnl++) {
				Channel(_achnl[ichnl]).AdjustContrast(nMultiplier, nMidValue);
			}
		}
		
		public function AdjustExposure(nExposure:Number, nMin:Number, nMax:Number):void {
			for (var ichnl:Number = 0; ichnl < _achnl.length; ichnl++) {
				Channel(_achnl[ichnl]).AdjustExposure(nExposure, nMin, nMax);
			}
		}
		
		public function Clamp(nMin:Number = 0, nMax:Number = 255):void {
			for (var ichnl:Number = 0; ichnl < _achnl.length; ichnl++) {
				Channel(_achnl[ichnl]).Clamp(nMin, nMax);
			}
		}
		
		public function GetPaletteMapArrays():Array {
			Debug.Assert(_achnl.length == 3, "GetPaletteMapArrays requires Palette to have exactly 3 channels");
			for (var ichnl:Number = 0; ichnl < _achnl.length; ichnl++) {
				if (_achnl[ichnl].length != 256) {
					Debug.Assert(false, "GetPaletteMapArrays requires Palette Channels to have exactly 256 elements");
				}
			}
	
			var chnlRed:Channel = _achnl[0];
			var chnlGreen:Channel = _achnl[1];
			var chnlBlue:Channel = _achnl[2];
			
			var mpcoRed:Array = new Array();
			var mpcoGreen:Array = new Array();
			var mpcoBlue:Array = new Array();
			
			for (var i:Number = 0; i < 256; i++) {
				mpcoRed[i] = chnlRed[i] << 16;
				mpcoGreen[i] = chnlGreen[i] << 8;
				mpcoBlue[i] = chnlBlue[i];
			}
			
			return new Array(mpcoRed, mpcoGreen, mpcoBlue);
		}
		
		public function get channels(): Array {
			return _achnl;
		}
	}
}