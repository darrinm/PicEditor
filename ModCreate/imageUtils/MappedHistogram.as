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
	public class MappedHistogram extends SimpleHistogram
	{
		private var _anOriginal:Array = null;
		
		public function apply(chmap:ChannelMap): void {
			if (!_anOriginal) _anOriginal = _an.slice();
			var an:Array = [];
			var i:Number;
			// Start empty
			for (i = 0; i < 256; i++) {
				an.push(0);
			}
			// Now map values across.
			for (i = 0; i < 256; i++) {
				var i2:Number = chmap.map(i);
				if (i2 < 0) i2 = 0;
				if (i2 > 255) i2 = 255;
				an[i2] += _anOriginal[i];
			}
			_setArray(an);
		}

		public override function setArray(an:Array): void {
			_anOriginal = an.slice();
			_setArray(an);
		}
	}
}