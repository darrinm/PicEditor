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
	// A Channel is an array of numbers. Typically a Channel represents the intensity
	// values of one channel (e.g. red, green, blue, alpha) of an image but it could
	// also represent combined luminosity, saturation or anything else that its operations
	// make sense for. Channel values are kept as floating point so precision is not
	// lost across multiple operations.
	//
	// NOTE: Many of Channel's methods are biased or only able to work with and return
	// values in the range from 0 to 255.
	
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import util.VBitmapData;

	public dynamic class Channel extends Array {
		public static var kichnlRed:Number = 0;
		public static var kichnlGreen:Number = 1;
		public static var kichnlBlue:Number = 2;
		public static var kichnlRGB:Number = 3;
		public static var kichnlIntensity:Number = 4;
		public static var kichnlMax:Number = 5;
		
		private var _nMedian:Number = 0;
		private var _fHasMedian:Boolean = false;
		
		public function Channel(nSize:Number = 0) {
			super(nSize);
		}
		
		public function Clone():Channel {
			var chnl:Channel = new Channel(length);
			chnl._nMedian = _nMedian;
			chnl._fHasMedian = _fHasMedian;
			for (var i:Number = 0; i < length; i++)
				chnl[i] = this[i];
			return chnl;
		}
		
		public function SetIdentityMapping():void {
			for (var i:Number = 0; i < length; i++)
				this[i] = i;
		}
		
		// Increase/descrease brightness by shifting all values up or down
		// nOffset can be any value
		public function AdjustBrightness(nOffset:Number):void {
			if (nOffset == 0)
				return;
				
			for (var i:Number = 0; i < this.length; i++)
				this[i] += nOffset;
		}
	
		// Increase/decrease contrast by multiplying all values after first shifting
		// them to a mid value, then back.
		// nMultiplier can be any floating point value. nMidValue must be in the range 0-255
		public function AdjustContrast(nMultiplier:Number, nMidValue:Number = 127):void {
	//		trace("Channel.AdjustContrast: nMultiplier: " + nMultiplier + ", nMidValue: " + nMidValue);
			if (nMultiplier == 1.0)
				return;
				
			for (var i:Number = 0; i < this.length; i++)
				this[i] = ((this[i] - nMidValue) * nMultiplier) + nMidValue + 0.5;
		}
	
		// Stretch the values to fill the range 0-255
		// For proper results, channel values should be within the range of nMin, nMax
		public function StretchLevels(nMin:Number, nMax:Number):void {
			Debug.Assert(nMin <= nMax, "StretchLevels: nMin must be less than or equal to nMax")
			for (var i:Number = 0; i < this.length; i++)
				this[i] = ((this[i] - nMin) / (nMax - nMin)) * 255.0 + 0.5;
		}
	
		// AdjustExposure produces output values in the range 0-255
		// nExposure is in the range 0-255
		// nMin, nMax are in the range 0-255. nMin must be less than or equal to nMax.
		public function AdjustExposure(nExposure:Number, nMin:Number = 0, nMax:Number = 255):void {
			Debug.Assert(nMin <= nMax, "AdjustExposure: nMin must be less than or equal to nMax")
	//		trace("Channel.AdjustExposure: nExposure: " + nExposure + ", nMin: " + nMin + ", nMax: " + nMax);
			//nExposure = (nMax - nExposure) + nMin;
				
			var nDelta:Number = (nMax - nMin) / 2;
			var nMid:Number = nMin + nDelta;
			var nGammaInverse:Number = Math.pow(10, (nExposure - nMid) / nDelta);
	//		trace("nGammaInverse: " + nGammaInverse);
	
			for (var i:Number = 0; i < this.length; i++) {
				this[i] = Math.pow(i / 255.0, nGammaInverse) * 255.0 + 0.5;
				// Stretch
				this[i] = ((this[i] - nMin) / (nMax - nMin)) * 255.0 + 0.5;
			}
		}
	
		// AdjustGamma produces output values in the range 0-255
		// nGamma is in the range 0.1-10.0 (values < 1.0 brighten, values > 1.0 darken)
		// nMin, nMax are in the range 0-255. nMin must be less than or equal to nMax.
		public function AdjustGamma(nGamma:Number):void {
			for (var i:Number = 0; i < this.length; i++) {
				this[i] = Math.pow(this[i] / 255.0, nGamma) * 255.0 + 0.5;
			}
		}
	
		// Clamp all values of the Channel to be integers within the nMin, nMax range
		public function Clamp(nMin:Number = 0, nMax:Number = 255):void {
			Debug.Assert(nMin <= nMax, "Channel.Clamp nMin must be <= nMax");
				
			for (var i:Number = 0; i < length; i++) {
				var n:Number = int(this[i] + 0.5);
				if (n < nMin)
					this[i] = nMin;
				else if (n > nMax)
					this[i] = nMax;
				else
					this[i] = n;
			}
		}
	
		// Produce an array of RGB mapping values corresponding to the Channel values
		// and the requested color channel (R, G or B)
		// The returned array is for passing to the PaletteMapImageOperation
		public function GetPaletteMapArray(ichnl:Number):Array {
			Debug.Assert(length == 256, "GetPaletteMapArray requires Channel to have exactly 256 elements");
	
			var mpco:Array = new Array();
			
			var nShift:Number = 0;
			switch (ichnl) {
			case Channel.kichnlRed:
				nShift = 16;
				break;
				
			case Channel.kichnlGreen:
				nShift = 8;
				break;
			
			default:
				nShift = 0;
				break;
			}
			
			for (var i:Number = 0; i < length; i++)
				mpco[i] = this[i] << nShift;
				
			return mpco;
		}
	
		// GetMedian returns the median of the Channel. This makes sense for Channels where each
		// element is a count (e.g. histograms)
		public function GetMedian():Number {
			if (_fHasMedian)
				return _nMedian;
				
			// First get a total count of pixels
			var cPixelsTotal:Number = 0;
			for (var j:Number = 0; j < 256; j++)
				cPixelsTotal += this[j];
			
			// Now count our way up until twice our count exceeds the total
			var cPixels:Number = 0;
			for (var i:Number = 0; i < 256; i++) {
				cPixels += this[i];
				if (cPixels * 2 >= cPixelsTotal) {
					_nMedian = i;
	//				trace("_nMedian: " + _nMedian + ", cPixelsTotal: " + cPixelsTotal + ", cPixels: " + cPixels);
					break;
				}
			}
			
			_fHasMedian = true;
			
			return _nMedian;
		}
		
		
		// Remap the values of 'this' Channel via the mapping specified by the
		// passed-in Channel. Unmapped values, i.e. those not represented in
		// chnlMap, are set to nUnmapped.
		public function Remap(chnlMap:Channel, nUnmapped:Number = 0):void {
			var chnlUnmapped:Channel = Clone();
				
			// Initialize mapped channel to the 'unmapped' value
			for (var i:Number = 0; i < 256; i++)
				this[i] = nUnmapped;
					
			for (var j:Number = 0; j < 256; j++) {
				var iMapped:Number = chnlMap[j];
				this[iMapped] += chnlUnmapped[j];
			}
	
			_fHasMedian = false;
			_nMedian = 0;
		}
	
		// GetMinMax assumes the Channel has 256 elements
		public function GetMinMax(nClipMin:Number = 0, nClipMax:Number = 0):Object {
			// First get a total count of pixels
			var cPixelsMax:Number = 0;
			for (var i:Number = 0; i < 256; i++)
				cPixelsMax += this[i];
				
			// find the lowest level used
			var cPixels:Number = 0;
			var iLevelMin:Number;
			for (iLevelMin = 0; iLevelMin < 256; iLevelMin++) {
				cPixels += this[iLevelMin];
				if (cPixels / cPixelsMax * 100 > nClipMin) {
	//				trace("nMin: " + iLevelMin + ", cPixels: " + cPixels + ", cPixelsMax: " + cPixelsMax + ", percentile: " + (cPixels / cPixelsMax * 100));
					break;
				}
			}
			
			// find the highest level used
			cPixels = 0;
			var iLevelMax:Number;
			for (iLevelMax = 255; iLevelMax >= 0; iLevelMax--) {
				cPixels += this[iLevelMax];
				if (cPixels / cPixelsMax * 100 > nClipMax) {
	//				trace("nMax: " + iLevelMax + ", cPixels: " + cPixels + ", cPixelsMax: " + cPixelsMax + ", percentile: " + (cPixels / cPixelsMax * 100));
					break;
				}
			}
	
			return { min: iLevelMin, max: iLevelMax };
		}
		
		// Draw the Channel as a histogram of the requested dimensions and color
		// into a BitmapData. The BitmapData is transparent everywhere no histogram
		// values are presented
		public function Draw(cx:Number, cy:Number, co:Number = 0xff000000):BitmapData {
			// Find the peak histogram element
			var cPixelsMax:Number = 0;
			var cPeaks:Number = 0;
			var cPixelsTotal:Number = 0;
			for (var i:Number = 0; i < 256; i++) {
				var cPixels:Number = this[i];
				if (cPixels > cPixelsMax)
					cPixelsMax = cPixels;
				if (cPixels > 0) {
					cPeaks++;
					cPixelsTotal += cPixels;
				}
			}
			
			// Voodoo to keep the histogram from being squashed by excessive peaks
			// UNDONE: not good enough
			var cPixelsAvg:Number = cPixelsTotal / cPeaks;
			if (cPixelsMax > cPixelsAvg * 4)
				cPixelsMax = cPixelsAvg * 4;
			
			var bmd:BitmapData = new VBitmapData(cx, cy, true, 0x00000000);
			var rc:Rectangle = new Rectangle(0, 0, 1, cy);
			for (var j:Number = 0; j < cx; j++) {
				var jX:Number;
				if (cx <= 1) jX = 0;
				else jX = Math.round(j * 255 / (cx -1) );
				var cyColumn:Number = Math.round((this[jX] / cPixelsMax) * cy);
				rc.x = j;
				rc.y = 0;
				rc.y = cy - cyColumn;
				rc.height = cyColumn;
				bmd.fillRect(rc, co);
			}
			
			return bmd;
		}
	}
}