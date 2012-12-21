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
	
	public class PerlinSpotsCreateBitmapInstruction extends CreateBitmapInstruction
	{
		private var _nPixelation:Number;
		
		public function PerlinSpotsCreateBitmapInstruction(nPixelation:Number, fTranparent:Boolean, clrFill:Number)
		{
			super(fTranparent, clrFill, 1);
			_nPixelation = nPixelation;
			key += ":" + _nPixelation;
		}

		override protected function CalculateSize(ptOrigSize:Point): Point {
			var ptOperatingSize:Point;
			if (_nPixelation < 1)
				ptOperatingSize = ptOrigSize;
			else
				ptOperatingSize = new Point(Math.ceil(ptOrigSize.x / _nPixelation), Math.ceil(ptOrigSize.y / _nPixelation));
			
			return ptOperatingSize; // override in sub-classes as needed. See PerlinSpotsNoiseInstruction
		}
		
	}
}