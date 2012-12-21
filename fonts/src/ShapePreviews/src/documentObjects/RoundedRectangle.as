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
package documentObjects
{
	public class RoundedRectangle extends RoundedSquare
	{
		public override function get typeName(): String {
			return "Rounded Rectangle";
		}
		
		public function RoundedRectangle(nRoundedPct:Number = 0.4) {
			super(nRoundedPct);
		}

		public function get defaultScaleY():Number {
			return 0.7;
		}

		// Return false to make default drag behavior not lock aspect ratio
		public function get hasFixedAspectRatio(): Boolean {
			return false;
		}
	}
}