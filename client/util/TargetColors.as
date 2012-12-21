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
	import flash.utils.Dictionary;
	
	import imagine.ImageDocument;
	
	import overlays.helpers.RGBColor;
	
	public class TargetColors
	{
		private static const knBrightness:Number = 60;
		private static const knSaturation:Number = 100;
		private static const kanHues:Array = [80, 160, 190, 210, 230, 280, 310, 360, 30, 60];
		
		private static var _dctMapDocToIndex:Dictionary = new Dictionary();
		
		public static function GetNextColor(imgd:ImageDocument): Number
		{
			var nNextIndex:Number = 0;
			if (imgd in _dctMapDocToIndex)
				nNextIndex = _dctMapDocToIndex[imgd];
			
			// Clean up our index
			if (isNaN(nNextIndex) || nNextIndex < 0 || nNextIndex >= kanHues.length) nNextIndex = 0;
			nNextIndex = Math.round(nNextIndex);
			
			var nHue:Number = kanHues[nNextIndex];
			
			var nColor:Number = RGBColor.HSVtoUint(nHue, knSaturation, knBrightness);
			
			// Get ready for next time
			nNextIndex++;
			if (nNextIndex >= kanHues.length) nNextIndex = 0;
			_dctMapDocToIndex[imgd] = nNextIndex;
			
			return nColor;
		}

	}
}