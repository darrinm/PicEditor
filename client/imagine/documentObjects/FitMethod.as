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
package imagine.documentObjects
{
	public class FitMethod
	{
		public static const SNAP_TO_EXACT_SIZE:Number = 0; // Set the width and height to the dimensions passed in - may distort aspect ratio
		public static const SNAP_TO_AREA:Number = 1; // Make the area the same as the dimensions passed in. Maintains aspect ratio.
		public static const SNAP_TO_MIN_WIDTH_HEIGHT:Number = 2; // Make the height and width at least as big as the dimension passed in. Maintains aspect ratio.
		public static const SNAP_TO_MAX_WIDTH_HEIGHT:Number = 3; // Make the height and width at most as big as the dimension passed in. Maintains aspect ratio.
	}
}