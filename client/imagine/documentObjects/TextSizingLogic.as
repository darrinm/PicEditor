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
package imagine.documentObjects {
	public class TextSizingLogic {
		// Changes to the object's text property cause the object's bounding box to change.
		// Changes to the object's bounds cause the apparent font size to change to fit the box.
		// Changes to the object's fontSize cause the box size to change to fit the font.
		public static const DYNAMIC_BOX:String = "dynamic_box";

		// Changes to the object's text property cause the apparent font size to change.
		// Changes to the object's bounds cause the apparent font size to change to fit the box.
		// Changes to the object's fontSize cause the box size to change to fit the font.
		public static const FIXED_BOX_DYNAMIC_FONT:String = "fixed_box_dynamic_font";

		// Changes to the object's text property don't make any changes to the object's
		// bounding box or apparent font size. This works well in cunjunction with
		// wordWrap=true.
		// Changes to the object's fontSize have no effect on the object's box.
		// Changes to the object's bounds (e.g. MoveSizeRotate controller) have no effect
		// on the object's apparent font size.
		// Changes to the object's scale (e.g. Resize) proportionally scale the apparent
		// size of the font.
		public static const FIXED_BOX_FIXED_FONT:String = "fixed_box_fixed_font";
	}
}
