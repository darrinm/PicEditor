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
package controls
{
	import flash.events.Event;
	
	import imageUtils.SimpleHistogram;
	
	import mx.core.UIComponent;
	
	import overlays.helpers.RGBColor;
	
	public class RGBLHistogramView extends UIComponent
	{
		private var _hist:SimpleHistogram = null;
  		private const kclrR:uint = 0xeb0707;
		private const kclrG:uint = 0x47e807;
		private const kclrB:uint = 0x004df2;

		private  const kaclrs:Array = [kclrR,kclrG,kclrB];

		private  var _clrLine:uint = 0xe0e0e0; // Color of the base line
		private var _fHistValid:Boolean = false;
		private var _ahist:Array = null;
		private var _nClipMax:Number = 1;

		public function set histogram(hist:SimpleHistogram): void {
			histograms = [hist];
			invalidateHist();
		}
		
		public function set clipMax(n:Number): void {
			_nClipMax = n;
			invalidateHist();
		}
		
		public function set lineColor(n:Number): void {
			_clrLine = n;
			invalidateHist();
		}
		
		public function set histograms(ahist:Array): void {
			var i:Number;
			if (_ahist) {
				for (i = 0; i < _ahist.length; i++) {
					(_ahist[i] as SimpleHistogram).removeEventListener("change", OnHistChange);
				}
			}
			_ahist = ahist;
			if (_ahist) {
				for (i = 0; i < _ahist.length; i++) {
					(_ahist[i] as SimpleHistogram).addEventListener("change", OnHistChange);
				}
			}
			invalidateHist();
		}
		
		public function invalidateHist(): void {
			_fHistValid = false;
			invalidateDisplayList();
		}
		
		private function AverageHist(nChannel:Number, iStart:Number, iEnd:Number): Number {
			if (iStart > iEnd) iStart = iEnd;
			var an:Array = (_ahist[nChannel] as SimpleHistogram).array;
			var nTot:Number = 0;
			for (var i:Number = iStart; i <= iEnd; i++) {
				nTot += an[i];
			}
			return nTot / (1 + iEnd - iStart);
		}
		
		// Combine two colors by taking their average HSV value
		protected function CombineColors(clr1:uint, clr2:uint): uint {
			var obHSV1:Object = RGBColor.Uint2HSV(clr1);
			var obHSV2:Object = RGBColor.Uint2HSV(clr2);
			
			// Make sure we wrap around the right direction
			if (obHSV1.h > obHSV2.h) {
				if ((obHSV1.h - obHSV2.h) > 180) {
					obHSV2.h += 360;
				}
			} else {
				if ((obHSV2.h - obHSV1.h) > 180) {
					obHSV1.h += 360;
				}
			}
			var nH:Number = (obHSV1.h + obHSV2.h) / 2;
			while (nH > 360) nH -= 360;
			
			var nS:Number = (obHSV1.s + obHSV2.s) / 2;
			var nV:Number = (obHSV1.v + obHSV2.v) / 2;
			
			return RGBColor.HSVtoUint(nH, nS, nV);
		}
		
		protected function drawHist(): void {
			//trace("drawHist: " + height + ", " + width);
			// Background
			graphics.clear();
			
			// Interior
			if (_ahist != null) {
				// Multi-channel histogram
				var iprev:Number = -1;
				var i:Number;
				var j:Number;
				var x:Number;
				var aob:Array = [];
				
				for (x = 0; x < width; x++) {
					i = Math.round((x+1) * 256 / width) - 1;
					// Take the average of points from i to iprev
					for (j = 0; j < _ahist.length; j++) {
						aob[j] = {'clr':kaclrs[j],'val':AverageHist(j, iprev+1, i)};
					}
					iprev = i;
					
					aob.sortOn('val', Array.NUMERIC | Array.DESCENDING); // Sort the largest val to the first element
					
					// Set the correct colors
					aob[aob.length-1].clr = _clrLine;
					if (aob.length > 2) {
						aob[1].clr = CombineColors(aob[1].clr, aob[0].clr);
					}
					
					// Start with lum
					graphics.moveTo(x, mapy(0));
					// graphics.moveTo(x, height);
					for (j = aob.length-1; j >= 0; j--) {
						graphics.lineStyle(1, aob[j].clr, 1, false);
						graphics.lineTo(x, mapy(aob[j].val));
					}
				}
			}
		}

		private function mapy(n:Number): Number {
			if (n > _nClipMax) n = _nClipMax;
			return Math.round(height - n * height / _nClipMax);
		}
		
		private function validateHist(): void {
			if (!_fHistValid) {
				drawHist();
				_fHistValid = true;
			}
		}
		
		public function VisualHistogram(): void {
		}
		
		public override function set width(value:Number):void {
			super.width = value;
			invalidateHist();
		}
		
		public override function set height(value:Number):void {
			super.height = value;
			invalidateHist();
		}
		
		protected function OnHistChange(evt:Event): void {
			invalidateHist();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number): void {
			validateHist();
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		protected override function measure():void {
			super.measure();
			measuredMinHeight = 10;
			measuredMinWidth = 10;
			measuredWidth = 256;
			measuredHeight = 100;
		}
	}
}