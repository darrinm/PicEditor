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
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.engine.OpStateMachine;
	
	import util.VBitmapData;
	
	public class PerlinNoiseInstruction extends OpInstruction
	{
		protected var _xBase:Number;
		protected var _yBase:Number;
		private var _cOctaves:Number;
		private var _nSeed:Number;
		private var _fStitch:Boolean;
		private var _fFractal:Boolean;
		private var _nChannels:Number;
		
		public function PerlinNoiseInstruction(xBase:Number, yBase:Number, cOctaves:Number, nSeed:Number, fStitch:Boolean, fFractal:Boolean, nChannels:Number)
		{
			super();
			
			_xBase = xBase;
			_yBase = yBase;
			_cOctaves = cOctaves;
			_nSeed = nSeed;
			_fStitch = fStitch;
			_fFractal = fFractal;
			_nChannels = nChannels;
			
			key = xBase + ":" + yBase + ":" + cOctaves + ":" + nSeed + ":" + fStitch + ":" + fFractal + ":" + nChannels;
		}
		
		protected function CalculateNoiseSize(ptOrigSize:Point): Point {
			return ptOrigSize; // override in sub-classes as needed. See PerlinSpotsNoiseInstruction
		}
		
		protected function CalculateBase(ptOrigSize:Point, ptBase:Point): Point {
			return ptBase; // override in sub-classes as needed. See PerlinSpotsNoiseInstruction
		}
		
		public override function Execute(opsmc:OpStateMachine):void {
			var bmdOrig:BitmapData = BitmapReference(opsmc.bitmapStack[opsmc.bitmapStack.length-1])._bmd;
			var ptOrigSize:Point = new Point(bmdOrig.width, bmdOrig.height);
			var ptNoiseSize:Point = CalculateNoiseSize(ptOrigSize);
			var ptBase:Point = CalculateBase(ptOrigSize, new Point(_xBase, _yBase));
			
			var bmdNoise:BitmapData = VBitmapData.Construct(ptNoiseSize.x, ptNoiseSize.y, true);
			bmdNoise.perlinNoise(ptBase.x, ptBase.y, _cOctaves, _nSeed, _fStitch, _fFractal, _nChannels, false);
			PushBitmap(opsmc, bmdNoise);
		}
	}
}