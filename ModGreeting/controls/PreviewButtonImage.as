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
package controls {
	import flash.filters.GlowFilter;

	public class PreviewButtonImage extends PosterButtonImage {
		override protected function get mouseOverGlow(): GlowFilter {
			return new GlowFilter(0x4c99bf, .7, 5, 5, 2, 3);
		}
		
		override protected function get selectedGlow(): GlowFilter {
			return new GlowFilter(0x4c99bf, .8, 8, 8, 2, 3);
		}
	}
}
