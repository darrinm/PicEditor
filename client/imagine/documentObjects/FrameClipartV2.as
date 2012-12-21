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
	import imagine.documentObjects.frameObjects.ClipartLoader;
	
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	
	import overlays.helpers.RGBColor;
	
	import util.FilterParser;

	public class FrameClipartV2 extends Sprite
	{
		public function FrameClipartV2()
		{
			super();
		}
		
		public var myFilters:Array = [];
		
		public function Clear(): void {
			filters = [];
			while (numChildren > 0)
				removeChildAt(numChildren-1);
		}
		
		public function SetParams(ldr:ClipartLoader, obShape:Object): void {
			Clear();
			addChild(ldr);
			for (var strKey:String in obShape) {
				if (strKey in this) {
					if (strKey == 'filters')
						this.myFilters = obShape.filters;
					else
						this[strKey] = obShape[strKey];
				}
			}
			ldr.x = -obShape['cWidth']/2;
			ldr.y = -obShape['cHeight']/2;
			
			if ('color' in obShape) {
				var nR:Number = RGBColor.RedFromUint(obShape.color);
				var nG:Number = RGBColor.GreenFromUint(obShape.color);
				var nB:Number = RGBColor.BlueFromUint(obShape.color);
				transform.colorTransform =
					new ColorTransform((255 - nR)/255, (255-nG)/255, (255-nB)/255, 1, nR, nG, nB);
			} else {
				transform.colorTransform = null;
			}
			
			// I'm not sure why we need this, but without, alpha doesn't work.
			if ('alpha' in obShape)
				alpha = Number(obShape.alpha);
			
		}
	}
}