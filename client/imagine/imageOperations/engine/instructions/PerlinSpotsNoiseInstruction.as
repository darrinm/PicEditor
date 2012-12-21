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
package imagine.imageOperations.engine.instructions
{
	import flash.geom.Point;
	
	import imagine.imageOperations.PerlinSpotsImageOperation;
	
	public class PerlinSpotsNoiseInstruction extends PerlinNoiseInstruction
	{
		private var _nQuality:Number;
		private var _nPixelation:Number;
		
		public function PerlinSpotsNoiseInstruction(nQuality:Number, nPixelation:Number, xBase:Number, yBase:Number, cOctaves:Number, nSeed:Number, fStitch:Boolean, fFractal:Boolean, nChannels:Number)
		{
			super(xBase, yBase, cOctaves, nSeed, fStitch, fFractal, nChannels);
			
			_nQuality = nQuality;
			_nPixelation = nPixelation;
			key += ":" + _nQuality + ":" + _nPixelation;
		}

		override protected function CalculateNoiseSize(ptOrigSize:Point): Point {
			var nTargetWidth:Number = Math.ceil((ptOrigSize.x / _nPixelation));
			var nTargetHeight:Number = Math.ceil((ptOrigSize.y / _nPixelation));
			
			if (_nPixelation < 1) {
				// Even multiple of two if we are sizing down.
				nTargetWidth = Math.ceil(nTargetWidth * _nPixelation) / _nPixelation;
				nTargetHeight = Math.ceil(nTargetHeight * _nPixelation) / _nPixelation;
			}
			
			if (_nQuality == PerlinSpotsImageOperation.QUALITY_AUTO) {
				nTargetWidth = Math.min(2400, nTargetWidth);
				nTargetHeight = Math.min(2400, nTargetHeight);
			} else {
				// TODO: Add support for different quality levels
				throw new Error("Not yet implemented: perlin spots quality == " + _nQuality);
			}
			return new Point(nTargetWidth, nTargetHeight);
		}
		
		override protected function CalculateBase(ptOrigSize:Point, ptBase:Point): Point {
			var nAverageSize:Number = (ptOrigSize.x + ptOrigSize.y) / 2;
			var xScale:Number = ptBase.x * nAverageSize / _nPixelation;
			var yScale:Number = ptBase.y * nAverageSize / _nPixelation;

			return new Point(xScale, yScale);
		}
	}
}