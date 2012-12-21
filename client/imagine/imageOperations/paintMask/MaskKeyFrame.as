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
package imagine.imageOperations.paintMask
{
	import flash.display.BitmapData;
	
	public class MaskKeyFrame
	{
		public var bitmapData:BitmapData;
		public var depth:Number;
		public var maxAge:Number;
		
		public function MaskKeyFrame(bmd:BitmapData, nDepth:Number, nMaxAge:Number)
		{
			if (bmd == null) throw new Error("null key frame not allowed");
			bitmapData = bmd;
			depth = nDepth;
			maxAge = nMaxAge;
		}
		
		public function Dispose(): void {
			bitmapData.dispose();
			bitmapData = null;
			depth = -1;
		}
	}
}